import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../utils/app_log.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../theme/app_theme.dart';
import '../../services/location_service.dart';
import '../../services/maps_service.dart';
import '../../services/notification_service.dart';
import '../../services/api_service.dart';
import 'trip_tracking_screen.dart';
import 'promo_screen.dart';

const _kCambodiaSW = LatLng(10.4, 102.3);
const _kCambodiaNE = LatLng(14.7, 107.6);
final _kCambodiaBounds = LatLngBounds(southwest: _kCambodiaSW, northeast: _kCambodiaNE);

bool _isInCambodia(LatLng p) =>
    p.latitude  >= _kCambodiaSW.latitude  && p.latitude  <= _kCambodiaNE.latitude &&
    p.longitude >= _kCambodiaSW.longitude && p.longitude <= _kCambodiaNE.longitude;

const _kPresets = [
  _Preset('Phnom Penh International Airport', LatLng(11.5462, 104.8440)),
  _Preset('Royal Palace',                     LatLng(11.5644, 104.9301)),
  _Preset('Aeon Mall Sen Sok',                LatLng(11.5878, 104.8978)),
  _Preset('Toul Tom Pong Market',             LatLng(11.5486, 104.9177)),
  _Preset('Night Market (Riverside)',         LatLng(11.5648, 104.9295)),
];

class _Preset {
  final String name;
  final LatLng latLng;
  const _Preset(this.name, this.latLng);
}

class _WayStop {
  String  address = '';
  LatLng? latLng;
  bool get isFilled => latLng != null && address.isNotEmpty;
}

class _RideType {
  final String name, serviceType, eta, desc;
  final IconData icon;
  const _RideType({
    required this.name,
    required this.serviceType,
    required this.icon,
    required this.eta,
    required this.desc,
  });
}

const _kRideTypes = [
  _RideType(name: 'Standard', serviceType: 'standard',   icon: Icons.directions_car,      eta: '4 min', desc: '4 seats'),
  _RideType(name: 'Premium',  serviceType: 'premium',    icon: Icons.local_taxi,          eta: '6 min', desc: 'Luxury'),
  _RideType(name: 'Shared',   serviceType: 'shared',     icon: Icons.airport_shuttle,     eta: '8 min', desc: 'Shared'),
  _RideType(name: 'Van',      serviceType: 'van',        icon: Icons.directions_bus,      eta: '6 min', desc: '6+ seats'),
];

// ─── Screen ───────────────────────────────────────────────────────────────────
// step 0 = "Where to?" landing   step 1 = destination search   step 2 = confirm

class RideBookingScreen extends StatefulWidget {
  const RideBookingScreen({super.key});
  @override
  State<RideBookingScreen> createState() => _RideBookingScreenState();
}

class _RideBookingScreenState extends State<RideBookingScreen> {
  int _step = 0;

  // ── Pickup ──────────────────────────────────────────────────────────────────
  GoogleMapController? _pickupMapCtrl;
  LatLng _pickupCenter  = const LatLng(11.5680, 104.9195);
  String _pickupAddress = 'Detecting location…';
  bool   _gpsLoading    = false;
  bool   _geocodingPickup = false;

  // ── Destination search ──────────────────────────────────────────────────────
  final _searchCtrl = TextEditingController();
  List<PlaceResult> _searchResults = [];
  bool   _searching  = false;
  Timer? _searchDebounce;
  // Multiple drop-off stops — last stop is always the final destination
  final List<_WayStop> _stops = [_WayStop()];
  int    _activeStopIdx = 0;
  int    _whereToTab    = 0; // 0=Recent  1=Suggestions  2=Saved

  // Getters for backward-compat with route/booking methods
  String  get _destAddress => _stops.last.address;
  LatLng? get _destLatLng  => _stops.last.latLng;

  // ── Destination map picker ──────────────────────────────────────────────────
  bool   _choosingDestOnMap = false;
  GoogleMapController? _destMapCtrl;
  LatLng _destMapCenter  = const LatLng(11.5680, 104.9195);
  String _mapPickerAddress = '';
  bool   _geocodingDest  = false;

  // ── Confirm ─────────────────────────────────────────────────────────────────
  GoogleMapController? _confirmMapCtrl;
  List<LatLng> _routePoints = [];
  int    _etaMinutes  = 0;
  double _distanceKm  = 0.0;
  bool   _routeLoading = false;
  Map<String, FareInfo> _fareByType  = {};
  bool                  _fareLoading = false;

  String   _selectedRide    = 'Standard';
  String   _paymentMethod   = 'cash';
  bool     _isScheduled     = false;
  DateTime _scheduledTime   = DateTime.now().add(const Duration(hours: 1));
  bool     _isBooking       = false;
  String?  _bookError;

