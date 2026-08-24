import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:geolocator/geolocator.dart';
import '../../utils/app_log.dart';
import '../../utils/location_display.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../theme/app_theme.dart';
import '../../services/location_service.dart';
import '../../services/maps_service.dart';
import '../../main.dart' show appLocale;
import '../../services/notification_service.dart';
import '../../services/api_service.dart';
import '../../models/ride_model.dart' show NearbyMapDriverModel;
import '../../l10n/app_localizations.dart';
import 'trip_tracking_screen.dart';
import 'promo_screen.dart';
import 'saved_places_screen.dart';

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
  // Base fare from the vehicle type's pricing (GET /vehicle-types
  // `pricing.base`) — shown for metered/no-destination rides, since the
  // real distance-based total can't be known until the trip ends.
  final int base;
  const _RideType({
    required this.name,
    required this.serviceType,
    required this.icon,
    required this.eta,
    required this.desc,
    this.base = 0,
  });
}

// Offline/error fallback only — mirrors GET /vehicle-types so the screen
// still works if that call fails. The real list (with real pricing/capacity)
// is fetched at runtime via ApiService.getVehicleTypes().
const _kFallbackRideTypes = [
  _RideType(name: 'Motorcycle',   serviceType: 'motorcycle', icon: Icons.two_wheeler,        eta: '', desc: '1 seat',  base: 2500),
  _RideType(name: 'Tuk-tuk',      serviceType: 'tuk_tuk',    icon: Icons.electric_rickshaw,   eta: '', desc: '3 seats', base: 3500),
  _RideType(name: 'Car Standard', serviceType: 'standard',   icon: Icons.directions_car,      eta: '', desc: '4 seats', base: 5000),
  _RideType(name: 'Car Premium',  serviceType: 'premium',    icon: Icons.local_taxi,          eta: '', desc: '4 seats', base: 8000),
  _RideType(name: 'Shared Ride',  serviceType: 'shared',     icon: Icons.groups,              eta: '', desc: '4 seats', base: 2500),
  _RideType(name: 'Van / XL',     serviceType: 'van',        icon: Icons.airport_shuttle,     eta: '', desc: '7 seats', base: 7000),
];

const _kRideCategories = ['All', 'Tuk Tuk', 'Car', 'Bike'];

// ─── Labeled marker (pill + numbered circle) ─────────────────────────────────
// Returns a composite bitmap of [label pill][number circle] plus the anchor
// offset so the circle center aligns to the map coordinate.

class _LabeledMarker {
  final BitmapDescriptor icon;
  final Offset anchor; // 0–1 relative to bitmap dimensions
  const _LabeledMarker(this.icon, this.anchor);
}

// Draw markers at 3× resolution and declare the logical display size explicitly
// so they appear at the correct dp size on all screen densities (retina/3×/etc.).
Future<_LabeledMarker> _buildLabeledMarker(
    int number, String label, {
    Color bg              = const Color(0xFFFF9800),
    double circleLogical  = 30.0, // desired display size in dp
    bool   showNumber     = true,
}) async {
  const scale    = 3.0; // render at 3× for sharpness
  final circleSize = circleLogical * scale; // canvas px

  const maxChars = 18;
  final display  = label.isEmpty
      ? (showNumber ? 'Stop $number' : 'Destination')
      : label.length > maxChars
          ? '${label.substring(0, maxChars)}…'
          : label;

  // All "logical dp" constants, scaled to canvas pixels
  final fontSize = 13.0 * scale;
  final pillPadH = 10.0 * scale;
  final pillPadV =  7.0 * scale;
  final pillR    =  8.0 * scale;
  final gap      =  5.0 * scale;
  final blurPad  =  6.0 * scale;

  final tp = TextPainter(
    text: TextSpan(
      text: display,
      style: TextStyle(
          color: Colors.white, fontSize: fontSize, fontWeight: FontWeight.w600),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  final pillW    = tp.width + pillPadH * 2;
  final pillH    = tp.height + pillPadV * 2;
  final contentH = circleSize > pillH ? circleSize : pillH;
  final canvasW  = pillW + gap + circleSize + blurPad * 2;
  final canvasH  = contentH + blurPad * 2;

  final recorder = ui.PictureRecorder();
  final canvas   = Canvas(recorder);

  // ── Pill ───────────────────────────────────────────────────────────────────
  final pillTop  = blurPad + (contentH - pillH) / 2;
  final pillRect = RRect.fromLTRBR(
      blurPad, pillTop, blurPad + pillW, pillTop + pillH,
      Radius.circular(pillR));

  canvas.drawRRect(
    pillRect,
    Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3 * scale),
  );
  canvas.drawRRect(pillRect, Paint()..color = bg);
  tp.paint(canvas, Offset(blurPad + pillPadH, pillTop + pillPadV));

  // ── Circle ─────────────────────────────────────────────────────────────────
  final cx     = blurPad + pillW + gap + circleSize / 2;
  final cy     = blurPad + contentH / 2;
  final center = Offset(cx, cy);
  final radius = circleSize / 2;

  canvas.drawCircle(
    center.translate(0, 2 * scale), radius,
    Paint()
      ..color = Colors.black.withValues(alpha: 0.22)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 * scale),
  );
  canvas.drawCircle(center, radius, Paint()..color = bg);
  canvas.drawCircle(
    center, radius,
    Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * scale,
  );

  if (showNumber) {
    final numTp = TextPainter(
      text: TextSpan(
        text: '$number',
        style: TextStyle(
            color: Colors.white,
            fontSize: circleSize * 0.42,
            fontWeight: FontWeight.w900),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    numTp.paint(canvas, center - Offset(numTp.width / 2, numTp.height / 2));
  } else {
    canvas.drawCircle(center, radius * 0.32, Paint()..color = Colors.white);
  }

  final picture = recorder.endRecording();
  final img     = await picture.toImage(canvasW.ceil(), canvasH.ceil());
  final bytes   = await img.toByteData(format: ui.ImageByteFormat.png);
  if (bytes == null) {
    return _LabeledMarker(BitmapDescriptor.defaultMarker, const Offset(0.5, 1.0));
  }

  // imagePixelRatio tells the map that this image was drawn at 3× density,
  // so it displays at canvasW/3 × canvasH/3 logical dp on all screen types.
  return _LabeledMarker(
    BitmapDescriptor.bytes(
        bytes.buffer.asUint8List(), imagePixelRatio: scale),
    Offset(cx / canvasW, cy / canvasH),
  );
}

/// Pickup marker — green dot with a white ring (no number).
Future<BitmapDescriptor> _buildPickupMarker({double logical = 26.0}) async {
  const scale  = 3.0;
  final size   = logical * scale;
  final radius = size / 2;
  final center = Offset(radius, radius);

  final recorder = ui.PictureRecorder();
  final canvas   = Canvas(recorder);

  canvas.drawCircle(
    center.translate(0, 2 * scale), radius,
    Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 * scale),
  );
  canvas.drawCircle(center, radius, Paint()..color = AppTheme.accent);
  canvas.drawCircle(
    center, radius,
    Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * scale,
  );
  canvas.drawCircle(center, radius * 0.35, Paint()..color = Colors.white);

  final picture = recorder.endRecording();
  final img     = await picture.toImage(size.ceil(), size.ceil());
  final bytes   = await img.toByteData(format: ui.ImageByteFormat.png);
  if (bytes == null) return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
  return BitmapDescriptor.bytes(
      bytes.buffer.asUint8List(), imagePixelRatio: scale);
}

// Vector Material icon per vehicle type — deliberately not an emoji glyph:
// emoji rendered through a raw Canvas/TextPainter (as opposed to a normal
// widget tree) came out upside-down/mangled on some Android devices,
// depending on the system emoji font. Material icons are a bundled vector
// font, so they render identically (and right-side up) everywhere.
IconData _vehicleIconData(String vehicleType) => switch (vehicleType) {
      'tuk_tuk'    => Icons.electric_rickshaw,
      'motorcycle' => Icons.two_wheeler,
      'van'        => Icons.airport_shuttle,
      _            => Icons.local_taxi,
    };

/// Nearby-driver marker, scattered on the pre-booking map (Grab/PassApp-style)
/// to show real driver supply near the pickup point. Cached per vehicle type
/// since the icon is identical for every driver of that type — no need to
/// redraw per marker.
final Map<String, Future<BitmapDescriptor>> _vehicleMarkerCache = {};

Future<BitmapDescriptor> _buildVehicleMarker(String vehicleType) {
  return _vehicleMarkerCache.putIfAbsent(vehicleType, () async {
    if (vehicleType == 'tuk_tuk') return _loadTukTukAssetMarker();

    const scale   = 3.0;
    const logical = 44.0;
    final size    = logical * scale;

    final recorder = ui.PictureRecorder();
    final canvas   = Canvas(recorder);
    _paintVehicleGlyph(canvas, size, _vehicleIconData(vehicleType));

    final picture = recorder.endRecording();
    final img     = await picture.toImage(size.ceil(), size.ceil());
    final bytes   = await img.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) return BitmapDescriptor.defaultMarker;
    return BitmapDescriptor.bytes(
        bytes.buffer.asUint8List(), imagePixelRatio: scale);
  });
}

// assets/ride.png is a pre-made 512×454 tuk-tuk illustration (teal, with a
// location pin above it) — used as-is rather than hand-drawn, per request.
// imagePixelRatio scales it down from its native pixel size to a sane
// on-map display width.
Future<BitmapDescriptor> _loadTukTukAssetMarker() async {
  final data = await rootBundle.load('assets/ride.png');
  const displayWidthDp = 48.0;
  const nativeWidthPx  = 512.0;
  return BitmapDescriptor.bytes(
    data.buffer.asUint8List(),
    imagePixelRatio: nativeWidthPx / displayWidthDp,
  );
}

void _paintVehicleGlyph(Canvas canvas, double size, IconData iconData) {
  final center = Offset(size / 2, size / 2);
  final tp = TextPainter(
    text: TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontSize: size * 0.9,
        fontFamily: iconData.fontFamily,
        package: iconData.fontPackage,
        color: AppTheme.accent,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: size * 0.02,
            offset: Offset(0, size * 0.01),
          ),
        ],
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
}

// ─── Screen ───────────────────────────────────────────────────────────────────
// step 0 = "Where to?" landing   step 1 = destination search   step 2 = confirm

class RideBookingScreen extends StatefulWidget {
  final FamilyMember? forFamilyMember;
  // Jump straight into "no destination" booking (pickup only, tell the
  // driver in person) — used by the dedicated home-screen shortcut.
  final bool skipDestination;
  // Pre-fill the destination and jump straight to the confirm screen —
  // used by "Book a ride to this EV station" deep links.
  final String? initialDestAddress;
  final LatLng?  initialDestLatLng;
  const RideBookingScreen({
    super.key,
    this.forFamilyMember,
    this.skipDestination = false,
    this.initialDestAddress,
    this.initialDestLatLng,
  });
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

  // ── Pickup search (type a name instead of dragging the map) ────────────────
  final _pickupSearchCtrl  = TextEditingController();
  final _pickupSearchFocus = FocusNode();
  List<PlaceResult> _pickupSearchResults = [];
  bool   _pickupSearching  = false;
  Timer? _pickupSearchDebounce;

  // Dedicated focus node for the "Where to?" field on the unified location
  // page — without its own explicit node it shared an implicit one that
  // could steal focus back from the pickup field on rebuild.
  final _destSearchFocus = FocusNode();

  // ── Destination search ──────────────────────────────────────────────────────
  final _searchCtrl = TextEditingController();
  List<PlaceResult> _searchResults = [];
  bool   _searching  = false;
  Timer? _searchDebounce;
  // Multiple drop-off stops — last stop is always the final destination
  final List<_WayStop> _stops = [_WayStop()];
  int    _activeStopIdx = 0;
  int    _whereToTab    = 0; // 0=Recent  1=Suggestions  2=Saved
  // Rider hasn't picked a destination yet — they'll tell the driver in
  // person once onboard, and the fare is metered/GPS-calculated at the end.
  bool   _noDestination = false;

  // Getters for backward-compat with route/booking methods
  String  get _destAddress => _stops.last.address;
  LatLng? get _destLatLng  => _stops.last.latLng;

  // Unified location-search page (step 0): "Map" button switches to the
  // interactive drag-to-set pickup map when the pickup field is focused.
  bool _pickupMapView = false;

  // Which field autofocuses when the unified location-search page is
  // (re)entered — true when navigated here specifically to set the
  // destination (e.g. tapping the "Where to?" row), false (default)
  // focuses pickup instead.
  bool _focusDestinationOnEntry = false;

  // ── Destination map picker ──────────────────────────────────────────────────
  bool   _choosingDestOnMap = false;
  GoogleMapController? _destMapCtrl;
  LatLng _destMapCenter  = const LatLng(11.5680, 104.9195);
  String _mapPickerAddress = '';
  bool   _geocodingDest  = false;

  // ── Step-1 mini-map ─────────────────────────────────────────────────────────
  GoogleMapController? _step1MapCtrl;

