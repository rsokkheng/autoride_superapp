import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'auth_service.dart';

class LocationService {
  LocationService._();
  static final instance = LocationService._();

  StreamSubscription<Position>? _sub;

  Future<bool> requestPermission() async {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    return perm == LocationPermission.whileInUse ||
        perm == LocationPermission.always;
  }

  void startTracking({
    required String driverId,
    required void Function(Position) onPosition,
  }) {
    AuthService.signInAnon();
    _sub?.cancel();
    _sub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((position) {
      FirebaseFirestore.instance.collection('drivers_live').doc(driverId).set({
        'lat': position.latitude,
        'lng': position.longitude,
        'speed': position.speed,
        'heading': position.heading,
        'online': true,
        'updated_at': FieldValue.serverTimestamp(),
      });
      onPosition(position);
    });
  }

  Future<void> stopTracking(String driverId) async {
    await _sub?.cancel();
    _sub = null;
    await FirebaseFirestore.instance
        .collection('drivers_live')
        .doc(driverId)
        .update({'online': false, 'updated_at': FieldValue.serverTimestamp()});
  }

  Stream<LatLng> listenDriver(String driverId) {
    return FirebaseFirestore.instance
        .collection('drivers_live')
        .doc(driverId)
        .snapshots()
        .expand((doc) {
      final data = doc.data();
      if (data == null) return const <LatLng>[];
      final lat = (data['lat'] as num?)?.toDouble();
      final lng = (data['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) return const <LatLng>[];
      return [LatLng(lat, lng)];
    });
  }
}
