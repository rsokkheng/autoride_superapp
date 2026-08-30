import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../main.dart' show navigatorKey;
import '../screens/auth/login_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_log.dart';
import '../models/user_model.dart';
import '../models/vehicle_model.dart';
import '../models/vehicle_type_model.dart';
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
import '../models/trip_model.dart';
import '../models/promo_event_model.dart';

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

  // Dedupes concurrent refresh attempts so a burst of 401s only triggers
  // one /auth/refresh call; all callers await the same in-flight Future.
  static Future<String>? _refreshingFuture;

  static Future<String?> _refreshAccessToken() {
    return _refreshingFuture ??= () async {
      try {
        return await refreshToken();
      } catch (e, s) {
        AppLog.w('API', 'Silent token refresh failed, clearing session: $e');
        AppLog.e('API', 'refresh stack', e, s);
        await clearSession();
        // Otherwise the app is left stranded on whatever screen it was on,
        // silently failing every subsequent API call with 401s — kick the
        // user back to login instead, same as IdleTimeoutWrapper does.
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
        rethrow;
      } finally {
        _refreshingFuture = null;
      }
    }();
  }

  static Future<_RawResponse> _rawGet(
    String path, {
    String? token,
  }) async {
    final res = await _rawGetOnce(path, token: token);
    if (res.statusCode == 401 && token != null) {
      try {
        final newToken = await _refreshAccessToken();
        if (newToken != null) return _rawGetOnce(path, token: newToken);
      } catch (_) {}
    }
    return res;
  }

  static Future<_RawResponse> _rawGetOnce(
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
    final res = await _rawPostOnce(path, body, token: token);
    if (res.statusCode == 401 && token != null) {
      try {
        final newToken = await _refreshAccessToken();
        if (newToken != null) return _rawPostOnce(path, body, token: newToken);
      } catch (_) {}
    }
    return res;
  }

  static Future<_RawResponse> _rawPostOnce(
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

  static Future<_RawResponse> _rawPostMultipart(
    String path, {
    Map<String, String> fields = const {},
    required List<MapEntry<String, File>> files,
    String? token,
  }) async {
    final res = await _rawPostMultipartOnce(path, fields: fields, files: files, token: token);
    if (res.statusCode == 401 && token != null) {
      try {
        final newToken = await _refreshAccessToken();
        if (newToken != null) {
          return _rawPostMultipartOnce(path, fields: fields, files: files, token: newToken);
        }
      } catch (_) {}
    }
    return res;
  }

  static Future<_RawResponse> _rawPostMultipartOnce(
    String path, {
    Map<String, String> fields = const {},
    required List<MapEntry<String, File>> files,
    String? token,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    final req = http.MultipartRequest('POST', uri);
    req.headers['Accept'] = 'application/json';
    if (token != null) req.headers['Authorization'] = 'Bearer $token';
    req.fields.addAll(fields);
    for (final e in files) {
      req.files.add(await http.MultipartFile.fromPath(e.key, e.value.path));
    }
    final streamed = await req.send();
    final body     = await streamed.stream.transform(utf8.decoder).join();
    AppLog.d('API', 'POST multipart $uri → ${streamed.statusCode}');
    return _RawResponse(streamed.statusCode, body);
  }

  static Future<_RawResponse> _rawPut(
    String path,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    final res = await _rawPutOnce(path, body, token: token);
    if (res.statusCode == 401 && token != null) {
      try {
        final newToken = await _refreshAccessToken();
        if (newToken != null) return _rawPutOnce(path, body, token: newToken);
      } catch (_) {}
    }
    return res;
  }

  static Future<_RawResponse> _rawPutOnce(
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
    final res = await _rawPatchOnce(path, body, token: token);
    if (res.statusCode == 401 && token != null) {
      try {
        final newToken = await _refreshAccessToken();
        if (newToken != null) return _rawPatchOnce(path, body, token: newToken);
      } catch (_) {}
    }
    return res;
  }

  static Future<_RawResponse> _rawPatchOnce(
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
    final res = await _rawDeleteOnce(path, token: token);
    if (res.statusCode == 401 && token != null) {
      try {
        final newToken = await _refreshAccessToken();
        if (newToken != null) return _rawDeleteOnce(path, token: newToken);
      } catch (_) {}
    }
    return res;
  }

  static Future<_RawResponse> _rawDeleteOnce(
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

  // ── Biometric token login ─────────────────────────────────────────────────

  static Future<({UserModel user, String token})> loginWithToken(String token) async {
    final raw  = await _rawGet('/auth/me', token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) {
      final data = (body['data'] as Map<String, dynamic>?) ?? body;
      final userJson = data['user'] ?? data;
      final user = UserModel.fromJson(userJson as Map<String, dynamic>);
      await _saveSession(user, token);
      return (user: user, token: token);
    }
    throw ApiException(body['message'] as String? ?? 'Session expired.', raw.statusCode);
  }

  // ── FCM device token ─────────────────────────────────────────────────────

  // Single endpoint for all roles — the backend now auto-inserts into the
  // driver_devices multi-device registry when the caller is a driver, so
  // there's no separate driver-specific call needed on the client side.
  static Future<void> saveFcmToken(String fcmToken, {required String platform}) async {
    final token = await getToken();
    if (token == null) return;
    try {
      final raw = await _rawPost('/auth/fcm-token', {
        'fcm_token': fcmToken,
        'platform':  platform,
      }, token: token);
      if (raw.statusCode != 200 && raw.statusCode != 201) {
        AppLog.w('FCM', 'saveFcmToken failed: HTTP ${raw.statusCode} ${raw.body}');
      }
    } catch (e, s) {
      AppLog.e('FCM', 'saveFcmToken failed', e, s);
    }
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
      // { "data": { "user": {...} } } — unwrap 'data' first, then 'user'.
      final data    = (body['data'] as Map<String, dynamic>?) ?? body;
      final userJson = data['user'] ?? data;
      return UserModel.fromJson(userJson as Map<String, dynamic>);
    }

    final message = body['message'] as String? ??
        body['error'] as String? ??
        'Failed to fetch user (${raw.statusCode}).';
    throw ApiException(message, raw.statusCode);
  }

  // ── Register ──────────────────────────────────────────────────────────────

  static Future<({UserModel user, String token})> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
    String  role            = 'passenger',
    String? driverType,
    String? city,
    String? referredByCode,
  }) async {
    final payload = <String, dynamic>{
      'name':                  name,
      'email':                 email,
      'password':              password,
      'password_confirmation': passwordConfirmation,
      'role':                  role,
      if (phone          != null) 'phone':            phone,
      if (driverType     != null) 'driver_type':      driverType,
      if (city           != null) 'city':             city,
      if (referredByCode != null) 'referred_by_code': referredByCode,
    };
    final raw  = await _rawPost('/auth/register', payload);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200 || raw.statusCode == 201) {
      final data        = (body['data'] as Map<String, dynamic>?) ?? body;
      final userJson    = data['user'] ?? data;
      final accessToken = data['access_token'] as String? ?? data['token'] as String?;
      if (userJson == null || accessToken == null) {
        throw ApiException('Server response missing user or token.', raw.statusCode);
      }
      final user = UserModel.fromJson(userJson as Map<String, dynamic>);
      await _saveSession(user, accessToken,
          refreshToken: data['refresh_token'] as String?);
      return (user: user, token: accessToken);
    }
    throw ApiException(body['message'] as String? ?? 'Registration failed.', raw.statusCode);
  }

  // ── Refresh token ─────────────────────────────────────────────────────────

  static Future<String> refreshToken() async {
    final refresh = await getRefreshToken();
    if (refresh == null) throw const ApiException('No refresh token.', 401);
    final raw  = await _rawPost('/auth/refresh', {'refresh_token': refresh});
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) {
      final data  = (body['data'] as Map<String, dynamic>?) ?? body;
      final token = data['access_token'] as String? ?? data['token'] as String?;
      if (token == null) throw const ApiException('No token in refresh response.', 500);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyToken, token);
      if (data['refresh_token'] != null) {
        await prefs.setString(_keyRefreshToken, data['refresh_token'] as String);
      }
      return token;
    }
    throw ApiException(body['message'] as String? ?? 'Token refresh failed.', raw.statusCode);
  }

  // ── Update profile ────────────────────────────────────────────────────────

  static Future<UserModel> updateProfile({
    String? name,
    String? phone,
    String? email,
    // Driver-only fields.
    String? statusNote,
    String? driverType, // 'owner' | 'company_staff' | 'rental'
    String? companyName,
  }) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final payload = <String, dynamic>{
      if (name        != null) 'name':         name,
      if (phone       != null) 'phone':        phone,
      if (email       != null) 'email':        email,
      if (statusNote  != null) 'status_note':  statusNote,
      if (driverType  != null) 'driver_type':  driverType,
      if (companyName != null) 'company_name': companyName,
    };
    final raw  = await _rawPut('/auth/profile', payload, token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) {
      final data = (body['data'] as Map<String, dynamic>?) ?? body;
      final user = UserModel.fromJson((data['user'] as Map<String, dynamic>?) ?? data);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyName,  user.name);
      await prefs.setString(_keyEmail, user.email);
      await prefs.setString(_keyPhone, user.phone);
      return user;
    }
    throw ApiException(body['message'] as String? ?? 'Profile update failed.', raw.statusCode);
  }

  // ── Avatar upload / delete ────────────────────────────────────────────────

  static Future<String> uploadAvatar(File photo) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawPostMultipart('/upload/avatar',
        files: [MapEntry('avatar', photo)], token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200 || raw.statusCode == 201) {
      final data = (body['data'] as Map<String, dynamic>?) ?? body;
      return data['avatar_url'] as String? ?? data['url'] as String? ?? '';
    }
    throw ApiException(body['message'] as String? ?? 'Upload failed.', raw.statusCode);
  }

  static Future<void> deleteAvatar() async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw = await _rawDelete('/upload/avatar', token: token);
    if (raw.statusCode == 200 || raw.statusCode == 204) return;
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  // ── Surge zone check ──────────────────────────────────────────────────────

  static Future<List<SurgeZone>> getSurgeZones({
    double? lat, double? lng, String? type,
  }) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final params = [
      if (lat  != null) 'lat=$lat',
      if (lng  != null) 'lng=$lng',
      if (type != null) 'type=$type',
    ];
    final path = '/surge/zones${params.isNotEmpty ? '?${params.join('&')}' : ''}';
    final raw  = await _rawGet(path, token: token);
    if (raw.statusCode != 200) return [];
    final body  = jsonDecode(raw.body) as Map<String, dynamic>;
    final data  = (body['data']  as Map<String, dynamic>?) ?? body;
    final list  = (data['zones'] as List<dynamic>?) ?? [];
    return list.whereType<Map<String, dynamic>>().map(SurgeZone.fromJson).toList();
  }

  static Future<SurgeInfo> checkSurge({double? lat, double? lng}) async {
    final zones = await getSurgeZones(lat: lat, lng: lng);
    if (zones.isEmpty) return const SurgeInfo(surgeActive: false, multiplier: 1.0);

    final inside = zones.where((z) => z.youAreInside).toList();
    if (inside.isNotEmpty) {
      final best = inside.reduce((a, b) => a.multiplier >= b.multiplier ? a : b);
      return SurgeInfo(
        surgeActive:  true,
        multiplier:   best.multiplier,
        zone:         best.name,
        message:      best.description,
        endsAt:       best.endsAt,
        youAreInside: true,
      );
    }

    // Not inside any zone — show nearest/highest as a "head there" tip
    final nearby = zones.reduce((a, b) {
      if (a.multiplier != b.multiplier) return a.multiplier > b.multiplier ? a : b;
      final da = a.distanceKm ?? double.maxFinite;
      final db = b.distanceKm ?? double.maxFinite;
      return da <= db ? a : b;
    });
    return SurgeInfo(
      surgeActive:      false,
      multiplier:       nearby.multiplier,
      zone:             nearby.name,
      message:          nearby.description,
      endsAt:           nearby.endsAt,
      youAreInside:     false,
      nearbyDistanceKm: nearby.distanceKm,
    );
  }

  // ── Active ride (restore after app reopen) ────────────────────────────────

  static Future<RideModel?> getActiveRide() async {
    final token = await getToken();
    if (token == null) return null;
    final raw  = await _rawGet('/rides/active', token: token);
    if (raw.statusCode == 404) return null;
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) {
      final data     = (body['data'] as Map<String, dynamic>?) ?? body;
      final rideJson = (data['ride'] as Map<String, dynamic>?) ?? data;
      return RideModel.fromJson(rideJson);
    }
    return null;
  }

  // ── Driver: mark arrived at passenger pickup ──────────────────────────────

  static Future<RideModel> arriveAtPickup(int rideId) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawPost('/rides/$rideId/arrive', {}, token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) {
      final data = (body['data'] as Map<String, dynamic>?) ?? body;
      return RideModel.fromJson((data['ride'] as Map<String, dynamic>?) ?? data);
    }
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  // ── Driver: start trip ────────────────────────────────────────────────────

  static Future<RideModel> startTrip(int rideId) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawPost('/rides/$rideId/start', {}, token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) {
      final data = (body['data'] as Map<String, dynamic>?) ?? body;
      return RideModel.fromJson((data['ride'] as Map<String, dynamic>?) ?? data);
    }
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  // ── Ride dispute ──────────────────────────────────────────────────────────

  static Future<void> disputeRide(int rideId, {
    required String reason,
    String? description,
  }) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawPost('/rides/$rideId/dispute', {
      'reason': reason,
      if (description != null) 'description': description,
    }, token: token);
    if (raw.statusCode == 200 || raw.statusCode == 201) return;
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  // ── Public trip tracking (no auth) ───────────────────────────────────────

  static Future<PublicTripModel> getPublicTrip(String token) async {
    final raw  = await _rawGet('/track/$token');
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) {
      final data = (body['data'] as Map<String, dynamic>?) ?? body;
      return PublicTripModel.fromJson(data);
    }
    throw ApiException(body['message'] as String? ?? 'Trip not found.', raw.statusCode);
  }

  // ── Support tickets ───────────────────────────────────────────────────────

  static Future<List<SupportTicketModel>> getSupportTickets() async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawGet('/support/tickets', token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) {
      final data = (body['data'] as Map<String, dynamic>?) ?? body;
      final list = (data['tickets'] as List<dynamic>?)
          ?? (data['data'] as List<dynamic>?)
          ?? (body['data'] as List<dynamic>?)
          ?? [];
      return list.whereType<Map<String, dynamic>>()
          .map(SupportTicketModel.fromJson).toList();
    }
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  static Future<SupportTicketModel> createSupportTicket({
    required String subject,
    required String message,
    String  priority = 'normal',
    String? rideId,
  }) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawPost('/support/tickets', {
      'subject':  subject,
      'message':  message,
      'priority': priority,
      if (rideId != null) 'ride_id': rideId,
    }, token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200 || raw.statusCode == 201) {
      final data = (body['data'] as Map<String, dynamic>?) ?? body;
      return SupportTicketModel.fromJson(
          (data['ticket'] as Map<String, dynamic>?) ?? data);
    }
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  static Future<void> replySupportTicket(int ticketId, String message) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawPost('/support/tickets/$ticketId/reply',
        {'message': message}, token: token);
    if (raw.statusCode == 200 || raw.statusCode == 201) return;
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  // ── Driver vehicles ───────────────────────────────────────────────────────

  static Future<VehicleModel> registerDriverVehicle({
    required String type,
    required String make,
    required String model,
    required int    year,
    required String plate,
    String? color,
  }) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawPost('/driver/vehicles', {
      'type':  type,
      'make':  make,
      'model': model,
      'year':  year,
      'plate': plate,
      if (color != null) 'color': color,
    }, token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200 || raw.statusCode == 201) {
      final data = (body['data'] as Map<String, dynamic>?) ?? body;
      return VehicleModel.fromJson(
          (data['vehicle'] as Map<String, dynamic>?) ?? data);
    }
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  static Future<VehicleModel> updateDriverVehicle(int id, {
    String? type, String? make, String? model, int? year,
    String? plate, String? color,
  }) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawPut('/driver/vehicles/$id', {
      if (type  != null) 'type':  type,
      if (make  != null) 'make':  make,
      if (model != null) 'model': model,
      if (year  != null) 'year':  year,
      if (plate != null) 'plate': plate,
      if (color != null) 'color': color,
    }, token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) {
      final data = (body['data'] as Map<String, dynamic>?) ?? body;
      return VehicleModel.fromJson(
          (data['vehicle'] as Map<String, dynamic>?) ?? data);
    }
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  static Future<void> uploadVehicleImages(int vehicleId, List<File> photos) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final files = photos.asMap().entries
        .map((e) => MapEntry('images[${e.key}]', e.value))
        .toList();
    final raw = await _rawPostMultipart(
        '/upload/vehicle/$vehicleId/images',
        files: files, token: token);
    if (raw.statusCode == 200 || raw.statusCode == 201) return;
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
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
      final outer = (body['data'] as Map<String, dynamic>?) ?? body;
      final candidate = outer['rides'] ?? outer;
      final List<dynamic> data;
      if (candidate is List) {
        data = candidate;
      } else if (candidate is Map<String, dynamic>) {
        data = (candidate['data'] as List<dynamic>?) ?? [];
      } else {
        data = [];
      }
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
      final rideMap = Map<String, dynamic>.from(
          (data['ride'] as Map<String, dynamic>?) ?? data);
      _mergeDriverInfo(data, rideMap);
      // RideModel.fromJson only reads a plain 'stops' list — if the
      // backend nests it under a different key (e.g. 'way_stops',
      // 'ride_stops'), this call would silently look like "no stops".
      final rawStops = rideMap['stops'];
      if (rawStops == null || (rawStops is List && rawStops.isEmpty)) {
        final otherStopKeys = rideMap.keys
            .where((k) => k.toLowerCase().contains('stop'))
            .toList();
        if (otherStopKeys.isNotEmpty && otherStopKeys.first != 'stops') {
          AppLog.w('API',
              'getRide($id): stops empty but found other stop-like key(s): $otherStopKeys');
        }
      }
      return RideModel.fromJson(rideMap);
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
      final outer = (body['data'] as Map<String, dynamic>?) ?? body;

      // Handle multiple server shapes:
      //   { data: { rides: { data: [...] } } }   ← paginated object
      //   { data: { rides: [...] } }              ← plain array under 'rides'
      //   { data: [...] }                         ← array directly in data
      //   { rides: [...] }                        ← array at root
      List<dynamic> list;
      final ridesField = outer['rides'];
      if (ridesField is Map<String, dynamic>) {
        list = (ridesField['data'] as List<dynamic>?) ?? [];
      } else if (ridesField is List<dynamic>) {
        list = ridesField;
      } else if (outer['data'] is List<dynamic>) {
        list = outer['data'] as List<dynamic>;
      } else if (body['data'] is List<dynamic>) {
        list = body['data'] as List<dynamic>;
      } else {
        list = [];
      }

      return list
          .whereType<Map<String, dynamic>>()
          .map(RideModel.fromJson)
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
      final data = (body['data'] as Map<String, dynamic>?) ?? body;
      return DriverStatusModel.fromJson(data);
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

  // ── Vehicle types ─────────────────────────────────────────────────────────

  /// Public catalogue of ride vehicle types and their pricing rules
  /// (motorcycle/tuk_tuk/standard/premium/shared/van) — no auth required.
  static Future<List<VehicleTypeModel>> getVehicleTypes() async {
    final raw = await _rawGet('/vehicle-types');

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(raw.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Unexpected server response (${raw.statusCode}).', raw.statusCode);
    }

    if (raw.statusCode == 200) {
      final data  = (body['data'] as Map<String, dynamic>?) ?? body;
      final list  = data['vehicle_types'] as List<dynamic>? ?? [];
      return list
          .map((v) => VehicleTypeModel.fromJson(v as Map<String, dynamic>))
          .toList();
    }

    final message = body['message'] as String? ?? body['error'] as String? ??
        'Failed to fetch vehicle types (${raw.statusCode}).';
    throw ApiException(message, raw.statusCode);
  }

  // ── Estimate ride ─────────────────────────────────────────────────────────

  static Future<RideEstimate> estimateRide({
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
    // Intermediate waypoints, in visit order — without these the backend
    // can only price the direct pickup→dropoff distance, undercounting the
    // detour through each stop (same shape as createRide's `stops`).
    List<Map<String, dynamic>>? stops,
  }) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);

    // Deliberately does NOT send a vehicle-type filter — the backend prices
    // every service type (motorcycle/tuk_tuk/standard/premium/shared/van)
    // from its own /vehicle-types pricing rule and returns all of them in
    // one `fares` map, which the Choose Ride screen renders as a flat list.
    final raw = await _rawPost('/rides/estimate', {
      'pickup_lat':  pickupLat,
      'pickup_lng':  pickupLng,
      'dropoff_lat': dropoffLat,
      'dropoff_lng': dropoffLng,
      if (stops != null && stops.isNotEmpty) 'stops': stops,
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
    String? dropoffAddress,
    required double pickupLat,
    required double pickupLng,
    double? dropoffLat,
    double? dropoffLng,
    // Rider hasn't picked a destination yet — they'll tell the driver in
    // person and the fare is metered/GPS-calculated at trip end.
    bool    noDestination  = false,
    String  serviceType    = 'standard',
    String  vehicleType    = 'car',
    String  paymentMethod  = 'cash',
    bool    surgeAccepted  = false,
    int?    vehicleId,
    String? scheduledAt,
    String? notes,
    String? passengerName,
    String? passengerPhone,
    String? promoCode,
    // Airport trip extras
    bool    isAirportTrip  = false,
    String? flightNumber,
    String? terminal,
    int?    luggageCount,
    // Business trip extras
    bool    isBusinessTrip  = false,
    String? expenseCategory,
    String? expenseRef,
    // Family member booking
    int?    familyMemberId,
    // Intermediate waypoints (multi-stop rides), in visit order — each
    // {'address', 'lat', 'lng'}. Sent inline so the backend persists them
    // atomically with the ride instead of via a separate follow-up call.
    List<Map<String, dynamic>>? stops,
  }) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);

    final body = <String, dynamic>{
      'pickup_address':  pickupAddress,
      'pickup_lat':      pickupLat,
      'pickup_lng':      pickupLng,
      'service_type':    serviceType,
      'vehicle_type':    vehicleType,
      'payment_method':  paymentMethod,
      'surge_accepted':  surgeAccepted,
      'no_destination':  noDestination,
      if (dropoffAddress != null)   'dropoff_address':  dropoffAddress,
      if (dropoffLat      != null)  'dropoff_lat':      dropoffLat,
      if (dropoffLng      != null)  'dropoff_lng':      dropoffLng,
      if (stops != null && stops.isNotEmpty) 'stops': stops,
      if (vehicleId       != null)  'vehicle_id':       vehicleId,
      if (scheduledAt     != null)  'scheduled_at':     scheduledAt,
      if (notes           != null)  'notes':            notes,
      if (passengerName   != null)  'passenger_name':   passengerName,
      if (passengerPhone  != null)  'passenger_phone':  passengerPhone,
      if (promoCode       != null)  'promo_code':       promoCode,
      if (isAirportTrip)            'is_airport_trip':  true,
      if (flightNumber    != null)  'flight_number':    flightNumber,
      if (terminal        != null)  'terminal':         terminal,
      if (luggageCount    != null)  'luggage_count':    luggageCount,
      if (isBusinessTrip)           'is_business_trip': true,
      if (expenseCategory != null)  'expense_category': expenseCategory,
      if (expenseRef      != null)  'expense_ref':      expenseRef,
      if (familyMemberId  != null)  'family_member_id': familyMemberId,
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

  static Future<List<DeliveryModel>> getMovings({int page = 1, String? status}) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);

    final query = [
      'page=$page',
      if (status != null) 'status=$status',
    ].join('&');

    final raw = await _rawGet('/movings?$query', token: token);
    AppLog.d('Moving', 'GET /movings?$query → ${raw.statusCode}: ${raw.body}');
    return _parseDeliveryList(raw);
  }

  // ── Active delivery/moving (restore after app reopen) ────────────────────
  static Future<DeliveryModel?> getActiveDelivery() async {
    try {
      final results = await Future.wait([
        getDeliveries(status: 'accepted'),
        getDeliveries(status: 'in_progress'),
        getMovings(status: 'accepted'),
        getMovings(status: 'in_progress'),
      ]);
      for (final deliveries in results) {
        if (deliveries.isNotEmpty) return deliveries.first;
      }
      return null;
    } catch (_) {
      return null;
    }
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

  /// GET /drivers/nearby — includes lat/lng (unlike getNearbyDrivers() above,
  /// which hits the delivery-only endpoint with no coordinates) so callers
  /// can actually place a marker per driver on the map, Grab/PassApp-style.
  static Future<List<NearbyMapDriverModel>> getNearbyMapDrivers({
    required double lat,
    required double lng,
    String type = 'rides',
    double? radius,
    int limit = 20,
  }) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);

    final qs = StringBuffer('lat=$lat&lng=$lng&type=$type&limit=$limit');
    if (radius != null) qs.write('&radius=$radius');

    final raw = await _rawGet('/drivers/nearby?$qs', token: token);

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(raw.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Unexpected server response (${raw.statusCode}).', raw.statusCode);
    }

    if (raw.statusCode == 200) {
      final data = (body['data'] as Map<String, dynamic>?) ?? body;
      return (data['drivers'] as List<dynamic>? ?? [])
          .map((e) => NearbyMapDriverModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    final message = body['message'] as String? ?? 'Failed to fetch nearby drivers (${raw.statusCode}).';
    throw ApiException(message, raw.statusCode);
  }

  /// GET /events — in-app feed of active promo events for the caller's role
  /// (driver or passenger), server-side filtered. Used in place of "Recent
  /// Trips" on the home screens.
  static Future<List<PromoEventModel>> getPromoEvents() async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);

    final raw = await _rawGet('/events', token: token);

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(raw.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Unexpected server response (${raw.statusCode}).', raw.statusCode);
    }

    if (raw.statusCode == 200) {
      final data   = (body['data'] as Map<String, dynamic>?) ?? body;
      final events = (data['events'] as Map<String, dynamic>?) ?? data;
      return (events['data'] as List<dynamic>? ?? [])
          .map((e) => PromoEventModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    final message = body['message'] as String? ?? 'Failed to fetch events (${raw.statusCode}).';
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

  static Future<DeliveryModel> startDelivery(int id) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw = await _rawPost('/deliveries/$id/start', {}, token: token);
    return _parseDeliveryResponse(raw);
  }

  static Future<void> updateDeliveryLocation(
    int deliveryId, {
    required double latitude,
    required double longitude,
    double? heading,
  }) async {
    final token = await getToken();
    if (token == null) return;
    await _rawPost('/tracking/deliveries/$deliveryId', {
      'latitude':  latitude,
      'longitude': longitude,
      if (heading != null) 'heading': heading,
    }, token: token);
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
      final data = (body['data'] as Map<String, dynamic>?) ?? body;
      // Support both /deliveries (key: "deliveries") and /movings (key: "movings"),
      // and both a flat list ("deliveries": [...]) or a Laravel paginator
      // ("deliveries": { "data": [...] }) shape.
      final candidate = data['deliveries'] ?? data['movings'] ?? data;
      final List<dynamic> list;
      if (candidate is List) {
        list = candidate;
      } else if (candidate is Map<String, dynamic>) {
        list = (candidate['data'] as List<dynamic>?) ?? [];
      } else {
        list = [];
      }
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
      final data    = (body['data'] as Map<String, dynamic>?) ?? body;
      final payload = (data['delivery'] ?? data['moving'] ?? data) as Map<String, dynamic>?;
      if (payload == null) throw ApiException('Unexpected server response (${raw.statusCode}).', raw.statusCode);
      return DeliveryModel.fromJson(payload);
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

    // The accept response nests the driver/vehicle details in a sibling
    // `driver_info` object rather than inside `ride.driver`/`ride.vehicle`
    // (the shape RideModel.fromJson expects) — merge them in before
    // parsing so this data isn't silently dropped. Falls back to the
    // shared parser (and its error handling) for anything unexpected.
    Map<String, dynamic> body;
    try {
      body = jsonDecode(raw.body) as Map<String, dynamic>;
    } catch (_) {
      return _parseRideResponse(raw);
    }
    if (raw.statusCode != 200 && raw.statusCode != 201) {
      return _parseRideResponse(raw);
    }

    final outer = (body['data'] as Map<String, dynamic>?) ?? body;
    final rideJson = Map<String, dynamic>.from(
        (outer['ride'] as Map<String, dynamic>?) ?? outer);
    _mergeDriverInfo(outer, rideJson);
    return RideModel.fromJson(rideJson);
  }

  // The `driver_info` sibling object (seen on both the accept response and
  // plain GET /rides/{id}) carries vehicle/driver details that
  // RideModel.fromJson doesn't look for on its own (it only reads
  // ride.driver / ride.vehicle) — merge them in-place so they aren't lost.
  // Uses ??= so real ride.driver/ride.vehicle data (when present) wins.
  static void _mergeDriverInfo(
      Map<String, dynamic> outer, Map<String, dynamic> rideJson) {
    final driverInfo = outer['driver_info'] as Map<String, dynamic>?;
    if (driverInfo == null) return;
    rideJson['driver'] ??= {
      'name':       driverInfo['name'],
      'phone':      driverInfo['phone'],
      'avatar_url': driverInfo['avatar_url'],
      'rating':     driverInfo['rating'],
    };
    final vehicleInfo = driverInfo['vehicle'] as Map<String, dynamic>?;
    if (vehicleInfo != null &&
        (rideJson['vehicle'] == null ||
            (rideJson['vehicle'] as Map).isEmpty)) {
      rideJson['vehicle'] = {
        'license_plate': vehicleInfo['plate'],
        'make':          vehicleInfo['make'],
        'model':         vehicleInfo['model'],
        'type':          vehicleInfo['type'],
        'year':          vehicleInfo['year'],
        'color':         vehicleInfo['color'],
        'vehicle_url':   vehicleInfo['vehicle_url'],
      };
    }
  }

  static Future<RideModel> completeRide(
    int id, {
    // Manually entered final fare + destination — used for "no destination"
    // (metered) trips, where these weren't known when the ride was booked.
    int?    fareKhr,
    String? dropoffAddress,
    double? dropoffLat,
    double? dropoffLng,
  }) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final body = <String, dynamic>{
      if (fareKhr        != null) 'final_fare':      fareKhr,
      if (dropoffAddress != null) 'dropoff_address': dropoffAddress,
      if (dropoffLat      != null) 'dropoff_lat':     dropoffLat,
      if (dropoffLng      != null) 'dropoff_lng':     dropoffLng,
    };
    final raw = await _rawPost('/rides/$id/complete', body, token: token);
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

  static Future<void> ratePassenger(int rideId, double rating, {String? comment}) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final body = <String, dynamic>{
      'rating': rating,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
    };
    final raw = await _rawPost('/rides/$rideId/rate-passenger', body, token: token);
    if (raw.statusCode != 200 && raw.statusCode != 201) {
      final resBody = jsonDecode(raw.body) as Map<String, dynamic>? ?? {};
      throw ApiException(
        resBody['message'] as String? ?? 'Rating failed (${raw.statusCode}).',
        raw.statusCode,
      );
    }
  }

  static Future<Map<String, dynamic>> getDriverTrips({int page = 1, String? filter}) async {
    final token = await getToken();
    if (token == null) return {'data': [], 'total': 0};
    var url = '/driver/trips?page=$page';
    if (filter != null && filter != 'all') url += '&filter=$filter';
    final raw = await _rawGet(url, token: token);
    if (raw.statusCode != 200) return {'data': [], 'total': 0};
    return jsonDecode(raw.body) as Map<String, dynamic>;
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

  /// Updates the driver's `current_latitude`/`current_longitude` on their
  /// user record — separate from [updateDriverLocation] (which is
  /// ride-scoped, for live tracking/map display). This is what
  /// `/rides/{id}/complete` falls back to for the dropoff location when
  /// the client doesn't send explicit `dropoff_lat`/`dropoff_lng` — must
  /// be called continuously during a trip for that fallback to work.
  static Future<void> updateCurrentLocation({
    required double latitude,
    required double longitude,
  }) async {
    final token = await getToken();
    if (token == null) return;
    try {
      await _rawPost('/driver/location', {
        'latitude':  latitude,
        'longitude': longitude,
      }, token: token);
    } catch (_) {
      // Best-effort — the ride-scoped tracking call is the primary path;
      // this just keeps the fallback populated.
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

    AppLog.d('Delivery', 'POST /deliveries body: ${jsonEncode(body)}');
    final raw = await _rawPost('/deliveries', body, token: token);
    AppLog.d('Delivery', 'POST /deliveries → ${raw.statusCode}: ${raw.body}');
    return _parseDeliveryResponse(raw);
  }

  // ── Create moving order ───────────────────────────────────────────────────

  static Future<DeliveryModel> createMoving({
    required String pickupAddress,
    required String dropoffAddress,
    double? pickupLat,
    double? pickupLng,
    double? dropoffLat,
    double? dropoffLng,
    required int    floorPickup,
    required int    floorDropoff,
    required bool   hasElevator,
    required bool   needsStairsCarry,
    required bool   heavyItems,
    required int    requiresHelpers,
    String  serviceOption = 'normal',        // 'normal' | 'express'
    String  helperType    = 'normal_carry',  // 'normal_carry' | 'heavy_carry'
    String  paymentMethod = 'cash',
    String  paymentModel  = 'customer_pays',
    String? notes,
    String? scheduledAt,
    int?    fee,
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
      if (pickupLat   != null) 'pickup_lat':    pickupLat,
      if (pickupLng   != null) 'pickup_lng':    pickupLng,
      if (dropoffLat  != null) 'dropoff_lat':   dropoffLat,
      if (dropoffLng  != null) 'dropoff_lng':   dropoffLng,
      if (notes       != null) 'notes':         notes,
      if (scheduledAt != null) 'scheduled_at':  scheduledAt,
      if (fee         != null) 'fee':           fee,
    };

    AppLog.d('Moving', 'POST /movings body: ${jsonEncode(body)}');
    final raw = await _rawPost('/movings', body, token: token);
    AppLog.d('Moving', 'POST /movings → ${raw.statusCode}: ${raw.body}');
    return _parseDeliveryResponse(raw);
  }

  // ── Estimate moving order ──────────────────────────────────────────────────

  static Future<MovingEstimateModel> estimateMoving({
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
    required int    floorPickup,
    required int    floorDropoff,
    required bool   hasElevator,
    required int    requiresHelpers,
    String serviceOption = 'normal',       // 'normal' | 'express'
    String helperType    = 'normal_carry', // 'normal_carry' | 'heavy_carry'
  }) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);

    final body = <String, dynamic>{
      'pickup_lat':       pickupLat,
      'pickup_lng':       pickupLng,
      'dropoff_lat':      dropoffLat,
      'dropoff_lng':      dropoffLng,
      'service_option':   serviceOption,
      'floor_pickup':     floorPickup,
      'floor_dropoff':    floorDropoff,
      'has_elevator':     hasElevator,
      'requires_helpers': requiresHelpers,
      'helper_type':      helperType,
    };

    AppLog.d('Moving', 'POST /movings/estimate body: ${jsonEncode(body)}');
    final raw = await _rawPost('/movings/estimate', body, token: token);
    AppLog.d('Moving', 'POST /movings/estimate → ${raw.statusCode}: ${raw.body}');

    final Map<String, dynamic> responseBody;
    try {
      responseBody = jsonDecode(raw.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException(
          'Unexpected server response (${raw.statusCode}).', raw.statusCode);
    }

    if (raw.statusCode == 200 || raw.statusCode == 201) {
      return MovingEstimateModel.fromJson(responseBody);
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

  static Future<DeliveryModel> cancelMoving(int id, {String? reason}) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw = await _rawPost('/movings/$id/cancel', {
      if (reason != null) 'reason': reason,
    }, token: token);
    return _parseDeliveryResponse(raw);
  }

  static Future<DeliveryModel> completeMoving(int id) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw = await _rawPost('/movings/$id/complete', {}, token: token);
    return _parseDeliveryResponse(raw);
  }

  static Future<DeliveryModel> startMoving(int id) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw = await _rawPost('/movings/$id/start', {}, token: token);
    return _parseDeliveryResponse(raw);
  }

  static Future<void> updateMovingLocation(
    int movingId, {
    required double latitude,
    required double longitude,
    double? heading,
  }) async {
    final token = await getToken();
    if (token == null) return;
    // Endpoint: POST /movings/{id}/track — fields: lat, lng
    await _rawPost('/movings/$movingId/track', {
      'lat': latitude,
      'lng': longitude,
    }, token: token);
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
        if (comment != null) 'comment': comment,
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

  // ── Unified Trip ─────────────────────────────────────────────────

  static Future<TripListResult> getTrips({
    String filter = 'recent', // recent | day | month
    String? date,             // 2026-06-15  (when filter=day)
    String? month,            // 2026-06     (when filter=month)
    String type   = 'all',   // all | ride | delivery | moving
    String status = 'all',   // all | completed | cancelled
    int    page   = 1,
  }) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);

    final params = <String, String>{
      'filter': filter,
      'type':   type,
      'status': status,
      'page':   '$page',
      if (date  != null) 'date':  date,
      if (month != null) 'month': month,
    };
    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');

    final raw  = await _rawGet('/trips?$query', token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) return TripListResult.fromJson(body);
    throw ApiException(
        body['message'] as String? ?? 'Failed to load trips (${raw.statusCode}).',
        raw.statusCode);
  }

  static Future<List<TripMonthOption>> getTripMonths() async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);

    final raw  = await _rawGet('/trips/months', token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) {
      final data   = (body['data'] as Map<String, dynamic>?) ?? body;
      final months = data['months'] as List<dynamic>? ?? [];
      return months
          .map((e) => TripMonthOption.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw ApiException(
        body['message'] as String? ?? 'Failed to load months.',
        raw.statusCode);
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
        // data.orders[] / data.rentals[] / data.<key>[] or data.<key>.data[]
        for (final v in data.values) {
          if (v is List) return v;
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

  static Future<MarketplaceProductsPage> getMarketplaceProducts({
    String? search,
    int?    categoryId,
    int?    sellerId,
    String? listingType,  // sale | rent | both
    String? condition,    // new | used | refurbished
    double? minPrice,
    double? maxPrice,
    int?    vehicleTypeId,
    int?    vehicleColorId,
    int?    vehicleSizeId,
    int     page = 1,
  }) async {
    final token = await getToken();
    final params = <String, String>{'page': '$page'};
    if (search         != null) params['search']      = search;
    if (categoryId     != null) params['category_id'] = '$categoryId';
    if (sellerId       != null) params['seller_id']   = '$sellerId';
    if (listingType    != null) params['listing_type'] = listingType;
    if (condition      != null) params['condition']   = condition;
    if (minPrice       != null) params['min_price']   = '$minPrice';
    if (maxPrice       != null) params['max_price']   = '$maxPrice';
    if (vehicleTypeId  != null) params['marketplace_vehicle_type_id']  = '$vehicleTypeId';
    if (vehicleColorId != null) params['marketplace_vehicle_color_id'] = '$vehicleColorId';
    if (vehicleSizeId  != null) params['marketplace_vehicle_size_id']  = '$vehicleSizeId';
    final query = '?${params.entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&')}';
    final raw = await _rawGet('/marketplace$query', token: token);
    if (raw.statusCode != 200) {
      final body = jsonDecode(raw.body) as Map<String, dynamic>? ?? {};
      throw ApiException(body['message'] as String? ?? 'Failed to load products.', raw.statusCode);
    }
    return _parseProductsPage(raw.body);
  }

  static Future<List<MarketplaceVehicleTypeModel>> getMarketplaceVehicleTypes() async {
    final token = await getToken();
    final raw = await _rawGet('/marketplace/vehicle-types', token: token);
    final Map<String, dynamic> body;
    try {
      body = jsonDecode(raw.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Unexpected server response (${raw.statusCode}).', raw.statusCode);
    }
    if (raw.statusCode == 200) {
      return _extractList(body)
          .whereType<Map<String, dynamic>>()
          .map(MarketplaceVehicleTypeModel.fromJson)
          .toList();
    }
    throw ApiException(body['message'] as String? ?? 'Failed to load vehicle types.', raw.statusCode);
  }

  static Future<List<MarketplaceVehicleColorModel>> getMarketplaceVehicleColors() async {
    final token = await getToken();
    final raw = await _rawGet('/marketplace/vehicle-colors', token: token);
    final Map<String, dynamic> body;
    try {
      body = jsonDecode(raw.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Unexpected server response (${raw.statusCode}).', raw.statusCode);
    }
    if (raw.statusCode == 200) {
      return _extractList(body)
          .whereType<Map<String, dynamic>>()
          .map(MarketplaceVehicleColorModel.fromJson)
          .toList();
    }
    throw ApiException(body['message'] as String? ?? 'Failed to load vehicle colors.', raw.statusCode);
  }

  static Future<List<MarketplaceVehicleSizeModel>> getMarketplaceVehicleSizes() async {
    final token = await getToken();
    final raw = await _rawGet('/marketplace/vehicle-sizes', token: token);
    final Map<String, dynamic> body;
    try {
      body = jsonDecode(raw.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Unexpected server response (${raw.statusCode}).', raw.statusCode);
    }
    if (raw.statusCode == 200) {
      return _extractList(body)
          .whereType<Map<String, dynamic>>()
          .map(MarketplaceVehicleSizeModel.fromJson)
          .toList();
    }
    throw ApiException(body['message'] as String? ?? 'Failed to load vehicle sizes.', raw.statusCode);
  }

  /// Which vehicle_type_id/vehicle_color_id/vehicle_size_id values have at
  /// least one active listing right now, optionally scoped to a category and
  /// whichever of the other two filters are already picked — drives which
  /// Buy Item chips render as selectable vs. grayed-out/unavailable.
  static Future<MarketplaceAvailableOptions> getMarketplaceAvailableOptions({
    int? categoryId,
    int? vehicleTypeId,
    int? vehicleColorId,
    int? vehicleSizeId,
  }) async {
    final token = await getToken();
    final params = <String, String>{
      if (categoryId     != null) 'category_id': '$categoryId',
      if (vehicleTypeId  != null) 'marketplace_vehicle_type_id':  '$vehicleTypeId',
      if (vehicleColorId != null) 'marketplace_vehicle_color_id': '$vehicleColorId',
      if (vehicleSizeId  != null) 'marketplace_vehicle_size_id':  '$vehicleSizeId',
    };
    final query = params.isEmpty ? '' : '?${Uri(queryParameters: params).query}';
    final raw = await _rawGet('/marketplace/available-options$query', token: token);
    final Map<String, dynamic> body;
    try {
      body = jsonDecode(raw.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Unexpected server response (${raw.statusCode}).', raw.statusCode);
    }
    if (raw.statusCode == 200) {
      final data = (body['data'] as Map<String, dynamic>?) ?? body;
      return MarketplaceAvailableOptions.fromJson(data);
    }
    throw ApiException(body['message'] as String? ?? 'Failed to load available options.', raw.statusCode);
  }

  static MarketplaceProductsPage _parseProductsPage(String body) {
    dynamic decoded;
    try { decoded = jsonDecode(body); } catch (_) {
      return const MarketplaceProductsPage(products: [], currentPage: 1, lastPage: 1, total: 0);
    }
    Map<String, dynamic>? pagination;
    if (decoded is Map<String, dynamic>) {
      final data = decoded['data'];
      if (data is Map<String, dynamic>) {
        final products = data['products'];
        if (products is Map<String, dynamic>) pagination = products;
        else if (data['data'] is List) pagination = data;
      }
    }
    final items = _extractList(decoded)
        .whereType<Map<String, dynamic>>()
        .map(MarketplaceProductModel.fromJson)
        .toList();
    return MarketplaceProductsPage(
      products:    items,
      currentPage: (pagination?['current_page'] as num?)?.toInt() ?? 1,
      lastPage:    (pagination?['last_page']    as num?)?.toInt() ?? 1,
      total:       (pagination?['total']        as num?)?.toInt() ?? items.length,
    );
  }

  static Future<MarketplaceProductModel> getMarketplaceProduct(int id) async {
    final token = await getToken();
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
    required double price,
    required String condition,    // new | used | refurbished
    required String listingType,  // sale | rent | both
    required String status,       // draft | active
    String? description,
    String? locationText,
    double? locationLat,
    double? locationLng,
    String? expiresAt,
    int?    categoryId,
    int?    vehicleId,
    int?    vehicleTypeId,
    int?    vehicleColorId,
    int?    vehicleSizeId,
    int     quantity        = 1,
    double? rentPricePerDay,
    List<File> images       = const [],  // max 10 files, 5 MB each
    String? guestName,
    String? guestPhone,
    List<MarketplaceAccessoryInput>? accessories,
  }) async {
    final token   = await getToken();
    final isGuest = token == null;

    final uri     = Uri.parse('$_baseUrl/marketplace');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Accept'] = 'application/json';
    if (token != null) request.headers['Authorization'] = 'Bearer $token';

    request.fields['entry_type']   = isGuest ? 'guest' : 'user';
    if (isGuest && guestName  != null) request.fields['guest_name']  = guestName;
    if (isGuest && guestPhone != null) request.fields['guest_phone'] = guestPhone;
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
    if (vehicleId       != null) request.fields['vehicle_id']         = '$vehicleId';
    if (vehicleTypeId   != null) request.fields['marketplace_vehicle_type_id']  = '$vehicleTypeId';
    if (vehicleColorId  != null) request.fields['marketplace_vehicle_color_id'] = '$vehicleColorId';
    if (vehicleSizeId   != null) request.fields['marketplace_vehicle_size_id']  = '$vehicleSizeId';
    if (rentPricePerDay != null) request.fields['rent_price_per_day'] = '$rentPricePerDay';
    // Nested arrays don't survive multipart/form-data the way flat fields
    // do — JSON-encode the whole list into one field; the backend decodes it.
    if (accessories != null) {
      request.fields['accessories'] =
          jsonEncode(accessories.map((a) => a.toJson()).toList());
    }

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
    int?    vehicleId,
    int?    vehicleTypeId,
    int?    vehicleColorId,
    int?    vehicleSizeId,
    String? condition,
    String? listingType,
    double? price,
    double? rentPricePerDay,
    int?    quantity,
    String? status,   // draft | active | paused | sold
    String? locationText,
    double? locationLat,
    double? locationLng,
    String? expiresAt,
    List<MarketplaceAccessoryInput>? accessories,
  }) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final body = <String, dynamic>{
      if (title           != null) 'title':              title,
      if (description     != null) 'description':        description,
      if (categoryId      != null) 'category_id':        categoryId,
      if (vehicleId       != null) 'vehicle_id':         vehicleId,
      if (vehicleTypeId   != null) 'marketplace_vehicle_type_id':  vehicleTypeId,
      if (vehicleColorId  != null) 'marketplace_vehicle_color_id': vehicleColorId,
      if (vehicleSizeId   != null) 'marketplace_vehicle_size_id':  vehicleSizeId,
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
      // Sent as a plain array here (unlike create's multipart field) since
      // this request body is JSON, not multipart/form-data.
      if (accessories     != null) 'accessories':        accessories.map((a) => a.toJson()).toList(),
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
    String  orderType      = 'purchase', // purchase | rent
    int     quantity       = 1,
    String  paymentMethod  = 'cash',     // cash | wallet | aba | wing | other_online
    String? notes,
    String? rentStartDate,
    String? rentEndDate,
    String? promoCode,
    List<int> accessoryIds = const [],
  }) async {
    final token = await getToken();
    final body = <String, dynamic>{
      'order_type':     orderType,
      'quantity':       quantity,
      'payment_method': paymentMethod,
      if (notes         != null) 'notes':           notes,
      if (rentStartDate != null) 'rent_start_date': rentStartDate,
      if (rentEndDate   != null) 'rent_end_date':   rentEndDate,
      if (promoCode     != null) 'promo_code':      promoCode,
      if (accessoryIds.isNotEmpty) 'accessory_ids': accessoryIds,
    };
    final raw = await _rawPost('/marketplace/$productId/order', body, token: token);
    final Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(raw.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Unexpected server response (${raw.statusCode}).', raw.statusCode);
    }
    if (raw.statusCode == 200 || raw.statusCode == 201) {
      // Response: { success: true, data: { order: { ... } } }
      final data  = decoded['data'] as Map<String, dynamic>? ?? decoded;
      final order = data['order']  as Map<String, dynamic>? ?? data;
      return MarketplaceOrderModel.fromJson(order);
    }
    throw ApiException(decoded['message'] as String? ?? 'Failed to place order.', raw.statusCode);
  }

  /// POST /marketplace/checkout — atomic multi-item order (all-or-nothing;
  /// 0 orders created if any item fails). Replaces firing placeMarketplaceOrder()
  /// once per item, which could partially succeed and leave a half-placed cart.
  static Future<List<MarketplaceOrderModel>> checkoutMarketplaceCart({
    required List<MarketplaceCheckoutItem> items,
    String  paymentMethod = 'cash',
    String? notes,
    String? promoCode,
  }) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final body = <String, dynamic>{
      'items': items.map((i) => i.toJson()).toList(),
      'payment_method': paymentMethod,
      if (notes     != null) 'notes':      notes,
      if (promoCode != null) 'promo_code': promoCode,
    };
    final raw = await _rawPost('/marketplace/checkout', body, token: token);
    final Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(raw.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Unexpected server response (${raw.statusCode}).', raw.statusCode);
    }
    if (raw.statusCode == 200 || raw.statusCode == 201) {
      final data = decoded['data'] as Map<String, dynamic>? ?? decoded;
      return _extractList(data)
          .whereType<Map<String, dynamic>>()
          .map(MarketplaceOrderModel.fromJson)
          .toList();
    }
    throw ApiException(decoded['message'] as String? ?? 'Checkout failed.', raw.statusCode);
  }

  static Future<List<MarketplaceOrderModel>> getMyMarketplaceOrders({
    String type = 'buying', // buying | selling | rental
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

  /// Exchanges a Firebase Phone Auth ID token for an app session
  /// (production phone-login flow — Firebase sends the real SMS client-side,
  /// this just hands the resulting ID token to the backend to mint tokens).
  static Future<({UserModel user, String token})> verifyFirebasePhone(String idToken) async {
    final raw = await _rawPost('/auth/phone/verify', {
      'firebase_id_token': idToken,
    });

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(raw.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Unexpected server response (${raw.statusCode}).', raw.statusCode);
    }

    if (raw.statusCode == 200 || raw.statusCode == 201) {
      final data        = (body['data'] as Map<String, dynamic>?) ?? body;
      final userJson    = data['user'];
      final accessToken = data['access_token'] as String? ?? data['token'] as String?;
      if (userJson == null || accessToken == null) {
        throw ApiException('Phone verified but no session returned.', raw.statusCode);
      }
      final user = UserModel.fromJson(userJson as Map<String, dynamic>);
      await _saveSession(user, accessToken,
          refreshToken: data['refresh_token'] as String?);
      return (user: user, token: accessToken);
    }

    final message = body['message'] as String? ?? body['error'] as String? ??
        'Phone verification failed (${raw.statusCode}).';
    throw ApiException(message, raw.statusCode);
  }

  /// Verify OTP and return the logged-in user + token (dev-only mock flow —
  /// use [verifyFirebasePhone] in production).
  static Future<({UserModel user, String token})> loginWithOtp(String phone, String code) async {
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

    if (raw.statusCode == 200 || raw.statusCode == 201) {
      final data        = (body['data'] as Map<String, dynamic>?) ?? body;
      final userJson    = data['user'];
      final accessToken = data['access_token'] as String? ?? data['token'] as String?;
      if (userJson == null || accessToken == null) {
        throw ApiException('OTP verified but no session returned.', raw.statusCode);
      }
      final user = UserModel.fromJson(userJson as Map<String, dynamic>);
      await _saveSession(user, accessToken,
          refreshToken: data['refresh_token'] as String?);
      return (user: user, token: accessToken);
    }

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

  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyEmail);
  }

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
      final data = (body['data'] as Map<String, dynamic>?) ?? body;
      return WalletModel.fromJson(data);
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
      // 'data' may be a flat array of transactions, or a nested object
      // ({ transactions / data: [...], pagination fields }) — support both.
      final rawData = body['data'];
      final Map<String, dynamic> data = rawData is Map<String, dynamic>
          ? rawData
          : rawData is List ? {...body, 'transactions': rawData} : body;
      return WalletTransactionsPage.fromJson(data);
    }

    final message = body['message'] as String? ?? body['error'] as String? ??
        'Failed to load transactions (${raw.statusCode}).';
    throw ApiException(message, raw.statusCode);
  }

  // ── Safety ─────────────────────────────────────────────────────────────────

  static Future<FakeCallResult> triggerFakeCall({int delaySeconds = 5}) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw = await _rawPost('/safety/fake-call', {'delay_seconds': delaySeconds}, token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200 || raw.statusCode == 201) {
      final data = (body['data'] as Map<String, dynamic>?) ?? body;
      return FakeCallResult.fromJson(data);
    }
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  static Future<SosResult> sendSos(int rideId) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw = await _rawPost('/rides/$rideId/sos', {}, token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200 || raw.statusCode == 201) {
      final data = (body['data'] as Map<String, dynamic>?) ?? body;
      return SosResult.fromJson(data);
    }
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  static Future<ShareTripResult> shareTrip(int rideId) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw = await _rawPost('/rides/$rideId/share', {}, token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200 || raw.statusCode == 201) {
      final data = (body['data'] as Map<String, dynamic>?) ?? body;
      return ShareTripResult.fromJson(data);
    }
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  static Future<void> stopSharingTrip(int rideId) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw = await _rawDelete('/rides/$rideId/share', token: token);
    if (raw.statusCode == 200 || raw.statusCode == 204) return;
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  static Future<String> getMaskedPhone(int rideId) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw = await _rawGet('/rides/$rideId/masked-phone', token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) {
      final data = (body['data'] as Map<String, dynamic>?) ?? body;
      return data['phone'] as String? ?? '';
    }
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  static Future<List<EmergencyContactModel>> getEmergencyContacts() async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw = await _rawGet('/emergency-contacts', token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) {
      final list = (body['data'] as List<dynamic>?)
          ?? (body['emergency_contacts'] as List<dynamic>?)
          ?? [];
      return list.whereType<Map<String, dynamic>>()
          .map(EmergencyContactModel.fromJson).toList();
    }
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  static Future<EmergencyContactModel> addEmergencyContact({
    required String name,
    required String phone,
    String? relationship,
    bool notifyOnSos = true,
    bool notifyOnTripShare = true,
  }) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final payload = <String, dynamic>{
      'name': name, 'phone': phone,
      'notify_on_sos': notifyOnSos,
      'notify_on_trip_share': notifyOnTripShare,
    };
    if (relationship != null) payload['relationship'] = relationship;
    final raw = await _rawPost('/emergency-contacts', payload, token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200 || raw.statusCode == 201) {
      final data = (body['data'] as Map<String, dynamic>?) ?? body;
      return EmergencyContactModel.fromJson(data);
    }
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  static Future<EmergencyContactModel> updateEmergencyContact(int id, {
    String? name, String? phone,
    bool? notifyOnSos, bool? notifyOnTripShare,
  }) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final payload = <String, dynamic>{};
    if (name != null) payload['name'] = name;
    if (phone != null) payload['phone'] = phone;
    if (notifyOnSos != null) payload['notify_on_sos'] = notifyOnSos;
    if (notifyOnTripShare != null) payload['notify_on_trip_share'] = notifyOnTripShare;
    final raw = await _rawPut('/emergency-contacts/$id', payload, token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) {
      final data = (body['data'] as Map<String, dynamic>?) ?? body;
      return EmergencyContactModel.fromJson(data);
    }
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  static Future<void> deleteEmergencyContact(int id) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw = await _rawDelete('/emergency-contacts/$id', token: token);
    if (raw.statusCode == 200 || raw.statusCode == 204) return;
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  static Future<void> reportSafetyIncident({
    required String type,
    required String description,
    int? rideId,
  }) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final payload = <String, dynamic>{'type': type, 'description': description};
    if (rideId != null) payload['ride_id'] = rideId;
    final raw = await _rawPost('/safety-incidents', payload, token: token);
    if (raw.statusCode == 200 || raw.statusCode == 201) return;
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  static Future<void> sendSosAlert({required int rideId, String? message}) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final payload = <String, dynamic>{'ride_id': rideId};
    if (message != null) payload['message'] = message;
    final raw = await _rawPost('/sos/alert', payload, token: token);
    if (raw.statusCode == 200 || raw.statusCode == 201) return;
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  // ── Notifications ─────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getNotifications() async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawGet('/notifications', token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) {
      final list = (body['data'] as List<dynamic>?)
          ?? (body['notifications'] as List<dynamic>?)
          ?? [];
      return list.whereType<Map<String, dynamic>>().toList();
    }
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  static Future<void> markNotificationRead(int id) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    await _rawPost('/notifications/$id/read', {}, token: token);
  }

  static Future<void> markAllNotificationsRead() async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    await _rawPost('/notifications/read-all', {}, token: token);
  }

  // ── Saved Places ──────────────────────────────────────────────────────────

  static Future<List<SavedPlaceModel>> getSavedPlaces() async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawGet('/saved-places', token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) {
      // 'data' may be a flat array, or a nested object
      // ({ saved_places / data: [...] }) — support both shapes.
      final rawData = body['data'];
      final List<dynamic> list;
      if (rawData is List) {
        list = rawData;
      } else if (rawData is Map<String, dynamic>) {
        list = (rawData['saved_places'] as List<dynamic>?) ?? (rawData['data'] as List<dynamic>?) ?? [];
      } else {
        list = (body['saved_places'] as List<dynamic>?) ?? [];
      }
      return list.whereType<Map<String, dynamic>>().map(SavedPlaceModel.fromJson).toList();
    }
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  static Future<SavedPlaceModel> addSavedPlace({
    required String label,
    required String address,
    required double lat,
    required double lng,
    String? icon,
    bool isDefault = false,
  }) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final payload = <String, dynamic>{
      'label': label, 'address': address, 'lat': lat, 'lng': lng,
      'is_default': isDefault,
      if (icon != null) 'icon': icon,
    };
    final raw  = await _rawPost('/saved-places', payload, token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200 || raw.statusCode == 201) {
      final data = (body['data'] as Map<String, dynamic>?) ?? body;
      return SavedPlaceModel.fromJson(data);
    }
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  static Future<SavedPlaceModel> updateSavedPlace(int id, {
    String? label, String? address, double? lat, double? lng,
    String? icon, bool? isDefault,
  }) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final payload = <String, dynamic>{
      if (label     != null) 'label':      label,
      if (address   != null) 'address':    address,
      if (lat       != null) 'lat':        lat,
      if (lng       != null) 'lng':        lng,
      if (icon      != null) 'icon':       icon,
      if (isDefault != null) 'is_default': isDefault,
    };
    final raw  = await _rawPut('/saved-places/$id', payload, token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) {
      final data = (body['data'] as Map<String, dynamic>?) ?? body;
      return SavedPlaceModel.fromJson(data);
    }
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  static Future<void> deleteSavedPlace(int id) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawDelete('/saved-places/$id', token: token);
    if (raw.statusCode == 200 || raw.statusCode == 204) return;
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  // ── Multi-stop rides ──────────────────────────────────────────────────────

  static Future<List<RideStopModel>> getRideStops(int rideId) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawGet('/rides/$rideId/stops', token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) {
      final list = _extractStopsList(body['data']);
      if (list.isEmpty) {
        // Log the raw shape so a genuine backend data/shape mismatch is
        // distinguishable from "this ride really has no stops" — this
        // response has been observed coming back empty for rides that
        // should have stops.
        AppLog.w('API', 'getRideStops($rideId): empty after 200 — raw body: ${raw.body}');
      }
      return list.whereType<Map<String, dynamic>>().map(RideStopModel.fromJson).toList();
    }
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  // 'data' has been observed as either a flat array, or an object wrapping
  // the array under 'stops'/'data'/'items' (e.g. a pagination envelope) —
  // handle both shapes instead of assuming it's always a List.
  static List<dynamic> _extractStopsList(dynamic data) {
    if (data is List<dynamic>) return data;
    if (data is Map<String, dynamic>) {
      for (final key in ['stops', 'data', 'items']) {
        final v = data[key];
        if (v is List<dynamic>) return v;
      }
    }
    return const [];
  }

  static Future<List<RideStopModel>> addRideStops(int rideId, List<Map<String, dynamic>> stops) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawPost('/rides/$rideId/stops', {'stops': stops}, token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200 || raw.statusCode == 201) {
      final list = _extractStopsList(body['data']);
      return list.whereType<Map<String, dynamic>>().map(RideStopModel.fromJson).toList();
    }
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  static Future<void> arriveAtRideStop(int rideId, int stopId) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawPost('/rides/$rideId/stops/$stopId/arrive', {}, token: token);
    if (raw.statusCode == 200 || raw.statusCode == 201) return;
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  // ── Re-order last ride ────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getReorderLast() async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawGet('/rides/reorder-last', token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) return (body['data'] as Map<String, dynamic>?) ?? body;
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  // ── Driver arrive timeout ─────────────────────────────────────────────────

  static Future<void> reportDriverTimeout(int rideId, {int timeoutMinutes = 5}) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawPost('/rides/$rideId/timeout',
        {'timeout_minutes': timeoutMinutes}, token: token);
    if (raw.statusCode == 200 || raw.statusCode == 201) return;
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  // ── Cancel ride (with fee) ────────────────────────────────────────────────

  static Future<CancelRideResult> cancelRideWithReason(int rideId, {String? reason}) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final payload = <String, dynamic>{if (reason != null) 'reason': reason};
    final raw  = await _rawPost('/rides/$rideId/cancel', payload, token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) {
      final data = (body['data'] as Map<String, dynamic>?) ?? body;
      return CancelRideResult.fromJson(data);
    }
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  // ── Multi-stop delivery ───────────────────────────────────────────────────

  static Future<List<DeliveryStopModel>> getDeliveryStops(int deliveryId) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawGet('/deliveries/$deliveryId/stops', token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) {
      final list = (body['data'] as List<dynamic>?) ?? [];
      return list.whereType<Map<String, dynamic>>().map(DeliveryStopModel.fromJson).toList();
    }
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  static Future<List<DeliveryStopModel>> addDeliveryStops(
      int deliveryId, List<Map<String, dynamic>> stops) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawPost('/deliveries/$deliveryId/stops', {'stops': stops}, token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200 || raw.statusCode == 201) {
      final list = (body['data'] as List<dynamic>?) ?? [];
      return list.whereType<Map<String, dynamic>>().map(DeliveryStopModel.fromJson).toList();
    }
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  // ── Proof of delivery ─────────────────────────────────────────────────────

  static Future<void> submitDeliveryProof(int deliveryId, File photo) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw = await _rawPostMultipart('/deliveries/$deliveryId/proof',
        files: [MapEntry('photo', photo)], token: token);
    if (raw.statusCode == 200 || raw.statusCode == 201) return;
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  static Future<void> submitDeliveryStopProof(int deliveryId, int stopId, File photo) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw = await _rawPostMultipart('/deliveries/$deliveryId/stops/$stopId/proof',
        files: [MapEntry('photo', photo)], token: token);
    if (raw.statusCode == 200 || raw.statusCode == 201) return;
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  // ── Live driver location (delivery) ──────────────────────────────────────

  static Future<DriverLocationModel> getDeliveryDriverLocation(int deliveryId) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawGet('/deliveries/$deliveryId/driver-location', token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) {
      final data   = (body['data'] as Map<String, dynamic>?) ?? body;
      final driver = (data['driver'] as Map<String, dynamic>?) ?? data;
      return DriverLocationModel.fromJson(driver);
    }
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  // ── Promo code validation ─────────────────────────────────────────────────

  static Future<PromoValidationResult> validatePromoCode({
    required String code,
    required String serviceType,
    required int orderAmount,
  }) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawPost('/promo-codes/validate',
        {'code': code, 'service_type': serviceType, 'order_amount': orderAmount},
        token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) {
      final data = (body['data'] as Map<String, dynamic>?) ?? body;
      return PromoValidationResult.fromJson(data);
    }
    throw ApiException(body['message'] as String? ?? 'Invalid promo code.', raw.statusCode);
  }

  // ── Driver earnings ────────────────────────────────────────────────────────

  /// GET /driver/earnings/summary — dashboard summary card.
  static Future<DriverEarningsSummaryModel> getDriverEarningsSummary() async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawGet('/driver/earnings/summary', token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) {
      final data = (body['data'] as Map<String, dynamic>?) ?? body;
      return DriverEarningsSummaryModel.fromJson(data);
    }
    throw ApiException(body['message'] as String? ?? 'Failed to load earnings summary.', raw.statusCode);
  }

  /// GET /driver/earnings?period=daily|weekly|monthly
  static Future<DriverEarningsModel> getDriverEarningsByPeriod({String period = 'daily'}) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawGet('/driver/earnings?period=$period', token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) {
      final data = (body['data'] as Map<String, dynamic>?) ?? body;
      return DriverEarningsModel.fromJson(data);
    }
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  /// GET /driver/earnings/history?days=7 — zero-filled daily chart data.
  static Future<List<DriverEarningsHistoryItem>> getDriverEarningsHistory({int days = 7}) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawGet('/driver/earnings/history?days=$days', token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) {
      final data  = (body['data'] as Map<String, dynamic>?) ?? body;
      final items = (data['items'] as List<dynamic>?) ?? [];
      return items
          .whereType<Map<String, dynamic>>()
          .map(DriverEarningsHistoryItem.fromJson)
          .toList();
    }
    throw ApiException(body['message'] as String? ?? 'Failed to load earnings history.', raw.statusCode);
  }

  // ── Driver incentives ─────────────────────────────────────────────────────

  static Future<List<DriverIncentiveModel>> getDriverIncentives() async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawGet('/driver/incentives', token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) {
      final list = (body['data'] as List<dynamic>?) ?? (body['incentives'] as List<dynamic>?) ?? [];
      return list.whereType<Map<String, dynamic>>().map(DriverIncentiveModel.fromJson).toList();
    }
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  // ── Driver ride history (with earnings summary) ────────────────────────────

  static Future<DriverRideHistoryResult> getDriverRideHistory({
    String? status,
    String? from,
    String? to,
    int page = 1,
    int perPage = 15,
  }) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final uri = Uri(path: '/driver/rides', queryParameters: {
      'page':     '$page',
      'per_page': '$perPage',
      if (status != null) 'status': status,
      if (from   != null) 'from':   from,
      if (to     != null) 'to':     to,
    });
    final raw = await _rawGet(uri.toString(), token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) {
      final data       = (body['data'] as Map<String, dynamic>?) ?? body;
      final summaryJson = (data['summary'] as Map<String, dynamic>?) ?? const {};
      final ridesJson   = (data['rides'] as List<dynamic>?) ?? const [];
      final pageJson    = (data['pagination'] as Map<String, dynamic>?) ?? const {};
      return DriverRideHistoryResult(
        summary: DriverRideSummary.fromJson(summaryJson),
        rides: ridesJson
            .whereType<Map<String, dynamic>>()
            .map(RideModel.fromJson)
            .toList(),
        currentPage: (pageJson['current_page'] as num?)?.toInt() ?? page,
        lastPage:    (pageJson['last_page']    as num?)?.toInt() ?? page,
      );
    }
    throw ApiException(body['message'] as String? ?? 'Failed to load ride history.', raw.statusCode);
  }

  // ── Driver cancellation status ────────────────────────────────────────────

  static Future<Map<String, dynamic>> getDriverCancellationStatus() async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawGet('/driver/cancellation-status', token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) return (body['data'] as Map<String, dynamic>?) ?? body;
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  // ── Driver documents ─────────────────────────────────────────────────────

  static Future<void> uploadDriverDocument({
    required String type,
    required File   file,
  }) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw = await _rawPostMultipart(
      '/driver/documents',
      fields: {'type': type},
      files:  [MapEntry('file', file)],
      token:  token,
    );
    if (raw.statusCode == 200 || raw.statusCode == 201) return;
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    throw ApiException(body['message'] as String? ?? 'Upload failed.', raw.statusCode);
  }

  static Future<List<DriverDocument>> getDriverDocuments() async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawGet('/driver/documents', token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) {
      final list = (body['data'] as List<dynamic>?) ?? [];
      return list.whereType<Map<String, dynamic>>().map(DriverDocument.fromJson).toList();
    }
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  // ── Driver approval status ────────────────────────────────────────────────

  static Future<DriverApprovalStatus> getDriverApprovalStatus() async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawGet('/driver/approval-status', token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) {
      final data = (body['data'] as Map<String, dynamic>?) ?? body;
      return DriverApprovalStatus.fromJson(data);
    }
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  // ── Admin — driver approval ───────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getAdminPendingDrivers() async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawGet('/admin/drivers/pending', token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) {
      final list = (body['data'] as List<dynamic>?) ?? [];
      return list.whereType<Map<String, dynamic>>().toList();
    }
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  static Future<void> adminApproveDriver(int driverId, {
    required String action,
    String? reason,
    String? serviceZone,
  }) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final payload = <String, dynamic>{'action': action};
    if (reason      != null) payload['reason']       = reason;
    if (serviceZone != null) payload['service_zone'] = serviceZone;
    final raw  = await _rawPost('/admin/drivers/$driverId/approve', payload, token: token);
    if (raw.statusCode == 200 || raw.statusCode == 201) return;
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  static Future<Map<String, dynamic>> adminGetDriverWithDocuments(int driverId) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawGet('/admin/drivers/$driverId/documents', token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) {
      return (body['data'] as Map<String, dynamic>?) ?? body;
    }
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  static Future<void> adminReviewDriverDocument(int driverId, int docId, {
    required String action,
    String? note,
  }) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final payload = <String, dynamic>{'action': action};
    if (note != null) payload['note'] = note;
    final raw = await _rawPost(
      '/admin/drivers/$driverId/documents/$docId/review',
      payload,
      token: token,
    );
    if (raw.statusCode == 200 || raw.statusCode == 201) return;
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  // ── Heat map ──────────────────────────────────────────────────────────────

  static Future<List<HeatMapPoint>> getDriverHeatmap() async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawGet('/driver/heatmap', token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) {
      final list = (body['data'] as List<dynamic>?) ?? [];
      return list.whereType<Map<String, dynamic>>().map(HeatMapPoint.fromJson).toList();
    }
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  // POST /rides/{id}/tip
  static Future<int> tipDriver(int rideId, {required int amountKhr}) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawPost('/rides/$rideId/tip', {'amount': amountKhr}, token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200 || raw.statusCode == 201) {
      final data = body['data'] as Map<String, dynamic>? ?? {};
      return data['tip_amount'] as int? ?? amountKhr;
    }
    throw ApiException(body['message'] as String? ?? 'Failed to send tip.', raw.statusCode);
  }

  // POST /wallet/transfer
  static Future<WalletTransferResult> walletTransfer({
    required String phone,
    required int amountKhr,
    String? note,
  }) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final payload = <String, dynamic>{'phone': phone, 'amount': amountKhr};
    if (note != null && note.isNotEmpty) payload['note'] = note;
    final raw  = await _rawPost('/wallet/transfer', payload, token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200 || raw.statusCode == 201) {
      return WalletTransferResult.fromJson(body['data'] as Map<String, dynamic>? ?? {});
    }
    throw ApiException(body['message'] as String? ?? 'Transfer failed.', raw.statusCode);
  }

  // GET /charging-stations?lat=&lng=
  static Future<List<ChargingStationModel>> getChargingStations({
    double? lat,
    double? lng,
  }) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final params = <String, String>{};
    if (lat != null) params['lat'] = lat.toString();
    if (lng != null) params['lng'] = lng.toString();
    final query = params.isEmpty ? '' : '?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}';
    final raw  = await _rawGet('/charging-stations$query', token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) {
      final data    = body['data'] as Map<String, dynamic>? ?? {};
      final list    = data['charging_stations'] as List<dynamic>? ?? [];
      return list.whereType<Map<String, dynamic>>().map(ChargingStationModel.fromJson).toList();
    }
    throw ApiException(body['message'] as String? ?? 'Failed to load stations.', raw.statusCode);
  }

  // ── Scheduled rides ─────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getScheduledRides() async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawGet('/rides/scheduled', token: token);
    if (raw.statusCode != 200) return [];
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    final data = body['data'];
    if (data is List) return List<Map<String, dynamic>>.from(data);
    if (data is Map<String, dynamic>) {
      final inner = data['data'] ?? data['rides'];
      if (inner is List) return List<Map<String, dynamic>>.from(inner);
    }
    return [];
  }

  static Future<void> cancelScheduledRide(int rideId) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawPost('/rides/$rideId/cancel', {}, token: token);
    if (raw.statusCode != 200) {
      final body = jsonDecode(raw.body) as Map<String, dynamic>;
      throw ApiException(body['message'] as String? ?? 'Cancel failed', raw.statusCode);
    }
  }

  // ── Loyalty / Rewards ────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getLoyaltyPoints() async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawGet('/loyalty', token: token);
    if (raw.statusCode != 200) return {'points': 0, 'tier': 'bronze', 'history': []};
    return jsonDecode(raw.body) as Map<String, dynamic>;
  }

  static Future<void> redeemPoints(int points) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawPost('/loyalty/redeem', {'points': points}, token: token);
    if (raw.statusCode != 200 && raw.statusCode != 201) {
      final body = jsonDecode(raw.body) as Map<String, dynamic>;
      throw ApiException(body['message'] as String? ?? 'Redemption failed', raw.statusCode);
    }
  }

  // ── Referrals ────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getReferralInfo() async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawGet('/referrals', token: token);
    if (raw.statusCode != 200) {
      return {'code': 'AUTORIDE', 'referred_count': 0, 'points_earned': 0, 'referrals': []};
    }
    return jsonDecode(raw.body) as Map<String, dynamic>;
  }

  // ── Car Rental ───────────────────────────────────────────────────────────────

  static String _fmtDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')}';

  static Future<List<Map<String, dynamic>>> getCarRentalCatalog({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final params = <String, String>{};
    if (startDate != null) params['start_date'] = _fmtDate(startDate);
    if (endDate   != null) params['end_date']   = _fmtDate(endDate);
    final query = params.isEmpty ? '' : '?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}';
    final token = await getToken();
    final raw   = await _rawGet('/rentals/catalog$query', token: token);
    if (raw.statusCode != 200) return [];
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    final catalog = body['catalog'];
    return catalog is List ? List<Map<String, dynamic>>.from(catalog) : [];
  }

  static Future<Map<String, dynamic>> createCarRental({
    required String pickupLocation,
    required DateTime startDate,
    required DateTime endDate,
    int?    marketplaceProductId,
    String? vehicleType,   // required only when no marketplaceProductId
    double? pickupLat,
    double? pickupLng,
    String? paymentMethod, // cash | wallet | aba | wing | other_online
    String? notes,
  }) async {
    final token = await getToken();
    final raw = await _rawPost('/rentals', {
      if (marketplaceProductId != null) 'marketplace_product_id': marketplaceProductId,
      if (vehicleType != null) 'vehicle_type': vehicleType,
      'pickup_location':  pickupLocation,
      if (pickupLat != null) 'pickup_lat': pickupLat,
      if (pickupLng != null) 'pickup_lng': pickupLng,
      'start_date':       _fmtDate(startDate),
      'end_date':         _fmtDate(endDate),
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    }, token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode != 200 && raw.statusCode != 201) {
      throw ApiException(body['message'] as String? ?? 'Booking failed.', raw.statusCode);
    }
    // Try every common nesting: data.rental, rental, data, root
    final data = body['data'];
    if (data is Map<String, dynamic>) {
      final inner = data['rental'] as Map<String, dynamic>?;
      if (inner != null) return inner;
      return data;
    }
    final rental = body['rental'];
    if (rental is Map<String, dynamic>) return rental;
    return body;
  }

  // Unified endpoint: car rentals + marketplace rent orders combined
  static Future<List<Map<String, dynamic>>> getRentalHistory({
    String? status, // pending | confirmed | completed | cancelled
  }) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final q = <String>[];
    if (status != null) q.add('status=$status');
    final query = q.isEmpty ? '' : '?${q.join('&')}';
    final raw   = await _rawGet('/rentals/my-rentals$query', token: token);
    final body  = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode != 200) {
      throw ApiException(body['message'] as String? ?? 'Failed to load rentals.', raw.statusCode);
    }
    // { "data": { "total": N, "rentals": [...] } }
    final data = body['data'];
    if (data is Map<String, dynamic>) {
      final list = data['rentals'];
      if (list is List) return List<Map<String, dynamic>>.from(list);
    }
    return [];
  }

  static Future<Map<String, dynamic>?> getRentalById(int id) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw   = await _rawGet('/rentals/$id', token: token);
    if (raw.statusCode != 200) return null;
    final body  = jsonDecode(raw.body) as Map<String, dynamic>;
    return (body['rental'] as Map<String, dynamic>?) ?? body;
  }

  static Future<void> cancelCarRental(int id) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawPost('/rentals/$id/cancel', {}, token: token);
    if (raw.statusCode != 200 && raw.statusCode != 201) {
      final body = jsonDecode(raw.body) as Map<String, dynamic>? ?? {};
      throw ApiException(body['message'] as String? ?? 'Cancel failed.', raw.statusCode);
    }
  }

  // ── Driver: rental requests ───────────────────────────────────────────────
  // "Available rentals" for a driver/vehicle-owner are their own pending
  // bookings — GET /rentals?status=pending ("My bookings" per the API docs).
  // (/rentals/available is a public, no-auth car-browsing endpoint, not this.)

  static Future<List<Map<String, dynamic>>> getAvailableRentals() async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw = await _rawGet('/rentals?status=pending', token: token);
    final Map<String, dynamic> body;
    try {
      body = jsonDecode(raw.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Unexpected server response (${raw.statusCode}).', raw.statusCode);
    }
    if (raw.statusCode != 200) {
      throw ApiException(body['message'] as String? ?? 'Failed to load rentals.', raw.statusCode);
    }
    return _extractList(body).whereType<Map<String, dynamic>>().toList();
  }

  static Future<void> acceptRentalRequest(int id) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw = await _rawPost('/rentals/$id/accept', {}, token: token);
    if (raw.statusCode != 200 && raw.statusCode != 201) {
      final body = jsonDecode(raw.body) as Map<String, dynamic>? ?? {};
      throw ApiException(body['message'] as String? ?? 'Accept failed.', raw.statusCode);
    }
  }

  // There's no dedicated "decline" endpoint — rejecting a pending booking
  // uses the same /cancel action as a customer cancellation.
  static Future<void> declineRentalRequest(int id) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw = await _rawPost('/rentals/$id/cancel', {}, token: token);
    if (raw.statusCode != 200 && raw.statusCode != 201) {
      final body = jsonDecode(raw.body) as Map<String, dynamic>? ?? {};
      throw ApiException(body['message'] as String? ?? 'Decline failed.', raw.statusCode);
    }
  }

  // ── Promo code ───────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> applyPromoCode(
      String code, int orderAmount, {String serviceType = 'ride'}) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawPost('/promo/apply', {
      'code':         code,
      'service_type': serviceType,
      'order_amount': orderAmount,
    }, token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode != 200) {
      throw ApiException(body['message'] as String? ?? 'Invalid promo code', raw.statusCode);
    }
    return body;
  }

  // ── Social Login ─────────────────────────────────────────────────────────────

  static Future<({UserModel user, String token})> socialLogin({
    required String provider,
    required String providerToken,
  }) async {
    final raw  = await _rawPost('/auth/social', {
      'provider': provider,
      'token':    providerToken,
    });
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) {
      final data = (body['data'] as Map<String, dynamic>?) ?? body;
      final userJson    = data['user'];
      final accessToken = data['access_token'] as String? ?? data['token'] as String?;
      if (userJson == null || accessToken == null) {
        throw ApiException('Missing user or token in social login response.', raw.statusCode);
      }
      final user = UserModel.fromJson(userJson as Map<String, dynamic>);
      await _saveSession(user, accessToken,
          refreshToken: data['refresh_token'] as String?);
      return (user: user, token: accessToken);
    }
    throw ApiException(body['message'] as String? ?? 'Social login failed.', raw.statusCode);
  }

  // ── Biometric — device registration & challenge/verify ────────────────────

  static Future<void> registerBiometricDevice({
    required String deviceId,
    required String publicKey,
    String? deviceName,
    String? platform,
  }) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw = await _rawPost('/auth/biometric/register', {
      'device_id':  deviceId,
      'public_key': publicKey,
      if (deviceName != null) 'device_name': deviceName,
      if (platform   != null) 'platform':    platform,
    }, token: token);
    if (raw.statusCode == 200 || raw.statusCode == 201) return;
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    throw ApiException(body['message'] as String? ?? 'Biometric registration failed.', raw.statusCode);
  }

  static Future<({String challenge, int expiresIn})> getBiometricChallenge(String deviceId) async {
    final raw  = await _rawPost('/auth/biometric/challenge', {'device_id': deviceId});
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) {
      final data = (body['data'] as Map<String, dynamic>?) ?? body;
      return (
        challenge:  data['challenge']  as String? ?? '',
        expiresIn:  data['expires_in'] as int?    ?? 120,
      );
    }
    throw ApiException(body['message'] as String? ?? 'Failed to get challenge.', raw.statusCode);
  }

  static Future<({UserModel user, String token})> verifyBiometric({
    required String deviceId,
    required String signedChallenge,
  }) async {
    final raw  = await _rawPost('/auth/biometric/verify', {
      'device_id':        deviceId,
      'signed_challenge': signedChallenge,
    });
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) {
      final data = (body['data'] as Map<String, dynamic>?) ?? body;
      final userJson    = data['user'];
      final accessToken = data['access_token'] as String? ?? data['token'] as String?;
      if (userJson == null || accessToken == null) {
        throw ApiException('Missing user or token.', raw.statusCode);
      }
      final user = UserModel.fromJson(userJson as Map<String, dynamic>);
      await _saveSession(user, accessToken);
      return (user: user, token: accessToken);
    }
    throw ApiException(body['message'] as String? ?? 'Biometric verification failed.', raw.statusCode);
  }

  static Future<List<Map<String, dynamic>>> getBiometricDevices() async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawGet('/auth/biometric/devices', token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) {
      final list = (body['data'] as List<dynamic>?) ?? [];
      return list.whereType<Map<String, dynamic>>().toList();
    }
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  static Future<void> deleteBiometricDevice(int id) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawDelete('/auth/biometric/devices/$id', token: token);
    if (raw.statusCode == 200 || raw.statusCode == 204) return;
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    throw ApiException(body['message'] as String? ?? 'Delete failed.', raw.statusCode);
  }

  // ── Multi-Account (server-side) ───────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getLinkedAccounts() async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawGet('/accounts', token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) {
      final list = (body['data'] as List<dynamic>?) ?? [];
      return list.whereType<Map<String, dynamic>>().toList();
    }
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  static Future<Map<String, dynamic>> linkAccount({
    required String email,
    required String password,
    String? label,
  }) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawPost('/accounts/link', {
      'email':    email,
      'password': password,
      if (label != null) 'label': label,
    }, token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200 || raw.statusCode == 201) {
      return (body['data'] as Map<String, dynamic>?) ?? body;
    }
    throw ApiException(body['message'] as String? ?? 'Link failed.', raw.statusCode);
  }

  static Future<({UserModel user, String token})> switchLinkedAccount(int linkId) async {
    final currentToken = await getToken();
    if (currentToken == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawPost('/accounts/switch/$linkId', {}, token: currentToken);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) {
      final data = (body['data'] as Map<String, dynamic>?) ?? body;
      final userJson    = data['user'];
      final accessToken = data['access_token'] as String? ?? data['token'] as String?;
      if (userJson == null || accessToken == null) {
        throw ApiException('Missing user or token.', raw.statusCode);
      }
      final user = UserModel.fromJson(userJson as Map<String, dynamic>);
      await _saveSession(user, accessToken);
      return (user: user, token: accessToken);
    }
    throw ApiException(body['message'] as String? ?? 'Switch failed.', raw.statusCode);
  }

  static Future<void> deleteLinkedAccount(int linkId) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawDelete('/accounts/$linkId', token: token);
    if (raw.statusCode == 200 || raw.statusCode == 204) return;
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    throw ApiException(body['message'] as String? ?? 'Delete failed.', raw.statusCode);
  }

  // ── QR Payment ───────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> generateQrPayment({
    required int amountKhr,
    String? paymentType,
    String? payableType,
    int?    payableId,
  }) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw = await _rawPost('/payments/qr/generate', {
      'amount_khr': amountKhr,
      if (paymentType != null) 'payment_type': paymentType,
      if (payableType != null) 'payable_type':  payableType,
      if (payableId   != null) 'payable_id':    payableId,
    }, token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200 || raw.statusCode == 201) {
      return (body['data'] as Map<String, dynamic>?) ?? body;
    }
    throw ApiException(body['message'] as String? ?? 'QR generation failed.', raw.statusCode);
  }

  static Future<Map<String, dynamic>> getQrPaymentStatus(String reference) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawGet('/payments/qr/$reference/status', token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) return (body['data'] as Map<String, dynamic>?) ?? body;
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  static Future<List<Map<String, dynamic>>> getQrPaymentHistory({int page = 1}) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawGet('/payments/qr?page=$page', token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) {
      final data = body['data'];
      if (data is List) return data.whereType<Map<String, dynamic>>().toList();
      if (data is Map) {
        final inner = (data['data'] as List<dynamic>?) ?? [];
        return inner.whereType<Map<String, dynamic>>().toList();
      }
    }
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  // ── Membership / Tiers ────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getMembership() async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawGet('/membership', token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) return (body['data'] as Map<String, dynamic>?) ?? body;
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  static Future<List<Map<String, dynamic>>> getPublicTiers() async {
    final raw  = await _rawGet('/membership/tiers');
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) {
      final list = (body['data'] as List<dynamic>?) ?? [];
      return list.whereType<Map<String, dynamic>>().toList();
    }
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  // ── Voucher Store ─────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getAvailableVouchers() async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawGet('/vouchers', token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) {
      final list = (body['data'] as List<dynamic>?) ?? [];
      return list.whereType<Map<String, dynamic>>().toList();
    }
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  static Future<void> claimVoucher(int id) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawPost('/vouchers/$id/claim', {}, token: token);
    if (raw.statusCode == 200 || raw.statusCode == 201) return;
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    throw ApiException(body['message'] as String? ?? 'Claim failed.', raw.statusCode);
  }

  static Future<List<Map<String, dynamic>>> getMyVouchers() async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawGet('/vouchers/mine', token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) {
      final list = (body['data'] as List<dynamic>?) ?? [];
      return list.whereType<Map<String, dynamic>>().toList();
    }
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  static Future<Map<String, dynamic>> applyVoucher({
    required int userVoucherId,
    required int fare,
    required String category,
  }) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawPost('/vouchers/apply', {
      'user_voucher_id': userVoucherId,
      'fare':            fare,
      'category':        category,
    }, token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) return (body['data'] as Map<String, dynamic>?) ?? body;
    throw ApiException(body['message'] as String? ?? 'Apply failed.', raw.statusCode);
  }

  // ── Onboarding ────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getOnboardingProgress() async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawGet('/onboarding', token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) return (body['data'] as Map<String, dynamic>?) ?? body;
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  static Future<void> completeOnboardingStep(String step) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawPost('/onboarding/step', {'step': step}, token: token);
    if (raw.statusCode == 200) return;
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  static Future<void> skipOnboarding() async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawPost('/onboarding/skip', {}, token: token);
    if (raw.statusCode == 200) return;
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  // ── Accessibility Settings ─────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getAccessibilitySettings() async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawGet('/accessibility', token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) return (body['data'] as Map<String, dynamic>?) ?? body;
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  static Future<Map<String, dynamic>> updateAccessibilitySettings(Map<String, dynamic> data) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawPatch('/accessibility', data, token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) return (body['data'] as Map<String, dynamic>?) ?? body;
    throw ApiException(body['message'] as String? ?? 'Update failed.', raw.statusCode);
  }

  // ── Voice Call (Agora) ─────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getRideCallToken(int rideId) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawPost('/rides/$rideId/call-token', {}, token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) return (body['data'] as Map<String, dynamic>?) ?? body;
    throw ApiException(body['message'] as String? ?? 'Failed to get call token.', raw.statusCode);
  }

  // ── Helmet Detection ──────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> checkHelmet(List<int> imageBytes, String filename) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final uri = Uri.parse('$_baseUrl/driver/helmet-check');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..headers['Accept']        = 'application/json'
      ..files.add(http.MultipartFile.fromBytes(
        'image', imageBytes, filename: filename,
        contentType: MediaType('image', filename.split('.').last),
      ));
    final streamed = await request.send().timeout(const Duration(seconds: 30));
    final raw  = await http.Response.fromStream(streamed);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) return (body['data'] as Map<String, dynamic>?) ?? body;
    throw ApiException(body['message'] as String? ?? 'Helmet check failed.', raw.statusCode);
  }

  // ── Promotional Banners ────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getBanners() async {
    final token = await getToken();
    final raw   = await _rawGet('/banners', token: token);
    final body  = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) {
      final list = (body['data'] as List<dynamic>?) ?? [];
      return list.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }

  // ── Driver Withdrawals ─────────────────────────────────────────────────────

  static Future<void> requestWithdrawal({
    required int    amountKhr,
    required String paymentMethod,
    required String accountNumber,
    required String accountName,
    String? bankName,
  }) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw = await _rawPost('/driver/withdraw', {
      'amount_khr':     amountKhr,
      'payment_method': paymentMethod,
      'account_number': accountNumber,
      'account_name':   accountName,
      if (bankName != null) 'bank_name': bankName,
    }, token: token);
    if (raw.statusCode == 200 || raw.statusCode == 201) return;
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    throw ApiException(body['message'] as String? ?? 'Withdrawal failed.', raw.statusCode);
  }

  static Future<List<Map<String, dynamic>>> getWithdrawalHistory() async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawGet('/driver/withdrawals', token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) {
      final list = (body['data'] as List<dynamic>?) ?? [];
      return list.whereType<Map<String, dynamic>>().toList();
    }
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  // ── Admin — Dashboard stats ───────────────────────────────────────────────

  static Future<Map<String, dynamic>> getAdminStats() async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawGet('/admin/stats', token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) return body['data'] as Map<String, dynamic>? ?? body;
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  // ── Admin — Fare management ───────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getAdminFareRules() async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawGet('/admin/fares', token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) {
      final list = (body['data'] as List<dynamic>?) ?? [];
      return list.whereType<Map<String, dynamic>>().toList();
    }
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  static Future<void> updateAdminFareRule(int id, Map<String, dynamic> data) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawPatch('/admin/fares/$id', data, token: token);
    if (raw.statusCode == 200) return;
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    throw ApiException(body['message'] as String? ?? 'Update failed.', raw.statusCode);
  }

  static Future<Map<String, dynamic>> createAdminFareRule(Map<String, dynamic> data) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawPost('/admin/fares', data, token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200 || raw.statusCode == 201) return body['data'] as Map<String, dynamic>? ?? body;
    throw ApiException(body['message'] as String? ?? 'Create failed.', raw.statusCode);
  }

  static Future<void> deleteAdminFareRule(int id) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawDelete('/admin/fares/$id', token: token);
    if (raw.statusCode == 200 || raw.statusCode == 204) return;
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    throw ApiException(body['message'] as String? ?? 'Delete failed.', raw.statusCode);
  }

  // ── Admin — Surge settings ────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getAdminSurgeSettings() async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawGet('/admin/surge', token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) return body['data'] as Map<String, dynamic>? ?? body;
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  static Future<void> updateAdminSurgeSettings(Map<String, dynamic> data) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawPost('/admin/surge', data, token: token);
    if (raw.statusCode == 200) return;
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    throw ApiException(body['message'] as String? ?? 'Update failed.', raw.statusCode);
  }

  // ── Admin — Promo codes ───────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getAdminPromos() async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawGet('/admin/promos', token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) {
      final list = (body['data'] as List<dynamic>?) ?? [];
      return list.whereType<Map<String, dynamic>>().toList();
    }
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  static Future<Map<String, dynamic>> createAdminPromo(Map<String, dynamic> data) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawPost('/admin/promos', data, token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200 || raw.statusCode == 201) return body['data'] as Map<String, dynamic>? ?? body;
    throw ApiException(body['message'] as String? ?? 'Create failed.', raw.statusCode);
  }

  static Future<void> updateAdminPromo(int id, Map<String, dynamic> data) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawPatch('/admin/promos/$id', data, token: token);
    if (raw.statusCode == 200) return;
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    throw ApiException(body['message'] as String? ?? 'Update failed.', raw.statusCode);
  }

  static Future<void> deleteAdminPromo(int id) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawDelete('/admin/promos/$id', token: token);
    if (raw.statusCode == 200 || raw.statusCode == 204) return;
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    throw ApiException(body['message'] as String? ?? 'Delete failed.', raw.statusCode);
  }

  // ── Admin — Auth ──────────────────────────────────────────────────────────

  static Future<({Map<String, dynamic> admin, String token})> adminLogin(String email, String password) async {
    final raw  = await _rawPost('/admin/login', {'email': email, 'password': password});
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) {
      final token = body['access_token'] as String? ?? body['token'] as String?;
      final admin = body['admin'] as Map<String, dynamic>? ?? {};
      if (token == null) throw const ApiException('No token in admin login response.', 500);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyToken, token);
      await prefs.setString(_keyRole,  'admin');
      await prefs.setString(_keyName,  admin['name'] as String? ?? 'Admin');
      await prefs.setString(_keyEmail, admin['email'] as String? ?? email);
      return (admin: admin, token: token);
    }
    throw ApiException(body['message'] as String? ?? 'Admin login failed.', raw.statusCode);
  }

  static Future<void> adminLogout() async {
    final token = await getToken();
    if (token != null) {
      try { await _rawPost('/admin/logout', {}, token: token); } catch (_) {}
    }
    await clearSession();
  }

  // ── Admin — Users ─────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getAdminUsers({String? role, String? search, int perPage = 20, int page = 1}) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final q = [
      'per_page=$perPage', 'page=$page',
      if (role   != null) 'role=$role',
      if (search != null) 'search=${Uri.encodeComponent(search)}',
    ].join('&');
    final raw  = await _rawGet('/admin/users?$q', token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) {
      final data = body['data'];
      if (data is List) return data.whereType<Map<String, dynamic>>().toList();
      if (data is Map) return ((data['data'] as List?) ?? []).whereType<Map<String, dynamic>>().toList();
    }
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  static Future<Map<String, dynamic>> getAdminUser(int id) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawGet('/admin/users/$id', token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) return (body['data'] as Map<String, dynamic>?) ?? body;
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  static Future<Map<String, dynamic>> updateAdminUser(int id, Map<String, dynamic> data) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawPut('/admin/users/$id', data, token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) return (body['data'] as Map<String, dynamic>?) ?? body;
    throw ApiException(body['message'] as String? ?? 'Update failed.', raw.statusCode);
  }

  static Future<void> deleteAdminUser(int id) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawDelete('/admin/users/$id', token: token);
    if (raw.statusCode == 200 || raw.statusCode == 204) return;
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    throw ApiException(body['message'] as String? ?? 'Delete failed.', raw.statusCode);
  }

  static Future<void> creditAdminUser(int id, int amountKhr, {String? note}) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawPost('/admin/users/$id/credit', {
      'amount_khr': amountKhr,
      if (note != null) 'note': note,
    }, token: token);
    if (raw.statusCode == 200 || raw.statusCode == 201) return;
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    throw ApiException(body['message'] as String? ?? 'Credit failed.', raw.statusCode);
  }

  // ── Admin — Drivers ───────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getAdminDrivers({String? approvalStatus, String? search, int page = 1}) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final q = [
      'page=$page',
      if (approvalStatus != null) 'approval_status=$approvalStatus',
      if (search         != null) 'search=${Uri.encodeComponent(search)}',
    ].join('&');
    final raw  = await _rawGet('/admin/drivers?$q', token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) {
      final data = body['data'];
      if (data is List) return data.whereType<Map<String, dynamic>>().toList();
      if (data is Map) return ((data['data'] as List?) ?? []).whereType<Map<String, dynamic>>().toList();
    }
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  static Future<Map<String, dynamic>> getAdminDriver(int id) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawGet('/admin/drivers/$id', token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) return (body['data'] as Map<String, dynamic>?) ?? body;
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  static Future<void> adminApproveDriverV2(int id, String status, {String? note}) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawPost('/admin/drivers/$id/approve', {
      'status': status,
      if (note != null) 'note': note,
    }, token: token);
    if (raw.statusCode == 200) return;
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  static Future<void> adminReviewDocumentV2(int driverId, int docId, String status, {String? note}) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawPost('/admin/drivers/$driverId/documents/$docId/review', {
      'status': status,
      if (note != null) 'note': note,
    }, token: token);
    if (raw.statusCode == 200) return;
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  // ── Admin — Rides ─────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getAdminRides({String? status, String? date, int perPage = 20, int page = 1}) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final q = [
      'per_page=$perPage', 'page=$page',
      if (status != null) 'status=$status',
      if (date   != null) 'date=$date',
    ].join('&');
    final raw  = await _rawGet('/admin/rides?$q', token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) {
      final data = body['data'];
      if (data is List) return data.whereType<Map<String, dynamic>>().toList();
      if (data is Map) return ((data['data'] as List?) ?? []).whereType<Map<String, dynamic>>().toList();
    }
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  static Future<Map<String, dynamic>> getAdminRide(int id) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawGet('/admin/rides/$id', token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) return (body['data'] as Map<String, dynamic>?) ?? body;
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  static Future<void> cancelAdminRide(int id, String reason) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawPost('/admin/rides/$id/cancel', {'reason': reason}, token: token);
    if (raw.statusCode == 200) return;
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    throw ApiException(body['message'] as String? ?? 'Cancel failed.', raw.statusCode);
  }

  // ── Admin — Deliveries ────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getAdminDeliveries({String? status, String? serviceType, int page = 1}) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final q = [
      'page=$page',
      if (status      != null) 'status=$status',
      if (serviceType != null) 'service_type=$serviceType',
    ].join('&');
    final raw  = await _rawGet('/admin/deliveries?$q', token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) {
      final data = body['data'];
      if (data is List) return data.whereType<Map<String, dynamic>>().toList();
      if (data is Map) return ((data['data'] as List?) ?? []).whereType<Map<String, dynamic>>().toList();
    }
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  static Future<Map<String, dynamic>> getAdminDelivery(int id) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawGet('/admin/deliveries/$id', token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) return (body['data'] as Map<String, dynamic>?) ?? body;
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  // ── Admin — Withdrawals ───────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getAdminWithdrawals({String? status, int page = 1}) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final q = 'page=$page${status != null ? '&status=$status' : ''}';
    final raw  = await _rawGet('/admin/withdrawals?$q', token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) {
      final data = body['data'];
      if (data is List) return data.whereType<Map<String, dynamic>>().toList();
      if (data is Map) return ((data['data'] as List?) ?? []).whereType<Map<String, dynamic>>().toList();
    }
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  static Future<void> approveAdminWithdrawal(int id, {String? note}) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawPost('/admin/withdrawals/$id/approve',
        note != null ? {'note': note} : {}, token: token);
    if (raw.statusCode == 200) return;
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  static Future<void> rejectAdminWithdrawal(int id, String reason) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawPost('/admin/withdrawals/$id/reject', {'reason': reason}, token: token);
    if (raw.statusCode == 200) return;
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  // ── Admin — Top-ups ───────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getAdminTopups({String? status, int page = 1}) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final q = 'page=$page${status != null ? '&status=$status' : ''}';
    final raw  = await _rawGet('/admin/topups?$q', token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) {
      final data = body['data'];
      if (data is List) return data.whereType<Map<String, dynamic>>().toList();
      if (data is Map) return ((data['data'] as List?) ?? []).whereType<Map<String, dynamic>>().toList();
    }
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  static Future<void> approveAdminTopup(int id) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawPost('/admin/topups/$id/approve', {}, token: token);
    if (raw.statusCode == 200) return;
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  static Future<void> rejectAdminTopup(int id, String reason) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawPost('/admin/topups/$id/reject', {'reason': reason}, token: token);
    if (raw.statusCode == 200) return;
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  // ── Admin — Support tickets ───────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getAdminSupportTickets({String? status, String? priority, int page = 1}) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final q = [
      'page=$page',
      if (status   != null) 'status=$status',
      if (priority != null) 'priority=$priority',
    ].join('&');
    final raw  = await _rawGet('/admin/support?$q', token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) {
      final data = body['data'];
      if (data is List) return data.whereType<Map<String, dynamic>>().toList();
      if (data is Map) return ((data['data'] as List?) ?? []).whereType<Map<String, dynamic>>().toList();
    }
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  static Future<Map<String, dynamic>> getAdminSupportTicket(int id) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawGet('/admin/support/$id', token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) return (body['data'] as Map<String, dynamic>?) ?? body;
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  static Future<void> replyAdminSupportTicket(int id, String message) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawPost('/admin/support/$id/reply', {'message': message}, token: token);
    if (raw.statusCode == 200 || raw.statusCode == 201) return;
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  static Future<void> updateAdminSupportTicketStatus(int id, String status) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawPut('/admin/support/$id/status', {'status': status}, token: token);
    if (raw.statusCode == 200) return;
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  // ── Admin — Transactions ──────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getAdminTransactions({String? type, int? userId, String? date, int page = 1}) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final q = [
      'page=$page',
      if (type   != null) 'type=$type',
      if (userId != null) 'user_id=$userId',
      if (date   != null) 'date=$date',
    ].join('&');
    final raw  = await _rawGet('/admin/transactions?$q', token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) {
      final data = body['data'];
      if (data is List) return data.whereType<Map<String, dynamic>>().toList();
      if (data is Map) return ((data['data'] as List?) ?? []).whereType<Map<String, dynamic>>().toList();
    }
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  // ── Admin — Banners ───────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getAdminBanners() async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawGet('/admin/banners', token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) {
      final list = (body['data'] as List?) ?? [];
      return list.whereType<Map<String, dynamic>>().toList();
    }
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  static Future<Map<String, dynamic>> createAdminBanner(Map<String, dynamic> data) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawPost('/admin/banners', data, token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200 || raw.statusCode == 201) return (body['data'] as Map<String, dynamic>?) ?? body;
    throw ApiException(body['message'] as String? ?? 'Create failed.', raw.statusCode);
  }

  static Future<Map<String, dynamic>> updateAdminBanner(int id, Map<String, dynamic> data) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawPut('/admin/banners/$id', data, token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) return (body['data'] as Map<String, dynamic>?) ?? body;
    throw ApiException(body['message'] as String? ?? 'Update failed.', raw.statusCode);
  }

  static Future<void> deleteAdminBanner(int id) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawDelete('/admin/banners/$id', token: token);
    if (raw.statusCode == 200 || raw.statusCode == 204) return;
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    throw ApiException(body['message'] as String? ?? 'Delete failed.', raw.statusCode);
  }

  // ── Admin — Surge zones ───────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getAdminSurgeZones() async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawGet('/admin/surge-zones', token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) {
      final list = (body['data'] as List?) ?? [];
      return list.whereType<Map<String, dynamic>>().toList();
    }
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  static Future<Map<String, dynamic>> createAdminSurgeZone(Map<String, dynamic> data) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawPost('/admin/surge-zones', data, token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200 || raw.statusCode == 201) return (body['data'] as Map<String, dynamic>?) ?? body;
    throw ApiException(body['message'] as String? ?? 'Create failed.', raw.statusCode);
  }

  static Future<Map<String, dynamic>> updateAdminSurgeZone(int id, Map<String, dynamic> data) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawPut('/admin/surge-zones/$id', data, token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) return (body['data'] as Map<String, dynamic>?) ?? body;
    throw ApiException(body['message'] as String? ?? 'Update failed.', raw.statusCode);
  }

  static Future<void> deleteAdminSurgeZone(int id) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawDelete('/admin/surge-zones/$id', token: token);
    if (raw.statusCode == 200 || raw.statusCode == 204) return;
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    throw ApiException(body['message'] as String? ?? 'Delete failed.', raw.statusCode);
  }

  static Future<Map<String, dynamic>> toggleAdminSurgeZone(int id) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawPost('/admin/surge-zones/$id/toggle', {}, token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) return (body['data'] as Map<String, dynamic>?) ?? body;
    throw ApiException(body['message'] as String? ?? 'Toggle failed.', raw.statusCode);
  }

  // ── Admin — Pricing ───────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getAdminPricing() async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawGet('/admin/pricing', token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) return (body['data'] as Map<String, dynamic>?) ?? body;
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  static Future<void> updateAdminPricingSettings(Map<String, dynamic> settings) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawPut('/admin/pricing/settings', {'settings': settings}, token: token);
    if (raw.statusCode == 200) return;
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    throw ApiException(body['message'] as String? ?? 'Update failed.', raw.statusCode);
  }

  // ── Admin — Safety ────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getAdminSafetyIncidents({String? type, int page = 1}) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final q = 'page=$page${type != null ? '&type=$type' : ''}';
    final raw  = await _rawGet('/admin/safety?$q', token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) {
      final data = body['data'];
      if (data is List) return data.whereType<Map<String, dynamic>>().toList();
      if (data is Map) return ((data['data'] as List?) ?? []).whereType<Map<String, dynamic>>().toList();
    }
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  // ── Airport ───────────────────────────────────────────────────────────────

  static Future<List<AirportZone>> getAirportZones() async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawGet('/airport/zones', token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) {
      final data = body['data'];
      final list = data is List ? data : (data as Map?)?['data'] as List? ?? [];
      return list.whereType<Map<String, dynamic>>().map(AirportZone.fromJson).toList();
    }
    throw ApiException(body['message'] as String? ?? 'Failed to load airport zones.', raw.statusCode);
  }

  static Future<AirportEstimate> estimateAirportRide({
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
    int     luggageCount = 0,
    String  serviceType  = 'standard',
  }) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw = await _rawPost('/airport/estimate', {
      'pickup_lat':   pickupLat,
      'pickup_lng':   pickupLng,
      'dropoff_lat':  dropoffLat,
      'dropoff_lng':  dropoffLng,
      'luggage_count': luggageCount,
      'service_type':  serviceType,
    }, token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200 || raw.statusCode == 201) {
      final data = (body['data'] as Map<String, dynamic>?) ?? body;
      return AirportEstimate.fromJson(data);
    }
    throw ApiException(body['message'] as String? ?? 'Failed to estimate airport fare.', raw.statusCode);
  }

  // ── Business ──────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> getBusinessAccount() async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawGet('/business', token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) return (body['data'] as Map<String, dynamic>?);
    if (raw.statusCode == 404) return null;
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  static Future<Map<String, dynamic>> registerBusiness(Map<String, dynamic> data) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawPost('/business/register', data, token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200 || raw.statusCode == 201) {
      return (body['data'] as Map<String, dynamic>?) ?? body;
    }
    throw ApiException(body['message'] as String? ?? 'Failed to register business.', raw.statusCode);
  }

  static Future<void> joinBusiness(String code) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawPost('/business/join', {'code': code}, token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode != 200 && raw.statusCode != 201) {
      throw ApiException(body['message'] as String? ?? 'Failed to join business.', raw.statusCode);
    }
  }

  static Future<void> leaveBusiness() async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawPost('/business/leave', {}, token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode != 200 && raw.statusCode != 201) {
      throw ApiException(body['message'] as String? ?? 'Failed to leave business.', raw.statusCode);
    }
  }

  static Future<Map<String, dynamic>> updateBusinessAccount(Map<String, dynamic> data) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawPut('/business/account', data, token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) return (body['data'] as Map<String, dynamic>?) ?? body;
    throw ApiException(body['message'] as String? ?? 'Failed to update.', raw.statusCode);
  }

  static Future<List<Map<String, dynamic>>> getBusinessMembers() async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawGet('/business/members', token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) {
      final data = body['data'];
      if (data is List) return data.whereType<Map<String, dynamic>>().toList();
      if (data is Map) return ((data['data'] as List?) ?? []).whereType<Map<String, dynamic>>().toList();
    }
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  static Future<void> updateBusinessMember(int id, Map<String, dynamic> data) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawPut('/business/members/$id', data, token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode != 200) {
      throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
    }
  }

  static Future<void> removeBusinessMember(int id) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawDelete('/business/members/$id', token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode != 200 && raw.statusCode != 204) {
      throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
    }
  }

  static Future<List<Map<String, dynamic>>> getBusinessTrips({
    String? from, String? to, String? department, int page = 1,
  }) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final q = [
      'page=$page',
      if (from       != null) 'from=$from',
      if (to         != null) 'to=$to',
      if (department != null) 'department=$department',
    ].join('&');
    final raw  = await _rawGet('/business/trips?$q', token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) {
      final data = body['data'];
      if (data is List) return data.whereType<Map<String, dynamic>>().toList();
      if (data is Map) return ((data['data'] as List?) ?? []).whereType<Map<String, dynamic>>().toList();
    }
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  // ── Family ────────────────────────────────────────────────────────────────

  static Future<FamilyGroup?> getFamilyGroup() async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawGet('/family', token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) {
      final data = body['data'] as Map<String, dynamic>?;
      return data != null ? FamilyGroup.fromJson(data) : null;
    }
    if (raw.statusCode == 404) return null;
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  static Future<FamilyGroup> setupFamilyGroup(String name) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawPost('/family/setup', {'name': name}, token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200 || raw.statusCode == 201) {
      return FamilyGroup.fromJson((body['data'] as Map<String, dynamic>?) ?? body);
    }
    throw ApiException(body['message'] as String? ?? 'Failed to create family group.', raw.statusCode);
  }

  static Future<FamilyMember> addFamilyMember({
    required String name, required String phone, required String relationship,
  }) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawPost('/family/members',
        {'name': name, 'phone': phone, 'relationship': relationship}, token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200 || raw.statusCode == 201) {
      return FamilyMember.fromJson((body['data'] as Map<String, dynamic>?) ?? body);
    }
    throw ApiException(body['message'] as String? ?? 'Failed to add member.', raw.statusCode);
  }

  static Future<void> updateFamilyMember(int id, {
    required String name, required String phone, required String relationship,
  }) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawPut('/family/members/$id',
        {'name': name, 'phone': phone, 'relationship': relationship}, token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode != 200) {
      throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
    }
  }

  static Future<void> removeFamilyMember(int id) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawDelete('/family/members/$id', token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode != 200 && raw.statusCode != 204) {
      throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
    }
  }

  // ── Subscriptions ─────────────────────────────────────────────────────────

  static Future<List<SubscriptionPlan>> getSubscriptionPlans() async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawGet('/subscriptions/plans', token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) {
      final list = (body['data'] as List? ?? []).whereType<Map<String, dynamic>>();
      return list.map(SubscriptionPlan.fromJson).toList();
    }
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  static Future<MySubscription?> getMySubscription() async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawGet('/subscriptions/my', token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) {
      final data = body['data'] as Map<String, dynamic>?;
      return data != null ? MySubscription.fromJson(data) : null;
    }
    if (raw.statusCode == 404) return null;
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  static Future<String> subscribePlan({
    required String planSlug,
    required String paymentMethod,
    bool autoRenew = true,
  }) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw = await _rawPost('/subscriptions/subscribe', {
      'plan_slug':      planSlug,
      'payment_method': paymentMethod,
      'auto_renew':     autoRenew,
    }, token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200 || raw.statusCode == 201) {
      return body['message'] as String? ?? 'Subscribed!';
    }
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  static Future<String> upgradeSubscription({
    required String planSlug,
    required String paymentMethod,
  }) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw = await _rawPost('/subscriptions/upgrade', {
      'plan_slug':      planSlug,
      'payment_method': paymentMethod,
    }, token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200 || raw.statusCode == 201) {
      return body['message'] as String? ?? 'Plan upgraded!';
    }
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  static Future<String> cancelSubscription() async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawPost('/subscriptions/cancel', {}, token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200 || raw.statusCode == 201) {
      return body['message'] as String? ?? 'Subscription cancelled.';
    }
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  static Future<bool> toggleAutoRenew(bool autoRenew) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawPut('/subscriptions/auto-renew',
        {'auto_renew': autoRenew}, token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) {
      return body['auto_renew'] as bool? ?? autoRenew;
    }
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }

  static Future<List<SubscriptionBill>> getSubscriptionHistory({int page = 1}) async {
    final token = await getToken();
    if (token == null) throw const ApiException('Not authenticated.', 401);
    final raw  = await _rawGet('/subscriptions/history?page=$page', token: token);
    final body = jsonDecode(raw.body) as Map<String, dynamic>;
    if (raw.statusCode == 200) {
      final outer = body['data'];
      final list  = outer is Map
          ? (outer['data'] as List? ?? [])
          : (outer as List? ?? []);
      return list.whereType<Map<String, dynamic>>()
          .map(SubscriptionBill.fromJson).toList();
    }
    throw ApiException(body['message'] as String? ?? 'Failed.', raw.statusCode);
  }
}

