import 'dart:async';
import 'dart:math' show min, max, sin, cos, atan2, pi;
import 'dart:ui' show lerpDouble;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../services/websocket_service.dart';
import '../../services/notification_service.dart';
import '../../services/api_service.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/location_service.dart';
import '../../services/maps_service.dart';
import '../../services/marker_icon_service.dart';
import '../../models/driver_marker_model.dart';
import 'rate_driver_screen.dart';
import '../shared/ride_chat_screen.dart';
import '../../theme/app_theme.dart';

const _kGreen = Color(0xFF00B14F);

/// A single intermediate stop passed to [TripTrackingScreen].
class TripStop {
  final String address;
  final LatLng latLng;
  const TripStop({required this.address, required this.latLng});
}

class TripTrackingScreen extends StatefulWidget {
  final int?    rideId;
  final String  driverId;
  final String  driverName;
  final String  driverRating;
  final String  driverTrips;
  final String  vehicle;
  final String  vehicleColor;
  final String  vehicleType;  // raw type: 'motorbike' | 'car' | 'van' | 'truck'
  final String  plate;
  final String  from;
  final String  to;
  final String  fare;
  final bool    isScheduled;
  // Real-world coordinates — used for live routing. Falls back to Phnom Penh
  // test coords when null (e.g., when navigated from a screen that doesn't
  // have geocoded coordinates yet).
  final LatLng? pickupLatLng;
  final LatLng? destLatLng;
  /// Intermediate stops between pickup and destination (in order).
  final List<TripStop> wayStops;

  const TripTrackingScreen({
    super.key,
    this.rideId,
    this.driverId      = '',
    this.driverName    = 'Finding driver...',
    this.driverRating  = '--',
    this.driverTrips   = '--',
    this.vehicle       = '--',
    this.vehicleColor  = '',
    this.vehicleType   = 'motorbike',
    this.plate         = '--',
    this.from          = '--',
    this.to            = '--',
    this.fare          = '--',
    this.isScheduled   = false,
    this.pickupLatLng,
    this.destLatLng,
    this.wayStops      = const [],
  });

  @override
  State<TripTrackingScreen> createState() => _TripTrackingScreenState();
}

