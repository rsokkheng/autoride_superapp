import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'auth_service.dart';

class LocationService {
  LocationService._();
  static final instance = LocationService._();

  // Trip tracking subscription (high-frequency, 5m filter)
  StreamSubscription<Position>? _tripSub;
  // Online-presence subscription (low-frequency, 50m filter — battery friendly)
  StreamSubscription<Position>? _onlineSub;

  final _firestore = FirebaseFirestore.instance;

  // ── Permissions ────────────────────────────────────────────────────────────────

  Future<bool> requestPermission() async {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    return perm == LocationPermission.whileInUse ||
        perm == LocationPermission.always;
  }

  // ── Online presence (Smart Dispatch) ──────────────────────────────────────────
  // Called when driver goes online from the home screen.
  // Broadcasts location every 50 m so the backend can find nearby drivers.

  Future<void> startOnlineTracking(String driverId) async {
    await _onlineSub?.cancel();
    _onlineSub = null;
    final granted = await requestPermission();
    if (!granted) return;
    AuthService.signInAnon();
    _onlineSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy:       LocationAccuracy.medium,
        distanceFilter: 50,
      ),
    ).listen((pos) {
      _firestore.collection('drivers_live').doc(driverId).set({
        'lat':        pos.latitude,
        'lng':        pos.longitude,
        'speed':      pos.speed,
        'heading':    pos.heading,
        'online':     true,
        'updated_at': FieldValue.serverTimestamp(),
      });
    }, onError: (_) {});
  }

  // ── Trip tracking ──────────────────────────────────────────────────────────────
  // High-frequency GPS during an active trip.
  // Also stops the online-presence sub (trip tracking takes over).

  void startTracking({
    required String driverId,
    required void Function(Position) onPosition,
  }) {
    _onlineSub?.cancel(); // trip tracking replaces online tracking
    _onlineSub = null;
    AuthService.signInAnon();
    _tripSub?.cancel();
    _tripSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy:       LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((position) {
      _firestore.collection('drivers_live').doc(driverId).set({
        'lat':        position.latitude,
        'lng':        position.longitude,
        'speed':      position.speed,
        'heading':    position.heading,
        'online':     true,
        'updated_at': FieldValue.serverTimestamp(),
      });
      onPosition(position);
    }, onError: (_) {});
  }

  // ── Stop ───────────────────────────────────────────────────────────────────────

  Future<void> stopTracking(String driverId) async {
    await _tripSub?.cancel();
    _tripSub = null;
    await _onlineSub?.cancel();
    _onlineSub = null;
    try {
      await _firestore
          .collection('drivers_live')
          .doc(driverId)
          .update({'online': false, 'updated_at': FieldValue.serverTimestamp()});
    } catch (_) {}
  }

  // ── Passenger side: listen to a driver's live position ───────────────────────

  Stream<LatLng> listenDriver(String driverId) {
    return _firestore
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
