import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'bus_management_screen.dart';
import 'driver_management_screen.dart';
import 'routes_stops_screen.dart';
import 'assignments_screen.dart';
import 'schedules_screen.dart';
import 'announcements_screen.dart';
import 'breakdown_reports_screen.dart';
import 'user_management_screen.dart';
import 'login_screen.dart';
import 'admin_management_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  Future<void> _logout(BuildContext context) async {
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

    if (confirm == true && context.mounted) {
      await ApiService().logout();

      if (!context.mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
        (route) => false,
      );
    }
  }

  Widget _buildManagementCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: CircleAvatar(
          child: Icon(icon),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios, size: 17),
        onTap: onTap ??
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$title module will be implemented next.'),
                ),
              );
            },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrator Dashboard'),
        actions: [
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Transport Management',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 5),
          const Text('Manage campus transport operations.'),
          const SizedBox(height: 20),
          _buildManagementCard(
            context: context,
            icon: Icons.directions_bus,
            title: 'Bus Management',
            description: 'Add, view, edit and delete buses.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BusManagementScreen(),
                ),
              );
            },
          ),
          _buildManagementCard(
            context: context,
            icon: Icons.person,
            title: 'Driver Management',
            description: 'Add, view, edit and delete driver accounts.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DriverManagementScreen(),
                ),
              );
            },
          ),
          _buildManagementCard(
            context: context,
            icon: Icons.route,
            title: 'Routes and Stops',
            description: 'Manage transport routes and stops.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const RoutesStopsScreen(),
                ),
              );
            },
          ),
          _buildManagementCard(
            context: context,
            icon: Icons.assignment_ind,
            title: 'Assignments',
            description: 'Assign drivers, buses and routes.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AssignmentsScreen(),
                ),
              );
            },
          ),
          _buildManagementCard(
            context: context,
            icon: Icons.schedule,
            title: 'Schedules',
            description: 'Manage bus departure and arrival schedules.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SchedulesScreen(),
                ),
              );
            },
          ),
          _buildManagementCard(
            context: context,
            icon: Icons.campaign,
            title: 'Announcements',
            description: 'Publish and manage campus transport updates.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AnnouncementsScreen(),
                ),
              );
            },
          ),
          _buildManagementCard(
            context: context,
            icon: Icons.warning_amber,
            title: 'Breakdown Reports',
            description: 'Review and manage reported breakdowns.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BreakdownReportsScreen(),
                ),
              );
            },
          ),
          _buildManagementCard(
            context: context,
            icon: Icons.people,
            title: 'User Management',
            description: 'View, search, edit and delete registered users.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const UserManagementScreen(),
                ),
              );
            },
          ),
          _buildManagementCard(
            context: context,
            icon: Icons.admin_panel_settings,
            title: 'Admin Management',
            description: 'Create and manage administrator accounts.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminManagementScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