class _TripTrackingScreenState extends State<TripTrackingScreen>
    with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  StreamSubscription<TripUpdate>?        _trackingSub;
  StreamSubscription<DriverMarkerModel>? _firestoreSub;
  StreamSubscription<Map<String, dynamic>>? _rideStatusSub;
  TripUpdate? _lastUpdate;
  // Server-side status string — more complete than TripStatus enum
  // (covers 'requested', 'accepted', 'driver_arrived', 'in_progress',
  //  'completed', 'cancelled')
  String _rideStatus = 'requested';

  final Set<Marker>   _markers   = {};
  final Set<Polyline> _polylines = {};

  // Pulse animation controller — reserved for a future "searching" ripple UI
  late AnimationController _pulseController;

  // Smooth driver-marker movement between successive GPS positions
  late AnimationController _markerAnimCtrl;
  LatLng? _prevDriverPos;
  LatLng? _targetDriverPos;

  // Live route data from Directions API
  int    _etaMinutes = 8;
  double _distanceKm = 2.4;
  DateTime? _lastRouteFetch;

  bool _cancelling = false;

  // ETA live countdown
  Timer?  _etaCountdownTimer;
  int     _etaSecondsLeft = 0;

  // Trip sharing state
  String? _shareUrl;
  bool    _sharing = false;

  // Masked driver phone (fetched once driver is assigned)
  String? _driverPhone;

  // SOS state
  bool _sosLoading = false;

  // Mutable driver info — updated when driver is assigned after booking
  late String _driverName;
  late String _driverRating;
  late String _driverTrips;
  late String _vehicle;
  late String _vehicleColor;
  late String _vehicleType;
  late String _plate;
  String  _currentDriverId = '';
  String? _driverAvatarUrl;
  Timer? _ridePollTimer;

  // Dynamic vehicle icon — loaded async; null means use default pin
  BitmapDescriptor? _driverIcon;
  double _driverHeading = 0.0;

  // Multi-stop: index into wayStops + destination.
  // 0..wayStops.length-1 = intermediate stops; wayStops.length = final destination.
  int _nextStopIndex = 0;
  // ETA in minutes to each remaining stop (index matches _nextStopIndex offset).
  List<int> _stopEtas = [];

  bool get _hasWayStops => widget.wayStops.isNotEmpty;

  /// The LatLng of the stop we are currently heading to during the trip.
  LatLng get _currentTarget {
    if (!_hasWayStops || _nextStopIndex >= widget.wayStops.length) return _destPoint;
    return widget.wayStops[_nextStopIndex].latLng;
  }

  String get _currentTargetLabel {
    if (!_hasWayStops || _nextStopIndex >= widget.wayStops.length) return widget.to;
    return 'Stop ${_nextStopIndex + 1}: ${widget.wayStops[_nextStopIndex].address}';
  }

  LatLng get _pickupPoint => widget.pickupLatLng ?? WebSocketService.pickupPoint;
  LatLng get _destPoint   => widget.destLatLng   ?? WebSocketService.destinationPoint;

  static const _initialCamera = CameraPosition(
    target: LatLng(11.5680, 104.9195),
    zoom: 14.5,
  );

  @override
  void initState() {
    super.initState();
    _driverName      = widget.driverName;
    _driverRating    = widget.driverRating;
    _driverTrips     = widget.driverTrips;
    _vehicle         = widget.vehicle;
    _vehicleColor    = widget.vehicleColor;
    _vehicleType     = DriverMarkerModel.normalise(widget.vehicleType);
    _plate           = widget.plate;
    _currentDriverId = widget.driverId;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _markerAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..addListener(_onMarkerAnimTick);

    // Pre-load icon so it's ready before first position update
    MarkerIconService.forType(_vehicleType).then((icon) {
      if (mounted) setState(() => _driverIcon = icon);
    });

    _initMarkers();
    _fetchStaticFullRoute();
    _startTracking();
    _startRidePoll();
  }

  void _initMarkers() {
    _markers.addAll([
      Marker(
        markerId: const MarkerId('pickup'),
        position: _pickupPoint,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(title: widget.from),
      ),
      // Intermediate stop markers
      for (int i = 0; i < widget.wayStops.length; i++)
        Marker(
          markerId: MarkerId('stop_$i'),
          position: widget.wayStops[i].latLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: InfoWindow(title: 'Stop ${i + 1}: ${widget.wayStops[i].address}'),
        ),
      Marker(
        markerId: const MarkerId('destination'),
        position: _destPoint,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: widget.to),
      ),
    ]);
    // Static full-route line (gray dashed): pickup → destination.
    // Drawn as a straight line immediately, then upgraded to follow actual
    // roads once _fetchStaticFullRoute() resolves. Stays visible as context
    // for the whole trip.
    _polylines.add(Polyline(
      polylineId: const PolylineId('full_route'),
      points:     [_pickupPoint, _destPoint],
      color:      const Color(0x55888888),
      width:      4,
      patterns:   [PatternItem.dash(16), PatternItem.gap(8)],
    ));
  }

  // Replaces the straight-line 'full_route' placeholder with one that
  // follows actual roads through pickup → each stop → destination.
  Future<void> _fetchStaticFullRoute() async {
    final legs = [_pickupPoint, ...widget.wayStops.map((s) => s.latLng), _destPoint];
    if (legs.length < 2) return;

    final routedPoints = <LatLng>[];
    for (int i = 0; i < legs.length - 1; i++) {
      final result = await MapsService.getRoute(origin: legs[i], destination: legs[i + 1]);
      routedPoints.addAll(
          result != null && result.points.isNotEmpty ? result.points : [legs[i], legs[i + 1]]);
    }
    if (!mounted || routedPoints.isEmpty) return;

    setState(() {
      _polylines
        ..removeWhere((p) => p.polylineId.value == 'full_route')
        ..add(Polyline(
          polylineId: const PolylineId('full_route'),
          points:     routedPoints,
          color:      const Color(0x55888888),
          width:      4,
          patterns:   [PatternItem.dash(16), PatternItem.gap(8)],
        ));
    });
  }

  // ── Marker animation ────────────────────────────────────────────────────────

  void _onMarkerAnimTick() {
    final prev   = _prevDriverPos;
    final target = _targetDriverPos;
    if (prev == null || target == null || !mounted) return;
    final t   = _markerAnimCtrl.value;
    final lat = lerpDouble(prev.latitude,  target.latitude,  t)!;
    final lng = lerpDouble(prev.longitude, target.longitude, t)!;
    _setDriverMarker(LatLng(lat, lng));
  }

  // ── Heading: bearing from previous → current position ────────────────────────

  static double _bearing(LatLng from, LatLng to) {
    final lat1 = from.latitude  * pi / 180;
    final lat2 = to.latitude    * pi / 180;
    final dLng = (to.longitude - from.longitude) * pi / 180;
    final y    = sin(dLng) * cos(lat2);
    final x    = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLng);
    return (atan2(y, x) * 180 / pi + 360) % 360;
  }

  void _setDriverMarker(LatLng pos) {
    if (!mounted) return;

    if (_prevDriverPos != null && _prevDriverPos != pos) {
      _driverHeading = _bearing(_prevDriverPos!, pos);
    }

    setState(() {
      _markers.removeWhere((m) => m.markerId.value == 'driver');
      _markers.add(Marker(
        markerId:   const MarkerId('driver'),
        position:   pos,
        icon:       _driverIcon ?? BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueAzure),
        infoWindow: InfoWindow(title: _driverName, snippet: _vehicle),
        rotation:   _driverHeading,
        anchor:     const Offset(0.5, 0.5),
        flat:       true, // marker rotates with map bearing
      ));
    });

    // Camera: fit driver + next waypoint so both are always visible
    final waypoint = _driverAssigned && _lastUpdate?.status == TripStatus.inProgress
        ? _destPoint
        : _pickupPoint;
    _fitCamera(pos, waypoint);
  }

  void _fitCamera(LatLng a, LatLng b) {
    final sw = LatLng(
      min(a.latitude,  b.latitude)  - 0.004,
      min(a.longitude, b.longitude) - 0.004,
    );
    final ne = LatLng(
      max(a.latitude,  b.latitude)  + 0.004,
      max(a.longitude, b.longitude) + 0.004,
    );
    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(southwest: sw, northeast: ne), 80),
    );
  }

  static bool _inCambodia(LatLng p) =>
      p.latitude  >= 10.4 && p.latitude  <= 14.7 &&
      p.longitude >= 102.3 && p.longitude <= 107.6;

  // ── Firestore driver position ──────────────────────────────────────────────
  //
  // Receives a full DriverMarkerModel from Firestore, which now carries
  // heading and vehicle_type alongside lat/lng.

  void _onDriverMarker(DriverMarkerModel model) {
    final pos = model.position;
    if (!_inCambodia(pos)) return;

    // Apply heading from the Firestore doc (driver's GPS bearing)
    _driverHeading = model.heading;

    // Reload icon if vehicle type changed (e.g. driver switched vehicles)
    final newType = DriverMarkerModel.normalise(model.vehicleType);
    if (newType != _vehicleType) {
      _vehicleType = newType;
      MarkerIconService.forType(newType).then((icon) {
        if (mounted) setState(() => _driverIcon = icon);
      });
    }

    // Smooth lerp animation from previous position to current
    _prevDriverPos   = _targetDriverPos ?? pos;
    _targetDriverPos = pos;
    _markerAnimCtrl
      ..reset()
      ..forward();

    // Throttle Routes API calls — at most once every 15 s
    final now = DateTime.now();
    if (_lastRouteFetch == null ||
        now.difference(_lastRouteFetch!).inSeconds >= 15) {
      _lastRouteFetch = now;
      _fetchRoute(pos);
    }
  }

  // ── Routes API — live route + ETA ────────────────────────────────────────────

  Future<void> _fetchRoute(LatLng driverPos) async {
    final inProgress =
        _driverAssigned && _lastUpdate?.status == TripStatus.inProgress;

    // Before pickup: driver → pickup.
    // During trip: driver → current stop (or destination if no more stops).
    final destination = inProgress ? _currentTarget : _pickupPoint;

    final result = await MapsService.getRoute(
      origin:      driverPos,
      destination: destination,
    );
    if (!mounted || result == null) return;

    // Build per-stop ETAs for remaining stops during trip.
    List<int> stopEtas = [];
    if (inProgress && _hasWayStops) {
      stopEtas = [result.etaMinutes]; // ETA to next stop
      // Estimate subsequent stops by fetching routes in sequence.
      LatLng prev = destination;
      final remaining = widget.wayStops.sublist(_nextStopIndex + 1);
      int accumulated = result.etaMinutes;
      for (final stop in remaining) {
        final r = await MapsService.getRoute(origin: prev, destination: stop.latLng);
        accumulated += r?.etaMinutes ?? 5;
        stopEtas.add(accumulated);
        prev = stop.latLng;
      }
      // Final destination ETA
      final finalR = await MapsService.getRoute(origin: prev, destination: _destPoint);
      accumulated += finalR?.etaMinutes ?? 5;
      stopEtas.add(accumulated);
    }

    if (!mounted) return;
    setState(() {
      _etaMinutes = result.etaMinutes;
      _distanceKm = result.distanceKm;
      _stopEtas   = stopEtas;
      _resetEtaCountdown(_etaMinutes);
      _polylines
        ..removeWhere((p) => p.polylineId.value == 'live_route')
        ..add(Polyline(
          polylineId: const PolylineId('live_route'),
          points:     result.points,
          color:      _kGreen,
          width:      5,
          startCap:   Cap.roundCap,
          endCap:     Cap.roundCap,
          jointType:  JointType.round,
        ));
    });
  }

  /// Called by websocket/poll when driver position is close to the current
  /// intermediate stop — advances to the next stop.
  void _checkStopProximity(LatLng driverPos) {
    if (!_hasWayStops || _nextStopIndex >= widget.wayStops.length) return;
    final stop = widget.wayStops[_nextStopIndex];
    final dist = Geolocator.distanceBetween(
      driverPos.latitude, driverPos.longitude,
      stop.latLng.latitude, stop.latLng.longitude,
    );
    if (dist < 80) { // within 80 m → arrived at stop
      setState(() {
        _nextStopIndex++;
        if (_stopEtas.isNotEmpty) _stopEtas.removeAt(0);
      });
    }
  }

  // ── Cancel ride ────────────────────────────────────────────────────────────

  // Cancellable: requested | accepted | driver_arrived
  // Not cancellable: in_progress | completed | cancelled
  bool get _canCancel => const {
    'requested', 'accepted', 'driver_arrived'
  }.contains(_rideStatus);

  bool get _hasCancellationFee => _rideStatus == 'driver_arrived';

  Future<void> _cancelRide() async {
    if (widget.rideId == null || _cancelling) return;

    if (!_canCancel) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_rideStatus == 'in_progress'
            ? 'Cannot cancel a ride in progress.'
            : 'This ride cannot be cancelled.'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    // Step 1: Pick a reason
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => _CancelReasonDialog(
        hasFee: _hasCancellationFee,
      ),
    );
    if (reason == null || !mounted) return;

    setState(() => _cancelling = true);
    try {
      await ApiService.cancelRideWithReason(widget.rideId!,
          reason: reason);
      if (!mounted) return;
      _disposeMapAndPop();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
      setState(() => _cancelling = false);
    } catch (_) {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  // Dispose map controller before pop to avoid iOS "recreating_view" error.
  // The platform view is released asynchronously on UIKit; waiting one frame
  // gives it enough time before the next screen's GoogleMap is created.
  void _disposeMapAndPop() {
    _mapController?.dispose();
    _mapController = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  Future<void> _goToMyLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      _mapController?.animateCamera(
          CameraUpdate.newLatLng(LatLng(pos.latitude, pos.longitude)));
    } catch (_) {}
  }

  // ── Tracking ───────────────────────────────────────────────────────────────

  void _startTracking() {
    _trackingSub =
        WebSocketService.instance.startTracking().listen((update) async {
      if (!mounted) return;
      final prevStatus = _lastUpdate?.status;
      setState(() => _lastUpdate = update);

      // Reload vehicle icon if server sends a different vehicle type
      final newType = DriverMarkerModel.normalise(update.vehicleType);
      if (newType != _vehicleType) {
        _vehicleType = newType;
        MarkerIconService.forType(newType).then((icon) {
          if (mounted) setState(() => _driverIcon = icon);
        });
      }

      // Animate driver marker from WebSocket position when Firestore isn't live
      if (_currentDriverId.isEmpty) {
        _onDriverMarker(DriverMarkerModel(
          driverId:    '',
          position:    update.driverPosition,
          heading:     update.heading,
          vehicleType: update.vehicleType,
        ));
      }

      // Advance to next wayStop when driver arrives within 80 m during trip
      if (update.status == TripStatus.inProgress) {
        _checkStopProximity(update.driverPosition);
      }

      if (update.status == TripStatus.pickingUp &&
          prevStatus == TripStatus.searching) {
        await NotificationService.instance.showTripUpdate(
          title: '🚗 Driver on the way',
          body: '$_driverName is $_etaMinutes min away',
          payload: 'picking_up',
        );
      } else if (update.status == TripStatus.arrived) {
        await NotificationService.instance.showTripUpdate(
          title: '✅ Driver Arrived!',
          body: '$_driverName is waiting at ${widget.from}',
          payload: 'arrived',
        );
      }
    });

    if (_currentDriverId.isNotEmpty) {
      _firestoreSub = LocationService.instance
          .listenDriver(_currentDriverId)
          .listen(_onDriverMarker);
    }

    // Firestore ride-status stream — replaces the 5-second poll timer.
    // Falls back to the timer if the rides_live doc doesn't exist yet.
    if (widget.rideId != null) {
      _rideStatusSub = LocationService.instance
          .listenRideStatus(widget.rideId.toString())
          .listen(_onFirestoreRideStatus);
    }
  }

  void _onFirestoreRideStatus(Map<String, dynamic> data) {
    final status   = data['status']    as String? ?? '';
    final driverId = data['driver_id'] as String? ?? '';

    // Cancel the polling timer once Firestore is delivering status
    _ridePollTimer?.cancel();
    _ridePollTimer = null;

    if (status.isNotEmpty && mounted) {
      setState(() => _rideStatus = status);
    }

    if (status == 'accepted' && driverId.isNotEmpty &&
        driverId != _currentDriverId) {
      // New driver assigned — re-subscribe to their live position
      _currentDriverId = driverId;
      _firestoreSub?.cancel();
      _firestoreSub = LocationService.instance
          .listenDriver(driverId)
          .listen(_onDriverMarker);
    }
  }

  void _resetEtaCountdown(int etaMinutes) {
    _etaCountdownTimer?.cancel();
    _etaSecondsLeft = etaMinutes * 60;
    _etaCountdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_etaSecondsLeft > 0) _etaSecondsLeft--;
      });
    });
  }

  String get _etaCountdownText {
    if (_etaSecondsLeft <= 0) return 'Arriving now';
    final m = _etaSecondsLeft ~/ 60;
    final s = _etaSecondsLeft % 60;
    return m > 0
        ? '$m min ${s.toString().padLeft(2, '0')} sec'
        : '${s.toString().padLeft(2, '0')} sec';
  }

  @override
  void dispose() {
    _ridePollTimer?.cancel();
    _etaCountdownTimer?.cancel();
    _trackingSub?.cancel();
    _firestoreSub?.cancel();
    _rideStatusSub?.cancel();
    WebSocketService.instance.stopTracking();
    _mapController?.dispose();
    _pulseController.dispose();
    _markerAnimCtrl.dispose();
    super.dispose();
  }

  // ── Ride poll (detects when driver is assigned) ────────────────────────────

  void _startRidePoll() {
    if (widget.rideId == null || _currentDriverId.isNotEmpty) return;
    _ridePollTimer =
        Timer.periodic(const Duration(seconds: 5), (_) => _pollRide());
  }

  Future<void> _pollRide() async {
    if (widget.rideId == null) return;
    try {
      final ride = await ApiService.getRide(widget.rideId!);
      if (!mounted) return;
      // Always sync server status
      if (ride.status.isNotEmpty) setState(() => _rideStatus = ride.status);
      if (ride.driverId == null) return;
      final newId = ride.driverId.toString();
      if (newId == _currentDriverId) return;
      setState(() {
        _currentDriverId = newId;
        _driverName      = ride.driver?.name ?? 'Driver #${ride.driverId}';
        _driverAvatarUrl = ride.driver?.photoUrl;
        _driverRating    = ride.driver?.rating != null
            ? ride.driver!.rating!.toStringAsFixed(1)
            : '--';
        _driverTrips     = ride.driver?.totalTrips != null
            ? ride.driver!.totalTrips!.toString()
            : '--';
        _vehicle      = ride.vehicle != null
            ? '${ride.vehicle!.make} ${ride.vehicle!.model} ${ride.vehicle!.year}'
            : '--';
        _vehicleColor = '';
        _plate        = ride.vehicle?.licensePlate ?? '--';
        if (ride.vehicle?.type != null) {
          final newType = DriverMarkerModel.normalise(ride.vehicle!.type);
          if (newType != _vehicleType) _vehicleType = newType;
        }
      });
      if (ride.vehicle?.type != null) {
        MarkerIconService.forType(
            DriverMarkerModel.normalise(ride.vehicle!.type)).then((icon) {
          if (mounted) setState(() => _driverIcon = icon);
        });
      }
      _firestoreSub?.cancel();
      _firestoreSub = LocationService.instance
          .listenDriver(_currentDriverId)
          .listen(_onDriverMarker);
      _ridePollTimer?.cancel();
      // Fetch masked phone number for the Call button
      if (widget.rideId != null) {
        try {
          final phone = await ApiService.getMaskedPhone(widget.rideId!);
          if (mounted) setState(() => _driverPhone = phone);
        } catch (_) {}
      }
    } catch (_) {}
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static IconData _vehicleTypeIcon(String type) {
    switch (type) {
      case 'motorbike': return Icons.two_wheeler;
      case 'van':       return Icons.airport_shuttle;
      case 'truck':     return Icons.local_shipping;
      default:          return Icons.directions_car;
    }
  }

  // Status must not advance past "searching" until a driver is actually assigned.
  bool get _driverAssigned => _currentDriverId.isNotEmpty;

  bool get _isArrived =>
      _driverAssigned &&
      (_lastUpdate?.status == TripStatus.arrived ||
       _rideStatus == 'driver_arrived');

  String get _statusTitle {
    if (!_driverAssigned) return 'Finding your driver...';
    if (_rideStatus == 'driver_arrived') return 'Driver has arrived!';
    if (_rideStatus == 'in_progress')    return 'Trip in progress';
    switch (_lastUpdate?.status) {
      case TripStatus.pickingUp:   return 'Your driver is on the way';
      case TripStatus.inProgress:  return 'Trip in progress';
      case TripStatus.arrived:     return 'Driver has arrived!';
      default:                     return 'Driver assigned — connecting...';
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final eta  = _isArrived ? 0 : _etaMinutes;
    final dist = _distanceKm.toStringAsFixed(1);

    return Scaffold(
      backgroundColor: context.appBackground,
      body: Stack(
        children: [
          // ── Map ────────────────────────────────────────────────────────
          GoogleMap(
            onMapCreated: (c) {
              _mapController = c;
              final pickup = _pickupPoint;
              final dest   = _destPoint;
              c.animateCamera(CameraUpdate.newLatLngBounds(
                LatLngBounds(
                  southwest: LatLng(
                    min(pickup.latitude,  dest.latitude)  - 0.012,
                    min(pickup.longitude, dest.longitude) - 0.012,
                  ),
                  northeast: LatLng(
                    max(pickup.latitude,  dest.latitude)  + 0.012,
                    max(pickup.longitude, dest.longitude) + 0.012,
                  ),
                ),
                72,
              ));
            },
            initialCameraPosition: _initialCamera,
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapType: MapType.normal,
          ),

          // ── Route card (top) ───────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: context.appSurface,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: Offset(0, 4))
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(16, 18, 16, 0),
                      child: Row(children: [
                        Container(
                            width: 12, height: 12,
                            decoration: BoxDecoration(
                                color: _kGreen, shape: BoxShape.circle)),
                        SizedBox(width: 12),
                        Expanded(
                            child: Text('My location',
                                style: TextStyle(
                                    color: context.appTextPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500))),
                        Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                              color: context.appCardBg, shape: BoxShape.circle),
                          child: Icon(Icons.add, color: context.appTextSecondary, size: 18),
                        ),
                      ]),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 21, top: 4, bottom: 4),
                      child: Row(children: [
                        Container(width: 2, height: 14, color: context.appCardBg),
                      ]),
                    ),
                    // Intermediate stops
                    for (int i = 0; i < widget.wayStops.length; i++) ...[
                      Padding(
                        padding: EdgeInsets.only(left: 21, top: 4, bottom: 4),
                        child: Row(children: [
                          Container(width: 2, height: 14,
                              color: i < _nextStopIndex
                                  ? _kGreen
                                  : Colors.grey[300]),
                        ]),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
                        child: Row(children: [
                          Icon(Icons.place,
                              color: i < _nextStopIndex
                                  ? _kGreen
                                  : i == _nextStopIndex
                                      ? Colors.orange
                                      : Colors.grey,
                              size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(widget.wayStops[i].address,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: i < _nextStopIndex
                                        ? context.appTextSecondary
                                        : context.appTextPrimary,
                                    fontSize: 13,
                                    decoration: i < _nextStopIndex
                                        ? TextDecoration.lineThrough
                                        : null,
                                    fontWeight: FontWeight.w500)),
                          ),
                          Text('Stop ${i + 1}',
                              style: TextStyle(
                                  color: i == _nextStopIndex
                                      ? Colors.orange
                                      : context.appTextSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ],
                    if (widget.wayStops.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(left: 21, top: 4, bottom: 4),
                        child: Row(children: [
                          Container(width: 2, height: 14, color: context.appCardBg),
                        ]),
                      ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 18),
                      child: Row(children: [
                        Icon(Icons.location_on, color: Colors.red, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(widget.to,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: context.appTextPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500)),
                        ),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── ETA badge ─────────────────────────────────────────────────
          Positioned(
            left: 24,
            bottom: 310,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: context.appSurface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15), blurRadius: 8)
                ],
              ),
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  children: [
                    TextSpan(
                        text: '$eta min',
                        style: TextStyle(color: _kGreen)),
                    TextSpan(
                        text: '\naway',
                        style: TextStyle(
                            color: context.appTextSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w400)),
                  ],
                ),
              ),
            ),
          ),

          // ── Map controls ──────────────────────────────────────────────
          Positioned(
            right: 14,
            bottom: 302,
            child: Column(children: [
              _MapBtn(icon: Icons.my_location, onTap: _goToMyLocation),
              const SizedBox(height: 8),
              _MapBtn(icon: Icons.layers_outlined, onTap: () {}),
            ]),
          ),

          // ── Bottom sheet ──────────────────────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: context.appSurface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black12, blurRadius: 20, offset: Offset(0, -4))
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 4, 20, 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle
                      Center(
                        child: Container(
                          margin: EdgeInsets.symmetric(vertical: 6),
                          width: 40, height: 4,
                          decoration: BoxDecoration(
                              color: context.appCardBg,
                              borderRadius: BorderRadius.circular(2)),
                        ),
                      ),

                      // Status
                      Text(_statusTitle,
                          style: TextStyle(
                              color: context.appTextPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w700)),
                      SizedBox(height: 4),
                      if (_driverAssigned) ...[
                        RichText(
                          text: TextSpan(
                            style: TextStyle(fontSize: 13, color: context.appTextSecondary),
                            children: [
                              TextSpan(
                                text: _hasWayStops &&
                                        _rideStatus == 'in_progress' &&
                                        _nextStopIndex < widget.wayStops.length
                                    ? 'Stop ${_nextStopIndex + 1} in '
                                    : 'Arriving in ',
                              ),
                              TextSpan(
                                text: _isArrived ? 'Now' : _etaCountdownText,
                                style: TextStyle(
                                    color: _kGreen, fontWeight: FontWeight.w700),
                              ),
                              if (!_isArrived) TextSpan(text: ' · $dist km'),
                            ],
                          ),
                        ),
                        // Per-stop ETA list (shown only during in_progress with stops)
                        if (_hasWayStops && _rideStatus == 'in_progress' &&
                            _stopEtas.isNotEmpty) ...[
                          SizedBox(height: 10),
                          _StopEtaList(
                            wayStops:       widget.wayStops,
                            destination:    widget.to,
                            nextStopIndex:  _nextStopIndex,
                            stopEtas:       _stopEtas,
                          ),
                        ],
                      ] else
                        Text('Looking for a nearby driver…',
                            style: TextStyle(fontSize: 13, color: context.appTextSecondary)),
                      SizedBox(height: 8),

                      // Driver + Car
                      Row(children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: context.appCardBg,
                          foregroundImage: _driverAvatarUrl != null
                              ? CachedNetworkImageProvider(_driverAvatarUrl!)
                              : null,
                          child: Text(
                            _driverName.isNotEmpty
                                ? _driverName[0].toUpperCase()
                                : 'D',
                            style: TextStyle(
                                color: context.appTextPrimary,
                                fontSize: 22,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_driverName,
                                  style: TextStyle(
                                      color: context.appTextPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15)),
                              SizedBox(height: 4),
                              Row(children: [
                                Icon(Icons.star,
                                    color: Color(0xFFFFA000), size: 15),
                                SizedBox(width: 3),
                                Text(_driverRating,
                                    style: TextStyle(
                                        color: context.appTextSecondary, fontSize: 13)),
                                if (_driverTrips != '--') ...[
                                  SizedBox(width: 8),
                                  Text('$_driverTrips trips',
                                      style: TextStyle(
                                          color: context.appTextSecondary, fontSize: 13)),
                                ],
                              ]),
                            ],
                          ),
                        ),
                        // Car info
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Icon(_vehicleTypeIcon(_vehicleType),
                                size: 30, color: context.appTextSecondary),
                            Text(_plate,
                                style: TextStyle(
                                    color: context.appTextPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13)),
                            Text(
                              _vehicleColor.isNotEmpty
                                  ? '$_vehicle · $_vehicleColor'
                                  : _vehicle,
                              style: TextStyle(
                                  color: context.appTextSecondary, fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ]),
                      const SizedBox(height: 8),

                      // Action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _ActionBtn(
                            icon: Icons.call_outlined,
                            label: 'Call',
                            onTap: _driverAssigned ? _callDriver : () {},
                          ),
                          _ActionBtn(
                            icon: Icons.chat_bubble_outline,
                            label: 'Chat',
                            onTap: _openRideChat,
                          ),
                          _ActionBtn(
                            icon:  _shareUrl != null
                                ? Icons.share_location
                                : Icons.share_outlined,
                            label: _shareUrl != null ? 'Sharing' : 'Share',
                            onTap: _sharing
                                ? () {}
                                : !_canShare
                                    ? () {}
                                    : _shareUrl != null
                                        ? () => _showShareSheet(_shareUrl!)
                                        : _shareTrip,
                            highlight: _shareUrl != null,
                            loading:   _sharing,
                            disabled:  !_canShare,
                          ),
                          if (_canCancel)
                            _ActionBtn(
                              icon:    Icons.cancel_outlined,
                              label:   _cancelling ? '...' : 'Cancel',
                              onTap:   _cancelling ? () {} : _cancelRide,
                              danger:  true,
                              loading: _cancelling,
                            )
                          else if (_driverAssigned)
                            _ActionBtn(
                              icon:    Icons.sos_outlined,
                              label:   _sosLoading ? '...' : 'SOS',
                              onTap:   _sosLoading ? () {} : _sendSos,
                              danger:  true,
                              loading: _sosLoading,
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Buttons row
                      Row(children: [
                        if (_canCancel)
                          GestureDetector(
                            onTap: _cancelling ? null : _cancelRide,
                            child: Container(
                              width: 48, height: 48,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: _cancelling
                                    ? Colors.grey[300]
                                    : Colors.red,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: _cancelling
                                  ? const Padding(
                                      padding: EdgeInsets.all(14),
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.cancel_outlined,
                                      color: Colors.white, size: 26),
                            ),
                          ),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              if (_isArrived) {
                                // Fetch final ride to get server-confirmed distance/duration/addresses
                                double? distKm;
                                int?    durMin;
                                String  fromAddr = widget.from;
                                String  toAddr   = widget.to;
                                String  payMethod    = 'cash';
                                int?    baseFareKhr;
                                int?    distFeeKhr;
                                // Was set once at booking time — for a metered
                                // (no-destination) ride the real fare isn't known
                                // until completion, so this starts as '0'/a
                                // placeholder. Overwritten below once the fresh
                                // fare comes back from the server.
                                String  fareText = widget.fare;
                                if (widget.rideId != null) {
                                  try {
                                    final r = await ApiService.getRide(widget.rideId!);
                                    distKm = r.distanceKm;
                                    durMin = r.durationMin;
                                    if (r.pickupAddress.isNotEmpty)  fromAddr = r.pickupAddress;
                                    if (r.dropoffAddress.isNotEmpty) toAddr   = r.dropoffAddress;
                                    if (r.paymentMethod != null && r.paymentMethod!.isNotEmpty) {
                                      payMethod = r.paymentMethod!;
                                    }
                                    // Derive base fare and distance fee from total.
                                    // Base fare is ~40% of total; distance fee is the remainder
                                    // (both pre-surge). If surgeMultiplier is present we account
                                    // for it so the two parts still sum to the displayed total.
                                    final totalKhr = r.fareKhr;
                                    if (totalKhr > 0) {
                                      fareText = AppTheme.khr(totalKhr);
                                      final surge = r.surgeMultiplier ?? 1.0;
                                      final preSurge = (totalKhr / surge).round();
                                      baseFareKhr = (preSurge * 0.4).round();
                                      distFeeKhr  = totalKhr - baseFareKhr;
                                    }
                                  } catch (_) {}
                                }
                                // Fall back to live-tracked distance if the server
                                // didn't return one — checking for a real 0 too,
                                // since the backend has been observed returning
                                // that (not null) for a completed metered ride.
                                if ((distKm == null || distKm <= 0) && _distanceKm > 0) {
                                  distKm = _distanceKm;
                                }
                                if (!mounted) return;
                                // Dispose map before replacing route to avoid
                                // iOS "recreating_view" PlatformException.
                                _mapController?.dispose();
                                _mapController = null;
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => RateDriverScreen(
                                            rideId:         widget.rideId,
                                            driverName:     _driverName,
                                            fare:           fareText,
                                            distanceKm:     distKm,
                                            durationMin:    durMin,
                                            from:           fromAddr,
                                            to:             toAddr,
                                            stops:          widget.wayStops.map((s) => s.address).toList(),
                                            paymentMethod:  payMethod,
                                            baseFareKhr:    baseFareKhr,
                                            distanceFeeKhr: distFeeKhr,
                                          )),
                                );
                              } else {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(const SnackBar(
                                  content:
                                      Text('Waiting for driver to arrive...'),
                                  behavior: SnackBarBehavior.floating,
                                  duration: Duration(seconds: 2),
                                ));
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.confirmBlue,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            child: const Text("I'm here",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openRideChat() async {
    if (widget.rideId == null) return;
    final saved = await ApiService.getSavedUser();
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => RideChatScreen(
        rideId:      widget.rideId!.toString(),
        driverId:    int.tryParse(_currentDriverId) ?? 0,
        passengerId: saved?.id ?? 0,
        myId:        saved?.id   ?? 0,
        myName:      saved?.name ?? 'Passenger',
        otherName:   _driverName,
        isDriver:    false,
      ),
    ));
  }

  // Sharing only valid while ride is active (not yet completed/cancelled)
  bool get _canShare =>
      _driverAssigned &&
      _rideStatus != 'completed' &&
      _rideStatus != 'cancelled' &&
      _lastUpdate?.status != null &&
      _lastUpdate!.status != TripStatus.searching;

  // ── SOS ────────────────────────────────────────────────────────────────────

  Future<void> _sendSos() async {
    if (widget.rideId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('🆘 Send SOS?',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.w800)),
        content: const Text(
            'An SOS alert will be sent to all your emergency contacts immediately.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: AppTheme.confirmButtonStyle(background: Colors.red),
            child: const Text('Send SOS'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _sosLoading = true);
    try {
      final result = await ApiService.sendSos(widget.rideId!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.contactsNotified > 0
            ? '🆘 SOS sent to ${result.contactsNotified} contact(s)'
            : '🆘 SOS alert sent'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('SOS failed: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _sosLoading = false);
    }
  }

  // ── Call driver ────────────────────────────────────────────────────────────

  Future<void> _callDriver() async {
    // Fetch masked phone on demand if not yet loaded
    if (_driverPhone == null && widget.rideId != null) {
      try {
        final phone = await ApiService.getMaskedPhone(widget.rideId!);
        if (mounted) setState(() => _driverPhone = phone);
      } on ApiException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ));
        }
        return;
      }
    }
    final phone = _driverPhone;
    if (phone == null || phone.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Driver phone not available yet.'),
          behavior: SnackBarBehavior.floating,
        ));
      }
      return;
    }
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Cannot dial $phone on this device.'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  // ── Trip sharing ───────────────────────────────────────────────────────────

  Future<void> _shareTrip() async {
    if (widget.rideId == null) return;
    setState(() => _sharing = true);
    try {
      final result = await ApiService.shareTrip(widget.rideId!);
      if (!mounted) return;
      final url = result.shareUrl.isNotEmpty ? result.shareUrl : null;
      setState(() { _shareUrl = url; _sharing = false; });
      if (url != null) {
        _showShareSheet(url);
      } else {
        // Fallback: share driver location via coordinates if available
        _shareLocationFallback();
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _sharing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _sharing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not generate share link: $e'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  void _shareLocationFallback() {
    final pickup = _pickupPoint;
    final text = 'I\'m on my way!\n'
        'From: ${widget.from}\nTo: ${widget.to}\n'
        'Track pickup: https://maps.google.com/?q=${pickup.latitude},${pickup.longitude}';
    final box = context.findRenderObject() as RenderBox?;
    Share.share(text,
        subject: 'My ROTEH Trip',
        sharePositionOrigin:
            box != null ? box.localToGlobal(Offset.zero) & box.size : null);
  }

  Future<void> _stopSharing() async {
    if (widget.rideId == null) return;
    try {
      await ApiService.stopSharingTrip(widget.rideId!);
      if (mounted) setState(() => _shareUrl = null);
    } catch (_) {}
  }

  void _showShareSheet(String url) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TripShareSheet(
        url:         url,
        from:        widget.from,
        to:          widget.to,
        driverName:  _driverName,
        etaMinutes:  _etaMinutes,
        onStop:      () {
          Navigator.pop(context);
          _stopSharing();
        },
      ),
    );
  }

}