// ── Wallet transfer result ────────────────────────────────────────────────────

class WalletTransferResult {
  final String message;
  final int    balance;
  final String recipientName;
  final String recipientPhone;
  const WalletTransferResult({
    required this.message,
    required this.balance,
    required this.recipientName,
    required this.recipientPhone,
  });
  factory WalletTransferResult.fromJson(Map<String, dynamic> j) {
    final recipient = j['recipient'] as Map<String, dynamic>? ?? {};
    return WalletTransferResult(
      message:       j['message']       as String? ?? 'Transferred.',
      balance:       j['balance']       as int?    ?? 0,
      recipientName: recipient['name']  as String? ?? '',
      recipientPhone: recipient['phone'] as String? ?? '',
    );
  }
}

// ── Charging station model ────────────────────────────────────────────────────

class ChargingStationModel {
  final int     id;
  final String  name;
  final String  address;
  final double  lat;
  final double  lng;
  final double? distanceKm;
  final int     availablePorts;
  final int?    totalPorts;
  final String  operator;
  final double? rating;
  final String  details;
  final bool    verified;
  final bool    fastCharging;
  final double? pricePerKwh;
  final List<String> connectorTypes;
  final String  hours;

  const ChargingStationModel({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    this.distanceKm,
    this.availablePorts = 0,
    this.totalPorts,
    this.operator = '',
    this.rating,
    this.details = '',
    this.verified = false,
    this.fastCharging = false,
    this.pricePerKwh,
    this.connectorTypes = const [],
    this.hours = '',
  });

