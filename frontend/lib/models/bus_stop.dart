class BusStop {
  final int id;
  final String stopName;
  final double? latitude;
  final double? longitude;
  final int departureOffsetMinutes;

  const BusStop({
    required this.id,
    required this.stopName,
    required this.latitude,
    required this.longitude,
    this.departureOffsetMinutes = 0,
  });

  factory BusStop.fromJson(Map<String, dynamic> json) {
    return BusStop(
      id: (json['stop_id'] as num).toInt(),
      stopName: (json['stop_name'] ?? 'Unnamed stop').toString().trim(),
      latitude: json['latitude'] == null
          ? null
          : (json['latitude'] as num).toDouble(),
      longitude: json['longitude'] == null
          ? null
          : (json['longitude'] as num).toDouble(),
      departureOffsetMinutes:
          (json['departure_offset_minutes'] as num?)?.toInt() ?? 0,
    );
  }

  bool get hasValidCoordinates {
    if (latitude == null || longitude == null) return false;

    return latitude! >= -90 &&
        latitude! <= 90 &&
        longitude! >= -180 &&
        longitude! <= 180;
  }
}