  // ── Nearby drivers (map markers, Grab/PassApp-style) ────────────────────────
  List<NearbyMapDriverModel> _nearbyDrivers = [];
  Map<int, BitmapDescriptor> _nearbyDriverIcons = {};
  Timer? _nearbyDriversTimer;

  // ── Confirm ─────────────────────────────────────────────────────────────────
  GoogleMapController? _confirmMapCtrl;
  List<LatLng>         _routePoints   = [];   // combined (for camera fit)
  List<List<LatLng>>   _segmentRoutes = [];   // one list of points per segment
  int    _etaMinutes  = 0;
  double _distanceKm  = 0.0;
  bool   _routeLoading = false;
  Map<String, FareInfo> _fareByType  = {};
  bool                  _fareLoading = false;

  // Labeled marker icons — built once per booking session
  BitmapDescriptor? _pickupIcon;
  List<_LabeledMarker> _stopMarkers = [];

  String   _selectedRide       = 'Tuk-tuk';

  // Fetched once from GET /vehicle-types — falls back to _kFallbackRideTypes
  // if the call fails so the screen still functions.
  List<_RideType> _visibleRideTypes = _kFallbackRideTypes;
  bool             _rideTypesLoading = true;

  // No-destination confirm screen: starts collapsed showing only the
  // Tuk-tuk row — dragging/scrolling the sheet up reveals the full list.
  bool _showAllRideOptions = false;

  // ── Ride category filter (All / Tuk Tuk / Car / Bike) ───────────────────────
  String _rideCategory = 'All';

  static String _wheelCategory(String serviceType) {
    switch (serviceType) {
      case 'motorcycle': return 'Bike';
      case 'tuk_tuk':     return 'Tuk Tuk';
      default:            return 'Car'; // standard/premium/shared/van
    }
  }

  List<_RideType> get _filteredRideTypes => _rideCategory == 'All'
      ? _visibleRideTypes
      : _visibleRideTypes
          .where((r) => _wheelCategory(r.serviceType) == _rideCategory)
          .toList();

  Future<void> _loadVehicleTypes() async {
    try {
      final types = await ApiService.getVehicleTypes();
      if (!mounted || types.isEmpty) return;
      setState(() {
        _visibleRideTypes = types
            .map((v) => _RideType(
                  name:        v.label,
                  serviceType: v.serviceType,
                  icon:        v.icon,
                  eta:         '',
                  desc:        v.seatsLabel,
                  base:        v.pricing.base,
                ))
            .toList();
        _rideTypesLoading = false;
        // Keep selection valid: default to tuk_tuk if present, else first.
        if (!_visibleRideTypes.any((r) => r.name == _selectedRide)) {
          _selectedRide = _visibleRideTypes
              .firstWhere((r) => r.serviceType == 'tuk_tuk',
                  orElse: () => _visibleRideTypes.first)
              .name;
        }
      });
    } catch (e, s) {
      AppLog.e('RideTypes', 'getVehicleTypes failed', e, s);
      if (mounted) setState(() => _rideTypesLoading = false);
    }
  }

  String   _paymentMethod      = 'cash';
  bool     _isScheduled     = false;
  DateTime _scheduledTime   = DateTime.now().add(const Duration(hours: 1));
  bool     _isBooking       = false;

  // Surge pricing
  SurgeInfo? _surgeInfo;

  // Saved places (Home / Work shortcuts)
  List<SavedPlaceModel> _savedPlaces = [];

  // Promo code
  String? _promoCode;
  double? _promoDiscount;   // discount amount in KHR
  bool    _promoLoading = false;
  String? _promoError;
  String?  _bookError;