  factory ChargingStationModel.fromJson(Map<String, dynamic> j) {
    // The backend sometimes packs connector/pricing/hours info as a
    // JSON-encoded *string* inside 'details' instead of top-level fields
    // (e.g. details: '{"connector_types":["Type 2","CCS"],"price_per_kwh":
    // 0.18,"open_hours":"07:00-21:00"}'). Unwrap it so the UI never shows
    // raw JSON text, and so these fields populate even when the backend
    // doesn't send them at the top level.
    Map<String, dynamic>? nested;
    final rawDetails = j['details'];
    if (rawDetails is String && rawDetails.trim().startsWith('{')) {
      try {
        final decoded = jsonDecode(rawDetails);
        if (decoded is Map<String, dynamic>) nested = decoded;
      } catch (_) {}
    } else if (rawDetails is Map<String, dynamic>) {
      nested = rawDetails;
    }
    final src = nested ?? j;

    return ChargingStationModel(
      id:             j['id']               as int,
      name:           j['name']             as String? ?? '',
      address:        j['address']          as String? ?? '',
      lat:            double.parse((j['latitude']  ?? j['lat']  ?? 0).toString()),
      lng:            double.parse((j['longitude'] ?? j['lng']  ?? 0).toString()),
      distanceKm:     j['distance_km'] != null
          ? double.tryParse(j['distance_km'].toString()) : null,
      availablePorts: j['available_ports']  as int? ?? 0,
      totalPorts:     j['total_ports'] as int?,
      verified:       j['verified'] == true || j['verified'] == 1,
      fastCharging:   j['fast_charging'] == true || j['fast_charging'] == 1 ||
          (src['power_kw'] is List &&
              (src['power_kw'] as List).any((p) => (p as num) >= 50)),
      pricePerKwh:    src['price_per_kwh'] != null
          ? double.tryParse(src['price_per_kwh'].toString()) : null,
      connectorTypes: (src['connector_types'] as List<dynamic>?)
              ?.map((e) => e.toString()).toList() ??
          const [],
      operator:       j['operator']         as String? ?? '',
      rating:         j['rating'] != null
          ? double.tryParse(j['rating'].toString()) : null,
      // Only keep 'details' as free text if it wasn't actually a JSON blob —
      // otherwise there's nothing human-readable left to show.
      details:        nested == null ? (rawDetails as String? ?? '') : '',
      hours:          (j['hours'] ?? src['open_hours']) as String? ?? '',
    );
  }

