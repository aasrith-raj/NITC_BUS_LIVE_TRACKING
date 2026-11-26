import 'package:flutter/material.dart';

import '../services/api_service.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _users = [];

  bool _isLoading = true;
  String? _error;
  int? _currentUserId;

  String _selectedRole = 'ALL';

  final List<String> _roles = [
    'ALL',
    'STUDENT',
    'STAFF',
    'DRIVER',
    'ADMIN',
  ];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _api.fetchUsers(),
        _api.fetchCurrentUser(),
      ]);

      final users = results[0] as List<Map<String, dynamic>>;
      final currentUser = results[1] as Map<String, dynamic>;

      if (!mounted) return;

      setState(() {
        _users = users;
        _currentUserId = int.tryParse(currentUser['user_id'].toString());
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

  List<Map<String, dynamic>> get _filteredUsers {
    final query = _searchController.text.trim().toLowerCase();

    return _users.where((user) {
      final name = (user['name'] ?? '').toString().toLowerCase();
      final email = (user['email'] ?? '').toString().toLowerCase();
      final role = (user['role'] ?? '').toString().toUpperCase();

      final matchesSearch = name.contains(query) || email.contains(query);

      final matchesRole = _selectedRole == 'ALL' || role == _selectedRole;

      return matchesSearch && matchesRole;
    }).toList();
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _showEditDialog(
    Map<String, dynamic> user,
  ) async {
    final userId = (user['user_id'] as num).toInt();
    final isSelf = userId == _currentUserId;
    final isDriver = user['role'] == 'DRIVER';

    final nameController = TextEditingController(
      text: user['name']?.toString() ?? '',
    );

    final emailController = TextEditingController(
      text: user['email']?.toString() ?? '',
    );

    final passwordController = TextEditingController();

    final formKey = GlobalKey<FormState>();

    String selectedRole = (user['role'] ?? 'STUDENT').toString().toUpperCase();

    bool isSaving = false;
    bool userUpdated = false;

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('Edit User'),
                content: SizedBox(
                  width: 450,
                  child: SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: nameController,
                            decoration: const InputDecoration(
                              labelText: 'Full Name',
                              prefixIcon: Icon(Icons.person_outline),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Enter the user name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email Address',
                              prefixIcon: Icon(Icons.email_outlined),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              final email = value?.trim() ?? '';

                              if (email.isEmpty ||
                                  !email.contains('@') ||
                                  !email.contains('.')) {
                                return 'Enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          if (!isSelf && !isDriver)
                            DropdownButtonFormField<String>(
                              initialValue: selectedRole,
                              decoration: const InputDecoration(
                                labelText: 'User Role',
                                prefixIcon: Icon(Icons.security),
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'STUDENT',
                                  child: Text('Student'),
                                ),
                                DropdownMenuItem(
                                  value: 'STAFF',
                                  child: Text('Staff'),
                                ),
                                DropdownMenuItem(
                                  value: 'ADMIN',
                                  child: Text('Administrator'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setDialogState(() {
                                    selectedRole = value;
                                  });
                                }
                              },
                            ),
                          if (isSelf)
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Your administrator role cannot be changed here.',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          if (isDriver)
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Manage this account through Driver Management.',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'New Password (Optional)',
                              hintText: 'Leave blank to keep current password',
                              prefixIcon: Icon(Icons.lock_outline),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value != null &&
                                  value.isNotEmpty &&
                                  value.length < 8) {
                                return 'Password must contain at least 8 characters';
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
                    onPressed:
                        isSaving ? null : () => Navigator.pop(dialogContext),
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
                              await _api.updateUser(
                                userId: userId,
                                name: nameController.text,
                                email: emailController.text,
                                password: passwordController.text.isEmpty
                                    ? null
                                    : passwordController.text,
                                role: (!isSelf && !isDriver)
                                    ? selectedRole
                                    : null,
                              );

                              if (!dialogContext.mounted) return;

                              userUpdated = true;
                              Navigator.pop(dialogContext);
                            } catch (e) {
                              setDialogState(() {
                                isSaving = false;
                              });

                              _showMessage(
                                'Unable to update user: $e',
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
                        : const Text('Save Changes'),
                  ),
                ],
              );
            },
          );
        },
      );
      if (userUpdated && mounted) {
        // Allow the dialog closing animation to finish.
        await Future<void>.delayed(
          const Duration(milliseconds: 300),
        );

        if (!mounted) return;

        await _loadUsers();

        _showMessage('User updated successfully.');
      }
    } finally {
      // Dispose controllers only after the dialog has closed.
      await Future<void>.delayed(
        const Duration(milliseconds: 300),
      );

      nameController.dispose();
      emailController.dispose();
      passwordController.dispose();
    }
  }

  Future<void> _deleteUser(
    Map<String, dynamic> user,
  ) async {
    final userId = (user['user_id'] as num).toInt();

    if (userId == _currentUserId) {
      _showMessage('You cannot delete your own administrator account.');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
          'Are you sure you want to delete '
          '${user['name']}?\n\nThis action cannot be undone.',
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

    if (confirm != true) return;

    try {
      await _api.deleteUser(userId);
      await _loadUsers();
      _showMessage('User deleted successfully.');
    } catch (e) {
      _showMessage('Unable to delete user: $e');
    }
  }

  Color _roleColor(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return Colors.deepPurple;
      case 'DRIVER':
        return Colors.orange;
      case 'STAFF':
        return Colors.teal;
      default:
        return Colors.blue;
    }
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final userId = (user['user_id'] as num).toInt();
    final name = (user['name'] ?? 'Unknown').toString();
    final email = (user['email'] ?? '').toString();
    final role = (user['role'] ?? 'STUDENT').toString().toUpperCase();

    final isSelf = userId == _currentUserId;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: CircleAvatar(
          backgroundColor: _roleColor(role).withValues(alpha: 0.12),
          child: Icon(
            role == 'DRIVER'
                ? Icons.directions_bus
                : role == 'ADMIN'
                    ? Icons.admin_panel_settings
                    : Icons.person,
            color: _roleColor(role),
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(email),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Chip(
                    label: Text(role),
                    backgroundColor: _roleColor(role).withValues(alpha: 0.12),
                    labelStyle: TextStyle(
                      color: _roleColor(role),
                      fontWeight: FontWeight.bold,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  Text(
                    'ID: $userId',
                    style: const TextStyle(fontSize: 12),
                  ),
                  if (isSelf)
                    const Text(
                      'You',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              _showEditDialog(user);
            } else if (value == 'delete') {
              _deleteUser(user);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_outlined),
                  SizedBox(width: 10),
                  Text('Edit User'),
                ],
              ),
            ),
            if (!isSelf)
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red),
                    SizedBox(width: 10),
                    Text('Delete User'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = _filteredUsers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          IconButton(
            onPressed: _loadUsers,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh users',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUsers,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Registered Users',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 5),
            const Text(
              'View and manage student, staff, driver and administrator accounts.',
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or email',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                  icon: const Icon(Icons.clear),
                ),
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _selectedRole,
              decoration: const InputDecoration(
                labelText: 'Filter by Role',
                prefixIcon: Icon(Icons.filter_list),
                border: OutlineInputBorder(),
              ),
              items: _roles.map((role) {
                return DropdownMenuItem(
                  value: role,
                  child: Text(
                    role == 'ALL' ? 'All Users' : role,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedRole = value;
                  });
                }
              },
            ),
            const SizedBox(height: 18),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 40,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      FilledButton.icon(
                        onPressed: _loadUsers,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              Text(
                '${filteredUsers.length} user(s) found',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (filteredUsers.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text('No matching users found.'),
                    ),
                  ),
                )
              else
                ...filteredUsers.map(_buildUserCard),
            ],
          ],
        ),
      ),
    );
  }
}
