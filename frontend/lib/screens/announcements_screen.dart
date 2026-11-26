import 'package:flutter/material.dart';

import '../models/announcement.dart';
import '../services/api_service.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final ApiService _api = ApiService();

  List<Announcement> _announcements = [];

  bool _loading = true;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    try {
      final results = await Future.wait([
        _api.fetchAnnouncements(),
        _api.fetchCurrentUser(),
      ]);

      if (!mounted) return;

      final userData = results[1] as Map<String, dynamic>;

      setState(() {
        _announcements = results[0] as List<Announcement>;
        _currentUserId = (userData['user_id'] as num).toInt();
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

  String _formatDate(DateTime? date) {
    if (date == null) return 'Date unavailable';

    final local = date.toLocal();

    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year;

    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';

    return '$day/$month/$year at $hour:$minute $period';
  }

  Future<void> _showAnnouncementDialog({
    Announcement? announcement,
  }) async {
    final formKey = GlobalKey<FormState>();

    final titleController = TextEditingController(
      text: announcement?.title ?? '',
    );

    final messageController = TextEditingController(
      text: announcement?.message ?? '',
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          announcement == null ? 'Create Announcement' : 'Edit Announcement',
        ),
        content: SizedBox(
          width: 450,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    maxLength: 150,
                    decoration: const InputDecoration(
                      labelText: 'Announcement Title',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter an announcement title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: messageController,
                    minLines: 4,
                    maxLines: 7,
                    decoration: const InputDecoration(
                      labelText: 'Announcement Message',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.message),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter an announcement message';
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
              Navigator.pop(dialogContext, false);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: Text(
              announcement == null ? 'Publish' : 'Update',
            ),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      try {
        if (announcement == null) {
          if (_currentUserId == null) {
            throw Exception('Unable to identify the logged-in user.');
          }

          await _api.createAnnouncement(
            title: titleController.text,
            message: messageController.text,
            createdBy: _currentUserId!,
          );

          if (mounted) {
            _showMessage('Announcement published successfully.');
          }
        } else {
          await _api.updateAnnouncement(
            announcementId: announcement.announcementId,
            title: titleController.text,
            message: messageController.text,
          );

          if (mounted) {
            _showMessage('Announcement updated successfully.');
          }
        }

        await _loadData();
      } catch (e) {
        if (mounted) {
          _showMessage(e.toString());
        }
      }
    }

    titleController.dispose();
    messageController.dispose();
  }

  Future<void> _deleteAnnouncement(
    Announcement announcement,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Announcement'),
        content: Text(
          'Are you sure you want to delete '
          '"${announcement.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, false);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
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
      await _api.deleteAnnouncement(
        announcement.announcementId,
      );

      if (mounted) {
        _showMessage('Announcement deleted successfully.');
      }

      await _loadData();
    } catch (e) {
      if (mounted) {
        _showMessage(e.toString());
      }
    }
  }

  Widget _buildAnnouncementCard(Announcement announcement) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 7,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.campaign,
                  color: Colors.deepOrange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    announcement.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showAnnouncementDialog(
                        announcement: announcement,
                      );
                    } else if (value == 'delete') {
                      _deleteAnnouncement(announcement);
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
            Text(
              announcement.message,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 17,
                ),
                const SizedBox(width: 5),
                Text('Created by User #${announcement.createdBy}'),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  size: 17,
                ),
                const SizedBox(width: 5),
                Text(_formatDate(announcement.createdAt)),
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
        title: const Text('Announcements Management'),
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
          : _announcements.isEmpty
              ? const Center(
                  child: Text(
                    'No announcements found.\n'
                    'Tap + to publish an announcement.',
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
                    itemCount: _announcements.length,
                    itemBuilder: (context, index) {
                      return _buildAnnouncementCard(
                        _announcements[index],
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAnnouncementDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