// ── Stop ETA list ─────────────────────────────────────────────────────────────

class _StopEtaList extends StatelessWidget {
  final List<TripStop> wayStops;
  final String destination;
  final int nextStopIndex;
  final List<int> stopEtas; // ETA in minutes per remaining stop + destination

  const _StopEtaList({
    required this.wayStops,
    required this.destination,
    required this.nextStopIndex,
    required this.stopEtas,
  });

  @override
  Widget build(BuildContext context) {
    // Build rows: remaining stops + destination
    final rows = <_EtaRow>[];
    int etaIdx = 0;
    for (int i = nextStopIndex; i < wayStops.length; i++) {
      rows.add(_EtaRow(
        label: 'Stop ${i + 1}',
        address: wayStops[i].address,
        etaMinutes: etaIdx < stopEtas.length ? stopEtas[etaIdx] : null,
        isCurrent: i == nextStopIndex,
        color: Colors.orange,
      ));
      etaIdx++;
    }
    // Destination
    rows.add(_EtaRow(
      label: 'Destination',
      address: destination,
      etaMinutes: etaIdx < stopEtas.length ? stopEtas[etaIdx] : null,
      isCurrent: false,
      color: Colors.red,
    ));

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: rows.map((r) => Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            Icon(r.isCurrent ? Icons.navigation_rounded : Icons.circle,
                color: r.color,
                size: r.isCurrent ? 16 : 8),
            SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(r.label,
                    style: TextStyle(
                        color: r.isCurrent ? r.color : context.appTextSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
                Text(r.address,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: context.appTextPrimary, fontSize: 12)),
              ]),
            ),
            if (r.etaMinutes != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: r.isCurrent
                        ? _kGreen.withValues(alpha: 0.1)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20)),
                child: Text('${r.etaMinutes} min',
                    style: TextStyle(
                        color: r.isCurrent ? _kGreen : context.appTextSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
          ]),
        )).toList(),
      ),
    );
  }
}

