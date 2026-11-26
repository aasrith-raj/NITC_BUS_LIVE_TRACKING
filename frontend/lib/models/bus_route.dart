class BusRoute {
  final int routeId;
  final String routeName;
  final String startLocation;
  final String endLocation;
  final bool isActive;

  const BusRoute({
    required this.routeId,
    required this.routeName,
    required this.startLocation,
    required this.endLocation,
    required this.isActive,
  });

  factory BusRoute.fromJson(Map<String, dynamic> json) {
    return BusRoute(
      routeId: (json['route_id'] as num).toInt(),
      routeName: (json['route_name'] ?? '').toString(),
      startLocation: (json['start_location'] ?? '').toString(),
      endLocation: (json['end_location'] ?? '').toString(),
      isActive: json['is_active'] as bool? ?? false,
    );
  }
}