  ChargingStationModel copyWith({double? distanceKm}) => ChargingStationModel(
    id: id, name: name, address: address, lat: lat, lng: lng,
    distanceKm: distanceKm ?? this.distanceKm,
    availablePorts: availablePorts, totalPorts: totalPorts, operator: operator,
    rating: rating, details: details, verified: verified, fastCharging: fastCharging,
    pricePerKwh: pricePerKwh, connectorTypes: connectorTypes, hours: hours,
  );
}

// ── Safety models ─────────────────────────────────────────────────────────────

class FakeCallResult {
  final String callerName;
  final String callerNumber;
  final int    delaySeconds;
  const FakeCallResult({required this.callerName, required this.callerNumber, required this.delaySeconds});
  factory FakeCallResult.fromJson(Map<String, dynamic> j) {
    final caller = j['caller'] as Map<String, dynamic>? ?? {};
    return FakeCallResult(
      callerName:   caller['name']   as String? ?? 'Unknown',
      callerNumber: caller['number'] as String? ?? '',
      delaySeconds: j['delay_seconds'] as int? ?? 5,
    );
  }
}

class SosResult {
  final String message;
  final String? shareUrl;
  final int contactsNotified;
  const SosResult({required this.message, this.shareUrl, required this.contactsNotified});
  factory SosResult.fromJson(Map<String, dynamic> j) => SosResult(
    message:           j['message']            as String? ?? '',
    shareUrl:          j['share_url']           as String?,
    contactsNotified:  j['contacts_notified']   as int?    ?? 0,
  );
}

