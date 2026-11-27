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
    this.recordedAt,
  });

  /// Parses the timestamp returned by FastAPI.
  ///
  bool get hasValidCoordinates {
    return latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180 &&
        !(latitude == 0 && longitude == 0);
  }

  /// MySQL DATETIME does not store timezone information.
  /// In this project, timestamps without a timezone are treated as UTC.
  static DateTime? _parseUtcTimestamp(dynamic value) {
    if (value == null) return null;

    final timestamp = value.toString().trim();
    if (timestamp.isEmpty) return null;

    // Check whether the timestamp already contains a timezone.
    final hasTimezone = RegExp(
      r'(Z|[+-]\d{2}:\d{2})$',
      caseSensitive: false,
    ).hasMatch(timestamp);

    final normalizedTimestamp = hasTimezone ? timestamp : '${timestamp}Z';

    final parsed = DateTime.tryParse(normalizedTimestamp);

    return parsed?.toUtc();
  }

  factory BusLocation.fromJson(Map<String, dynamic> json) {
    return BusLocation(
      locationId: (json['location_id'] as num).toInt(),
      busId: (json['bus_id'] as num).toInt(),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      recordedAt: _parseUtcTimestamp(json['recorded_at']),
    );
  }
}
