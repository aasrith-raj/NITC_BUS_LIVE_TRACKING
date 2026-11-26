import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/bus_route.dart';
import '../models/route_stop.dart';
import '../services/api_service.dart';

class RouteDetailsScreen extends StatefulWidget {
  final BusRoute route;

  const RouteDetailsScreen({
    super.key,
    required this.route,
  });

  @override
  State<RouteDetailsScreen> createState() => _RouteDetailsScreenState();
}

class _RouteDetailsScreenState extends State<RouteDetailsScreen> {
  final ApiService _api = ApiService();

  List<RouteStop> _stops = [];

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStops();
  }

  Future<void> _loadStops() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final stops = await _api.fetchOrderedRouteStops(
        widget.route.routeId,
      );

      if (!mounted) return;

      setState(() {
        _stops = stops;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Widget _buildRouteInformation() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.route.routeName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 14),
            _infoRow(
              Icons.trip_origin,
              'Starting point',
              widget.route.startLocation,
            ),
            const SizedBox(height: 10),
            _infoRow(
              Icons.location_on,
              'Destination',
              widget.route.endLocation,
            ),
            const SizedBox(height: 10),
            _infoRow(
              Icons.info_outline,
              'Status',
              widget.route.isActive ? 'Active' : 'Inactive',
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF176B87)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '$label: $value',
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildStopList() {
    if (_stops.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No stops have been assigned to this route yet.'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stops along this route',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...List.generate(_stops.length, (index) {
              final stop = _stops[index];

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 38,
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 15,
                          backgroundColor: const Color(0xFF176B87),
                          child: Text(
                            '${stop.stopOrder}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        if (index != _stops.length - 1)
                          Container(
                            width: 2,
                            height: 42,
                            color: Colors.grey.shade300,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 5, bottom: 22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stop.stopName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          if (stop.hasValidCoordinates)
                            Text(
                              '${stop.latitude}, ${stop.longitude}',
                              style: Theme.of(context).textTheme.bodySmall,
                            )
                          else
                            Text(
                              'Location coordinates unavailable',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMap() {
    final validStops =
        _stops.where((stop) => stop.hasValidCoordinates).toList();

    if (validStops.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Map unavailable because no valid stop coordinates exist.',
          ),
        ),
      );
    }

    final points = validStops
        .map(
          (stop) => LatLng(
            stop.latitude!,
            stop.longitude!,
          ),
        )
        .toList();

    final center = points.first;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 300,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: 15,
            minZoom: 5,
            maxZoom: 19,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.nitc_bus_tracking',
            ),
            if (points.length >= 2)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: points,
                    strokeWidth: 4,
                    color: const Color(0xFF176B87),
                  ),
                ],
              ),
            MarkerLayer(
              markers: List.generate(validStops.length, (index) {
                final stop = validStops[index];

                return Marker(
                  point: points[index],
                  width: 100,
                  height: 55,
                  child: Column(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 30,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${stop.stopOrder}. ${stop.stopName}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
            RichAttributionWidget(
              attributions: [
                TextSourceAttribution('OpenStreetMap contributors'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Details'),
        actions: [
          IconButton(
            onPressed: _loadStops,
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off, size: 45),
                        const SizedBox(height: 12),
                        const Text('Unable to load route stops.'),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _loadStops,
                          child: const Text('Try again'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadStops,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildRouteInformation(),
                      const SizedBox(height: 20),
                      _buildStopList(),
                      const SizedBox(height: 20),
                      Text(
                        'Route Map',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      _buildMap(),
                    ],
                  ),
                ),
    );
  }
}
