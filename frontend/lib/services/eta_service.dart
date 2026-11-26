import 'dart:math' as math;

import '../models/route_stop.dart';
import '../models/bus_location.dart';

class EtaService {
  static const double averageSpeedKmh = 20.0;

  // Calculate distance in kilometres between two GPS coordinates.
  static double _distanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371.0;

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.pow(math.sin(dLon / 2), 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusKm * c;
  }

  static double _toRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  // Estimate remaining route distance from the bus to a destination stop.
  static double? remainingDistanceKm({
    required BusLocation busLocation,
    required List<RouteStop> routeStops,
    required int destinationStopId,
  }) {
    if (!busLocation.hasValidCoordinates) return null;

    final stops = routeStops.where((stop) => stop.hasValidCoordinates).toList()
      ..sort((a, b) => a.stopOrder.compareTo(b.stopOrder));

    if (stops.length < 2) return null;

    final destinationIndex = stops.indexWhere(
      (stop) => stop.stopId == destinationStopId,
    );

    if (destinationIndex < 0) return null;

    // Calculate the length of each route segment.
    final segmentLengths = <double>[];
    final cumulativeDistances = <double>[0];

    for (var i = 0; i < stops.length - 1; i++) {
      final length = _distanceKm(
        stops[i].latitude!,
        stops[i].longitude!,
        stops[i + 1].latitude!,
        stops[i + 1].longitude!,
      );

      segmentLengths.add(length);
      cumulativeDistances.add(cumulativeDistances.last + length);
    }

    // Find the closest point on the route to the current bus location.
    double nearestDistance = double.infinity;
    double busRoutePosition = 0;

    for (var i = 0; i < stops.length - 1; i++) {
      final start = stops[i];
      final end = stops[i + 1];

      final meanLatitude = _toRadians(
        (start.latitude! + end.latitude!) / 2,
      );

      final scaleX = math.cos(meanLatitude);

      final startX = start.longitude! * scaleX;
      final startY = start.latitude!;

      final endX = end.longitude! * scaleX;
      final endY = end.latitude!;

      final busX = busLocation.longitude * scaleX;
      final busY = busLocation.latitude;

      final dx = endX - startX;
      final dy = endY - startY;

      final segmentSquared = dx * dx + dy * dy;

      if (segmentSquared == 0) continue;

      var t = ((busX - startX) * dx + (busY - startY) * dy) / segmentSquared;

      t = t.clamp(0.0, 1.0);

      final projectedLatitude =
          start.latitude! + t * (end.latitude! - start.latitude!);

      final projectedLongitude =
          start.longitude! + t * (end.longitude! - start.longitude!);

      final distanceToBus = _distanceKm(
        busLocation.latitude,
        busLocation.longitude,
        projectedLatitude,
        projectedLongitude,
      );

      if (distanceToBus < nearestDistance) {
        nearestDistance = distanceToBus;

        busRoutePosition = cumulativeDistances[i] + t * segmentLengths[i];
      }
    }

    // Reject locations that are too far from this route.
    if (nearestDistance > 1.0) return null;

    final destinationDistance = cumulativeDistances[destinationIndex];

    final remaining = destinationDistance - busRoutePosition;

    // The selected stop is behind the bus.
    if (remaining < -0.02) return null;

    return math.max(0, remaining);
  }

  // Convert remaining distance into an estimated travel time.
  static int? estimatedMinutes({
    required BusLocation busLocation,
    required List<RouteStop> routeStops,
    required int destinationStopId,
  }) {
    final distance = remainingDistanceKm(
      busLocation: busLocation,
      routeStops: routeStops,
      destinationStopId: destinationStopId,
    );

    if (distance == null) return null;

    return (distance / averageSpeedKmh * 60).ceil();
  }
}
