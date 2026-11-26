class Bus {
  final int id;
  final String busNumber;
  final String? registrationNumber;
  final int capacity;
  final String status;

  const Bus({
    required this.id,
    required this.busNumber,
    this.registrationNumber,
    required this.capacity,
    required this.status,
  });

  factory Bus.fromJson(Map<String, dynamic> json) {
    return Bus(
      id: (json['bus_id'] as num).toInt(),
      busNumber: (json['bus_number'] ?? 'Unknown').toString().trim(),
      registrationNumber: json['registration_number']?.toString().trim(),
      capacity: (json['capacity'] as num?)?.toInt() ?? 0,
      status: (json['status'] ?? 'UNKNOWN').toString().trim(),
    );
  }
}
