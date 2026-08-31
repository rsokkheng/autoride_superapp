import 'package:autoride_superapp/l10n/app_localizations.dart';
import 'dart:async';
import 'dart:math' show pi, sin, cos, atan2;
import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';
import '../../services/maps_service.dart';
import '../../models/delivery_model.dart';
import '../shared/ride_chat_screen.dart';
import 'driver_delivery_summary_screen.dart';

// Default Phnom Penh centre — used until GPS fix obtained
const _kPhnomPenh = LatLng(11.5680, 104.9195);

// Delivery workflow
enum _DeliveryPhase {
  headingToPickup,   // driver going to sender
  arrivedAtPickup,   // driver at sender, waiting to pick up
  inTransit,         // en-route to dropoff
  completed,
}

// Moving workflow
enum _MovingPhase {
  headingToLocation,  // going to the moving origin
  arrivedAtLocation,  // at origin, loading
  inTransit,          // driving to new location
  completed,
}

class DriverDeliveryActiveScreen extends StatefulWidget {
  final DeliveryModel delivery;
  final String driverIdStr;
  /// When true: map + details shown but no action buttons (view from Missions)
  final bool readOnly;

  const DriverDeliveryActiveScreen({
    super.key,
    required this.delivery,
    required this.driverIdStr,
    this.readOnly = false,
  });

  @override
  State<DriverDeliveryActiveScreen> createState() =>
      _DriverDeliveryActiveScreenState();
}

