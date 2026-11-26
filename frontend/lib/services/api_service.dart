import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../models/announcement.dart';
import '../models/bus.dart';
import '../models/bus_location.dart';
import '../models/bus_route.dart';
import '../models/bus_stop.dart';
import '../models/driver.dart';
import '../models/assignment.dart';
import '../models/schedule.dart';
import '../models/breakdown_report.dart';
import '../models/route_stop.dart';

class ApiService {
  // Android emulator address for accessing the computer's backend.
  static const String baseUrl = 'http://10.0.2.2:8000';

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _tokenKey = 'access_token';

  // --------------------------------------------------
  // COMMON METHODS
  // --------------------------------------------------

  // Extract useful error messages from FastAPI.
  String _getErrorMessage(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map && decoded['detail'] != null) {
        final detail = decoded['detail'];

        if (detail is String) {
          return detail;
        }

        if (detail is List) {
          return detail
              .map((e) => e is Map ? e['msg'] : e.toString())
              .join(', ');
        }
      }
    } catch (_) {
      // Use the default message below.
    }

    return 'Request failed (${response.statusCode})';
  }

  // Common request headers, including the stored JWT when available.
  Future<Map<String, String>> _headers() async {
    final token = await getToken();

    return {
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // Common GET request.
  Future<http.Response> _get(String endpoint) async {
    final response = await http
        .get(
          Uri.parse('$baseUrl$endpoint'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(_getErrorMessage(response));
    }

    return response;
  }

  // Decode a GET response that should contain a JSON list.
  Future<List<dynamic>> _getList(String endpoint) async {
    final response = await _get(endpoint);
    final decoded = jsonDecode(response.body);

    if (decoded is! List) {
      throw FormatException(
        'Expected a list from $endpoint',
      );
    }

    return decoded;
  }

  // --------------------------------------------------
  // LOGIN
  // --------------------------------------------------

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/login'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'email': email.trim(),
            'password': password,
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(_getErrorMessage(response));
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    final token = data['access_token'] as String?;

    if (token == null || token.isEmpty) {
      throw Exception(
        'Login response did not contain an access token.',
      );
    }

    await _storage.write(
      key: _tokenKey,
      value: token,
    );

    return data;
  }

  // --------------------------------------------------
  // SIGNUP
  // --------------------------------------------------

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/users'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'name': name.trim(),
            'email': email.trim(),
            'password': password,
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 201) {
      throw Exception(_getErrorMessage(response));
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // --------------------------------------------------
  // TOKEN MANAGEMENT
  // --------------------------------------------------

  Future<String?> getToken() async {
    return _storage.read(key: _tokenKey);
  }

  // --------------------------------------------------
  // FIREBASE CLOUD MESSAGING
  // --------------------------------------------------

  // POST /fcm/register
  // Registers the current device's FCM token with FastAPI.

  Future<Map<String, dynamic>> registerFcmToken({
    required String installationId,
    String deviceType = 'ANDROID',
  }) async {
    if (installationId.trim().isEmpty) {
      throw Exception('Firebase Installation ID is empty.');
    }

    final response = await http
        .post(
          Uri.parse('$baseUrl/fcm/register'),
          headers: {
            ...await _headers(),
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'token': installationId.trim(),
            'device_type': deviceType,
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_getErrorMessage(response));
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
  }

  // --------------------------------------------------
  // ADMIN - BUS MANAGEMENT APIs
  // --------------------------------------------------

  // POST /buses - Add a new bus.

  Future<Map<String, dynamic>> createBus({
    required String busNumber,
    String? registrationNumber,
    required int capacity,
    required String status,
  }) async {
    final body = <String, dynamic>{
      'bus_number': busNumber.trim(),
      'capacity': capacity,
      'status': status,
      'registration_number': registrationNumber?.trim().isEmpty == true
          ? null
          : registrationNumber?.trim().toUpperCase(),
    };

    final response = await http
        .post(
          Uri.parse('$baseUrl/buses'),
          headers: {
            ...await _headers(),
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_getErrorMessage(response));
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateBus({
    required int busId,
    required String busNumber,
    String? registrationNumber,
    required int capacity,
    required String status,
  }) async {
    final body = <String, dynamic>{
      'bus_number': busNumber.trim(),
      'capacity': capacity,
      'status': status,
    };

    if (registrationNumber != null) {
      body['registration_number'] = registrationNumber.trim().isEmpty
          ? null
          : registrationNumber.trim().toUpperCase();
    }

    final response = await http
        .patch(
          Uri.parse('$baseUrl/buses/$busId'),
          headers: {
            ...await _headers(),
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(_getErrorMessage(response));
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // DELETE /buses/{bus_id} - Delete a bus.
  Future<void> deleteBus(int busId) async {
    final response = await http
        .delete(
          Uri.parse('$baseUrl/buses/$busId'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(_getErrorMessage(response));
    }
  }

  // --------------------------------------------------
  // STUDENT APIs
  // --------------------------------------------------

  // GET /buses
  Future<List<Bus>> fetchBuses() async {
    final data = await _getList('/buses');

    return data
        .map((item) => Bus.fromJson(
              item as Map<String, dynamic>,
            ))
        .toList();
  }

  // GET /routes
  Future<List<BusRoute>> fetchRoutes() async {
    final data = await _getList('/routes');

    return data
        .map((item) => BusRoute.fromJson(
              item as Map<String, dynamic>,
            ))
        .toList();
  }

  // GET /stops
  Future<List<BusStop>> fetchStops() async {
    final data = await _getList('/stops');

    return data
        .map((item) => BusStop.fromJson(
              item as Map<String, dynamic>,
            ))
        .toList();
  }

  // GET /bus-locations
  Future<List<BusLocation>> fetchBusLocations() async {
    final data = await _getList('/bus-locations');

    return data
        .map((item) => BusLocation.fromJson(
              item as Map<String, dynamic>,
            ))
        .toList();
  }

  // GET /bus-locations/latest
  // Fetches only the latest GPS location for each bus.
  Future<List<BusLocation>> fetchLatestBusLocations() async {
    final data = await _getList('/bus-locations/latest');

    return data
        .map((item) => BusLocation.fromJson(
              item as Map<String, dynamic>,
            ))
        .toList();
  }

  // GET /announcements
  Future<List<Announcement>> fetchAnnouncements() async {
    final data = await _getList('/announcements');

    return data
        .map((item) => Announcement.fromJson(
              item as Map<String, dynamic>,
            ))
        .toList();
  }

  // --------------------------------------------------
  // ADMIN - ANNOUNCEMENT MANAGEMENT APIs
  // --------------------------------------------------

  // POST /announcements
  Future<Map<String, dynamic>> createAnnouncement({
    required String title,
    required String message,
    required int createdBy,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/announcements'),
          headers: {
            ...await _headers(),
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'title': title.trim(),
            'message': message.trim(),
            'created_by': createdBy,
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_getErrorMessage(response));
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // PATCH /announcements/{announcement_id}
  Future<Map<String, dynamic>> updateAnnouncement({
    required int announcementId,
    required String title,
    required String message,
  }) async {
    final response = await http
        .patch(
          Uri.parse('$baseUrl/announcements/$announcementId'),
          headers: {
            ...await _headers(),
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'title': title.trim(),
            'message': message.trim(),
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(_getErrorMessage(response));
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // DELETE /announcements/{announcement_id}
  Future<void> deleteAnnouncement(int announcementId) async {
    final response = await http
        .delete(
          Uri.parse('$baseUrl/announcements/$announcementId'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(_getErrorMessage(response));
    }
  }

  // GET /routes/{route_id}/stops

  Future<List<BusStop>> fetchRouteStops(int routeId) async {
    final data = await _getList('/routes/$routeId/stops');

    return data.map((item) {
      final json = item as Map<String, dynamic>;

      return BusStop.fromJson({
        'stop_id': json['stop_id'],
        'stop_name': json['stop_name'],
        'latitude': json['latitude'],
        'longitude': json['longitude'],
        'departure_offset_minutes': json['departure_offset_minutes'],
      });
    }).toList();
  }

  // GET /routes/{route_id}/stops
  // Fetch route stops with their actual stop order.
  Future<List<RouteStop>> fetchOrderedRouteStops(int routeId) async {
    final data = await _getList('/routes/$routeId/stops');

    final stops = data
        .map(
          (item) => RouteStop.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();

    // Always display stops in ascending order.
    stops.sort((a, b) {
      final orderComparison = a.stopOrder.compareTo(b.stopOrder);

      if (orderComparison != 0) return orderComparison;

      return a.stopId.compareTo(b.stopId);
    });

    return stops;
  }

  // --------------------------------------------------
  // DRIVER APIs
  // --------------------------------------------------

  // GET /test-auth
  // Retrieves the currently authenticated user.
  Future<Map<String, dynamic>> fetchCurrentUser() async {
    final response = await _get('/test-auth');

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'Invalid current-user response',
      );
    }

    return decoded;
  }

  // --------------------------------------------------
  // ADMIN - ADMINISTRATOR MANAGEMENT APIs
  // --------------------------------------------------

  // POST /admin/create-admin
  // Creates a new administrator account.
  Future<Map<String, dynamic>> createAdminAccount({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/admin/create-admin'),
          headers: {
            ...await _headers(),
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'name': name.trim(),
            'email': email.trim().toLowerCase(),
            'password': password,
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 201) {
      throw Exception(_getErrorMessage(response));
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // --------------------------------------------------
  // ADMIN - DRIVER MANAGEMENT APIs
  // --------------------------------------------------

  // POST /admin/create-driver
  // Creates a driver login account and driver profile.
  Future<Map<String, dynamic>> createDriverAccount({
    required String name,
    required String email,
    required String password,
    required String licenseNumber,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/admin/create-driver'),
          headers: {
            ...await _headers(),
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'name': name.trim(),
            'email': email.trim().toLowerCase(),
            'password': password,
            'license_number': licenseNumber.trim(),
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 201) {
      throw Exception(_getErrorMessage(response));
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // PATCH /drivers/{driver_id}
  // Updates the driver's license number.
  Future<Map<String, dynamic>> updateDriver({
    required int driverId,
    required String licenseNumber,
  }) async {
    final response = await http
        .patch(
          Uri.parse('$baseUrl/drivers/$driverId'),
          headers: {
            ...await _headers(),
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'license_number': licenseNumber.trim(),
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(_getErrorMessage(response));
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // DELETE /drivers/{driver_id}
  Future<void> deleteDriver(int driverId) async {
    final response = await http
        .delete(
          Uri.parse('$baseUrl/drivers/$driverId'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(_getErrorMessage(response));
    }
  }

  // GET /drivers
  Future<List<Driver>> fetchDrivers() async {
    final data = await _getList('/drivers');

    return data
        .map((item) => Driver.fromJson(
              item as Map<String, dynamic>,
            ))
        .toList();
  }

  // GET /assignments
  Future<List<Assignment>> fetchAssignments() async {
    final data = await _getList('/assignments');

    return data
        .map((item) => Assignment.fromJson(
              item as Map<String, dynamic>,
            ))
        .toList();
  }

  // --------------------------------------------------
  // ADMIN - ASSIGNMENT MANAGEMENT APIs
  // --------------------------------------------------

  // POST /assignments - Create an assignment.
  Future<Map<String, dynamic>> createAssignment({
    required int busId,
    required int driverId,
    required int routeId,
    required DateTime assignmentDate,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/assignments'),
          headers: {
            ...await _headers(),
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'bus_id': busId,
            'driver_id': driverId,
            'route_id': routeId,
            'assignment_date':
                '${assignmentDate.year.toString().padLeft(4, '0')}-'
                    '${assignmentDate.month.toString().padLeft(2, '0')}-'
                    '${assignmentDate.day.toString().padLeft(2, '0')}',
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_getErrorMessage(response));
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // PATCH /assignments/{assignment_id} - Update an assignment.
  Future<Map<String, dynamic>> updateAssignment({
    required int assignmentId,
    required int busId,
    required int driverId,
    required int routeId,
    required DateTime assignmentDate,
  }) async {
    final response = await http
        .patch(
          Uri.parse('$baseUrl/assignments/$assignmentId'),
          headers: {
            ...await _headers(),
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'bus_id': busId,
            'driver_id': driverId,
            'route_id': routeId,
            'assignment_date':
                '${assignmentDate.year.toString().padLeft(4, '0')}-'
                    '${assignmentDate.month.toString().padLeft(2, '0')}-'
                    '${assignmentDate.day.toString().padLeft(2, '0')}',
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(_getErrorMessage(response));
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // DELETE /assignments/{assignment_id} - Delete an assignment.
  Future<void> deleteAssignment(int assignmentId) async {
    final response = await http
        .delete(
          Uri.parse('$baseUrl/assignments/$assignmentId'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(_getErrorMessage(response));
    }
  }

  // --------------------------------------------------
  // ADMIN - SCHEDULE MANAGEMENT APIs
  // --------------------------------------------------

  // GET /schedules
  Future<List<BusSchedule>> fetchSchedules() async {
    final data = await _getList('/schedules');

    return data
        .map((item) => BusSchedule.fromJson(
              item as Map<String, dynamic>,
            ))
        .toList();
  }

  // POST /schedules
  Future<Map<String, dynamic>> createSchedule({
    required int assignmentId,
    required String departureTime,
    required String arrivalTime,
    required String scheduleDay,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/schedules'),
          headers: {
            ...await _headers(),
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'assignment_id': assignmentId,
            'departure_time': departureTime,
            'arrival_time': arrivalTime,
            'schedule_day': scheduleDay,
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_getErrorMessage(response));
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // PATCH /schedules/{schedule_id}
  Future<Map<String, dynamic>> updateSchedule({
    required int scheduleId,
    required int assignmentId,
    required String departureTime,
    required String arrivalTime,
    required String scheduleDay,
  }) async {
    final response = await http
        .patch(
          Uri.parse('$baseUrl/schedules/$scheduleId'),
          headers: {
            ...await _headers(),
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'assignment_id': assignmentId,
            'departure_time': departureTime,
            'arrival_time': arrivalTime,
            'schedule_day': scheduleDay,
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(_getErrorMessage(response));
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // DELETE /schedules/{schedule_id}
  Future<void> deleteSchedule(int scheduleId) async {
    final response = await http
        .delete(
          Uri.parse('$baseUrl/schedules/$scheduleId'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(_getErrorMessage(response));
    }
  }

  // POST /bus-locations
  // Uploads the driver's GPS coordinates to the backend.
  Future<void> uploadBusLocation({
    required int busId,
    required double latitude,
    required double longitude,
    required DateTime recordedAt,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/bus-locations'),
          headers: {
            ...await _headers(),
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'bus_id': busId,
            'latitude': latitude,
            'longitude': longitude,
            'recorded_at': recordedAt.toIso8601String(),
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 201) {
      throw Exception(_getErrorMessage(response));
    }
  }

  // POST /breakdown-reports
  // Submits a bus breakdown report.
  Future<Map<String, dynamic>> submitBreakdownReport({
    required int busId,
    required int driverId,
    required String description,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/breakdown-reports'),
          headers: {
            ...await _headers(),
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'bus_id': busId,
            'driver_id': driverId,
            'description': description.trim(),
            'status': 'REPORTED',
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 201) {
      throw Exception(_getErrorMessage(response));
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // GET /breakdown-reports
  Future<List<BreakdownReport>> fetchBreakdownReports() async {
    final data = await _getList('/breakdown-reports');

    return data
        .map((item) => BreakdownReport.fromJson(
              item as Map<String, dynamic>,
            ))
        .toList();
  }

  // PATCH /breakdown-reports/{report_id}
  Future<Map<String, dynamic>> updateBreakdownReport({
    required int reportId,
    required int busId,
    required int driverId,
    required String description,
    required String status,
  }) async {
    final response = await http
        .patch(
          Uri.parse('$baseUrl/breakdown-reports/$reportId'),
          headers: {
            ...await _headers(),
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'bus_id': busId,
            'driver_id': driverId,
            'description': description.trim(),
            'status': status,
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(_getErrorMessage(response));
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // DELETE /breakdown-reports/{report_id}
  Future<void> deleteBreakdownReport(int reportId) async {
    final response = await http
        .delete(
          Uri.parse('$baseUrl/breakdown-reports/$reportId'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(_getErrorMessage(response));
    }
  }

  // --------------------------------------------------
  // ADMIN - ROUTE MANAGEMENT APIs
  // --------------------------------------------------

  // POST /routes
  Future<Map<String, dynamic>> createRoute({
    required String routeName,
    required String startLocation,
    required String endLocation,
    required bool isActive,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/routes'),
          headers: {
            ...await _headers(),
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'route_name': routeName.trim(),
            'start_location': startLocation.trim(),
            'end_location': endLocation.trim(),
            'is_active': isActive,
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_getErrorMessage(response));
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // PATCH /routes/{route_id}
  Future<Map<String, dynamic>> updateRoute({
    required int routeId,
    required String routeName,
    required String startLocation,
    required String endLocation,
    required bool isActive,
  }) async {
    final response = await http
        .patch(
          Uri.parse('$baseUrl/routes/$routeId'),
          headers: {
            ...await _headers(),
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'route_name': routeName.trim(),
            'start_location': startLocation.trim(),
            'end_location': endLocation.trim(),
            'is_active': isActive,
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(_getErrorMessage(response));
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // DELETE /routes/{route_id}
  Future<void> deleteRoute(int routeId) async {
    final response = await http
        .delete(
          Uri.parse('$baseUrl/routes/$routeId'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(_getErrorMessage(response));
    }
  }

  // --------------------------------------------------
  // ADMIN - STOP MANAGEMENT APIs
  // --------------------------------------------------

  // POST /stops
  Future<Map<String, dynamic>> createStop({
    required String stopName,
    double? latitude,
    double? longitude,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/stops'),
          headers: {
            ...await _headers(),
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'stop_name': stopName.trim(),
            'latitude': latitude,
            'longitude': longitude,
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_getErrorMessage(response));
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // PATCH /stops/{stop_id}
  Future<Map<String, dynamic>> updateStop({
    required int stopId,
    required String stopName,
    double? latitude,
    double? longitude,
  }) async {
    final response = await http
        .patch(
          Uri.parse('$baseUrl/stops/$stopId'),
          headers: {
            ...await _headers(),
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'stop_name': stopName.trim(),
            'latitude': latitude,
            'longitude': longitude,
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(_getErrorMessage(response));
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // DELETE /stops/{stop_id}
  Future<void> deleteStop(int stopId) async {
    final response = await http
        .delete(
          Uri.parse('$baseUrl/stops/$stopId'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(_getErrorMessage(response));
    }
  }

  // --------------------------------------------------
  // ADMIN - ROUTE STOP MANAGEMENT APIs
  // --------------------------------------------------

  // POST /route-stops

  Future<Map<String, dynamic>> addStopToRoute({
    required int routeId,
    required int stopId,
    required int stopOrder,
    int departureOffsetMinutes = 0,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/route-stops'),
          headers: {
            ...await _headers(),
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'route_id': routeId,
            'stop_id': stopId,
            'stop_order': stopOrder,
            'departure_offset_minutes': departureOffsetMinutes,
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_getErrorMessage(response));
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // PATCH /route-stops/{route_id}/{stop_id}

  Future<Map<String, dynamic>> updateRouteStopOrder({
    required int routeId,
    required int stopId,
    required int stopOrder,
    int departureOffsetMinutes = 0,
  }) async {
    final response = await http
        .patch(
          Uri.parse('$baseUrl/route-stops/$routeId/$stopId'),
          headers: {
            ...await _headers(),
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'stop_order': stopOrder,
            'departure_offset_minutes': departureOffsetMinutes,
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(_getErrorMessage(response));
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // DELETE /route-stops/{route_id}/{stop_id}
  Future<void> removeStopFromRoute({
    required int routeId,
    required int stopId,
  }) async {
    final response = await http
        .delete(
          Uri.parse('$baseUrl/route-stops/$routeId/$stopId'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(_getErrorMessage(response));
    }
  }

  // --------------------------------------------------
  // ADMIN - USER MANAGEMENT APIs
  // --------------------------------------------------

  // GET /users
  Future<List<Map<String, dynamic>>> fetchUsers() async {
    final data = await _getList('/users');

    return data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  // GET /users/{user_id}
  Future<Map<String, dynamic>> fetchUser(int userId) async {
    final response = await _get('/users/$userId');

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // PATCH /users/{user_id}
  Future<Map<String, dynamic>> updateUser({
    required int userId,
    required String name,
    required String email,
    String? password,
    String? role,
  }) async {
    final body = <String, dynamic>{
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
    };

    if (password != null && password.isNotEmpty) {
      body['password'] = password;
    }

    if (role != null) {
      body['role'] = role;
    }

    final response = await http
        .patch(
          Uri.parse('$baseUrl/users/$userId'),
          headers: {
            ...await _headers(),
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(_getErrorMessage(response));
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // DELETE /users/{user_id}
  Future<void> deleteUser(int userId) async {
    final response = await http
        .delete(
          Uri.parse('$baseUrl/users/$userId'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(_getErrorMessage(response));
    }
  }
}
