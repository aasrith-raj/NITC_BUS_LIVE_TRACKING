class BusSchedule {
  final int scheduleId;
  final int assignmentId;
  final String departureTime;
  final String arrivalTime;
  final String scheduleDay;

  const BusSchedule({
    required this.scheduleId,
    required this.assignmentId,
    required this.departureTime,
    required this.arrivalTime,
    required this.scheduleDay,
  });

  factory BusSchedule.fromJson(Map<String, dynamic> json) {
    return BusSchedule(
      scheduleId: (json['schedule_id'] as num).toInt(),
      assignmentId: (json['assignment_id'] as num).toInt(),
      departureTime: json['departure_time'].toString(),
      arrivalTime: json['arrival_time'].toString(),
      scheduleDay: json['schedule_day'].toString(),
    );
  }
}