class _DriverDeliveryActiveScreenState
    extends State<DriverDeliveryActiveScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {

  GoogleMapController? _mapController;
  late AnimationController _markerAnimCtrl;

  // Phase — derived from delivery.status so resuming from Missions is correct
  late _DeliveryPhase _deliveryPhase;
  late _MovingPhase   _movingPhase;
  bool get _isMoving => widget.delivery.isMoving;

  // GPS
  LatLng? _driverLatLng;
  LatLng? _prevDriverPos;
  LatLng? _targetDriverPos;
  double  _driverHeading = 0;

  // Route
  int    _etaMinutes = 0;
  double _distanceKm = 0;

  // UI state
  bool _acting       = false;
  bool _completed    = false;
  DateTime? _lastBackendPush;

  // Map data
  final Set<Marker>   _markers   = {};
  final Set<Polyline> _polylines = {};

  // Real coords from model — fallback to Phnom Penh centre if null
  static const _kFallback = LatLng(11.5680, 104.9195);

  LatLng get _pickupLatLng => (widget.delivery.pickupLat != null && widget.delivery.pickupLng != null)
      ? LatLng(widget.delivery.pickupLat!, widget.delivery.pickupLng!)
      : _kFallback;

  LatLng get _dropoffLatLng => (widget.delivery.dropoffLat != null && widget.delivery.dropoffLng != null)
      ? LatLng(widget.delivery.dropoffLat!, widget.delivery.dropoffLng!)
      : _kFallback;

  bool get _headingToPickup =>
      _isMoving
          ? _movingPhase == _MovingPhase.headingToLocation
          : _deliveryPhase == _DeliveryPhase.headingToPickup;

  LatLng get _currentDestination =>
      _headingToPickup ? _pickupLatLng : _dropoffLatLng;

  @override
  void initState() {
    super.initState();
    _deliveryPhase = _phaseFromStatus(widget.delivery.status);
    _movingPhase   = _movingPhaseFromStatus(widget.delivery.status);

    _markerAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..addListener(_onMarkerAnimTick);

    _initStaticMarkers();
    if (!widget.readOnly) _startTracking();
    WidgetsBinding.instance.addObserver(this);
  }

  static _DeliveryPhase _phaseFromStatus(String status) {
    switch (status) {
      case 'in_progress': return _DeliveryPhase.inTransit;
      case 'completed':   return _DeliveryPhase.completed;
      default:            return _DeliveryPhase.headingToPickup;
    }
  }

  static _MovingPhase _movingPhaseFromStatus(String status) {
    switch (status) {
      case 'in_progress': return _MovingPhase.inTransit;
      case 'completed':   return _MovingPhase.completed;
      default:            return _MovingPhase.headingToLocation;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _markerAnimCtrl.dispose();
    if (!widget.readOnly) LocationService.instance.stopTracking(widget.driverIdStr);
    _mapController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _onAppResumed();
  }

  void _onAppResumed() {
    if (!mounted || widget.readOnly || _completed) return;
    // Force map widget redraw (fixes tile blank on iOS after lock screen)
    setState(() {});
    // Restart GPS stream in case the OS paused it
    _startTracking();
    // Re-fetch route and restore camera with last known position
    if (_driverLatLng != null) {
      _fetchLiveRoute(_driverLatLng!);
      Future.delayed(const Duration(milliseconds: 300),
          () => mounted ? _fitToDriver() : null);
    }
  }

  // ── Map markers ───────────────────────────────────────────────────────────

  void _initStaticMarkers() {
    _markers.addAll([
      Marker(
        markerId: const MarkerId('pickup'),
        position: _pickupLatLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: _isMoving
              ? AppLocalizations.of(context).movingFrom
              : AppLocalizations.of(context).pickup,
          snippet: widget.delivery.pickupAddress,
        ),
      ),
      Marker(
        markerId: const MarkerId('dropoff'),
        position: _dropoffLatLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: _isMoving
              ? AppLocalizations.of(context).movingTo
              : AppLocalizations.of(context).dropoff,
          snippet: widget.delivery.dropoffAddress,
        ),
      ),
    ]);

    // Context dashed line
    _polylines.add(Polyline(
      polylineId: const PolylineId('context_route'),
      points:     [_pickupLatLng, _dropoffLatLng],
      color:      const Color(0x44888888),
      width:      3,
      patterns:   [PatternItem.dash(14), PatternItem.gap(8)],
    ));
  }

  // ── GPS tracking ──────────────────────────────────────────────────────────

  Future<void> _startTracking() async {
    final granted = await LocationService.instance.requestPermission();
    if (!granted || !mounted) return;

    // Draw an initial route immediately using last known position so the
    // line appears even if the driver hasn't moved 5 m yet.
    final last = await Geolocator.getLastKnownPosition();
    if (last != null && mounted && _inCambodia(last.latitude, last.longitude)) {
      _onDriverPosition(last);
    }

    LocationService.instance.startTracking(
      driverId:    widget.driverIdStr,
      onPosition:  _onDriverPosition,
      vehicleType: widget.delivery.vehicleType ?? 'motorbike',
    );
  }

  void _onDriverPosition(Position position) {
    if (!mounted) return;
    if (!_inCambodia(position.latitude, position.longitude)) return;

    final pos     = LatLng(position.latitude, position.longitude);
    final prevPos = _driverLatLng;

    _driverHeading = (prevPos != null && prevPos != pos)
        ? _bearing(prevPos, pos)
        : position.heading;

    _prevDriverPos   = _targetDriverPos ?? pos;
    _targetDriverPos = pos;
    _driverLatLng    = pos;

    _markerAnimCtrl
      ..stop()
      ..forward(from: 0);

    _pushLocationToBackend(position);
    _fetchLiveRoute(pos);
  }

  void _onMarkerAnimTick() {
    final prev   = _prevDriverPos;
    final target = _targetDriverPos;
    if (prev == null || target == null || !mounted) return;
    final t   = _markerAnimCtrl.value;
    final lat = lerpDouble(prev.latitude,  target.latitude,  t)!;
    final lng = lerpDouble(prev.longitude, target.longitude, t)!;
    if (mounted) setState(() {
      _markers.removeWhere((m) => m.markerId.value == 'driver');
      _markers.add(Marker(
        markerId:   const MarkerId('driver'),
        position:   LatLng(lat, lng),
        icon:       BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: InfoWindow(title: AppLocalizations.of(context).you),
        rotation:   _driverHeading,
        anchor:     const Offset(0.5, 0.5),
        flat:       true,
      ));
    });
  }

  // ── Route ─────────────────────────────────────────────────────────────────

  Future<void> _fetchLiveRoute(LatLng driverPos) async {
    final result = await MapsService.getRoute(
      origin:      driverPos,
      destination: _currentDestination,
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

  // ── Chat ──────────────────────────────────────────────────────────────────

  Future<void> _openChat() async {
    final saved = await ApiService.getSavedUser();
    if (!mounted) return;
    final driverId    = int.tryParse(widget.driverIdStr) ?? (saved?.id ?? 0);
    final passengerId = widget.delivery.senderId;
    final senderName  = widget.delivery.sender?.name
        ?? widget.delivery.senderName
        ?? '${AppLocalizations.of(context).senderNumberPrefix}$passengerId';
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => RideChatScreen(
        rideId:      'delivery-${widget.delivery.id}',
        driverId:    driverId,
        passengerId: passengerId,
        myId:        driverId,
        myName:      saved?.name ?? AppLocalizations.of(context).driver,
        otherName:   senderName,
        isDriver:    true,
      ),
    ));
  }

  // ── Backend location push ──────────────────────────────────────────────────

  void _pushLocationToBackend(Position pos) {
    final now = DateTime.now();
    if (_lastBackendPush != null &&
        now.difference(_lastBackendPush!).inSeconds < 10) return;
    _lastBackendPush = now;

    if (_isMoving) {
      ApiService.updateMovingLocation(
        widget.delivery.id,
        latitude:  pos.latitude,
        longitude: pos.longitude,
        heading:   pos.heading,
      );
    } else {
      ApiService.updateDeliveryLocation(
        widget.delivery.id,
        latitude:  pos.latitude,
        longitude: pos.longitude,
        heading:   pos.heading,
      );
    }
  }

  // ── Map camera ─────────────────────────────────────────────────────────────

  void _fitToDriver() {
    final driver = _driverLatLng;
    if (driver == null) return;
    final dest   = _currentDestination;
    final minLat = driver.latitude  < dest.latitude  ? driver.latitude  : dest.latitude;
    final maxLat = driver.latitude  > dest.latitude  ? driver.latitude  : dest.latitude;
    final minLng = driver.longitude < dest.longitude ? driver.longitude : dest.longitude;
    final maxLng = driver.longitude > dest.longitude ? driver.longitude : dest.longitude;
    _mapController?.animateCamera(CameraUpdate.newLatLngBounds(
      LatLngBounds(
        southwest: LatLng(minLat - 0.006, minLng - 0.006),
        northeast: LatLng(maxLat + 0.006, maxLng + 0.006),
      ),
      72,
    ));
  }

  // ── Workflow actions ───────────────────────────────────────────────────────

  Future<void> _onActionTap() async {
    if (_acting) return;
    setState(() => _acting = true);

    try {
      if (_isMoving) {
        await _movingAction();
      } else {
        await _deliveryAction();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.message),
          backgroundColor: AppTheme.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } catch (_) {
      // silently fail non-API errors (network timeouts etc)
    } finally {
      if (mounted && !_completed) setState(() => _acting = false);
    }
  }

  Future<void> _deliveryAction() async {
    switch (_deliveryPhase) {
      case _DeliveryPhase.headingToPickup:
        // Mark arrived at pickup — no separate API endpoint; we just advance the UI phase
        // and optionally send a status ping via startDelivery if the server supports it
        setState(() => _deliveryPhase = _DeliveryPhase.arrivedAtPickup);
        _showPhaseSnack(AppLocalizations.of(context).youArrivedAtPickupLocation);
        break;

      case _DeliveryPhase.arrivedAtPickup:
        await ApiService.startDelivery(widget.delivery.id);
        setState(() {
          _deliveryPhase = _DeliveryPhase.inTransit;
          // Refresh route to dropoff
          if (_driverLatLng != null) _fetchLiveRoute(_driverLatLng!);
        });
        _showPhaseSnack(AppLocalizations.of(context).packagePickedUpHeadingToDropoff);
        break;

      case _DeliveryPhase.inTransit:
        DeliveryModel? completedDelivery;
        try {
          completedDelivery = await ApiService.completeDelivery(widget.delivery.id);
        } catch (_) {}
        setState(() {
          _deliveryPhase = _DeliveryPhase.completed;
          _completed     = true;
        });
        await _showCompleteSummary(completedDelivery ?? widget.delivery);
        break;

      case _DeliveryPhase.completed:
        break;
    }
  }

  Future<void> _movingAction() async {
    switch (_movingPhase) {
      case _MovingPhase.headingToLocation:
        setState(() => _movingPhase = _MovingPhase.arrivedAtLocation);
        _showPhaseSnack(AppLocalizations.of(context).arrivedAtMovingLocationStartLoading);
        break;

      case _MovingPhase.arrivedAtLocation:
        await ApiService.startMoving(widget.delivery.id);
        setState(() {
          _movingPhase = _MovingPhase.inTransit;
          if (_driverLatLng != null) _fetchLiveRoute(_driverLatLng!);
        });
        _showPhaseSnack(AppLocalizations.of(context).loadingCompleteHeadingToNewLocation);
        break;

      case _MovingPhase.inTransit:
        DeliveryModel? completedDelivery;
        try {
          completedDelivery = await ApiService.completeMoving(widget.delivery.id);
        } catch (_) {}
        setState(() {
          _movingPhase = _MovingPhase.completed;
          _completed   = true;
        });
        await _showCompleteSummary(completedDelivery ?? widget.delivery);
        break;

      case _MovingPhase.completed:
        break;
    }
  }

  void _showPhaseSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppTheme.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ));
  }

  Future<void> _showCompleteSummary([DeliveryModel? delivery]) async {
    LocationService.instance.stopTracking(widget.driverIdStr);
    final targetDelivery = delivery ?? widget.delivery;
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DriverDeliverySummaryScreen(delivery: targetDelivery),
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static bool _inCambodia(double lat, double lng) =>
      lat >= 10.4 && lat <= 14.7 && lng >= 102.3 && lng <= 107.6;

  static double _bearing(LatLng from, LatLng to) {
    final lat1 = from.latitude  * pi / 180;
    final lat2 = to.latitude    * pi / 180;
    final dLng = (to.longitude - from.longitude) * pi / 180;
    final y    = sin(dLng) * cos(lat2);
    final x    = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLng);
    return (atan2(y, x) * 180 / pi + 360) % 360;
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        // ── Map ──────────────────────────────────────────────────────────────
        GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: _kPhnomPenh,
            zoom: 14,
          ),
          markers:              _markers,
          polylines:            _polylines,
          myLocationEnabled:    false,
          myLocationButtonEnabled: false,
          zoomControlsEnabled:  false,
          mapToolbarEnabled:    false,
          onMapCreated: (c) {
            _mapController = c;
            _fitToDriver();
            if (_driverLatLng != null) _fetchLiveRoute(_driverLatLng!);
          },
        ),

        // ── Top bar ───────────────────────────────────────────────────────────
        SafeArea(child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            _MapButton(
              icon: Icons.arrow_back,
              onTap: () => Navigator.of(context).pop(),
            ),
            const Spacer(),
            // ETA chip
            if (_driverLatLng != null) _EtaChip(
              etaMin:     _etaMinutes,
              distanceKm: _distanceKm,
            ),
            const SizedBox(width: 8),
            _MapButton(
              icon: Icons.chat_bubble_outline,
              onTap: _openChat,
            ),
            const SizedBox(width: 8),
            _MapButton(
              icon: Icons.my_location,
              onTap: _fitToDriver,
            ),
          ]),
        )),

        // ── Bottom sheet ──────────────────────────────────────────────────────
        Positioned(
          left: 0, right: 0, bottom: 0,
          child: _BottomPanel(
            delivery:      widget.delivery,
            isMoving:      _isMoving,
            deliveryPhase: _deliveryPhase,
            movingPhase:   _movingPhase,
            acting:        _acting,
            onAction:      _onActionTap,
            etaMinutes:    _etaMinutes,
            readOnly:      widget.readOnly,
          ),
        ),
      ]),
    );
  }
}

