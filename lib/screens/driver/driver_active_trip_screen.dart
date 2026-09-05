import 'package:autoride_superapp/l10n/app_localizations.dart';
import 'dart:async';
import 'dart:math' show min, max, sin, cos, atan2, pi, sqrt;
import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_log.dart';
import '../../services/notification_service.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';
import '../../services/maps_service.dart';
import '../../services/locale_service.dart';
import '../../services/marker_icon_service.dart';
import '../../models/driver_marker_model.dart';
import '../../models/ride_model.dart';
import '../shared/ride_chat_screen.dart';
import 'driver_trip_summary_screen.dart';

enum _TripPhase { headingToPickup, waitingAtPickup, inProgress, completed }

// Restrict the trip map to Cambodia only.
const _kCambodiaSW = LatLng(10.4, 102.3);
const _kCambodiaNE = LatLng(14.7, 107.6);
final _kCambodiaBounds = LatLngBounds(southwest: _kCambodiaSW, northeast: _kCambodiaNE);

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
    with TickerProviderStateMixin, WidgetsBindingObserver {

  GoogleMapController? _mapController;
  _TripPhase _phase     = _TripPhase.headingToPickup;
  bool       _completing = false;
  bool       _locationPermissionDenied = false;

  // Live route data
  int    _etaMinutes    = 0;
  double _distanceKm    = 0.0;
  DateTime? _lastRouteFetch;

  // Turn-by-turn navigation banner (Grab-style)
  List<RouteStep> _navSteps = [];
  int    _currentStepIndex = 0;
  double _speedKmh = 0.0;
  bool   _navBannerDismissed = false;

  // Client-side trip distance/duration fallback when API doesn't return them
  double?   _tripDistanceKm;
  DateTime? _tripStartTime;

  // Driver position — plain field; updated in GPS callback without setState
  LatLng? _driverLatLng;

  // Smooth lerp animation (same pattern as passenger tracking screen)
  late AnimationController _markerAnimCtrl;
  LatLng? _prevDriverPos;
  LatLng? _targetDriverPos;

  // Custom vehicle icon — loaded once per vehicle type
  BitmapDescriptor? _driverIcon;
  String            _vehicleType = 'motorbike';

  final Set<Marker>   _markers   = {};
  final Set<Polyline> _polylines = {};

  // Intermediate stops (multi-stop rides) — fetched from the backend since
  // RideModel itself doesn't carry them.
  List<RideStopModel> _wayStops     = [];
  int                 _nextStopIndex = 0;

  late AnimationController _pulseCtrl;
  late Animation<double>   _pulseAnim;

  // ── Derived from ride (real coords) or fallback to PNH centre ───────────────

  LatLng get _pickupLatLng =>
      (widget.ride?.pickupLat != null && widget.ride?.pickupLng != null)
          ? LatLng(widget.ride!.pickupLat!, widget.ride!.pickupLng!)
          : const LatLng(11.5650, 104.9175);

  // "Book Without Destination" — no dropoff was picked at booking time, so
  // there's nothing to route to until the driver enters a fare on completion.
  bool get _isMetered => widget.ride?.noDestination ?? false;

  LatLng? get _destLatLng {
    if (widget.ride?.dropoffLat != null && widget.ride?.dropoffLng != null) {
      return LatLng(widget.ride!.dropoffLat!, widget.ride!.dropoffLng!);
    }
    return _isMetered ? null : const LatLng(11.5616, 104.9282);
  }

  // Next leg to route/fit-camera to: pickup while en-route, then each
  // unarrived stop in order, then the final destination once all stops
  // are done.
  LatLng? get _nextWaypoint {
    if (_phase != _TripPhase.inProgress) return _pickupLatLng;
    if (_nextStopIndex < _wayStops.length) {
      return LatLng(_wayStops[_nextStopIndex].lat, _wayStops[_nextStopIndex].lng);
    }
    return _destLatLng;
  }

  String get _passengerName => widget.ride?.passenger?.name
      ?? (widget.ride != null
          ? '${AppLocalizations.of(context).passengerNumberPrefix}${widget.ride!.passengerId}'
          : widget.passengerName);
  String get _pickupAddr    => widget.ride?.pickupAddress  ?? widget.pickup;
  String get _destAddr      => (widget.ride?.dropoffAddress.isNotEmpty ?? false)
      ? widget.ride!.dropoffAddress
      : (_isMetered
          ? AppLocalizations.of(context).noDestinationAskPassenger
          : widget.destination);
  String get _fare          => widget.ride != null
      ? AppTheme.khr(widget.ride!.fareKhr)
      : widget.fare;

  // Resolved once in initState via _resolveDriverId(). widget.ride is the
  // pre-acceptance payload handed down from the incoming-request card (see
  // driver_home.dart's _RideRequestCard._accept — it deliberately keeps
  // using the pre-accept ride object for its pickup/dropoff coords, since
  // the accept response omits them), so widget.ride.driverId is still
  // null/stale at this point. Publishing live GPS under that null/'unknown'
  // id writes to a Firestore doc nobody is listening to, which is why the
  // passenger's map stayed on "Locating your driver…" forever with no
  // error anywhere — the writes were succeeding, just to the wrong doc.
  String _driverId = 'unknown';

  Future<void> _resolveDriverId() async {
    try {
      final saved = await ApiService.getSavedUser();
      if (saved != null) {
        _driverId = saved.id.toString();
        return;
      }
    } catch (_) {}
    _driverId = widget.ride?.driverId?.toString() ?? 'unknown';
  }

  String get _serviceLabel {
    final l = AppLocalizations.of(context);
    switch (widget.ride?.serviceType) {
      case 'motorcycle': return l.bike4;
      case 'tuk_tuk':     return l.tukTuk5;
      default:            return l.carShort;
    }
  }

  String get _paymentLabel {
    switch (widget.ride?.paymentMethod) {
      case 'aba':    return 'ABA Pay'; // brand name — not translated
      case 'wing':   return 'Wing';
      case 'wallet': return 'ROTEH Pay';
      default:       return AppLocalizations.of(context).cash;
    }
  }

  String get _distanceLabel => _distanceKm < 1
      ? '${(_distanceKm * 1000).round()} m'
      : '${_distanceKm.toStringAsFixed(1)} km';

  // ── Lifecycle ──────────────────────────────────────────────────────────────────

  String? _prevMapsLanguage;

  @override
  void initState() {
    super.initState();
    // Force the native Maps SDK (road/place labels) to Khmer for this trip
    // screen, regardless of the app's current UI language — restored on
    // dispose so the rest of the app keeps the user's chosen language.
    _prevMapsLanguage = MapsService.language;
    MapsService.language = 'km';
    LocaleService.setLocale('km');

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
    _fetchFullRoute();
    _resolveDriverId().then((_) => _startTracking());
    _loadWayStops();
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> _loadWayStops({int attempt = 0}) async {
    if (widget.ride == null) return;
    List<RideStopModel> stops = const [];
    try {
      stops = await ApiService.getRideStops(widget.ride!.id);
    } catch (e, s) {
      // Most rides have no stops — a 404/empty response is expected —
      // but log it so a genuine failure (network, auth, parse) is visible
      // rather than silently looking identical to "no stops booked".
      AppLog.w('DriverTrip', 'getRideStops(${widget.ride!.id}) failed: $e');
      AppLog.e('DriverTrip', 'getRideStops stack', e, s);
    }
    if (stops.isEmpty) {
      // Fallback: stops are now sent inline with ride creation. If the
      // dedicated /rides/{id}/stops endpoint hasn't caught up, read them
      // straight off a fresh ride fetch instead (embedded 'stops' field).
      try {
        final ride = await ApiService.getRide(widget.ride!.id);
        AppLog.d('DriverTrip',
            'getRide(${widget.ride!.id}) fallback found ${ride.stops.length} embedded stop(s)');
        stops = ride.stops.map((s) => RideStopModel(
          id:      s.id ?? -(s.order),
          rideId:  widget.ride!.id,
          order:   s.order,
          address: s.address,
          lat:     s.lat,
          lng:     s.lng,
          arrived: s.arrived,
        )).toList();
      } catch (e, s) {
        AppLog.e('DriverTrip', 'getRide fallback failed for ${widget.ride!.id}', e, s);
      }
    }
    if (stops.isEmpty && attempt < 2) {
      // Both reads came back empty — could be a write/read race right after
      // booking (backend hasn't finished persisting the stops yet). Retry a
      // couple of times before accepting "no stops" as final.
      AppLog.w('DriverTrip',
          'no stops found for ride ${widget.ride!.id} on attempt $attempt — retrying');
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return;
      return _loadWayStops(attempt: attempt + 1);
    }
    stops.sort((a, b) => a.order.compareTo(b.order));
    if (!mounted || stops.isEmpty) return;
    setState(() {
      _wayStops      = stops;
      _nextStopIndex = stops.indexWhere((s) => !s.arrived);
      if (_nextStopIndex == -1) _nextStopIndex = stops.length;
      _markers.clear();
      _polylines.clear();
    });
    _initMap();
    _fetchFullRoute();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    LocationService.instance.stopTracking(_driverId);
    if (_prevMapsLanguage != null) {
      MapsService.language = _prevMapsLanguage!;
      LocaleService.setLocale(_prevMapsLanguage!);
    }
    _pulseCtrl.dispose();
    _markerAnimCtrl.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _onAppResumed();
  }

  void _onAppResumed() {
    if (!mounted || _phase == _TripPhase.completed) return;
    // Force map widget redraw (fixes tile blank on iOS after lock screen)
    setState(() {});
    // Restart GPS stream — LocationService cancels the old sub before starting a new one
    _startTracking();
    // Re-fetch route and restore camera with last known position
    if (_driverLatLng != null) {
      _lastRouteFetch = null;
      _fetchLiveRoute(_driverLatLng!);
      final waypoint = _nextWaypoint;
      Future.delayed(const Duration(milliseconds: 300),
          () => mounted ? _fitCamera(_driverLatLng!, waypoint) : null);
    }
  }

  // ── Map initialisation ────────────────────────────────────────────────────────

  void _initMap() {
    final pickup = _pickupLatLng;
    final dest   = _destLatLng;

    _markers.add(Marker(
      markerId: const MarkerId('pickup'),
      position: pickup,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: InfoWindow(title: _pickupAddr),
    ));

    // Intermediate stops — numbered orange markers between pickup and dest
    for (int i = 0; i < _wayStops.length; i++) {
      final s = _wayStops[i];
      _markers.add(Marker(
        markerId: MarkerId('stop_${s.id}'),
        position: LatLng(s.lat, s.lng),
        icon: BitmapDescriptor.defaultMarkerWithHue(
            s.arrived ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueOrange),
        infoWindow: InfoWindow(title: 'Stop ${i + 1}: ${s.address}'),
      ));
    }

    if (dest == null) {
      // No final destination (metered ride) — still draw pickup → stops.
      if (_wayStops.isNotEmpty) {
        final points = [pickup, ..._wayStops.map((s) => LatLng(s.lat, s.lng))];
        _polylines.add(Polyline(
          polylineId: const PolylineId('full_route'),
          points:     points,
          color:      AppTheme.accent,
          width:      4,
        ));
      }
      return;
    }

    _markers.add(Marker(
      markerId: const MarkerId('dest'),
      position: dest,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: InfoWindow(title: _destAddr),
    ));

    // Static full route — solid green line through every leg, including
    // each stop-to-stop segment (pickup → stop 1 → stop 2 → … → destination)
    final points = [
      pickup,
      ..._wayStops.map((s) => LatLng(s.lat, s.lng)),
      dest,
    ];
    _polylines.add(Polyline(
      polylineId: const PolylineId('full_route'),
      points:     points,
      color:      AppTheme.accent,
      width:      4,
    ));
  }

  // ── GPS tracking ──────────────────────────────────────────────────────────────

  Future<void> _startTracking() async {
    final granted = await LocationService.instance.requestPermission();
    if (!granted) {
      // Previously failed completely silently — the driver had no idea
      // live tracking (route, ETA, and the metered fare calculation) was
      // broken for the whole trip until they tried to complete it.
      if (mounted) setState(() => _locationPermissionDenied = true);
      return;
    }
    if (mounted && _locationPermissionDenied) {
      setState(() => _locationPermissionDenied = false);
    }
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

  // ── Smooth lerp animation ─────────────────────────────────────────────────

  void _onMarkerAnimTick() {
    final prev   = _prevDriverPos;
    final target = _targetDriverPos;
    if (prev == null || target == null || !mounted) return;
    final t   = _markerAnimCtrl.value;
    final lat = lerpDouble(prev.latitude,  target.latitude,  t)!;
    final lng = lerpDouble(prev.longitude, target.longitude, t)!;
    _updateDriverMarker(_snapToRoute(LatLng(lat, lng)));
  }

  // ── Snap-to-road ─────────────────────────────────────────────────────────────
  // Raw GPS pings are noisy and the straight lerp between two pings cuts
  // corners wherever the real road bends — both make the marker visibly
  // drift off the drawn route. Since we already have the actual
  // road-following polyline from Directions API, project the marker onto
  // the nearest point of it instead of trusting the raw fix. Display only —
  // ETA/distance calculations still use the raw position.
  LatLng _snapToRoute(LatLng point) {
    final route = _polylines
        .firstWhere((p) => p.polylineId.value == 'live_route',
            orElse: () => _polylines.firstWhere(
                (p) => p.polylineId.value == 'full_route',
                orElse: () => const Polyline(polylineId: PolylineId('none'))))
        .points;
    if (route.length < 2) return point;

    const maxSnapDistanceMeters = 80.0;
    LatLng? closest;
    double bestDistSq = double.infinity;
    for (int i = 0; i < route.length - 1; i++) {
      final proj = _projectOntoSegment(point, route[i], route[i + 1]);
      final dLat = proj.latitude  - point.latitude;
      final dLng = proj.longitude - point.longitude;
      final distSq = dLat * dLat + dLng * dLng;
      if (distSq < bestDistSq) {
        bestDistSq = distSq;
        closest = proj;
      }
    }
    if (closest == null) return point;

    final distMeters = _approxMeters(point, closest);
    return distMeters <= maxSnapDistanceMeters ? closest : point;
  }

  static LatLng _projectOntoSegment(LatLng p, LatLng a, LatLng b) {
    final abLat = b.latitude  - a.latitude;
    final abLng = b.longitude - a.longitude;
    final abLenSq = abLat * abLat + abLng * abLng;
    if (abLenSq == 0) return a;
    final t = (((p.latitude - a.latitude) * abLat) +
            ((p.longitude - a.longitude) * abLng)) /
        abLenSq;
    final tc = t.clamp(0.0, 1.0);
    return LatLng(a.latitude + abLat * tc, a.longitude + abLng * tc);
  }

  static double _approxMeters(LatLng a, LatLng b) {
    const metersPerDegLat = 111320.0;
    final metersPerDegLng = 111320.0 * cos(a.latitude * pi / 180);
    final dLat = (b.latitude  - a.latitude)  * metersPerDegLat;
    final dLng = (b.longitude - a.longitude) * metersPerDegLng;
    return sqrt(dLat * dLat + dLng * dLng);
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
        infoWindow: InfoWindow(title: AppLocalizations.of(context).you),
        // No rotation: ride.png is a fixed-orientation illustration (pin +
        // side-view tuk-tuk), not a top-down sprite meant to spin with GPS
        // bearing — rotating it made the tuk-tuk render upside-down/sideways
        // depending on travel direction.
        anchor:     const Offset(0.5, 0.5),
      ));
    });
  }

  // ── GPS callback ──────────────────────────────────────────────────────────

  void _onDriverPosition(Position position) {
    if (!mounted) return;
    if (!_inCambodia(position.latitude, position.longitude)) return;

    final pos = LatLng(position.latitude, position.longitude);

    // Animate smoothly from previous to current GPS ping
    _prevDriverPos   = _targetDriverPos ?? pos;
    _targetDriverPos = pos;
    _driverLatLng    = pos;
    _markerAnimCtrl
      ..reset()
      ..forward();

    // position.speed is m/s — clamp negatives (GPS noise when stationary).
    _speedKmh = (position.speed * 3.6).clamp(0, 999);
    _advanceNavStep(pos);

    // Auto-detect arrival at pickup (within 80 m → advance phase automatically)
    if (_phase == _TripPhase.headingToPickup) {
      final distToPickup = _distanceMetres(pos, _pickupLatLng);
      if (distToPickup <= 80) {
        _autoArriveAtPickup();
      }
    }

    // Auto-detect arrival at the next intermediate stop (within 80 m)
    if (_phase == _TripPhase.inProgress && _nextStopIndex < _wayStops.length) {
      final nextStop = _wayStops[_nextStopIndex];
      final distToStop = _distanceMetres(pos, LatLng(nextStop.lat, nextStop.lng));
      if (distToStop <= 80) {
        _autoArriveAtStop(nextStop);
      }
    }

    // Camera: show driver + next waypoint (pickup → each stop → destination)
    _fitCamera(pos, _nextWaypoint);

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

  // Advance the turn-by-turn banner to the next maneuver once the driver
  // gets close to the current step's end point.
  void _advanceNavStep(LatLng pos) {
    while (_currentStepIndex < _navSteps.length - 1 &&
        _distanceMetres(pos, _navSteps[_currentStepIndex].endLocation) <= 30) {
      _currentStepIndex++;
    }
  }

  // ── Turn-by-turn banner helpers ──────────────────────────────────────────

  static IconData _maneuverIcon(String maneuver) {
    switch (maneuver) {
      case 'TURN_SHARP_LEFT':
      case 'TURN_LEFT':          return Icons.turn_left_rounded;
      case 'TURN_SLIGHT_LEFT':   return Icons.turn_slight_left_rounded;
      case 'TURN_SHARP_RIGHT':
      case 'TURN_RIGHT':         return Icons.turn_right_rounded;
      case 'TURN_SLIGHT_RIGHT':  return Icons.turn_slight_right_rounded;
      case 'UTURN_LEFT':
      case 'UTURN_RIGHT':        return Icons.u_turn_left_rounded;
      case 'RAMP_LEFT':
      case 'FORK_LEFT':          return Icons.fork_left_rounded;
      case 'RAMP_RIGHT':
      case 'FORK_RIGHT':         return Icons.fork_right_rounded;
      case 'ROUNDABOUT_LEFT':
      case 'ROUNDABOUT_RIGHT':   return Icons.roundabout_left_rounded;
      case 'MERGE':              return Icons.merge_rounded;
      default:                   return Icons.straight_rounded;
    }
  }

  // "Turn left onto Boon Tat St" → "Boon Tat St"; falls back to the full
  // instruction when there's no "onto"/"toward" clause to isolate.
  String _navStreetName(RouteStep step) {
    final text = step.instruction;
    final match = RegExp(r'onto (.+)$', caseSensitive: false).firstMatch(text);
    return match?.group(1) ?? (text.isEmpty ? AppLocalizations.of(context).continueStraight : text);
  }

  String _navDistanceLabel(RouteStep step) {
    final pos = _driverLatLng;
    final meters = pos != null
        ? _distanceMetres(pos, step.endLocation)
        : step.distanceMeters;
    return meters >= 1000
        ? '${(meters / 1000).toStringAsFixed(1)} km'
        : '${meters.round()} m';
  }

  void _autoArriveAtPickup() {
    setState(() => _phase = _TripPhase.waitingAtPickup);
    NotificationService.instance.showTripUpdate(
      title: AppLocalizations.of(context).arrivedAtPickup,
      body:  '${AppLocalizations.of(context).youHaveArrivedAt} $_pickupAddr',
    );
  }

  bool _arrivingAtStop = false;

  Future<void> _autoArriveAtStop(RideStopModel stop) async {
    if (_arrivingAtStop) return;
    _arrivingAtStop = true;
    setState(() => _nextStopIndex++);
    NotificationService.instance.showTripUpdate(
      title: AppLocalizations.of(context).arrivedAtStop,
      body:  '${AppLocalizations.of(context).youHaveArrivedAt} ${stop.address}',
    );
    if (widget.ride != null) {
      try {
        await ApiService.arriveAtRideStop(widget.ride!.id, stop.id);
      } catch (_) {}
    }
    _arrivingAtStop = false;
  }

  // ── Routes API — live route ────────────────────────────────────────────────────

  Future<void> _fetchLiveRoute(LatLng driverPos) async {
    final destination = _nextWaypoint;
    // No destination picked yet (metered trip) — nothing to route to.
    if (destination == null) return;

    final result = await MapsService.getRoute(
      origin:       driverPos,
      destination:  destination,
      includeSteps: true,
    );
    if (!mounted || result == null) return;

    setState(() {
      _etaMinutes = result.etaMinutes;
      _distanceKm = result.distanceKm;
      _navSteps = result.steps;
      _currentStepIndex = 0;
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

  // Overview route (pickup → each stop → destination), following actual
  // roads instead of the straight-line placeholder drawn by _initMap.
  Future<void> _fetchFullRoute() async {
    final pickup = _pickupLatLng;
    final dest   = _destLatLng;
    final legs = [pickup, ..._wayStops.map((s) => LatLng(s.lat, s.lng)), if (dest != null) dest];
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
          color:      AppTheme.accent,
          width:      4,
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
    // Also keeps user.current_latitude/longitude fresh — the dropoff
    // fallback /rides/{id}/complete uses if we don't send explicit
    // dropoff_lat/lng (e.g. metered trips where GPS failed at the exact
    // moment of completion).
    ApiService.updateCurrentLocation(latitude: pos.latitude, longitude: pos.longitude);
  }

  // ── Camera ─────────────────────────────────────────────────────────────────────

  void _fitCamera(LatLng a, LatLng? b) {
    if (b == null) {
      _mapController?.animateCamera(CameraUpdate.newLatLng(a));
      return;
    }
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
      case _TripPhase.headingToPickup: return AppLocalizations.of(context).headingToPickup2;
      case _TripPhase.waitingAtPickup: return AppLocalizations.of(context).waitingAtPickup;
      case _TripPhase.inProgress:      return AppLocalizations.of(context).tripInProgressCap;
      case _TripPhase.completed:       return AppLocalizations.of(context).tripCompleted;
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
      case _TripPhase.headingToPickup: return AppLocalizations.of(context).arrivedAtPickupBtn;
      case _TripPhase.waitingAtPickup: return AppLocalizations.of(context).passengerOnBoardStartTrip;
      case _TripPhase.inProgress:      return AppLocalizations.of(context).completeTripBtn;
      case _TripPhase.completed:       return AppLocalizations.of(context).backToDashboardBtn;
    }
  }

  Future<void> _advancePhase() async {
    if (_phase == _TripPhase.completed) {
      Navigator.pop(context);
      return;
    }

    if (_phase == _TripPhase.inProgress) {
      // No destination was picked at booking — the fare is auto-calculated
      // from pickup → the driver's current GPS position, using the same
      // admin-configured rate table as a normal fare estimate. The driver
      // still reviews a read-only summary (km/duration/fare) and taps
      // Confirm before it's finalized, so they know what to collect from
      // the passenger. If the calculation fails (no GPS signal), fall back
      // to manual entry instead.
      int?    finalFareKhr;
      double? meteredDistanceKm;
      int?    meteredDurationMin;
      if (_isMetered) {
        setState(() => _completing = true);
        final suggested = await _estimateMeteredFare();
        if (!mounted) return;
        setState(() => _completing = false);
        if (suggested != null) {
          meteredDistanceKm  = suggested.distanceKm;
          meteredDurationMin = _tripStartTime != null
              ? DateTime.now().difference(_tripStartTime!).inMinutes
              : null;
          finalFareKhr = await _confirmTripSummary(
            fareKhr: suggested.amount,
            distanceKm: suggested.distanceKm,
            durationMin: meteredDurationMin,
          );
          if (finalFareKhr == null) return;
        } else {
          finalFareKhr = await _promptFinalFare(suggested);
          if (finalFareKhr == null) return;
        }
      }

      setState(() => _completing = true);
      RideModel? completedRide;
      if (widget.ride != null) {
        try {
          completedRide = await ApiService.completeRide(
            widget.ride!.id,
            fareKhr:        finalFareKhr,
            dropoffLat:     _isMetered ? _driverLatLng?.latitude  : null,
            dropoffLng:     _isMetered ? _driverLatLng?.longitude : null,
          );
          // The complete endpoint may not return distance/duration —
          // fetch the finalized ride to get server-computed values.
          if (completedRide.distanceKm == null || completedRide.durationMin == null) {
            try {
              final fresh = await ApiService.getRide(widget.ride!.id);
              if (fresh.distanceKm != null || fresh.durationMin != null) {
                completedRide = fresh;
              }
            } catch (_) {}
          }
        } catch (_) {
          completedRide = widget.ride;
        }
      }
      if (!mounted) return;
      setState(() { _completing = false; _phase = _TripPhase.completed; });

      final notifiedFareKhr = (completedRide ?? widget.ride)?.fareKhr ?? 0;
      await NotificationService.instance.showTripUpdate(
        title: AppLocalizations.of(context).tripCompleted2,
        body:  'You earned ${AppTheme.khr(notifiedFareKhr > 0 ? notifiedFareKhr : (finalFareKhr ?? 0))}',
      );
      if (!mounted) return;
      final finalRide = completedRide ?? widget.ride ?? _fakeSummaryRide();
      // For metered rides, prefer the values just calculated and shown to
      // the driver in the confirm dialog — the backend's completion
      // response doesn't reliably echo the fare/distance/duration back.
      // Using `> 0 ? x : fallback` rather than `??` throughout: the
      // backend has been observed returning a real `0` (not null) for
      // these fields, which `??` would never fall back past.
      final fallbackDist = (finalRide.distanceKm != null && finalRide.distanceKm! > 0)
          ? finalRide.distanceKm
          : (meteredDistanceKm ?? _tripDistanceKm);
      final fallbackDur  = (finalRide.durationMin != null && finalRide.durationMin! > 0)
          ? finalRide.durationMin
          : (meteredDurationMin ??
              (_tripStartTime != null
                  ? DateTime.now().difference(_tripStartTime!).inMinutes
                  : null));
      final fallbackFareKhr = finalRide.fareKhr > 0 ? null : finalFareKhr;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DriverTripSummaryScreen(
            ride:            finalRide,
            distanceKmFallback: fallbackDist,
            durationMinFallback: fallbackDur,
            fareKhrFallback: fallbackFareKhr,
            wayStops:        _wayStops.map((s) => s.address).toList(),
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

    // When trip starts (inProgress), record start time and snapshot route distance
    if (_phase == _TripPhase.inProgress) {
      _tripStartTime   = DateTime.now();
      _tripDistanceKm  = _distanceKm > 0 ? _distanceKm : null;
      if (_driverLatLng != null) {
        _lastRouteFetch = null;
        _fetchLiveRoute(_driverLatLng!);
      }
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

  // ── Metered fare entry (no-destination trips) ─────────────────────────────────

  // Surfaced in the manual-entry dialog when auto-calculation fails, so a
  // screenshot shows the real cause instead of a generic message — useful
  // when the person hitting this has no console/log access.
  String? _meteredFareError;

  // Uses the same admin-configured rate table as normal ride estimates —
  // pickup → driver's current position stands in for the actual distance
  // travelled, since there was no destination to route against.
  Future<({int amount, double distanceKm})?> _estimateMeteredFare() async {
    _meteredFareError = null;
    if (widget.ride == null) {
      _meteredFareError = AppLocalizations.of(context).noActiveRide;
      return null;
    }

    // _driverLatLng only updates from the live GPS stream — if it hasn't
    // fired yet at the exact moment "Complete Trip" is tapped (stream lag,
    // just-granted permission, etc.) this was null. Try progressively
    // harder fallbacks: last-known fix, then a fresh high-accuracy fix,
    // then a fresh lower-accuracy fix with a longer timeout.
    var pos = _driverLatLng;
    if (pos == null) {
      try {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) pos = LatLng(lastKnown.latitude, lastKnown.longitude);
      } catch (_) {}
    }
    if (pos == null) {
      try {
        final fresh = await Geolocator.getCurrentPosition(
                desiredAccuracy: LocationAccuracy.high)
            .timeout(const Duration(seconds: 8));
        pos = LatLng(fresh.latitude, fresh.longitude);
      } catch (_) {
        try {
          final fresh = await Geolocator.getCurrentPosition(
                  desiredAccuracy: LocationAccuracy.medium)
              .timeout(const Duration(seconds: 15));
          pos = LatLng(fresh.latitude, fresh.longitude);
        } catch (e2, s) {
          AppLog.w('DriverTrip', 'GPS fix failed for metered fare, using pickup as fallback: $e2');
          AppLog.e('DriverTrip', 'GPS fix stack', e2, s);
        }
      }
    }

    // Reject a GPS fix outside Cambodia — a stale cached position, a
    // simulator's default location, or bad data would otherwise produce a
    // huge nonsensical "distance" (seen in practice: 17,000+ km, roughly a
    // third of the way around the Earth) and charge the passenger for it.
    if (pos != null && !_inCambodia(pos.latitude, pos.longitude)) {
      AppLog.w('DriverTrip',
          'GPS position (${pos.latitude}, ${pos.longitude}) outside Cambodia, using pickup as fallback');
      pos = null;
    }

    // No usable GPS position — fall back to pickup-as-dropoff (distance ≈
    // 0) so the driver still gets an automatically-calculated base fare
    // from the same rate table, rather than a blank manual-entry field.
    pos ??= _pickupLatLng;

    try {
      final estimate = await ApiService.estimateRide(
        pickupLat:  _pickupLatLng.latitude,
        pickupLng:  _pickupLatLng.longitude,
        dropoffLat: pos.latitude,
        dropoffLng: pos.longitude,
      );
      // Sanity clamp — Cambodia is ~450 km at its widest, so any single
      // metered trip's straight-line distance should never exceed this by
      // much even accounting for a winding route. Catches a backend
      // calculation bug even when the GPS position itself was valid.
      if (estimate.distanceKm > 500) {
        _meteredFareError = '${AppLocalizations.of(context).calculatedDistancePrefix} '
            '(${estimate.distanceKm.toStringAsFixed(1)} km) '
            '${AppLocalizations.of(context).looksWrongFartherThanTrip}';
        return null;
      }
      final fare = estimate.fares[widget.ride!.serviceType] ??
          (estimate.fares.values.isNotEmpty ? estimate.fares.values.first : null);
      if (fare == null) {
        _meteredFareError = '${AppLocalizations.of(context).noFareReturnedForServiceType} '
            '"${widget.ride!.serviceType}" (${AppLocalizations.of(context).available}: ${estimate.fares.keys.join(', ')}).';
        return null;
      }
      return (amount: fare.total, distanceKm: estimate.distanceKm);
    } catch (e, s) {
      AppLog.e('DriverTrip', 'estimateRide failed for metered fare', e, s);
      _meteredFareError = '${AppLocalizations.of(context).fareCalculationFailedPrefix} $e';
      return null;
    }
  }

  // Read-only review of the auto-calculated trip — driver confirms before
  // it's submitted, so they know exactly what to collect from the passenger.
  Future<int?> _confirmTripSummary({
    required int fareKhr,
    required double distanceKm,
    required int? durationMin,
  }) async {
    return showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.appSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(AppLocalizations.of(context).tripCompleted2,
            style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w800)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(AppLocalizations.of(context).thisTripHadNoDestination,
              style: TextStyle(color: context.appTextSecondary, fontSize: 13)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: context.appCardBg, borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                _SummaryStat(icon: Icons.route_outlined, label: AppLocalizations.of(context).distance,
                    value: '${distanceKm.toStringAsFixed(1)} km'),
                _SummaryStat(icon: Icons.timer_outlined, label: AppLocalizations.of(context).duration,
                    value: durationMin != null ? '$durationMin min' : '--'),
              ]),
              const SizedBox(height: 14),
              Divider(height: 1, color: context.appTextSecondary.withValues(alpha: 0.2)),
              const SizedBox(height: 14),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(AppLocalizations.of(context).amountToCollect,
                    style: TextStyle(color: context.appTextSecondary, fontSize: 13)),
                Text(AppTheme.khr(fareKhr),
                    style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w800, fontSize: 20)),
              ]),
            ]),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, fareKhr),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(AppLocalizations.of(context).confirm),
          ),
        ],
      ),
    );
  }

  Future<int?> _promptFinalFare(({int amount, double distanceKm})? suggested) async {
    final ctrl = TextEditingController(
        text: suggested != null ? suggested.amount.toString() : '');
    String? error;
    return showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: context.appSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(AppLocalizations.of(context).enterFinalFare,
              style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w800)),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              suggested != null
                  ? '${AppLocalizations.of(context).tripHadNoDestinationSuggested} '
                    'from ${suggested.distanceKm.toStringAsFixed(1)} km ${AppLocalizations.of(context).fromDistanceTravelledAdjust}'
                  : "This trip had no destination set — enter the metered fare to complete it.\n"
                    "Couldn't auto-calculate a suggestion: "
                    "${_meteredFareError ?? AppLocalizations.of(context).unknownError}",
              style: TextStyle(color: context.appTextSecondary, fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w700, fontSize: 18),
              decoration: InputDecoration(
                prefixText: '៛ ',
                hintText: 'e.g. 8000',
                filled: true,
                fillColor: context.appCardBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                errorText: error,
              ),
            ),
          ]),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.of(context).cancel),
            ),
            ElevatedButton(
              onPressed: () {
                final amt = int.tryParse(ctrl.text.trim());
                if (amt == null || amt <= 0) {
                  setLocal(() => error = AppLocalizations.of(context).enterAValidAmount2);
                  return;
                }
                Navigator.pop(ctx, amt);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(AppLocalizations.of(context).completeTrip),
            ),
          ],
        ),
      ),
    );
  }

  // ── Dialogs / actions ─────────────────────────────────────────────────────────

  void _showSOS() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.appSurface,
        title: Row(children: [
          Icon(Icons.warning_amber_rounded, color: AppTheme.danger, size: 28),
          SizedBox(width: 10),
          Text(AppLocalizations.of(context).emergencySos,
              style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.w800)),
        ]),
        content: Text(
          AppLocalizations.of(context).thisWillAlertEmergencyServices,
          style: TextStyle(color: context.appTextSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context).cancel,
                  style: TextStyle(color: context.appTextSecondary))),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); _sendSOS(); },
            style: AppTheme.confirmButtonStyle(background: AppTheme.danger),
            child: Text(AppLocalizations.of(context).sendSos),
          ),
        ],
      ),
    );
  }

  Future<void> _sendSOS() async {
    if (widget.ride == null) return;
    try {
      await ApiService.sendSosAlert(
        rideId: widget.ride!.id,
        message: 'Driver-initiated SOS during active trip.',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context).sosSentHelpIsOn),
        backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
      ));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('SOS failed: ${e.message}'),
        backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('SOS failed to send. Please call emergency services directly.'),
        backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
      ));
    }
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
        myName:      saved?.name ?? AppLocalizations.of(context).driver,
        otherName:   widget.ride!.passenger?.name
                         ?? '${AppLocalizations.of(context).passengerNumberPrefix}${widget.ride!.passengerId}',
        isDriver:    true,
      ),
    ));
  }

  void _callPassenger() {
    final phone = widget.ride?.passenger?.phone ?? '+855 --';
    showModalBottomSheet(
      context: context,
      backgroundColor: context.appSurface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: AppTheme.accent.withValues(alpha: 0.2),
            child: Text(_passengerName[0],
                style: TextStyle(
                    color: AppTheme.accent,
                    fontSize: 28,
                    fontWeight: FontWeight.w800)),
          ),
          SizedBox(height: 12),
          Text(_passengerName,
              style: TextStyle(
                  color: context.appTextPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          Text(phone, style: TextStyle(color: context.appTextSecondary)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                final uri = Uri(scheme: 'tel', path: phone);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
              icon: const Icon(Icons.call),
              label: Text(AppLocalizations.of(context).callNow,
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
    final midLat  = dest != null ? (pickup.latitude  + dest.latitude)  / 2 : pickup.latitude;
    final midLng  = dest != null ? (pickup.longitude + dest.longitude) / 2 : pickup.longitude;

    return Scaffold(
      body: Stack(children: [

        // ── Full-screen map ───────────────────────────────────────────────────
        GoogleMap(
          onMapCreated: (c) {
            _mapController = c;
            if (dest == null) {
              c.animateCamera(CameraUpdate.newLatLngZoom(pickup, 15));
              return;
            }
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
          style: Theme.of(context).brightness == Brightness.dark
              ? _kDarkMapStyle
              : _kLightMapStyle,
          cameraTargetBounds: CameraTargetBounds(_kCambodiaBounds),
          minMaxZoomPreference: const MinMaxZoomPreference(6, 20),
          markers:   _markers,
          polylines: _polylines,
          myLocationEnabled: false,
          zoomControlsEnabled: false,
        ),

        // ── Turn-by-turn navigation banner (Grab-style) ────────────────────────
        if (!_navBannerDismissed && !isCompleted && _navSteps.isNotEmpty &&
            _currentStepIndex < _navSteps.length &&
            (_phase == _TripPhase.headingToPickup || _phase == _TripPhase.inProgress))
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              color: const Color(0xFF10151F),
              padding: EdgeInsets.only(
                top:    MediaQuery.of(context).padding.top + 10,
                left:   16, right: 8, bottom: 14,
              ),
              child: Row(children: [
                Icon(_maneuverIcon(_navSteps[_currentStepIndex].maneuver),
                    color: Colors.white, size: 36),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_navDistanceLabel(_navSteps[_currentStepIndex]),
                        style: const TextStyle(color: Colors.white60,
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(_navStreetName(_navSteps[_currentStepIndex]),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white,
                            fontSize: 19, fontWeight: FontWeight.w800)),
                  ]),
                ),
                GestureDetector(
                  onTap: () => setState(() => _navBannerDismissed = true),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                        color: Colors.white24, shape: BoxShape.circle),
                    child: const Icon(Icons.close, color: Colors.white, size: 16),
                  ),
                ),
              ]),
            ),
          ),

        // ── Top bar ───────────────────────────────────────────────────────────
        SafeArea(
          child: Column(children: [
            if (_locationPermissionDenied)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  const Icon(Icons.location_off, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${AppLocalizations.of(context).locationPermissionDeniedLiveTracking}'
                      'calculation won\'t work.',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Geolocator.openAppSettings(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                          color: Colors.white, borderRadius: BorderRadius.circular(8)),
                      child: Text(AppLocalizations.of(context).enable,
                          style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.w800, fontSize: 12)),
                    ),
                  ),
                ]),
              ),
            Padding(
            padding: EdgeInsets.all(16),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.9),
                      shape: BoxShape.circle),
                  child: Icon(Icons.arrow_back,
                      color: context.appTextPrimary, size: 20),
                ),
              ),
              Spacer(),
              // Pulsing phase pill
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, __) => Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                    SizedBox(width: 6),
                    Text(_phaseLabel,
                        style: TextStyle(
                            color: _phaseColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 12)),
                  ]),
                ),
              ),
              Spacer(),
              // SOS
              GestureDetector(
                onTap: _showSOS,
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                      color: AppTheme.danger,
                      borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(AppLocalizations.of(context).sos,
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 12)),
                  ]),
                ),
              ),
            ]),
            ),

            // Live speed readout (Grab-style) — only while en-route.
            if (!isCompleted &&
                (_phase == _TripPhase.headingToPickup || _phase == _TripPhase.inProgress))
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 16, top: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: context.appSurface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
                    ),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text('${_speedKmh.round()}',
                          style: TextStyle(color: context.appTextPrimary,
                              fontSize: 20, fontWeight: FontWeight.w900)),
                      Text(AppLocalizations.of(context).kmH,
                          style: TextStyle(color: context.appTextSecondary,
                              fontSize: 10, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              ),
          ]),
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
                  EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: context.appSurface,
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
                        style: TextStyle(
                            color: context.appTextSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w400)),
                  ],
                ),
              ),
            ),
          ),

        // ── Bottom sheet ──────────────────────────────────────────────────────
        // The CTA button floats fixed at the bottom (via Stack) while the
        // content column scrolls its full height behind/under it, instead
        // of the button pushing down and shrinking the scrollable area.
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            decoration: BoxDecoration(
              color: context.appSurface,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 20)
              ],
            ),
            child: Stack(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  // Handle
                  Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                          color: context.appCardBg,
                          borderRadius: BorderRadius.circular(2))),
                  SizedBox(height: 14),

                  // Everything scrolls together as one area — the compact
                  // card is just first, so it's what shows by default
                  // before any scrolling, capped to 50% of screen height.
                  ConstrainedBox(
                    constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.5),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 76),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [

              if (!isCompleted) ...[
                // Compact Grab-style trip card — status pill + distance/ETA,
                // next-address subtitle, payment/fare row with quick actions.
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: context.appCardBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: _phaseColor, borderRadius: BorderRadius.circular(20)),
                        child: Text(_serviceLabel,
                            style: const TextStyle(color: Colors.white,
                                fontSize: 11, fontWeight: FontWeight.w800)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_phaseLabel,
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: context.appTextPrimary,
                                fontWeight: FontWeight.w700, fontSize: 14)),
                      ),
                      if (_etaMinutes > 0)
                        Text('$_distanceLabel  |  $_etaMinutes min',
                            style: TextStyle(color: _phaseColor,
                                fontWeight: FontWeight.w800, fontSize: 13)),
                    ]),
                    const SizedBox(height: 4),
                    Text(_phase == _TripPhase.inProgress ? _destAddr : _pickupAddr,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
                    Divider(height: 22, color: context.appSurface),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: context.appTextPrimary, borderRadius: BorderRadius.circular(6)),
                        child: Text(_paymentLabel,
                            style: TextStyle(color: context.appSurface,
                                fontSize: 10, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_isMetered ? AppLocalizations.of(context).metered : _fare,
                            style: TextStyle(color: context.appTextPrimary,
                                fontWeight: FontWeight.w800, fontSize: 15)),
                      ),
                      GestureDetector(
                        onTap: _openRideChat,
                        child: Icon(Icons.chat_bubble_outline,
                            size: 20, color: context.appTextSecondary),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: _callPassenger,
                        child: Icon(Icons.call_outlined,
                            size: 20, color: context.appTextSecondary),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: _showSOS,
                        child: Icon(Icons.more_horiz,
                            size: 22, color: context.appTextSecondary),
                      ),
                    ]),
                  ]),
                ),

                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: context.appCardBg,
                      borderRadius: BorderRadius.circular(12)),
                  child: Column(children: [
                    Row(children: [
                      Icon(Icons.circle,
                          color: AppTheme.success, size: 10),
                      SizedBox(width: 8),
                      Expanded(
                          child: Text(_pickupAddr,
                              style: TextStyle(
                                  color: context.appTextPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600))),
                    ]),
                    for (int i = 0; i < _wayStops.length; i++) ...[
                      SizedBox(height: 4),
                      Row(children: [
                        Container(
                            width: 1,
                            height: 16,
                            color: context.appTextSecondary,
                            margin: EdgeInsets.only(left: 4)),
                      ]),
                      SizedBox(height: 4),
                      Row(children: [
                        Container(
                          width: 16, height: 16,
                          decoration: BoxDecoration(
                            color: (_wayStops[i].arrived ? AppTheme.success : AppTheme.warning)
                                .withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: _wayStops[i].arrived ? AppTheme.success : AppTheme.warning,
                                width: 1.2),
                          ),
                          child: Center(
                            child: Text('${i + 1}',
                                style: TextStyle(
                                    color: _wayStops[i].arrived ? AppTheme.success : AppTheme.warning,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800)),
                          ),
                        ),
                        SizedBox(width: 6),
                        Expanded(
                            child: Text(_wayStops[i].address,
                                style: TextStyle(
                                    color: context.appTextPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600))),
                      ]),
                    ],
                    SizedBox(height: 4),
                    Row(children: [
                      Container(
                          width: 1,
                          height: 16,
                          color: context.appTextSecondary,
                          margin: EdgeInsets.only(left: 4)),
                    ]),
                    SizedBox(height: 4),
                    Row(children: [
                      if (_isMetered || _wayStops.isEmpty)
                        Icon(_isMetered ? Icons.record_voice_over_outlined : Icons.location_on,
                            color: _isMetered ? AppTheme.accent : AppTheme.accentOrange, size: 12)
                      else
                        Container(
                          width: 16, height: 16,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE53935).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFE53935), width: 1.2),
                          ),
                          child: Center(
                            child: Text('${_wayStops.length + 1}',
                                style: const TextStyle(
                                    color: Color(0xFFE53935),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800)),
                          ),
                        ),
                      SizedBox(width: _isMetered || _wayStops.isEmpty ? 8 : 6),
                      Expanded(
                          child: Text(_destAddr,
                              style: TextStyle(
                                  color: _isMetered ? AppTheme.accent : context.appTextSecondary,
                                  fontWeight: _isMetered ? FontWeight.w600 : FontWeight.w400,
                                  fontSize: 13))),
                    ]),
                  ]),
                ),
                const SizedBox(height: 14),
              ],

              if (isCompleted) ...[
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: AppTheme.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16)),
                  child: Column(children: [
                    Icon(Icons.check_circle,
                        color: AppTheme.success, size: 48),
                    SizedBox(height: 8),
                    Text(AppLocalizations.of(context).tripCompleted,
                        style: TextStyle(
                            color: AppTheme.success,
                            fontWeight: FontWeight.w800,
                            fontSize: 18)),
                    Text('${AppLocalizations.of(context).youEarnedPrefix} $_fare',
                        style: TextStyle(
                            color: context.appTextSecondary)),
                  ]),
                ),
                const SizedBox(height: 14),
              ],
                      ]),
                    ),
                  ),
                ]),
              ),

              // CTA button — floats fixed at the bottom, over the
              // scrollable content above.
              Positioned(
                left: 20, right: 20, bottom: 20,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _completing ? null : _advancePhase,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isCompleted ? AppTheme.success : _phaseColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28)),
                      elevation: 4,
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
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _SummaryStat extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  const _SummaryStat({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Icon(icon, color: AppTheme.accent, size: 18),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
      Text(label, style: TextStyle(color: context.appTextSecondary, fontSize: 11)),
    ]);
  }
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

// White/light background for light mode — plain geometry, no dark tinting.
const String _kLightMapStyle =
    '[{"elementType":"geometry","stylers":[{"color":"#ffffff"}]},'
    '{"elementType":"labels.text.fill","stylers":[{"color":"#616161"}]},'
    '{"elementType":"labels.text.stroke","stylers":[{"color":"#ffffff"}]},'
    '{"featureType":"road","elementType":"geometry","stylers":[{"color":"#f2f2f2"}]},'
    '{"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#e8e8e8"}]},'
    '{"featureType":"water","elementType":"geometry","stylers":[{"color":"#d7ebfa"}]},'
    '{"featureType":"poi","elementType":"geometry","stylers":[{"color":"#f2f2f2"}]},'
    '{"featureType":"administrative","elementType":"geometry.stroke","stylers":[{"color":"#e0e0e0"}]}]';
