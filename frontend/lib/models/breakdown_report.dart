class BreakdownReport {
  final int reportId;
  final int busId;
  final int driverId;
  final String description;
  final DateTime? reportedAt;
  final String status;

  const BreakdownReport({
    required this.reportId,
    required this.busId,
    required this.driverId,
    required this.description,
    required this.reportedAt,
    required this.status,
  });

  factory BreakdownReport.fromJson(Map<String, dynamic> json) {
    return BreakdownReport(
      reportId: (json['report_id'] as num).toInt(),
      busId: (json['bus_id'] as num).toInt(),
      driverId: (json['driver_id'] as num).toInt(),
      description: (json['description'] ?? '').toString(),
      reportedAt: json['reported_at'] == null
          ? null
          : DateTime.tryParse(json['reported_at'].toString()),
      status: (json['status'] ?? 'REPORTED').toString().toUpperCase(),
    );
  }
}