  // ── Lifecycle ────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    _detectGps();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchDebounce?.cancel();
    _pickupMapCtrl?.dispose();
    _destMapCtrl?.dispose();
    _confirmMapCtrl?.dispose();
    super.dispose();
  }

  // ── GPS ──────────────────────────────────────────────────────────────────────

  Future<void> _detectGps() async {
    setState(() { _gpsLoading = true; _pickupAddress = 'Detecting location…'; });
    try {
      final granted = await LocationService.instance.requestPermission();
      if (!granted || !mounted) {
        setState(() { _gpsLoading = false; _pickupAddress = 'Location permission denied'; });
        return;
      }

      // Show last known position instantly — but only if it is recent (< 5 min).
      // A stale cache would show a location from hours ago, which is misleading.
      final last = await Geolocator.getLastKnownPosition();
      if (last != null && mounted) {
        final age = DateTime.now().difference(last.timestamp);
        final lastLatLng = LatLng(last.latitude, last.longitude);
        if (age.inMinutes < 5 && _isInCambodia(lastLatLng)) {
          setState(() => _pickupCenter = lastLatLng);
          _pickupMapCtrl?.animateCamera(CameraUpdate.newLatLng(lastLatLng));
          _reverseGeocodePickup(lastLatLng);
        }
      }

      // Upgrade to accurate current position.
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 15));
      if (!mounted) return;
      final latLng = LatLng(pos.latitude, pos.longitude);
      if (!_isInCambodia(latLng)) {
        setState(() { _gpsLoading = false; _pickupAddress = 'Tap map to set pickup'; });
        return;
      }
      setState(() { _pickupCenter = latLng; _gpsLoading = false; });
      _pickupMapCtrl?.animateCamera(CameraUpdate.newLatLng(latLng));
      _reverseGeocodePickup(latLng);
    } catch (e, s) {
      AppLog.e('GPS', 'Location detection failed', e, s);
      if (mounted) setState(() { _gpsLoading = false; _pickupAddress = 'Tap map to set pickup'; });
    }
  }

  Future<void> _geocodeMapCenter() async {
    setState(() => _geocodingDest = true);
    final address = await MapsService.reverseGeocode(_destMapCenter);
    if (!mounted) return;
    setState(() {
      _mapPickerAddress = address ??
          '${_destMapCenter.latitude.toStringAsFixed(4)}, ${_destMapCenter.longitude.toStringAsFixed(4)}';
      _geocodingDest = false;
    });
  }

  Future<void> _reverseGeocodePickup(LatLng pos) async {
    setState(() => _geocodingPickup = true);
    final address = await MapsService.reverseGeocode(pos);
    if (!mounted) return;
    setState(() {
      _pickupAddress  = address ?? '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
      _geocodingPickup = false;
    });
  }

  // ── Search ───────────────────────────────────────────────────────────────────

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) {
      setState(() { _searchResults = []; _searching = false; });
      return;
    }
    setState(() {}); // rebuild to show/hide clear button
    _searchDebounce = Timer(const Duration(milliseconds: 500), () => _searchPlaces(q));
  }

  Future<void> _searchPlaces(String q) async {
    setState(() => _searching = true);
    final results = await MapsService.searchAddress(q);
    if (!mounted) return;
    setState(() { _searchResults = results; _searching = false; });
  }

  void _selectResult(PlaceResult r) {
    setState(() {
      _stops[_activeStopIdx].address = r.address;
      _stops[_activeStopIdx].latLng  = r.latLng;
    });
    _afterStopFilled();
  }

  void _selectPreset(_Preset p) {
    setState(() {
      _stops[_activeStopIdx].address = p.name;
      _stops[_activeStopIdx].latLng  = p.latLng;
    });
    _afterStopFilled();
  }

  void _afterStopFilled() {
    final next = _stops.indexWhere((s) => !s.isFilled, _activeStopIdx + 1);
    if (next == -1) {
      // All stops are filled. Keep focus on the last stop and allow editing.
      setState(() { _searchCtrl.clear(); });
    } else {
      setState(() { _activeStopIdx = next; _searchCtrl.clear(); });
    }
  }

  String _shortAddress(String address) {
    final parts = address.split(',');
    if (parts.length <= 2) return address;
    return '${parts[0].trim()}, ${parts[1].trim()}';
  }

  // ── Navigation ───────────────────────────────────────────────────────────────

  void _goToStep(int s) {
    setState(() {
      _step = s;
      if (s != 1) _choosingDestOnMap = false;
    });
    if (s == 2) _fetchRoute();
  }

  void _onBack() {
    if (_step == 2) {
      setState(() {
        _step = 1;
        _activeStopIdx = _stops.length - 1;
        _searchCtrl.clear();
        _choosingDestOnMap = false;
      });
    } else if (_step == 1 && _choosingDestOnMap) {
      setState(() => _choosingDestOnMap = false);
    } else if (_step == 1) {
      _searchCtrl.clear();
      setState(() { _step = 0; _searchResults = []; });
    } else if (_step > 0) {
      Navigator.pop(context);
    }
  }

  // ── Payment method ────────────────────────────────────────────────────────────

  static const _kPaymentMethods = ['cash', 'wallet', 'aba', 'acleda', 'wing'];

  static String _paymentLabel(String method) {
    switch (method) {
      case 'wallet': return 'AutoRide Pay';
      case 'aba':    return 'ABA Pay';
      case 'acleda': return 'ACLEDA';
      case 'wing':   return 'Wing Money';
      default:       return 'Cash';
    }
  }

  void _showPaymentSheet(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: AppTheme.cardBg, borderRadius: BorderRadius.circular(2)),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Payment Method',
                  style: TextStyle(color: AppTheme.textPrimary,
                      fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
          ..._kPaymentMethods.map((m) => ListTile(
            leading: Icon(
              m == 'cash'   ? Icons.money :
              m == 'wallet' ? Icons.account_balance_wallet_outlined :
              Icons.credit_card_outlined,
              color: _paymentMethod == m ? AppTheme.accent : AppTheme.textSecondary,
            ),
            title: Text(_paymentLabel(m),
                style: TextStyle(
                    color: _paymentMethod == m ? AppTheme.accent : AppTheme.textPrimary,
                    fontWeight: _paymentMethod == m ? FontWeight.w700 : FontWeight.w400)),
            trailing: _paymentMethod == m
                ? const Icon(Icons.check_circle, color: AppTheme.accent, size: 20)
                : null,
            onTap: () {
              setState(() => _paymentMethod = m);
              Navigator.pop(ctx);
            },
          )),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  // ── Route + fare estimate (parallel) ─────────────────────────────────────────

  Future<void> _fetchRoute() async {
    final dest = _destLatLng;
    if (dest == null) return;
    setState(() {
      _routeLoading = true;
      _fareLoading  = true;
      _routePoints  = [];
      _etaMinutes   = 0;
      _distanceKm   = 0;
      _fareByType   = {};
    });
    await Future.wait([_doFetchRoute(dest), _doFetchFares(dest)]);
  }

  Future<void> _doFetchRoute(LatLng dest) async {
    final result = await MapsService.getRoute(origin: _pickupCenter, destination: dest);
    if (!mounted) return;
    setState(() {
      _routeLoading = false;
      if (result != null) {
        _routePoints = result.points;
        _etaMinutes  = result.etaMinutes;
        _distanceKm  = result.distanceKm;
      } else {
        _routePoints = [_pickupCenter, dest];
      }
    });
    if (_routePoints.isNotEmpty) {
      final sw = LatLng(
        [_pickupCenter.latitude,  dest.latitude].reduce((a,b) => a<b?a:b) - 0.005,
        [_pickupCenter.longitude, dest.longitude].reduce((a,b) => a<b?a:b) - 0.005,
      );
      final ne = LatLng(
        [_pickupCenter.latitude,  dest.latitude].reduce((a,b) => a>b?a:b) + 0.005,
        [_pickupCenter.longitude, dest.longitude].reduce((a,b) => a>b?a:b) + 0.005,
      );
      _confirmMapCtrl?.animateCamera(
        CameraUpdate.newLatLngBounds(LatLngBounds(southwest: sw, northeast: ne), 64),
      );
    }
  }

  Future<void> _doFetchFares(LatLng dest) async {
    try {
      final estimate = await ApiService.estimateRide(
        pickupLat:  _pickupCenter.latitude,
        pickupLng:  _pickupCenter.longitude,
        dropoffLat: dest.latitude,
        dropoffLng: dest.longitude,
      );
      if (!mounted) return;
      setState(() {
        _fareByType  = estimate.fares;
        _fareLoading = false;
        // Use backend route data to pre-fill distance/ETA before Google Maps responds
        if (_distanceKm == 0 && estimate.distanceKm > 0) _distanceKm = estimate.distanceKm;
        if (_etaMinutes == 0 && estimate.etaMinutes > 0) _etaMinutes = estimate.etaMinutes;
      });
    } catch (e, s) {
      AppLog.e('Fare', 'estimateRide failed', e, s);
      if (!mounted) return;
      setState(() => _fareLoading = false);
    }
  }

  // ── Book ride ─────────────────────────────────────────────────────────────────

  Future<void> _bookRide() async {
    if (_pickupAddress.isEmpty || _destAddress.isEmpty || _destLatLng == null) return;
    setState(() { _isBooking = true; _bookError = null; });
    final type = _kRideTypes.firstWhere((r) => r.name == _selectedRide);
    try {
      final ride = await ApiService.createRide(
        pickupAddress:  _pickupAddress,
        dropoffAddress: _destAddress,
        pickupLat:      _pickupCenter.latitude,
        pickupLng:      _pickupCenter.longitude,
        dropoffLat:     _destLatLng!.latitude,
        dropoffLng:     _destLatLng!.longitude,
        serviceType:    type.serviceType,
        paymentMethod:  _paymentMethod,
        scheduledAt: _isScheduled
            ? '${_scheduledTime.year}-'
              '${_scheduledTime.month.toString().padLeft(2,'0')}-'
              '${_scheduledTime.day.toString().padLeft(2,'0')} '
              '${_scheduledTime.hour.toString().padLeft(2,'0')}:'
              '${_scheduledTime.minute.toString().padLeft(2,'0')}:00'
            : null,
      );
      await NotificationService.instance.showTripUpdate(
        title: 'Ride Requested!',
        body:  'Looking for a driver…',
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TripTrackingScreen(
            rideId:       ride.id,
            fare:         AppTheme.khr(ride.fareKhr),
            from:         ride.pickupAddress,
            to:           ride.dropoffAddress,
            isScheduled:  _isScheduled,
            pickupLatLng: _pickupCenter,
            destLatLng:   _destLatLng,
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() { _isBooking = false; _bookError = e.message; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _isBooking = false; _bookError = e.toString(); });
    }
  }

  Future<DateTime?> _pickDateTime(BuildContext ctx) async {
    final date = await showDatePicker(
      context: ctx,
      initialDate: _scheduledTime,
      firstDate:   DateTime.now(),
      lastDate:    DateTime.now().add(const Duration(days: 7)),
      builder: (c, child) => Theme(
        data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: AppTheme.accent)),
        child: child!,
      ),
    );
    if (date == null || !mounted) return null;
    // ignore: use_build_context_synchronously
    final time = await showTimePicker(
      context: ctx,
      initialTime: TimeOfDay.fromDateTime(_scheduledTime),
      builder: (c, child) => Theme(
        data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: AppTheme.accent)),
        child: child!,
      ),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Step 0: full-screen "Where to?" landing — no top header
    if (_step == 0) {
      return Scaffold(
        backgroundColor: AppTheme.primary,
        body: _buildWhereTo(),
      );
    }
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: Column(children: [
        _StepHeader(step: _step - 1, onBack: _onBack),
        Expanded(child: _step == 1 ? _buildDestination() : _buildConfirm()),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Step 0 — "Where to?" landing
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildWhereTo() {
    return Stack(children: [
      GoogleMap(
        onMapCreated: (c) {
          _pickupMapCtrl = c;
          c.animateCamera(CameraUpdate.newLatLng(_pickupCenter));
        },
        initialCameraPosition: CameraPosition(target: _pickupCenter, zoom: 15),
        style: _kDarkMapStyle,
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        cameraTargetBounds: CameraTargetBounds(_kCambodiaBounds),
        minMaxZoomPreference: const MinMaxZoomPreference(10, 20),
        onCameraMove: (pos) => _pickupCenter = pos.target,
        onCameraIdle: () => _reverseGeocodePickup(_pickupCenter),
      ),

      const Center(child: _Crosshair()),

      // Back + GPS buttons
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MapFab(
                icon: Icons.arrow_back_ios_new,
                onTap: () => Navigator.pop(context),
              ),
              _MapFab(
                icon: _gpsLoading ? Icons.hourglass_empty : Icons.my_location,
                onTap: _gpsLoading ? null : _detectGps,
              ),
            ],
          ),
        ),
      ),

      // Bottom card
      Positioned(
        bottom: 0, left: 0, right: 0,
        child: _BottomCard(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Current location row
            Row(children: [
              Container(
                width: 10, height: 10,
                decoration: const BoxDecoration(
                    color: AppTheme.accent, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _geocodingPickup || _gpsLoading
                    ? Row(children: [
                        const SizedBox(
                          width: 14, height: 14,
                          child: CircularProgressIndicator(
                              color: AppTheme.accent, strokeWidth: 2),
                        ),
                        const SizedBox(width: 10),
                        Text(_pickupAddress,
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 13)),
                      ])
                    : Text(_pickupAddress,
                        style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
              ),
            ]),
            const SizedBox(height: 12),

            // "Where to?" tappable pill
            GestureDetector(
              onTap: () => _goToStep(1),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  const Icon(Icons.search, color: AppTheme.textSecondary, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Where to?',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Now',
                        style: TextStyle(
                            color: AppTheme.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      ),
      const SizedBox(height: 12),
    ]);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Step 1 — Destination search
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildDestination() {
    if (_choosingDestOnMap) return _buildDestinationMapPicker();

    final hasQuery = _searchCtrl.text.trim().isNotEmpty;

    return Column(children: [
      // ── Route card (Grab-style) ──────────────────────────────────────────
      Container(
        color: AppTheme.surface,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        child: Column(children: [

          // ── Pickup row (read-only) ──────────────────────────────────────
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Container(
              width: 12, height: 12,
              decoration: const BoxDecoration(color: AppTheme.accent, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _pickupAddress.isEmpty ? 'Current location' : _pickupAddress,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
            ),
          ]),

          // ── Stop rows ───────────────────────────────────────────────────
          ...List.generate(_stops.length, (i) {
            final stop    = _stops[i];
            final isActive = i == _activeStopIdx;
            final isLast   = i == _stops.length - 1;

            return Column(children: [
              // Connector line
              Row(children: [
                const SizedBox(width: 5),
                Container(width: 2, height: 20,
                    color: AppTheme.cardBg.withValues(alpha: 0.8)),
              ]),

              // Stop row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: isActive
                    ? BoxDecoration(
                        color: AppTheme.cardBg.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
                      )
                    : null,
                child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  // Stop icon
                  isLast && _stops.length == 1
                    // Single destination → red pin
                    ? const Icon(Icons.location_on, color: AppTheme.accentOrange, size: 20)
                    : isLast
                    // Final stop of multi-stop → red pin
                    ? const Icon(Icons.location_on, color: AppTheme.danger, size: 20)
                    // Intermediate stop → numbered circle
                    : Container(
                        width: 20, height: 20,
                        decoration: BoxDecoration(
                          color: AppTheme.warning.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.warning, width: 1.5),
                        ),
                        child: Center(
                          child: Text('${i + 1}',
                              style: const TextStyle(color: AppTheme.warning,
                                  fontSize: 10, fontWeight: FontWeight.w800)),
                        ),
                      ),

                  const SizedBox(width: 10),

                  // Input or filled text
                  Expanded(
                    child: isActive
                      ? TextField(
                          controller: _searchCtrl,
                          autofocus: true,
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: i == 0 ? 'Where to?' : 'Stop ${i + 1}',
                            hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 7),
                            suffixIcon: hasQuery
                              ? IconButton(
                                  icon: const Icon(Icons.close, size: 16, color: AppTheme.textSecondary),
                                  onPressed: () => _searchCtrl.clear(),
                                )
                              : null,
                          ),
                        )
                      : GestureDetector(
                          onTap: () => setState(() { _activeStopIdx = i; _searchCtrl.clear(); }),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            child: stop.isFilled
                              ? Text(stop.address,
                                  style: const TextStyle(color: AppTheme.textPrimary,
                                      fontSize: 14, fontWeight: FontWeight.w500),
                                  maxLines: 1, overflow: TextOverflow.ellipsis)
                              : Text(i == 0 ? 'Where to?' : 'Stop ${i + 1}',
                                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                          ),
                        ),
                  ),

                  // Delete stop button
                  if (_stops.length > 1)
                    GestureDetector(
                      onTap: () => setState(() {
                        _stops.removeAt(i);
                        if (_activeStopIdx >= _stops.length) {
                          _activeStopIdx = _stops.length - 1;
                        }
                      }),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                        child: Icon(Icons.close, size: 16, color: AppTheme.textSecondary),
                      ),
                    ),
                ]),
              ),
            ]);
          }),

          // ── "Add a stop" — always visible when < 4 stops ───────────────
          if (_stops.length < 4) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                final unfilled = _stops.indexWhere((s) => !s.isFilled);
                if (unfilled != -1) {
                  // Focus the first unfilled stop instead of adding a new one
                  setState(() { _activeStopIdx = unfilled; _searchCtrl.clear(); });
                } else {
                  setState(() {
                    _stops.add(_WayStop());
                    _activeStopIdx = _stops.length - 1;
                    _searchCtrl.clear();
                  });
                }
              },
              child: Row(children: [
                Container(
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, size: 14, color: AppTheme.accent),
                ),
                const SizedBox(width: 10),
                const Text('Add a stop',
                    style: TextStyle(color: AppTheme.accent,
                        fontSize: 14, fontWeight: FontWeight.w500)),
              ]),
            ),
          ],
        ]),
      ),

      const Divider(height: 1, color: AppTheme.cardBg),

      // ── Search results / tabs ────────────────────────────────────────────
      Expanded(
        child: _searching
            ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
            : hasQuery && _searchResults.isEmpty
                ? const Center(child: Text('No results found',
                    style: TextStyle(color: AppTheme.textSecondary)))
                : hasQuery
                    ? ListView(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        children: _searchResults
                            .map((r) {
                              final isAlreadySelected = _stops.any((s) => s.address == r.address);
                              return _DestTile(
                                icon: Icons.location_on,
                                iconColor: AppTheme.accent,
                                title: r.address,
                                trailing: isAlreadySelected
                                    ? const Icon(Icons.check_circle, color: AppTheme.success, size: 20)
                                    : null,
                                onTap: () => _selectResult(r),
                              );
                            })
                            .toList(),
                      )
                    : _buildWhereToTabs(),
      ),
      if (_stops.every((s) => s.isFilled))
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _goToStep(2),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                _stops.length > 1 ? 'Confirm destinations' : 'Confirm destination',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
    ]);
  }

  Widget _buildWhereToTabs() {
    return Column(children: [
      // Choose on Map — always at top
      _DestTile(
        icon: Icons.map_outlined,
        iconColor: AppTheme.accent,
        title: 'Choose on Map',
        onTap: () {
          final activeStop = _stops[_activeStopIdx];
          setState(() {
            // Start at the stop's existing position; fall back to pickup center
            _destMapCenter   = activeStop.latLng ?? _pickupCenter;
            // Pre-fill address so confirm button is enabled immediately
            _mapPickerAddress = activeStop.address;
            _choosingDestOnMap = true;
          });
        },
      ),
      const Divider(height: 1, color: AppTheme.cardBg),

      // Tab bar
      Container(
        color: AppTheme.surface,
        child: Row(children: [
          _TabChip(label: 'Recent',      selected: _whereToTab == 0, onTap: () => setState(() => _whereToTab = 0)),
          _TabChip(label: 'Suggestions', selected: _whereToTab == 1, onTap: () => setState(() => _whereToTab = 1)),
          _TabChip(label: 'Saved',       selected: _whereToTab == 2, onTap: () => setState(() => _whereToTab = 2)),
        ]),
      ),
      const Divider(height: 1, color: AppTheme.cardBg),

      Expanded(child: _buildTabContent()),
    ]);
  }

  Widget _buildTabContent() {
    switch (_whereToTab) {
      case 0:
        return const Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.history, color: AppTheme.textSecondary, size: 40),
            SizedBox(height: 12),
            Text('No recent trips',
                style: TextStyle(color: AppTheme.textSecondary)),
          ]),
        );
      case 1:
        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: _kPresets
              .map((p) {
                final isAlreadySelected = _stops.any((s) => s.address == p.name);
                return _DestTile(
                  icon: Icons.place_outlined,
                  iconColor: AppTheme.accentOrange,
                  title: p.name,
                  trailing: isAlreadySelected
                      ? const Icon(Icons.check_circle, color: AppTheme.success, size: 20)
                      : null,
                  onTap: () => _selectPreset(p),
                );
              })
              .toList(),
        );
      case 2:
        return const Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.bookmark_border, color: AppTheme.textSecondary, size: 40),
            SizedBox(height: 12),
            Text('No saved places',
                style: TextStyle(color: AppTheme.textSecondary)),
          ]),
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildDestinationMapPicker() {
    return Stack(children: [
      GoogleMap(
        onMapCreated: (c) {
          _destMapCtrl = c;
          c.animateCamera(CameraUpdate.newLatLng(_destMapCenter));
          // Geocode immediately so the confirm button is ready without dragging
          if (_mapPickerAddress.isEmpty) _geocodeMapCenter();
        },
        initialCameraPosition: CameraPosition(target: _destMapCenter, zoom: 15),
        style: _kDarkMapStyle,
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        cameraTargetBounds: CameraTargetBounds(_kCambodiaBounds),
        minMaxZoomPreference: const MinMaxZoomPreference(10, 20),
        onCameraMove: (pos) => _destMapCenter = pos.target,
        onCameraIdle: _geocodeMapCenter,
      ),

      const Center(child: _Crosshair()),

      Positioned(
        bottom: 0, left: 0, right: 0,
        child: Builder(builder: (ctx) {
          // Use viewPadding so this always sits above the system nav bar,
          // regardless of whether the parent Scaffold already consumed the inset.
          final bottomInset = MediaQuery.of(ctx).viewPadding.bottom;
          return Container(
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20)],
            ),
            padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomInset),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.accent, width: 2)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _geocodingDest
                      ? const Row(children: [
                          SizedBox(
                            width: 14, height: 14,
                            child: CircularProgressIndicator(
                                color: AppTheme.accent, strokeWidth: 2),
                          ),
                          SizedBox(width: 10),
                          Text('Finding address…',
                              style: TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 13)),
                        ])
                      : Text(
                          _mapPickerAddress.isEmpty
                              ? 'Drag map to set destination'
                              : _mapPickerAddress,
                          style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                ),
              ]),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_geocodingDest || _mapPickerAddress.isEmpty)
                      ? null
                      : () {
                          setState(() {
                            _stops[_activeStopIdx].address = _mapPickerAddress;
                            _stops[_activeStopIdx].latLng  = _destMapCenter;
                            _choosingDestOnMap = false;
                            _mapPickerAddress  = '';
                          });
                          _afterStopFilled();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.danger,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppTheme.danger.withValues(alpha: 0.4),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Confirm Destination',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                ),
              ),
            ]),
          );
        }),
      ),
    ]);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Step 2 — Confirm
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildConfirm() {
    // Safety check: ensure we have stops with valid destination
    if (_stops.isEmpty || _destLatLng == null || _stops.last.address.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('No destination selected', style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _goToStep(1),
            child: const Text('Select Destination'),
          ),
        ]),
      );
    }

    final dest = _destLatLng;
    final type = _kRideTypes.firstWhere(
      (r) => r.name == _selectedRide,
      orElse: () => _kRideTypes[0],  // Default to first ride type if not found
    );

    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('pickup'),
        position: _pickupCenter,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: 'Pickup'),
      ),
      // Intermediate stops (orange)
      for (int i = 0; i < _stops.length - 1; i++)
        if (_stops[i].latLng != null)
          Marker(
            markerId: MarkerId('stop_$i'),
            position: _stops[i].latLng!,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
            infoWindow: InfoWindow(title: 'Stop ${i + 1}'),
          ),
      // Final destination (red)
      if (dest != null)
        Marker(
          markerId: const MarkerId('dest'),
          position: dest,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'Destination'),
        ),
    };
    final polylines = _routePoints.length >= 2
        ? <Polyline>{
            Polyline(
              polylineId: const PolylineId('route'),
              points: _routePoints,
              color: AppTheme.accent,
              width: 5,
            ),
          }
        : <Polyline>{};

    final midLat = dest != null
        ? (_pickupCenter.latitude  + dest.latitude)  / 2
        : _pickupCenter.latitude;
    final midLng = dest != null
        ? (_pickupCenter.longitude + dest.longitude) / 2
        : _pickupCenter.longitude;

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
        child: Row(children: [
          Expanded(
            child: Text('Review trip details',
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
          ),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _step = 1;
                _activeStopIdx = _stops.length - 1;
                _searchCtrl.clear();
                _choosingDestOnMap = false;
              });
            },
            icon: const Icon(Icons.cancel_outlined, size: 18),
            label: const Text('Edit route'),
            style: TextButton.styleFrom(foregroundColor: AppTheme.accent),
          ),
        ]),
      ),
      SizedBox(
        height: 240,
        child: Stack(children: [
          GoogleMap(
            onMapCreated: (c) {
              _confirmMapCtrl = c;
              if (dest != null) {
                final sw = LatLng(
                  [_pickupCenter.latitude,  dest.latitude].reduce((a,b) => a<b?a:b) - 0.005,
                  [_pickupCenter.longitude, dest.longitude].reduce((a,b) => a<b?a:b) - 0.005,
                );
                final ne = LatLng(
                  [_pickupCenter.latitude,  dest.latitude].reduce((a,b) => a>b?a:b) + 0.005,
                  [_pickupCenter.longitude, dest.longitude].reduce((a,b) => a>b?a:b) + 0.005,
                );
                c.animateCamera(CameraUpdate.newLatLngBounds(
                    LatLngBounds(southwest: sw, northeast: ne), 64));
              } else {
                c.animateCamera(CameraUpdate.newLatLng(_pickupCenter));
              }
            },
            initialCameraPosition: CameraPosition(
              target: LatLng(midLat, midLng), zoom: 13,
            ),
            style: _kDarkMapStyle,
            markers:   markers,
            polylines: polylines,
            myLocationEnabled:       false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled:     false,
          ),
          if (_routeLoading)
            const ColoredBox(
              color: Colors.black38,
              child: Center(child: CircularProgressIndicator(color: AppTheme.accent)),
            ),
        ]),
      ),

      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Route summary
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(14)),
              child: Column(children: [
                _RouteRow(color: AppTheme.accent, icon: Icons.circle, label: _pickupAddress),
                ...List.generate(_stops.length, (i) {
                  final isLast = i == _stops.length - 1;
                  return Column(children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8, top: 4, bottom: 4),
                      child: Container(width: 2, height: 16, color: AppTheme.cardBg),
                    ),
                    _RouteRow(
                      color: isLast ? AppTheme.accentOrange : AppTheme.warning,
                      icon:  isLast ? Icons.location_on : Icons.location_on_outlined,
                      label: _stops[i].address,
                      onTap: () {
                        setState(() {
                          _step = 1;
                          _activeStopIdx = i;
                          _searchCtrl.clear();
                          _choosingDestOnMap = false;
                        });
                      },
                      trailing: const Icon(Icons.cancel_outlined, color: AppTheme.accent, size: 18),
                    ),
                  ]);
                }),
                if (_etaMinutes > 0 || _distanceKm > 0) ...[
                  const Divider(color: AppTheme.cardBg, height: 20),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                    _InfoChip(icon: Icons.straighten,        label: '${_distanceKm.toStringAsFixed(1)} km'),
                    _InfoChip(icon: Icons.access_time_outlined, label: '~$_etaMinutes min'),
                  ]),
                ],
              ]),
            ),
            const SizedBox(height: 16),

            if (_bookError != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.danger.withValues(alpha: 0.4)),
                ),
                child: Row(children: [
                  const Icon(Icons.error_outline, color: AppTheme.danger, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_bookError!,
                      style: const TextStyle(color: AppTheme.danger, fontSize: 12))),
                ]),
              ),
              const SizedBox(height: 12),
            ],

            Row(children: [
              const Text('Choose Ride',
                  style: TextStyle(color: AppTheme.textPrimary,
                      fontSize: 15, fontWeight: FontWeight.w700)),
              if (_fareLoading) ...[
                const SizedBox(width: 10),
                const SizedBox(
                  width: 14, height: 14,
                  child: CircularProgressIndicator(color: AppTheme.accent, strokeWidth: 2),
                ),
              ],
            ]),
            const SizedBox(height: 10),
            ..._kRideTypes.map((r) => _RideTypeCard(
                  type:        r,
                  selected:    _selectedRide == r.name,
                  onTap:       () => setState(() => _selectedRide = r.name),
                  fareInfo:    _fareByType[r.serviceType],
                  fareLoading: _fareLoading,
                )),
            const SizedBox(height: 16),

            GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const PromoScreen())),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12)),
                child: const Row(children: [
                  Icon(Icons.local_offer_outlined, color: AppTheme.warning, size: 20),
                  SizedBox(width: 10),
                  Expanded(child: Text('Add promo code',
                      style: TextStyle(color: AppTheme.textSecondary))),
                  Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                ]),
              ),
            ),
            const SizedBox(height: 10),

            // Payment method selector
            GestureDetector(
              onTap: () => _showPaymentSheet(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  const Icon(Icons.payment_outlined, color: AppTheme.accent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_paymentLabel(_paymentMethod),
                      style: const TextStyle(color: AppTheme.textPrimary))),
                  const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                ]),
              ),
            ),
            const SizedBox(height: 14),

            Row(children: [
              const Text('Schedule for later',
                  style: TextStyle(color: AppTheme.textPrimary,
                      fontSize: 14, fontWeight: FontWeight.w600)),
              const Spacer(),
              Switch(
                value: _isScheduled,
                onChanged: (v) => setState(() => _isScheduled = v),
                activeThumbColor: AppTheme.accent,
                activeTrackColor: AppTheme.accent.withValues(alpha: 0.4),
              ),
            ]),
            if (_isScheduled) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final dt = await _pickDateTime(context);
                  if (dt != null) setState(() => _scheduledTime = dt);
                },
                child: Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.accent.withValues(alpha: 0.4)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.schedule, color: AppTheme.accent, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      '${_scheduledTime.day}/${_scheduledTime.month}/'
                      '${_scheduledTime.year}  '
                      '${_scheduledTime.hour}:'
                      '${_scheduledTime.minute.toString().padLeft(2,'0')}',
                      style: const TextStyle(
                          color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                  ]),
                ),
              ),
            ],
            const SizedBox(height: 12),
          ]),
        ),
      ),

    // Full-width confirm button
    Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: ElevatedButton(
        onPressed: _isBooking ? null : _bookRide,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isScheduled ? AppTheme.warning : AppTheme.danger,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _isBooking
            ? const SizedBox(
                width: 22, height: 22,
                child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2.5))
            : Text(
                _isScheduled
                    ? '📅  Schedule — ${_fareByType[type.serviceType]?.formattedTotal ?? '...'}'
                    : '🚗  Confirm — ${_fareByType[type.serviceType]?.formattedTotal ?? '...'}',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
      ),
    ),

    ]);
  }
}

