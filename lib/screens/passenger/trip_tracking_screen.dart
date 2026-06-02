import 'dart:async';
import 'dart:math' show min, max, sin, cos, atan2, pi;
import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../services/websocket_service.dart';
import '../../services/notification_service.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';
import '../../services/maps_service.dart';
import 'rate_driver_screen.dart';
import '../shared/ride_chat_screen.dart';

const _kGreen      = Color(0xFF00B14F);
const _kTextMain   = Color(0xFF1A1A1A);
const _kTextSub    = Color(0xFF757575);
const _kDivider    = Color(0xFFEEEEEE);

class TripTrackingScreen extends StatefulWidget {
  final int?    rideId;
  final String  driverId;
  final String  driverName;
  final String  driverRating;
  final String  driverTrips;
  final String  vehicle;
  final String  vehicleColor;
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

  const TripTrackingScreen({
    super.key,
    this.rideId,
    this.driverId      = '',
    this.driverName    = 'Finding driver...',
    this.driverRating  = '--',
    this.driverTrips   = '--',
    this.vehicle       = '--',
    this.vehicleColor  = '',
    this.plate         = '--',
    this.from          = '--',
    this.to            = '--',
    this.fare          = '--',
    this.isScheduled   = false,
    this.pickupLatLng,
    this.destLatLng,
  });

  @override
  State<TripTrackingScreen> createState() => _TripTrackingScreenState();
}

