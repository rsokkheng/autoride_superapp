import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
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

class _RideType {
  final String name, serviceType, price, eta, desc;
  final IconData icon;
  const _RideType({
    required this.name,
    required this.serviceType,
    required this.icon,
    required this.price,
    required this.eta,
    required this.desc,
  });
}

const _kRideTypes = [
  _RideType(name: 'Standard', serviceType: 'standard', icon: Icons.directions_car,  price: '\$3.50', eta: '3 min', desc: '4 seats'),
  _RideType(name: 'Premium',  serviceType: 'premium',  icon: Icons.local_taxi,       price: '\$6.00', eta: '5 min', desc: 'Luxury car'),
  _RideType(name: 'Shared',   serviceType: 'shared',   icon: Icons.airport_shuttle,  price: '\$2.50', eta: '7 min', desc: 'Shared ride'),
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
  String _destAddress = '';
  LatLng? _destLatLng;
  int    _whereToTab  = 0; // 0=Recent  1=Suggestions  2=Saved

  // ── Destination map picker ──────────────────────────────────────────────────
  bool   _choosingDestOnMap = false;
  GoogleMapController? _destMapCtrl;
  LatLng _destMapCenter = const LatLng(11.5680, 104.9195);
  bool   _geocodingDest = false;

  // ── Confirm ─────────────────────────────────────────────────────────────────
  GoogleMapController? _confirmMapCtrl;
  List<LatLng> _routePoints = [];
  int    _etaMinutes  = 0;
  double _distanceKm  = 0.0;
  bool   _routeLoading = false;

  String   _selectedRide  = 'Standard';
  bool     _isScheduled   = false;
  DateTime _scheduledTime = DateTime.now().add(const Duration(hours: 1));
  bool     _isBooking     = false;
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
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 10));
      if (!mounted) return;
      final latLng = LatLng(pos.latitude, pos.longitude);
      if (!_isInCambodia(latLng)) {
        setState(() { _gpsLoading = false; _pickupAddress = 'Tap map to set pickup'; });
        return;
      }
      setState(() { _pickupCenter = latLng; _gpsLoading = false; });
      _pickupMapCtrl?.animateCamera(CameraUpdate.newLatLng(latLng));
      _reverseGeocodePickup(latLng);
    } catch (_) {
      if (mounted) setState(() { _gpsLoading = false; _pickupAddress = 'Tap map to set pickup'; });
    }
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
    setState(() { _destAddress = r.address; _destLatLng = r.latLng; });
    _goToStep(2);
  }

  void _selectPreset(_Preset p) {
    setState(() { _destAddress = p.name; _destLatLng = p.latLng; });
    _goToStep(2);
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
    if (_step == 1 && _choosingDestOnMap) {
      setState(() => _choosingDestOnMap = false);
    } else if (_step == 1) {
      _searchCtrl.clear();
      setState(() { _step = 0; _searchResults = []; });
    } else if (_step > 0) {
      setState(() => _step--);
    } else {
      Navigator.pop(context);
    }
  }

  // ── Route ────────────────────────────────────────────────────────────────────

  Future<void> _fetchRoute() async {
    final dest = _destLatLng;
    if (dest == null) return;
    setState(() { _routeLoading = true; _routePoints = []; _etaMinutes = 0; _distanceKm = 0; });
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

  // ── Book ride ─────────────────────────────────────────────────────────────────

  Future<void> _bookRide() async {
    if (_pickupAddress.isEmpty || _destAddress.isEmpty) return;
    setState(() { _isBooking = true; _bookError = null; });
    final type = _kRideTypes.firstWhere((r) => r.name == _selectedRide);
    try {
      final ride = await ApiService.createRide(
        pickupAddress:  _pickupAddress,
        dropoffAddress: _destAddress,
        serviceType:    type.serviceType,
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
            fare:         '\$${ride.fare}',
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
        data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(primary: AppTheme.accent)),
        child: child!,
      ),
    );
    if (date == null || !mounted) return null;
    // ignore: use_build_context_synchronously
    final time = await showTimePicker(
      context: ctx,
      initialTime: TimeOfDay.fromDateTime(_scheduledTime),
      builder: (c, child) => Theme(
        data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(primary: AppTheme.accent)),
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
    ]);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Step 1 — Destination search
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildDestination() {
    if (_choosingDestOnMap) return _buildDestinationMapPicker();

    final hasQuery = _searchCtrl.text.trim().isNotEmpty;
    return Column(children: [
      // Route header — current location + where to input
      Container(
        color: AppTheme.surface,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Pickup row
          Row(children: [
            Container(
              width: 10, height: 10,
              decoration: const BoxDecoration(
                  color: AppTheme.accent, shape: BoxShape.circle),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                _pickupAddress.isEmpty ? 'Current location' : _pickupAddress,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ]),
          // Vertical connector
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Container(width: 2, height: 14, color: AppTheme.cardBg),
          ),
          // Destination input row
          Row(children: [
            Container(
              width: 10, height: 10,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.accent, width: 2)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Where to?',
                  hintStyle: const TextStyle(color: AppTheme.textSecondary),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  suffixIcon: hasQuery
                      ? IconButton(
                          icon: const Icon(Icons.close,
                              color: AppTheme.textSecondary, size: 18),
                          onPressed: () => _searchCtrl.clear(),
                        )
                      : null,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 6),
          const Divider(height: 1, color: AppTheme.cardBg),
        ]),
      ),

      // Body
      Expanded(
        child: _searching
            ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
            : hasQuery && _searchResults.isEmpty
                ? const Center(
                    child: Text('No results found',
                        style: TextStyle(color: AppTheme.textSecondary)))
                : hasQuery
                    ? ListView(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        children: _searchResults
                            .map((r) => _DestTile(
                                  icon: Icons.location_on,
                                  iconColor: AppTheme.accent,
                                  title: r.address,
                                  onTap: () => _selectResult(r),
                                ))
                            .toList(),
                      )
                    : _buildWhereToTabs(),
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
        onTap: () => setState(() {
          _destMapCenter = _pickupCenter;
          _choosingDestOnMap = true;
        }),
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
              .map((p) => _DestTile(
                    icon: Icons.place_outlined,
                    iconColor: AppTheme.accentOrange,
                    title: p.name,
                    onTap: () => _selectPreset(p),
                  ))
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
        },
        initialCameraPosition: CameraPosition(target: _destMapCenter, zoom: 15),
        style: _kDarkMapStyle,
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        cameraTargetBounds: CameraTargetBounds(_kCambodiaBounds),
        minMaxZoomPreference: const MinMaxZoomPreference(10, 20),
        onCameraMove: (pos) => _destMapCenter = pos.target,
        onCameraIdle: () async {
          setState(() => _geocodingDest = true);
          final address = await MapsService.reverseGeocode(_destMapCenter);
          if (!mounted) return;
          setState(() {
            _destAddress = address ??
                '${_destMapCenter.latitude.toStringAsFixed(4)}, ${_destMapCenter.longitude.toStringAsFixed(4)}';
            _geocodingDest = false;
          });
        },
      ),

      const Center(child: _Crosshair()),

      Positioned(
        bottom: 0, left: 0, right: 0,
        child: _BottomCard(
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
                        _destAddress.isEmpty
                            ? 'Drag map to set destination'
                            : _destAddress,
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
                onPressed: (_geocodingDest || _destAddress.isEmpty)
                    ? null
                    : () {
                        setState(() {
                          _destLatLng = _destMapCenter;
                          _choosingDestOnMap = false;
                        });
                        _goToStep(2);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: AppTheme.primary,
                  disabledBackgroundColor: AppTheme.accent.withValues(alpha: 0.4),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Confirm Destination',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              ),
            ),
          ]),
        ),
      ),
    ]);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Step 2 — Confirm
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildConfirm() {
    final dest = _destLatLng;
    final type = _kRideTypes.firstWhere((r) => r.name == _selectedRide);

    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('pickup'),
        position: _pickupCenter,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: 'Pickup'),
      ),
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
                _RouteRow(color: AppTheme.accent,       icon: Icons.circle,      label: _pickupAddress),
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4, bottom: 4),
                  child: Container(width: 2, height: 16, color: AppTheme.cardBg),
                ),
                _RouteRow(color: AppTheme.accentOrange, icon: Icons.location_on, label: _destAddress),
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

            const Text('Choose Ride',
                style: TextStyle(color: AppTheme.textPrimary,
                    fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            ..._kRideTypes.map((r) => _RideTypeCard(
                  type: r,
                  selected: _selectedRide == r.name,
                  onTap: () => setState(() => _selectedRide = r.name),
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
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isBooking ? null : _bookRide,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isScheduled ? AppTheme.warning : AppTheme.accent,
                  foregroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _isBooking
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(
                            color: AppTheme.primary, strokeWidth: 2.5))
                    : Text(
                        _isScheduled
                            ? '📅  Schedule — ${type.price}'
                            : '🚗  Confirm — ${type.price}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
              ),
            ),
          ]),
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
  const _DestTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
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
      onTap: onTap,
    );
  }
}