// ─── Step header (2 steps: Where To? / Confirm) ───────────────────────────────

class _StepHeader extends StatelessWidget {
  final int step;
  final VoidCallback? onBack;
  const _StepHeader({required this.step, this.onBack});

  static const _labels = ['Where To?', 'Confirm'];

  @override
  Widget build(BuildContext context) {
    final label = _labels[step.clamp(0, _labels.length - 1)];
    return SafeArea(
      bottom: false,
      child: Container(
        color: AppTheme.surface,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          SizedBox(
            width: 36,
            child: onBack != null
                ? GestureDetector(
                    onTap: onBack,
                    child: const Icon(Icons.arrow_back_ios_new,
                        color: AppTheme.textPrimary, size: 18),
                  )
                : null,
          ),
          Expanded(
            child: Column(children: [
              Text(label,
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(2, (i) {
                  final done   = i < step;
                  final active = i == step;
                  return Row(children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: active ? 20 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: active
                            ? AppTheme.accent
                            : done
                                ? AppTheme.accent.withValues(alpha: 0.5)
                                : AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    if (i < 1)
                      Container(
                        width: 20, height: 2,
                        color: i < step
                            ? AppTheme.accent.withValues(alpha: 0.5)
                            : AppTheme.cardBg,
                      ),
                  ]);
                }),
              ),
            ]),
          ),
          const SizedBox(width: 36),
        ]),
      ),
    );
  }
}