class _TripTrackingScreenState extends State<TripTrackingScreen>
    with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  StreamSubscription<TripUpdate>? _trackingSub;
  StreamSubscription<LatLng>?    _firestoreSub;
  TripUpdate? _lastUpdate;

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

  // Mutable driver info — updated when driver is assigned after booking
  late String _driverName;
  late String _driverRating;
  late String _driverTrips;
  late String _vehicle;
  late String _vehicleColor;
  late String _plate;
  String _currentDriverId = '';
  Timer? _ridePollTimer;

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

    _initMarkers();
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
      Marker(
        markerId: const MarkerId('destination'),
        position: _destPoint,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: widget.to),
      ),
    ]);
    // Static full-route line (gray dashed): pickup → destination
    // This stays visible the entire trip as context.
    _polylines.add(Polyline(
      polylineId: const PolylineId('full_route'),
      points:     [_pickupPoint, _destPoint],
      color:      const Color(0x55888888),
      width:      4,
      patterns:   [PatternItem.dash(16), PatternItem.gap(8)],
    ));
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

    final heading = (_prevDriverPos != null && _prevDriverPos != pos)
        ? _bearing(_prevDriverPos!, pos)
        : 0.0;

    setState(() {
      _markers.removeWhere((m) => m.markerId.value == 'driver');
      _markers.add(Marker(
        markerId: const MarkerId('driver'),
        position: pos,
        icon:     BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: InfoWindow(title: _driverName, snippet: _vehicle),
        rotation: heading,
        anchor:   const Offset(0.5, 0.5),
        flat:     true,   // rotates with the map rather than always pointing up
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

  void _onDriverPosition(LatLng pos) {
    if (!_inCambodia(pos)) return; // ignore stale/invalid Firestore values
    // Animate from wherever the marker currently is
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
    // Before pickup: driver → pickup.  During trip: driver → destination.
    final destination =
        _driverAssigned && _lastUpdate?.status == TripStatus.inProgress
            ? _destPoint
            : _pickupPoint;

    final result = await MapsService.getRoute(
      origin:      driverPos,
      destination: destination,
    );
    if (!mounted || result == null) return;
    setState(() {
      _etaMinutes = result.etaMinutes;
      _distanceKm = result.distanceKm;
      // Replace only the live-route polyline; keep the full static route
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

  // ── Cancel ride ────────────────────────────────────────────────────────────

  Future<void> _cancelRide() async {
    if (widget.rideId == null || _cancelling) return;
    setState(() => _cancelling = true);
    try {
      await ApiService.cancelRide(widget.rideId!);
      if (!mounted) return;
      Navigator.pop(context);
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

  // ── Tracking ───────────────────────────────────────────────────────────────

  void _startTracking() {
    _trackingSub =
        WebSocketService.instance.startTracking().listen((update) async {
      if (!mounted) return;
      final prevStatus = _lastUpdate?.status;
      setState(() => _lastUpdate = update);

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
          .listen(_onDriverPosition);
    }
  }

  @override
  void dispose() {
    _ridePollTimer?.cancel();
    _trackingSub?.cancel();
    _firestoreSub?.cancel();
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
      if (ride.driverId == null) return;
      final newId = ride.driverId.toString();
      if (newId == _currentDriverId) return;
      setState(() {
        _currentDriverId = newId;
        _driverName   = ride.driver?.name ?? 'Driver #${ride.driverId}';
        _driverRating = '--';
        _driverTrips  = '--';
        _vehicle      = ride.vehicle != null
            ? '${ride.vehicle!.make} ${ride.vehicle!.model} ${ride.vehicle!.year}'
            : '--';
        _vehicleColor = '';
        _plate        = ride.vehicle?.licensePlate ?? '--';
      });
      _firestoreSub?.cancel();
      _firestoreSub = LocationService.instance
          .listenDriver(_currentDriverId)
          .listen(_onDriverPosition);
      _ridePollTimer?.cancel();
    } catch (_) {}
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  // Status must not advance past "searching" until a driver is actually assigned.
  bool get _driverAssigned => _currentDriverId.isNotEmpty;

  bool get _isArrived =>
      _driverAssigned && _lastUpdate?.status == TripStatus.arrived;

  String get _statusTitle {
    if (!_driverAssigned) return 'Finding your driver...';
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
      backgroundColor: Colors.white,
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Row(children: [
                        Container(
                            width: 12, height: 12,
                            decoration: const BoxDecoration(
                                color: _kGreen, shape: BoxShape.circle)),
                        const SizedBox(width: 12),
                        const Expanded(
                            child: Text('My location',
                                style: TextStyle(
                                    color: _kTextMain,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500))),
                        Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                              color: Colors.grey[100], shape: BoxShape.circle),
                          child: const Icon(Icons.add, color: _kTextSub, size: 18),
                        ),
                      ]),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 21, top: 4, bottom: 4),
                      child: Row(children: [
                        Container(width: 2, height: 14, color: Colors.grey[300]),
                      ]),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Row(children: [
                        const Icon(Icons.location_on, color: Colors.red, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(widget.to,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: _kTextMain,
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15), blurRadius: 8)
                ],
              ),
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  children: [
                    TextSpan(
                        text: '$eta min',
                        style: const TextStyle(color: _kGreen)),
                    TextSpan(
                        text: '\naway',
                        style: TextStyle(
                            color: _kTextSub,
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
              _MapBtn(icon: Icons.my_location, onTap: () {}),
              const SizedBox(height: 8),
              _MapBtn(icon: Icons.layers_outlined, onTap: () {}),
            ]),
          ),

          // ── Bottom sheet ──────────────────────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black12, blurRadius: 20, offset: Offset(0, -4))
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle
                      Center(
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          width: 40, height: 4,
                          decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(2)),
                        ),
                      ),

                      // Status
                      Text(_statusTitle,
                          style: const TextStyle(
                              color: _kTextMain,
                              fontSize: 17,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      if (_driverAssigned)
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                                fontSize: 13, color: _kTextSub),
                            children: [
                              const TextSpan(text: 'Arriving in '),
                              TextSpan(
                                  text: '$eta min',
                                  style: const TextStyle(
                                      color: _kGreen,
                                      fontWeight: FontWeight.w600)),
                              TextSpan(text: ' ($dist km)'),
                            ],
                          ),
                        )
                      else
                        const Text('Looking for a nearby driver…',
                            style: TextStyle(fontSize: 13, color: _kTextSub)),
                      const SizedBox(height: 18),

                      // Driver + Car
                      Row(children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.grey[200],
                          child: Text(
                            _driverName.isNotEmpty
                                ? _driverName[0].toUpperCase()
                                : 'D',
                            style: const TextStyle(
                                color: _kTextMain,
                                fontSize: 22,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_driverName,
                                  style: const TextStyle(
                                      color: _kTextMain,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15)),
                              const SizedBox(height: 4),
                              Row(children: [
                                const Icon(Icons.star,
                                    color: Color(0xFFFFA000), size: 15),
                                const SizedBox(width: 3),
                                Text(_driverRating,
                                    style: const TextStyle(
                                        color: _kTextSub, fontSize: 13)),
                                if (_driverTrips != '--') ...[
                                  const SizedBox(width: 8),
                                  Text('$_driverTrips trips',
                                      style: const TextStyle(
                                          color: _kTextSub, fontSize: 13)),
                                ],
                              ]),
                            ],
                          ),
                        ),
                        // Car info
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Icon(Icons.directions_car,
                                size: 42, color: _kTextSub),
                            Text(_plate,
                                style: const TextStyle(
                                    color: _kTextMain,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13)),
                            Text(
                              _vehicleColor.isNotEmpty
                                  ? '$_vehicle · $_vehicleColor'
                                  : _vehicle,
                              style: const TextStyle(
                                  color: _kTextSub, fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ]),
                      const SizedBox(height: 18),
                      const Divider(color: _kDivider, height: 1),
                      const SizedBox(height: 14),

                      // Action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _ActionBtn(icon: Icons.call_outlined, label: 'Call', onTap: () {}),
                          _ActionBtn(
                            icon: Icons.chat_bubble_outline,
                            label: 'Chat',
                            onTap: _openRideChat,
                          ),
                          _ActionBtn(icon: Icons.share_outlined, label: 'Share', onTap: () {}),
                          _ActionBtn(icon: Icons.more_horiz, label: 'More', onTap: () {
                            _showMoreSheet(context);
                          }),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Divider(color: _kDivider, height: 1),

                      // Promo code
                      InkWell(
                        onTap: () {},
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(children: [
                            const Icon(Icons.local_offer_outlined,
                                color: _kGreen, size: 20),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Save on future rides',
                                      style: TextStyle(
                                          color: _kTextMain,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500)),
                                  Text('Add a promo code',
                                      style: TextStyle(
                                          color: _kGreen, fontSize: 12)),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: _kTextSub),
                          ]),
                        ),
                      ),
                      const Divider(color: _kDivider, height: 1),
                      const SizedBox(height: 16),

                      // Buttons row
                      Row(children: [
                        GestureDetector(
                          onTap: _cancelling ? null : _cancelRide,
                          child: Container(
                            width: 52, height: 52,
                            decoration: BoxDecoration(
                              color: _cancelling
                                  ? Colors.grey[300]
                                  : _kGreen,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: _cancelling
                                ? const Padding(
                                    padding: EdgeInsets.all(14),
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.keyboard_double_arrow_right,
                                    color: Colors.white, size: 26),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              if (_isArrived) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => RateDriverScreen(
                                            rideId:     widget.rideId,
                                            driverName: _driverName,
                                            fare:       widget.fare,
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
                              backgroundColor: _kGreen,
                              padding: const EdgeInsets.symmetric(vertical: 16),
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

  void _showMoreSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),
            ListTile(
              leading: const Icon(Icons.cancel_outlined, color: Colors.red),
              title: const Text('Cancel Ride',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _cancelRide();
              },
            ),
            ListTile(
              leading: const Icon(Icons.report_outlined, color: _kTextSub),
              title: const Text('Report an issue',
                  style: TextStyle(color: _kTextMain)),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
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
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.15), blurRadius: 6)
          ],
        ),
        child: Icon(icon, color: _kTextMain, size: 20),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionBtn(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        Container(
          width: 50, height: 50,
          decoration: BoxDecoration(
            color: _kGreen.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: _kGreen, size: 22),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(color: _kTextSub, fontSize: 12)),
      ]),
    );
  }
}
