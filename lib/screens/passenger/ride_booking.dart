import 'dart:async';
import 'dart:ui' as ui;
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

  // imagePixelRatio tells the map that this image was drawn at 3× density,
  // so it displays at canvasW/3 × canvasH/3 logical dp on all screen types.
  return _LabeledMarker(
    BitmapDescriptor.bytes(
        bytes!.buffer.asUint8List(), imagePixelRatio: scale),
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
  return BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(), imagePixelRatio: scale);
}

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

  // ── Step-1 mini-map ─────────────────────────────────────────────────────────
  GoogleMapController? _step1MapCtrl;

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

  String   _selectedRide    = 'Standard';
  String   _paymentMethod   = 'cash';
  bool     _isScheduled     = false;
  DateTime _scheduledTime   = DateTime.now().add(const Duration(hours: 1));
  bool     _isBooking       = false;

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
    _detectGps();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchDebounce?.cancel();
    _pickupMapCtrl?.dispose();
    _destMapCtrl?.dispose();
    _step1MapCtrl?.dispose();
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
    if (s == 2) {
      _fetchRoute();
      _buildMarkerIcons();
    }
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

  void _showPromoSheet(BuildContext ctx) {
    final ctrl = TextEditingController(text: _promoCode ?? '');
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (_, setLocal) {
          Future<void> apply() async {
            final code = ctrl.text.trim().toUpperCase();
            if (code.isEmpty) return;
            setLocal(() { _promoLoading = true; _promoError = null; });
            try {
              final fare = _fareByType[_kRideTypes
                  .firstWhere((r) => r.name == _selectedRide,
                      orElse: () => _kRideTypes.first)
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
              Navigator.pop(sheetCtx);
            } on ApiException catch (e) {
              setLocal(() { _promoError = e.message; _promoLoading = false; });
            } catch (_) {
              setLocal(() { _promoError = 'Invalid or expired code.'; _promoLoading = false; });
            } finally {
              setLocal(() => _promoLoading = false);
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
              const SizedBox(height: 16),
              const Text('Promo Code',
                  style: TextStyle(color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w800, fontSize: 17)),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: ctrl,
                    autofocus: true,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w700, letterSpacing: 1.5),
                    decoration: InputDecoration(
                      hintText: 'e.g. SAVE10',
                      hintStyle: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.normal, letterSpacing: 0),
                      filled: true, fillColor: AppTheme.cardBg,
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
                      : const Text('Apply',
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
                child: const Text('Browse available vouchers →',
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
        promoCode:      _promoCode,
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
    // Step 2 — full-screen map, no header
    if (_step == 2) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: _buildConfirm(),
      );
    }
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: Column(children: [
        _StepHeader(step: _step - 1, onBack: _onBack),
        Expanded(child: _buildDestination()),
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

            // "Where to?" tappable pill — shows destination name when already set
            GestureDetector(
              onTap: () => _goToStep(1),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: _stops.last.isFilled
                      ? Border.all(color: AppTheme.accent.withValues(alpha: 0.4))
                      : null,
                ),
                child: Row(children: [
                  Icon(
                    _stops.last.isFilled ? Icons.location_on : Icons.search,
                    color: _stops.last.isFilled ? AppTheme.accentOrange : AppTheme.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _stops.last.isFilled
                        ? Text(
                            _stops.last.address,
                            style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        : const Text('Where to?',
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
    };
    return set;
  }

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
                    // Single destination → plain red pin (no number)
                    ? const Icon(Icons.location_on, color: AppTheme.accentOrange, size: 20)
                    // All multi-stop items (including last) get a numbered circle
                    : Container(
                        width: 20, height: 20,
                        decoration: BoxDecoration(
                          color: (isLast
                              ? const Color(0xFFE53935)
                              : AppTheme.warning).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isLast ? const Color(0xFFE53935) : AppTheme.warning,
                            width: 1.5),
                        ),
                        child: Center(
                          child: Text('${i + 1}',
                              style: TextStyle(
                                color: isLast
                                    ? const Color(0xFFE53935)
                                    : AppTheme.warning,
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
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            child: Row(children: [
                              Expanded(
                                child: Text(stop.address,
                                    style: const TextStyle(color: AppTheme.textPrimary,
                                        fontSize: 14, fontWeight: FontWeight.w500),
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.check_circle,
                                  color: AppTheme.success, size: 16),
                            ]),
                          ),
                        )
                      // ── Empty stop: show TextField when active, placeholder otherwise
                      : isActive
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
                                child: Text(i == 0 ? 'Where to?' : 'Stop ${i + 1}',
                                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
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
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                        child: Icon(Icons.close, size: 16, color: AppTheme.textSecondary),
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

      // ── Confirm button (shown when all stops are filled, above the map) ───
      if (allFilled)
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _goToStep(2),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                _stops.length > 1 ? 'Confirm destinations' : 'Confirm destination',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),

      // ── Live map (when all filled) or search results ──────────────────────
      Expanded(
        child: _activeStopIdx == -1
            // All stops confirmed → full live map showing route
            ? GoogleMap(
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
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.accent))
                : hasQuery && _searchResults.isEmpty
                    ? const Center(
                        child: Text('No results found',
                            style: TextStyle(color: AppTheme.textSecondary)))
                    : hasQuery
                        ? ListView(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            children: _searchResults.map((r) {
                              final isAlreadySelected =
                                  _stops.any((s) => s.address == r.address);
                              return _DestTile(
                                icon: Icons.location_on,
                                iconColor: AppTheme.accent,
                                title: r.address,
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
                color: AppTheme.surface,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 8)],
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: AppTheme.textPrimary, size: 18),
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
              padding: const EdgeInsets.only(top: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8)],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.straighten, color: AppTheme.accent, size: 14),
                  const SizedBox(width: 4),
                  Text('${_distanceKm.toStringAsFixed(1)} km',
                      style: const TextStyle(color: AppTheme.textPrimary,
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 12),
                  const Icon(Icons.access_time_outlined, color: AppTheme.accent, size: 14),
                  const SizedBox(width: 4),
                  Text('~$_etaMinutes min',
                      style: const TextStyle(color: AppTheme.textPrimary,
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
          decoration: const BoxDecoration(
            color: AppTheme.surface,
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
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),

              // Route summary — Grab-style numbered list
              _RouteSummary(
                pickupAddress: _pickupAddress.isEmpty ||
                        _pickupAddress == 'Detecting location…'
                    ? 'Current location'
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
                  final insertAt = _stops.length - 1;
                  setState(() {
                    _stops.insert(insertAt, _WayStop());
                    _step          = 1;
                    _activeStopIdx = insertAt;
                    _searchCtrl.clear();
                    _choosingDestOnMap = false;
                  });
                } : null,
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
              Row(children: [
                const Text('Choose Ride',
                    style: TextStyle(color: AppTheme.textPrimary,
                        fontSize: 15, fontWeight: FontWeight.w700)),
                if (_fareLoading) ...[
                  const SizedBox(width: 10),
                  const SizedBox(width: 14, height: 14,
                      child: CircularProgressIndicator(color: AppTheme.accent, strokeWidth: 2)),
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
              const SizedBox(height: 14),

              // Promo code
              GestureDetector(
                onTap: () => _showPromoSheet(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: _promoCode != null
                        ? AppTheme.success.withValues(alpha: 0.08)
                        : AppTheme.cardBg,
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
                                Text('− ${AppTheme.khr(_promoDiscount!)} discount',
                                    style: const TextStyle(color: AppTheme.success, fontSize: 12)),
                            ])
                          : const Text('Add promo code',
                              style: TextStyle(color: AppTheme.textSecondary)),
                    ),
                    GestureDetector(
                      onTap: _promoCode != null
                          ? () => setState(() { _promoCode = null; _promoDiscount = null; })
                          : null,
                      child: Icon(
                        _promoCode != null ? Icons.close : Icons.chevron_right,
                        color: AppTheme.textSecondary,
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
                      color: AppTheme.cardBg, borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    const Icon(Icons.payment_outlined, color: AppTheme.accent, size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_paymentLabel(_paymentMethod),
                        style: const TextStyle(color: AppTheme.textPrimary))),
                    const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                  ]),
                ),
              ),
              const SizedBox(height: 10),

              // Schedule toggle
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                    color: AppTheme.cardBg, borderRadius: BorderRadius.circular(12)),
                child: Column(children: [
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
                            style: const TextStyle(
                                color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
                          ),
                          const Spacer(),
                          const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
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
              color: AppTheme.surface,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 16,
                    offset: const Offset(0, -4)),
              ],
            ),
            padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + safeBot),
            child: ElevatedButton(
              onPressed: _isBooking ? null : _bookRide,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isScheduled ? AppTheme.warning : AppTheme.danger,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _isBooking
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : Text(
                      _isScheduled
                          ? '📅  Schedule — ${_fareByType[type.serviceType]?.formattedTotal ?? '...'}'
                          : '🚗  Confirm — ${_fareByType[type.serviceType]?.formattedTotal ?? '...'}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15)),
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
          color: AppTheme.cardBg, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          // ── Pickup row ────────────────────────────────────────────────────
          GestureDetector(
            onTap: onEditPickup,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(children: [
                Container(
                  width: 10, height: 10,
                  decoration: const BoxDecoration(
                      color: AppTheme.accent, shape: BoxShape.circle),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    pickupAddress,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (onEditPickup != null)
                  const Icon(Icons.edit_outlined,
                      color: AppTheme.textSecondary, size: 15),
              ]),
            ),
          ),

          // ── Stop rows ─────────────────────────────────────────────────────
          ...List.generate(stops.length, (i) {
            final isLast = i == stops.length - 1;
            return Column(children: [
              Divider(height: 1, indent: 40, color: AppTheme.surface.withValues(alpha: 0.8)),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
                child: Row(children: [
                  // Numbered circle
                  Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      color: isLast
                          ? const Color(0xFFE53935)
                          : const Color(0xFFFF9800),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Address
                  Expanded(
                    child: GestureDetector(
                      onTap: () => onEditStop(i),
                      child: Text(
                        stops[i].address,
                        style: const TextStyle(
                            color: AppTheme.textPrimary,
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
                      child: const Padding(
                        padding: EdgeInsets.only(left: 10),
                        child: Icon(Icons.close,
                            color: AppTheme.textSecondary, size: 18),
                      ),
                    ),
                ]),
              ),
            ]);
          }),

          // ── Add a stop ────────────────────────────────────────────────────
          if (onAddStop != null && stops.length < 5) ...[
            Divider(height: 1, indent: 40, color: AppTheme.surface.withValues(alpha: 0.8)),
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
                  const Text('Add a stop',
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