  // ── Lifecycle ────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    _pickupSearchCtrl.addListener(_onPickupSearchChanged);
    appLocale.addListener(_onLocaleChanged);
    _detectGps();
    _loadSurge();
    _loadSavedPlaces();
    _loadVehicleTypes();
    if (widget.skipDestination) _skipDestination();
    if (widget.initialDestAddress != null && widget.initialDestLatLng != null) {
      _stops[0].address = widget.initialDestAddress!;
      _stops[0].latLng  = widget.initialDestLatLng;
      WidgetsBinding.instance.addPostFrameCallback((_) => _goToStep(2));
    }
  }

  void _onLocaleChanged() => setState(() {});

  Future<void> _loadSurge() async {
    try {
      double? lat, lng;
      try {
        final pos = await Geolocator.getLastKnownPosition() ??
            await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.low,
            );
        lat = pos.latitude;
        lng = pos.longitude;
      } catch (_) {}
      final info = await ApiService.checkSurge(lat: lat, lng: lng);
      if (mounted && info.surgeActive) setState(() => _surgeInfo = info);
    } catch (_) {}
  }

  Future<void> _loadSavedPlaces() async {
    try {
      final places = await ApiService.getSavedPlaces();
      if (!mounted) return;
      setState(() => _savedPlaces = places.take(4).toList());
      // Saved places may finish loading after the GPS pickup was already
      // reverse-geocoded — re-check now in case it's actually a match.
      final match = _matchSavedPlace(_pickupCenter);
      if (match != null && _pickupAddress != match.label) {
        setState(() => _pickupAddress = match.label);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchDebounce?.cancel();
    _pickupSearchCtrl.dispose();
    _pickupSearchFocus.dispose();
    _pickupSearchDebounce?.cancel();
    _destSearchFocus.dispose();
    appLocale.removeListener(_onLocaleChanged);
    _pickupMapCtrl?.dispose();
    _destMapCtrl?.dispose();
    _step1MapCtrl?.dispose();
    _confirmMapCtrl?.dispose();
    _nearbyDriversTimer?.cancel();
    super.dispose();
  }

  // ── Nearby drivers ───────────────────────────────────────────────────────────
  // Fetched once entering step 1 (pickup is known by then) and refreshed
  // periodically while the rider is still choosing a destination — mirrors
  // Grab/PassApp showing live driver supply around the pickup point before
  // the ride is ever booked.

  void _startNearbyDriversPolling() {
    _loadNearbyDrivers();
    _nearbyDriversTimer?.cancel();
    _nearbyDriversTimer =
        Timer.periodic(const Duration(seconds: 15), (_) => _loadNearbyDrivers());
  }

  Future<void> _loadNearbyDrivers() async {
    try {
      final drivers = await ApiService.getNearbyMapDrivers(
        lat: _pickupCenter.latitude,
        lng: _pickupCenter.longitude,
      );
      if (!mounted) return;
      final located = drivers.where((d) => d.hasLocation).toList();
      final icons = <int, BitmapDescriptor>{};
      for (final d in located) {
        icons[d.id] = await _buildVehicleMarker(d.vehicleType);
      }
      if (!mounted) return;
      setState(() {
        _nearbyDrivers     = located;
        _nearbyDriverIcons = icons;
      });
    } catch (_) {
      // Best-effort supply display — leave whatever markers were already
      // showing rather than clearing them on a transient network error.
    }
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

  // Distance within which the current GPS position is considered "at" a
  // saved place (Home/Work/bookmark) — shows its friendly label instead of
  // the raw geocoded address.
  static const double _kSavedPlaceMatchMeters = 100;

  SavedPlaceModel? _matchSavedPlace(LatLng pos) {
    for (final place in _savedPlaces) {
      final dist = Geolocator.distanceBetween(
          pos.latitude, pos.longitude, place.lat, place.lng);
      if (dist <= _kSavedPlaceMatchMeters) return place;
    }
    return null;
  }

  Future<void> _reverseGeocodePickup(LatLng pos) async {
    final savedMatch = _matchSavedPlace(pos);
    if (savedMatch != null) {
      setState(() {
        _pickupAddress   = savedMatch.label;
        _geocodingPickup = false;
      });
      // Pickup moved — re-fetch route/fare if a destination is already
      // set, otherwise the estimate keeps reflecting the old pickup point.
      _fetchRoute();
      return;
    }
    setState(() => _geocodingPickup = true);
    final address = await MapsService.reverseGeocode(pos);
    if (!mounted) return;
    setState(() {
      _pickupAddress  = address ?? '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
      _geocodingPickup = false;
    });
    _fetchRoute();
  }

  // ── Pickup search ────────────────────────────────────────────────────────────

  void _onPickupSearchChanged() {
    _pickupSearchDebounce?.cancel();
    final q = _pickupSearchCtrl.text.trim();
    if (q.isEmpty) {
      setState(() { _pickupSearchResults = []; _pickupSearching = false; });
      return;
    }
    setState(() {}); // rebuild to show/hide clear button + results panel
    _pickupSearchDebounce =
        Timer(const Duration(milliseconds: 500), () => _searchPickupPlaces(q));
  }

  Future<void> _searchPickupPlaces(String q) async {
    setState(() => _pickupSearching = true);
    final results = await MapsService.searchAddress(q);
    if (!mounted) return;
    setState(() { _pickupSearchResults = results; _pickupSearching = false; });
  }

  void _selectPickupResult(PlaceResult r) {
    setState(() {
      _pickupAddress       = r.address;
      _pickupCenter        = r.latLng;
      _pickupSearchResults = [];
    });
    _pickupSearchCtrl.clear();
    _pickupSearchFocus.unfocus();
    _pickupMapCtrl?.animateCamera(CameraUpdate.newLatLng(r.latLng));
    // Pickup moved — re-fetch route/fare if a destination is already set,
    // otherwise the estimate keeps reflecting the old pickup point.
    _fetchRoute();
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
    if (_activeStopIdx < 0) return;
    setState(() {
      _stops[_activeStopIdx].address = r.address;
      _stops[_activeStopIdx].latLng  = r.latLng;
    });
    _afterStopFilled();
  }

  void _selectPreset(_Preset p) {
    if (_activeStopIdx < 0) return;
    setState(() {
      _stops[_activeStopIdx].address = p.name;
      _stops[_activeStopIdx].latLng  = p.latLng;
    });
    _afterStopFilled();
  }

  void _selectSavedPlace(SavedPlaceModel place) {
    if (_activeStopIdx < 0) return;
    setState(() {
      _stops[_activeStopIdx].address = place.address;
      _stops[_activeStopIdx].latLng  = LatLng(place.lat, place.lng);
    });
    _afterStopFilled();
  }

  SavedPlaceModel? _findSavedPlace(List<String> labelMatches) {
    for (final p in _savedPlaces) {
      final l = p.label.toLowerCase();
      if (labelMatches.any((m) => l.contains(m))) return p;
    }
    return null;
  }

  void _showAllSavedPlaces() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.appSurface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(AppLocalizations.of(context).savedPlaces,
                  style: TextStyle(
                      color: context.appTextPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
            ),
          ),
          if (_savedPlaces.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(AppLocalizations.of(context).noSavedPlacesYet,
                  style: TextStyle(color: context.appTextSecondary)),
            )
          else
            ..._savedPlaces.map((p) => _DestTile(
                  icon: p.label.toLowerCase().contains('home')
                      ? Icons.home_outlined
                      : p.label.toLowerCase().contains('work') ||
                              p.label.toLowerCase().contains('office')
                          ? Icons.work_outline
                          : Icons.bookmark_outline,
                  iconColor: AppTheme.accent,
                  title: p.label,
                  onTap: () {
                    Navigator.pop(context);
                    _selectSavedPlace(p);
                  },
                )),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  void _afterStopFilled() {
    final searchFrom = _activeStopIdx < 0 ? 0 : _activeStopIdx + 1;
    final next = _stops.indexWhere((s) => !s.isFilled, searchFrom);
    if (next == -1) {
      setState(() { _activeStopIdx = -1; _searchCtrl.clear(); });
    } else {
      setState(() { _activeStopIdx = next; _searchCtrl.clear(); });
    }
    _buildMarkerIcons().then((_) => _fitStep1Camera());
  }


  // ── Navigation ───────────────────────────────────────────────────────────────

  void _goToStep(int s) {
    setState(() {
      _step = s;
      if (s != 1) _choosingDestOnMap = false;
    });
    if (s == 1 || (s == 2 && _noDestination)) {
      _startNearbyDriversPolling();
    } else {
      _nearbyDriversTimer?.cancel();
    }
    if (s == 2) {
      if (_noDestination) {
        _buildPickupOnlyMarker();
      } else {
        _fetchRoute();
        _buildMarkerIcons();
      }
    }
  }

  // Used in "no destination" mode — just need the pickup pin, no route/fare.
  Future<void> _buildPickupOnlyMarker() async {
    final pickup = await _buildPickupMarker();
    if (!mounted) return;
    setState(() => _pickupIcon = pickup);
  }

  void _skipDestination() {
    setState(() {
      _noDestination = true;
      _stops
        ..clear()
        ..add(_WayStop());
    });
    _goToStep(2);
  }

  Future<void> _buildMarkerIcons() async {
    final pickup  = await _buildPickupMarker();
    final single  = _stops.length == 1;
    final markers = await Future.wait(
      List.generate(_stops.length, (i) => _buildLabeledMarker(
        i + 1,
        _stops[i].address,
        bg: i == _stops.length - 1
            ? const Color(0xFFE53935)  // red for final destination
            : const Color(0xFFFF9800), // orange for intermediate stops
        showNumber: !single,          // no number when there is only one stop
      )),
    );
    if (!mounted) return;
    setState(() {
      _pickupIcon  = pickup;
      _stopMarkers = markers;
    });
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
      setState(() {
        _step = 0;
        _searchResults = [];
        // Clear the previously drawn route line so it doesn't linger when
        // landing back on the default pickup screen.
        _segmentRoutes = [];
        _routePoints   = [];
      });
    } else if (_step > 0) {
      Navigator.pop(context);
    }
  }

  // ── Payment method ────────────────────────────────────────────────────────────

  static const _kPaymentMethods = ['cash', 'wallet', 'aba', 'acleda', 'wing'];

  static String _paymentLabel(String method) {
    switch (method) {
      case 'wallet': return 'ROTEH Pay';
      case 'aba':    return 'ABA Pay';
      case 'acleda': return 'ACLEDA';
      case 'wing':   return 'Wing Money';
      default:       return 'Cash';
    }
  }

  void _showPromoSheet(BuildContext ctx) {
    final ctrl = TextEditingController(text: _promoCode ?? '');
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: context.appSurface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (_, setLocal) {
          Future<void> apply() async {
            final code = ctrl.text.trim().toUpperCase();
            if (code.isEmpty) return;
            setLocal(() { _promoLoading = true; _promoError = null; });
            bool success = false;
            try {
              final fare = _fareByType[_visibleRideTypes
                  .firstWhere((r) => r.name == _selectedRide,
                      orElse: () => _visibleRideTypes.first)
                  .serviceType];
              final result = await ApiService.validatePromoCode(
                code:        code,
                serviceType: 'rides',
                orderAmount: fare?.total ?? 0,
              );
              if (!mounted) return;
              setState(() {
                _promoCode     = code;
                _promoDiscount = result.discountAmount;
                _promoError    = null;
              });
              success = true;
              Navigator.pop(sheetCtx);
            } on ApiException catch (e) {
              setLocal(() { _promoError = e.message; _promoLoading = false; });
            } catch (_) {
              setLocal(() { _promoError = 'Invalid or expired code.'; _promoLoading = false; });
            } finally {
              if (!success) setLocal(() => _promoLoading = false);
            }
          }

          return Padding(
            padding: EdgeInsets.only(
                left: 20, right: 20, top: 20,
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24),
            child: Column(mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2)),
              )),
              SizedBox(height: 16),
              Text(AppLocalizations.of(context).promoCodeTitle,
                  style: TextStyle(color: context.appTextPrimary,
                      fontWeight: FontWeight.w800, fontSize: 17)),
              SizedBox(height: 14),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: ctrl,
                    autofocus: true,
                    textCapitalization: TextCapitalization.characters,
                    style: TextStyle(
                        color: context.appTextPrimary,
                        fontWeight: FontWeight.w700, letterSpacing: 1.5),
                    decoration: InputDecoration(
                      hintText: 'e.g. SAVE10',
                      hintStyle: TextStyle(
                          color: context.appTextSecondary,
                          fontWeight: FontWeight.normal, letterSpacing: 0),
                      filled: true, fillColor: context.appCardBg,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                    ),
                    onSubmitted: (_) => apply(),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _promoLoading ? null : apply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _promoLoading
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(AppLocalizations.of(context).apply,
                          style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ]),
              if (_promoError != null) ...[
                const SizedBox(height: 8),
                Text(_promoError!,
                    style: const TextStyle(
                        color: AppTheme.danger, fontSize: 13)),
              ],
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  Navigator.pop(sheetCtx);
                  Navigator.push(ctx,
                      MaterialPageRoute(
                          builder: (_) => const PromoScreen()));
                },
                child: Text(AppLocalizations.of(context).browseVouchers,
                    style: TextStyle(
                        color: AppTheme.accent,
                        fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            ]),
          );
        },
      ),
    );
  }

  void _showPaymentSheet(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: context.appSurface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            margin: EdgeInsets.symmetric(vertical: 10),
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: context.appCardBg, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(AppLocalizations.of(context).paymentMethod,
                  style: TextStyle(color: context.appTextPrimary,
                      fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
          ..._kPaymentMethods.map((m) => ListTile(
            leading: Icon(
              m == 'cash'   ? Icons.money :
              m == 'wallet' ? Icons.account_balance_wallet_outlined :
              Icons.credit_card_outlined,
              color: _paymentMethod == m ? AppTheme.accent : context.appTextSecondary,
            ),
            title: Text(_paymentLabel(m),
                style: TextStyle(
                    color: _paymentMethod == m ? AppTheme.accent : context.appTextPrimary,
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
      _routeLoading  = true;
      _fareLoading   = true;
      _routePoints   = [];
      _segmentRoutes = [];
      _etaMinutes    = 0;
      _distanceKm    = 0;
      _fareByType    = {};
    });
    await Future.wait([_doFetchRoute(dest), _doFetchFares(dest)]);
  }

  Future<void> _doFetchRoute(LatLng dest) async {
    // Build ordered waypoints: pickup + all filled stops
    final waypoints = [
      _pickupCenter,
      ..._stops.where((s) => s.latLng != null).map((s) => s.latLng!),
    ];

    // Fetch each segment (origin→next) in parallel
    final results = await Future.wait(
      List.generate(waypoints.length - 1, (i) =>
        MapsService.getRoute(origin: waypoints[i], destination: waypoints[i + 1]),
      ),
    );
    if (!mounted) return;

    final segments = <List<LatLng>>[];
    int   totalEta  = 0;
    double totalKm  = 0.0;

    for (int i = 0; i < results.length; i++) {
      final r = results[i];
      if (r != null) {
        segments.add(r.points);
        totalEta += r.etaMinutes;
        totalKm  += r.distanceKm;
      } else {
        // Fallback: straight line for this segment
        segments.add([waypoints[i], waypoints[i + 1]]);
      }
    }

    final combined = segments.expand((pts) => pts).toList();

    setState(() {
      _routeLoading  = false;
      _segmentRoutes = segments;
      _routePoints   = combined;
      if (totalEta > 0) _etaMinutes = totalEta;
      if (totalKm  > 0) _distanceKm = totalKm;
    });

    if (combined.isNotEmpty) {
      final lats = combined.map((p) => p.latitude);
      final lngs = combined.map((p) => p.longitude);
      final sw = LatLng(lats.reduce((a,b) => a<b?a:b) - 0.005,
                        lngs.reduce((a,b) => a<b?a:b) - 0.005);
      final ne = LatLng(lats.reduce((a,b) => a>b?a:b) + 0.005,
                        lngs.reduce((a,b) => a>b?a:b) + 0.005);
      _confirmMapCtrl?.animateCamera(
        CameraUpdate.newLatLngBounds(LatLngBounds(southwest: sw, northeast: ne), 64),
      );
    }
  }

  Future<void> _doFetchFares(LatLng dest) async {
    try {
      // Intermediate stops (every filled stop except the final destination)
      // so the fare reflects the full route, not just a direct pickup→dest
      // line — otherwise the pre-booking estimate undercounts any detour.
      final intermediateStops = _stops.length > 1
          ? _stops.sublist(0, _stops.length - 1).where((s) => s.isFilled).toList()
          : const <_WayStop>[];
      final estimate = await ApiService.estimateRide(
        pickupLat:   _pickupCenter.latitude,
        pickupLng:   _pickupCenter.longitude,
        dropoffLat:  dest.latitude,
        dropoffLng:  dest.longitude,
        stops: intermediateStops.isEmpty
            ? null
            : List.generate(intermediateStops.length, (i) => {
                'order':   i + 1,
                'address': intermediateStops[i].address,
                'lat':     intermediateStops[i].latLng!.latitude,
                'lng':     intermediateStops[i].latLng!.longitude,
              }),
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
    // Still resolving real GPS — _pickupCenter is sitting on the hardcoded
    // placeholder coordinate at this point, so booking now would silently
    // use the wrong pickup location.
    if (_gpsLoading) return;
    if (_pickupAddress.isEmpty) return;
    if (!_noDestination && (_destAddress.isEmpty || _destLatLng == null)) return;
    setState(() { _isBooking = true; _bookError = null; });
    final type = _visibleRideTypes.firstWhere((r) => r.name == _selectedRide,
        orElse: () => _visibleRideTypes.first);
    // Intermediate stops sent inline with ride creation so the backend
    // persists them atomically — a driver app that fetches the ride right
    // after creation will already see them.
    final intermediateStops = (!_noDestination && _stops.length > 1)
        ? _stops.sublist(0, _stops.length - 1).where((s) => s.isFilled).toList()
        : const <_WayStop>[];
    try {
      final ride = await ApiService.createRide(
        pickupAddress:  _pickupAddress,
        dropoffAddress: _noDestination ? null : _destAddress,
        pickupLat:      _pickupCenter.latitude,
        pickupLng:      _pickupCenter.longitude,
        dropoffLat:     _noDestination ? null : _destLatLng!.latitude,
        dropoffLng:     _noDestination ? null : _destLatLng!.longitude,
        noDestination:  _noDestination,
        serviceType:    type.serviceType,
        vehicleType:    type.serviceType,
        paymentMethod:  _paymentMethod,
        promoCode:      _promoCode,
        passengerName:  widget.forFamilyMember?.name,
        passengerPhone: widget.forFamilyMember?.phone,
        familyMemberId: widget.forFamilyMember?.id,
        scheduledAt: _isScheduled
            ? '${_scheduledTime.year}-'
              '${_scheduledTime.month.toString().padLeft(2,'0')}-'
              '${_scheduledTime.day.toString().padLeft(2,'0')} '
              '${_scheduledTime.hour.toString().padLeft(2,'0')}:'
              '${_scheduledTime.minute.toString().padLeft(2,'0')}:00'
            : null,
        stops: intermediateStops.isEmpty
            ? null
            : List.generate(intermediateStops.length, (i) => {
                'order':   i + 1,
                'address': intermediateStops[i].address,
                'lat':     intermediateStops[i].latLng!.latitude,
                'lng':     intermediateStops[i].latLng!.longitude,
              }),
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
            from:         _pickupAddress.isNotEmpty ? _pickupAddress : (ride.pickupAddress.isNotEmpty ? ride.pickupAddress : '--'),
            to:           _noDestination
                ? 'Tell driver on arrival'
                : (_destAddress.isNotEmpty ? _destAddress : (ride.dropoffAddress.isNotEmpty ? ride.dropoffAddress : '--')),
            isScheduled:  _isScheduled,
            pickupLatLng: _pickupCenter,
            destLatLng:   _noDestination ? null : _destLatLng,
            wayStops:     (!_noDestination && _stops.length > 1)
                ? _stops
                    .sublist(0, _stops.length - 1)
                    .where((s) => s.isFilled)
                    .map((s) => TripStop(address: s.address, latLng: s.latLng!))
                    .toList()
                : const [],
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
    // Step 0: unified pickup + destination search landing — no top header
    if (_step == 0) {
      return Scaffold(
        backgroundColor: context.appBackground,
        body: _pickupMapView ? _buildWhereTo() : _buildLocationSearch(),
      );
    }
    // Step 2 — full-screen map, no header
    if (_step == 2) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: _noDestination ? _buildNoDestinationConfirm() : _buildConfirm(),
      );
    }
    return Scaffold(
      backgroundColor: context.appBackground,
      body: SafeArea(
        child: Column(children: [
          _StepHeader(step: _step - 1, onBack: _onBack),
          Expanded(child: _buildDestination()),
        ]),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Step 0 — Unified location search (pickup + "Where to?" on one page)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildLocationSearch() {
    if (_choosingDestOnMap) return _buildDestinationMapPicker();

    final hasQuery = _searchCtrl.text.trim().isNotEmpty;
    final pickupSearchActive = _pickupSearchFocus.hasFocus &&
        _pickupSearchCtrl.text.trim().isNotEmpty;

    // Shows the real resolved current location whenever the field isn't
    // actively being edited — tapping directly into the field is what
    // clears it for a fresh search (see the field's onTap below); just
    // navigating here (e.g. tapping the pickup row elsewhere) does not
    // autofocus this field, so there's no race with this sync. Listener
    // removed for the assignment — setting `.text` here would otherwise
    // fire it synchronously during build and call setState, which throws.
    if (!_pickupSearchFocus.hasFocus &&
        _pickupAddress.isNotEmpty &&
        _pickupAddress != 'Detecting location…' &&
        _pickupSearchCtrl.text != getDisplayLocation(name: '', address: _pickupAddress)) {
      _pickupSearchCtrl.removeListener(_onPickupSearchChanged);
      _pickupSearchCtrl.text = getDisplayLocation(name: '', address: _pickupAddress);
      _pickupSearchCtrl.addListener(_onPickupSearchChanged);
    }

    return SafeArea(
      child: Column(children: [
        // ── Header: close / Cambodia / Map ──────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(children: [
            GestureDetector(
              onTap: () {
                // Reached here by editing pickup/destination from the
                // no-destination Choose Ride screen — return there instead
                // of leaving the flow entirely.
                if (_noDestination) {
                  setState(() => _step = 2);
                  return;
                }
                Navigator.maybePop(context);
              },
              child: Icon(Icons.close, color: context.appTextPrimary, size: 24),
            ),
            const Spacer(),
            Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('🇰🇭', style: TextStyle(fontSize: 15)),
              const SizedBox(width: 4),
              Text(AppLocalizations.of(context).cambodia,
                  style: TextStyle(color: context.appTextPrimary,
                      fontSize: 14, fontWeight: FontWeight.w600)),
            ]),
            const Spacer(),
            GestureDetector(
              onTap: () {
                if (_pickupSearchFocus.hasFocus) {
                  setState(() => _pickupMapView = true);
                } else if (_activeStopIdx >= 0) {
                  final activeStop = _stops[_activeStopIdx];
                  setState(() {
                    _destMapCenter     = activeStop.latLng ?? _pickupCenter;
                    _mapPickerAddress  = activeStop.address;
                    _choosingDestOnMap = true;
                  });
                }
              },
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.location_on_outlined, color: AppTheme.accent, size: 20),
                Text(AppLocalizations.of(context).mapLabel, style: TextStyle(color: context.appTextSecondary, fontSize: 11)),
              ]),
            ),
          ]),
        ),

        // ── Body ─────────────────────────────────────────────────────────────
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              // ── Pickup row (editable) ───────────────────────────────────
              Row(key: const ValueKey('pickup_row'), crossAxisAlignment: CrossAxisAlignment.center, children: [
                _geocodingPickup || _gpsLoading
                    ? SizedBox(
                        width: 12, height: 12,
                        child: CircularProgressIndicator(color: AppTheme.accent, strokeWidth: 2),
                      )
                    : Container(
                        width: 12, height: 12,
                        decoration: const BoxDecoration(color: AppTheme.accent, shape: BoxShape.circle),
                      ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    key: const ValueKey('pickup_search_field'),
                    controller: _pickupSearchCtrl,
                    focusNode:  _pickupSearchFocus,
                    // Never autofocuses — arriving here (e.g. via the
                    // pickup row) should just display the current value;
                    // only an explicit tap on the field opens the keyboard
                    // and clears it for a fresh search (see onTap below).
                    // Tapping in to change pickup clears the old resolved
                    // address so the field shows the "Pickup location"
                    // placeholder for a fresh search, instead of requiring
                    // the old text to be manually deleted first.
                    onTap: () {
                      if (_pickupSearchCtrl.text == getDisplayLocation(name: '', address: _pickupAddress)) {
                        _pickupSearchCtrl.clear();
                      }
                    },
                    style: TextStyle(color: context.appTextPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: 'Pickup location',
                      hintStyle: TextStyle(color: context.appTextSecondary, fontSize: 14),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      suffixIcon: pickupSearchActive
                          ? IconButton(
                              icon: Icon(Icons.close, size: 16, color: context.appTextSecondary),
                              onPressed: () => _pickupSearchCtrl.clear(),
                            )
                          : null,
                    ),
                  ),
                ),
              ]),

              if (pickupSearchActive) ...[
                const SizedBox(height: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: _pickupSearching
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator(color: AppTheme.accent)),
                        )
                      : _pickupSearchResults.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(AppLocalizations.of(context).noResultsFound,
                                  style: TextStyle(color: context.appTextSecondary)),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              itemCount: _pickupSearchResults.length,
                              itemBuilder: (_, i) {
                                final r = _pickupSearchResults[i];
                                return _DestTile(
                                  icon: Icons.location_on,
                                  iconColor: AppTheme.accent,
                                  title: getDisplayLocation(name: r.name, address: r.address),
                                  onTap: () => _selectPickupResult(r),
                                );
                              },
                            ),
                ),
              ],

              // ── Stop rows ────────────────────────────────────────────────
              // Keyed by stop identity so Flutter doesn't lose this row's
              // TextField focus/state when sibling widgets above it (e.g.
              // the pickup results panel) toggle in and out, shifting
              // everyone's position in this list.
              ...List.generate(_stops.length, (i) {
                final stop     = _stops[i];
                final isActive = i == _activeStopIdx;
                final isLast   = i == _stops.length - 1;

                return Column(key: ValueKey('stop_row_$i'), children: [
                  Row(children: [
                    SizedBox(width: 6),
                    Container(width: 2, height: 20,
                        color: context.appCardBg.withValues(alpha: 0.8)),
                  ]),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: isActive
                        ? BoxDecoration(
                            color: context.appCardBg.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
                          )
                        : null,
                    child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                      isLast && _stops.length == 1
                        ? const Icon(Icons.location_on, color: AppTheme.accentOrange, size: 20)
                        : Container(
                            width: 20, height: 20,
                            decoration: BoxDecoration(
                              color: (isLast ? const Color(0xFFE53935) : AppTheme.warning)
                                  .withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isLast ? const Color(0xFFE53935) : AppTheme.warning,
                                width: 1.5),
                            ),
                            child: Center(
                              child: Text('${i + 1}',
                                  style: TextStyle(
                                    color: isLast ? const Color(0xFFE53935) : AppTheme.warning,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800)),
                            ),
                          ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: stop.isFilled
                          ? GestureDetector(
                              onTap: () => setState(() {
                                _stops[i].address = '';
                                _stops[i].latLng  = null;
                                _activeStopIdx    = i;
                                _searchCtrl.clear();
                              }),
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 9),
                                child: Row(children: [
                                  Expanded(
                                    child: Text(getDisplayLocation(name: '', address: stop.address),
                                        style: TextStyle(color: context.appTextPrimary,
                                            fontSize: 14, fontWeight: FontWeight.w500),
                                        maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ),
                                  SizedBox(width: 6),
                                  Icon(Icons.check_circle, color: AppTheme.success, size: 16),
                                ]),
                              ),
                            )
                          : isActive
                              ? TextField(
                                  controller: _searchCtrl,
                                  focusNode:  i == 0 ? _destSearchFocus : null,
                                  autofocus:  i == 0 && _focusDestinationOnEntry,
                                  style: TextStyle(color: context.appTextPrimary, fontSize: 14),
                                  decoration: InputDecoration(
                                    hintText: i == 0 ? 'Where to?' : 'Stop ${i + 1}',
                                    hintStyle: TextStyle(color: context.appTextSecondary, fontSize: 14),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(vertical: 7),
                                    suffixIcon: hasQuery
                                      ? IconButton(
                                          icon: Icon(Icons.close, size: 16, color: context.appTextSecondary),
                                          onPressed: () => _searchCtrl.clear(),
                                        )
                                      : null,
                                  ),
                                )
                              : GestureDetector(
                                  onTap: () => setState(() { _activeStopIdx = i; _searchCtrl.clear(); }),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 9),
                                    child: Text(i == 0 ? 'Where to?' : 'Stop ${i + 1}',
                                        style: TextStyle(color: context.appTextSecondary, fontSize: 14)),
                                  ),
                                ),
                      ),
                      if (_stops.length > 1)
                        GestureDetector(
                          onTap: () => setState(() {
                            _stops.removeAt(i);
                            if (_activeStopIdx >= _stops.length || _activeStopIdx == i) {
                              _activeStopIdx = _stops.every((s) => s.isFilled)
                                  ? -1
                                  : _stops.indexWhere((s) => !s.isFilled);
                            }
                          }),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                            child: Icon(Icons.close, size: 16, color: context.appTextSecondary),
                          ),
                        ),
                    ]),
                  ),
                ]);
              }),

              // ── Add a stop ───────────────────────────────────────────────
              if (_stops.length < 5) ...[
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    final unfilled = _stops.indexWhere((s) => !s.isFilled);
                    if (unfilled != -1) {
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
                      child: Icon(Icons.add, size: 14, color: AppTheme.accent),
                    ),
                    SizedBox(width: 10),
                    Text(AppLocalizations.of(context).addAStop,
                        style: TextStyle(color: AppTheme.accent,
                            fontSize: 14, fontWeight: FontWeight.w500)),
                  ]),
                ),
              ],

              // ── Quick-access shortcuts: Home / Office / Saved / Airport ──
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                _QuickPlaceButton(
                  icon: Icons.add_home_outlined,
                  label: 'Home',
                  onTap: () {
                    if (_activeStopIdx < 0) return;
                    final home = _findSavedPlace(['home']);
                    if (home != null) {
                      _selectSavedPlace(home);
                    } else {
                      Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const SavedPlacesScreen()));
                    }
                  },
                ),
                _QuickPlaceButton(
                  icon: Icons.add_business_outlined,
                  label: 'Office',
                  onTap: () {
                    if (_activeStopIdx < 0) return;
                    final office = _findSavedPlace(['work', 'office']);
                    if (office != null) {
                      _selectSavedPlace(office);
                    } else {
                      Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const SavedPlacesScreen()));
                    }
                  },
                ),
                _QuickPlaceButton(
                  icon: Icons.bookmark_border,
                  label: 'Saved',
                  onTap: _showAllSavedPlaces,
                ),
                _QuickPlaceButton(
                  icon: Icons.flight_outlined,
                  label: 'Airport',
                  onTap: () {
                    if (_activeStopIdx < 0) return;
                    _selectPreset(_kPresets.first);
                  },
                ),
              ]),

              const SizedBox(height: 8),
              Divider(height: 24, color: context.appCardBg),

              // ── Set location later (metered / no destination) ────────────
              _DestTile(
                icon: Icons.schedule_outlined,
                iconColor: AppTheme.accentOrange,
                title: 'Set location later',
                onTap: _skipDestination,
              ),

              // ── Search results / recent+suggestions ───────────────────────
              if (hasQuery) ...[
                if (_searching)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator(color: AppTheme.accent)),
                  )
                else if (_searchResults.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(AppLocalizations.of(context).noResultsFound,
                        style: TextStyle(color: context.appTextSecondary)),
                  )
                else
                  ..._searchResults.map((r) {
                    final isAlreadySelected = _stops.any((s) => s.address == r.address);
                    return _DestTile(
                      icon: Icons.location_on,
                      iconColor: AppTheme.accent,
                      title: getDisplayLocation(name: r.name, address: r.address),
                      trailing: isAlreadySelected
                          ? const Icon(Icons.check_circle, color: AppTheme.success, size: 20)
                          : null,
                      onTap: () => _selectResult(r),
                    );
                  }),
              ] else
                ..._kPresets.map((p) {
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
                }),
            ],
          ),
        ),

        // ── Confirm button (shown when all stops are filled) ─────────────────
        if (_stops.every((s) => s.isFilled))
          Container(
            decoration: BoxDecoration(
              color: context.appSurface,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 16, offset: const Offset(0, -4)),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _noDestination = false;
                  _goToStep(2);
                },
                style: AppTheme.confirmButtonStyle(),
                child: Text(_stops.length > 1 ? 'Confirm destinations' : 'Confirm destination'),
              ),
            ),
          ),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Step 0 — "Where to?" landing (map-based pickup adjuster)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildWhereTo() {
    return Stack(children: [
      GoogleMap(
        key: ValueKey('pickup_map_${appLocale.value.languageCode}'),
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
        minMaxZoomPreference: MinMaxZoomPreference(10, 20),
        onCameraMove: (pos) => _pickupCenter = pos.target,
        // Skip while GPS is still resolving — otherwise the map's initial
        // render (still sitting on the hardcoded placeholder center) fires
        // onCameraIdle immediately and reverse-geocodes that placeholder
        // into a real-looking street address, which then briefly displays
        // in place of "Detecting location…" as if it were the user's
        // actual position.
        onCameraIdle: () { if (!_gpsLoading) _reverseGeocodePickup(_pickupCenter); },
      ),

      Center(child: _Crosshair()),

      // Back + GPS buttons
      SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MapFab(
                icon: Icons.arrow_back_ios_new,
                onTap: () {
                  // Reached via the "Map" button on the unified location
                  // search page — return there instead of leaving the flow.
                  if (_pickupMapView) {
                    setState(() => _pickupMapView = false);
                    return;
                  }
                  // Reached from the no-destination confirm screen's pickup
                  // row — return there instead of leaving the flow.
                  if (_noDestination) {
                    setState(() => _step = 2);
                    return;
                  }
                  Navigator.maybePop(context);
                },
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
          child: Builder(builder: (context) {
            final pickupSearchActive = _pickupSearchFocus.hasFocus &&
                _pickupSearchCtrl.text.trim().isNotEmpty;
            // Keep the search field's text synced to the resolved address
            // whenever it's not actively being edited (GPS fix, map drag,
            // saved-place match, etc. all flow through _pickupAddress).
            // Listener is removed for the assignment — setting `.text`
            // inside build() would otherwise fire _onPickupSearchChanged
            // synchronously, which calls setState() during build and throws.
            if (!_pickupSearchFocus.hasFocus &&
                _pickupSearchCtrl.text != getDisplayLocation(name: '', address: _pickupAddress)) {
              _pickupSearchCtrl.removeListener(_onPickupSearchChanged);
              _pickupSearchCtrl.text = getDisplayLocation(name: '', address: _pickupAddress);
              _pickupSearchCtrl.addListener(_onPickupSearchChanged);
            }
            return Column(mainAxisSize: MainAxisSize.min, children: [
              // Current location / pickup search row
              Row(children: [
                _geocodingPickup || _gpsLoading
                    ? SizedBox(
                        width: 14, height: 14,
                        child: CircularProgressIndicator(
                            color: AppTheme.accent, strokeWidth: 2),
                      )
                    : Container(
                        width: 10, height: 10,
                        decoration: BoxDecoration(
                            color: AppTheme.accent, shape: BoxShape.circle),
                      ),
                SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _pickupSearchCtrl,
                    focusNode:  _pickupSearchFocus,
                    style: TextStyle(
                        color: context.appTextPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: 'Search pickup location',
                      hintStyle: TextStyle(color: context.appTextSecondary, fontSize: 14),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      suffixIcon: pickupSearchActive
                          ? IconButton(
                              icon: Icon(Icons.close, size: 16, color: context.appTextSecondary),
                              onPressed: () => _pickupSearchCtrl.clear(),
                            )
                          : null,
                    ),
                  ),
                ),
              ]),

              if (pickupSearchActive) ...[
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 240),
                  child: _pickupSearching
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator(color: AppTheme.accent)),
                        )
                      : _pickupSearchResults.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(AppLocalizations.of(context).noResultsFound,
                                  style: TextStyle(color: context.appTextSecondary)),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              itemCount: _pickupSearchResults.length,
                              itemBuilder: (_, i) {
                                final r = _pickupSearchResults[i];
                                return _DestTile(
                                  icon: Icons.location_on,
                                  iconColor: AppTheme.accent,
                                  title: getDisplayLocation(name: r.name, address: r.address),
                                  onTap: () => _selectPickupResult(r),
                                );
                              },
                            ),
                ),
              ] else ...[
                SizedBox(height: 12),

                // "Where to?" tappable pill — shows destination name when already set
                GestureDetector(
                  onTap: () => _goToStep(1),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: context.appCardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: _stops.last.isFilled
                          ? Border.all(color: AppTheme.accent.withValues(alpha: 0.4))
                          : null,
                    ),
                    child: Row(children: [
                      Icon(
                        _stops.last.isFilled ? Icons.location_on : Icons.search,
                        color: _stops.last.isFilled ? AppTheme.accentOrange : context.appTextSecondary,
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _stops.last.isFilled
                            ? Text(
                                getDisplayLocation(name: '', address: _stops.last.address),
                                style: TextStyle(
                                    color: context.appTextPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            : Text(AppLocalizations.of(context).whereTo,
                                style: TextStyle(color: context.appTextSecondary, fontSize: 15)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(AppLocalizations.of(context).now,
                            style: TextStyle(
                                color: AppTheme.accent,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ),
                    ]),
                  ),
                ),

                // ── Confirm Booking without a destination — tell the driver later ──
                if (!_stops.last.isFilled) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _skipDestination,
                      style: AppTheme.confirmButtonStyle(),
                      child: Text(AppLocalizations.of(context).confirmBooking),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Center(
                    child: Text(AppLocalizations.of(context).noDestinationNeeded,
                        style: TextStyle(color: context.appTextSecondary, fontSize: 11.5)),
                  ),
                ],

                // ── Saved places shortcuts (Home / Work / etc.) ────────────
                if (_savedPlaces.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _savedPlaces.map((place) {
                        final icon = place.label.toLowerCase().contains('home')
                            ? Icons.home_outlined
                            : place.label.toLowerCase().contains('work')
                                ? Icons.work_outline
                                : Icons.bookmark_outline;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _stops[0].address = place.address;
                              _stops[0].latLng  = LatLng(place.lat, place.lng);
                              _activeStopIdx    = -1;
                            });
                            _afterStopFilled();
                            _goToStep(1);
                          },
                          child: Container(
                            margin: EdgeInsets.only(right: 8),
                            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                            decoration: BoxDecoration(
                              color: context.appCardBg,
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(icon, size: 16, color: AppTheme.accent),
                              SizedBox(width: 6),
                              Text(place.label,
                                  style: TextStyle(
                                      color: context.appTextPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500)),
                            ]),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ]);
          }),
        ),
      ),
      const SizedBox(height: 12),
    ]);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Step 1 — Destination search
  // ═══════════════════════════════════════════════════════════════════════════

  // Mini-map markers for step 1 overlay
  Set<Marker> get _step1Markers {
    final set = <Marker>{
      Marker(
        markerId: const MarkerId('step1_pickup'),
        position: _pickupCenter,
        icon: _pickupIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
      for (int i = 0; i < _stops.length; i++)
        if (_stops[i].latLng != null)
          Marker(
            markerId: MarkerId('step1_stop_$i'),
            position: _stops[i].latLng!,
            icon: (_stopMarkers.length > i)
                ? _stopMarkers[i].icon
                : BitmapDescriptor.defaultMarkerWithHue(
                    i == _stops.length - 1
                        ? BitmapDescriptor.hueRed
                        : BitmapDescriptor.hueOrange),
            anchor: _stopMarkers.length > i
                ? _stopMarkers[i].anchor
                : const Offset(0.5, 1.0),
          ),
      ..._nearbyDriverMarkers,
    };
    return set;
  }

  // Nearby-driver markers only — reused by both the destination-search map
  // (_step1Markers, above) and the no-destination confirm map, which has no
  // pickup/stop pins of its own (pickup is shown via the fixed crosshair
  // instead).
  Set<Marker> get _nearbyDriverMarkers => {
        for (final d in _nearbyDrivers)
          Marker(
            markerId: MarkerId('nearby_driver_${d.id}'),
            position: LatLng(d.lat!, d.lng!),
            icon: _nearbyDriverIcons[d.id] ?? BitmapDescriptor.defaultMarker,
            anchor: const Offset(0.5, 0.5),
          ),
      };

  void _fitStep1Camera() {
    if (_step1MapCtrl == null) return;
    final filledLatLngs = [
      _pickupCenter,
      ..._stops.where((s) => s.latLng != null).map((s) => s.latLng!),
    ];
    if (filledLatLngs.length == 1) {
      _step1MapCtrl!.animateCamera(
          CameraUpdate.newLatLngZoom(filledLatLngs.first, 15));
      return;
    }
    final lats = filledLatLngs.map((l) => l.latitude);
    final lngs = filledLatLngs.map((l) => l.longitude);
    final sw = LatLng(lats.reduce((a, b) => a < b ? a : b) - 0.005,
                     lngs.reduce((a, b) => a < b ? a : b) - 0.005);
    final ne = LatLng(lats.reduce((a, b) => a > b ? a : b) + 0.005,
                     lngs.reduce((a, b) => a > b ? a : b) + 0.005);
    _step1MapCtrl!.animateCamera(
        CameraUpdate.newLatLngBounds(LatLngBounds(southwest: sw, northeast: ne), 48));
  }

  Widget _buildDestination() {
    if (_choosingDestOnMap) return _buildDestinationMapPicker();

    final hasQuery    = _searchCtrl.text.trim().isNotEmpty;
    final allFilled   = _stops.every((s) => s.isFilled);

    return Column(children: [

      // ── Live map (when all filled) or search results — shown first ────────
      Expanded(
        child: _activeStopIdx == -1
            // All stops confirmed → full live map showing route
            ? GoogleMap(
                key: ValueKey('step1_map_${appLocale.value.languageCode}'),
                onMapCreated: (c) {
                  _step1MapCtrl = c;
                  _fitStep1Camera();
                },
                initialCameraPosition:
                    CameraPosition(target: _pickupCenter, zoom: 14),
                style: _kDarkMapStyle,
                markers: _step1Markers,
                polylines: {
                  for (int i = 0; i < _segmentRoutes.length; i++)
                    if (_segmentRoutes[i].length >= 2)
                      Polyline(
                        polylineId: PolylineId('step1_seg_$i'),
                        points: _segmentRoutes[i],
                        color: const [
                          Color(0xFF00C48C),
                          Color(0xFFE53935),
                          Color(0xFF1976D2),
                          Color(0xFFFF9800),
                          Color(0xFF9C27B0),
                        ][i % 5],
                        width: 4,
                      ),
                },
                myLocationEnabled:       true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled:     false,
              )
            // Still searching / selecting → search results or tabs
            : _searching
                ? Center(
                    child: CircularProgressIndicator(color: AppTheme.accent))
                : hasQuery && _searchResults.isEmpty
                    ? Center(
                        child: Text(AppLocalizations.of(context).noResultsFound,
                            style: TextStyle(color: context.appTextSecondary)))
                    : hasQuery
                        ? ListView(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            children: _searchResults.map((r) {
                              final isAlreadySelected =
                                  _stops.any((s) => s.address == r.address);
                              return _DestTile(
                                icon: Icons.location_on,
                                iconColor: AppTheme.accent,
                                title: getDisplayLocation(name: r.name, address: r.address),
                                trailing: isAlreadySelected
                                    ? const Icon(Icons.check_circle,
                                        color: AppTheme.success, size: 20)
                                    : null,
                                onTap: () => _selectResult(r),
                              );
                            }).toList(),
                          )
                        : _buildWhereToTabs(),
      ),

      // ── Route card (Grab-style) ──────────────────────────────────────────
      Container(
        color: context.appSurface,
        padding: EdgeInsets.fromLTRB(14, 14, 14, 10),
        child: Column(children: [

          // ── "Where To?" label — moved below the map ──────────────────────
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(AppLocalizations.of(context).whereToTitle,
                  style: TextStyle(
                      color: context.appTextPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
            ),
          ),

          // ── Pickup row (read-only) ──────────────────────────────────────
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Container(
              width: 12, height: 12,
              decoration: BoxDecoration(color: AppTheme.accent, shape: BoxShape.circle),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                _pickupAddress.isEmpty ? 'Pickup location' : getDisplayLocation(name: '', address: _pickupAddress),
                style: TextStyle(color: context.appTextSecondary, fontSize: 13),
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
                SizedBox(width: 5),
                Container(width: 2, height: 20,
                    color: context.appCardBg.withValues(alpha: 0.8)),
              ]),

              // Stop row
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: isActive
                    ? BoxDecoration(
                        color: context.appCardBg.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
                      )
                    : null,
                child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  // Stop icon — numbered in the order each address was
                  // picked (Add a stop always appends, so an earlier stop's
                  // number never shifts). A lone destination with no
                  // intermediate stops gets a plain pin instead.
                  isLast && _stops.length == 1
                    ? const Icon(Icons.location_on, color: AppTheme.accentOrange, size: 20)
                    : Container(
                        width: 20, height: 20,
                        decoration: BoxDecoration(
                          color: (isLast ? const Color(0xFFE53935) : AppTheme.warning)
                              .withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isLast ? const Color(0xFFE53935) : AppTheme.warning,
                            width: 1.5),
                        ),
                        child: Center(
                          child: Text('${i + 1}',
                              style: TextStyle(
                                color: isLast ? const Color(0xFFE53935) : AppTheme.warning,
                                fontSize: 10,
                                fontWeight: FontWeight.w800)),
                        ),
                      ),

                  const SizedBox(width: 10),

                  // Input or filled text
                  Expanded(
                    child: stop.isFilled
                      // ── Confirmed stop: show name + checkmark, tap to clear & re-edit
                      ? GestureDetector(
                          onTap: () => setState(() {
                            _stops[i].address = '';
                            _stops[i].latLng  = null;
                            _activeStopIdx    = i;
                            _searchCtrl.clear();
                          }),
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 9),
                            child: Row(children: [
                              Expanded(
                                child: Text(getDisplayLocation(name: '', address: stop.address),
                                    style: TextStyle(color: context.appTextPrimary,
                                        fontSize: 14, fontWeight: FontWeight.w500),
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                              SizedBox(width: 6),
                              Icon(Icons.check_circle,
                                  color: AppTheme.success, size: 16),
                            ]),
                          ),
                        )
                      // ── Empty stop: show TextField when active, placeholder otherwise
                      : isActive
                          ? TextField(
                              controller: _searchCtrl,
                              autofocus: true,
                              style: TextStyle(color: context.appTextPrimary, fontSize: 14),
                              decoration: InputDecoration(
                                hintText: i == 0 ? 'Where to?' : 'Stop ${i + 1}',
                                hintStyle: TextStyle(color: context.appTextSecondary, fontSize: 14),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 7),
                                suffixIcon: hasQuery
                                  ? IconButton(
                                      icon: Icon(Icons.close, size: 16, color: context.appTextSecondary),
                                      onPressed: () => _searchCtrl.clear(),
                                    )
                                  : null,
                              ),
                            )
                          : GestureDetector(
                              onTap: () => setState(() { _activeStopIdx = i; _searchCtrl.clear(); }),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 9),
                                child: Text(i == 0 ? 'Where to?' : 'Stop ${i + 1}',
                                    style: TextStyle(color: context.appTextSecondary, fontSize: 14)),
                              ),
                            ),
                  ),

                  // Delete stop button
                  if (_stops.length > 1)
                    GestureDetector(
                      onTap: () => setState(() {
                        _stops.removeAt(i);
                        if (_activeStopIdx >= _stops.length || _activeStopIdx == i) {
                          _activeStopIdx = _stops.every((s) => s.isFilled)
                              ? -1
                              : _stops.indexWhere((s) => !s.isFilled);
                        }
                      }),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                        child: Icon(Icons.close, size: 16, color: context.appTextSecondary),
                      ),
                    ),
                ]),
              ),
            ]);
          }),

          // ── "Add a stop" — always visible when < 5 stops ───────────────
          if (_stops.length < 5) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                final unfilled = _stops.indexWhere((s) => !s.isFilled);
                if (unfilled != -1) {
                  // Focus the first unfilled stop instead of adding a new one
                  setState(() { _activeStopIdx = unfilled; _searchCtrl.clear(); });
                } else {
                  // Append at the end — whatever was picked first keeps its
                  // position/number, and each new stop becomes the new final
                  // destination (matching the "Add a stop" behaviour on the
                  // confirm screen).
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
                  child: Icon(Icons.add, size: 14, color: AppTheme.accent),
                ),
                SizedBox(width: 10),
                Text(AppLocalizations.of(context).addAStop,
                    style: TextStyle(color: AppTheme.accent,
                        fontSize: 14, fontWeight: FontWeight.w500)),
              ]),
            ),
          ],

          // ── Quick-access shortcuts: Home / Office / Saved / Airport ─────
          if (_activeStopIdx >= 0) ...[
            const SizedBox(height: 14),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _QuickPlaceButton(
                icon: Icons.add_home_outlined,
                label: 'Home',
                onTap: () {
                  final home = _findSavedPlace(['home']);
                  if (home != null) {
                    _selectSavedPlace(home);
                  } else {
                    Navigator.push(context, MaterialPageRoute(
                        builder: (_) => const SavedPlacesScreen()));
                  }
                },
              ),
              _QuickPlaceButton(
                icon: Icons.add_business_outlined,
                label: 'Office',
                onTap: () {
                  final office = _findSavedPlace(['work', 'office']);
                  if (office != null) {
                    _selectSavedPlace(office);
                  } else {
                    Navigator.push(context, MaterialPageRoute(
                        builder: (_) => const SavedPlacesScreen()));
                  }
                },
              ),
              _QuickPlaceButton(
                icon: Icons.bookmark_border,
                label: 'Saved',
                onTap: _showAllSavedPlaces,
              ),
              _QuickPlaceButton(
                icon: Icons.flight_outlined,
                label: 'Airport',
                onTap: () => _selectPreset(_kPresets.first),
              ),
            ]),
          ],
        ]),
      ),

      Divider(height: 1, color: context.appCardBg),

      // ── Confirm button (shown when all stops are filled, below the map) ───
      // Same fixed-footer treatment (surface color + top shadow) as the
      // "Confirm Booking" footer on the final confirm screen, so the button
      // reads as a consistent, elevated footer bar throughout the flow.
      if (allFilled)
        Container(
          decoration: BoxDecoration(
            color: context.appSurface,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 16,
                  offset: const Offset(0, -4)),
            ],
          ),
          // Small fixed buffer only — the outer SafeArea already reserves
          // the real system-inset space, so adding viewPadding.bottom here
          // too would double-count it and leave a large empty gap below
          // the button. This just nudges the tap target clear of Samsung's
          // gesture-nav touch zone (e.g. the Flip series).
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12 + 8),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // A real destination is filled here — make sure the metered
                // no-destination confirm screen doesn't stick around if the
                // user reached this step by backing out of it earlier.
                _noDestination = false;
                _goToStep(2);
              },
              style: AppTheme.confirmButtonStyle(),
              child: Text(
                _stops.length > 1 ? 'Confirm destinations' : 'Confirm destination',
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
          if (_activeStopIdx < 0) return;
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
      Divider(height: 1, color: context.appCardBg),

      // Tab bar
      Container(
        color: context.appSurface,
        child: Row(children: [
          _TabChip(label: 'Recent',      selected: _whereToTab == 0, onTap: () => setState(() => _whereToTab = 0)),
          _TabChip(label: 'Suggestions', selected: _whereToTab == 1, onTap: () => setState(() => _whereToTab = 1)),
          _TabChip(label: 'Saved',       selected: _whereToTab == 2, onTap: () => setState(() => _whereToTab = 2)),
        ]),
      ),
      Divider(height: 1, color: context.appCardBg),

      Expanded(child: _buildTabContent()),
    ]);
  }

  Widget _buildTabContent() {
    switch (_whereToTab) {
      case 0:
        return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.history, color: context.appTextSecondary, size: 40),
            SizedBox(height: 12),
            Text(AppLocalizations.of(context).noRecentTrips,
                style: TextStyle(color: context.appTextSecondary)),
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
        return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.bookmark_border, color: context.appTextSecondary, size: 40),
            SizedBox(height: 12),
            Text(AppLocalizations.of(context).noSavedPlaces,
                style: TextStyle(color: context.appTextSecondary)),
          ]),
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildDestinationMapPicker() {
    return Stack(children: [
      GoogleMap(
        key: ValueKey('dest_map_${appLocale.value.languageCode}'),
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
          // regardless of whether the parent Scaffold already consumed the
          // inset. The extra +8 is a buffer for devices (e.g. Samsung Flip)
          // whose gesture-nav touch zone is taller than the reported inset.
          final bottomInset = MediaQuery.of(ctx).viewPadding.bottom + 8;
          return Container(
            decoration: BoxDecoration(
              color: context.appSurface,
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
                SizedBox(width: 12),
                Expanded(
                  child: _geocodingDest
                      ? Row(children: [
                          SizedBox(
                            width: 14, height: 14,
                            child: CircularProgressIndicator(
                                color: AppTheme.accent, strokeWidth: 2),
                          ),
                          SizedBox(width: 10),
                          Text(AppLocalizations.of(context).findingAddress,
                              style: TextStyle(
                                  color: context.appTextSecondary, fontSize: 13)),
                        ])
                      : Text(
                          _mapPickerAddress.isEmpty
                              ? 'Drag map to set destination'
                              : _mapPickerAddress,
                          style: TextStyle(
                              color: context.appTextPrimary,
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
                  onPressed: (_geocodingDest || _mapPickerAddress.isEmpty || _activeStopIdx < 0)
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
                  style: AppTheme.confirmButtonStyle(),
                  child: Text(AppLocalizations.of(context).confirmDestination),
                ),
              ),
            ]),
          );
        }),
      ),
    ]);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Step 2 (no-destination mode) — single-screen confirm: map + pickup pin,
  // optional "Where to?", vehicle type, quick actions, one Confirm button.
  // No fare-by-type list since the fare is metered.
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildNoDestinationConfirm() {
    return Stack(children: [
      GoogleMap(
        key: ValueKey('confirm_map_nodest_${appLocale.value.languageCode}'),
        onMapCreated: (c) {
          _confirmMapCtrl = c;
          c.animateCamera(CameraUpdate.newLatLngZoom(_pickupCenter, 16));
        },
        initialCameraPosition: CameraPosition(target: _pickupCenter, zoom: 16),
        style: _kDarkMapStyle,
        markers: _nearbyDriverMarkers,
        myLocationEnabled:       true,
        myLocationButtonEnabled: false,
        zoomControlsEnabled:     false,
        cameraTargetBounds: CameraTargetBounds(_kCambodiaBounds),
        minMaxZoomPreference: const MinMaxZoomPreference(10, 20),
        onCameraMove: (pos) => _pickupCenter = pos.target,
        // Skip while GPS is still resolving — otherwise the map's initial
        // render (still sitting on the hardcoded placeholder center) fires
        // onCameraIdle immediately and reverse-geocodes that placeholder
        // into a real-looking street address, which then briefly displays
        // in place of "Detecting location…" as if it were the user's
        // actual position.
        onCameraIdle: () { if (!_gpsLoading) _reverseGeocodePickup(_pickupCenter); },
      ),

      // Fixed crosshair — drag the map to reposition pickup. Positioned
      // within the visible map sliver above the bottom sheet (which covers
      // ~55% of the screen by default), not screen-center, or it would sit
      // hidden underneath the sheet.
      const Align(alignment: Alignment(0, -0.55), child: _Crosshair()),

      // ── Floating back button ──────────────────────────────────────────────
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: GestureDetector(
            onTap: () {
              // Reached directly from Home (skipDestination) — there's no
              // prior in-flow step to go back to, so go straight back to
              // Home instead of the destination-search step.
              if (widget.skipDestination) {
                // Safe no-op if this instance isn't a pushed route (e.g. the
                // bottom-nav "Book Ride" tab, which is index-swapped rather
                // than pushed) — only pops when there's actually a route to
                // return to, such as the Home-screen "Book Ride" tile.
                Navigator.maybePop(context);
                return;
              }
              setState(() {
                _step          = 1;
                _noDestination = false;
                _searchCtrl.clear();
                _choosingDestOnMap = false;
              });
            },
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: context.appSurface,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 8)],
              ),
              child: Icon(Icons.arrow_back_ios_new,
                  color: context.appTextPrimary, size: 18),
            ),
          ),
        ),
      ),

      // ── Scrollable content — mirrors the normal Confirm screen's layout ───
      NotificationListener<DraggableScrollableNotification>(
        onNotification: (n) {
          if (!_showAllRideOptions && n.extent > n.initialExtent + 0.02) {
            setState(() => _showAllRideOptions = true);
          }
          return false;
        },
        child: DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize:     0.2,
        maxChildSize:     0.9,
        snap:             true,
        snapSizes:        const [0.55, 0.9],
        builder: (ctx, scrollCtrl) {
          final safeBottom = MediaQuery.of(ctx).viewPadding.bottom;
          return Container(
          decoration: BoxDecoration(
            color: context.appSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20)],
          ),
          child: ListView(
            controller: scrollCtrl,
            padding: EdgeInsets.fromLTRB(20, 12, 20, 96 + safeBottom),
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: context.appCardBg,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              // Route summary — pickup + optional destination, same card
              // style as the normal Confirm screen's route summary.
              Container(
                decoration: BoxDecoration(
                    color: context.appCardBg, borderRadius: BorderRadius.circular(14)),
                child: Column(children: [
                  InkWell(
                    // Tapping pickup opens the dedicated full-screen pickup
                    // picker (map + search + drag-to-set) instead of editing
                    // inline here — dragging the map above still works too.
                    onTap: () {
                      // Clear any stale focus from a prior visit — autofocus
                      // only applies if nothing in the scope already has
                      // focus, so a leftover focused field would silently
                      // block it.
                      _destSearchFocus.unfocus();
                      setState(() {
                        _focusDestinationOnEntry = false;
                        _step = 0;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                      child: Row(children: [
                        _geocodingPickup || _gpsLoading
                            ? SizedBox(
                                width: 10, height: 10,
                                child: CircularProgressIndicator(color: AppTheme.accent, strokeWidth: 2),
                              )
                            : Container(
                                width: 10, height: 10,
                                decoration: const BoxDecoration(color: AppTheme.accent, shape: BoxShape.circle),
                              ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            _pickupAddress.isEmpty || _pickupAddress == 'Detecting location…'
                                ? 'Pickup location'
                                : getDisplayLocation(name: '', address: _pickupAddress),
                            style: TextStyle(color: context.appTextSecondary, fontSize: 13),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(Icons.chevron_right, color: context.appTextSecondary, size: 18),
                      ]),
                    ),
                  ),
                  Divider(height: 1, indent: 40, color: context.appSurface.withValues(alpha: 0.8)),
                  InkWell(
                    // Same unified location-search page as tapping pickup,
                    // not the old separate destination-only screen —
                    // autofocuses "Where to?" instead of pickup.
                    onTap: () {
                      // Clear any stale pickup focus from a prior visit —
                      // autofocus only applies if nothing in the scope
                      // already has focus, so a leftover focused pickup
                      // field would silently block "Where to?" from
                      // getting it.
                      _pickupSearchFocus.unfocus();
                      setState(() {
                        _focusDestinationOnEntry = true;
                        _step = 0;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
                      child: Row(children: [
                        const Icon(Icons.location_on_outlined, color: AppTheme.accentOrange, size: 18),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(AppLocalizations.of(context).whereToOptional,
                              style: TextStyle(color: context.appTextSecondary, fontSize: 13)),
                        ),
                        Icon(Icons.chevron_right, color: context.appTextSecondary, size: 18),
                      ]),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 14),

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

              // Choose Ride
              Text(AppLocalizations.of(context).chooseRideTitle,
                  style: TextStyle(color: context.appTextPrimary,
                      fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),

              if (!_rideTypesLoading) ...[
                _RideCategoryTabs(
                  selected: _rideCategory,
                  onChanged: (c) => setState(() => _rideCategory = c),
                ),
                const SizedBox(height: 10),
              ],

              if (_rideTypesLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator(color: AppTheme.accent)),
                )
              else ...[
                ...(_showAllRideOptions
                        ? _filteredRideTypes
                        : [
                            _filteredRideTypes.firstWhere(
                                (r) => r.serviceType == 'tuk_tuk',
                                orElse: () => _filteredRideTypes.first),
                          ])
                    .map((r) => _RideTypeCard(
                          type:     r,
                          selected: _selectedRide == r.name,
                          metered:  true,
                          onTap:    () => setState(() => _selectedRide = r.name),
                        )),
                if (!_showAllRideOptions && _filteredRideTypes.length > 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Center(
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.keyboard_arrow_up, size: 16, color: context.appTextSecondary),
                        const SizedBox(width: 4),
                        Text(AppLocalizations.of(context).scrollUpForMore,
                            style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
                      ]),
                    ),
                  ),
              ],
              const SizedBox(height: 4),

              // Promo code
              GestureDetector(
                onTap: () => _showPromoSheet(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: _promoCode != null
                        ? AppTheme.success.withValues(alpha: 0.08)
                        : context.appCardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: _promoCode != null
                        ? Border.all(color: AppTheme.success.withValues(alpha: 0.4))
                        : null,
                  ),
                  child: Row(children: [
                    Icon(
                      _promoCode != null ? Icons.check_circle_outline : Icons.local_offer_outlined,
                      color: _promoCode != null ? AppTheme.success : AppTheme.warning,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _promoCode != null
                          ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(_promoCode!, style: const TextStyle(
                                  color: AppTheme.success, fontWeight: FontWeight.w700, letterSpacing: 1)),
                              if (_promoDiscount != null)
                                Text('− ${AppTheme.khr(_promoDiscount!)} ${AppLocalizations.of(context).discountSuffix}',
                                    style: TextStyle(color: AppTheme.success, fontSize: 12)),
                            ])
                          : Text(AppLocalizations.of(context).promoCode,
                              style: TextStyle(color: context.appTextSecondary)),
                    ),
                    GestureDetector(
                      onTap: _promoCode != null
                          ? () => setState(() { _promoCode = null; _promoDiscount = null; })
                          : null,
                      child: Icon(
                        _promoCode != null ? Icons.close : Icons.chevron_right,
                        color: context.appTextSecondary,
                      ),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 10),

              // Payment method
              GestureDetector(
                onTap: () => _showPaymentSheet(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                      color: context.appCardBg, borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    const Icon(Icons.payment_outlined, color: AppTheme.accent, size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_paymentLabel(_paymentMethod),
                        style: TextStyle(color: context.appTextPrimary))),
                    Icon(Icons.chevron_right, color: context.appTextSecondary),
                  ]),
                ),
              ),
              const SizedBox(height: 10),

              // Schedule toggle
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                    color: context.appCardBg, borderRadius: BorderRadius.circular(12)),
                child: Column(children: [
                  Row(children: [
                    Text(AppLocalizations.of(context).scheduleForLater,
                        style: TextStyle(color: context.appTextPrimary,
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Switch(
                      value: _isScheduled,
                      onChanged: (v) => setState(() => _isScheduled = v),
                      activeThumbColor: AppTheme.accent,
                      activeTrackColor: AppTheme.accent.withValues(alpha: 0.4),
                    ),
                  ]),
                  if (_isScheduled)
                    GestureDetector(
                      onTap: () async {
                        final dt = await _pickDateTime(context);
                        if (dt != null) setState(() => _scheduledTime = dt);
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(children: [
                          const Icon(Icons.schedule, color: AppTheme.accent, size: 18),
                          const SizedBox(width: 10),
                          Text(
                            '${_scheduledTime.day}/${_scheduledTime.month}/'
                            '${_scheduledTime.year}  '
                            '${_scheduledTime.hour}:'
                            '${_scheduledTime.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                                color: context.appTextPrimary, fontWeight: FontWeight.w500),
                          ),
                          const Spacer(),
                          Icon(Icons.chevron_right, color: context.appTextSecondary),
                        ]),
                      ),
                    ),
                ]),
              ),
            ],
          ),
        );
        },
      ),
      ),

      // ── Fixed confirm button (footer) ─────────────────────────────────────
      Positioned(
        left: 0, right: 0, bottom: 0,
        child: Builder(builder: (ctx) {
          final safeBot = MediaQuery.of(ctx).viewPadding.bottom;
          return Container(
            decoration: BoxDecoration(
              color: context.appSurface,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 16,
                    offset: const Offset(0, -4)),
              ],
            ),
            padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + safeBot),
            child: ElevatedButton(
              onPressed: (_isBooking || _gpsLoading) ? null : _bookRide,
              style: AppTheme.confirmButtonStyle(),
              child: _isBooking
                  ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : Text(AppLocalizations.of(context).confirmBooking),
            ),
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
          Text(AppLocalizations.of(context).noDestinationSelected, style: TextStyle(color: context.appTextSecondary)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _goToStep(1),
            child: Text(AppLocalizations.of(context).selectDestination),
          ),
        ]),
      );
    }

    final dest = _destLatLng;
    final type = _visibleRideTypes.firstWhere(
      (r) => r.name == _selectedRide,
      orElse: () => _visibleRideTypes[0],  // Default to first ride type if not found
    );

    final markers = <Marker>{
      // Pickup — green dot
      Marker(
        markerId: const MarkerId('pickup'),
        position: _pickupCenter,
        icon: _pickupIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(title: '📍 Pickup', snippet: _pickupAddress),
      ),
      // All stops in order — numbered 1, 2, 3…
      for (int i = 0; i < _stops.length; i++)
        if (_stops[i].latLng != null)
          Marker(
            markerId: MarkerId('stop_$i'),
            position: _stops[i].latLng!,
            icon: (_stopMarkers.length > i)
                ? _stopMarkers[i].icon
                : BitmapDescriptor.defaultMarkerWithHue(
                    i == _stops.length - 1
                        ? BitmapDescriptor.hueRed
                        : BitmapDescriptor.hueOrange),
            anchor: _stopMarkers.length > i
                ? _stopMarkers[i].anchor
                : const Offset(0.5, 1.0),
            infoWindow: InfoWindow(
              title: i == _stops.length - 1
                  ? '🏁 Stop ${i + 1} — Destination'
                  : '🔵 Stop ${i + 1}',
              snippet: _stops[i].address,
            ),
          ),
    };
    // Road-following route, one colored polyline per segment:
    // segment 0 (pickup→1): green  1→2: red  2→3: blue …
    const _segmentColors = [
      Color(0xFF00C48C), // green
      Color(0xFFE53935), // red
      Color(0xFF1976D2), // blue
      Color(0xFFFF9800), // orange
      Color(0xFF9C27B0), // purple
    ];
    final polylines = <Polyline>{
      for (int i = 0; i < _segmentRoutes.length; i++)
        if (_segmentRoutes[i].length >= 2)
          Polyline(
            polylineId: PolylineId('seg_$i'),
            points: _segmentRoutes[i],
            color: _segmentColors[i % _segmentColors.length],
            width: 4,
          ),
    };

    final midLat = dest != null
        ? (_pickupCenter.latitude  + dest.latitude)  / 2
        : _pickupCenter.latitude;
    final midLng = dest != null
        ? (_pickupCenter.longitude + dest.longitude) / 2
        : _pickupCenter.longitude;

    return Stack(children: [

      // ── Full-screen map ───────────────────────────────────────────────────
      GoogleMap(
        key: ValueKey('confirm_map_${appLocale.value.languageCode}'),
        onMapCreated: (c) {
          _confirmMapCtrl = c;
          if (dest != null) {
            final allLats = [_pickupCenter.latitude,  ..._stops.whereType<_WayStop>().where((s) => s.latLng != null).map((s) => s.latLng!.latitude)];
            final allLngs = [_pickupCenter.longitude, ..._stops.whereType<_WayStop>().where((s) => s.latLng != null).map((s) => s.latLng!.longitude)];
            final sw = LatLng(allLats.reduce((a,b) => a<b?a:b) - 0.008, allLngs.reduce((a,b) => a<b?a:b) - 0.008);
            final ne = LatLng(allLats.reduce((a,b) => a>b?a:b) + 0.008, allLngs.reduce((a,b) => a>b?a:b) + 0.008);
            c.animateCamera(CameraUpdate.newLatLngBounds(LatLngBounds(southwest: sw, northeast: ne), 80));
          } else {
            c.animateCamera(CameraUpdate.newLatLng(_pickupCenter));
          }
        },
        initialCameraPosition: CameraPosition(target: LatLng(midLat, midLng), zoom: 13),
        style: _kDarkMapStyle,
        markers:   markers,
        polylines: polylines,
        myLocationEnabled:       true,
        myLocationButtonEnabled: false,
        zoomControlsEnabled:     false,
      ),

      if (_routeLoading)
        const Positioned.fill(
          child: ColoredBox(
            color: Colors.black26,
            child: Center(child: CircularProgressIndicator(color: AppTheme.accent)),
          ),
        ),

      // ── Floating back button ──────────────────────────────────────────────
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: GestureDetector(
            onTap: () => setState(() {
              _step          = 1;
              _activeStopIdx = _stops.length - 1;
              _searchCtrl.clear();
              _choosingDestOnMap = false;
            }),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: context.appSurface,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 8)],
              ),
              child: Icon(Icons.arrow_back_ios_new,
                  color: context.appTextPrimary, size: 18),
            ),
          ),
        ),
      ),

      // ── Floating ETA / distance chips ────────────────────────────────────
      if ((_etaMinutes > 0 || _distanceKm > 0) && !_routeLoading)
        SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.only(top: 10),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: context.appSurface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8)],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.straighten, color: AppTheme.accent, size: 14),
                  const SizedBox(width: 4),
                  Text('${_distanceKm.toStringAsFixed(1)} ${AppLocalizations.of(context).km}',
                      style: TextStyle(color: context.appTextPrimary,
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  SizedBox(width: 12),
                  Icon(Icons.access_time_outlined, color: AppTheme.accent, size: 14),
                  SizedBox(width: 4),
                  Text('~$_etaMinutes ${AppLocalizations.of(context).min}',
                      style: TextStyle(color: context.appTextPrimary,
                          fontSize: 13, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ),
        ),

      // ── Bottom sheet ─────────────────────────────────────────────────────
      DraggableScrollableSheet(
        initialChildSize: 0.45,
        minChildSize:     0.18,
        maxChildSize:     0.95,
        snap:             true,
        snapSizes:        const [0.45, 0.95],
        builder: (ctx, scrollCtrl) {
          final safeBottom = MediaQuery.of(ctx).viewPadding.bottom;
          return Container(
          decoration: BoxDecoration(
            color: context.appSurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20)],
          ),
          child: ListView(
            controller: scrollCtrl,
            padding: EdgeInsets.fromLTRB(20, 0, 20, 96 + safeBottom),
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: EdgeInsets.symmetric(vertical: 10),
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: context.appCardBg,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),

              // Route summary — Grab-style numbered list
              _RouteSummary(
                pickupAddress: _pickupAddress.isEmpty ||
                        _pickupAddress == 'Detecting location…'
                    ? 'Pickup location'
                    : _pickupAddress,
                stops: _stops,
                onEditPickup: () => setState(() {
                  _step = 0;
                  _searchCtrl.clear();
                  _choosingDestOnMap = false;
                }),
                onEditStop: (i) => setState(() {
                  _step = 1; _activeStopIdx = i;
                  _searchCtrl.clear(); _choosingDestOnMap = false;
                }),
                onRemoveStop: _stops.length > 1 ? (i) {
                  setState(() => _stops.removeAt(i));
                  _fetchRoute();
                  _buildMarkerIcons();
                } : null,
                onAddStop: _stops.length < 5 ? () {
                  setState(() {
                    _stops.add(_WayStop());
                    _step          = 1;
                    _activeStopIdx = _stops.length - 1;
                    _searchCtrl.clear();
                    _choosingDestOnMap = false;
                  });
                } : null,
              ),
              SizedBox(height: 14),

              if (_bookError != null) ...[
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.danger.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.danger.withValues(alpha: 0.4)),
                  ),
                  child: Row(children: [
                    Icon(Icons.error_outline, color: AppTheme.danger, size: 16),
                    SizedBox(width: 8),
                    Expanded(child: Text(_bookError!,
                        style: TextStyle(color: AppTheme.danger, fontSize: 12))),
                  ]),
                ),
                SizedBox(height: 12),
              ],

              // Choose Ride
              Row(children: [
                Text(AppLocalizations.of(context).chooseRideTitle,
                    style: TextStyle(color: context.appTextPrimary,
                        fontSize: 15, fontWeight: FontWeight.w700)),
                if (_fareLoading) ...[
                  const SizedBox(width: 10),
                  const SizedBox(width: 14, height: 14,
                      child: CircularProgressIndicator(color: AppTheme.accent, strokeWidth: 2)),
                ],
              ]),
              const SizedBox(height: 10),
              if (_surgeInfo != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.warning.withValues(alpha: 0.4)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.local_fire_department, color: AppTheme.warning, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(
                      '${_surgeInfo!.multiplier.toStringAsFixed(1)}× surge pricing — high demand in your area',
                      style: TextStyle(color: AppTheme.warning, fontSize: 12, fontWeight: FontWeight.w600),
                    )),
                  ]),
                ),
              if (!_rideTypesLoading) ...[
                _RideCategoryTabs(
                  selected: _rideCategory,
                  onChanged: (c) => setState(() => _rideCategory = c),
                ),
                const SizedBox(height: 10),
              ],

              if (_rideTypesLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator(color: AppTheme.accent)),
                )
              else
                ..._filteredRideTypes.map((r) => _RideTypeCard(
                      type:        r,
                      selected:    _selectedRide == r.name,
                      onTap:       () => setState(() => _selectedRide = r.name),
                      fareInfo:    _fareByType[r.serviceType],
                      fareLoading: _fareLoading,
                      surgeMultiplier: _surgeInfo?.surgeActive == true ? _surgeInfo!.multiplier : 1.0,
                      etaMinutes:  _etaMinutes,
                    )),
              SizedBox(height: 14),

              // Promo code
              GestureDetector(
                onTap: () => _showPromoSheet(context),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: _promoCode != null
                        ? AppTheme.success.withValues(alpha: 0.08)
                        : context.appCardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: _promoCode != null
                        ? Border.all(color: AppTheme.success.withValues(alpha: 0.4))
                        : null,
                  ),
                  child: Row(children: [
                    Icon(
                      _promoCode != null ? Icons.check_circle_outline : Icons.local_offer_outlined,
                      color: _promoCode != null ? AppTheme.success : AppTheme.warning,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _promoCode != null
                          ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(_promoCode!, style: const TextStyle(
                                  color: AppTheme.success, fontWeight: FontWeight.w700, letterSpacing: 1)),
                              if (_promoDiscount != null)
                                Text('− ${AppTheme.khr(_promoDiscount!)} ${AppLocalizations.of(context).discountSuffix}',
                                    style: TextStyle(color: AppTheme.success, fontSize: 12)),
                            ])
                          : Text(AppLocalizations.of(context).promoCode,
                              style: TextStyle(color: context.appTextSecondary)),
                    ),
                    GestureDetector(
                      onTap: _promoCode != null
                          ? () => setState(() { _promoCode = null; _promoDiscount = null; })
                          : null,
                      child: Icon(
                        _promoCode != null ? Icons.close : Icons.chevron_right,
                        color: context.appTextSecondary,
                      ),
                    ),
                  ]),
                ),
              ),
              SizedBox(height: 10),

              // Payment method
              GestureDetector(
                onTap: () => _showPaymentSheet(context),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                      color: context.appCardBg, borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    Icon(Icons.payment_outlined, color: AppTheme.accent, size: 20),
                    SizedBox(width: 10),
                    Expanded(child: Text(_paymentLabel(_paymentMethod),
                        style: TextStyle(color: context.appTextPrimary))),
                    Icon(Icons.chevron_right, color: context.appTextSecondary),
                  ]),
                ),
              ),
              SizedBox(height: 10),

              // Schedule toggle
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                    color: context.appCardBg, borderRadius: BorderRadius.circular(12)),
                child: Column(children: [
                  Row(children: [
                    Text(AppLocalizations.of(context).scheduleForLater,
                        style: TextStyle(color: context.appTextPrimary,
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Switch(
                      value: _isScheduled,
                      onChanged: (v) => setState(() => _isScheduled = v),
                      activeThumbColor: AppTheme.accent,
                      activeTrackColor: AppTheme.accent.withValues(alpha: 0.4),
                    ),
                  ]),
                  if (_isScheduled)
                    GestureDetector(
                      onTap: () async {
                        final dt = await _pickDateTime(context);
                        if (dt != null) setState(() => _scheduledTime = dt);
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(children: [
                          const Icon(Icons.schedule, color: AppTheme.accent, size: 18),
                          const SizedBox(width: 10),
                          Text(
                            '${_scheduledTime.day}/${_scheduledTime.month}/'
                            '${_scheduledTime.year}  '
                            '${_scheduledTime.hour}:'
                            '${_scheduledTime.minute.toString().padLeft(2,'0')}',
                            style: TextStyle(
                                color: context.appTextPrimary, fontWeight: FontWeight.w500),
                          ),
                          Spacer(),
                          Icon(Icons.chevron_right, color: context.appTextSecondary),
                        ]),
                      ),
                    ),
                ]),
              ),
            ],
          ),
        );
        },
      ),

      // ── Fixed confirm button (footer) ─────────────────────────────────────
      Positioned(
        left: 0, right: 0, bottom: 0,
        child: Builder(builder: (ctx) {
          final safeBot = MediaQuery.of(ctx).viewPadding.bottom;
          return Container(
            decoration: BoxDecoration(
              color: context.appSurface,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 16,
                    offset: const Offset(0, -4)),
              ],
            ),
            padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + safeBot),
            child: ElevatedButton(
              onPressed: (_isBooking || _gpsLoading) ? null : _bookRide,
              style: AppTheme.confirmButtonStyle(
                  background: _isScheduled ? AppTheme.warning : null),
              child: _isBooking
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : Text(
                      _isScheduled
                          ? '📅  Schedule — ${_fareByType[type.serviceType]?.formattedTotal ?? '...'}'
                          : '🛺  Confirm — ${_fareByType[type.serviceType]?.formattedTotal ?? '...'}',
                    ),
            ),
          );
        }),
      ),

    ]);
  }
}

