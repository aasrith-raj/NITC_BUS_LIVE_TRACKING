class RouteStop {
  final int routeId;
  final int stopId;
  final String stopName;
  final int stopOrder;
  final double? latitude;
  final double? longitude;
  final int departureOffsetMinutes;

  const RouteStop({
    required this.routeId,
    required this.stopId,
    required this.stopName,
    required this.stopOrder,
    this.latitude,
    this.longitude,
    this.departureOffsetMinutes = 0,
  });

  factory RouteStop.fromJson(Map<String, dynamic> json) {
    return RouteStop(
      routeId: (json['route_id'] as num).toInt(),
      stopId: (json['stop_id'] as num).toInt(),
      stopName: (json['stop_name'] ?? 'Unnamed stop').toString(),
      stopOrder: (json['stop_order'] as num).toInt(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      departureOffsetMinutes:
          (json['departure_offset_minutes'] as num?)?.toInt() ?? 0,
    );
  }

  bool get hasValidCoordinates {
    if (latitude == null || longitude == null) return false;

    return latitude! >= -90 &&
        latitude! <= 90 &&
        longitude! >= -180 &&
        longitude! <= 180 &&
        !(latitude == -90 && longitude == -180);
  }
}