// ─── Small reusable widgets ───────────────────────────────────────────────────

class _Crosshair extends StatelessWidget {
  const _Crosshair();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(
            color: AppTheme.accent,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
        ),
        Container(width: 2, height: 12, color: AppTheme.accent),
      ]),
    );
  }
}

class _MapFab extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _MapFab({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
        ),
        child: Icon(icon, color: AppTheme.accent, size: 22),
      ),
    );
  }
}

class _BottomCard extends StatelessWidget {
  final Widget child;
  const _BottomCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20)],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: child,
        ),
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TabChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(label,
              style: TextStyle(
                color: selected ? AppTheme.accent : AppTheme.textSecondary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 14,
              )),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 24, height: 2,
            decoration: BoxDecoration(
              color: selected ? AppTheme.accent : Colors.transparent,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ]),
      ),
    );
  }
}

class _DestTile extends StatelessWidget {
  final IconData icon;
  final Color    iconColor;
  final String   title;
  final VoidCallback onTap;
  final Widget? trailing;
  const _DestTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12), shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      title: Text(title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
      trailing: trailing,
      onTap: onTap,
    );
  }
}

class _RouteRow extends StatelessWidget {
  final Color    color;
  final IconData icon;
  final String   label;
  final VoidCallback? onTap;
  final Widget?      trailing;
  const _RouteRow({
    required this.color,
    required this.icon,
    required this.label,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final content = Row(children: [
      Icon(icon, color: color, size: 14),
      const SizedBox(width: 10),
      Expanded(child: Text(label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13))),
      if (trailing != null) ...[
        const SizedBox(width: 8),
        trailing!,
      ],
    ]);

    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: content),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String   label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: AppTheme.accent, size: 15),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(
          color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
    ]);
  }
}

