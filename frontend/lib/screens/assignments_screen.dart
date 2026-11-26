import 'package:flutter/material.dart';

import '../models/assignment.dart';
import '../models/bus.dart';
import '../models/driver.dart';
import '../models/bus_route.dart';
import '../services/api_service.dart';

class AssignmentsScreen extends StatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  final ApiService _api = ApiService();

  List<Assignment> _assignments = [];
  List<Bus> _buses = [];
  List<Driver> _drivers = [];
  List<BusRoute> _routes = [];

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _message(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    try {
      final results = await Future.wait([
        _api.fetchAssignments(),
        _api.fetchBuses(),
        _api.fetchDrivers(),
        _api.fetchRoutes(),
      ]);

      if (!mounted) return;

      setState(() {
        _assignments = results[0] as List<Assignment>;
        _buses = results[1] as List<Bus>;
        _drivers = results[2] as List<Driver>;
        _routes = results[3] as List<BusRoute>;
      });
    } catch (e) {
      _message(e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _busName(int busId) {
    final matches = _buses.where((bus) => bus.id == busId);

    if (matches.isEmpty) return 'Bus ID: $busId';

    return matches.first.busNumber;
  }

  String _driverName(int driverId) {
    final matches = _drivers.where(
      (driver) => driver.driverId == driverId,
    );

    if (matches.isEmpty) return 'Driver ID: $driverId';

    return 'Driver #$driverId (${matches.first.licenseNumber})';
  }

  String _routeName(int routeId) {
    final matches = _routes.where(
      (route) => route.routeId == routeId,
    );

    if (matches.isEmpty) return 'Route ID: $routeId';

    return matches.first.routeName;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Future<Map<String, dynamic>?> _assignmentDialog({
    Assignment? assignment,
  }) async {
    int? selectedBusId = assignment?.busId;
    int? selectedDriverId = assignment?.driverId;
    int? selectedRouteId = assignment?.routeId;

    DateTime selectedDate = assignment?.assignmentDate ?? DateTime.now();

    final formKey = GlobalKey<FormState>();

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                assignment == null ? 'Create Assignment' : 'Edit Assignment',
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<int>(
                        initialValue: selectedBusId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Select Bus',
                          border: OutlineInputBorder(),
                        ),
                        items: _buses.map((bus) {
                          return DropdownMenuItem<int>(
                            value: bus.id,
                            child: Text(
                              '${bus.busNumber} (${bus.status})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedBusId = value;
                          });
                        },
                        validator: (value) =>
                            value == null ? 'Please select a bus' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        initialValue: selectedDriverId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Select Driver',
                          border: OutlineInputBorder(),
                        ),
                        items: _drivers.map((driver) {
                          return DropdownMenuItem<int>(
                            value: driver.driverId,
                            child: Text(
                              'Driver #${driver.driverId} - '
                              '${driver.licenseNumber}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedDriverId = value;
                          });
                        },
                        validator: (value) =>
                            value == null ? 'Please select a driver' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        initialValue: selectedRouteId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Select Route',
                          border: OutlineInputBorder(),
                        ),
                        items: _routes.map((route) {
                          return DropdownMenuItem<int>(
                            value: route.routeId,
                            child: Text(
                              '${route.routeName} '
                              '(${route.startLocation} - '
                              '${route.endLocation})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedRouteId = value;
                          });
                        },
                        validator: (value) =>
                            value == null ? 'Please select a route' : null,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Assignment Date',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_month),
                        label: Text(_formatDate(selectedDate)),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: dialogContext,
                            initialDate: selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );

                          if (picked != null) {
                            setDialogState(() {
                              selectedDate = picked;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;

                    Navigator.pop(
                      dialogContext,
                      {
                        'busId': selectedBusId,
                        'driverId': selectedDriverId,
                        'routeId': selectedRouteId,
                        'assignmentDate': selectedDate,
                      },
                    );
                  },
                  child: Text(
                    assignment == null ? 'Create' : 'Update',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _addAssignment() async {
    if (_buses.isEmpty || _drivers.isEmpty || _routes.isEmpty) {
      _message(
        'Please add at least one bus, driver and route first.',
      );
      return;
    }

    final data = await _assignmentDialog();

    if (data == null || !mounted) return;

    try {
      await _api.createAssignment(
        busId: data['busId'] as int,
        driverId: data['driverId'] as int,
        routeId: data['routeId'] as int,
        assignmentDate: data['assignmentDate'] as DateTime,
      );

      if (!mounted) return;

      _message('Assignment created successfully.');
      await _loadData();
    } catch (e) {
      _message(e.toString());
    }
  }

  Future<void> _editAssignment(Assignment assignment) async {
    final data = await _assignmentDialog(
      assignment: assignment,
    );

    if (data == null || !mounted) return;

    try {
      await _api.updateAssignment(
        assignmentId: assignment.assignmentId,
        busId: data['busId'] as int,
        driverId: data['driverId'] as int,
        routeId: data['routeId'] as int,
        assignmentDate: data['assignmentDate'] as DateTime,
      );

      if (!mounted) return;

      _message('Assignment updated successfully.');
      await _loadData();
    } catch (e) {
      _message(e.toString());
    }
  }

  Future<void> _deleteAssignment(Assignment assignment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Assignment'),
          content: Text(
            'Are you sure you want to delete assignment '
            '#${assignment.assignmentId}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true || !mounted) return;

    try {
      await _api.deleteAssignment(assignment.assignmentId);

      if (!mounted) return;

      _message('Assignment deleted successfully.');
      await _loadData();
    } catch (e) {
      _message(e.toString());
    }
  }

  Widget _assignmentCard(Assignment assignment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.assignment_ind,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Assignment #${assignment.assignmentId}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editAssignment(assignment);
                    } else if (value == 'delete') {
                      _deleteAssignment(assignment);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Edit'),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(
                          Icons.delete,
                          color: Colors.red,
                        ),
                        title: Text('Delete'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(),
            _detailRow(
              Icons.directions_bus,
              'Bus',
              _busName(assignment.busId),
            ),
            _detailRow(
              Icons.person,
              'Driver',
              _driverName(assignment.driverId),
            ),
            _detailRow(
              Icons.route,
              'Route',
              _routeName(assignment.routeId),
            ),
            _detailRow(
              Icons.calendar_today,
              'Assignment Date',
              _formatDate(assignment.assignmentDate),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: Colors.grey.shade700),
          const SizedBox(width: 10),
          SizedBox(
            width: 115,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignments Management'),
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _assignments.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.assignment_outlined,
                        size: 65,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'No assignments found.',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Tap the + button to create an assignment.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        'Total Assignments: ${_assignments.length}',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 14),
                      ..._assignments.map(_assignmentCard),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addAssignment,
        icon: const Icon(Icons.add),
        label: const Text('Add Assignment'),
      ),
    );
  }
}
