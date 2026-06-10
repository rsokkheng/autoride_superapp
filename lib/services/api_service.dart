import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_log.dart';
import '../models/user_model.dart';
import '../models/vehicle_model.dart';
import '../models/ride_model.dart';
import '../models/driver_status_model.dart';
import '../models/driver_stats_model.dart';
import '../models/driver_tasks_model.dart';
import '../models/delivery_model.dart';
import '../models/ride_location_model.dart';
import '../models/conversation_model.dart';
import '../models/chat_message_model.dart';
import '../models/wallet_model.dart';
import '../models/marketplace_model.dart';

class ApiService {
  static String get _baseUrl =>
      (dotenv.env['BASE_URL'] ?? 'http://192.168.1.9:8000/api/v1')
          .replaceAll(RegExp(r'/+$'), '');

  static const String _keyToken        = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyRole         = 'user_role';
  static const String _keyName         = 'user_name';
  static const String _keyEmail        = 'user_email';
  static const String _keyPhone        = 'user_phone';
  static const String _keyId           = 'user_id';

  // ── Raw HTTP helpers (dart:io — allows Host header override) ─────────────

  static Future<_RawResponse> _rawGet(
    String path, {
    String? token,
  }) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 10);
    try {
      final uri = Uri.parse('$_baseUrl$path');
      final req = await client.getUrl(uri);

      req.headers.set('Accept', 'application/json');
      if (token != null) req.headers.set('Authorization', 'Bearer $token');

      final res     = await req.close();
      final resBody = await res.transform(utf8.decoder).join();

      AppLog.d('API', 'GET $uri → ${res.statusCode}');
      if (res.statusCode >= 400) AppLog.w('API', 'GET $uri body: $resBody');

      return _RawResponse(res.statusCode, resBody);
    } catch (e, s) {
      AppLog.e('API', 'GET $path network error', e, s);
      rethrow;
    } finally {
      client.close(force: true);
    }
  }

  static Future<_RawResponse> _rawPost(
    String path,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 10);
    try {
      final uri = Uri.parse('$_baseUrl$path');
      final req  = await client.postUrl(uri);

      req.headers.set('Content-Type', 'application/json; charset=utf-8');
      req.headers.set('Accept',       'application/json');
      if (token != null) req.headers.set('Authorization', 'Bearer $token');

      final bytes = utf8.encode(jsonEncode(body));
      req.headers.contentLength = bytes.length;
      req.add(bytes);

      final res      = await req.close();
      final resBody  = await res.transform(utf8.decoder).join();

      AppLog.d('API', 'POST $uri → ${res.statusCode}');
      if (res.statusCode >= 400) AppLog.w('API', 'POST $uri body: $resBody');

      return _RawResponse(res.statusCode, resBody);
    } catch (e, s) {
      AppLog.e('API', 'POST $path network error', e, s);
      rethrow;
    } finally {
      client.close(force: true);
    }
  }

  static Future<_RawResponse> _rawPut(
    String path,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 10);
    try {
      final uri = Uri.parse('$_baseUrl$path');
      final req = await client.putUrl(uri);

      req.headers.set('Content-Type', 'application/json; charset=utf-8');
      req.headers.set('Accept', 'application/json');
      if (token != null) req.headers.set('Authorization', 'Bearer $token');

      final bytes = utf8.encode(jsonEncode(body));
      req.headers.contentLength = bytes.length;
      req.add(bytes);

      final res     = await req.close();
      final resBody = await res.transform(utf8.decoder).join();

      AppLog.d('API', 'PUT $uri → ${res.statusCode}');
      if (res.statusCode >= 400) AppLog.w('API', 'PUT $uri body: $resBody');

      return _RawResponse(res.statusCode, resBody);
    } catch (e, s) {
      AppLog.e('API', 'PUT $path network error', e, s);
      rethrow;
    } finally {
      client.close(force: true);
    }
  }

  static Future<_RawResponse> _rawPatch(
    String path,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 10);
    try {
      final uri = Uri.parse('$_baseUrl$path');
      final req = await client.patchUrl(uri);

      req.headers.set('Content-Type', 'application/json; charset=utf-8');
      req.headers.set('Accept', 'application/json');
      if (token != null) req.headers.set('Authorization', 'Bearer $token');

      final bytes = utf8.encode(jsonEncode(body));
      req.headers.contentLength = bytes.length;
      req.add(bytes);

      final res     = await req.close();
      final resBody = await res.transform(utf8.decoder).join();

      AppLog.d('API', 'PATCH $uri → ${res.statusCode}');
      if (res.statusCode >= 400) AppLog.w('API', 'PATCH $uri body: $resBody');

      return _RawResponse(res.statusCode, resBody);
    } catch (e, s) {
      AppLog.e('API', 'PATCH $path network error', e, s);
      rethrow;
    } finally {
      client.close(force: true);
    }
  }

  static Future<_RawResponse> _rawDelete(
    String path, {
    String? token,
  }) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 10);
    try {
      final uri = Uri.parse('$_baseUrl$path');
      final req = await client.deleteUrl(uri);

      req.headers.set('Accept', 'application/json');
      if (token != null) req.headers.set('Authorization', 'Bearer $token');

      final res     = await req.close();
      final resBody = await res.transform(utf8.decoder).join();

      AppLog.d('API', 'DELETE $uri → ${res.statusCode}');
      if (res.statusCode >= 400) AppLog.w('API', 'DELETE $uri body: $resBody');

      return _RawResponse(res.statusCode, resBody);
    } catch (e, s) {
      AppLog.e('API', 'DELETE $path network error', e, s);
      rethrow;
    } finally {
      client.close(force: true);
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────────

  static Future<({UserModel user, String token})> login(
    String email,
    String password,
  ) async {
    final raw = await _rawPost('/auth/login', {
      'email':    email,
      'password': password,
    });

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(raw.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException(
        'Unexpected server response (${raw.statusCode}). '
        'Is the backend running at $_baseUrl?',
        raw.statusCode,
      );
    }

    if (raw.statusCode == 200) {
      // Unwrap optional data envelope: { "data": { ... } } or flat { ... }
      final data = (body['data'] as Map<String, dynamic>?) ?? body;

      final userJson    = data['user'];
      // Accept both 'access_token' and 'token' (Laravel returns either)
      final accessToken = data['access_token'] as String?
                       ?? data['token']        as String?;
      final refreshToken = data['refresh_token'] as String?;

      if (userJson == null || accessToken == null) {
        AppLog.e('Auth', 'Login response missing user or token. Keys: ${data.keys.toList()}');
        throw ApiException(
          'Server response missing "user" or "access_token" fields.',
          raw.statusCode,
        );
      }

      final user = UserModel.fromJson(userJson as Map<String, dynamic>);
      await _saveSession(user, accessToken, refreshToken: refreshToken);
      return (user: user, token: accessToken);
    }

    final message = body['message'] as String? ??
        (body['data'] as Map?)?.entries.first.value?.toString() ??
        body['error'] as String? ??
        'Login failed (${raw.statusCode}).';
    throw ApiException(message, raw.statusCode);
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  static Future<void> logout() async {
    try {
      final token = await getToken();
      if (token != null) {
        await _rawPost('/auth/logout', {}, token: token);
      }
    } catch (e, s) {
      AppLog.w('Auth', 'logout server call failed (session cleared anyway): $e');
      AppLog.e('Auth', 'logout stack', e, s);
    }
    await clearSession();
  }

  // ── Auth/me ───────────────────────────────────────────────────────────────

  static Future<UserModel> getMe() async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);

    final raw = await _rawGet('/auth/me', token: token);

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(raw.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException(
        'Unexpected server response (${raw.statusCode}).',
        raw.statusCode,
      );
    }

    if (raw.statusCode == 200) {
      final userJson = body['user'] ?? body;
      return UserModel.fromJson(userJson as Map<String, dynamic>);
    }

    final message = body['message'] as String? ??
        body['error'] as String? ??
        'Failed to fetch user (${raw.statusCode}).';
    throw ApiException(message, raw.statusCode);
  }

  // ── Vehicles ──────────────────────────────────────────────────────────────

  static Future<List<VehicleModel>> getVehicles({int page = 1}) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);

    final raw = await _rawGet('/vehicles?page=$page', token: token);

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(raw.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException(
        'Unexpected server response (${raw.statusCode}).',
        raw.statusCode,
      );
    }

    if (raw.statusCode == 200) {
      final pagination = body['vehicles'] as Map<String, dynamic>;
      final data = pagination['data'] as List<dynamic>;
      return data
          .map((e) => VehicleModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    final message = body['message'] as String? ??
        body['error'] as String? ??
        'Failed to fetch vehicles (${raw.statusCode}).';
    throw ApiException(message, raw.statusCode);
  }

  static Future<VehicleModel> getVehicle(int id) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);

    final raw = await _rawGet('/vehicles/$id', token: token);

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(raw.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException(
        'Unexpected server response (${raw.statusCode}).',
        raw.statusCode,
      );
    }

    if (raw.statusCode == 200) {
      return VehicleModel.fromJson(body['vehicle'] as Map<String, dynamic>);
    }

    final message = body['message'] as String? ??
        body['error'] as String? ??
        'Failed to fetch vehicle (${raw.statusCode}).';
    throw ApiException(message, raw.statusCode);
  }

  // ── Rides ─────────────────────────────────────────────────────────────────

  static Future<List<RideModel>> getRides({int page = 1, String? status}) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);

    final query = [
      'page=$page',
      if (status != null) 'status=$status',
    ].join('&');

    final raw = await _rawGet('/rides?$query', token: token);

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(raw.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException(
        'Unexpected server response (${raw.statusCode}).',
        raw.statusCode,
      );
    }

    if (raw.statusCode == 200) {
      final outer     = (body['data'] as Map<String, dynamic>?) ?? body;
      final pagination = outer['rides'] as Map<String, dynamic>;
      final data = pagination['data'] as List<dynamic>;
      return data
          .map((e) => RideModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    final message = body['message'] as String? ??
        body['error'] as String? ??
        'Failed to fetch rides (${raw.statusCode}).';
    throw ApiException(message, raw.statusCode);
  }

  // ── Single ride ───────────────────────────────────────────────────────────

  static Future<RideModel> getRide(int id) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);

    final raw = await _rawGet('/rides/$id', token: token);

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(raw.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Unexpected server response (${raw.statusCode}).', raw.statusCode);
    }

    if (raw.statusCode == 200) {
      final data    = (body['data'] as Map<String, dynamic>?) ?? body;
      final rideJson = data['ride'] ?? data;
      return RideModel.fromJson(rideJson as Map<String, dynamic>);
    }

    final message = body['message'] as String? ?? body['error'] as String? ??
        'Failed to fetch ride (${raw.statusCode}).';
    throw ApiException(message, raw.statusCode);
  }

  // ── Available rides (Driver only) ────────────────────────────────────────

  static Future<List<RideModel>> getAvailableRides({int page = 1}) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);

    final raw = await _rawGet('/rides/available?page=$page', token: token);

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(raw.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Unexpected server response (${raw.statusCode}).', raw.statusCode);
    }

    if (raw.statusCode == 200) {
      final outer      = (body['data'] as Map<String, dynamic>?) ?? body;
      final pagination = outer['rides'] as Map<String, dynamic>;
      final data = pagination['data'] as List<dynamic>;
      return data
          .map((e) => RideModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    final message = body['message'] as String? ??
        body['error'] as String? ??
        'Failed to fetch available rides (${raw.statusCode}).';
    throw ApiException(message, raw.statusCode);
  }

  // ── Driver status ─────────────────────────────────────────────────────────

  static Future<DriverStatusModel> getDriverStatus() async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);

    final raw = await _rawGet('/driver/status', token: token);

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(raw.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException(
        'Unexpected server response (${raw.statusCode}).',
        raw.statusCode,
      );
    }

    if (raw.statusCode == 200) {
      return DriverStatusModel.fromJson(body);
    }

    final message = body['message'] as String? ??
        body['error'] as String? ??
        'Failed to fetch driver status (${raw.statusCode}).';
    throw ApiException(message, raw.statusCode);
  }

  // ── Driver stats ──────────────────────────────────────────────────────────

  static Future<DriverStatsModel> getDriverStats() async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);

    final raw = await _rawGet('/driver/stats', token: token);

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(raw.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException(
        'Unexpected server response (${raw.statusCode}).',
        raw.statusCode,
      );
    }

    if (raw.statusCode == 200) {
      return DriverStatsModel.fromJson(body);
    }

    final message = body['message'] as String? ??
        body['error'] as String? ??
        'Failed to fetch driver stats (${raw.statusCode}).';
    throw ApiException(message, raw.statusCode);
  }

  // ── Estimate ride ─────────────────────────────────────────────────────────

  static Future<RideEstimate> estimateRide({
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
  }) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);

    final raw = await _rawPost('/rides/estimate', {
      'pickup_lat':  pickupLat,
      'pickup_lng':  pickupLng,
      'dropoff_lat': dropoffLat,
      'dropoff_lng': dropoffLng,
    }, token: token);

    final Map<String, dynamic> resBody;
    try {
      resBody = jsonDecode(raw.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Unexpected server response (${raw.statusCode}).', raw.statusCode);
    }

    if (raw.statusCode == 200 || raw.statusCode == 201) {
      final data  = (resBody['data'] as Map<String, dynamic>?) ?? resBody;
      final fares = data['fares'] as Map<String, dynamic>? ?? {};
      final route = data['route'] as Map<String, dynamic>?;
      return RideEstimate(
        fares: fares.map((key, value) =>
            MapEntry(key, FareInfo.fromJson(value as Map<String, dynamic>))),
        distanceKm: (route?['distance_km'] as num?)?.toDouble() ?? 0.0,
        etaMinutes: (route?['duration_min'] as num?)?.toInt()   ?? 0,
      );
    }

    final message = resBody['message'] as String? ?? resBody['error'] as String? ??
        'Failed to estimate ride (${raw.statusCode}).';
    throw ApiException(message, raw.statusCode);
  }

  // ── Create ride ───────────────────────────────────────────────────────────

  static Future<RideModel> createRide({
    required String pickupAddress,
    required String dropoffAddress,
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
    String  serviceType   = 'standard',
    String  paymentMethod = 'cash',
    int?    vehicleId,
    String? scheduledAt,
    String? notes,
  }) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);

    final body = <String, dynamic>{
      'pickup_address':  pickupAddress,
      'dropoff_address': dropoffAddress,
      'pickup_lat':      pickupLat,
      'pickup_lng':      pickupLng,
      'dropoff_lat':     dropoffLat,
      'dropoff_lng':     dropoffLng,
      'service_type':    serviceType,
      'payment_method':  paymentMethod,
      if (vehicleId   != null) 'vehicle_id':  vehicleId,
      if (scheduledAt != null) 'scheduled_at': scheduledAt,
      if (notes       != null) 'notes':        notes,
    };

    final raw = await _rawPost('/rides', body, token: token);

    final Map<String, dynamic> resBody;
    try {
      resBody = jsonDecode(raw.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Unexpected server response (${raw.statusCode}).', raw.statusCode);
    }

    if (raw.statusCode == 200 || raw.statusCode == 201) {
      final data    = (resBody['data'] as Map<String, dynamic>?) ?? resBody;
      final rideJson = data['ride'] ?? data;
      return RideModel.fromJson(rideJson as Map<String, dynamic>);
    }

    final message = resBody['message'] as String? ?? resBody['error'] as String? ??
        'Failed to create ride (${raw.statusCode}).';
    throw ApiException(message, raw.statusCode);
  }

  // ── Deliveries ────────────────────────────────────────────────────────────

  static Future<List<DeliveryModel>> getDeliveries({int page = 1, String? status}) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);

    final query = [
      'page=$page',
      if (status != null) 'status=$status',
    ].join('&');

    final raw = await _rawGet('/deliveries?$query', token: token);
    return _parseDeliveryList(raw);
  }

  static Future<DeliveryModel> getDelivery(int id) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);

    final raw = await _rawGet('/deliveries/$id', token: token);
    return _parseDeliveryResponse(raw);
  }

  static Future<DeliveryModel> updateDelivery(
    int id, {
    String? pickupAddress,
    String? dropoffAddress,
    String? packageDetails,
    String? packageSize,
    String? senderName,
    String? senderPhone,
    String? recipientName,
    String? recipientPhone,
    int? fee,
    String? paymentBy,
    String? paymentMethod,
    String? serviceOption,
    String? paymentModel,
    String? partnerCode,
    int? splitPercent,
    String? scheduledAt,
    String? notes,
    int? vehicleId,
    int? floorPickup,
    int? floorDropoff,
    bool? hasElevator,
    bool? needsStairsCarry,
    bool? heavyItems,
    int? requiresHelpers,
    String? helperType,
    bool? packingService,
    String? serviceType,
  }) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);

    final body = <String, dynamic>{
      if (pickupAddress  != null) 'pickup_address':   pickupAddress,
      if (dropoffAddress != null) 'dropoff_address':  dropoffAddress,
      if (packageDetails != null) 'package_details': packageDetails,
      if (packageSize    != null) 'package_size':    packageSize,
      if (senderName     != null) 'sender_name':     senderName,
      if (senderPhone    != null) 'sender_phone':    senderPhone,
      if (recipientName  != null) 'recipient_name':  recipientName,
      if (recipientPhone != null) 'recipient_phone': recipientPhone,
      if (fee            != null) 'fee':             fee,
      if (paymentBy      != null) 'payment_by':      paymentBy,
      if (paymentMethod  != null) 'payment_method':  paymentMethod,
      if (serviceOption  != null) 'service_option':  serviceOption,
      if (paymentModel   != null) 'payment_model':   paymentModel,
      if (partnerCode    != null) 'partner_code':    partnerCode,
      if (splitPercent   != null) 'split_percent':   splitPercent,
      if (scheduledAt    != null) 'scheduled_at':    scheduledAt,
      if (notes          != null) 'notes':           notes,
      if (vehicleId      != null) 'vehicle_id':      vehicleId,
      if (floorPickup    != null) 'floor_pickup':    floorPickup,
      if (floorDropoff   != null) 'floor_dropoff':   floorDropoff,
      if (hasElevator    != null) 'has_elevator':    hasElevator,
      if (needsStairsCarry != null) 'needs_stairs_carry': needsStairsCarry,
      if (heavyItems     != null) 'heavy_items':     heavyItems,
      if (requiresHelpers != null) 'requires_helpers': requiresHelpers,
      if (helperType     != null) 'helper_type':     helperType,
      if (packingService != null) 'packing_service': packingService,
      if (serviceType    != null) 'service_type':    serviceType,
    };

    final raw = await _rawPut('/deliveries/$id', body, token: token);
    return _parseDeliveryResponse(raw);
  }

  static Future<void> deleteDelivery(int id) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);

    final raw = await _rawDelete('/deliveries/$id', token: token);
    if (raw.statusCode != 200 && raw.statusCode != 204) {
      final body = jsonDecode(raw.body) as Map<String, dynamic>? ?? {};
      throw ApiException(
        body['message'] as String? ?? 'Failed to delete delivery (${raw.statusCode}).',
        raw.statusCode,
      );
    }
  }

  static Future<List<DeliveryModel>> getDeliveryHistory() async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw = await _rawGet('/deliveries/history', token: token);
    return _parseDeliveryList(raw);
  }

  static Future<List<DeliveryModel>> getAvailableDeliveries() async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw = await _rawGet('/deliveries/available', token: token);
    return _parseDeliveryList(raw);
  }

  static Future<({List<NearbyDriverModel> drivers, int total, double radiusKm})>
      getNearbyDrivers({
    required double pickupLat,
    required double pickupLng,
    int limit = 10,
  }) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);

    final raw = await _rawGet(
      '/deliveries/nearby-drivers?pickup_lat=$pickupLat&pickup_lng=$pickupLng&limit=$limit',
      token: token,
    );

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(raw.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Unexpected server response (${raw.statusCode}).', raw.statusCode);
    }

    if (raw.statusCode == 200) {
      final data = (body['data'] as Map<String, dynamic>?) ?? body;
      final list = (data['drivers'] as List<dynamic>? ?? [])
          .map((e) => NearbyDriverModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return (
        drivers:  list,
        total:    data['total'] as int? ?? list.length,
        radiusKm: (data['radius_km'] as num?)?.toDouble() ?? 30.0,
      );
    }

    final message = body['message'] as String? ?? 'Failed to fetch nearby drivers (${raw.statusCode}).';
    throw ApiException(message, raw.statusCode);
  }

  static Future<DeliveryEstimateModel> estimateDelivery({
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
    String serviceType = 'delivery',
    String serviceOption = 'normal',
    String packageSize = 'medium',
  }) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);

    final body = <String, dynamic>{
      'service_type': serviceType,
      'service_option': serviceOption,
      'pickup_lat': pickupLat,
      'pickup_lng': pickupLng,
      'dropoff_lat': dropoffLat,
      'dropoff_lng': dropoffLng,
      'package_size': packageSize,
    };
    
    final raw = await _rawPost(
      '/deliveries/estimate',
      body,
      token: token,
    );

    final Map<String, dynamic> responseBody;
    try {
      responseBody = jsonDecode(raw.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Unexpected server response (${raw.statusCode}).', raw.statusCode);
    }

    if (raw.statusCode == 200 || raw.statusCode == 201) {
      return DeliveryEstimateModel.fromJson(responseBody);
    }

    final message = responseBody['message'] as String? ?? 'Failed to estimate delivery (${raw.statusCode}).';
    throw ApiException(message, raw.statusCode);
  }

  static Future<DeliveryModel> acceptDelivery(int id) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw = await _rawPost('/deliveries/$id/accept', {}, token: token);
    return _parseDeliveryResponse(raw);
  }

  static Future<DeliveryTrackingModel> trackDelivery(int id) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw = await _rawPost('/deliveries/$id/track', {}, token: token);

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(raw.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Unexpected server response (${raw.statusCode}).', raw.statusCode);
    }

    if (raw.statusCode == 200 || raw.statusCode == 201) {
      return DeliveryTrackingModel.fromJson(body['data'] as Map<String, dynamic>? ?? body);
    }

    final message = body['message'] as String? ?? 'Failed to track delivery (${raw.statusCode}).';
    throw ApiException(message, raw.statusCode);
  }

  static Future<DeliveryModel> cancelDelivery(int id) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw = await _rawPost('/deliveries/$id/cancel', {}, token: token);
    return _parseDeliveryResponse(raw);
  }

  static Future<DeliveryModel> completeDelivery(int id) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw = await _rawPost('/deliveries/$id/complete', {}, token: token);
    return _parseDeliveryResponse(raw);
  }

  static Future<DeliveryModel> rateDelivery(
    int id, {
    required double rating,
    String? comment,
  }) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);

    final raw = await _rawPost(
      '/deliveries/$id/rate',
      {
        'rating': rating,
        if (comment != null) 'rating_comment': comment,
      },
      token: token,
    );

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(raw.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Unexpected server response (${raw.statusCode}).', raw.statusCode);
    }

    if (raw.statusCode == 200 || raw.statusCode == 201) {
      final data = (body['data'] as Map<String, dynamic>?) ?? body;
      return DeliveryModel.fromJson(data['delivery'] as Map<String, dynamic>);
    }

    final message = body['message'] as String? ?? 'Failed to rate delivery (${raw.statusCode}).';
    throw ApiException(message, raw.statusCode);
  }

  static List<DeliveryModel> _parseDeliveryList(_RawResponse raw) {
    final Map<String, dynamic> body;
    try {
      body = jsonDecode(raw.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Unexpected server response (${raw.statusCode}).', raw.statusCode);
    }

    if (raw.statusCode == 200) {
      final data       = (body['data'] as Map<String, dynamic>?) ?? body;
      final pagination = (data['deliveries'] as Map<String, dynamic>?) ?? {};
      final list       = pagination['data'] as List<dynamic>? ?? [];
      return list
          .map((e) => DeliveryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    final message = body['message'] as String? ??
        body['error'] as String? ??
        'Failed to fetch deliveries (${raw.statusCode}).';
    throw ApiException(message, raw.statusCode);
  }

  static DeliveryModel _parseDeliveryResponse(_RawResponse raw) {
    final Map<String, dynamic> body;
    try {
      body = jsonDecode(raw.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Unexpected server response (${raw.statusCode}).', raw.statusCode);
    }

    if (raw.statusCode == 200 || raw.statusCode == 201) {
      final data = (body['data'] as Map<String, dynamic>?) ?? body;
      return DeliveryModel.fromJson(data['delivery'] as Map<String, dynamic>);
    }

    final message = body['message'] as String? ??
        body['error'] as String? ??
        'Request failed (${raw.statusCode}).';
    throw ApiException(message, raw.statusCode);
  }

  // ── Ride actions ──────────────────────────────────────────────────────────

  static Future<RideModel> acceptRide(int id) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw = await _rawPost('/rides/$id/accept', {}, token: token);
    return _parseRideResponse(raw);
  }

  static Future<RideModel> completeRide(int id) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw = await _rawPost('/rides/$id/complete', {}, token: token);
    return _parseRideResponse(raw);
  }

  static Future<RideModel> cancelRide(int id) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw = await _rawPost('/rides/$id/cancel', {}, token: token);
    return _parseRideResponse(raw);
  }

  static Future<void> rateRide(int id, double rating, {String? comment}) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);

    final body = <String, dynamic>{
      'rating':  rating,
      if (comment != null) 'comment': comment,
    };

    final raw = await _rawPost('/rides/$id/rate', body, token: token);
    if (raw.statusCode != 200 && raw.statusCode != 201) {
      final resBody = jsonDecode(raw.body) as Map<String, dynamic>? ?? {};
      throw ApiException(
        resBody['message'] as String? ?? 'Failed to rate ride (${raw.statusCode}).',
        raw.statusCode,
      );
    }
  }

  static Future<RideModel> declineRide(int id) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw = await _rawPost('/driver/rides/$id/decline', {}, token: token);
    return _parseRideResponse(raw);
  }

  static RideModel _parseRideResponse(_RawResponse raw) {
    final Map<String, dynamic> body;
    try {
      body = jsonDecode(raw.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Unexpected server response (${raw.statusCode}).', raw.statusCode);
    }
    if (raw.statusCode == 200 || raw.statusCode == 201) {
      final outer    = (body['data'] as Map<String, dynamic>?) ?? body;
      final rideJson = outer['ride'] ?? outer;
      return RideModel.fromJson(rideJson as Map<String, dynamic>);
    }
    final message = body['message'] as String? ?? body['error'] as String? ??
        'Request failed (${raw.statusCode}).';
    throw ApiException(message, raw.statusCode);
  }

  // ── Ride tracking ──────────────────────────────────────────────────────────

  static Future<List<RideLocationModel>> getRideLocationHistory(int rideId) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);

    final raw = await _rawGet('/tracking/rides/$rideId', token: token);

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(raw.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Unexpected server response (${raw.statusCode}).', raw.statusCode);
    }

    if (raw.statusCode == 200) {
      final list = (body['locations'] ?? body['data'] ?? []) as List<dynamic>;
      return list
          .map((e) => RideLocationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    final message = body['message'] as String? ?? 'Failed to fetch tracking (${raw.statusCode}).';
    throw ApiException(message, raw.statusCode);
  }

  static Future<void> updateDriverLocation(
    int rideId, {
    required double latitude,
    required double longitude,
    double? speed,
    double? heading,
    String? status,
  }) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);

    final body = <String, dynamic>{
      'latitude':  latitude,
      'longitude': longitude,
      if (speed   != null) 'speed':   speed,
      if (heading != null) 'heading': heading,
      if (status  != null) 'status':  status,
    };

    final raw = await _rawPost('/tracking/rides/$rideId', body, token: token);
    if (raw.statusCode != 200 && raw.statusCode != 201) {
      final resBody = jsonDecode(raw.body) as Map<String, dynamic>? ?? {};
      throw ApiException(
        resBody['message'] as String? ?? 'Failed to update location (${raw.statusCode}).',
        raw.statusCode,
      );
    }
  }

  // ── Create delivery ───────────────────────────────────────────────────────

  static Future<DeliveryModel> createDelivery({
    required String pickupAddress,
    required String dropoffAddress,
    required String packageDetails,
    String? senderName,
    String? senderPhone,
    String? recipientName,
    String? recipientPhone,
    String? packageSize,
    int?    fee,
    String  paymentBy     = 'sender',   // 'sender' | 'recipient'
    String  paymentMethod = 'cash',     // 'cash' | 'wallet' | 'aba' | 'wing' | 'other_online'
    String  serviceOption = 'normal',   // 'normal' | 'express'
    String  paymentModel  = 'customer_pays', // 'customer_pays'|'partner_pays'|'split_payment'|'sponsored'
    String? scheduledAt,
    String? notes,
  }) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);

    final body = <String, dynamic>{
      'service_type':    'delivery',
      'pickup_address':  pickupAddress,
      'dropoff_address': dropoffAddress,
      'package_details': packageDetails,
      'payment_by':      paymentBy,
      'payment_method':  paymentMethod,
      'payment_model':   paymentModel,
      'service_option':  serviceOption,
      if (senderName     != null) 'sender_name':     senderName,
      if (senderPhone    != null) 'sender_phone':    senderPhone,
      if (recipientName  != null) 'recipient_name':  recipientName,
      if (recipientPhone != null) 'recipient_phone': recipientPhone,
      if (packageSize    != null) 'package_size':    packageSize,
      if (fee            != null) 'fee':             fee,
      if (scheduledAt    != null) 'scheduled_at':    scheduledAt,
      if (notes          != null) 'notes':           notes,
    };

    final raw = await _rawPost('/deliveries', body, token: token);
    return _parseDeliveryResponse(raw);
  }

  // ── Create moving order ───────────────────────────────────────────────────

  static Future<DeliveryModel> createMoving({
    required String pickupAddress,
    required String dropoffAddress,
    required int    floorPickup,
    required int    floorDropoff,
    required bool   hasElevator,
    required bool   needsStairsCarry,
    required bool   heavyItems,
    required int    requiresHelpers,   // 1–4
    String  serviceOption  = 'normal',       // 'normal' | 'express'
    String  helperType     = 'normal_carry', // 'normal_carry' | 'heavy_carry'
    String  paymentMethod  = 'cash',         // 'cash' | 'wallet' | 'aba' | 'wing' | 'other_online'
    String  paymentModel   = 'customer_pays', // 'customer_pays'|'partner_pays'|'split_payment'|'sponsored'
    String? packageDetails,
    String? notes,
    String? scheduledAt,
  }) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);

    final body = <String, dynamic>{
      'pickup_address':     pickupAddress,
      'dropoff_address':    dropoffAddress,
      'payment_method':     paymentMethod,
      'payment_model':      paymentModel,
      'floor_pickup':       floorPickup,
      'floor_dropoff':      floorDropoff,
      'has_elevator':       hasElevator,
      'needs_stairs_carry': needsStairsCarry,
      'heavy_items':        heavyItems,
      'requires_helpers':   requiresHelpers,
      'helper_type':        helperType,
      'service_option':     serviceOption,
      if (packageDetails != null) 'package_details': packageDetails,
      if (notes          != null) 'notes':           notes,
      if (scheduledAt    != null) 'scheduled_at':    scheduledAt,
    };

    final raw = await _rawPost('/movings', body, token: token);
    return _parseDeliveryResponse(raw);
  }

  // ── Estimate moving order ──────────────────────────────────────────────────

  static Future<DeliveryEstimateModel> estimateMoving({
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
    required int floorPickup,
    required int floorDropoff,
    required bool hasElevator,
    required bool heavyItems,
    required int requiresHelpers,
    String serviceOption = 'normal',
    String helperType = 'normal_carry', // 'normal_carry' | 'heavy_carry'
  }) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);

    final body = <String, dynamic>{
      'service_type': 'moving',
      'service_option': serviceOption,
      'pickup_lat': pickupLat,
      'pickup_lng': pickupLng,
      'dropoff_lat': dropoffLat,
      'dropoff_lng': dropoffLng,
      'floor_pickup': floorPickup,
      'floor_dropoff': floorDropoff,
      'has_elevator': hasElevator,
      'heavy_items': heavyItems,
      'requires_helpers': requiresHelpers,
      'helper_type': helperType,
    };

    final raw = await _rawPost(
      '/movings/estimate',
      body,
      token: token,
    );

    final Map<String, dynamic> responseBody;
    try {
      responseBody = jsonDecode(raw.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Unexpected server response (${raw.statusCode}).', raw.statusCode);
    }

    if (raw.statusCode == 200 || raw.statusCode == 201) {
      return DeliveryEstimateModel.fromJson(responseBody);
    }

    final message = responseBody['message'] as String? ??
        'Failed to estimate moving (${raw.statusCode}).';
    throw ApiException(message, raw.statusCode);
  }

  // ── Moving order CRUD ──────────────────────────────────────────────────────

  static Future<DeliveryModel> getMoving(int id) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);

    final raw = await _rawGet('/movings/$id', token: token);
    return _parseDeliveryResponse(raw);
  }

  static Future<DeliveryModel> updateMoving(
    int id, {
    String? pickupAddress,
    String? dropoffAddress,
    int? floorPickup,
    int? floorDropoff,
    bool? hasElevator,
    bool? needsStairsCarry,
    bool? heavyItems,
    int? requiresHelpers,
    String? serviceOption,
    String? helperType,
    bool? packingService,
    int? fee,
    String? paymentMethod,
    String? paymentModel,
    String? partnerReference,
    int? splitPctCustomer,
    String? notes,
    String? scheduledAt,
  }) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);

    final body = <String, dynamic>{
      if (pickupAddress     != null) 'pickup_address':     pickupAddress,
      if (dropoffAddress    != null) 'dropoff_address':    dropoffAddress,
      if (floorPickup       != null) 'floor_pickup':       floorPickup,
      if (floorDropoff      != null) 'floor_dropoff':      floorDropoff,
      if (hasElevator       != null) 'has_elevator':       hasElevator,
      if (needsStairsCarry  != null) 'needs_stairs_carry': needsStairsCarry,
      if (heavyItems        != null) 'heavy_items':        heavyItems,
      if (requiresHelpers   != null) 'requires_helpers':   requiresHelpers,
      if (serviceOption     != null) 'service_option':     serviceOption,
      if (helperType        != null) 'helper_type':        helperType,
      if (packingService    != null) 'packing_service':    packingService,
      if (fee               != null) 'fee':                fee,
      if (paymentMethod     != null) 'payment_method':     paymentMethod,
      if (paymentModel      != null) 'payment_model':      paymentModel,
      if (partnerReference  != null) 'partner_reference':  partnerReference,
      if (splitPctCustomer  != null) 'split_pct_customer': splitPctCustomer,
      if (notes             != null) 'notes':              notes,
      if (scheduledAt       != null) 'scheduled_at':       scheduledAt,
    };

    final raw = await _rawPut('/movings/$id', body, token: token);
    return _parseDeliveryResponse(raw);
  }

  static Future<DeliveryModel> patchMoving(
    int id, {
    String? pickupAddress,
    String? dropoffAddress,
    int? floorPickup,
    int? floorDropoff,
    bool? hasElevator,
    bool? needsStairsCarry,
    bool? heavyItems,
    int? requiresHelpers,
    String? serviceOption,
    String? helperType,
    bool? packingService,
    int? fee,
    String? paymentMethod,
    String? paymentModel,
    String? partnerReference,
    int? splitPctCustomer,
    String? notes,
    String? scheduledAt,
  }) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);

    final body = <String, dynamic>{
      if (pickupAddress     != null) 'pickup_address':     pickupAddress,
      if (dropoffAddress    != null) 'dropoff_address':    dropoffAddress,
      if (floorPickup       != null) 'floor_pickup':       floorPickup,
      if (floorDropoff      != null) 'floor_dropoff':      floorDropoff,
      if (hasElevator       != null) 'has_elevator':       hasElevator,
      if (needsStairsCarry  != null) 'needs_stairs_carry': needsStairsCarry,
      if (heavyItems        != null) 'heavy_items':        heavyItems,
      if (requiresHelpers   != null) 'requires_helpers':   requiresHelpers,
      if (serviceOption     != null) 'service_option':     serviceOption,
      if (helperType        != null) 'helper_type':        helperType,
      if (packingService    != null) 'packing_service':    packingService,
      if (fee               != null) 'fee':                fee,
      if (paymentMethod     != null) 'payment_method':     paymentMethod,
      if (paymentModel      != null) 'payment_model':      paymentModel,
      if (partnerReference  != null) 'partner_reference':  partnerReference,
      if (splitPctCustomer  != null) 'split_pct_customer': splitPctCustomer,
      if (notes             != null) 'notes':              notes,
      if (scheduledAt       != null) 'scheduled_at':       scheduledAt,
    };

    final raw = await _rawPatch('/movings/$id', body, token: token);
    return _parseDeliveryResponse(raw);
  }

  static Future<void> deleteMoving(int id) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);

    final raw = await _rawDelete('/movings/$id', token: token);
    if (raw.statusCode != 200 && raw.statusCode != 204) {
      final body = jsonDecode(raw.body) as Map<String, dynamic>? ?? {};
      throw ApiException(
        body['message'] as String? ?? 'Failed to delete moving (${raw.statusCode}).',
        raw.statusCode,
      );
    }
  }

  // ── Moving order actions ───────────────────────────────────────────────────

  static Future<DeliveryModel> acceptMoving(int id) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw = await _rawPost('/movings/$id/accept', {}, token: token);
    return _parseDeliveryResponse(raw);
  }

  static Future<DeliveryModel> cancelMoving(int id) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw = await _rawPost('/movings/$id/cancel', {}, token: token);
    return _parseDeliveryResponse(raw);
  }

  static Future<DeliveryTrackingModel> trackMoving(int id) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw = await _rawPost('/movings/$id/track', {}, token: token);

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(raw.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Unexpected server response (${raw.statusCode}).', raw.statusCode);
    }

    if (raw.statusCode == 200 || raw.statusCode == 201) {
      return DeliveryTrackingModel.fromJson(body['data'] as Map<String, dynamic>? ?? body);
    }

    final message = body['message'] as String? ?? 'Failed to track moving (${raw.statusCode}).';
    throw ApiException(message, raw.statusCode);
  }

  static Future<DeliveryModel> completeMoving(int id) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw = await _rawPost('/movings/$id/complete', {}, token: token);
    return _parseDeliveryResponse(raw);
  }

  static Future<DeliveryModel> rateMoving(
    int id, {
    required double rating,
    String? comment,
  }) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);

    final raw = await _rawPost(
      '/movings/$id/rate',
      {
        'rating': rating,
        if (comment != null) 'rating_comment': comment,
      },
      token: token,
    );

    return _parseDeliveryResponse(raw);
  }

  // ── Driver availability ───────────────────────────────────────────────────

  static Future<void> goOnline() async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw = await _rawPost('/driver/go-online', {}, token: token);
    if (raw.statusCode != 200) {
      final body = jsonDecode(raw.body) as Map<String, dynamic>? ?? {};
      throw ApiException(
        body['message'] as String? ?? 'Failed to go online (${raw.statusCode}).',
        raw.statusCode,
      );
    }
  }

  static Future<void> goOffline() async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw = await _rawPost('/driver/go-offline', {}, token: token);
    if (raw.statusCode != 200) {
      final body = jsonDecode(raw.body) as Map<String, dynamic>? ?? {};
      throw ApiException(
        body['message'] as String? ?? 'Failed to go offline (${raw.statusCode}).',
        raw.statusCode,
      );
    }
  }

  // ── Marketplace ───────────────────────────────────────────────────────────

  static List<dynamic> _extractList(dynamic decoded) {
    if (decoded is List) return decoded;
    if (decoded is Map<String, dynamic>) {
      final data = decoded['data'];
      if (data is List) return data;
      if (data is Map<String, dynamic>) {
        // data.data[]
        final inner = data['data'];
        if (inner is List) return inner;
        // data.products.data[] (marketplace browse)
        final products = data['products'];
        if (products is Map<String, dynamic>) {
          final pData = products['data'];
          if (pData is List) return pData;
        }
        // data.orders.data[] etc.
        for (final v in data.values) {
          if (v is Map<String, dynamic>) {
            final vData = v['data'];
            if (vData is List) return vData;
          }
        }
      }
    }
    return [];
  }

  static List<MarketplaceProductModel> _parseProductList(String body) {
    dynamic decoded;
    try {
      decoded = jsonDecode(body);
    } catch (_) {
      return [];
    }
    return _extractList(decoded)
        .whereType<Map<String, dynamic>>()
        .map(MarketplaceProductModel.fromJson)
        .toList();
  }

  static MarketplaceProductModel _parseProduct(_RawResponse raw) {
    dynamic decoded;
    try {
      decoded = jsonDecode(raw.body);
    } catch (_) {
      throw ApiException('Unexpected server response (${raw.statusCode}).', raw.statusCode);
    }
    if (raw.statusCode == 200 || raw.statusCode == 201) {
      Map<String, dynamic>? data;
      if (decoded is Map<String, dynamic>) {
        final d = decoded['data'];
        if (d is Map<String, dynamic>) {
          // data.product  (single-item endpoint)
          final product = d['product'];
          data = product is Map<String, dynamic> ? product : d;
        } else {
          data = decoded;
        }
      }
      if (data == null) {
        throw ApiException('Unexpected response format (${raw.statusCode}).', raw.statusCode);
      }
      return MarketplaceProductModel.fromJson(data);
    }
    final msg = decoded is Map<String, dynamic>
        ? decoded['message'] as String? ?? 'Request failed (${raw.statusCode}).'
        : 'Request failed (${raw.statusCode}).';
    throw ApiException(msg, raw.statusCode);
  }

  static Future<List<MarketplaceCategoryModel>> getMarketplaceCategories() async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw = await _rawGet('/marketplace/categories', token: token);
    final Map<String, dynamic> body;
    try {
      body = jsonDecode(raw.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Unexpected server response (${raw.statusCode}).', raw.statusCode);
    }
    if (raw.statusCode == 200) {
      return _extractList(body)
          .whereType<Map<String, dynamic>>()
          .map(MarketplaceCategoryModel.fromJson)
          .toList();
    }
    throw ApiException(body['message'] as String? ?? 'Failed to load categories.', raw.statusCode);
  }

  static Future<List<MarketplaceProductModel>> getMarketplaceProducts({
    String? search,
    int?    categoryId,
    int?    sellerId,
    String? listingType,  // sale | rent | both
    String? condition,    // new | used | refurbished
    int?    minPrice,
    int?    maxPrice,
    int     page = 1,
  }) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final params = <String, String>{'page': '$page'};
    if (search      != null) params['search']      = search;
    if (categoryId  != null) params['category_id'] = '$categoryId';
    if (sellerId    != null) params['seller_id']   = '$sellerId';
    if (listingType != null) params['listing_type'] = listingType;
    if (condition   != null) params['condition']   = condition;
    if (minPrice    != null) params['min_price']   = '$minPrice';
    if (maxPrice    != null) params['max_price']   = '$maxPrice';
    final query = params.isEmpty ? '' : '?${params.entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&')}';
    final raw = await _rawGet('/marketplace$query', token: token);
    if (raw.statusCode == 200) return _parseProductList(raw.body);
    final body = jsonDecode(raw.body) as Map<String, dynamic>? ?? {};
    throw ApiException(body['message'] as String? ?? 'Failed to load products.', raw.statusCode);
  }

  static Future<MarketplaceProductModel> getMarketplaceProduct(int id) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw = await _rawGet('/marketplace/$id', token: token);
    return _parseProduct(raw);
  }

  static Future<List<MarketplaceProductModel>> getMyMarketplaceProducts() async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw = await _rawGet('/marketplace/my-products', token: token);
    if (raw.statusCode == 200) return _parseProductList(raw.body);
    final body = jsonDecode(raw.body) as Map<String, dynamic>? ?? {};
    throw ApiException(body['message'] as String? ?? 'Failed to load your products.', raw.statusCode);
  }

  static Future<MarketplaceProductModel> createMarketplaceProduct({
    required String title,
    required int    price,
    required String condition,    // new | used | refurbished
    required String listingType,  // sale | rent | both
    required String status,       // draft | active
    String? description,
    String? locationText,
    double? locationLat,
    double? locationLng,
    String? expiresAt,
    int?    categoryId,
    int     quantity        = 1,
    int?    rentPricePerDay,
    List<File> images       = const [],  // max 10 files, 5 MB each
  }) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);

    final uri     = Uri.parse('$_baseUrl/marketplace');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..headers['Accept']        = 'application/json';

    request.fields['title']        = title;
    request.fields['price']        = '$price';
    request.fields['condition']    = condition;
    request.fields['listing_type'] = listingType;
    request.fields['status']       = status;
    request.fields['quantity']     = '$quantity';
    if (description     != null) request.fields['description']        = description;
    if (locationText    != null) request.fields['location_text']      = locationText;
    if (locationLat     != null) request.fields['location_lat']       = '$locationLat';
    if (locationLng     != null) request.fields['location_lng']       = '$locationLng';
    if (expiresAt       != null) request.fields['expires_at']         = expiresAt;
    if (categoryId      != null) request.fields['category_id']        = '$categoryId';
    if (rentPricePerDay != null) request.fields['rent_price_per_day'] = '$rentPricePerDay';

    for (final file in images) {
      request.files.add(await http.MultipartFile.fromPath('images[]', file.path));
    }

    final streamed = await request.send();
    final body     = await streamed.stream.bytesToString();
    AppLog.d('API', 'POST /marketplace → ${streamed.statusCode}');
    if (streamed.statusCode >= 400) AppLog.w('API', 'POST /marketplace body: $body');
    return _parseProduct(_RawResponse(streamed.statusCode, body));
  }

  static Future<MarketplaceProductModel> updateMarketplaceProduct(
    int id, {
    String? title,
    String? description,
    int?    categoryId,
    String? condition,
    String? listingType,
    int?    price,
    int?    rentPricePerDay,
    int?    quantity,
    String? status,   // draft | active | paused | sold
    String? locationText,
    double? locationLat,
    double? locationLng,
    String? expiresAt,
  }) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final body = <String, dynamic>{
      if (title           != null) 'title':              title,
      if (description     != null) 'description':        description,
      if (categoryId      != null) 'category_id':        categoryId,
      if (condition       != null) 'condition':          condition,
      if (listingType     != null) 'listing_type':       listingType,
      if (price           != null) 'price':              price,
      if (rentPricePerDay != null) 'rent_price_per_day': rentPricePerDay,
      if (quantity        != null) 'quantity':           quantity,
      if (status          != null) 'status':             status,
      if (locationText    != null) 'location_text':      locationText,
      if (locationLat     != null) 'location_lat':       locationLat,
      if (locationLng     != null) 'location_lng':       locationLng,
      if (expiresAt       != null) 'expires_at':         expiresAt,
    };
    final raw = await _rawPut('/marketplace/$id', body, token: token);
    return _parseProduct(raw);
  }

  static Future<void> deleteMarketplaceProduct(int id) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw = await _rawDelete('/marketplace/$id', token: token);
    if (raw.statusCode != 200 && raw.statusCode != 204) {
      final body = jsonDecode(raw.body) as Map<String, dynamic>? ?? {};
      throw ApiException(body['message'] as String? ?? 'Failed to delete product.', raw.statusCode);
    }
  }

  static Future<void> uploadMarketplaceProductImages(int id, List<File> imageFiles) async {
    if (imageFiles.isEmpty) return;
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final uri     = Uri.parse('$_baseUrl/marketplace/$id/images');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..headers['Accept']        = 'application/json';
    for (final file in imageFiles) {
      request.files.add(await http.MultipartFile.fromPath('images[]', file.path));
    }
    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();
    AppLog.d('API', 'POST /marketplace/$id/images → ${streamed.statusCode}');
    if (streamed.statusCode != 200 && streamed.statusCode != 201) {
      final decoded = jsonDecode(body) as Map<String, dynamic>? ?? {};
      throw ApiException(decoded['message'] as String? ?? 'Image upload failed.', streamed.statusCode);
    }
  }

  static Future<void> deleteMarketplaceProductImage(int id, int imageId) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw = await _rawDelete('/marketplace/$id/images/$imageId', token: token);
    if (raw.statusCode != 200 && raw.statusCode != 204) {
      final body = jsonDecode(raw.body) as Map<String, dynamic>? ?? {};
      throw ApiException(body['message'] as String? ?? 'Failed to delete image.', raw.statusCode);
    }
  }

  static Future<MarketplaceOrderModel> placeMarketplaceOrder(
    int productId, {
    String  orderType     = 'purchase', // purchase | rent
    int     quantity      = 1,
    String  paymentMethod = 'cash',
    String? notes,
    String? rentStartDate,
    String? rentEndDate,
  }) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final body = <String, dynamic>{
      'order_type':      orderType,
      'quantity':        quantity,
      'payment_method':  paymentMethod,
      if (notes          != null) 'notes':           notes,
      if (rentStartDate  != null) 'rent_start_date': rentStartDate,
      if (rentEndDate    != null) 'rent_end_date':   rentEndDate,
    };
    final raw = await _rawPost('/marketplace/$productId/order', body, token: token);
    final Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(raw.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Unexpected server response (${raw.statusCode}).', raw.statusCode);
    }
    if (raw.statusCode == 200 || raw.statusCode == 201) {
      final data = decoded['data'] ?? decoded;
      return MarketplaceOrderModel.fromJson(data as Map<String, dynamic>);
    }
    throw ApiException(decoded['message'] as String? ?? 'Failed to place order.', raw.statusCode);
  }

  static Future<List<MarketplaceOrderModel>> getMyMarketplaceOrders({
    String type = 'buying', // buying | selling
  }) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw = await _rawGet('/marketplace/my-orders?type=$type', token: token);
    final Map<String, dynamic> body;
    try {
      body = jsonDecode(raw.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Unexpected server response (${raw.statusCode}).', raw.statusCode);
    }
    if (raw.statusCode == 200) {
      return _extractList(body)
          .whereType<Map<String, dynamic>>()
          .map(MarketplaceOrderModel.fromJson)
          .toList();
    }
    throw ApiException(body['message'] as String? ?? 'Failed to load orders.', raw.statusCode);
  }

  static Future<void> _marketplaceOrderAction(String path) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw = await _rawPost(path, {}, token: token);
    if (raw.statusCode != 200 && raw.statusCode != 201) {
      final body = jsonDecode(raw.body) as Map<String, dynamic>? ?? {};
      throw ApiException(body['message'] as String? ?? 'Action failed (${raw.statusCode}).', raw.statusCode);
    }
  }

  static Future<void> confirmMarketplaceOrder(int id)  => _marketplaceOrderAction('/marketplace/orders/$id/confirm');
  static Future<void> completeMarketplaceOrder(int id) => _marketplaceOrderAction('/marketplace/orders/$id/complete');
  static Future<void> cancelMarketplaceOrder(int id)   => _marketplaceOrderAction('/marketplace/orders/$id/cancel');

  // ── Driver tasks ──────────────────────────────────────────────────────────

  static Future<DriverTasksModel> getDriverTasks() async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);

    final raw = await _rawGet('/driver/tasks', token: token);

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(raw.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException(
        'Unexpected server response (${raw.statusCode}).',
        raw.statusCode,
      );
    }

    if (raw.statusCode == 200) {
      return DriverTasksModel.fromJson(body);
    }

    final message = body['message'] as String? ??
        body['error'] as String? ??
        'Failed to fetch driver tasks (${raw.statusCode}).';
    throw ApiException(message, raw.statusCode);
  }

  // ── OTP ───────────────────────────────────────────────────────────────────

  /// Returns the sent phone and (in dev) the OTP code.
  static Future<({String phone, int? code})> sendOtp(String phone) async {
    final raw = await _rawPost('/auth/otp/send', {'phone': phone});

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(raw.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Unexpected server response (${raw.statusCode}).', raw.statusCode);
    }

    if (raw.statusCode == 200 || raw.statusCode == 201) {
      return (
        phone: body['phone'] as String? ?? phone,
        code:  body['code']  as int?,
      );
    }

    final message = body['message'] as String? ?? body['error'] as String? ??
        'Failed to send OTP (${raw.statusCode}).';
    throw ApiException(message, raw.statusCode);
  }

  static Future<void> verifyOtp(String phone, String code) async {
    final raw = await _rawPost('/auth/otp/verify', {
      'phone': phone,
      'code':  code,
    });

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(raw.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Unexpected server response (${raw.statusCode}).', raw.statusCode);
    }

    if (raw.statusCode == 200 || raw.statusCode == 201) return;

    final message = body['message'] as String? ?? body['error'] as String? ??
        'OTP verification failed (${raw.statusCode}).';
    throw ApiException(message, raw.statusCode);
  }

  // ── Chat ──────────────────────────────────────────────────────────────────

  // Primary: GET /rides/{id}/conversation — direct ride → conversation link.
  // Returns null (does NOT throw) when the endpoint 404s or the ride has no conversation yet.
  static Future<ConversationModel?> getRideConversation(int rideId) async {
    final token = await getToken();
    if (token == null) return null;

    final raw = await _rawGet('/rides/$rideId/conversation', token: token);

    if (kDebugMode) {
      debugPrint('[Chat] GET /rides/$rideId/conversation → ${raw.statusCode}');
      debugPrint('[Chat] body: ${raw.body}');
    }

    if (raw.statusCode != 200) return null;

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(raw.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }

    try {
      final data    = (body['data'] as Map<String, dynamic>?) ?? body;
      final convJson = data['conversation'] as Map<String, dynamic>? ?? data;
      return ConversationModel.fromJson(convJson);
    } catch (_) {
      return null;
    }
  }

  // Fallback: GET /chats → match by the other party's ID.
  static Future<ConversationModel?> findRideConversation({
    int? withDriverId,
    int? withPassengerId,
  }) async {
    final conversations = await getConversations();

    if (kDebugMode) {
      debugPrint('[Chat] GET /chats → ${conversations.length} conversation(s)');
      for (final c in conversations) {
        debugPrint('[Chat]   conv id=${c.id} driverId=${c.driverId} passengerId=${c.passengerId} topic=${c.topic}');
      }
      debugPrint('[Chat] matching withDriverId=$withDriverId withPassengerId=$withPassengerId');
    }

    for (final conv in conversations) {
      if (withDriverId    != null && conv.driverId    == withDriverId)    return conv;
      if (withPassengerId != null && conv.passengerId == withPassengerId)  return conv;
    }
    return null;
  }

  static Future<List<ConversationModel>> getConversations() async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);

    final raw = await _rawGet('/chats', token: token);

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(raw.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Unexpected server response (${raw.statusCode}).', raw.statusCode);
    }

    if (raw.statusCode == 200) {
      final data = (body['data'] as Map<String, dynamic>?) ?? body;
      final list = (data['conversations'] ?? body['conversations']) as List<dynamic>? ?? [];
      return list.map((e) => ConversationModel.fromJson(e as Map<String, dynamic>)).toList();
    }

    final message = body['message'] as String? ?? body['error'] as String? ??
        'Failed to fetch conversations (${raw.statusCode}).';
    throw ApiException(message, raw.statusCode);
  }

  static Future<List<ChatMessageModel>> getMessages(int conversationId) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);

    final raw = await _rawGet('/chats/$conversationId', token: token);

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(raw.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Unexpected server response (${raw.statusCode}).', raw.statusCode);
    }

    if (raw.statusCode == 200) {
      final data = (body['data'] as Map<String, dynamic>?) ?? body;
      final list = (data['messages'] ?? body['messages']) as List<dynamic>? ?? [];
      return list.map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>)).toList();
    }

    final message = body['message'] as String? ?? body['error'] as String? ??
        'Failed to fetch messages (${raw.statusCode}).';
    throw ApiException(message, raw.statusCode);
  }

  static Future<ChatMessageModel> sendMessage(int conversationId, String message) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);

    final raw = await _rawPost('/chats/$conversationId/messages', {'message': message}, token: token);

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(raw.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Unexpected server response (${raw.statusCode}).', raw.statusCode);
    }

    if (raw.statusCode == 200 || raw.statusCode == 201) {
      final data    = (body['data']    as Map<String, dynamic>?) ?? body;
      final msgJson = data['message'] as Map<String, dynamic>? ??
                      body['message'] as Map<String, dynamic>;
      return ChatMessageModel.fromJson(msgJson);
    }

    final msg = body['message'] as String? ?? body['error'] as String? ??
        'Failed to send message (${raw.statusCode}).';
    throw ApiException(msg, raw.statusCode);
  }

  // ── Session storage ───────────────────────────────────────────────────────

  static Future<void> _saveSession(UserModel user, String token, {String? refreshToken}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    if (refreshToken != null) await prefs.setString(_keyRefreshToken, refreshToken);
    await prefs.setString(_keyRole,  user.role);
    await prefs.setString(_keyName,  user.name);
    await prefs.setString(_keyEmail, user.email);
    await prefs.setString(_keyPhone, user.phone);
    await prefs.setInt(   _keyId,    user.id);
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyRefreshToken);
    await prefs.remove(_keyRole);
    await prefs.remove(_keyName);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyPhone);
    await prefs.remove(_keyId);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRefreshToken);
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRole);
  }

  static Future<UserModel?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_keyToken);
    if (token == null) return null;
    return UserModel(
      id:        prefs.getInt(   _keyId)    ?? 0,
      name:      prefs.getString(_keyName)  ?? '',
      email:     prefs.getString(_keyEmail) ?? '',
      phone:     prefs.getString(_keyPhone) ?? '',
      role:      prefs.getString(_keyRole)  ?? 'passenger',
      available: true,
    );
  }

  static Future<bool> isLoggedIn() async => (await getToken()) != null;

  // ── Wallet ────────────────────────────────────────────────────────────────

  static Future<WalletModel> getWallet() async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);

    final raw = await _rawGet('/wallet', token: token);

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(raw.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Unexpected server response (${raw.statusCode}).', raw.statusCode);
    }

    if (raw.statusCode == 200) {
      return WalletModel.fromJson(body);
    }

    final message = body['message'] as String? ?? body['error'] as String? ??
        'Failed to load wallet (${raw.statusCode}).';
    throw ApiException(message, raw.statusCode);
  }

  /// POST /v1/wallet/topup  — returns the new TopUpRequestModel (status: pending)
  static Future<TopUpRequestModel> requestTopUp({
    required int    amount,
    required String method,  // 'cash' | 'online' | 'company_credit'
    String?         note,
  }) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);

    final body = <String, dynamic>{'amount': amount, 'method': method};
    if (note != null && note.trim().isNotEmpty) body['note'] = note.trim();

    final raw = await _rawPost('/wallet/topup', body, token: token);

    final Map<String, dynamic> resBody;
    try {
      resBody = jsonDecode(raw.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Unexpected server response (${raw.statusCode}).', raw.statusCode);
    }

    if (raw.statusCode == 201) {
      return TopUpRequestModel.fromJson(resBody);
    }

    final message = resBody['message'] as String? ?? resBody['error'] as String? ??
        'Top-up request failed (${raw.statusCode}).';
    throw ApiException(message, raw.statusCode);
  }

  /// GET /v1/wallet/topup/{id}
  static Future<TopUpRequestModel> getTopUpRequest(int id) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);

    final raw = await _rawGet('/wallet/topup/$id', token: token);

    final Map<String, dynamic> resBody;
    try {
      resBody = jsonDecode(raw.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Unexpected server response (${raw.statusCode}).', raw.statusCode);
    }

    if (raw.statusCode == 200) {
      return TopUpRequestModel.fromJson(resBody);
    }

    final message = resBody['message'] as String? ?? resBody['error'] as String? ??
        'Failed to fetch top-up request (${raw.statusCode}).';
    throw ApiException(message, raw.statusCode);
  }

  /// POST /v1/wallet/withdraw
  static Future<WithdrawResultModel> withdraw({
    required int amount,
    String?      note,
  }) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);

    final body = <String, dynamic>{'amount': amount};
    if (note != null && note.trim().isNotEmpty) body['note'] = note.trim();

    final raw = await _rawPost('/wallet/withdraw', body, token: token);

    final Map<String, dynamic> resBody;
    try {
      resBody = jsonDecode(raw.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Unexpected server response (${raw.statusCode}).', raw.statusCode);
    }

    if (raw.statusCode == 200) {
      return WithdrawResultModel.fromJson(resBody);
    }

    final message = resBody['message'] as String? ?? resBody['error'] as String? ??
        'Withdrawal failed (${raw.statusCode}).';
    throw ApiException(message, raw.statusCode);
  }

  static Future<WalletTransactionsPage> getWalletTransactions({int page = 1}) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);

    final raw = await _rawGet('/wallet/transactions?page=$page', token: token);

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(raw.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Unexpected server response (${raw.statusCode}).', raw.statusCode);
    }

    if (raw.statusCode == 200) {
      return WalletTransactionsPage.fromJson(body);
    }

    final message = body['message'] as String? ?? body['error'] as String? ??
        'Failed to load transactions (${raw.statusCode}).';
    throw ApiException(message, raw.statusCode);
  }
}

