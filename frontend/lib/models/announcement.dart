class Announcement {
  final int announcementId;
  final String title;
  final String message;
  final int createdBy;
  final DateTime? createdAt;

  const Announcement({
    required this.announcementId,
    required this.title,
    required this.message,
    required this.createdBy,
    required this.createdAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      announcementId: (json['announcement_id'] as num).toInt(),
      title: (json['title'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      createdBy: (json['created_by'] as num).toInt(),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'].toString()),
    );
  }
}
