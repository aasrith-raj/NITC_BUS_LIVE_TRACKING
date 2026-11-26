class Assignment {
  final int assignmentId;
  final int routeId;
  final int busId;
  final int driverId;
  final DateTime assignmentDate;

  const Assignment({
    required this.assignmentId,
    required this.routeId,
    required this.busId,
    required this.driverId,
    required this.assignmentDate,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      assignmentId: (json['assignment_id'] as num).toInt(),
      routeId: (json['route_id'] as num).toInt(),
      busId: (json['bus_id'] as num).toInt(),
      driverId: (json['driver_id'] as num).toInt(),
      assignmentDate: DateTime.parse(
        json['assignment_date'].toString(),
      ),
    );
  }
}
