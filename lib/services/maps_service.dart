import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PlaceResult {
  final String address;
  final LatLng latLng;
  const PlaceResult({required this.address, required this.latLng});
}

class DirectionsResult {
  final List<LatLng> points;
  final int etaMinutes;
  final double distanceKm;
  const DirectionsResult({
    required this.points,
    required this.etaMinutes,
    required this.distanceKm,
  });
}

class MapsService {
  // Must match the key in AndroidManifest.xml and iOS AppDelegate.swift
  static const _apiKey = 'AIzaSyBzMVRTpOLoEI5y1S6zDq5icp1llS0fYkc';

  static Future<DirectionsResult?> getRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json'
      '?origin=${origin.latitude},${origin.longitude}'
      '&destination=${destination.latitude},${destination.longitude}'
      '&mode=driving'
      '&key=$_apiKey',
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = body['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) return null;

      final route = routes.first as Map<String, dynamic>;
      final leg   = (route['legs'] as List<dynamic>).first as Map<String, dynamic>;
      final etaSec    = (leg['duration']['value'] as num).toInt();
      final distanceM = (leg['distance']['value'] as num).toDouble();
      final encoded   = route['overview_polyline']['points'] as String;

      return DirectionsResult(
        points:     _decodePolyline(encoded),
        etaMinutes: (etaSec / 60).ceil(),
        distanceKm: distanceM / 1000,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<String?> reverseGeocode(LatLng pos) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json'
      '?latlng=${pos.latitude},${pos.longitude}'
      '&key=$_apiKey',
    );
    try {
      final res = await http.get(url).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final results = body['results'] as List<dynamic>?;
      if (results == null || results.isEmpty) return null;
      return (results.first as Map<String, dynamic>)['formatted_address']
          as String?;
    } catch (_) {
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
      if (res.statusCode != 200) return [];
      final body  = jsonDecode(res.body) as Map<String, dynamic>;
      final list  = (body['results'] as List<dynamic>? ?? []).take(5);
      return list.map((r) {
        final map = r as Map<String, dynamic>;
        final loc = (map['geometry'] as Map<String, dynamic>)['location']
            as Map<String, dynamic>;
        return PlaceResult(
          address: map['formatted_address'] as String,
          latLng: LatLng(
            (loc['lat'] as num).toDouble(),
            (loc['lng'] as num).toDouble(),
          ),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static List<LatLng> _decodePolyline(String encoded) {
    final result = <LatLng>[];
    int index = 0;
    int lat = 0, lng = 0;

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
