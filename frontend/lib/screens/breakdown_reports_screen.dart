import 'package:flutter/material.dart';

import '../models/breakdown_report.dart';
import '../models/bus.dart';
import '../models/driver.dart';
import '../services/api_service.dart';

class BreakdownReportsScreen extends StatefulWidget {
  const BreakdownReportsScreen({super.key});

  @override
  State<BreakdownReportsScreen> createState() => _BreakdownReportsScreenState();
}

class _BreakdownReportsScreenState extends State<BreakdownReportsScreen> {
  final ApiService _api = ApiService();

  List<BreakdownReport> _reports = [];
  List<Bus> _buses = [];
  List<Driver> _drivers = [];

  bool _isLoading = true;
  String? _error;

  final List<String> _statuses = [
    'REPORTED',
    'IN_PROGRESS',
    'RESOLVED',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // --------------------------------------------------
  // LOAD DATA
  // --------------------------------------------------

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final results = await Future.wait([
        _api.fetchBreakdownReports(),
        _api.fetchBuses(),
        _api.fetchDrivers(),
      ]);

      if (!mounted) return;

      setState(() {
        _reports = results[0] as List<BreakdownReport>;
        _buses = results[1] as List<Bus>;
        _drivers = results[2] as List<Driver>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    await _loadData();
  }

  // --------------------------------------------------
  // HELPER METHODS
  // --------------------------------------------------

  String _busName(int busId) {
    final matches = _buses.where(
      (bus) => bus.id == busId,
    );

    if (matches.isEmpty) {
      return 'Bus ID: $busId';
    }

    return matches.first.busNumber;
  }

  String _driverName(int driverId) {
    final matches = _drivers.where(
      (driver) => driver.driverId == driverId,
    );

    if (matches.isEmpty) {
      return 'Driver ID: $driverId';
    }

    return 'Driver ID: ${matches.first.driverId}';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'REPORTED':
        return Colors.red;
      case 'IN_PROGRESS':
        return Colors.orange;
      case 'RESOLVED':
        return Colors.green;
      default:
        return Colors.blueGrey;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Date unavailable';
    }

    final localDate = date.toLocal();

    final day = localDate.day.toString().padLeft(2, '0');
    final month = localDate.month.toString().padLeft(2, '0');
    final year = localDate.year;

    final hour = localDate.hour.toString().padLeft(2, '0');
    final minute = localDate.minute.toString().padLeft(2, '0');

    return '$day/$month/$year at $hour:$minute';
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // --------------------------------------------------
  // EDIT BREAKDOWN REPORT
  // --------------------------------------------------

  Future<void> _showReportDialog({
    required BreakdownReport report,
  }) async {
    if (_buses.isEmpty || _drivers.isEmpty) {
      _showMessage(
        'Bus or driver information could not be loaded.',
      );
      return;
    }

    final descriptionController = TextEditingController(
      text: report.description,
    );

    int selectedBusId = _buses.any(
      (bus) => bus.id == report.busId,
    )
        ? report.busId
        : _buses.first.id;

    int selectedDriverId = _drivers.any(
      (driver) => driver.driverId == report.driverId,
    )
        ? report.driverId
        : _drivers.first.driverId;

    String selectedStatus =
        _statuses.contains(report.status) ? report.status : 'REPORTED';

    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        bool isSaving = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                'Edit Breakdown Report #${report.reportId}',
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<int>(
                        initialValue: selectedBusId,
                        decoration: const InputDecoration(
                          labelText: 'Select Bus',
                          border: OutlineInputBorder(),
                        ),
                        items: _buses.map((bus) {
                          return DropdownMenuItem<int>(
                            value: bus.id,
                            child: Text(bus.busNumber),
                          );
                        }).toList(),
                        onChanged: isSaving
                            ? null
                            : (value) {
                                if (value != null) {
                                  setDialogState(() {
                                    selectedBusId = value;
                                  });
                                }
                              },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        initialValue: selectedDriverId,
                        decoration: const InputDecoration(
                          labelText: 'Select Driver',
                          border: OutlineInputBorder(),
                        ),
                        items: _drivers.map((driver) {
                          return DropdownMenuItem<int>(
                            value: driver.driverId,
                            child: Text(
                              'Driver ID: ${driver.driverId}',
                            ),
                          );
                        }).toList(),
                        onChanged: isSaving
                            ? null
                            : (value) {
                                if (value != null) {
                                  setDialogState(() {
                                    selectedDriverId = value;
                                  });
                                }
                              },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: descriptionController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Breakdown Description',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Report Status',
                          border: OutlineInputBorder(),
                        ),
                        items: _statuses.map((status) {
                          return DropdownMenuItem<String>(
                            value: status,
                            child: Text(
                              status.replaceAll('_', ' '),
                            ),
                          );
                        }).toList(),
                        onChanged: isSaving
                            ? null
                            : (value) {
                                if (value != null) {
                                  setDialogState(() {
                                    selectedStatus = value;
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
                  onPressed: isSaving
                      ? null
                      : () {
                          Navigator.pop(dialogContext, false);
                        },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }

                          setDialogState(() {
                            isSaving = true;
                          });

                          try {
                            await _api.updateBreakdownReport(
                              reportId: report.reportId,
                              busId: selectedBusId,
                              driverId: selectedDriverId,
                              description: descriptionController.text.trim(),
                              status: selectedStatus,
                            );

                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext, true);
                            }
                          } catch (e) {
                            setDialogState(() {
                              isSaving = false;
                            });

                            if (dialogContext.mounted) {
                              ScaffoldMessenger.of(
                                dialogContext,
                              ).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Failed to update report: $e',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Update Report'),
                ),
              ],
            );
          },
        );
      },
    );

    descriptionController.dispose();

    if (result == true && mounted) {
      await _loadData();

      if (!mounted) return;

      _showMessage(
        'Breakdown report updated successfully.',
      );
    }
  }

  // --------------------------------------------------
  // PUBLISH ANNOUNCEMENT FROM BREAKDOWN REPORT
  // --------------------------------------------------

  String _getBusConditionMessage(String status) {
    switch (status) {
      case 'REPORTED':
        return 'A breakdown has been reported. The bus service '
            'availability is currently being assessed. Please check '
            'with the transport office for further updates.';

      case 'IN_PROGRESS':
        return 'The bus is undergoing maintenance. It may be '
            'temporarily unavailable or operating with restrictions. '
            'Please check for further service updates.';

      case 'RESOLVED':
        return 'The breakdown report has been marked as resolved. '
            'Please confirm the bus service availability with the '
            'transport office before travelling.';

      default:
        return 'Please contact the transport office for the '
            'latest information about this bus service.';
    }
  }

  Future<void> _publishAnnouncement(
    BreakdownReport report,
  ) async {
    try {
      // Retrieve the currently authenticated user.
      final currentUser = await _api.fetchCurrentUser();

      final role = currentUser['role']?.toString().toUpperCase();

      if (role != 'ADMIN') {
        throw Exception(
          'Only an administrator can publish announcements.',
        );
      }

      final adminId = (currentUser['user_id'] as num).toInt();

      final busNumber = _busName(report.busId);
      final reportedAt = _formatDate(report.reportedAt);

      final defaultTitle = 'Bus $busNumber - Breakdown Alert';

      final defaultMessage = 'Affected Bus: $busNumber\n\n'
          'Breakdown Description: ${report.description}\n\n'
          'Report Status: '
          '${report.status.replaceAll('_', ' ')}\n\n'
          'Reported Date and Time: $reportedAt\n\n'
          'Bus Service Information:\n'
          '${_getBusConditionMessage(report.status)}\n\n'
          'Please plan your journey accordingly and follow '
          'official transport updates.';

      // Open the editable announcement preview.
      if (!mounted) return;
      final announcement = await showDialog<Map<String, String>>(
        context: context,
        builder: (dialogContext) {
          return _PublishAnnouncementDialog(
            initialTitle: defaultTitle,
            initialMessage: defaultMessage,
          );
        },
      );

      if (announcement == null) return;

      final title = announcement['title'] ?? '';
      final message = announcement['message'] ?? '';

      if (title.trim().isEmpty || message.trim().isEmpty) {
        _showMessage(
          'Announcement title and message are required.',
        );
        return;
      }

      // Publish using the existing announcement API.
      await _api.createAnnouncement(
        title: title,
        message: message,
        createdBy: adminId,
      );

      if (!mounted) return;

      _showMessage(
        'Announcement published successfully!',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Failed to publish announcement: $e',
      );
    }
  }

  // --------------------------------------------------
  // DELETE BREAKDOWN REPORT
  // --------------------------------------------------

  Future<void> _deleteReport(
    BreakdownReport report,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Report'),
        content: Text(
          'Are you sure you want to delete report '
          '#${report.reportId}?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, false);
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () {
              Navigator.pop(dialogContext, true);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _api.deleteBreakdownReport(report.reportId);

      if (!mounted) return;

      await _loadData();

      if (!mounted) return;

      _showMessage(
        'Breakdown report deleted successfully.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Failed to delete report: $e',
      );
    }
  }

  // --------------------------------------------------
  // BREAKDOWN REPORT CARD
  // --------------------------------------------------

  Widget _buildReportCard(
    BreakdownReport report,
  ) {
    final statusColor = _statusColor(report.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.car_crash,
                  color: Colors.red,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Report #${report.reportId}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showReportDialog(
                        report: report,
                      );
                    } else if (value == 'publish') {
                      _publishAnnouncement(report);
                    } else if (value == 'delete') {
                      _deleteReport(report);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Edit Report'),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'publish',
                      child: ListTile(
                        leading: Icon(
                          Icons.campaign,
                          color: Colors.green,
                        ),
                        title: Text('Publish Announcement'),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(
                          Icons.delete,
                          color: Colors.red,
                        ),
                        title: Text('Delete Report'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: const Icon(
                    Icons.directions_bus,
                    size: 18,
                  ),
                  label: Text(
                    _busName(report.busId),
                  ),
                ),
                Chip(
                  avatar: const Icon(
                    Icons.person,
                    size: 18,
                  ),
                  label: Text(
                    _driverName(report.driverId),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Description',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(report.description),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _formatDate(report.reportedAt),
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(
                      alpha: 0.12,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    report.status.replaceAll('_', ' '),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    _publishAnnouncement(report);
                  },
                  icon: const Icon(
                    Icons.campaign,
                    size: 18,
                  ),
                  label: const Text('Publish'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
  // MAIN SCREEN
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Breakdown Reports'),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh reports',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
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
                          'Failed to load breakdown reports.\n$_error',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: _loadData,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: _reports.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 150),
                            Icon(
                              Icons.check_circle_outline,
                              size: 60,
                              color: Colors.green,
                            ),
                            SizedBox(height: 16),
                            Center(
                              child: Text(
                                'No breakdown reports found.',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        )
                      : ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          children: [
                            Text(
                              'Total Reports: ${_reports.length}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            ..._reports.map(_buildReportCard),
                          ],
                        ),
                ),
    );
  }
}

// ==================================================
// ANNOUNCEMENT PREVIEW AND EDIT DIALOG
// ==================================================

class _PublishAnnouncementDialog extends StatefulWidget {
  final String initialTitle;
  final String initialMessage;

  const _PublishAnnouncementDialog({
    required this.initialTitle,
    required this.initialMessage,
  });

  @override
  State<_PublishAnnouncementDialog> createState() =>
      _PublishAnnouncementDialogState();
}

class _PublishAnnouncementDialogState
    extends State<_PublishAnnouncementDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _messageController;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(
      text: widget.initialTitle,
    );

    _messageController = TextEditingController(
      text: widget.initialMessage,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(
            Icons.campaign,
            color: Colors.green,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text('Publish Announcement'),
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'An announcement has been prepared using the '
                  'breakdown report details. Review and edit it '
                  'before publishing.',
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _titleController,
                  maxLength: 150,
                  decoration: const InputDecoration(
                    labelText: 'Announcement Title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an announcement title.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _messageController,
                  maxLines: 9,
                  decoration: const InputDecoration(
                    labelText: 'Announcement Message',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an announcement message.';
                    }

                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: () {
            if (!_formKey.currentState!.validate()) {
              return;
            }

            Navigator.pop(
              context,
              {
                'title': _titleController.text.trim(),
                'message': _messageController.text.trim(),
              },
            );
          },
          icon: const Icon(Icons.send),
          label: const Text('Publish'),
        ),
      ],
    );
  }
}