class _RouteRow extends StatelessWidget {
  final Color    color;
  final IconData icon;
  final String   label;
  const _RouteRow({required this.color, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, color: color, size: 14),
      const SizedBox(width: 10),
      Expanded(child: Text(label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13))),
    ]);
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
  final _RideType type;
  final bool selected;
  final VoidCallback onTap;
  const _RideTypeCard({required this.type, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
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
            Text(type.price,
                style: TextStyle(
                    color: selected ? AppTheme.accent : AppTheme.textPrimary,
                    fontWeight: FontWeight.w700)),
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

const String _kDarkMapStyle =
    '[{"elementType":"geometry","stylers":[{"color":"#1a1a2e"}]},'
    '{"elementType":"labels.text.fill","stylers":[{"color":"#b0bec5"}]},'
    '{"elementType":"labels.text.stroke","stylers":[{"color":"#1a1a2e"}]},'
    '{"featureType":"road","elementType":"geometry","stylers":[{"color":"#16213e"}]},'
    '{"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#0f3460"}]},'
    '{"featureType":"water","elementType":"geometry","stylers":[{"color":"#0f3460"}]},'
    '{"featureType":"poi","elementType":"geometry","stylers":[{"color":"#16213e"}]},'
    '{"featureType":"administrative","elementType":"geometry.stroke","stylers":[{"color":"#0f3460"}]}]';