// ─── ETA chip ─────────────────────────────────────────────────────────────────

class _EtaChip extends StatelessWidget {
  final int    etaMin;
  final double distanceKm;
  const _EtaChip({required this.etaMin, required this.distanceKm});

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: context.appSurface,
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [BoxShadow(color: Color(0x18000000), blurRadius: 8)],
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.access_time, size: 14, color: AppTheme.accentOrange),
      SizedBox(width: 4),
      Text(
        etaMin > 0 ? '$etaMin ${AppLocalizations.of(context).minShort}' : AppLocalizations.of(context).arriving,
        style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w700, fontSize: 13),
      ),
      if (distanceKm > 0) ...[
        const SizedBox(width: 6),
        Text(
          '· ${distanceKm.toStringAsFixed(1)} km',
          style: TextStyle(color: context.appTextSecondary, fontSize: 12),
        ),
      ],
    ]),
  );
}

// ─── Map icon button ──────────────────────────────────────────────────────────

class _MapButton extends StatelessWidget {
  final IconData  icon;
  final VoidCallback onTap;
  const _MapButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        color: context.appSurface,
        shape: BoxShape.circle,
        boxShadow: const [BoxShadow(color: Color(0x18000000), blurRadius: 8)],
      ),
      child: Icon(icon, color: context.appTextPrimary, size: 20),
    ),
  );
}

