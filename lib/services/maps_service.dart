import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../utils/app_log.dart';

class PlaceResult {
  final String address;
  final LatLng latLng;
  const PlaceResult({required this.address, required this.latLng});
}

class DirectionsResult {
  final List<LatLng> points;
  final int    etaMinutes;
  final double distanceKm;
  const DirectionsResult({
    required this.points,
    required this.etaMinutes,
    required this.distanceKm,
  });
}

class MapsService {
  static const _apiKey = 'AIzaSyBzMVRTpOLoEI5y1S6zDq5icp1llS0fYkc';

  // ── Routes API (v2) — traffic-aware, replaces legacy Directions API ──────────

  static Future<DirectionsResult?> getRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final url = Uri.parse(
        'https://routes.googleapis.com/directions/v2:computeRoutes');

    final body = {
      'origin': {
        'location': {
          'latLng': {
            'latitude':  origin.latitude,
            'longitude': origin.longitude,
          }
        }
      },
      'destination': {
        'location': {
          'latLng': {
            'latitude':  destination.latitude,
            'longitude': destination.longitude,
          }
        }
      },
      'travelMode':            'DRIVE',
      'routingPreference':     'TRAFFIC_AWARE',
      'computeAlternativeRoutes': false,
      'languageCode':          'km',
      'units':                 'METRIC',
    };

    try {
      final res = await http.post(
        url,
        headers: {
          'Content-Type':      'application/json',
          'X-Goog-Api-Key':    _apiKey,
          // Only request the fields we use — avoids being billed for extras
          'X-Goog-FieldMask':
              'routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) {
        AppLog.w('Maps', 'Routes API HTTP ${res.statusCode}: ${res.body}');
        return null;
      }

      final data   = jsonDecode(res.body) as Map<String, dynamic>;
      final routes = data['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) {
        AppLog.w('Maps', 'Routes API: no routes in response');
        return null;
      }

      final route       = routes.first as Map<String, dynamic>;
      final distMeters  = (route['distanceMeters'] as num?)?.toDouble() ?? 0.0;
      // duration arrives as "732s"
      final durStr      = route['duration'] as String? ?? '0s';
      final durSec      = int.tryParse(durStr.replaceAll('s', '')) ?? 0;
      final encoded     = (route['polyline'] as Map<String, dynamic>?)?
                              ['encodedPolyline'] as String? ?? '';

      if (encoded.isEmpty) {
        AppLog.w('Maps', 'Routes API: empty polyline');
        return null;
      }

      return DirectionsResult(
        points:     _decodePolyline(encoded),
        etaMinutes: (durSec / 60).ceil(),
        distanceKm: distMeters / 1000,
      );
    } catch (e, s) {
      AppLog.e('Maps', 'getRoute failed', e, s);
      return null;
    }
  }

  // ── Geocoding API — reverse geocode & address search ─────────────────────────

  static Future<String?> reverseGeocode(LatLng pos) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json'
      '?latlng=${pos.latitude},${pos.longitude}'
      '&key=$_apiKey',
    );
    try {
      final res = await http.get(url).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) {
        AppLog.w('Maps', 'reverseGeocode HTTP ${res.statusCode}');
        return null;
      }
      final body    = jsonDecode(res.body) as Map<String, dynamic>;
      final results = body['results'] as List<dynamic>?;
      if (results == null || results.isEmpty) {
        AppLog.w('Maps', 'reverseGeocode: no results (status=${body['status']})');
        return null;
      }
      return (results.first as Map<String, dynamic>)['formatted_address']
          as String?;
    } catch (e, s) {
      AppLog.e('Maps', 'reverseGeocode failed', e, s);
      return null;
    }
  }

  static Future<List<PlaceResult>> searchAddress(String query) async {
    if (query.trim().isEmpty) return [];
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json'
      '?address=${Uri.encodeComponent(query)}'
      '&region=kh'
      '&key=$_apiKey',
    );
    try {
      final res = await http.get(url).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) {
        AppLog.w('Maps', 'searchAddress HTTP ${res.statusCode}');
        return [];
      }
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final list = (body['results'] as List<dynamic>? ?? []).take(5);
      return list.map((r) {
        final map = r as Map<String, dynamic>;
        final loc = (map['geometry'] as Map<String, dynamic>)['location']
            as Map<String, dynamic>;
        return PlaceResult(
          address: map['formatted_address'] as String,
          latLng:  LatLng(
            (loc['lat'] as num).toDouble(),
            (loc['lng'] as num).toDouble(),
          ),
        );
      }).toList();
    } catch (e, s) {
      AppLog.e('Maps', 'searchAddress failed', e, s);
      return [];
    }
  }

  // ── Polyline decoder (same encoding as Directions API) ───────────────────────

  static List<LatLng> _decodePolyline(String encoded) {
    final result = <LatLng>[];
    int index = 0, lat = 0, lng = 0;

    while (index < encoded.length) {
      int shift = 0, acc = 0, b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        acc |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += ((acc & 1) != 0) ? ~(acc >> 1) : (acc >> 1);

      shift = 0; acc = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        acc |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += ((acc & 1) != 0) ? ~(acc >> 1) : (acc >> 1);

      result.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return result;
  }
}