class ShareTripResult {
  final String shareToken;
  final String shareUrl;
  const ShareTripResult({required this.shareToken, required this.shareUrl});
  factory ShareTripResult.fromJson(Map<String, dynamic> j) => ShareTripResult(
    shareToken: j['share_token'] as String? ?? '',
    shareUrl:   j['share_url']   as String? ?? '',
  );
}

class EmergencyContactModel {
  final int     id;
  final String  name;
  final String  phone;
  final String? relationship;
  final bool    notifyOnSos;
  final bool    notifyOnTripShare;
  const EmergencyContactModel({
    required this.id, required this.name, required this.phone,
    this.relationship, required this.notifyOnSos, required this.notifyOnTripShare,
  });
  factory EmergencyContactModel.fromJson(Map<String, dynamic> j) => EmergencyContactModel(
    id:                 j['id']                   as int?    ?? 0,
    name:               j['name']                 as String? ?? '',
    phone:              j['phone']                as String? ?? '',
    relationship:       j['relationship']         as String?,
    notifyOnSos:        j['notify_on_sos']        as bool?   ?? true,
    notifyOnTripShare:  j['notify_on_trip_share'] as bool?   ?? true,
  );
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

// ── Saved place model ─────────────────────────────────────────────────────────

class SavedPlaceModel {
  final int    id;
  final String label;
  final String address;
  final double lat;
  final double lng;
  final String? icon;
  final bool   isDefault;