// ─── Bottom panel ─────────────────────────────────────────────────────────────

class _BottomPanel extends StatelessWidget {
  final DeliveryModel   delivery;
  final bool            isMoving;
  final _DeliveryPhase  deliveryPhase;
  final _MovingPhase    movingPhase;
  final bool            acting;
  final VoidCallback    onAction;
  final int             etaMinutes;
  final bool            readOnly;

  const _BottomPanel({
    required this.delivery,
    required this.isMoving,
    required this.deliveryPhase,
    required this.movingPhase,
    required this.acting,
    required this.onAction,
    required this.etaMinutes,
    this.readOnly = false,
  });

  // ── Delivery workflow labels ───────────────────────────────────────────────

  String _buttonLabel(AppLocalizations l) {
    if (isMoving) {
      switch (movingPhase) {
        case _MovingPhase.headingToLocation: return l.arrivedAtLocation;
        case _MovingPhase.arrivedAtLocation: return l.loadingComplete;
        case _MovingPhase.inTransit:         return l.markAsDelivered;
        case _MovingPhase.completed:         return l.done;
      }
    }
    switch (deliveryPhase) {
      case _DeliveryPhase.headingToPickup:  return l.arrivedAtPickup;
      case _DeliveryPhase.arrivedAtPickup:  return l.packagePickedUp;
      case _DeliveryPhase.inTransit:        return l.markAsDelivered;
      case _DeliveryPhase.completed:        return l.done;
    }
  }

