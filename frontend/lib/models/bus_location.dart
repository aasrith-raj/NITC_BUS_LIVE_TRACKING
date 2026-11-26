class BusLocation {
  final int locationId;
  final int busId;
  final double latitude;
  final double longitude;
  final DateTime? recordedAt;

  const BusLocation({
    required this.locationId,
    required this.busId,
    required this.latitude,
    required this.longitude,
    required this.recordedAt,
  });

  factory BusLocation.fromJson(Map<String, dynamic> json) {
    return BusLocation(
      locationId: (json['location_id'] as num).toInt(),
      busId: (json['bus_id'] as num).toInt(),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      recordedAt: json['recorded_at'] == null
          ? null
          : DateTime.tryParse(json['recorded_at'].toString()),
    );
  }

  bool get hasValidCoordinates {
    return latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180 &&
        !(latitude == -90 && longitude == -180);
  }
}