  const SavedPlaceModel({
    required this.id, required this.label, required this.address,
    required this.lat, required this.lng, this.icon, required this.isDefault,
  });

  factory SavedPlaceModel.fromJson(Map<String, dynamic> j) => SavedPlaceModel(
    id:        j['id'] as int,
    label:     j['label'] as String? ?? '',
    address:   j['address'] as String? ?? '',
    lat:       (j['lat'] as num).toDouble(),
    lng:       (j['lng'] as num).toDouble(),
    icon:      j['icon'] as String?,
    isDefault: j['is_default'] == true || j['is_default'] == 1,
  );
}

// ── Ride stop model ───────────────────────────────────────────────────────────

class RideStopModel {
  final int    id;
  final int    rideId;
  final int    order;
  final String address;
  final double lat;
  final double lng;
  final bool   arrived;

  const RideStopModel({
    required this.id, required this.rideId, required this.order,
    required this.address, required this.lat, required this.lng,
    required this.arrived,
  });

  factory RideStopModel.fromJson(Map<String, dynamic> j) => RideStopModel(
    id:      j['id'] as int,
    rideId:  j['ride_id'] as int? ?? 0,
    order:   j['order'] as int? ?? j['stop_order'] as int? ?? 0,
    address: j['address'] as String? ?? '',
    lat:     (j['lat'] as num? ?? 0).toDouble(),
    lng:     (j['lng'] as num? ?? 0).toDouble(),
    arrived: j['arrived'] == true || j['arrived'] == 1,
  );
}

// ── Cancel ride result ────────────────────────────────────────────────────────

class CancelRideResult {
  final String  status;
  final double? cancellationFee;
  final String? message;

