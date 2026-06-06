import 'dart:async';
import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

enum TripStatus { searching, pickingUp, inProgress, arrived }

class TripUpdate {
  final LatLng     driverPosition;
  final TripStatus status;
  final int        etaMinutes;
  final double     distanceKm;
  final String     vehicleType; // 'motorbike' | 'car' | 'van' | 'truck'
  final double     heading;     // degrees 0–360

  const TripUpdate({
    required this.driverPosition,
    required this.status,
    required this.etaMinutes,
    required this.distanceKm,
    this.vehicleType = 'motorbike',
    this.heading     = 0.0,
  });
}

// Simulated route through Phnom Penh — replace StreamController with a real
// WebSocketChannel in production: WebSocketChannel.connect(Uri.parse('wss://...'))
class WebSocketService {
  static final WebSocketService _instance = WebSocketService._();
  static WebSocketService get instance => _instance;
  WebSocketService._();

  StreamController<TripUpdate>? _controller;
  Timer? _timer;
  int _step = 0;

  // Route: Phnom Penh Mall → Royal Palace (simulated GPS waypoints)
  static const List<LatLng> driverRoute = [
    LatLng(11.5720, 104.9100), // Driver starts far
    LatLng(11.5700, 104.9120),
    LatLng(11.5680, 104.9145),
    LatLng(11.5660, 104.9165), // Approaching pickup
    LatLng(11.5650, 104.9175), // At pickup (Phnom Penh Mall)
    LatLng(11.5645, 104.9210),
    LatLng(11.5638, 104.9240),
    LatLng(11.5630, 104.9262),
    LatLng(11.5622, 104.9278), // Approaching destination
    LatLng(11.5616, 104.9282), // Royal Palace — arrived
  ];

  static const LatLng pickupPoint      = LatLng(11.5650, 104.9175);
  static const LatLng destinationPoint = LatLng(11.5616, 104.9282);

  Stream<TripUpdate> startTracking() {
    _controller?.close();
    _controller = StreamController<TripUpdate>.broadcast();
    _step = 0;
    _timer?.cancel();

    _emitUpdate();

    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      _step++;
      if (_step >= driverRoute.length) {
        _step = driverRoute.length - 1;
        _emitUpdate();
        _timer?.cancel();
        return;
      }
      _emitUpdate();
    });

    return _controller!.stream;
  }

  void _emitUpdate() {
    final pos       = driverRoute[_step];
    final stepsLeft = driverRoute.length - 1 - _step;
    final status    = _step < 4
        ? TripStatus.pickingUp
        : _step < driverRoute.length - 1
            ? TripStatus.inProgress
            : TripStatus.arrived;

    final bearing = _step > 0 ? _bearing(driverRoute[_step - 1], pos) : 0.0;

    _controller?.add(TripUpdate(
      driverPosition: pos,
      status:      status,
      etaMinutes:  (stepsLeft * 2).clamp(0, 20),
      distanceKm:  (stepsLeft * 0.35).clamp(0.0, 5.0),
      vehicleType: 'motorbike',
      heading:     bearing,
    ));
  }

  static double _bearing(LatLng from, LatLng to) {
    final lat1 = from.latitude  * math.pi / 180;
    final lat2 = to.latitude    * math.pi / 180;
    final dLng = (to.longitude - from.longitude) * math.pi / 180;
    final y    = math.sin(dLng) * math.cos(lat2);
    final x    = math.cos(lat1) * math.sin(lat2) -
                 math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  void stopTracking() {
    _timer?.cancel();
    _controller?.close();
    _controller = null;
    _step = 0;
  }

  void dispose() => stopTracking();
}
