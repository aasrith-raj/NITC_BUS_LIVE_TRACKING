import 'package:flutter/material.dart';

import '../models/bus.dart';
import '../services/api_service.dart';

class BusManagementScreen extends StatefulWidget {
  const BusManagementScreen({super.key});

  @override
  State<BusManagementScreen> createState() => _BusManagementScreenState();
}

class _BusManagementScreenState extends State<BusManagementScreen> {
  final ApiService _api = ApiService();

  List<Bus> _buses = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBuses();
  }

  Future<void> _loadBuses() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final buses = await _api.fetchBuses();

      if (!mounted) return;

      setState(() {
        _buses = buses;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _showBusForm({Bus? bus}) async {
    final isEditing = bus != null;

    final formKey = GlobalKey<FormState>();

    final busNumberController = TextEditingController(
      text: bus?.busNumber ?? '',
    );

    final registrationNumberController = TextEditingController(
      text: bus?.registrationNumber ?? '',
    );

    final capacityController = TextEditingController(
      text: bus?.capacity.toString() ?? '',
    );

    String selectedStatus = bus?.status ?? 'ACTIVE';
    bool isSaving = false;

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: Text(isEditing ? 'Edit Bus' : 'Add New Bus'),
                content: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: busNumberController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            labelText: 'Bus Number',
                            hintText: 'Example: KL 11 AB 1234',
                            prefixIcon: Icon(Icons.directions_bus),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Enter the bus number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: registrationNumberController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            labelText: 'Registration Number (Optional)',
                            hintText: 'Example: KL 11 N 1234',
                            prefixIcon:
                                Icon(Icons.confirmation_number_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: capacityController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Seating Capacity',
                            prefixIcon: Icon(Icons.event_seat),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            final capacity = int.tryParse(
                              value?.trim() ?? '',
                            );

                            if (capacity == null || capacity <= 0) {
                              return 'Enter a valid capacity';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: selectedStatus,
                          decoration: const InputDecoration(
                            labelText: 'Bus Status',
                            prefixIcon: Icon(Icons.info_outline),
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'ACTIVE',
                              child: Text('Active'),
                            ),
                            DropdownMenuItem(
                              value: 'INACTIVE',
                              child: Text('Inactive'),
                            ),
                          ],
                          onChanged: (value) {
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
                    onPressed:
                        isSaving ? null : () => Navigator.pop(dialogContext),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (formKey.currentState?.validate() != true) {
                              return;
                            }

                            setDialogState(() {
                              isSaving = true;
                            });

                            try {
                              final busNumber =
                                  busNumberController.text.trim().toUpperCase();

                              final capacity = int.parse(
                                capacityController.text.trim(),
                              );

                              if (isEditing) {
                                await _api.updateBus(
                                  busId: bus.id,
                                  busNumber: busNumber,
                                  capacity: capacity,
                                  registrationNumber:
                                      registrationNumberController.text.trim(),
                                  status: selectedStatus,
                                );
                              } else {
                                await _api.createBus(
                                  busNumber: busNumber,
                                  capacity: capacity,
                                  registrationNumber:
                                      registrationNumberController.text.trim(),
                                  status: selectedStatus,
                                );
                              }

                              if (!dialogContext.mounted) return;

                              debugPrint('BUS UPDATE API SUCCESSFUL');
                              Navigator.pop(dialogContext);
                              debugPrint('BUS EDIT DIALOG CLOSED');

                              if (!mounted) return;

                              _showMessage(
                                isEditing
                                    ? 'Bus updated successfully.'
                                    : 'Bus added successfully.',
                              );

                              await _loadBuses();
                            } catch (e) {
                              if (!dialogContext.mounted) return;

                              setDialogState(() {
                                isSaving = false;
                              });

                              if (!mounted) return;

                              _showMessage(
                                e.toString().replaceFirst(
                                      'Exception: ',
                                      '',
                                    ),
                              );
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
                        : Text(isEditing ? 'Save Changes' : 'Add Bus'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      // Wait for the dialog's closing animation to finish.
      await Future<void>.delayed(
        const Duration(milliseconds: 300),
      );

      busNumberController.dispose();
      registrationNumberController.dispose();
      capacityController.dispose();
    }
  }

  Future<void> _deleteBus(Bus bus) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Bus'),
        content: Text(
          'Are you sure you want to delete ${bus.busNumber}?',
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
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      await _api.deleteBus(bus.id);

      if (!mounted) return;

      _showMessage('Bus deleted successfully.');
      await _loadBuses();
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Widget _buildBusCard(Bus bus) {
    final isActive = bus.status.toUpperCase() == 'ACTIVE';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: isActive
                  ? Colors.green.withValues(alpha: 0.12)
                  : Colors.grey.withValues(alpha: 0.15),
              child: Icon(
                Icons.directions_bus,
                color: isActive ? Colors.green : Colors.grey,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bus.busNumber,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text('Capacity: ${bus.capacity} passengers'),
                  if (bus.registrationNumber != null &&
                      bus.registrationNumber!.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text('Registration: ${bus.registrationNumber}'),
                  ],
                  const SizedBox(height: 5),
                  Text(
                    bus.status,
                    style: TextStyle(
                      color: isActive ? Colors.green : Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _showBusForm(bus: bus);
                } else if (value == 'delete') {
                  _deleteBus(bus);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined),
                      SizedBox(width: 10),
                      Text('Edit'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: Colors.red),
                      SizedBox(width: 10),
                      Text('Delete'),
                    ],
                  ),
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
        title: const Text('Bus Management'),
        actions: [
          IconButton(
            onPressed: _loadBuses,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh buses',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBusForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Bus'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
                          'Unable to load buses.',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: _loadBuses,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadBuses,
                  child: _buses.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 130),
                            Icon(
                              Icons.directions_bus_outlined,
                              size: 65,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 15),
                            Center(
                              child: Text('No buses have been added yet.'),
                            ),
                            SizedBox(height: 100),
                          ],
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(
                            16,
                            16,
                            16,
                            90,
                          ),
                          children: [
                            Text(
                              'Registered Buses (${_buses.length})',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 15),
                            ..._buses.map(_buildBusCard),
                          ],
                        ),
                ),
    );
  }
}