class _EtaRow {
  final String label;
  final String address;
  final int?   etaMinutes;
  final bool   isCurrent;
  final Color  color;
  const _EtaRow({
    required this.label, required this.address,
    required this.etaMinutes, required this.isCurrent, required this.color,
  });
}

// ── Small widgets ─────────────────────────────────────────────────────────────

class _MapBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MapBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: context.appSurface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.15), blurRadius: 6)
          ],
        ),
        child: Icon(icon, color: context.appTextPrimary, size: 20),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String   label;
  final VoidCallback onTap;
  final bool highlight;
  final bool loading;
  final bool disabled;
  final bool danger;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlight = false,
    this.loading   = false,
    this.disabled  = false,
    this.danger    = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color activeColor = danger ? Colors.red : _kGreen;
    final Color iconColor   = disabled
        ? context.appTextSecondary.withValues(alpha: 0.4)
        : highlight || danger ? activeColor : activeColor;

    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Column(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: disabled
                ? Colors.grey.withValues(alpha: 0.08)
                : highlight
                    ? activeColor.withValues(alpha: 0.18)
                    : activeColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: highlight
                ? Border.all(color: activeColor, width: 1.5)
                : danger
                    ? Border.all(color: Colors.red.withValues(alpha: 0.4), width: 1)
                    : null,
          ),
          child: loading
              ? Padding(
                  padding: EdgeInsets.all(11),
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: activeColor))
              : Icon(icon, color: iconColor, size: 19),
        ),
        SizedBox(height: 4),
        Text(label,
            style: TextStyle(
              color: disabled
                  ? context.appTextSecondary.withValues(alpha: 0.4)
                  : highlight
                      ? activeColor
                      : danger
                          ? Colors.red
                          : context.appTextSecondary,
              fontSize: 12,
              fontWeight:
                  highlight || danger ? FontWeight.w600 : FontWeight.normal,
            )),
      ]),
    );
  }
}