// ── Ride estimate models ──────────────────────────────────────────────────────

class RideEstimate {
  final Map<String, FareInfo> fares;
  final double distanceKm;
  final int    etaMinutes;
  const RideEstimate({required this.fares, required this.distanceKm, required this.etaMinutes});
}

class FareInfo {
  final int  total;
  final int  minimumFare;
  final bool surgeActive;
  final bool nightRate;
  final Map<String, int> breakdown;

  const FareInfo({
    required this.total,
    required this.minimumFare,
    required this.surgeActive,
    required this.nightRate,
    required this.breakdown,
  });

  factory FareInfo.fromJson(Map<String, dynamic> json) {
    final bd = json['breakdown'] as Map<String, dynamic>? ?? {};
    return FareInfo(
      total:       (json['total']        as num?)?.toInt() ?? 0,
      minimumFare: (json['minimum_fare'] as num?)?.toInt() ?? 0,
      surgeActive:  json['surge_active'] as bool? ?? false,
      nightRate:    json['night_rate']   as bool? ?? false,
      breakdown:   bd.map((k, v) => MapEntry(k, (v as num).toInt())),
    );
  }

  // e.g. 12200 → "12,200 ៛"
  String get formattedTotal {
    final s = total.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return '${buf.toString()} ៛';
  }
}

class _RawResponse {
  final int    statusCode;
  final String body;
  const _RawResponse(this.statusCode, this.body);
}

class ApiException implements Exception {
  final String message;
  final int    statusCode;
  const ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}
