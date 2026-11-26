import 'package:flutter/material.dart';

import '../models/driver.dart';
import '../services/api_service.dart';

class DriverManagementScreen extends StatefulWidget {
  const DriverManagementScreen({super.key});

  @override
  State<DriverManagementScreen> createState() => _DriverManagementScreenState();
}

class _DriverManagementScreenState extends State<DriverManagementScreen> {
  final ApiService _api = ApiService();

  List<Driver> _drivers = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDrivers();
  }

  Future<void> _loadDrivers() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final drivers = await _api.fetchDrivers();

      if (!mounted) return;

      setState(() {
        _drivers = drivers;
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

  Future<void> _showDriverForm({Driver? driver}) async {
    final isEditing = driver != null;

    final formKey = GlobalKey<FormState>();

    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final licenseController = TextEditingController(
      text: driver?.licenseNumber ?? '',
    );

    bool isSaving = false;
    bool obscurePassword = true;

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: Text(
                  isEditing ? 'Edit Driver' : 'Add New Driver',
                ),
                content: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isEditing) ...[
                          TextFormField(
                            controller: nameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Driver Name',
                              prefixIcon: Icon(Icons.person),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Enter the driver name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'NITC Email',
                              hintText: 'driver@nitc.ac.in',
                              prefixIcon: Icon(Icons.email_outlined),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              final email = value?.trim().toLowerCase() ?? '';

                              if (!email.endsWith('@nitc.ac.in')) {
                                return 'Use a valid @nitc.ac.in email';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: passwordController,
                            obscureText: obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setDialogState(() {
                                    obscurePassword = !obscurePassword;
                                  });
                                },
                                icon: Icon(
                                  obscurePassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.length < 8) {
                                return 'Password must have at least 8 characters';
                              }

                              if (value.contains(RegExp(r'\s'))) {
                                return 'Password must not contain spaces';
                              }

                              if (!RegExp(r'[A-Z]').hasMatch(value) ||
                                  !RegExp(r'[a-z]').hasMatch(value) ||
                                  !RegExp(r'[0-9]').hasMatch(value) ||
                                  !RegExp(r'[^A-Za-z0-9\s]').hasMatch(value)) {
                                return 'Include uppercase, lowercase, number and special character';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                        ],
                        TextFormField(
                          controller: licenseController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            labelText: 'Driving License Number',
                            prefixIcon: Icon(Icons.badge_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Enter the license number';
                            }
                            return null;
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
                              if (isEditing) {
                                await _api.updateDriver(
                                  driverId: driver.driverId,
                                  licenseNumber: licenseController.text.trim(),
                                );
                              } else {
                                await _api.createDriverAccount(
                                  name: nameController.text.trim(),
                                  email: emailController.text.trim(),
                                  password: passwordController.text,
                                  licenseNumber: licenseController.text.trim(),
                                );
                              }

                              if (!dialogContext.mounted) return;

                              Navigator.pop(dialogContext);

                              if (!mounted) return;

                              _showMessage(
                                isEditing
                                    ? 'Driver updated successfully.'
                                    : 'Driver account created successfully.',
                              );

                              await _loadDrivers();
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
                        : Text(
                            isEditing ? 'Save Changes' : 'Create Driver',
                          ),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      nameController.dispose();
      emailController.dispose();
      passwordController.dispose();
      licenseController.dispose();
    }
  }

  Future<void> _deleteDriver(Driver driver) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Driver'),
        content: Text(
          'Are you sure you want to delete Driver ID ${driver.driverId}?',
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
      await _api.deleteDriver(driver.driverId);

      if (!mounted) return;

      _showMessage('Driver deleted successfully.');
      await _loadDrivers();
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Widget _buildDriverCard(Driver driver) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 25,
              child: Icon(Icons.person, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Driver ID: ${driver.driverId}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text('User ID: ${driver.userId}'),
                  const SizedBox(height: 5),
                  Text(
                    'License: ${driver.licenseNumber}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _showDriverForm(driver: driver);
                } else if (value == 'delete') {
                  _deleteDriver(driver);
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
        title: const Text('Driver Management'),
        actions: [
          IconButton(
            onPressed: _loadDrivers,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh drivers',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showDriverForm(),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Driver'),
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
                        const Icon(Icons.cloud_off, size: 45),
                        const SizedBox(height: 12),
                        const Text(
                          'Unable to load drivers.',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: _loadDrivers,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDrivers,
                  child: _drivers.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 130),
                            Icon(
                              Icons.people_outline,
                              size: 65,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 15),
                            Center(
                              child:
                                  Text('No drivers have been registered yet.'),
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
                              'Registered Drivers (${_drivers.length})',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 15),
                            ..._drivers.map(_buildDriverCard),
                          ],
                        ),
                ),
    );
  }
}
