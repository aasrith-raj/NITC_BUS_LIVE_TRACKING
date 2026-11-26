class Driver {
  final int driverId;
  final int userId;
  final String licenseNumber;

  const Driver({
    required this.driverId,
    required this.userId,
    required this.licenseNumber,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      driverId: (json['driver_id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      licenseNumber: (json['license_number'] ?? '').toString(),
    );
  }
}
