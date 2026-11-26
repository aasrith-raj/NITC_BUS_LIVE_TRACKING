import 'package:flutter/material.dart';

import '../models/schedule.dart';
import '../models/assignment.dart';
import '../services/api_service.dart';

class SchedulesScreen extends StatefulWidget {
  const SchedulesScreen({super.key});

  @override
  State<SchedulesScreen> createState() => _SchedulesScreenState();
}

class _SchedulesScreenState extends State<SchedulesScreen> {
  final ApiService _api = ApiService();

  List<BusSchedule> _schedules = [];
  List<Assignment> _assignments = [];

  bool _loading = true;

  static const List<String> _days = [
    'MONDAY',
    'TUESDAY',
    'WEDNESDAY',
    'THURSDAY',
    'FRIDAY',
    'SATURDAY',
    'SUNDAY',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    try {
      final results = await Future.wait([
        _api.fetchSchedules(),
        _api.fetchAssignments(),
      ]);

      if (!mounted) return;

      setState(() {
        _schedules = results[0] as List<BusSchedule>;
        _assignments = results[1] as List<Assignment>;
      });
    } catch (e) {
      if (mounted) {
        _showMessage(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _formatTime(String time) {
    final parts = time.split(':');

    if (parts.length < 2) return time;

    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts[1];

    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;

    return '$displayHour:$minute $period';
  }

  Future<TimeOfDay?> _pickTime(String initialTime) async {
    final parts = initialTime.split(':');

    final initialHour = int.tryParse(parts[0]) ?? 8;
    final initialMinute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;

    return showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: initialHour,
        minute: initialMinute,
      ),
    );
  }

  String _timeToApi(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:00';
  }

  Future<void> _showScheduleDialog({
    BusSchedule? schedule,
  }) async {
    if (_assignments.isEmpty) {
      _showMessage(
        'Create an assignment before adding a schedule.',
      );
      return;
    }

    int selectedAssignmentId =
        schedule?.assignmentId ?? _assignments.first.assignmentId;

    if (!_assignments.any(
      (a) => a.assignmentId == selectedAssignmentId,
    )) {
      selectedAssignmentId = _assignments.first.assignmentId;
    }

    String selectedDay = schedule?.scheduleDay.toUpperCase() ?? 'MONDAY';

    if (!_days.contains(selectedDay)) {
      selectedDay = 'MONDAY';
    }

    TimeOfDay departureTime = const TimeOfDay(
      hour: 8,
      minute: 0,
    );

    TimeOfDay arrivalTime = const TimeOfDay(
      hour: 9,
      minute: 0,
    );

    if (schedule != null) {
      final departureParts = schedule.departureTime.split(':');
      final arrivalParts = schedule.arrivalTime.split(':');

      departureTime = TimeOfDay(
        hour: int.tryParse(departureParts[0]) ?? 8,
        minute: int.tryParse(departureParts[1]) ?? 0,
      );

      arrivalTime = TimeOfDay(
        hour: int.tryParse(arrivalParts[0]) ?? 9,
        minute: int.tryParse(arrivalParts[1]) ?? 0,
      );
    }

    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                schedule == null ? 'Add Schedule' : 'Edit Schedule',
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Assignment',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        initialValue: selectedAssignmentId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Select Assignment',
                        ),
                        items: _assignments.map((assignment) {
                          return DropdownMenuItem<int>(
                            value: assignment.assignmentId,
                            child: Text(
                              'Assignment #${assignment.assignmentId} '
                              '(Bus #${assignment.busId})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              selectedAssignmentId = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Schedule Day',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: selectedDay,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        items: _days.map((day) {
                          return DropdownMenuItem<String>(
                            value: day,
                            child: Text(day),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              selectedDay = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Departure Time',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await _pickTime(
                            _timeToApi(departureTime),
                          );

                          if (picked != null) {
                            setDialogState(() {
                              departureTime = picked;
                            });
                          }
                        },
                        icon: const Icon(Icons.access_time),
                        label: Text(
                          departureTime.format(context),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Arrival Time',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await _pickTime(
                            _timeToApi(arrivalTime),
                          );

                          if (picked != null) {
                            setDialogState(() {
                              arrivalTime = picked;
                            });
                          }
                        },
                        icon: const Icon(Icons.access_time),
                        label: Text(
                          arrivalTime.format(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, false);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (arrivalTime.hour * 60 + arrivalTime.minute <=
                        departureTime.hour * 60 + departureTime.minute) {
                      _showMessage(
                        'Arrival time must be later than departure time.',
                      );
                      return;
                    }

                    Navigator.pop(dialogContext, true);
                  },
                  child: Text(
                    schedule == null ? 'Create' : 'Update',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != true || !mounted) return;

    try {
      if (schedule == null) {
        await _api.createSchedule(
          assignmentId: selectedAssignmentId,
          departureTime: _timeToApi(departureTime),
          arrivalTime: _timeToApi(arrivalTime),
          scheduleDay: selectedDay,
        );

        if (mounted) {
          _showMessage('Schedule created successfully.');
        }
      } else {
        await _api.updateSchedule(
          scheduleId: schedule.scheduleId,
          assignmentId: selectedAssignmentId,
          departureTime: _timeToApi(departureTime),
          arrivalTime: _timeToApi(arrivalTime),
          scheduleDay: selectedDay,
        );

        if (mounted) {
          _showMessage('Schedule updated successfully.');
        }
      }

      await _loadData();
    } catch (e) {
      if (mounted) {
        _showMessage(e.toString());
      }
    }
  }

  Future<void> _deleteSchedule(BusSchedule schedule) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Schedule'),
        content: Text(
          'Are you sure you want to delete Schedule '
          '#${schedule.scheduleId}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _api.deleteSchedule(schedule.scheduleId);

      if (mounted) {
        _showMessage('Schedule deleted successfully.');
      }

      await _loadData();
    } catch (e) {
      if (mounted) {
        _showMessage(e.toString());
      }
    }
  }

  Widget _buildScheduleCard(BusSchedule schedule) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 7,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.schedule,
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Schedule #${schedule.scheduleId}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showScheduleDialog(schedule: schedule);
                    } else if (value == 'delete') {
                      _deleteSchedule(schedule);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(),
            Text('Assignment ID: ${schedule.assignmentId}'),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(schedule.scheduleDay),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.departure_board,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Departure: ${_formatTime(schedule.departureTime)}',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.directions_bus,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Arrival: ${_formatTime(schedule.arrivalTime)}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedules Management'),
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _schedules.isEmpty
              ? const Center(
                  child: Text(
                    'No schedules found.\nTap + to create a schedule.',
                    textAlign: TextAlign.center,
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(
                      top: 8,
                      bottom: 80,
                    ),
                    itemCount: _schedules.length,
                    itemBuilder: (context, index) {
                      return _buildScheduleCard(
                        _schedules[index],
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showScheduleDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
