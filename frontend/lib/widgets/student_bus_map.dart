import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/bus.dart';
import '../models/bus_location.dart';
import '../models/bus_stop.dart';

class StudentBusMap extends StatefulWidget {
  final List<Bus> buses;
  final List<BusLocation> locations;
  final List<BusStop> stops;

  const StudentBusMap({
    super.key,
    required this.buses,
    required this.locations,
    required this.stops,
  });

  @override
  State<StudentBusMap> createState() => _StudentBusMapState();
}

class _StudentBusMapState extends State<StudentBusMap> {
  final MapController _mapController = MapController();

  // Initial map center near NIT Calicut.
  static const LatLng _initialCenter = LatLng(11.3216, 75.9340);

  // Show bus details when a bus marker is tapped.
  void _showBusDetails(Bus bus, BusLocation location) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              bus.busNumber,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text('Status: ${bus.status}'),
            Text('Capacity: ${bus.capacity} passengers'),
            Text('Latitude: ${location.latitude}'),
            Text('Longitude: ${location.longitude}'),
            Text(
              'Last updated: '
              '${location.recordedAt?.toLocal() ?? 'Unavailable'}',
            ),
          ],
        ),
      ),
    );
  }

  // Show stop details when a stop marker is tapped.
  void _showStopDetails(BusStop stop) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              stop.stopName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            Text('Latitude: ${stop.latitude}'),
            Text('Longitude: ${stop.longitude}'),
          ],
        ),
      ),
    );
  }

  // Reset map to the initial campus location.
  void _resetMap() {
    _mapController.move(_initialCenter, 15);
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Create a lookup table for buses using their IDs.
    final busById = {
      for (final bus in widget.buses) bus.id: bus,
    };

    // ------------------------------------------------
    // GET LATEST VALID GPS LOCATION FOR EACH BUS
    // ------------------------------------------------

    final Map<int, BusLocation> latestLocations = {};

    for (final location in widget.locations) {
      // Ignore invalid GPS coordinates and unknown buses.
      if (!location.hasValidCoordinates ||
          !busById.containsKey(location.busId)) {
        continue;
      }

      final previous = latestLocations[location.busId];

      if (previous == null) {
        latestLocations[location.busId] = location;
      } else {
        final previousTime = previous.recordedAt;
        final currentTime = location.recordedAt;

        // Keep the record with the latest timestamp.
        if (currentTime != null &&
            (previousTime == null || currentTime.isAfter(previousTime))) {
          latestLocations[location.busId] = location;
        }
      }
    }

    final validLocations = latestLocations.values.toList();

    // Centre the map on the first available bus GPS location.
    // If no bus location exists, use the default campus position.
    final LatLng mapCenter = validLocations.isNotEmpty
        ? LatLng(
            validLocations.first.latitude,
            validLocations.first.longitude,
          )
        : _initialCenter;

    // ------------------------------------------------
    // FILTER VALID BUS STOPS
    // ------------------------------------------------

    final validStops = widget.stops.where(
      (stop) => stop.hasValidCoordinates,
    );

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: mapCenter,
            initialZoom: 15,
            minZoom: 5,
            maxZoom: 19,
          ),
          children: [
            // OpenStreetMap tiles.
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.nitc_bus_tracking',
            ),

            // Bus and stop markers.
            MarkerLayer(
              markers: [
                // --------------------------------------
                // BUS GPS MARKERS
                // --------------------------------------

                ...validLocations.map((location) {
                  final bus = busById[location.busId]!;

                  return Marker(
                    point: LatLng(
                      location.latitude,
                      location.longitude,
                    ),
                    width: 85,
                    height: 65,
                    child: GestureDetector(
                      onTap: () => _showBusDetails(bus, location),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.directions_bus,
                            color: Colors.blue,
                            size: 34,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              bus.busNumber,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                // --------------------------------------
                // BUS STOP MARKERS
                // --------------------------------------

                ...validStops.map((stop) {
                  return Marker(
                    point: LatLng(
                      stop.latitude!,
                      stop.longitude!,
                    ),
                    width: 90,
                    height: 55,
                    child: GestureDetector(
                      onTap: () => _showStopDetails(stop),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 30,
                          ),
                          Text(
                            stop.stopName,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),

            // OpenStreetMap attribution.
            RichAttributionWidget(
              attributions: [
                TextSourceAttribution(
                  'OpenStreetMap contributors',
                ),
              ],
            ),
          ],
        ),

        // Reset map button.
        Positioned(
          top: 12,
          right: 12,
          child: FloatingActionButton.small(
            heroTag: 'resetStudentMap',
            onPressed: _resetMap,
            tooltip: 'Reset map',
            child: const Icon(Icons.my_location),
          ),
        ),
      ],
    );
  }
}
