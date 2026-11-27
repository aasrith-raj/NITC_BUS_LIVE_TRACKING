import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/driver.dart';
import '../models/assignment.dart';
import '../models/bus.dart';
import '../models/bus_route.dart';
import '../models/schedule.dart';

import '../services/api_service.dart';
import '../services/location_service.dart';
import '../widgets/info_card.dart';

import 'login_screen.dart';

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  final ApiService _apiService = ApiService();
  final LocationService _locationService = LocationService();

  StreamSubscription<Position>? _locationSubscription;

  bool _loading = true;
  bool _sharing = false;
  bool _uploadingLocation = false;

  String? _errorMessage;

  String _driverName = 'Driver';
  String _driverEmail = '';

  Driver? _driver;
  Assignment? _assignment;
  Bus? _bus;
  BusRoute? _route;

  List<BusSchedule> _schedules = [];

  String _locationText = 'Location has not been requested';

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  // --------------------------------------------------
  // LOAD DRIVER DASHBOARD
  // --------------------------------------------------

  Future<void> _loadDashboard() async {
    try {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });

      // 1. Identify the currently authenticated user.
      final currentUser = await _apiService.fetchCurrentUser();

      final userId = (currentUser['user_id'] as num).toInt();

      _driverName = currentUser['name']?.toString() ?? 'Driver';
      _driverEmail = currentUser['email']?.toString() ?? '';

      // 2. Retrieve driver profiles.
      final drivers = await _apiService.fetchDrivers();

      final matchingDrivers =
          drivers.where((driver) => driver.userId == userId).toList();

      if (matchingDrivers.isEmpty) {
        throw Exception(
          'No driver profile is linked to your account.',
        );
      }

      final driver = matchingDrivers.first;
      _driver = driver;

      // 3. Retrieve assignments belonging to this driver.
      final assignments = await _apiService.fetchAssignments();

      final driverAssignments = assignments
          .where((assignment) => assignment.driverId == driver.driverId)
          .toList();

      if (driverAssignments.isEmpty) {
        throw Exception(
          'No bus assignment was found for this driver.',
        );
      }

      // If multiple assignments exist, use the latest assignment date.
      driverAssignments.sort(
        (a, b) => b.assignmentDate.compareTo(a.assignmentDate),
      );

      final assignment = driverAssignments.first;
      _assignment = assignment;

      // 4. Retrieve buses and routes.
      final buses = await _apiService.fetchBuses();
      final routes = await _apiService.fetchRoutes();

      final matchingBuses =
          buses.where((bus) => bus.id == assignment.busId).toList();

      final matchingRoutes =
          routes.where((route) => route.routeId == assignment.routeId).toList();

      if (matchingBuses.isEmpty) {
        throw Exception('The assigned bus was not found.');
      }

      if (matchingRoutes.isEmpty) {
        throw Exception('The assigned route was not found.');
      }

      _bus = matchingBuses.first;
      _route = matchingRoutes.first;

      // 5. Retrieve schedules for this assignment.
      final allSchedules = await _apiService.fetchSchedules();

      _schedules = allSchedules
          .where((schedule) => schedule.assignmentId == assignment.assignmentId)
          .toList();

      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _errorMessage = error.toString();
      });
    }
  }

  // --------------------------------------------------
  // START LOCATION SHARING
  // --------------------------------------------------

  Future<void> _startSharing() async {
    if (_bus == null || _driver == null) {
      _showMessage(
        'Your bus assignment is not available.',
      );
      return;
    }

    try {
      final positionStream = await _locationService.getPositionStream();

      if (!mounted) return;

      setState(() {
        _sharing = true;
        _locationText = 'Waiting for GPS location...';
      });

      _locationSubscription = positionStream.listen(
        (position) async {
          if (!mounted || !_sharing) return;

          setState(() {
            _locationText = '${position.latitude.toStringAsFixed(6)}, '
                '${position.longitude.toStringAsFixed(6)}';
          });

          await _uploadLocation(position);
        },
        onError: (error) {
          if (!mounted) return;

          _showMessage(
            'GPS error: $error',
          );

          _stopSharing();
        },
      );
    } catch (error) {
      if (!mounted) return;

      _showMessage(error.toString());
    }
  }

  // --------------------------------------------------
  // UPLOAD LOCATION TO FASTAPI
  // --------------------------------------------------

  Future<void> _uploadLocation(Position position) async {
    if (_bus == null) return;

    if (_uploadingLocation) return;

    _uploadingLocation = true;

    try {
      await _apiService.uploadBusLocation(
        busId: _bus!.id,
        latitude: position.latitude,
        longitude: position.longitude,

        // Use the timestamp associated with this GPS reading.
        // Convert it to UTC before sending it to the backend.
        recordedAt: position.timestamp.toUtc(),
      );
    } catch (error) {
      if (mounted) {
        _showMessage(
          'Location upload failed: $error',
        );
      }
    } finally {
      _uploadingLocation = false;
    }
  }

  // --------------------------------------------------
  // STOP LOCATION SHARING
  // --------------------------------------------------

  Future<void> _stopSharing() async {
    await _locationSubscription?.cancel();
    _locationSubscription = null;

    if (!mounted) return;

    setState(() {
      _sharing = false;
    });
  }

  Future<void> _toggleSharing() async {
    if (_sharing) {
      await _stopSharing();
    } else {
      await _startSharing();
    }
  }

  // --------------------------------------------------
  // BREAKDOWN REPORT
  // --------------------------------------------------

  Future<void> _showBreakdownDialog() async {
    if (_bus == null || _driver == null) {
      _showMessage(
        'Your assigned bus is not available.',
      );
      return;
    }

    final description = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return const _BreakdownReportDialog();
      },
    );

    if (description == null) return;

    if (description.trim().isEmpty) {
      _showMessage('Please enter a breakdown description.');
      return;
    }

    try {
      await _apiService.submitBreakdownReport(
        busId: _bus!.id,
        driverId: _driver!.driverId,
        description: description.trim(),
      );

      if (!mounted) return;

      _showMessage(
        'Breakdown report submitted successfully.',
      );
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        'Failed to submit report: $error',
      );
    }
  }

  // --------------------------------------------------
  // LOGOUT
  // --------------------------------------------------

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text(
          'Are you sure you want to logout?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    await _stopSharing();
    await _apiService.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  // --------------------------------------------------
  // HELPER
  // --------------------------------------------------

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildScheduleSection() {
    if (_schedules.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'No schedules have been added for this assignment yet.',
          ),
        ),
      );
    }

    return Column(
      children: _schedules.map((schedule) {
        return Card(
          child: ListTile(
            leading: const Icon(Icons.schedule),
            title: Text(schedule.scheduleDay),
            subtitle: Text(
              'Departure: ${schedule.departureTime}\n'
              'Arrival: ${schedule.arrivalTime}',
            ),
            isThreeLine: true,
          ),
        );
      }).toList(),
    );
  }

  // --------------------------------------------------
  // BUILD UI
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _errorMessage != null
              ? _buildErrorView()
              : _buildDashboard(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadDashboard,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    return RefreshIndicator(
      onRefresh: _loadDashboard,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Welcome, $_driverName',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 6),

          if (_driverEmail.isNotEmpty) Text(_driverEmail),

          if (_driver != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'License: ${_driver!.licenseNumber}',
              ),
            ),

          const SizedBox(height: 16),

          // Assigned bus.
          InfoCard(
            icon: Icons.directions_bus,
            title: 'Assigned bus',
            value: _bus == null
                ? 'Not available'
                : '${_bus!.busNumber.trim()} '
                    '(${_bus!.capacity} seats)',
          ),

          // Assigned route.
          InfoCard(
            icon: Icons.route,
            title: 'Assigned route',
            value: _route == null
                ? 'Not available'
                : '${_route!.routeName.trim()}\n'
                    '${_route!.startLocation.trim()} → '
                    '${_route!.endLocation.trim()}',
          ),

          const SizedBox(height: 16),

          // Schedule.
          Text(
            'Bus Schedule',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 8),

          _buildScheduleSection(),

          const SizedBox(height: 16),

          // Location sharing.
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    _sharing ? Icons.gps_fixed : Icons.gps_not_fixed,
                    size: 52,
                    color: _sharing ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _sharing
                        ? 'Location sharing active'
                        : 'Location sharing off',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _locationText,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  if (_sharing)
                    const Text(
                      'Sending foreground GPS updates to the server.',
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _toggleSharing,
                      icon: Icon(
                        _sharing ? Icons.stop : Icons.play_arrow,
                      ),
                      label: Text(
                        _sharing ? 'Stop sharing' : 'Start location sharing',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Breakdown report.
          FilledButton.tonalIcon(
            onPressed: _showBreakdownDialog,
            icon: const Icon(
              Icons.report_problem_outlined,
            ),
            label: const Text('Report breakdown'),
          ),

          const SizedBox(height: 16),

          Text(
            'Assignment ID: ${_assignment?.assignmentId ?? '-'}',
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          const Text(
            'Location sharing operates while the app is running. '
            'Background tracking requires additional Android setup.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }
}

// --------------------------------------------------
// BREAKDOWN REPORT DIALOG
// --------------------------------------------------

class _BreakdownReportDialog extends StatefulWidget {
  const _BreakdownReportDialog();

  @override
  State<_BreakdownReportDialog> createState() => _BreakdownReportDialogState();
}

class _BreakdownReportDialogState extends State<_BreakdownReportDialog> {
  final TextEditingController _descriptionController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Report Bus Breakdown'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Breakdown Description',
            hintText: 'Describe the problem with the bus...',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a breakdown description.';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) {
              return;
            }

            Navigator.pop(
              context,
              _descriptionController.text.trim(),
            );
          },
          child: const Text('Submit Report'),
        ),
      ],
    );
  }
}