class _RideTypeCard extends StatelessWidget {
  final _RideType    type;
  final bool         selected;
  final VoidCallback onTap;
  final FareInfo?    fareInfo;
  final bool         fareLoading;
  const _RideTypeCard({
    required this.type,
    required this.selected,
    required this.onTap,
    this.fareInfo,
    this.fareLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final priceText = fareInfo != null
        ? fareInfo!.formattedTotal
        : fareLoading ? '...' : '—';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected ? AppTheme.accent : Colors.transparent, width: 1.5),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (selected ? AppTheme.accent : AppTheme.textSecondary)
                  .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(type.icon,
                color: selected ? AppTheme.accent : AppTheme.textSecondary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(type.name,
                style: const TextStyle(
                    color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
            Text(type.desc,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              if (fareInfo?.surgeActive == true) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('Surge',
                      style: TextStyle(color: AppTheme.warning,
                          fontSize: 9, fontWeight: FontWeight.w700)),
                ),
              ],
              Text(priceText,
                  style: TextStyle(
                      color: selected ? AppTheme.accent : AppTheme.textPrimary,
                      fontWeight: FontWeight.w700)),
            ]),
            Text(type.eta,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          ]),
          const SizedBox(width: 8),
          Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppTheme.accent : AppTheme.textSecondary, size: 20),
        ]),
      ),
    );
  }
}

const String? _kDarkMapStyle = null; // default light Google Maps style
