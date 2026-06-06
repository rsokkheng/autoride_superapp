import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/driver_marker_model.dart';
import 'auth_service.dart';

enum DriverStatus { online, busy, offline }

class LocationService {
  LocationService._();
  static final instance = LocationService._();

  // Trip tracking subscription (high-frequency, 5m filter)
  StreamSubscription<Position>? _tripSub;
  // Online-presence subscription (low-frequency, 50m filter — battery friendly)
  StreamSubscription<Position>? _onlineSub;

  final _db = FirebaseFirestore.instance;

  // Current service modes — kept in sync with driver_home so every GPS write
  // reflects the latest mode without restarting the stream.
  bool   _modeRide     = true;
  bool   _modeDelivery = false;
  bool   _modeRental   = false;
  String _vehicleType  = 'motorbike';

  // ── Permissions ────────────────────────────────────────────────────────────

  Future<bool> requestPermission() async {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    return perm == LocationPermission.whileInUse ||
        perm == LocationPermission.always;
  }

  // ── Online presence (Smart Dispatch) ──────────────────────────────────────
  // Broadcasts position every 50 m so the backend can match nearby drivers.
  // Includes service modes and vehicle type for dispatch + passenger icon.

  Future<void> startOnlineTracking(
    String driverId, {
    bool   modeRide     = true,
    bool   modeDelivery = false,
    bool   modeRental   = false,
    String vehicleType  = 'motorbike',
  }) async {
    _modeRide     = modeRide;
    _modeDelivery = modeDelivery;
    _modeRental   = modeRental;
    _vehicleType  = DriverMarkerModel.normalise(vehicleType);

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
      _db.collection('drivers_live').doc(driverId).set({
        'lat':           pos.latitude,
        'lng':           pos.longitude,
        'speed':         pos.speed,
        'heading':       pos.heading,
        'online':        true,
        'status':        'online',
        'vehicle_type':  _vehicleType,
        'mode_ride':     _modeRide,
        'mode_delivery': _modeDelivery,
        'mode_rental':   _modeRental,
        'updated_at':    FieldValue.serverTimestamp(),
      });
    }, onError: (_) {});
  }

  // ── Update service modes while already online ──────────────────────────────

  Future<void> updateServiceMode(
    String driverId, {
    required bool modeRide,
    required bool modeDelivery,
    required bool modeRental,
  }) async {
    _modeRide     = modeRide;
    _modeDelivery = modeDelivery;
    _modeRental   = modeRental;
    try {
      await _db.collection('drivers_live').doc(driverId).update({
        'mode_ride':     modeRide,
        'mode_delivery': modeDelivery,
        'mode_rental':   modeRental,
        'updated_at':    FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  // ── Push a status transition to Firestore immediately ─────────────────────

  Future<void> updateDriverStatus(String driverId, DriverStatus status) async {
    final statusStr = switch (status) {
      DriverStatus.online  => 'online',
      DriverStatus.busy    => 'busy',
      DriverStatus.offline => 'offline',
    };
    try {
      await _db.collection('drivers_live').doc(driverId).update({
        'status':     statusStr,
        'online':     status != DriverStatus.offline,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  // ── Trip tracking ──────────────────────────────────────────────────────────
  // High-frequency GPS (5 m filter) during an active trip.
  // Writes vehicle_type so passengers get the correct icon.

  void startTracking({
    required String   driverId,
    required void Function(Position) onPosition,
    String vehicleType = 'motorbike',
  }) {
    _onlineSub?.cancel();
    _onlineSub  = null;
    _vehicleType = DriverMarkerModel.normalise(vehicleType);
    AuthService.signInAnon();
    _tripSub?.cancel();
    _tripSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy:       LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((position) {
      _db.collection('drivers_live').doc(driverId).set({
        'lat':           position.latitude,
        'lng':           position.longitude,
        'speed':         position.speed,
        'heading':       position.heading,
        'online':        true,
        'status':        'busy',
        'vehicle_type':  _vehicleType,
        'mode_ride':     _modeRide,
        'mode_delivery': _modeDelivery,
        'mode_rental':   _modeRental,
        'updated_at':    FieldValue.serverTimestamp(),
      });
      onPosition(position);
    }, onError: (_) {});
  }

  // ── Stop ──────────────────────────────────────────────────────────────────

  Future<void> stopTracking(String driverId) async {
    await _tripSub?.cancel();
    _tripSub = null;
    await _onlineSub?.cancel();
    _onlineSub = null;
    try {
      await _db.collection('drivers_live').doc(driverId)
          .update({'online': false, 'updated_at': FieldValue.serverTimestamp()});
    } catch (_) {}
  }

  // ── Passenger side: listen to a driver's live position ────────────────────
  //
  // Returns a [DriverMarkerModel] on every Firestore document snapshot.
  // Includes heading and vehicle_type so callers can rotate + icon-swap
  // the marker without any extra API round-trips.

  Stream<DriverMarkerModel> listenDriver(String driverId) {
    return _db
        .collection('drivers_live')
        .doc(driverId)
        .snapshots()
        .expand((doc) {
      final data = doc.data();
      if (data == null) return const <DriverMarkerModel>[];
      final lat = (data['lat'] as num?)?.toDouble();
      final lng = (data['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) return const <DriverMarkerModel>[];
      return [
        DriverMarkerModel(
          driverId:    driverId,
          position:    LatLng(lat, lng),
          heading:     (data['heading']     as num?)?.toDouble() ?? 0.0,
          vehicleType: data['vehicle_type'] as String? ?? 'motorbike',
        ),
      ];
    });
  }

  // ── Passenger side: stream ride status from Firestore ─────────────────────
  //
  // Backend (or the driver client) writes to `rides_live/{rideId}` with
  // at least {status, driver_id}. This eliminates the 5-second polling timer.
  //
  // Falls back gracefully if the document doesn't exist: the stream just
  // never emits, and the caller's timer remains the safety net.

  Stream<Map<String, dynamic>> listenRideStatus(String rideId) {
    return _db
        .collection('rides_live')
        .doc(rideId)
        .snapshots()
        .expand((doc) {
      final data = doc.data();
      if (data == null) return const <Map<String, dynamic>>[];
      return [data];
    });
  }
}
