import 'dart:async';
import 'dart:math' show min, max, sin, cos, atan2, pi, sqrt;
import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../theme/app_theme.dart';
import '../../services/notification_service.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';
import '../../services/maps_service.dart';
import '../../services/marker_icon_service.dart';
import '../../models/driver_marker_model.dart';
import '../../models/ride_model.dart';
import '../shared/ride_chat_screen.dart';
import 'driver_trip_summary_screen.dart';

enum _TripPhase { headingToPickup, waitingAtPickup, inProgress, completed }

class DriverActiveTripScreen extends StatefulWidget {
  final RideModel? ride;
  final String passengerName;
  final String passengerRating;
  final String pickup;
  final String destination;
  final String fare;

  const DriverActiveTripScreen({
    super.key,
    this.ride,
    this.passengerName   = 'Passenger',
    this.passengerRating = '5.0',
    this.pickup          = '--',
    this.destination     = '--',
    this.fare            = '--',
  });

  @override
  State<DriverActiveTripScreen> createState() => _DriverActiveTripScreenState();
}

class _DriverActiveTripScreenState extends State<DriverActiveTripScreen>
    with TickerProviderStateMixin {

  GoogleMapController? _mapController;
  _TripPhase _phase     = _TripPhase.headingToPickup;
  bool       _completing = false;

  // Live route data
  int    _etaMinutes    = 0;
  double _distanceKm    = 0.0;
  DateTime? _lastRouteFetch;

  // Driver position — plain fields; updated in GPS callback without setState
  LatLng? _driverLatLng;
  double  _driverHeading = 0.0;

  // Smooth lerp animation (same pattern as passenger tracking screen)
  late AnimationController _markerAnimCtrl;
  LatLng? _prevDriverPos;
  LatLng? _targetDriverPos;

  // Custom vehicle icon — loaded once per vehicle type
  BitmapDescriptor? _driverIcon;
  String            _vehicleType = 'motorbike';

  final Set<Marker>   _markers   = {};
  final Set<Polyline> _polylines = {};

  late AnimationController _pulseCtrl;
  late Animation<double>   _pulseAnim;

  // ── Derived from ride (real coords) or fallback to PNH centre ───────────────

  LatLng get _pickupLatLng =>
      (widget.ride?.pickupLat != null && widget.ride?.pickupLng != null)
          ? LatLng(widget.ride!.pickupLat!, widget.ride!.pickupLng!)
          : const LatLng(11.5650, 104.9175);

  LatLng get _destLatLng =>
      (widget.ride?.dropoffLat != null && widget.ride?.dropoffLng != null)
          ? LatLng(widget.ride!.dropoffLat!, widget.ride!.dropoffLng!)
          : const LatLng(11.5616, 104.9282);

  String get _passengerName => widget.ride?.passenger?.name
      ?? (widget.ride != null ? 'Passenger #${widget.ride!.passengerId}' : widget.passengerName);
  String get _pickupAddr    => widget.ride?.pickupAddress  ?? widget.pickup;
  String get _destAddr      => widget.ride?.dropoffAddress ?? widget.destination;
  String get _fare          => widget.ride != null
      ? AppTheme.khr(widget.ride!.fareKhr)
      : widget.fare;

  String get _driverId => widget.ride?.driverId?.toString() ?? 'unknown';

  // ── Lifecycle ──────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(_pulseCtrl);

    // Smooth marker movement between GPS pings
    _markerAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..addListener(_onMarkerAnimTick);

    // Load vehicle icon from the ride's vehicle type (falls back to motorbike)
    _vehicleType = DriverMarkerModel.normalise(
        widget.ride?.vehicle?.type ?? 'motorbike');
    MarkerIconService.forType(_vehicleType).then((icon) {
      if (mounted) setState(() => _driverIcon = icon);
    });

    _initMap();
    _startTracking();
  }

  @override
  void dispose() {
    LocationService.instance.stopTracking(_driverId);
    _pulseCtrl.dispose();
    _markerAnimCtrl.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  // ── Map initialisation ────────────────────────────────────────────────────────

  void _initMap() {
    final pickup = _pickupLatLng;
    final dest   = _destLatLng;

    _markers.addAll([
      Marker(
        markerId: const MarkerId('pickup'),
        position: pickup,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(title: _pickupAddr),
      ),
      Marker(
        markerId: const MarkerId('dest'),
        position: dest,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: _destAddr),
      ),
    ]);

    // Static full route — dashed gray context line (pickup → destination)
    _polylines.add(Polyline(
      polylineId: const PolylineId('full_route'),
      points:     [pickup, dest],
      color:      const Color(0x55888888),
      width:      4,
      patterns:   [PatternItem.dash(16), PatternItem.gap(8)],
    ));
  }

  // ── GPS tracking ──────────────────────────────────────────────────────────────

  Future<void> _startTracking() async {
    final granted = await LocationService.instance.requestPermission();
    if (!granted) return;
    LocationService.instance.startTracking(
      driverId:    _driverId,
      onPosition:  _onDriverPosition,
      vehicleType: widget.ride?.vehicle?.type ?? _vehicleType,
    );
  }

  static bool _inCambodia(double lat, double lng) =>
      lat >= 10.4 && lat <= 14.7 && lng >= 102.3 && lng <= 107.6;

  // Haversine distance in metres between two LatLng points
  static double _distanceMetres(LatLng a, LatLng b) {
    const r = 6371000.0;
    final lat1 = a.latitude  * pi / 180;
    final lat2 = b.latitude  * pi / 180;
    final dLat = (b.latitude  - a.latitude)  * pi / 180;
    final dLng = (b.longitude - a.longitude) * pi / 180;
    final x = sin(dLat / 2) * sin(dLat / 2) +
              cos(lat1) * cos(lat2) * sin(dLng / 2) * sin(dLng / 2);
    return r * 2 * atan2(sqrt(x), sqrt(1 - x));
  }

  static double _bearing(LatLng from, LatLng to) {
    final lat1 = from.latitude  * pi / 180;
    final lat2 = to.latitude    * pi / 180;
    final dLng = (to.longitude - from.longitude) * pi / 180;
    final y    = sin(dLng) * cos(lat2);
    final x    = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLng);
    return (atan2(y, x) * 180 / pi + 360) % 360;
  }

  // ── Smooth lerp animation ─────────────────────────────────────────────────

  void _onMarkerAnimTick() {
    final prev   = _prevDriverPos;
    final target = _targetDriverPos;
    if (prev == null || target == null || !mounted) return;
    final t   = _markerAnimCtrl.value;
    final lat = lerpDouble(prev.latitude,  target.latitude,  t)!;
    final lng = lerpDouble(prev.longitude, target.longitude, t)!;
    _updateDriverMarker(LatLng(lat, lng));
  }

  void _updateDriverMarker(LatLng pos) {
    if (!mounted) return;
    setState(() {
      _markers.removeWhere((m) => m.markerId.value == 'driver');
      _markers.add(Marker(
        markerId:   const MarkerId('driver'),
        position:   pos,
        icon:       _driverIcon ?? BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueOrange),
        infoWindow: const InfoWindow(title: 'You'),
        rotation:   _driverHeading,
        anchor:     const Offset(0.5, 0.5),
        flat:       true, // marker rotates with map compass bearing
      ));
    });
  }

  // ── GPS callback ──────────────────────────────────────────────────────────

  void _onDriverPosition(Position position) {
    if (!mounted) return;
    if (!_inCambodia(position.latitude, position.longitude)) return;

    final pos     = LatLng(position.latitude, position.longitude);
    final prevPos = _driverLatLng;

    _driverHeading = (prevPos != null && prevPos != pos)
        ? _bearing(prevPos, pos)
        : position.heading;

    // Animate smoothly from previous to current GPS ping
    _prevDriverPos   = _targetDriverPos ?? pos;
    _targetDriverPos = pos;
    _driverLatLng    = pos;
    _markerAnimCtrl
      ..reset()
      ..forward();

    // Auto-detect arrival at pickup (within 80 m → advance phase automatically)
    if (_phase == _TripPhase.headingToPickup) {
      final distToPickup = _distanceMetres(pos, _pickupLatLng);
      if (distToPickup <= 80) {
        _autoArriveAtPickup();
      }
    }

    // Camera: show driver + next waypoint
    final waypoint = _phase == _TripPhase.inProgress ? _destLatLng : _pickupLatLng;
    _fitCamera(pos, waypoint);

    // Also push location to backend API during trip (throttled to once per 10 s)
    _pushLocationToBackend(position);

    // Throttle Routes API calls to once per 15 s
    final now = DateTime.now();
    if (_lastRouteFetch == null ||
        now.difference(_lastRouteFetch!).inSeconds >= 15) {
      _lastRouteFetch = now;
      _fetchLiveRoute(pos);
    }
  }

  void _autoArriveAtPickup() {
    setState(() => _phase = _TripPhase.waitingAtPickup);
    NotificationService.instance.showTripUpdate(
      title: 'Arrived at Pickup',
      body:  'You have arrived at $_pickupAddr',
    );
  }

  // ── Routes API — live route ────────────────────────────────────────────────────

  Future<void> _fetchLiveRoute(LatLng driverPos) async {
    final destination =
        _phase == _TripPhase.inProgress ? _destLatLng : _pickupLatLng;

    final result = await MapsService.getRoute(
      origin:      driverPos,
      destination: destination,
    );
    if (!mounted || result == null) return;

    setState(() {
      _etaMinutes = result.etaMinutes;
      _distanceKm = result.distanceKm;
      _polylines
        ..removeWhere((p) => p.polylineId.value == 'live_route')
        ..add(Polyline(
          polylineId: const PolylineId('live_route'),
          points:     result.points,
          color:      AppTheme.accentOrange,
          width:      5,
          startCap:   Cap.roundCap,
          endCap:     Cap.roundCap,
          jointType:  JointType.round,
        ));
    });
  }

  // ── Backend location update (Smart Dispatch + passenger tracking) ─────────────

  DateTime? _lastBackendPush;

  void _pushLocationToBackend(Position pos) {
    if (widget.ride == null) return;
    final now = DateTime.now();
    if (_lastBackendPush != null &&
        now.difference(_lastBackendPush!).inSeconds < 10) { return; }
    _lastBackendPush = now;
    ApiService.updateDriverLocation(
      widget.ride!.id,
      latitude:  pos.latitude,
      longitude: pos.longitude,
      speed:     pos.speed,
      heading:   pos.heading,
      status:    _phase == _TripPhase.inProgress ? 'in_progress' : 'picking_up',
    ).catchError((_) {});
  }

  // ── Camera ─────────────────────────────────────────────────────────────────────

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

  // ── Phase management ──────────────────────────────────────────────────────────

  String get _phaseLabel {
    switch (_phase) {
      case _TripPhase.headingToPickup: return 'Heading to Pickup';
      case _TripPhase.waitingAtPickup: return 'Waiting at Pickup';
      case _TripPhase.inProgress:      return 'Trip in Progress';
      case _TripPhase.completed:       return 'Trip Completed';
    }
  }

  Color get _phaseColor {
    switch (_phase) {
      case _TripPhase.headingToPickup: return AppTheme.warning;
      case _TripPhase.waitingAtPickup: return AppTheme.accentOrange;
      case _TripPhase.inProgress:      return AppTheme.accent;
      case _TripPhase.completed:       return AppTheme.success;
    }
  }

  String get _ctaLabel {
    switch (_phase) {
      case _TripPhase.headingToPickup: return '✅  Arrived at Pickup';
      case _TripPhase.waitingAtPickup: return '🚗  Passenger On Board — Start Trip';
      case _TripPhase.inProgress:      return '🏁  Complete Trip';
      case _TripPhase.completed:       return '🏠  Back to Dashboard';
    }
  }

  Future<void> _advancePhase() async {
    if (_phase == _TripPhase.completed) {
      Navigator.pop(context);
      return;
    }

    if (_phase == _TripPhase.inProgress) {
      setState(() => _completing = true);
      RideModel? completedRide;
      if (widget.ride != null) {
        try {
          completedRide = await ApiService.completeRide(widget.ride!.id);
        } catch (_) {
          completedRide = widget.ride;
        }
      }
      if (!mounted) return;
      setState(() { _completing = false; _phase = _TripPhase.completed; });

      await NotificationService.instance.showTripUpdate(
        title: 'Trip Completed',
        body:  'You earned ${AppTheme.khr((completedRide ?? widget.ride)?.fareKhr ?? 0)}',
      );
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DriverTripSummaryScreen(
            ride: completedRide ?? widget.ride ?? _fakeSummaryRide(),
          ),
        ),
      );
      if (!mounted) return;
      Navigator.pop(context);
      return;
    }

    // Call backend API before advancing phase
    if (_phase == _TripPhase.headingToPickup && widget.ride != null) {
      // Mark arrived at pickup → POST /rides/{id}/arrive
      try {
        await ApiService.arriveAtPickup(widget.ride!.id);
      } catch (_) {}
    } else if (_phase == _TripPhase.waitingAtPickup && widget.ride != null) {
      // Passenger on board → POST /rides/{id}/start
      try {
        await ApiService.startTrip(widget.ride!.id);
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() => _phase = _TripPhase.values[_phase.index + 1]);

    // When trip starts (inProgress), re-fetch route to destination
    if (_phase == _TripPhase.inProgress && _driverLatLng != null) {
      _lastRouteFetch = null;
      _fetchLiveRoute(_driverLatLng!);
    }
  }

  RideModel _fakeSummaryRide() => RideModel(
    id:            0,
    passengerId:   0,
    pickupAddress: _pickupAddr,
    dropoffAddress: _destAddr,
    status:        'completed',
    fare:          '0',
    serviceType:   'standard',
    paymentMethod: 'cash',
    createdAt:     DateTime.now().toIso8601String(),
    updatedAt:     DateTime.now().toIso8601String(),
  );

  // ── Dialogs / actions ─────────────────────────────────────────────────────────

  void _showSOS() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: AppTheme.danger, size: 28),
          SizedBox(width: 10),
          Text('Emergency SOS',
              style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.w800)),
        ]),
        content: const Text(
          'This will alert emergency services and notify AutoRide operations team with your location.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel',
                  style: TextStyle(color: AppTheme.textSecondary))),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); _sendSOS(); },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Send SOS'),
          ),
        ],
      ),
    );
  }

  void _sendSOS() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('🚨 SOS Sent! Help is on the way.'),
      backgroundColor: AppTheme.danger,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _openRideChat() async {
    if (widget.ride == null) return;
    final saved = await ApiService.getSavedUser();
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => RideChatScreen(
        rideId:      widget.ride!.id.toString(),
        driverId:    widget.ride!.driverId ?? saved?.id ?? 0,
        passengerId: widget.ride!.passengerId,
        myId:        saved?.id   ?? 0,
        myName:      saved?.name ?? 'Driver',
        otherName:   widget.ride!.passenger?.name
                         ?? 'Passenger #${widget.ride!.passengerId}',
        isDriver:    true,
      ),
    ));
  }

  void _callPassenger() {
    final phone = widget.ride?.passenger?.phone ?? '+855 --';
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: AppTheme.accent.withValues(alpha: 0.2),
            child: Text(_passengerName[0],
                style: const TextStyle(
                    color: AppTheme.accent,
                    fontSize: 28,
                    fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 12),
          Text(_passengerName,
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          Text(phone, style: const TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.call),
              label: const Text('Call Now',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ]),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isCompleted = _phase == _TripPhase.completed;
    final pickup  = _pickupLatLng;
    final dest    = _destLatLng;
    final midLat  = (pickup.latitude  + dest.latitude)  / 2;
    final midLng  = (pickup.longitude + dest.longitude) / 2;

    return Scaffold(
      body: Stack(children: [

        // ── Full-screen map ───────────────────────────────────────────────────
        GoogleMap(
          onMapCreated: (c) {
            _mapController = c;
            // Fit camera to show full pickup → destination route
            c.animateCamera(CameraUpdate.newLatLngBounds(
              LatLngBounds(
                southwest: LatLng(
                  min(pickup.latitude,  dest.latitude)  - 0.01,
                  min(pickup.longitude, dest.longitude) - 0.01,
                ),
                northeast: LatLng(
                  max(pickup.latitude,  dest.latitude)  + 0.01,
                  max(pickup.longitude, dest.longitude) + 0.01,
                ),
              ),
              80,
            ));
          },
          initialCameraPosition: CameraPosition(
              target: LatLng(midLat, midLng), zoom: 13),
          style: _kDarkMapStyle,
          markers:   _markers,
          polylines: _polylines,
          myLocationEnabled: false,
          zoomControlsEnabled: false,
        ),

        // ── Top bar ───────────────────────────────────────────────────────────
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.9),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_back,
                      color: AppTheme.textPrimary, size: 20),
                ),
              ),
              const Spacer(),
              // Pulsing phase pill
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, __) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _phaseColor
                        .withValues(alpha: 0.1 + 0.1 * _pulseAnim.value),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: _phaseColor.withValues(alpha: 0.5)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                            color: _phaseColor, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(_phaseLabel,
                        style: TextStyle(
                            color: _phaseColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 12)),
                  ]),
                ),
              ),
              const Spacer(),
              // SOS
              GestureDetector(
                onTap: _showSOS,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                      color: AppTheme.danger,
                      borderRadius: BorderRadius.circular(20)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text('SOS',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 12)),
                  ]),
                ),
              ),
            ]),
          ),
        ),

        // ── ETA badge (only while en-route) ───────────────────────────────────
        if (_etaMinutes > 0 &&
            (_phase == _TripPhase.headingToPickup ||
             _phase == _TripPhase.inProgress))
          Positioned(
            left: 16,
            bottom: 280,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 8)
                ],
              ),
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700),
                  children: [
                    TextSpan(
                        text: '$_etaMinutes min',
                        style: const TextStyle(color: AppTheme.accentOrange)),
                    TextSpan(
                        text: '\n${_distanceKm.toStringAsFixed(1)} km',
                        style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w400)),
                  ],
                ),
              ),
            ),
          ),

        // ── Bottom sheet ──────────────────────────────────────────────────────
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 20)
              ],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Handle
              Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 14),

              if (!isCompleted) ...[
                // Passenger info row
                Row(children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppTheme.accent.withValues(alpha: 0.2),
                    child: Text(_passengerName[0],
                        style: const TextStyle(
                            color: AppTheme.accent,
                            fontWeight: FontWeight.w800,
                            fontSize: 16)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_passengerName,
                            style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w700)),
                        Row(children: [
                          const Icon(Icons.star,
                              color: AppTheme.gold, size: 13),
                          const SizedBox(width: 3),
                          Text(widget.passengerRating,
                              style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12)),
                        ]),
                      ],
                    ),
                  ),
                  Text(_fare,
                      style: const TextStyle(
                          color: AppTheme.accent,
                          fontSize: 20,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(width: 12),
                  _ActionBtn(
                      icon: Icons.call_outlined,
                      color: AppTheme.success,
                      onTap: _callPassenger),
                  const SizedBox(width: 8),
                  _ActionBtn(
                      icon: Icons.chat_bubble_outline,
                      color: AppTheme.accent,
                      onTap: _openRideChat),
                ]),
                const SizedBox(height: 12),

                // Route card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(12)),
                  child: Column(children: [
                    Row(children: [
                      const Icon(Icons.circle,
                          color: AppTheme.success, size: 10),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(_pickupAddr,
                              style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600))),
                    ]),
                    const SizedBox(height: 4),
                    Row(children: [
                      Container(
                          width: 1,
                          height: 16,
                          color: AppTheme.textSecondary,
                          margin: const EdgeInsets.only(left: 4)),
                    ]),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.location_on,
                          color: AppTheme.accentOrange, size: 12),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(_destAddr,
                              style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 13))),
                    ]),
                  ]),
                ),
                const SizedBox(height: 14),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: AppTheme.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16)),
                  child: Column(children: [
                    const Icon(Icons.check_circle,
                        color: AppTheme.success, size: 48),
                    const SizedBox(height: 8),
                    const Text('Trip Completed!',
                        style: TextStyle(
                            color: AppTheme.success,
                            fontWeight: FontWeight.w800,
                            fontSize: 18)),
                    Text('You earned $_fare',
                        style: const TextStyle(
                            color: AppTheme.textSecondary)),
                  ]),
                ),
                const SizedBox(height: 14),
              ],

              // CTA button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _completing ? null : _advancePhase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isCompleted ? AppTheme.success : _phaseColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _completing
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : Text(_ctaLabel,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 14)),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final IconData     icon;
  final Color        color;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 18),
        ),
      );
}

const String _kDarkMapStyle =
    '[{"elementType":"geometry","stylers":[{"color":"#1a1a2e"}]},'
    '{"elementType":"labels.text.fill","stylers":[{"color":"#b0bec5"}]},'
    '{"elementType":"labels.text.stroke","stylers":[{"color":"#1a1a2e"}]},'
    '{"featureType":"road","elementType":"geometry","stylers":[{"color":"#16213e"}]},'
    '{"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#0f3460"}]},'
    '{"featureType":"water","elementType":"geometry","stylers":[{"color":"#0f3460"}]},'
    '{"featureType":"poi","elementType":"geometry","stylers":[{"color":"#16213e"}]},'
    '{"featureType":"administrative","elementType":"geometry.stroke","stylers":[{"color":"#0f3460"}]}]';