  String _statusLabel(AppLocalizations l) {
    if (isMoving) {
      switch (movingPhase) {
        case _MovingPhase.headingToLocation: return l.headingToPickupLocation;
        case _MovingPhase.arrivedAtLocation: return l.atLocationLoadingItems;
        case _MovingPhase.inTransit:         return l.inTransitToNewLocation;
        case _MovingPhase.completed:         return l.movingCompleteExcl;
      }
    }
    switch (deliveryPhase) {
      case _DeliveryPhase.headingToPickup: return l.headingToSender;
      case _DeliveryPhase.arrivedAtPickup: return l.atPickupCollectPackage;
      case _DeliveryPhase.inTransit:       return l.onTheWayToRecipient;
      case _DeliveryPhase.completed:       return l.deliveredExcl;
    }
  }

  bool get _isDone =>
      (isMoving && movingPhase == _MovingPhase.completed) ||
      (!isMoving && deliveryPhase == _DeliveryPhase.completed);

  List<String> _steps(AppLocalizations l) => isMoving
      ? [l.heading, l.atLocation, l.inTransit, l.done]
      : [l.heading, l.atPickup, l.inTransit, l.delivered];

  int get _currentStep {
    if (isMoving) return movingPhase.index;
    return deliveryPhase.index;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appSurface,
        boxShadow: [BoxShadow(color: Color(0x18000000), blurRadius: 16, offset: Offset(0, -4))],
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Handle
        Center(child: Container(
          width: 36, height: 4,
          decoration: BoxDecoration(
              color: context.appCardBg, borderRadius: BorderRadius.circular(2)),
        )),
        SizedBox(height: 14),

        // Progress stepper
        _MiniStepper(steps: _steps(AppLocalizations.of(context)), currentStep: _currentStep),
        SizedBox(height: 14),

        // Status label
        Row(children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              color: _isDone ? AppTheme.success : AppTheme.accentOrange,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(_statusLabel(AppLocalizations.of(context)),
                style: TextStyle(
                    color: context.appTextPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15)),
          ),
          if (etaMinutes > 0 && !_isDone)
            Text('$etaMinutes ${AppLocalizations.of(context).minAway}',
                style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
        ]),
        SizedBox(height: 12),