  const CancelRideResult({required this.status, this.cancellationFee, this.message});

  factory CancelRideResult.fromJson(Map<String, dynamic> j) => CancelRideResult(
    status:           j['status'] as String? ?? 'cancelled',
    cancellationFee:  j['cancellation_fee'] != null
        ? (j['cancellation_fee'] as num).toDouble() : null,
    message:          j['message'] as String?,
  );
}

// ── Delivery stop model ───────────────────────────────────────────────────────

class DeliveryStopModel {
  final int    id;
  final int    deliveryId;
  final int    order;
  final String address;
  final double lat;
  final double lng;
  final String? recipientName;
  final String? recipientPhone;
  final bool   completed;

  const DeliveryStopModel({
    required this.id, required this.deliveryId, required this.order,
    required this.address, required this.lat, required this.lng,
    this.recipientName, this.recipientPhone, required this.completed,
  });

  factory DeliveryStopModel.fromJson(Map<String, dynamic> j) => DeliveryStopModel(
    id:             j['id'] as int,
    deliveryId:     j['delivery_id'] as int? ?? 0,
    order:          j['order'] as int? ?? j['stop_order'] as int? ?? 0,
    address:        j['address'] as String? ?? '',
    lat:            (j['lat'] as num? ?? 0).toDouble(),
    lng:            (j['lng'] as num? ?? 0).toDouble(),
    recipientName:  j['recipient_name'] as String?,
    recipientPhone: j['recipient_phone'] as String?,
    completed:      j['completed'] == true || j['completed'] == 1,
  );
}

// ── Driver location model ─────────────────────────────────────────────────────

class DriverLocationModel {
  final int    id;
  final String name;
  final String phone;
  final double rating;
  final double lat;
  final double lng;

  const DriverLocationModel({
    required this.id, required this.name, required this.phone,
    required this.rating, required this.lat, required this.lng,
  });

  factory DriverLocationModel.fromJson(Map<String, dynamic> j) => DriverLocationModel(
    id:     j['id']   as int? ?? 0,
    name:   j['name'] as String? ?? '',
    phone:  j['phone'] as String? ?? '',
    rating: (j['rating'] as num? ?? 0).toDouble(),
    lat:    (j['lat']    as num).toDouble(),
    lng:    (j['lng']    as num).toDouble(),
  );
}

// ── Promo validation result ───────────────────────────────────────────────────

class PromoValidationResult {
  final bool   valid;
  final String code;
  final String? type;
  final double? discountAmount;
  final double? discountPercent;
  final double? maxDiscount;
  final String? description;

  const PromoValidationResult({
    required this.valid, required this.code,
    this.type, this.discountAmount, this.discountPercent,
    this.maxDiscount, this.description,
  });

  factory PromoValidationResult.fromJson(Map<String, dynamic> j) => PromoValidationResult(
    valid:           j['valid'] == true || j['valid'] == 1,
    code:            j['code'] as String? ?? '',
    type:            j['type'] as String?,
    discountAmount:  j['discount_amount']  != null ? (j['discount_amount']  as num).toDouble() : null,
    discountPercent: j['discount_percent'] != null ? (j['discount_percent'] as num).toDouble() : null,
    maxDiscount:     j['max_discount']     != null ? (j['max_discount']     as num).toDouble() : null,
    description:     j['description'] as String?,
  );
}

// ── Driver earnings model ─────────────────────────────────────────────────────

class DriverEarningsModel {
  final String period;
  final int    rideEarnings;
  final int    deliveryEarnings;
  final int    totalEarnings;
  final int    tripCount;
  final int    deliveryCount;
  final String currency;
  final int    walletBalance;
  final List<EarningEntryModel> breakdown;

  const DriverEarningsModel({
    required this.period,
    required this.rideEarnings,
    required this.deliveryEarnings,
    required this.totalEarnings,
    required this.tripCount,
    required this.deliveryCount,
    required this.currency,
    required this.walletBalance,
    required this.breakdown,
  });

  factory DriverEarningsModel.fromJson(Map<String, dynamic> j) {
    final list = (j['breakdown'] as List<dynamic>?) ?? [];
    return DriverEarningsModel(
      period:           j['period'] as String? ?? 'daily',
      rideEarnings:     _toInt(j['ride_earnings']),
      deliveryEarnings: _toInt(j['delivery_earnings']),
      totalEarnings:    _toInt(j['total_earnings']),
      tripCount:        _toInt(j['trip_count']),
      deliveryCount:    _toInt(j['delivery_count']),
      currency:         j['currency'] as String? ?? 'KHR',
      walletBalance:    _toInt(j['wallet_balance']),
      breakdown:        list.whereType<Map<String, dynamic>>()
          .map(EarningEntryModel.fromJson).toList(),
    );
  }

  static int _toInt(dynamic v) =>
      v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;
}

class EarningEntryModel {
  final String date;
  final int    total;
  final int    trips;

  const EarningEntryModel({required this.date, required this.total, required this.trips});

  factory EarningEntryModel.fromJson(Map<String, dynamic> j) => EarningEntryModel(
    date:  j['date'] as String? ?? '',
    total: _toInt(j['total'] ?? j['amount']),
    trips: _toInt(j['trips']),
  );

  static int _toInt(dynamic v) =>
      v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;
}

// ── Driver earnings summary model (dashboard card) ────────────────────────────

class DriverEarningsSummaryModel {
  final int    todayKhr;
  final int    weekKhr;
  final int    totalTrips;
  final String currency;
  final int    walletBalance;
  final double walletBalanceUsd;
  final bool   canWithdraw;
  final int    minWithdrawalKhr;
  final Map<String, dynamic>? pendingWithdrawal;

  const DriverEarningsSummaryModel({
    required this.todayKhr,
    required this.weekKhr,
    required this.totalTrips,
    required this.currency,
    required this.walletBalance,
    required this.walletBalanceUsd,
    required this.canWithdraw,
    required this.minWithdrawalKhr,
    this.pendingWithdrawal,
  });

  bool get hasPendingWithdrawal => pendingWithdrawal != null;

  factory DriverEarningsSummaryModel.fromJson(Map<String, dynamic> j) => DriverEarningsSummaryModel(
    todayKhr:          _toInt(j['today_khr']),
    weekKhr:           _toInt(j['week_khr']),
    totalTrips:        _toInt(j['total_trips']),
    currency:          j['currency'] as String? ?? 'KHR',
    walletBalance:     _toInt(j['wallet_balance']),
    walletBalanceUsd:  (j['wallet_balance_usd'] as num? ?? 0).toDouble(),
    canWithdraw:       j['can_withdraw'] as bool? ?? true,
    minWithdrawalKhr:  _toInt(j['min_withdrawal_khr']),
    pendingWithdrawal: j['pending_withdrawal'] as Map<String, dynamic>?,
  );

  static int _toInt(dynamic v) =>
      v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;
}

// ── Driver earnings history model (chart data) ────────────────────────────────

class DriverEarningsHistoryItem {
  final String date;
  final int    trips;
  final int    amountKhr;

  const DriverEarningsHistoryItem({required this.date, required this.trips, required this.amountKhr});

  factory DriverEarningsHistoryItem.fromJson(Map<String, dynamic> j) => DriverEarningsHistoryItem(
    date:      j['date'] as String? ?? '',
    trips:     _toInt(j['trips']),
    amountKhr: _toInt(j['amount_khr']),
  );

  static int _toInt(dynamic v) =>
      v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;
}

// ── Driver ride history ───────────────────────────────────────────────────────

class DriverRideHistoryResult {
  final DriverRideSummary summary;
  final List<RideModel>   rides;
  final int currentPage;
  final int lastPage;
  const DriverRideHistoryResult({
    required this.summary,
    required this.rides,
    required this.currentPage,
    required this.lastPage,
  });
}

class DriverRideSummary {
  final int    totalCompleted;
  final int    totalEarnedKhr;
  final double totalKm;
  final int    totalMinutes;
  final int    avgFareKhr;

  const DriverRideSummary({
    required this.totalCompleted,
    required this.totalEarnedKhr,
    required this.totalKm,
    required this.totalMinutes,
    required this.avgFareKhr,
  });

  factory DriverRideSummary.fromJson(Map<String, dynamic> j) => DriverRideSummary(
    totalCompleted: (j['total_completed'] as num?)?.toInt() ?? 0,
    totalEarnedKhr: (j['total_earned']    as num?)?.toInt() ?? 0,
    totalKm:        (j['total_km']        as num?)?.toDouble() ?? 0,
    totalMinutes:   (j['total_minutes']   as num?)?.toInt() ?? 0,
    avgFareKhr:     (j['avg_fare']        as num?)?.toInt() ?? 0,
  );
}

// ── Driver incentive model ────────────────────────────────────────────────────

class DriverIncentiveModel {
  final int    id;
  final String title;
  final String description;
  final String type;
  final double target;
  final double current;
  final double reward;
  final String status;
  final DateTime? expiresAt;