// ── Trip share bottom sheet ───────────────────────────────────────────────────

class _TripShareSheet extends StatelessWidget {
  final String   url;
  final String   from;
  final String   to;
  final String   driverName;
  final int      etaMinutes;
  final VoidCallback onStop;

  const _TripShareSheet({
    required this.url,
    required this.from,
    required this.to,
    required this.driverName,
    required this.etaMinutes,
    required this.onStop,
  });

  void _copy(BuildContext ctx) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
      content: Text('Link copied to clipboard'),
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: 2),
    ));
  }

  void _shareNative(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    Share.share(
      'Track my ROTEH trip live 🚗\n'
      'Driver: $driverName · ETA: $etaMinutes min\n'
      'From: $from\nTo: $to\n\n$url',
      subject: 'Track my ride live',
      sharePositionOrigin:
          box != null ? box.localToGlobal(Offset.zero) & box.size : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: context.appCardBg,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: 20),

          // Header
          Row(children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _kGreen.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.share_location, color: _kGreen, size: 22),
            ),
            SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Share Trip', style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w700, color: context.appTextPrimary)),
              Text('Friends & family can track your ride live',
                  style: TextStyle(fontSize: 12, color: context.appTextSecondary)),
            ])),
          ]),
          SizedBox(height: 20),

          // Trip summary card
          Container(
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.appCardBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(children: [
              Row(children: [
                Icon(Icons.circle, color: _kGreen, size: 8),
                SizedBox(width: 10),
                Expanded(child: Text(from,
                    style: TextStyle(color: context.appTextPrimary, fontSize: 13),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
              Padding(
                padding: EdgeInsets.only(left: 3),
                child: Column(children: List.generate(3, (_) => Container(
                  width: 2, height: 4, margin: EdgeInsets.symmetric(vertical: 1),
                  color: Colors.grey[400],
                ))),
              ),
              Row(children: [
                Icon(Icons.location_on, color: Colors.red, size: 10),
                SizedBox(width: 10),
                Expanded(child: Text(to,
                    style: TextStyle(color: context.appTextPrimary, fontSize: 13),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
              SizedBox(height: 10),
              Row(children: [
                Icon(Icons.person_outline, color: context.appTextSecondary, size: 14),
                SizedBox(width: 6),
                Text('Driver: $driverName',
                    style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
                Spacer(),
                Icon(Icons.timer_outlined, color: context.appTextSecondary, size: 14),
                SizedBox(width: 4),
                Text('ETA $etaMinutes min',
                    style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
              ]),
            ]),
          ),
          const SizedBox(height: 16),

          // URL row
          GestureDetector(
            onTap: () => _copy(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _kGreen.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kGreen.withValues(alpha: 0.25)),
              ),
              child: Row(children: [
                const Icon(Icons.link_rounded, color: _kGreen, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text(url,
                    style: const TextStyle(
                      color: _kGreen, fontSize: 12, fontWeight: FontWeight.w500),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 8),
                const Icon(Icons.copy_rounded, color: _kGreen, size: 16),
              ]),
            ),
          ),
          const SizedBox(height: 16),

          // Action buttons
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _copy(context),
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('Copy link'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kGreen,
                  side: const BorderSide(color: _kGreen),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _shareNative(context),
                icon: const Icon(Icons.share_rounded, size: 16),
                label: const Text('Share via...'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 10),

          // Stop sharing
          TextButton(
            onPressed: onStop,
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
              minimumSize: const Size(double.infinity, 44),
            ),
            child: const Text('Stop sharing location',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ─── Cancel Reason Dialog ─────────────────────────────────────────────────────

class _CancelReasonDialog extends StatefulWidget {
  final bool hasFee;
  const _CancelReasonDialog({required this.hasFee});

  @override
  State<_CancelReasonDialog> createState() => _CancelReasonDialogState();
}

class _CancelReasonDialogState extends State<_CancelReasonDialog> {
  static const _reasons = [
    'Changed my mind',
    'Driver is taking too long',
    'Wrong pickup location',
    'Found another ride',
    'Emergency came up',
    'Other',
  ];

  String? _selected;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      titlePadding: EdgeInsets.zero,
      title: Container(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 14),
        decoration: BoxDecoration(
          color: _kGreen,
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Cancel Ride',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          SizedBox(height: 4),
          Text(
            widget.hasFee
                ? 'Driver has arrived — a 2,000 ៛ fee applies.'
                : 'Please tell us why you\'re cancelling.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ]),
      ),
      contentPadding: EdgeInsets.symmetric(vertical: 8),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: _reasons.map((r) => RadioListTile<String>(
          value: r,
          groupValue: _selected,
          onChanged: (v) => setState(() => _selected = v),
          activeColor: _kGreen,
          title: Text(r, style: TextStyle(fontSize: 14)),
          dense: true,
        )).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Keep Ride',
              style: TextStyle(color: context.appTextSecondary, fontWeight: FontWeight.w600)),
        ),
        ElevatedButton(
          onPressed: _selected == null
              ? null
              : () => Navigator.pop(context, _selected),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(
            widget.hasFee ? 'Cancel (2,000 ៛ fee)' : 'Cancel Ride',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