        // Route info
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: context.appCardBg, borderRadius: BorderRadius.circular(12)),
          child: Column(children: [
            Row(children: [
              Icon(Icons.circle, color: AppTheme.success, size: 8),
              SizedBox(width: 8),
              Expanded(child: Text(delivery.pickupAddress,
                  style: TextStyle(color: context.appTextSecondary, fontSize: 12),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
            ]),
            Container(margin: EdgeInsets.only(left: 3),
                width: 2, height: 10, color: context.appCardBg),
            Row(children: [
              Icon(Icons.location_on, color: AppTheme.accentOrange, size: 10),
              SizedBox(width: 8),
              Expanded(child: Text(delivery.dropoffAddress,
                  style: TextStyle(color: context.appTextSecondary, fontSize: 12),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
            ]),
          ]),
        ),
        const SizedBox(height: 12),

        // Recipient info
        if (delivery.recipientName != null || delivery.recipientPhone != null)
          _RecipientRow(
            name:  delivery.recipientName,
            phone: delivery.recipientPhone,
          ),

        // Action button — hidden in read-only (Missions view) mode
        if (!_isDone && !readOnly)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: acting ? null : onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
                textStyle: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 15),
              ),
              child: acting
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(_buttonLabel(AppLocalizations.of(context))),
            ),
          ),

        // Read-only view-only notice
        if (readOnly && !_isDone)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              Icon(Icons.info_outline, color: AppTheme.accent, size: 16),
              SizedBox(width: 8),
              Expanded(child: Text(
                AppLocalizations.of(context).toUpdateProgressContinueFrom,
                style: TextStyle(color: AppTheme.accent, fontSize: 12),
              )),
            ]),
          ),
      ]),
    );
  }
}

// ─── Mini stepper ─────────────────────────────────────────────────────────────

class _MiniStepper extends StatelessWidget {
  final List<String> steps;
  final int          currentStep;
  const _MiniStepper({required this.steps, required this.currentStep});

  @override
  Widget build(BuildContext context) => Row(
    children: List.generate(steps.length, (i) {
      final done   = i < currentStep;
      final active = i == currentStep;
      return Expanded(child: Column(children: [
        Row(children: [
          if (i > 0) Expanded(child: Container(
            height: 2,
            color: done || active ? AppTheme.success : context.appCardBg,
          )),
          Container(
            width: 16, height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? AppTheme.success : active ? AppTheme.accentOrange : context.appCardBg,
              border: Border.all(
                color: done ? AppTheme.success : active ? AppTheme.accentOrange
                    : context.appTextSecondary.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Center(
              child: done
                  ? Icon(Icons.check, size: 9, color: Colors.white)
                  : active
                      ? Container(width: 6, height: 6, decoration: BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle))
                      : null,
            ),
          ),
          if (i < steps.length - 1) Expanded(child: Container(
            height: 2,
            color: done ? AppTheme.success : context.appCardBg,
          )),
        ]),
        SizedBox(height: 3),
        Text(steps[i],
          textAlign: TextAlign.center,
          style: TextStyle(
            color: done || active ? context.appTextPrimary : context.appTextSecondary,
            fontSize: 9,
            fontWeight: active ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ]));
    }),
  );
}

// ─── Recipient row ────────────────────────────────────────────────────────────

class _RecipientRow extends StatelessWidget {
  final String? name;
  final String? phone;
  const _RecipientRow({this.name, this.phone});

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: 12),
    child: Row(children: [
      Container(
        padding: EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: AppTheme.accent.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.person_outline, color: AppTheme.accent, size: 18),
      ),
      SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (name != null)
          Text(name!, style: TextStyle(
              color: context.appTextPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        if (phone != null)
          Text(phone!, style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
      ])),
      if (phone != null)
        GestureDetector(
          onTap: () {/* dial phone */},
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.phone, color: AppTheme.success, size: 18),
          ),
        ),
    ]),
  );
}