  const DriverIncentiveModel({
    required this.id, required this.title, required this.description,
    required this.type, required this.target, required this.current,
    required this.reward, required this.status, this.expiresAt,
  });

  double get progress => target > 0 ? (current / target).clamp(0.0, 1.0) : 0;

  factory DriverIncentiveModel.fromJson(Map<String, dynamic> j) => DriverIncentiveModel(
    id:          j['id'] as int,
    title:       j['title'] as String? ?? '',
    description: j['description'] as String? ?? '',
    type:        j['type'] as String? ?? 'trips',
    target:      (j['target'] as num? ?? 0).toDouble(),
    current:     (j['current'] as num? ?? 0).toDouble(),
    reward:      (j['reward'] as num? ?? 0).toDouble(),
    status:      j['status'] as String? ?? 'active',
    expiresAt:   j['expires_at'] != null
        ? DateTime.tryParse(j['expires_at'] as String) : null,
  );
}

// ── Surge info model ──────────────────────────────────────────────────────────

class SurgeZone {
  final int     id;
  final String  name;
  final String? description;
  final double  centerLat;
  final double  centerLng;
  final double  radiusKm;
  final double  multiplier;
  final String  type;
  final DateTime? endsAt;
  final double? distanceKm;
  final bool    youAreInside;

  const SurgeZone({
    required this.id,
    required this.name,
    this.description,
    required this.centerLat,
    required this.centerLng,
    required this.radiusKm,
    required this.multiplier,
    required this.type,
    this.endsAt,
    this.distanceKm,
    required this.youAreInside,
  });

  factory SurgeZone.fromJson(Map<String, dynamic> j) => SurgeZone(
    id:          j['id'] as int,
    name:        j['name'] as String? ?? '',
    description: j['description'] as String?,
    centerLat:   (j['center_lat'] as num).toDouble(),
    centerLng:   (j['center_lng'] as num).toDouble(),
    radiusKm:    (j['radius_km']  as num? ?? 1.0).toDouble(),
    multiplier:  (j['multiplier'] as num? ?? 1.0).toDouble(),
    type:        j['type'] as String? ?? 'rides',
    endsAt:      j['ends_at'] != null ? DateTime.tryParse(j['ends_at'] as String) : null,
    distanceKm:  j['distance_km'] != null ? (j['distance_km'] as num).toDouble() : null,
    youAreInside: j['you_are_inside'] as bool? ?? false,
  );
}

class SurgeInfo {
  final bool      surgeActive;    // true = driver IS inside a surge zone
  final double    multiplier;
  final String?   zone;
  final String?   message;
  final DateTime? endsAt;
  final bool      youAreInside;   // false = nearby zone only
  final double?   nearbyDistanceKm;

  const SurgeInfo({
    required this.surgeActive,
    required this.multiplier,
    this.zone,
    this.message,
    this.endsAt,
    this.youAreInside    = false,
    this.nearbyDistanceKm,
  });

  // A banner should show when inside a zone OR when there's a nearby zone worth showing
  bool get shouldShowBanner => surgeActive || (zone != null && multiplier > 1.0);
}

// ── Public trip model ─────────────────────────────────────────────────────────

class PublicTripModel {
  final int     rideId;
  final String  status;
  final bool    isLive;
  final String  pickupAddress;
  final String  dropoffAddress;
  final double  pickupLat;
  final double  pickupLng;
  final double  dropoffLat;
  final double  dropoffLng;
  final double? driverLat;
  final double? driverLng;
  final bool    locationUpdated;   // false = driver GPS not yet received
  final String  driverName;
  final String  vehicleType;
  final String  plate;
  final int?    etaMinutes;

  const PublicTripModel({
    required this.rideId,
    required this.status,
    required this.isLive,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropoffLat,
    required this.dropoffLng,
    this.driverLat,
    this.driverLng,
    required this.locationUpdated,
    required this.driverName,
    required this.vehicleType,
    required this.plate,
    this.etaMinutes,
  });

  factory PublicTripModel.fromJson(Map<String, dynamic> j) {
    final driver  = j['driver']  as Map<String, dynamic>? ?? {};
    final vehicle = driver['vehicle'] as Map<String, dynamic>? ?? {};

    // Backend guarantees lat/lng are null when location_updated == false
    final locationUpdated = driver['location_updated'] as bool? ?? false;
    final driverLat = locationUpdated && driver['lat'] != null
        ? (driver['lat'] as num).toDouble() : null;
    final driverLng = locationUpdated && driver['lng'] != null
        ? (driver['lng'] as num).toDouble() : null;

    return PublicTripModel(
      rideId:          j['ride_id']        as int?    ?? j['id'] as int? ?? 0,
      status:          j['status']         as String? ?? '',
      isLive:          j['is_live']        as bool?   ?? false,
      pickupAddress:   j['pickup_address'] as String? ?? '',
      dropoffAddress:  j['dropoff_address'] as String? ?? '',
      pickupLat:       (j['pickup_lat']  as num? ?? 0).toDouble(),
      pickupLng:       (j['pickup_lng']  as num? ?? 0).toDouble(),
      dropoffLat:      (j['dropoff_lat'] as num? ?? 0).toDouble(),
      dropoffLng:      (j['dropoff_lng'] as num? ?? 0).toDouble(),
      driverLat:       driverLat,
      driverLng:       driverLng,
      locationUpdated: locationUpdated,
      driverName:      driver['name']  as String? ?? '',
      vehicleType:     driver['vehicle_type'] as String?
                       ?? vehicle['type']     as String? ?? '',
      plate:           vehicle['plate']        as String?
                       ?? vehicle['license_plate'] as String? ?? '',
      etaMinutes:      j['eta_minutes'] as int?,
    );
  }
}

// ── Support ticket model ──────────────────────────────────────────────────────

class SupportTicketModel {
  final int    id;
  final String subject;
  final String status;
  final String priority;
  final DateTime? createdAt;
  final List<SupportReplyModel> replies;

  const SupportTicketModel({
    required this.id,
    required this.subject,
    required this.status,
    required this.priority,
    this.createdAt,
    required this.replies,
  });

  bool get isOpen   => status == 'open'   || status == 'pending';
  bool get isClosed => status == 'closed' || status == 'resolved';

  factory SupportTicketModel.fromJson(Map<String, dynamic> j) {
    final rawReplies = (j['replies'] as List<dynamic>?) ?? [];
    return SupportTicketModel(
      id:        j['id']       as int,
      subject:   j['subject']  as String? ?? '',
      status:    j['status']   as String? ?? 'open',
      priority:  j['priority'] as String? ?? 'normal',
      createdAt: j['created_at'] != null
          ? DateTime.tryParse(j['created_at'] as String) : null,
      replies:   rawReplies.whereType<Map<String, dynamic>>()
          .map(SupportReplyModel.fromJson).toList(),
    );
  }
}

class SupportReplyModel {
  final int    id;
  final String message;
  final bool   isStaff;
  final DateTime? createdAt;

  const SupportReplyModel({
    required this.id,
    required this.message,
    required this.isStaff,
    this.createdAt,
  });

  factory SupportReplyModel.fromJson(Map<String, dynamic> j) => SupportReplyModel(
    id:        j['id']      as int? ?? 0,
    message:   j['message'] as String? ?? '',
    isStaff:   j['is_staff'] == true || j['is_staff'] == 1,
    createdAt: j['created_at'] != null
        ? DateTime.tryParse(j['created_at'] as String) : null,
  );
}

// ── Heatmap point model ───────────────────────────────────────────────────────

class HeatMapPoint {
  final double lat;
  final double lng;
  final double weight;

  const HeatMapPoint({required this.lat, required this.lng, required this.weight});

  factory HeatMapPoint.fromJson(Map<String, dynamic> j) => HeatMapPoint(
    lat:    (j['lat'] as num).toDouble(),
    lng:    (j['lng'] as num).toDouble(),
    weight: (j['weight'] as num? ?? 1).toDouble(),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

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

// ── Driver document model ─────────────────────────────────────────────────────

class DriverDocument {
  final int    id;
  final String type;
  final String status; // pending / approved / rejected
  final String? fileUrl;
  final String? note;

  const DriverDocument({
    required this.id,
    required this.type,
    required this.status,
    this.fileUrl,
    this.note,
  });

  factory DriverDocument.fromJson(Map<String, dynamic> j) => DriverDocument(
    id:      (j['id'] as num).toInt(),
    type:    j['type']   as String? ?? '',
    status:  j['status'] as String? ?? 'pending',
    fileUrl: j['file_url'] as String?,
    note:    j['note']    as String?,
  );

  bool get isPending  => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
}

// ── Driver approval status model ──────────────────────────────────────────────

class DriverApprovalStatus {
  final String approvalStatus; // pending / approved / rejected
  final String? serviceZone;
  final String? city;
  final List<DriverDocument> documents;

  const DriverApprovalStatus({
    required this.approvalStatus,
    this.serviceZone,
    this.city,
    this.documents = const [],
  });

  factory DriverApprovalStatus.fromJson(Map<String, dynamic> j) {
    final docs = (j['documents'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(DriverDocument.fromJson)
        .toList();
    return DriverApprovalStatus(
      approvalStatus: j['approval_status'] as String? ?? j['status'] as String? ?? 'pending',
      serviceZone:    j['service_zone'] as String?,
      city:           j['city']         as String?,
      documents:      docs,
    );
  }

  bool get isPending  => approvalStatus == 'pending';
  bool get isApproved => approvalStatus == 'approved';
  bool get isRejected => approvalStatus == 'rejected';
}

// ── Airport models ────────────────────────────────────────────────────────────

class AirportZone {
  final int    id;
  final String name;
  final String iataCode;
  final double lat;
  final double lng;

  const AirportZone({
    required this.id, required this.name,
    required this.iataCode, required this.lat, required this.lng,
  });

  factory AirportZone.fromJson(Map<String, dynamic> j) => AirportZone(
    id:       j['id'] as int,
    name:     j['name'] as String? ?? '',
    iataCode: j['iata_code'] as String? ?? '',
    lat:      (j['lat'] as num? ?? j['latitude']  as num? ?? 0).toDouble(),
    lng:      (j['lng'] as num? ?? j['longitude'] as num? ?? 0).toDouble(),
  );
}

class AirportEstimate {
  final AirportZone? zone;
  final double  distanceKm;
  final int     baseFareKhr;
  final int     surchargKhr;
  final int     luggageFeeKhr;
  final int     luggageCount;
  final int     totalKhr;

  const AirportEstimate({
    this.zone,
    required this.distanceKm,
    required this.baseFareKhr,
    required this.surchargKhr,
    required this.luggageFeeKhr,
    required this.luggageCount,
    required this.totalKhr,
  });

  factory AirportEstimate.fromJson(Map<String, dynamic> j) => AirportEstimate(
    zone:         j['airport_zone'] != null
                  ? AirportZone.fromJson(j['airport_zone'] as Map<String, dynamic>)
                  : null,
    distanceKm:   (j['distance_km']    as num? ?? 0).toDouble(),
    baseFareKhr:  (j['base_fare_khr']  as num? ?? 0).toInt(),
    surchargKhr:  (j['surcharge_khr']  as num? ?? 0).toInt(),
    luggageFeeKhr:(j['luggage_fee_khr'] as num? ?? 0).toInt(),
    luggageCount: (j['luggage_count']  as num? ?? 0).toInt(),
    totalKhr:     (j['total_khr']      as num? ?? 0).toInt(),
  );
}

// ── Family models ─────────────────────────────────────────────────────────────

class FamilyMember {
  final int     id;
  final String  name;
  final String  phone;
  final String  relationship;
  final String? avatarUrl;
  final bool    hasAccount;

  const FamilyMember({
    required this.id, required this.name, required this.phone,
    required this.relationship, this.avatarUrl, this.hasAccount = false,
  });

  factory FamilyMember.fromJson(Map<String, dynamic> j) => FamilyMember(
    id:           j['id'] as int? ?? 0,
    name:         j['name'] as String? ?? '',
    phone:        j['phone'] as String? ?? '',
    relationship: j['relationship'] as String? ?? '',
    avatarUrl:    j['avatar_url'] as String?,
    hasAccount:   j['has_account'] as bool? ?? false,
  );
}

class FamilyGroup {
  final int              id;
  final String           name;
  final List<FamilyMember> members;

  const FamilyGroup({required this.id, required this.name, required this.members});

  factory FamilyGroup.fromJson(Map<String, dynamic> j) => FamilyGroup(
    id:      j['id'] as int? ?? 0,
    name:    j['name'] as String? ?? '',
    members: (j['members'] as List<dynamic>? ?? [])
             .whereType<Map<String, dynamic>>()
             .map(FamilyMember.fromJson)
             .toList(),
  );
}

// ── Subscription models ───────────────────────────────────────────────────────

class SubscriptionPlan {
  final int    id;
  final String name;
  final String slug;
  final String? description;
  final int    priceKhr;
  final String billingCycle;
  final int    rideCreditKhr;
  final int    rideDiscountPct;
  final int    deliveryDiscountPct;
  final String freeCancellations; // may be "Unlimited"
  final bool   surgeWaived;
  final bool   priorityMatching;
  final int    bonusPointsPct;
  final List<String> features;
  final String badgeColor;        // hex e.g. "#f59e0b"
  final String icon;              // font-awesome class — mapped to IconData in UI

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    required this.priceKhr,
    required this.billingCycle,
    required this.rideCreditKhr,
    required this.rideDiscountPct,
    required this.deliveryDiscountPct,
    required this.freeCancellations,
    required this.surgeWaived,
    required this.priorityMatching,
    required this.bonusPointsPct,
    required this.features,
    required this.badgeColor,
    required this.icon,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> j) => SubscriptionPlan(
    id:                   j['id'] as int? ?? 0,
    name:                 j['name'] as String? ?? '',
    slug:                 j['slug'] as String? ?? '',
    description:          j['description'] as String?,
    priceKhr:             (j['price_khr'] as num? ?? 0).toInt(),
    billingCycle:         j['billing_cycle'] as String? ?? 'monthly',
    rideCreditKhr:        (j['ride_credit_khr'] as num? ?? 0).toInt(),
    rideDiscountPct:      (j['ride_discount_pct'] as num? ?? 0).toInt(),
    deliveryDiscountPct:  (j['delivery_discount_pct'] as num? ?? 0).toInt(),
    freeCancellations:    j['free_cancellations']?.toString() ?? '0',
    surgeWaived:          j['surge_waived'] as bool? ?? false,
    priorityMatching:     j['priority_matching'] as bool? ?? false,
    bonusPointsPct:       (j['bonus_points_pct'] as num? ?? 0).toInt(),
    features:             (j['features'] as List<dynamic>? ?? []).cast<String>(),
    badgeColor:           j['badge_color'] as String? ?? '#64748b',
    icon:                 j['icon'] as String? ?? '',
  );
}

class MySubscription {
  final int    id;
  final String planName;
  final String planSlug;
  final int    planPriceKhr;
  final String status;
  final bool   isActive;
  final String paymentMethod;
  final bool   autoRenew;
  final DateTime? startedAt;
  final DateTime? expiresAt;
  final int    expiresInDays;
  final int    usedRideCreditKhr;
  final int    remainingCreditKhr;
  final int    usedCancellations;
  final String remainingCancellations;
  final int    renewalCount;

  const MySubscription({
    required this.id,
    required this.planName,
    required this.planSlug,
    required this.planPriceKhr,
    required this.status,
    required this.isActive,
    required this.paymentMethod,
    required this.autoRenew,
    this.startedAt,
    this.expiresAt,
    required this.expiresInDays,
    required this.usedRideCreditKhr,
    required this.remainingCreditKhr,
    required this.usedCancellations,
    required this.remainingCancellations,
    required this.renewalCount,
  });

  factory MySubscription.fromJson(Map<String, dynamic> j) {
    final plan = j['plan'] as Map<String, dynamic>? ?? {};
    return MySubscription(
      id:                    j['id'] as int? ?? 0,
      planName:              plan['name'] as String? ?? '',
      planSlug:              plan['slug'] as String? ?? '',
      planPriceKhr:          (plan['price_khr'] as num? ?? 0).toInt(),
      status:                j['status'] as String? ?? 'inactive',
      isActive:              j['is_active'] as bool? ?? false,
      paymentMethod:         j['payment_method'] as String? ?? 'wallet',
      autoRenew:             j['auto_renew'] as bool? ?? false,
      startedAt:             j['started_at'] != null ? DateTime.tryParse(j['started_at'] as String) : null,
      expiresAt:             j['expires_at'] != null ? DateTime.tryParse(j['expires_at'] as String) : null,
      expiresInDays:         (j['expires_in_days'] as num? ?? 0).toInt(),
      usedRideCreditKhr:     (j['used_ride_credit_khr'] as num? ?? 0).toInt(),
      remainingCreditKhr:    (j['remaining_credit_khr'] as num? ?? 0).toInt(),
      usedCancellations:     (j['used_cancellations'] as num? ?? 0).toInt(),
      remainingCancellations: j['remaining_cancellations']?.toString() ?? '0',
      renewalCount:          (j['renewal_count'] as num? ?? 0).toInt(),
    );
  }
}

class SubscriptionBill {
  final int    id;
  final int    amountKhr;
  final String type;
  final String status;
  final String paymentMethod;
  final String reference;
  final DateTime? paidAt;
  final String planName;
  final String planSlug;
  final String badgeColor;

  const SubscriptionBill({
    required this.id,
    required this.amountKhr,
    required this.type,
    required this.status,
    required this.paymentMethod,
    required this.reference,
    this.paidAt,
    required this.planName,
    required this.planSlug,
    required this.badgeColor,
  });

  factory SubscriptionBill.fromJson(Map<String, dynamic> j) {
    final plan = j['plan'] as Map<String, dynamic>? ?? {};
    return SubscriptionBill(
      id:            j['id'] as int? ?? 0,
      amountKhr:     (j['amount_khr'] as num? ?? 0).toInt(),
      type:          j['type'] as String? ?? '',
      status:        j['status'] as String? ?? '',
      paymentMethod: j['payment_method'] as String? ?? '',
      reference:     j['reference'] as String? ?? '',
      paidAt:        j['paid_at'] != null ? DateTime.tryParse(j['paid_at'] as String) : null,
      planName:      plan['name'] as String? ?? '',
      planSlug:      plan['slug'] as String? ?? '',
      badgeColor:    plan['badge_color'] as String? ?? '#64748b',
    );
  }
}
