import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  // Check GPS availability and request location permission.
  Future<void> _checkPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception(
        'Please enable location services on your phone.',
      );
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission is required. Please enable it in Settings.',
      );
    }
  }

  // Get one GPS position.
  Future<Position> getCurrentPosition() async {
    await _checkPermission();

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  // Android foreground service notification configuration.
  LocationSettings _getLocationSettings() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
        intervalDuration: const Duration(seconds: 5),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'NITC Bus Tracking',
          notificationText: 'Your bus location is being shared with students.',
          enableWakeLock: true,
          setOngoing: true,
        ),
      );
    }

    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );
  }

  // Get a continuous GPS stream.
  // On Android, this uses a foreground service with a notification.
  Future<Stream<Position>> getPositionStream() async {
    await _checkPermission();

    return Geolocator.getPositionStream(
      locationSettings: _getLocationSettings(),
    );
  }
}
