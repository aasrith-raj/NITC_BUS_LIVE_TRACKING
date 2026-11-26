import 'package:flutter/material.dart';

import '../models/bus_route.dart';
import '../models/bus_stop.dart';
import '../services/api_service.dart';

class RoutesStopsScreen extends StatefulWidget {
  const RoutesStopsScreen({super.key});

  @override
  State<RoutesStopsScreen> createState() => _RoutesStopsScreenState();
}

class _RoutesStopsScreenState extends State<RoutesStopsScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();

  late final TabController _tabController;

  List<BusRoute> _routes = [];
  List<BusStop> _stops = [];

  bool _loadingRoutes = true;
  bool _loadingStops = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRoutes();
    _loadStops();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _loadRoutes() async {
    setState(() => _loadingRoutes = true);
    try {
      final result = await _api.fetchRoutes();
      if (!mounted) return;
      setState(() => _routes = result);
    } catch (e) {
      _message(e.toString());
    } finally {
      if (mounted) setState(() => _loadingRoutes = false);
    }
  }

  Future<void> _loadStops() async {
    setState(() => _loadingStops = true);
    try {
      final result = await _api.fetchStops();
      if (!mounted) return;
      setState(() => _stops = result);
    } catch (e) {
      _message(e.toString());
    } finally {
      if (mounted) setState(() => _loadingStops = false);
    }
  }

  Future<bool> _confirmDelete(String title) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text('Delete $title?'),
            content: const Text(
              'Are you sure you want to delete this item?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _routeDialog({BusRoute? route}) async {
    final name = TextEditingController(text: route?.routeName ?? '');
    final start = TextEditingController(text: route?.startLocation ?? '');
    final end = TextEditingController(text: route?.endLocation ?? '');
    bool active = route?.isActive ?? true;

    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(route == null ? 'Add Route' : 'Edit Route'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: name,
                    decoration: const InputDecoration(
                      labelText: 'Route Name',
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Enter route name'
                        : null,
                  ),
                  TextFormField(
                    controller: start,
                    decoration: const InputDecoration(
                      labelText: 'Starting Location',
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Enter starting location'
                        : null,
                  ),
                  TextFormField(
                    controller: end,
                    decoration: const InputDecoration(
                      labelText: 'Ending Location',
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Enter ending location'
                        : null,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Active Route'),
                    value: active,
                    onChanged: (value) {
                      setDialogState(() => active = value);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                try {
                  if (route == null) {
                    await _api.createRoute(
                      routeName: name.text,
                      startLocation: start.text,
                      endLocation: end.text,
                      isActive: active,
                    );
                  } else {
                    await _api.updateRoute(
                      routeId: route.routeId,
                      routeName: name.text,
                      startLocation: start.text,
                      endLocation: end.text,
                      isActive: active,
                    );
                  }

                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);
                  await _loadRoutes();
                  _message(route == null
                      ? 'Route added successfully'
                      : 'Route updated successfully');
                } catch (e) {
                  _message(e.toString());
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    // Allow the dialog's closing animation to finish
    // before disposing its text controllers.
    await Future<void>.delayed(
      const Duration(milliseconds: 300),
    );

    name.dispose();
    start.dispose();
    end.dispose();
  }

  Future<void> _deleteRoute(BusRoute route) async {
    if (!await _confirmDelete(route.routeName)) return;

    try {
      await _api.deleteRoute(route.routeId);
      await _loadRoutes();
      _message('Route deleted successfully');
    } catch (e) {
      _message(e.toString());
    }
  }

  Future<void> _stopDialog({BusStop? stop}) async {
    final name = TextEditingController(text: stop?.stopName ?? '');
    final latitude = TextEditingController(
      text: stop?.latitude?.toString() ?? '',
    );
    final longitude = TextEditingController(
      text: stop?.longitude?.toString() ?? '',
    );

    final formKey = GlobalKey<FormState>();

    double? parseCoordinate(String value) {
      if (value.trim().isEmpty) return null;
      return double.tryParse(value.trim());
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(stop == null ? 'Add Stop' : 'Edit Stop'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: name,
                  decoration: const InputDecoration(
                    labelText: 'Stop Name',
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Enter stop name' : null,
                ),
                TextFormField(
                  controller: latitude,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Latitude (optional)',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final value = double.tryParse(v);
                    if (value == null || value < -90 || value > 90) {
                      return 'Enter latitude between -90 and 90';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: longitude,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Longitude (optional)',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final value = double.tryParse(v);
                    if (value == null || value < -180 || value > 180) {
                      return 'Enter longitude between -180 and 180';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final lat = parseCoordinate(latitude.text);
              final lng = parseCoordinate(longitude.text);

              if ((lat == null) != (lng == null)) {
                _message('Enter both coordinates, or leave both empty.');
                return;
              }

              try {
                if (stop == null) {
                  await _api.createStop(
                    stopName: name.text,
                    latitude: lat,
                    longitude: lng,
                  );
                } else {
                  await _api.updateStop(
                    stopId: stop.id,
                    stopName: name.text,
                    latitude: lat,
                    longitude: lng,
                  );
                }

                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                await _loadStops();
                _message(stop == null
                    ? 'Stop added successfully'
                    : 'Stop updated successfully');
              } catch (e) {
                _message(e.toString());
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    // Allow the dialog's closing animation to finish
    // before disposing its text controllers.
    await Future<void>.delayed(
      const Duration(milliseconds: 300),
    );

    name.dispose();
    latitude.dispose();
    longitude.dispose();
  }

  Future<void> _deleteStop(BusStop stop) async {
    if (!await _confirmDelete(stop.stopName)) return;

    try {
      await _api.deleteStop(stop.id);
      await _loadStops();
      _message('Stop deleted successfully');
    } catch (e) {
      _message(e.toString());
    }
  }

  Widget _routeList() {
    if (_loadingRoutes) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_routes.isEmpty) {
      return const Center(child: Text('No routes found.'));
    }

    return RefreshIndicator(
      onRefresh: _loadRoutes,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _routes.length,
        itemBuilder: (context, index) {
          final route = _routes[index];

          return Card(
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.route),
              ),
              title: Text(
                route.routeName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${route.startLocation} → ${route.endLocation}\n'
                '${route.isActive ? 'Active' : 'Inactive'}',
              ),
              isThreeLine: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RouteStopsScreen(route: route),
                  ),
                );
              },
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') _routeDialog(route: route);
                  if (value == 'delete') _deleteRoute(route);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit'),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _stopList() {
    if (_loadingStops) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_stops.isEmpty) {
      return const Center(child: Text('No stops found.'));
    }

    return RefreshIndicator(
      onRefresh: _loadStops,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _stops.length,
        itemBuilder: (context, index) {
          final stop = _stops[index];

          return Card(
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.location_on),
              ),
              title: Text(
                stop.stopName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                stop.hasValidCoordinates
                    ? 'Lat: ${stop.latitude}, Long: ${stop.longitude}'
                    : 'Coordinates not available',
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') _stopDialog(stop: stop);
                  if (value == 'delete') _deleteStop(stop);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit'),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Routes and Stops'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.route), text: 'Routes'),
            Tab(icon: Icon(Icons.location_on), text: 'Stops'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _routeList(),
          _stopList(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tabController.index == 0) {
            _routeDialog();
          } else {
            _stopDialog();
          }
        },
        icon: const Icon(Icons.add),
        label: Text(
          _tabController.index == 0 ? 'Add Route' : 'Add Stop',
        ),
      ),
    );
  }
}

// ==================================================
// ROUTE STOPS SCREEN
// ==================================================

class RouteStopsScreen extends StatefulWidget {
  final BusRoute route;

  const RouteStopsScreen({
    super.key,
    required this.route,
  });

  @override
  State<RouteStopsScreen> createState() => _RouteStopsScreenState();
}

class _RouteStopsScreenState extends State<RouteStopsScreen> {
  final ApiService _api = ApiService();

  List<BusStop> _routeStops = [];
  List<BusStop> _allStops = [];

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    try {
      final results = await Future.wait([
        _api.fetchRouteStops(widget.route.routeId),
        _api.fetchStops(),
      ]);

      if (!mounted) return;

      setState(() {
        _routeStops = results[0];
        _allStops = results[1];
      });
    } catch (e) {
      _message(e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _addStop() async {
    final assignedIds = _routeStops.map((s) => s.id).toSet();
    final available =
        _allStops.where((s) => !assignedIds.contains(s.id)).toList();

    if (available.isEmpty) {
      _message('No unassigned stops available. Add a stop first.');
      return;
    }

    BusStop selected = available.first;
    final orderController = TextEditingController(
      text: (_routeStops.length + 1).toString(),
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Stop to Route'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<BusStop>(
                initialValue: selected,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Select Stop'),
                items: available.map((stop) {
                  return DropdownMenuItem(
                    value: stop,
                    child: Text(stop.stopName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => selected = value);
                  }
                },
              ),
              TextField(
                controller: orderController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Stop Order',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final order = int.tryParse(orderController.text);

                if (order == null || order <= 0) {
                  _message('Enter a valid stop order greater than zero.');
                  return;
                }

                try {
                  await _api.addStopToRoute(
                    routeId: widget.route.routeId,
                    stopId: selected.id,
                    stopOrder: order,
                  );

                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);
                  await _loadData();
                  _message('Stop added to route');
                } catch (e) {
                  _message(e.toString());
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    await Future<void>.delayed(
      const Duration(milliseconds: 300),
    );

    orderController.dispose();
  }

  Future<void> _changeOrder(BusStop stop, int currentOrder) async {
    final controller = TextEditingController(
      text: currentOrder.toString(),
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Change order: ${stop.stopName}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'New Stop Order',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final order = int.tryParse(controller.text);

              if (order == null || order <= 0) {
                _message('Enter an order greater than zero.');
                return;
              }

              try {
                await _api.updateRouteStopOrder(
                  routeId: widget.route.routeId,
                  stopId: stop.id,
                  stopOrder: order,
                );

                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                await _loadData();
                _message('Stop order updated');
              } catch (e) {
                _message(e.toString());
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );

    await Future<void>.delayed(
      const Duration(milliseconds: 300),
    );

    controller.dispose();
  }

  Future<void> _removeStop(BusStop stop) async {
    final confirm = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Remove Stop'),
            content: Text(
              'Remove ${stop.stopName} from this route?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Remove'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    try {
      await _api.removeStopFromRoute(
        routeId: widget.route.routeId,
        stopId: stop.id,
      );
      await _loadData();
      _message('Stop removed from route');
    } catch (e) {
      _message(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.route.routeName),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _routeStops.isEmpty
              ? const Center(
                  child: Text('No stops assigned to this route yet.'),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _routeStops.length,
                    itemBuilder: (context, index) {
                      final stop = _routeStops[index];

                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text('${index + 1}'),
                          ),
                          title: Text(
                            stop.stopName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            stop.hasValidCoordinates
                                ? 'Lat: ${stop.latitude}, Long: ${stop.longitude}'
                                : 'Coordinates unavailable',
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'order') {
                                _changeOrder(stop, index + 1);
                              }
                              if (value == 'remove') {
                                _removeStop(stop);
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'order',
                                child: Text('Change Order'),
                              ),
                              PopupMenuItem(
                                value: 'remove',
                                child: Text('Remove from Route'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading ? null : _addStop,
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Add Stop'),
      ),
    );
  }
}
