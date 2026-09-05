import 'dart:async';
import 'dart:math' show min, max, cos, pi, sqrt;
import 'dart:ui' show lerpDouble;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../services/notification_service.dart';
import '../../services/api_service.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/location_service.dart';
import '../../services/maps_service.dart';
import '../../services/marker_icon_service.dart';
import '../../models/driver_marker_model.dart';
import '../../models/ride_model.dart';
import '../../l10n/app_localizations.dart';
import 'rate_driver_screen.dart';
import 'safety_screen.dart';
import '../shared/ride_chat_screen.dart';
import '../../theme/app_theme.dart';
import '../../utils/location_display.dart';
import '../../utils/app_log.dart';
import '../../main.dart' show appLocale;

const _kGreen = Color(0xFF00B14F);

/// A single intermediate stop passed to [TripTrackingScreen].
class TripStop {
  final String address;
  final LatLng latLng;
  TripStop({required this.address, required this.latLng});
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

  TripTrackingScreen({
    super.key,
    this.rideId,
    this.driverId      = '',
    // Constructor defaults can't call AppLocalizations.of (no BuildContext
    // yet) — empty string is a sentinel resolved to the localized
    // placeholder in initState below.
    this.driverName    = '',
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
  StreamSubscription<DriverMarkerModel>? _firestoreSub;
  StreamSubscription<Map<String, dynamic>>? _rideStatusSub;
  // Server-side status string (covers 'requested', 'accepted',
  // 'driver_arrived', 'in_progress', 'completed', 'cancelled')
  String _rideStatus = 'requested';

  final Set<Marker>   _markers   = {};
  final Set<Polyline> _polylines = {};

  // Route detail card starts collapsed to a small chevron (Grab-style) —
  // tap to expand the full pickup/stops/dropoff breakdown.
  bool _routeCardExpanded = false;

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
  String? _vehiclePhotoUrl;
  Timer? _ridePollTimer;

  // One-shot guard so the "driver is arriving" alert fires only once per
  // driver, the moment they first come within 50m of the pickup point.
  bool _arrivingAlertShown = false;

  // One-shot guard for the "almost at your destination" alert.
  bool _arrivingDestAlertShown = false;

  // Dynamic vehicle icon — loaded async; null means use default pin
  BitmapDescriptor? _driverIcon;

  // True once at least one real GPS ping has arrived for the assigned
  // driver (i.e. drivers_live/{id} has lat/lng in Firestore). A driver can
  // be assigned (name/plate/rating already fetched via REST) well before
  // their app starts writing live location, so this drives a distinct
  // "Locating driver…" state instead of silently showing no marker.
  bool _driverPositionKnown = false;

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

  // Fallback only for the rare case neither was passed in — same default
  // center used by the map's initial camera position below.
  LatLng get _pickupPoint => widget.pickupLatLng ?? _initialCamera.target;
  LatLng get _destPoint   => widget.destLatLng   ?? _initialCamera.target;

  static const _initialCamera = CameraPosition(
    target: LatLng(11.5680, 104.9195),
    zoom: 14.5,
  );

  bool _l10nDefaultsApplied = false;

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_l10nDefaultsApplied) return;
    _l10nDefaultsApplied = true;
    if (_driverName.isEmpty) {
      _driverName = AppLocalizations.of(context).findingDriver;
    }
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
      color:      _kGreen,
      width:      5,
      startCap:   Cap.roundCap,
      endCap:     Cap.roundCap,
      jointType:  JointType.round,
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
          color:      _kGreen,
          width:      5,
          startCap:   Cap.roundCap,
          endCap:     Cap.roundCap,
          jointType:  JointType.round,
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
    _setDriverMarker(_snapToRoute(LatLng(lat, lng)));
  }

