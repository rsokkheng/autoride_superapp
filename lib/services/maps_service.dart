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

  static bool _isInCambodia(LatLng p) =>
      p.latitude  >= 9.0   && p.latitude  <= 15.5 &&
      p.longitude >= 102.0 && p.longitude <= 108.0;

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
    final url = Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
      'latlng':   '${pos.latitude},${pos.longitude}',
      'language': 'km',
      'key':      _apiKey,
    });
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

  // Returns a short area name like "ដូនពេញ, ភ្នំពេញ" in Khmer.
  // No result_type filter — Cambodia uses non-standard admin levels and the
  // filter (with URL-encoded | ) can return zero results for Sangkat/Khan.
  // Returns null when pos is outside Cambodia.
  static Future<String?> getAreaName(LatLng pos) async {
    if (!_isInCambodia(pos)) return null;
    final url = Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
      'latlng':   '${pos.latitude},${pos.longitude}',
      'language': 'km',
      'key':      _apiKey,
    });
    try {
      final res = await http.get(url).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final body    = jsonDecode(res.body) as Map<String, dynamic>;
      final results = body['results'] as List<dynamic>?;
      if (results == null || results.isEmpty) return null;

      // Walk all results' components and pick the most specific area name.
      // Priority for Cambodia: neighborhood > sublocality_level_2 > sublocality_level_1
      //   > sublocality > administrative_area_level_2 (Khan) > administrative_area_level_1
      // Then pair with locality (city).
      String? area;
      String? city;

      for (final result in results) {
        final components =
            (result as Map<String, dynamic>)['address_components'] as List<dynamic>?;
        if (components == null) continue;
        for (final comp in components) {
          final c     = comp as Map<String, dynamic>;
          final types = (c['types'] as List<dynamic>).cast<String>();
          final name  = c['long_name'] as String? ?? '';
          if (name.isEmpty) continue;

          if (area == null && (
              types.contains('neighborhood')           ||
              types.contains('sublocality_level_2')    ||
              types.contains('sublocality_level_1')    ||
              types.contains('sublocality')            ||
              types.contains('administrative_area_level_2') ||
              types.contains('administrative_area_level_3'))) {
            area = name;
          }
          if (city == null && (
              types.contains('locality') ||
              types.contains('administrative_area_level_1'))) {
            city = name;
          }
        }
        if (area != null && city != null) break;
      }

      // Last-resort: parse the first result's formatted_address.
      // e.g. "Wat Phnom, Phsar Kandal I, Phnom Penh, Cambodia"
      //   → take index 1 (Phsar Kandal I) and index 2 (Phnom Penh)
      if (area == null || city == null) {
        final formatted = (results.first as Map<String, dynamic>)['formatted_address'] as String?;
        if (formatted != null) {
          final parts = formatted.split(',').map((s) => s.trim()).toList();
          if (parts.length >= 3) {
            area ??= parts[1];
            city ??= parts[2];
          } else if (parts.length == 2) {
            area ??= parts[0];
            city ??= parts[1];
          }
        }
      }

      if (area == null && city == null) return null;
      if (area != null && city != null && area != city) return '$area, $city';
      return area ?? city;
    } catch (e, s) {
      AppLog.e('Maps', 'getAreaName failed', e, s);
      return null;
    }
  }

  static Future<List<PlaceResult>> searchAddress(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final autocompleteUrl = Uri.https(
        'maps.googleapis.com',
        '/maps/api/place/autocomplete/json',
        {
          'input': query,
          'key': _apiKey,
          'components': 'country:kh',
          'language': 'en',
        },
      );

      final autoRes = await http.get(autocompleteUrl).timeout(const Duration(seconds: 8));
      if (autoRes.statusCode != 200) {
        AppLog.w('Maps', 'searchAddress autocomplete HTTP ${autoRes.statusCode}');
        return [];
      }

      final autoBody = jsonDecode(autoRes.body) as Map<String, dynamic>;
      final status = autoBody['status'] as String? ?? '';
      if (status != 'OK' && status != 'ZERO_RESULTS') {
        AppLog.w('Maps', 'searchAddress autocomplete status: $status');
        return [];
      }

      final predictions = autoBody['predictions'] as List<dynamic>? ?? [];
      final results = await Future.wait(predictions.take(5).map((prediction) async {
        final pred = prediction as Map<String, dynamic>;
        final placeId = pred['place_id'] as String?;
        final description = pred['description'] as String? ?? '';

        if (placeId == null || placeId.isEmpty) return null;
        try {
          final detailsUrl = Uri.https(
            'maps.googleapis.com',
            '/maps/api/place/details/json',
            {
              'place_id': placeId,
              'fields': 'formatted_address,geometry',
              'key': _apiKey,
              'language': 'en',
            },
          );

          final detailRes = await http.get(detailsUrl).timeout(const Duration(seconds: 8));
          if (detailRes.statusCode != 200) {
            AppLog.w('Maps', 'searchAddress details HTTP ${detailRes.statusCode}');
            return null;
          }

          final detailBody = jsonDecode(detailRes.body) as Map<String, dynamic>;
          final result = detailBody['result'] as Map<String, dynamic>?;
          if (result == null) return null;

          final geometry = result['geometry'] as Map<String, dynamic>?;
          final location = geometry?['location'] as Map<String, dynamic>?;
          if (location == null) return null;

          final lat = (location['lat'] as num?)?.toDouble();
          final lng = (location['lng'] as num?)?.toDouble();
          final formattedAddress = result['formatted_address'] as String? ?? description;

          if (lat == null || lng == null) return null;
          return PlaceResult(
            address: formattedAddress,
            latLng: LatLng(lat, lng),
          );
        } catch (e, s) {
          AppLog.e('Maps', 'searchAddress details failed', e, s);
          return null;
        }
      }));

      return results.whereType<PlaceResult>().toList();
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
