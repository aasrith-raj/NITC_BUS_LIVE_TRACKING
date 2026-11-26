import 'dart:async';

import 'package:flutter/material.dart';

import '../models/announcement.dart';
import '../models/bus.dart';
import '../models/bus_location.dart';
import '../models/bus_route.dart';
import '../models/bus_stop.dart';
import '../models/assignment.dart';
import '../models/schedule.dart';
import '../models/route_stop.dart';

import '../services/api_service.dart';
import '../services/eta_service.dart';

import '../widgets/info_card.dart';
import '../widgets/student_bus_map.dart';

import 'route_details_screen.dart';
import 'login_screen.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final ApiService _api = ApiService();

  List<Bus> _buses = [];
  List<BusLocation> _locations = [];
  List<BusRoute> _routes = [];
  List<BusStop> _stops = [];
  List<Announcement> _announcements = [];
  List<Assignment> _assignments = [];
  List<BusSchedule> _schedules = [];

  // ETA feature state.
  List<RouteStop> _etaRouteStops = [];

  int? _selectedEtaAssignmentId;
  int? _selectedEtaStopId;

  bool _isLoadingEtaStops = false;
  String? _etaError;

  bool _isLoading = true;
  String? _errorMessage;

  // Automatic GPS refresh management.
  Timer? _locationRefreshTimer;
  bool _isRefreshingLocations = false;

  @override
  void initState() {
    super.initState();

    _loadDashboard();

    // Refresh bus GPS locations every 15 seconds.
    _locationRefreshTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) {
        _refreshLocations();
      },
    );
  }

  // Load all Student Dashboard data.
  Future<void> _loadDashboard() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _api.fetchBuses(),
        _api.fetchLatestBusLocations(),
        _api.fetchRoutes(),
        _api.fetchStops(),
        _api.fetchAnnouncements(),
        _api.fetchAssignments(),
        _api.fetchSchedules(),
      ]);

      if (!mounted) return;

      setState(() {
        _buses = results[0] as List<Bus>;
        _locations = results[1] as List<BusLocation>;
        _routes = results[2] as List<BusRoute>;
        _stops = results[3] as List<BusStop>;
        _announcements = results[4] as List<Announcement>;
        _assignments = results[5] as List<Assignment>;
        _schedules = results[6] as List<BusSchedule>;

        _isLoading = false;
      });

      // Initialize ETA after the dashboard data has loaded.
      await _initializeEta();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // Initialize ETA using the first valid assignment.
  Future<void> _initializeEta() async {
    if (_assignments.isEmpty) {
      if (!mounted) return;

      setState(() {
        _selectedEtaAssignmentId = null;
        _selectedEtaStopId = null;
        _etaRouteStops = [];
      });

      return;
    }

    Assignment? selectedAssignment;

    for (final assignment in _assignments) {
      final hasBus = _buses.any(
        (bus) => bus.id == assignment.busId,
      );

      final hasRoute = _routes.any(
        (route) => route.routeId == assignment.routeId,
      );

      if (hasBus && hasRoute) {
        selectedAssignment = assignment;
        break;
      }
    }

    if (selectedAssignment == null || !mounted) return;

    final chosenAssignment = selectedAssignment;

    setState(() {
      _selectedEtaAssignmentId = chosenAssignment.assignmentId;
    });

    await _loadEtaRouteStops(chosenAssignment.routeId);
  }

  // Load ordered stops for the selected route.
  Future<void> _loadEtaRouteStops(int routeId) async {
    if (!mounted) return;

    setState(() {
      _isLoadingEtaStops = true;
      _etaError = null;
      _etaRouteStops = [];
      _selectedEtaStopId = null;
    });

    try {
      final stops = await _api.fetchOrderedRouteStops(routeId);

      if (!mounted) return;

      final validStops = stops
          .where((stop) => stop.hasValidCoordinates)
          .toList()
        ..sort((a, b) => a.stopOrder.compareTo(b.stopOrder));

      setState(() {
        _etaRouteStops = validStops;

        // Initially select the final stop.
        if (validStops.isNotEmpty) {
          _selectedEtaStopId = validStops.last.stopId;
        }

        _isLoadingEtaStops = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _etaError = e.toString();
        _isLoadingEtaStops = false;
      });
    }
  }

  // Handle assignment selection.
  Future<void> _onEtaAssignmentChanged(int? assignmentId) async {
    if (assignmentId == null) return;

    Assignment? selectedAssignment;

    for (final item in _assignments) {
      if (item.assignmentId == assignmentId) {
        selectedAssignment = item;
        break;
      }
    }

    if (selectedAssignment == null || !mounted) return;

    final chosenAssignment = selectedAssignment;

    setState(() {
      _selectedEtaAssignmentId = assignmentId;
    });

    await _loadEtaRouteStops(chosenAssignment.routeId);
  }

  // Refresh only bus GPS locations.
  Future<void> _refreshLocations() async {
    if (_isRefreshingLocations || !mounted) return;

    _isRefreshingLocations = true;

    try {
      final locations = await _api.fetchLatestBusLocations();

      if (!mounted) return;

      setState(() {
        _locations = locations;
      });
    } catch (e) {
      debugPrint('Bus location refresh failed: $e');
    } finally {
      _isRefreshingLocations = false;
    }
  }

  // Logout.
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

    if (confirm == true && mounted) {
      await _api.logout();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
        (route) => false,
      );
    }
  }

  // Section heading.
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  // Display available buses.
  Widget _buildBusList() {
    if (_buses.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'No buses are currently available.',
          ),
        ),
      );
    }

    return Column(
      children: _buses.map((bus) {
        return Card(
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.directions_bus),
            ),
            title: Text(bus.busNumber),
            subtitle: Text(
              'Capacity: ${bus.capacity} passengers',
            ),
            trailing: Chip(
              label: Text(bus.status),
            ),
          ),
        );
      }).toList(),
    );
  }

  // Display available routes.
  Widget _buildRouteList() {
    if (_routes.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'No routes are currently available.',
          ),
        ),
      );
    }

    return Column(
      children: _routes.map((route) {
        return Card(
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.route),
            ),
            title: Text(route.routeName),
            subtitle: Text(
              '${route.startLocation} → ${route.endLocation}',
            ),
            trailing: Icon(
              route.isActive ? Icons.check_circle : Icons.cancel,
              color: route.isActive ? Colors.green : Colors.grey,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RouteDetailsScreen(route: route),
                ),
              );
            },
          ),
        );
      }).toList(),
    );
  }

  // Display ETA information.
  Widget _buildEtaSection() {
    if (_assignments.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'No bus assignments are currently available for ETA.',
          ),
        ),
      );
    }

    Assignment? selectedAssignment;

    for (final assignment in _assignments) {
      if (assignment.assignmentId == _selectedEtaAssignmentId) {
        selectedAssignment = assignment;
        break;
      }
    }

    Bus? selectedBus;

    if (selectedAssignment != null) {
      for (final bus in _buses) {
        if (bus.id == selectedAssignment.busId) {
          selectedBus = bus;
          break;
        }
      }
    }

    BusLocation? selectedBusLocation;

    if (selectedAssignment != null) {
      for (final location in _locations) {
        if (location.busId == selectedAssignment.busId &&
            location.hasValidCoordinates) {
          selectedBusLocation = location;
          break;
        }
      }
    }

    final destinationMatches = _etaRouteStops.where(
      (stop) => stop.stopId == _selectedEtaStopId,
    );

    final destinationStop =
        destinationMatches.isEmpty ? null : destinationMatches.first;

    final remainingDistance =
        selectedBusLocation != null && destinationStop != null
            ? EtaService.remainingDistanceKm(
                busLocation: selectedBusLocation,
                routeStops: _etaRouteStops,
                destinationStopId: destinationStop.stopId,
              )
            : null;

    final estimatedMinutes =
        selectedBusLocation != null && destinationStop != null
            ? EtaService.estimatedMinutes(
                busLocation: selectedBusLocation,
                routeStops: _etaRouteStops,
                destinationStopId: destinationStop.stopId,
              )
            : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  color: Colors.blue,
                  size: 26,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Estimated Time of Arrival',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'Select bus and route assignment',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              initialValue: _selectedEtaAssignmentId,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.directions_bus),
              ),
              hint: const Text('Select an assignment'),
              items: _assignments.map((assignment) {
                Bus? bus;
                BusRoute? route;

                for (final item in _buses) {
                  if (item.id == assignment.busId) {
                    bus = item;
                    break;
                  }
                }

                for (final item in _routes) {
                  if (item.routeId == assignment.routeId) {
                    route = item;
                    break;
                  }
                }

                return DropdownMenuItem<int>(
                  value: assignment.assignmentId,
                  child: Text(
                    '${bus?.busNumber ?? 'Unknown bus'} - '
                    '${route?.routeName ?? 'Unknown route'}',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: _onEtaAssignmentChanged,
            ),
            const SizedBox(height: 18),
            const Text(
              'Select destination stop',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            if (_isLoadingEtaStops)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_etaError != null)
              Text(
                'Unable to load route stops: $_etaError',
                style: const TextStyle(color: Colors.red),
              )
            else if (_etaRouteStops.isEmpty)
              const Text(
                'No route stops with valid GPS coordinates are available.',
              )
            else
              DropdownButtonFormField<int>(
                initialValue: _selectedEtaStopId,
                isExpanded: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                items: _etaRouteStops.map((stop) {
                  return DropdownMenuItem<int>(
                    value: stop.stopId,
                    child: Text(
                      '${stop.stopOrder}. ${stop.stopName}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (stopId) {
                  setState(() {
                    _selectedEtaStopId = stopId;
                  });
                },
              ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            if (selectedAssignment == null)
              const Text('Select a valid bus assignment.')
            else if (selectedBus == null)
              const Text('Bus information is unavailable.')
            else if (_isLoadingEtaStops)
              const Text('Loading route information...')
            else if (_etaError != null)
              const Text(
                  'Unable to calculate ETA because route stops failed to load.')
            else if (_etaRouteStops.length < 2)
              const Text(
                'At least two valid route stops are required for ETA.',
              )
            else if (selectedBusLocation == null)
              const Text(
                'Waiting for the selected bus GPS location.',
              )
            else if (destinationStop == null)
              const Text('Select a destination stop.')
            else if (estimatedMinutes == null)
              const Text(
                'ETA is unavailable. The bus may be away from its route, '
                'or it may have already passed the selected stop.',
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedBus.busNumber,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    estimatedMinutes == 0
                        ? 'The bus is at or very close to your selected stop.'
                        : '$estimatedMinutes minutes',
                    style: const TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Destination: ${destinationStop.stopName}',
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Remaining route distance: '
                    '${remainingDistance!.toStringAsFixed(2)} km',
                    style: const TextStyle(
                      color: Colors.blueGrey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Based on an assumed average speed of 20 km/h. '
                    'This is an approximate estimate, not a traffic-aware prediction.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // Display available bus schedules.
  Widget _buildScheduleList() {
    if (_schedules.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.schedule),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No bus schedules are currently available.',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _schedules.map((schedule) {
        Assignment? assignment;

        for (final item in _assignments) {
          if (item.assignmentId == schedule.assignmentId) {
            assignment = item;
            break;
          }
        }

        Bus? bus;

        if (assignment != null) {
          for (final item in _buses) {
            if (item.id == assignment.busId) {
              bus = item;
              break;
            }
          }
        }

        BusRoute? route;

        if (assignment != null) {
          for (final item in _routes) {
            if (item.routeId == assignment.routeId) {
              route = item;
              break;
            }
          }
        }

        final departure = schedule.departureTime.length >= 5
            ? schedule.departureTime.substring(0, 5)
            : schedule.departureTime;

        final arrival = schedule.arrivalTime.length >= 5
            ? schedule.arrivalTime.substring(0, 5)
            : schedule.arrivalTime;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      child: Icon(Icons.directions_bus),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        bus?.busNumber ?? 'Bus information unavailable',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.schedule,
                      color: Colors.blueGrey,
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    const Icon(Icons.route, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        route?.routeName ?? 'Route information unavailable',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildScheduleTime(
                        'Departure',
                        departure,
                        Icons.departure_board,
                      ),
                    ),
                    Expanded(
                      child: _buildScheduleTime(
                        'Arrival',
                        arrival,
                        Icons.flag_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 17,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Operating day: ${schedule.scheduleDay}',
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // Display departure and arrival times.
  Widget _buildScheduleTime(
    String label,
    String time,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.blueGrey),
        const SizedBox(width: 6),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                time,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Display announcements.
  Widget _buildAnnouncementList() {
    if (_announcements.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.campaign_outlined),
              SizedBox(width: 12),
              Expanded(
                child: Text('No announcements yet.'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _announcements.map((announcement) {
        return Card(
          child: ListTile(
            leading: const Icon(Icons.campaign),
            title: Text(announcement.title),
            subtitle: Text(announcement.message),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'NITC Campus Bus Tracker',
        ),
        actions: [
          IconButton(
            onPressed: _loadDashboard,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh dashboard',
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.cloud_off,
                          size: 45,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Unable to load dashboard data.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _loadDashboard,
                          child: const Text('Try again'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDashboard,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        'Hello, Student!',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),

                      const SizedBox(height: 5),

                      const Text(
                        'Track campus buses and plan your journey.',
                      ),

                      const SizedBox(height: 16),

                      InfoCard(
                        icon: Icons.directions_bus,
                        title: 'Available Buses',
                        value: '${_buses.length} buses registered',
                      ),

                      const SizedBox(height: 20),

                      // Campus Bus Map.
                      _buildSectionTitle('Campus Bus Map'),

                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(
                          height: 350,
                          child: StudentBusMap(
                            buses: _buses,
                            locations: _locations,
                            stops: _stops,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Manual GPS refresh.
                      TextButton.icon(
                        onPressed: _refreshLocations,
                        icon: const Icon(Icons.my_location),
                        label: const Text(
                          'Refresh bus locations',
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Available Buses.
                      _buildSectionTitle('Available Buses'),
                      _buildBusList(),

                      const SizedBox(height: 20),

                      // Campus Routes.
                      _buildSectionTitle('Campus Routes'),
                      _buildRouteList(),

                      const SizedBox(height: 20),

                      // Bus Arrival Estimates.
                      _buildSectionTitle('Bus Arrival Estimates'),
                      _buildEtaSection(),

                      const SizedBox(height: 20),

                      // Bus Schedules.
                      _buildSectionTitle('Bus Schedules'),
                      _buildScheduleList(),

                      const SizedBox(height: 20),

                      // Announcements.
                      _buildSectionTitle('Announcements'),
                      _buildAnnouncementList(),
                    ],
                  ),
                ),
    );
  }

  // Cancel the timer when leaving the dashboard.
  @override
  void dispose() {
    _locationRefreshTimer?.cancel();
    super.dispose();
  }
}