  // ── Snap-to-road ─────────────────────────────────────────────────────────────
  // Raw GPS pings are noisy (multipath off buildings, etc.) and the straight
  // lerp between two pings cuts corners wherever the real road bends — both
  // make the marker visibly drift off the drawn route. Since we already have
  // the actual road-following polyline from Directions API, project the
  // marker onto the nearest point of it instead of trusting the raw fix.
  // Only for display — ETA/distance calculations still use the raw position.
  LatLng _snapToRoute(LatLng point) {
    final route = _polylines
        .firstWhere((p) => p.polylineId.value == 'live_route',
            orElse: () => _polylines.firstWhere(
                (p) => p.polylineId.value == 'full_route',
                orElse: () => const Polyline(polylineId: PolylineId('none'))))
        .points;
    if (route.length < 2) return point;

    // Only snap when reasonably close to the route already — a big jump
    // (stale/wrong polyline, or the driver genuinely off-route) should show
    // the real position rather than snapping somewhere misleading.
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

  // Projects [p] onto the segment [a]→[b] using an equirectangular
  // approximation — plenty accurate at the scale of one road segment.
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

  void _setDriverMarker(LatLng pos) {
    if (!mounted) return;

    setState(() {
      _markers.removeWhere((m) => m.markerId.value == 'driver');
      _markers.add(Marker(
        markerId:   const MarkerId('driver'),
        position:   pos,
        icon:       _driverIcon ?? BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueAzure),
        infoWindow: InfoWindow(title: _driverName, snippet: _vehicle),
        // No rotation: ride.png is a fixed-orientation illustration (pin +
        // side-view tuk-tuk), not a top-down sprite meant to spin with GPS
        // bearing — rotating it made the tuk-tuk render upside-down/sideways
        // depending on travel direction.
        anchor:     const Offset(0.5, 0.5),
      ));
    });
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

    if (!_driverPositionKnown && mounted) {
      setState(() => _driverPositionKnown = true);
    }

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

    _checkArrivingSoon(pos);
    _checkArrivingAtDestination(pos);
    if (_rideStatus == 'in_progress') _checkStopProximity(pos);

    // Camera: fit driver + next waypoint so both are always visible — once
    // per real GPS update, not every animation frame (was previously
    // called from the 60fps marker-lerp tick, thrashing the camera).
    final waypoint = _driverAssigned && _rideStatus == 'in_progress'
        ? _destPoint
        : _pickupPoint;
    _fitCamera(pos, waypoint);

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
        _driverAssigned && _rideStatus == 'in_progress';

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

  /// Notifies the passenger once when the driver first comes within 50m of
  /// the pickup point, while still en route to pick them up.
  // "Driver found" alert (sound + notification) — this used to only fire
  // from the legacy WebSocket TripUpdate stream, which isn't a reliable
  // signal (same gap as the ride-status one fixed elsewhere in this file).
  // Now triggered from the same reliable paths (Firestore listener + REST
  // poll) that already detect a new driver assignment.
  bool _driverFoundAlertShown = false;
  void _notifyDriverFound() {
    if (_driverFoundAlertShown) return;
    _driverFoundAlertShown = true;
    // Body deliberately doesn't include the driver's name — this fires
    // before _fetchDriverDetails()/_applyDriverDetails() resolve, so
    // _driverName may still be the "Finding driver..." placeholder here.
    NotificationService.instance.showTripUpdate(
      title: AppLocalizations.of(context).driverFound,
      body:  AppLocalizations.of(context).yourDriverIsOnThe2,
      payload: 'picking_up',
    );
  }

  void _checkArrivingSoon(LatLng driverPos) {
    if (!_isApproachingPickup || _arrivingAlertShown) return;
    final dist = Geolocator.distanceBetween(
      driverPos.latitude, driverPos.longitude,
      _pickupPoint.latitude, _pickupPoint.longitude,
    );
    if (dist <= 50) {
      _arrivingAlertShown = true;
      NotificationService.instance.showTripUpdate(
        title: AppLocalizations.of(context).yourDriverIsAlmostHere,
        body: '$_driverName is arriving at your pickup point.',
        payload: 'arriving_soon',
      );
    }
  }

  /// Notifies the passenger once when the driver first comes within 50m of
  /// the final destination, while the trip is already in progress (i.e. the
  /// passenger is already onboard — this is a "check your belongings" alert,
  /// not a pickup alert). Localized to the app's current language (km/en/zh).
  void _checkArrivingAtDestination(LatLng driverPos) {
    if (_rideStatus != 'in_progress' || _arrivingDestAlertShown) return;
    final dist = Geolocator.distanceBetween(
      driverPos.latitude, driverPos.longitude,
      _destPoint.latitude, _destPoint.longitude,
    );
    if (dist <= 50) {
      _arrivingDestAlertShown = true;
      final String title, body;
      switch (appLocale.value.languageCode) {
        case 'km':
          title = '🔔 ជិតដល់គោលដៅហើយ';
          body  = 'សូមពិនិត្យមើលសម្ភារៈរបស់អ្នក មុនចុះចេញពីកង់បី។';
          break;
        case 'zh':
          title = '🔔 即将到达目的地';
          body  = '下车前，请检查您的随身物品。';
          break;
        default:
          title = AppLocalizations.of(context).youReAlmostAtYour;
          body  = AppLocalizations.of(context).pleaseCheckYourBelongingsBefore;
      }
      NotificationService.instance.showTripUpdate(
        title: title,
        body:  body,
        payload: 'arriving_destination',
      );
    }
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
            ? AppLocalizations.of(context).cannotCancelARideIn
            : AppLocalizations.of(context).thisRideCannotBeCancelled),
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

  bool _serverCancellationHandled = false;

  // The ride was cancelled by something other than this screen's own
  // _cancelRide() flow (that path already pops immediately, so by the time
  // this fires the ride was cancelled server-side — no driver found within
  // the dispatch window, or the driver cancelled after accepting).
  void _handleServerCancellation(String? reason) {
    if (_serverCancellationHandled || !mounted) return;
    _serverCancellationHandled = true;

    final message = reason == 'no_driver_available'
        ? AppLocalizations.of(context).noDriverWasAvailableFor
        : AppLocalizations.of(context).thisRideWasCancelled;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context).rideCancelled),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context).ok),
          ),
        ],
      ),
    ).then((_) {
      if (mounted) _disposeMapAndPop();
    });
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
  // Real driver position/status only — Firestore live doc, with the REST
  // poll (_pollRide) as fallback. There is no simulated/fake data source;
  // a previous WebSocketService here was a hardcoded demo route that always
  // reported the driver as already en route regardless of actual ride
  // status, and has been removed entirely.

  void _startTracking() {
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

  bool _navigatingToRating = false;

  // Central place _rideStatus gets updated from (Firestore + REST poll) —
  // auto-navigates to the rating screen once the trip is actually
  // completed, instead of relying on a manual button (previously mislabeled
  // "I'm here" and wired to fire on driver-arrived-at-pickup, not
  // trip completion).
  bool _driverArrivedAlertShown = false;

  void _setRideStatus(String status) {
    if (!mounted) return;
    final prevStatus = _rideStatus;
    setState(() => _rideStatus = status);
    if (status == 'driver_arrived' && prevStatus != 'driver_arrived' &&
        !_driverArrivedAlertShown) {
      _driverArrivedAlertShown = true;
      NotificationService.instance.showTripUpdate(
        title: AppLocalizations.of(context).driverArrived,
        body: '$_driverName is waiting at ${widget.from}',
        payload: 'arrived',
      );
    }
    if (status == 'completed') {
      _navigateToRating();
    }
    if (status == 'completed' || status == 'cancelled') {
      _ridePollTimer?.cancel();
      _ridePollTimer = null;
    }
  }

  Future<void> _navigateToRating() async {
    if (_navigatingToRating) return;
    _navigatingToRating = true;

    // Fetch final ride to get server-confirmed distance/duration/addresses
    double? distKm;
    int?    durMin;
    String  fromAddr = widget.from;
    String  toAddr   = widget.to;
    String  payMethod    = 'cash';
    int?    baseFareKhr;
    int?    distFeeKhr;
    // Was set once at booking time — for a metered (no-destination) ride
    // the real fare isn't known until completion, so this starts as a
    // placeholder. Overwritten below once the fresh fare comes back.
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
        // Derive base fare and distance fee from total. Base fare is ~40%
        // of total; distance fee is the remainder (both pre-surge).
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
    // Fall back to live-tracked distance if the server didn't return one.
    if ((distKm == null || distKm <= 0) && _distanceKm > 0) {
      distKm = _distanceKm;
    }
    if (!mounted) return;
    // Dispose map before replacing route to avoid iOS
    // "recreating_view" PlatformException.
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
  }

  void _onFirestoreRideStatus(Map<String, dynamic> data) {
    // driver_id comes back as a Firestore integerValue (int), not a String
    // — a plain `as String?` cast throws the moment real data arrives.
    final status   = data['status'] as String? ?? '';
    final driverId = data['driver_id']?.toString() ?? '';

    // Deliberately NOT cancelling _ridePollTimer here — Firestore firing
    // once doesn't guarantee it'll fire again for later transitions (e.g.
    // "completed"), so the REST poll stays as the reliable fallback for
    // the whole trip.

    if (status.isNotEmpty && mounted) {
      _setRideStatus(status);
    }

    if (status == 'cancelled') {
      // Firestore's rides_live doc doesn't carry cancellation_reason — poll
      // immediately rather than waiting up to 5s for the next timer tick.
      _pollRide();
    }

    if (status == 'accepted' && driverId.isNotEmpty &&
        driverId != _currentDriverId) {
      // New driver assigned — re-subscribe to their live position
      _currentDriverId = driverId;
      _arrivingAlertShown = false;
      _driverPositionKnown = false;
      _firestoreSub?.cancel();
      _firestoreSub = LocationService.instance
          .listenDriver(driverId)
          .listen(_onDriverMarker);
      _notifyDriverFound();
      // Firestore's driver-location doc doesn't include name/vehicle/plate
      // — fetch those separately.
      _fetchDriverDetails();
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
    if (_etaSecondsLeft <= 0) return AppLocalizations.of(context).arrivingNow;
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
    _firestoreSub?.cancel();
    _rideStatusSub?.cancel();
    _mapController?.dispose();
    _pulseController.dispose();
    _markerAnimCtrl.dispose();
    super.dispose();
  }

  // ── Ride poll ──────────────────────────────────────────────────────────────
  // Detects driver assignment AND keeps syncing ride status for the whole
  // trip — Firestore's rides_live doc isn't reliably written by every
  // backend path, so this REST fallback is what actually guarantees the
  // passenger learns about status changes (e.g. "completed") even if
  // Firestore never fires. Only stops once the ride reaches a terminal
  // status (see _setRideStatus) or the screen is disposed.

  void _startRidePoll() {
    if (widget.rideId == null) return;
    _ridePollTimer =
        Timer.periodic(const Duration(seconds: 5), (_) => _pollRide());
  }

  Future<void> _pollRide() async {
    if (widget.rideId == null) return;
    try {
      final ride = await ApiService.getRide(widget.rideId!);
      if (!mounted) return;
      // Always sync server status
      if (ride.status.isNotEmpty) _setRideStatus(ride.status);
      if (ride.status == 'cancelled') {
        _handleServerCancellation(ride.cancellationReason);
        return;
      }
      if (ride.driverId == null) return;
      final newId = ride.driverId.toString();
      if (newId == _currentDriverId) return;
      setState(() {
        _currentDriverId = newId;
        _arrivingAlertShown = false;
        _driverPositionKnown = false;
        _applyDriverDetails(ride);
      });
      _afterDriverDetailsApplied(ride);
      _notifyDriverFound();
      _firestoreSub?.cancel();
      _firestoreSub = LocationService.instance
          .listenDriver(_currentDriverId)
          .listen(_onDriverMarker);
    } catch (e, s) {
      // This used to fail silently, so a persistent auth/network/parse
      // error here looked identical to "still searching for a driver" —
      // the passenger would be stuck on the loading screen forever with
      // no way to tell why. Logged so it's diagnosable; the timer keeps
      // retrying every 5s regardless.
      AppLog.e('TripTracking', 'pollRide(${widget.rideId}) failed', e, s);
    }
  }

  // Populates driver/vehicle display fields from a fetched RideModel.
  // Shared by the REST poll fallback and the Firestore status listener, so
  // plate/vehicle/name/rating get filled in regardless of which path
  // detects the driver assignment first.
  void _applyDriverDetails(RideModel ride) {
    _driverName      = ride.driver?.name ?? 'Driver #${ride.driverId}';
    _driverAvatarUrl = ride.driver?.photoUrl;
    _driverRating    = ride.driver?.rating != null
        ? ride.driver!.rating!.toStringAsFixed(1)
        : '--';
    _driverTrips     = ride.driver?.totalTrips != null
        ? ride.driver!.totalTrips!.toString()
        : '--';
    // Skip the model when it's identical to the make (e.g. tuk-tuks where
    // both are literally "Tuk Tuk") — avoids "Tuk Tuk Tuk Tuk". No year,
    // to match the "Color • Make Model" reference style.
    _vehicle      = ride.vehicle != null
        ? (ride.vehicle!.make.trim().toLowerCase() ==
                ride.vehicle!.model.trim().toLowerCase()
            ? ride.vehicle!.make
            : '${ride.vehicle!.make} ${ride.vehicle!.model}')
        : '--';
    _vehicleColor = ride.vehicle?.color ?? '';
    _vehiclePhotoUrl = (ride.vehicle?.vehicleUrl.isNotEmpty ?? false)
        ? ride.vehicle!.vehicleUrl
        : null;
    _plate        = ride.vehicle?.licensePlate ?? '--';
    if (ride.vehicle?.type != null) {
      final newType = DriverMarkerModel.normalise(ride.vehicle!.type);
      if (newType != _vehicleType) _vehicleType = newType;
    }
  }

  // Side effects that follow applying driver details — marker icon reload
  // and the masked phone number for the Call button.
  void _afterDriverDetailsApplied(RideModel ride) {
    if (ride.vehicle?.type != null) {
      MarkerIconService.forType(
          DriverMarkerModel.normalise(ride.vehicle!.type)).then((icon) {
        if (mounted) setState(() => _driverIcon = icon);
      });
    }
    if (widget.rideId != null) {
      ApiService.getMaskedPhone(widget.rideId!).then((phone) {
        if (mounted) setState(() => _driverPhone = phone);
      }).catchError((_) {});
    }
  }

  // Firestore reports a driver assignment faster than the REST poll, but
  // (unlike _pollRide) doesn't carry name/vehicle/plate/rating — fetch the
  // full ride once so those fields don't stay stuck at their placeholders.
  Future<void> _fetchDriverDetails() async {
    if (widget.rideId == null) return;
    try {
      final ride = await ApiService.getRide(widget.rideId!);
      if (!mounted) return;
      setState(() => _applyDriverDetails(ride));
      _afterDriverDetailsApplied(ride);
    } catch (e, s) {
      AppLog.e('TripTracking', 'fetchDriverDetails(${widget.rideId}) failed', e, s);
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static IconData _vehicleTypeIcon(String type) {
    switch (type) {
      case 'motorbike': return Icons.electric_rickshaw;
      case 'van':       return Icons.airport_shuttle;
      case 'truck':     return Icons.local_shipping;
      default:          return Icons.directions_car;
    }
  }

  // Status must not advance past "searching" until a driver is actually assigned.
  bool get _driverAssigned => _currentDriverId.isNotEmpty;

  bool get _isArrived => _driverAssigned && _rideStatus == 'driver_arrived';

  // Driver assigned and still en route to pick up the passenger — i.e. not
  // yet arrived and not already picked up/driving to the destination.
  bool get _isApproachingPickup =>
      _driverAssigned && !_isArrived && _rideStatus != 'in_progress';

  String get _statusTitle {
    if (!_driverAssigned)                return AppLocalizations.of(context).findingYourDriver;
    if (_rideStatus == 'driver_arrived') return AppLocalizations.of(context).driverHasArrived;
    if (_rideStatus == 'in_progress')    return AppLocalizations.of(context).tripInProgress2;
    if (_rideStatus == 'accepted')       return AppLocalizations.of(context).yourDriverIsOnThe;
    return AppLocalizations.of(context).driverAssignedConnecting;
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

          // ── Route card (top) — collapses to a chevron, Grab-style ──────
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: !_routeCardExpanded
                  ? GestureDetector(
                      onTap: () => setState(() => _routeCardExpanded = true),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: context.appSurface,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 10, offset: Offset(0, 4))
                          ],
                        ),
                        child: Icon(Icons.keyboard_arrow_down_rounded,
                            color: context.appTextPrimary, size: 22),
                      ),
                    )
                  : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                GestureDetector(
                  onTap: () => setState(() => _routeCardExpanded = false),
                  child: Container(
                    width: 40, height: 40,
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: context.appSurface,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 10, offset: Offset(0, 4))
                      ],
                    ),
                    child: Icon(Icons.keyboard_arrow_up_rounded,
                        color: context.appTextPrimary, size: 22),
                  ),
                ),
                Container(
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
                            child: Text(
                                getDisplayLocation(name: '', address: widget.from),
                                overflow: TextOverflow.ellipsis,
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
                          Text('${AppLocalizations.of(context).stop} ${i + 1}',
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
                        Text(AppLocalizations.of(context).dropoff,
                            style: TextStyle(
                                color: Colors.red,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ],
                ),
              ),
              ]),
            ),
          ),

          // ── Locating-driver banner ───────────────────────────────────
          // Shown on the map itself (not just the bottom sheet) whenever a
          // driver is assigned but Firestore hasn't received a live GPS
          // ping yet, so the passenger isn't left staring at a map with no
          // driver pin and no explanation why.
          if (_driverAssigned && !_driverPositionKnown)
            Positioned(
              top: 90,
              left: 0,
              right: 0,
              child: Center(
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
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    SizedBox(
                      width: 12, height: 12,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _kGreen),
                    ),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.of(context).locatingYourDriver,
                        style: TextStyle(
                            color: context.appTextPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ]),
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

          // ── Safety Centre pill ──────────────────────────────────────────
          Positioned(
            left: 14,
            bottom: 302,
            child: GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SafetyScreen())),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: context.appSurface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.shield_outlined, color: _kGreen, size: 16),
                  const SizedBox(width: 6),
                  Text(AppLocalizations.of(context).safetyCentre,
                      style: TextStyle(color: _kGreen,
                          fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
                ]),
              ),
            ),
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

                      // Status card — Grab-style: title + ETA on the right,
                      // next-address subtitle below.
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: context.appCardBg,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Expanded(
                              child: Text(_statusTitle,
                                  style: TextStyle(
                                      color: context.appTextPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800)),
                            ),
                            if (_driverAssigned)
                              Text(_isArrived ? 'Now' : '$eta min',
                                  style: TextStyle(
                                      color: context.appTextPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800)),
                          ]),
                          const SizedBox(height: 4),
                          Text(
                            !_driverAssigned
                                ? AppLocalizations.of(context).lookingForANearbyDriver
                                : (!_driverPositionKnown
                                    ? AppLocalizations.of(context).locatingYourDriver
                                    : (_hasWayStops &&
                                            _rideStatus == 'in_progress' &&
                                            _nextStopIndex < widget.wayStops.length
                                        ? 'Stop ${_nextStopIndex + 1} · $dist km'
                                        : (_rideStatus == 'in_progress' ? widget.to : widget.from))),
                            style: TextStyle(fontSize: 13, color: context.appTextSecondary),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                          // Per-stop ETA list (shown only during in_progress with stops)
                          if (_driverAssigned && _hasWayStops && _rideStatus == 'in_progress' &&
                              _stopEtas.isNotEmpty) ...[
                            SizedBox(height: 10),
                            _StopEtaList(
                              wayStops:       widget.wayStops,
                              destination:    widget.to,
                              nextStopIndex:  _nextStopIndex,
                              stopEtas:       _stopEtas,
                            ),
                          ],
                          // Fare — only shown when the ride has a set
                          // destination; a metered (no-destination) ride's
                          // final fare isn't known until it's completed.
                          if (widget.destLatLng != null) ...[
                            SizedBox(height: 8),
                            Row(children: [
                              Text(AppLocalizations.of(context).fare,
                                  style: TextStyle(fontSize: 13, color: context.appTextSecondary)),
                              const Spacer(),
                              Text(widget.fare,
                                  style: TextStyle(color: _kGreen,
                                      fontSize: 15, fontWeight: FontWeight.w800)),
                            ]),
                          ],
                        ]),
                      ),
                      SizedBox(height: 12),

                      // Driver card (avatar/plate/rating + chat/call) — only
                      // once a driver is actually assigned; nothing to show
                      // while still searching.
                      if (_driverAssigned) ...[
                      // Vehicle photo — full-width banner above the driver card.
                      if (_vehiclePhotoUrl != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: CachedNetworkImage(
                            imageUrl: _vehiclePhotoUrl!,
                            width: double.infinity,
                            height: 140,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => const SizedBox.shrink(),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      // Driver + Car (Grab-style: plate/vehicle up top, name+rating below)
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Stack(clipBehavior: Clip.none, children: [
                          CircleAvatar(
                            radius: 27,
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
                          Positioned(
                            right: -4, bottom: -4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: _kGreen,
                                shape: BoxShape.circle,
                                border: Border.all(color: context.appSurface, width: 2),
                              ),
                              child: Icon(_vehicleTypeIcon(_vehicleType),
                                  size: 13, color: Colors.white),
                            ),
                          ),
                        ]),
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_plate,
                                  style: TextStyle(
                                      color: context.appTextPrimary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 17)),
                              Text(
                                _vehicleColor.isNotEmpty
                                    ? '$_vehicleColor · $_vehicle'
                                    : _vehicle,
                                style: TextStyle(
                                    color: context.appTextSecondary, fontSize: 12),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 6),
                              Row(children: [
                                Expanded(
                                  child: Text(_driverName,
                                      style: TextStyle(
                                          color: context.appTextPrimary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14),
                                      maxLines: 1, overflow: TextOverflow.ellipsis),
                                ),
                                Icon(Icons.star,
                                    color: Color(0xFFFFA000), size: 14),
                                SizedBox(width: 3),
                                Text(_driverRating,
                                    style: TextStyle(
                                        color: context.appTextSecondary, fontSize: 13)),
                              ]),
                            ],
                          ),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      ],

                      // Call, Chat, Share, Cancel — all on one row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _ActionBtn(
                            icon:  Icons.call_outlined,
                            label: AppLocalizations.of(context).call,
                            onTap: _driverAssigned ? _callDriver : () {},
                            disabled: !_driverAssigned,
                          ),
                          _ActionBtn(
                            icon:  Icons.chat_bubble_outline,
                            label: AppLocalizations.of(context).chat,
                            onTap: _openRideChat,
                          ),
                          _ActionBtn(
                            icon:  _shareUrl != null
                                ? Icons.share_location
                                : Icons.share_outlined,
                            label: _shareUrl != null ? AppLocalizations.of(context).sharing : AppLocalizations.of(context).share,
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
                              label:   _cancelling ? '...' : AppLocalizations.of(context).cancel,
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
        myName:      saved?.name ?? AppLocalizations.of(context).passenger,
        otherName:   _driverName,
        isDriver:    false,
      ),
    ));
  }

  // Sharing only valid while ride is active (not yet completed/cancelled)
  bool get _canShare =>
      _driverAssigned &&
      _rideStatus != 'completed' &&
      _rideStatus != 'cancelled';

  // ── SOS ────────────────────────────────────────────────────────────────────

  Future<void> _sendSos() async {
    if (widget.rideId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(AppLocalizations.of(context).sendSOSQuestion,
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.w800)),
        content: Text(
            AppLocalizations.of(context).anSosAlertWillBe),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(AppLocalizations.of(context).cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: AppTheme.confirmButtonStyle(background: Colors.red),
            child: Text(AppLocalizations.of(context).sendSOS),
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
            : AppLocalizations.of(context).sosAlertSent),
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
          content: Text('${AppLocalizations.of(context).sosFailed}: $e'),
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context).driverPhoneNotAvailable),
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
        content: Text('${AppLocalizations.of(context).cannotDialPrefix} $phone ${AppLocalizations.of(context).onThisDevice}'),
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
          content: Text('${AppLocalizations.of(context).couldNotGenerateShareLink}: $e'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  void _shareLocationFallback() {
    final pickup = _pickupPoint;
    final text = AppLocalizations.of(context).iMOnMyWay +
        'From: ${widget.from}\nTo: ${widget.to}\n'
            'Track pickup: https://maps.google.com/?q=${pickup.latitude},${pickup.longitude}';
    final box = context.findRenderObject() as RenderBox?;
    Share.share(text,
        subject: AppLocalizations.of(context).myRotehTrip,
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
      label: AppLocalizations.of(context).destination,
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
                child: Text('${r.etaMinutes} ${AppLocalizations.of(context).min}',
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
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      content: Text(AppLocalizations.of(ctx).linkCopied),
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: 2),
    ));
  }

  void _shareNative(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    Share.share(
      AppLocalizations.of(context).trackMyRotehTripLive +
          'Driver: $driverName · ETA: $etaMinutes min\n'
              'From: $from\nTo: $to\n\n$url',
      subject: AppLocalizations.of(context).trackMyRideLive,
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
              Text(AppLocalizations.of(context).shareTrip, style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w700, color: context.appTextPrimary)),
              Text(AppLocalizations.of(context).friendsCanTrack,
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
                Text('${AppLocalizations.of(context).driverLabel}: $driverName',
                    style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
                Spacer(),
                Icon(Icons.timer_outlined, color: context.appTextSecondary, size: 14),
                SizedBox(width: 4),
                Text('${AppLocalizations.of(context).eta} $etaMinutes ${AppLocalizations.of(context).min}',
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
                Icon(Icons.link_rounded, color: _kGreen, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text(url,
                    style: TextStyle(
                      color: _kGreen, fontSize: 12, fontWeight: FontWeight.w500),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 8),
                Icon(Icons.copy_rounded, color: _kGreen, size: 16),
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
                label: Text(AppLocalizations.of(context).copyLink),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kGreen,
                  side: BorderSide(color: _kGreen),
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
                label: Text(AppLocalizations.of(context).shareVia),
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
            child: Text(AppLocalizations.of(context).stopSharingLocation,
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
  // Built per-frame rather than held as a static, so the reasons follow the
  // active locale.
  List<String> _reasonsFor(AppLocalizations l) => [
    l.changedMyMind,
    l.driverIsTakingTooLong,
    l.wrongPickupLocation,
    l.foundAnotherRide,
    l.emergencyCameUp,
    l.other,
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
          Text(AppLocalizations.of(context).cancelRide,
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          SizedBox(height: 4),
          Text(
            widget.hasFee
                ? AppLocalizations.of(context).driverHasArrivedA2
                : AppLocalizations.of(context).pleaseTellUsWhyYou,
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ]),
      ),
      contentPadding: EdgeInsets.symmetric(vertical: 8),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: _reasonsFor(AppLocalizations.of(context))
            .map((r) => RadioListTile<String>(
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
          child: Text(AppLocalizations.of(context).keepRide,
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
            widget.hasFee ? AppLocalizations.of(context).cancel2000Fee : AppLocalizations.of(context).cancelRide,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