// ─── Step header (2 steps: Where To? / Confirm) ───────────────────────────────

class _StepHeader extends StatelessWidget {
  final int step;
  final VoidCallback? onBack;
  const _StepHeader({required this.step, this.onBack});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        color: context.appSurface,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          SizedBox(
            width: 36,
            child: onBack != null
                ? GestureDetector(
                    onTap: onBack,
                    child: Icon(Icons.arrow_back_ios_new,
                        color: context.appTextPrimary, size: 18),
                  )
                : null,
          ),
          Expanded(
            child: Column(children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(2, (i) {
                  final done   = i < step;
                  final active = i == step;
                  return Row(children: [
                    AnimatedContainer(
                      duration: Duration(milliseconds: 250),
                      width: active ? 20 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: active
                            ? AppTheme.accent
                            : done
                                ? AppTheme.accent.withValues(alpha: 0.5)
                                : context.appCardBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    if (i < 1)
                      Container(
                        width: 20, height: 2,
                        color: i < step
                            ? AppTheme.accent.withValues(alpha: 0.5)
                            : context.appCardBg,
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

  static const _green = Color(0xFF00C853);

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Column(mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center, children: [
        // Circle head
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: _green,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [
              BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 3)),
            ],
          ),
          child: const Icon(Icons.location_on, color: Colors.white, size: 20),
        ),
        // Stem
        Container(
          width: 3, height: 18,
          decoration: const BoxDecoration(
            color: _green,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(2)),
          ),
        ),
        // Ground dot shadow
        Container(
          width: 10, height: 4,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(5),
          ),
        ),
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
        decoration: BoxDecoration(
          color: context.appSurface,
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
      decoration: BoxDecoration(
        color: context.appSurface,
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
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(label,
              style: TextStyle(
                color: selected ? AppTheme.accent : context.appTextSecondary,
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

class _RideCategoryTabs extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const _RideCategoryTabs({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.appCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: _kRideCategories.map((c) {
          final isSelected = c == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(c),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? context.appSurface : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: isSelected
                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4)]
                      : null,
                ),
                child: Text(c,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: isSelected ? AppTheme.accent : context.appTextSecondary,
                        fontSize: 12.5,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _QuickPlaceButton extends StatelessWidget {
  final IconData icon;
  final String   label;
  final VoidCallback onTap;
  const _QuickPlaceButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 22, color: AppTheme.accent),
        const SizedBox(height: 6),
        Text(label,
            style: TextStyle(color: context.appTextPrimary, fontSize: 12.5, fontWeight: FontWeight.w500)),
      ]),
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
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12), shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      title: Text(getDisplayLocation(name: '', address: title),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: context.appTextPrimary, fontSize: 13)),
      trailing: trailing,
      onTap: onTap,
    );
  }
}

// ─── Grab-style route summary — numbered stop list ────────────────────────────

class _RouteSummary extends StatelessWidget {
  final String pickupAddress;
  final List<_WayStop> stops;
  final VoidCallback? onEditPickup;
  final void Function(int stopIndex) onEditStop;
  final void Function(int stopIndex)? onRemoveStop;
  final VoidCallback? onAddStop;

  const _RouteSummary({
    required this.pickupAddress,
    required this.stops,
    this.onEditPickup,
    required this.onEditStop,
    this.onRemoveStop,
    this.onAddStop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: context.appCardBg, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          // ── Pickup row ────────────────────────────────────────────────────
          GestureDetector(
            onTap: onEditPickup,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(children: [
                Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                      color: AppTheme.accent, shape: BoxShape.circle),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    getDisplayLocation(name: '', address: pickupAddress),
                    style: TextStyle(
                        color: context.appTextSecondary, fontSize: 13),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (onEditPickup != null)
                  Icon(Icons.edit_outlined,
                      color: context.appTextSecondary, size: 15),
              ]),
            ),
          ),

          // ── Stop rows ─────────────────────────────────────────────────────
          ...List.generate(stops.length, (i) {
            final isLast = i == stops.length - 1;
            return Column(children: [
              Divider(height: 1, indent: 40, color: context.appSurface.withValues(alpha: 0.8)),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
                child: Row(children: [
                  // Numbered in the order each address was picked — Add a
                  // stop always appends, so an earlier stop's number never
                  // shifts. A lone destination gets a plain pin instead.
                  isLast && stops.length == 1
                    ? const Icon(Icons.location_on, color: Color(0xFFE53935), size: 24)
                    : Container(
                        width: 24, height: 24,
                        decoration: BoxDecoration(
                          color: isLast ? const Color(0xFFE53935) : const Color(0xFFFF9800),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                  SizedBox(width: 14),
                  // Address
                  Expanded(
                    child: GestureDetector(
                      onTap: () => onEditStop(i),
                      child: Text(
                        getDisplayLocation(name: '', address: stops[i].address),
                        style: TextStyle(
                            color: context.appTextPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  // Remove button
                  if (onRemoveStop != null && stops.length > 1)
                    GestureDetector(
                      onTap: () => onRemoveStop!(i),
                      child: Padding(
                        padding: EdgeInsets.only(left: 10),
                        child: Icon(Icons.close,
                            color: context.appTextSecondary, size: 18),
                      ),
                    ),
                ]),
              ),
            ]);
          }),

          // ── Add a stop ────────────────────────────────────────────────────
          if (onAddStop != null && stops.length < 5) ...[
            Divider(height: 1, indent: 40, color: context.appSurface.withValues(alpha: 0.8)),
            GestureDetector(
              onTap: onAddStop,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(children: [
                  Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, size: 14, color: AppTheme.accent),
                  ),
                  const SizedBox(width: 14),
                  Text(AppLocalizations.of(context).addAStop,
                      style: TextStyle(
                          color: AppTheme.accent,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ],
        ],
      ),
    );
  }
}


// ─── Quick action icon (Cash / Coupon / Option / Note row) ────────────────────
class _RideTypeCard extends StatelessWidget {
  final _RideType    type;
  final bool         selected;
  final VoidCallback onTap;
  final FareInfo?    fareInfo;
  final bool         fareLoading;
  final bool         metered;
  final double       surgeMultiplier;
  final int          etaMinutes;
  const _RideTypeCard({
    required this.type,
    required this.selected,
    required this.onTap,
    this.fareInfo,
    this.fareLoading = false,
    this.metered = false,
    this.surgeMultiplier = 1.0,
    this.etaMinutes = 0,
  });

  @override
  Widget build(BuildContext context) {
    String priceText;
    if (metered) {
      // No drop-off yet, so the real distance-based fare isn't known —
      // show the vehicle type's base fare (GET /vehicle-types `pricing.base`)
      // as a starting-price indicator instead of a generic label.
      priceText = type.base > 0 ? ' ${AppTheme.khr(type.base)}' : 'Metered fare';
    } else if (fareInfo != null) {
      if (surgeMultiplier > 1.0) {
        final surgedTotal = (fareInfo!.total * surgeMultiplier).round();
        priceText = AppTheme.khr(surgedTotal);
      } else {
        priceText = fareInfo!.formattedTotal;
      }
    } else {
      priceText = fareLoading ? '...' : '—';
    }
    final hasSurge = surgeMultiplier > 1.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 10),
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected ? AppTheme.accent : Colors.transparent, width: 1.5),
        ),
        child: Row(children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (selected ? AppTheme.accent : context.appTextSecondary)
                  .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(type.icon,
                color: selected ? AppTheme.accent : context.appTextSecondary, size: 22),
          ),
          SizedBox(width: 12),
          Expanded(child: Row(children: [
            Flexible(
              child: Text(type.name,
                  style: TextStyle(
                      color: context.appTextPrimary, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis),
            ),
            if (RegExp(r'^(\d+)').firstMatch(type.desc)?.group(1) case final seats?) ...[
              const SizedBox(width: 6),
              Icon(Icons.person, size: 13, color: context.appTextSecondary),
              Text(seats,
                  style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
            ],
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              if (hasSurge) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('${surgeMultiplier.toStringAsFixed(1)}×',
                      style: TextStyle(color: AppTheme.warning,
                          fontSize: 9, fontWeight: FontWeight.w700)),
                ),
              ],
              Text(priceText,
                  style: TextStyle(
                      color: selected ? AppTheme.accent : context.appTextPrimary,
                      fontWeight: FontWeight.w700)),
            ]),
            if (etaMinutes > 0)
              Text('$etaMinutes ${AppLocalizations.of(context).min}',
                  style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
          ]),
          SizedBox(width: 8),
          Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppTheme.accent : context.appTextSecondary, size: 20),
        ]),
      ),
    );
  }
}

const String? _kDarkMapStyle = null; // default light Google Maps style
