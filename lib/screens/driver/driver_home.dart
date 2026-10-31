import 'dart:async';
import '../auth/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../l10n/app_localizations.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';
import '../../services/realtime_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;
import '../../services/maps_service.dart';
import '../../services/location_service.dart' show LocationService, DriverStatus;
import '../../models/user_model.dart';
import '../../models/vehicle_model.dart';
import '../../models/delivery_model.dart';
import '../../models/ride_model.dart';
import '../../models/driver_stats_model.dart';
import '../../models/wallet_model.dart';
import '../auth/role_selection.dart';
import '../passenger/wallet_screen.dart';
import '../shared/chat_screen.dart';
import '../passenger/safety_screen.dart';
import '../passenger/charging_stations.dart';
import 'driver_active_trip_screen.dart';
import 'driver_delivery_active_screen.dart';
import 'driver_missions_screen.dart';
import 'driver_history_screen.dart';
import 'driver_missed_requests_screen.dart';
import 'driver_earnings_screen.dart';
import 'helmet_check_screen.dart';
import '../../widgets/delete_account_dialog.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  int          _tab           = 0;
  DriverStatus _driverStatus  = DriverStatus.online;
  bool         _togglingOnline = false;
  bool   _modeRide     = true;
  bool   _modeDelivery = false;
  bool   _modeRental   = false;
  String _vehicleType  = 'motorbike'; // raw type from VehicleModel.type

  // Wallet-balance gate — checked before showing/allowing the online toggle.
  // min_balance_khr is admin-configurable, so always read it from the API.
  bool _canGoOnline      = true;
  int  _walletBalanceKhr = 0;
  int  _minBalanceKhr    = 0;

  bool get _isOnline => _driverStatus != DriverStatus.offline;

  @override
  void initState() {
    super.initState();
    _loadGoOnlineGate();
  }

  Future<void> _loadGoOnlineGate() async {
    try {
      final status = await ApiService.getDriverStatus();
      if (!mounted) return;
      setState(() {
        _canGoOnline      = status.canGoOnline;
        _walletBalanceKhr = status.walletBalanceKhr;
        _minBalanceKhr    = status.minBalanceKhr;
      });
    } catch (_) {
      // Fail open — don't block the dashboard if this check fails; the
      // backend still enforces the gate on the actual go-online call.
    }
  }

  void _showTopUpRequired({String? message, int? shortByKhr}) {
    final shortfall = shortByKhr ?? (_minBalanceKhr - _walletBalanceKhr);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Icon(Icons.account_balance_wallet_outlined, color: AppTheme.danger),
          const SizedBox(width: 10),
          Expanded(child: Text(AppLocalizations.of(context).topUpRequired, style: TextStyle(fontWeight: FontWeight.w800))),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            message ??
                AppLocalizations.of(context).drvTopUpMsg(AppTheme.khr(_minBalanceKhr)),
            style: TextStyle(color: context.appTextSecondary, fontSize: 13),
          ),
          if (shortfall > 0) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(AppLocalizations.of(context).drvShortBy(AppTheme.khr(shortfall)),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.danger, fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ],
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()));
              _loadGoOnlineGate();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(AppLocalizations.of(context).topUpNow),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleOnline(bool value) async {
    if (_togglingOnline || _driverStatus == DriverStatus.busy) return;
    if (value && !_canGoOnline) {
      _showTopUpRequired();
      return;
    }
    setState(() => _togglingOnline = true);
    try {
      final user     = await ApiService.getSavedUser();
      final driverId = user?.id.toString() ?? '';

      if (value) {
        await ApiService.goOnline();
        if (driverId.isNotEmpty) {
          await LocationService.instance.startOnlineTracking(
            driverId,
            modeRide:     _modeRide,
            modeDelivery: _modeDelivery,
            modeRental:   _modeRental,
            vehicleType:  _vehicleType,
          );
        }
        if (mounted) setState(() => _driverStatus = DriverStatus.online);
      } else {
        await ApiService.goOffline();
        if (driverId.isNotEmpty) {
          await LocationService.instance.stopTracking(driverId);
        }
        if (mounted) setState(() => _driverStatus = DriverStatus.offline);
      }
    } on ApiException catch (e) {
      if (mounted) {
        if (value && e.statusCode == 403) {
          setState(() => _canGoOnline = false);
          _showTopUpRequired(message: e.message);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.message),
            backgroundColor: AppTheme.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ));
        }
      }
    } finally {
      if (mounted) setState(() => _togglingOnline = false);
    }
  }

  // Called when driver accepts a ride — blocks new requests during the trip.
  Future<void> _setBusy() async {
    setState(() => _driverStatus = DriverStatus.busy);
    final user     = await ApiService.getSavedUser();
    final driverId = user?.id.toString() ?? '';
    if (driverId.isNotEmpty) {
      await LocationService.instance.updateDriverStatus(driverId, DriverStatus.busy);
    }
  }

  // Called automatically when the active trip screen closes (complete or cancel).
  Future<void> _setOnlineAfterTrip() async {
    if (!mounted) return;
    setState(() => _driverStatus = DriverStatus.online);
    final user     = await ApiService.getSavedUser();
    final driverId = user?.id.toString() ?? '';
    if (driverId.isNotEmpty) {
      await LocationService.instance.updateDriverStatus(driverId, DriverStatus.online);
      // Resume online-presence tracking
      await LocationService.instance.startOnlineTracking(
        driverId,
        modeRide:     _modeRide,
        modeDelivery: _modeDelivery,
        modeRental:   _modeRental,
        vehicleType:  _vehicleType,
      );
    }
  }

  // Toggles a service mode and, if currently online, immediately pushes the
  // updated modes to Firestore so Smart Dispatch reflects the change instantly.
  Future<void> _changeMode({bool? ride, bool? delivery, bool? rental}) async {
    final newRide     = ride     ?? _modeRide;
    final newDelivery = delivery ?? _modeDelivery;
    final newRental   = rental   ?? _modeRental;
    // At least one mode must stay active
    if (!newRide && !newDelivery && !newRental) return;
    setState(() {
      _modeRide     = newRide;
      _modeDelivery = newDelivery;
      _modeRental   = newRental;
    });
    if (_isOnline) {
      final user     = await ApiService.getSavedUser();
      final driverId = user?.id.toString() ?? '';
      if (driverId.isNotEmpty) {
        await LocationService.instance.updateServiceMode(
          driverId,
          modeRide:     _modeRide,
          modeDelivery: _modeDelivery,
          modeRental:   _modeRental,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _DriverDashboard(
        driverStatus:  _driverStatus,
        onToggle:      _toggleOnline,
        modeRide:      _modeRide,
        modeDelivery:  _modeDelivery,
        modeRental:    _modeRental,
        onModeRide:     (v) => _changeMode(ride:     v),
        onModeDelivery: (v) => _changeMode(delivery: v),
        onModeRental:   (v) => _changeMode(rental:   v),
        onBusy:         _setBusy,
        onTripCompleted: _setOnlineAfterTrip,
        onOpenTab:      (i) => setState(() => _tab = i),
      ),
      _DriverEarnings(onWalletChanged: _loadGoOnlineGate),
      const DriverMissionsScreen(),
      ChargingStationsScreen(isDriver: true, onBack: () => setState(() => _tab = 0)),
      _DriverProfile(onGoToEarnings: () => setState(() => _tab = 1),
          onWalletChanged: _loadGoOnlineGate),
    ];

    final l = AppLocalizations.of(context);
    void go(int i) => setState(() => _tab = i);
    return Scaffold(
      body: pages[_tab],
      // Charging · Missions · [Home / accept rides] · Earnings · Account.
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, -4))],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: _NavItem(icon: Icons.ev_station_rounded,              label: l.charging, index: 3, current: _tab, onTap: go)),
                Expanded(child: _NavItem(icon: Icons.format_list_bulleted_rounded,    label: l.missions, index: 2, current: _tab, onTap: go)),
                Expanded(child: _AcceptRidesButton(
                  label: _driverStatus == DriverStatus.busy
                      ? l.busy
                      : _isOnline ? l.online : l.drvAcceptRides,
                  online: _isOnline,
                  busy: _driverStatus == DriverStatus.busy,
                  onTap: () {
                    go(0);
                    if (!_isOnline && !_togglingOnline) _toggleOnline(true);
                  },
                )),
                Expanded(child: _NavItem(icon: Icons.account_balance_wallet_outlined, label: l.earnings, index: 1, current: _tab, onTap: go)),
                Expanded(child: _NavItem(icon: Icons.person_outline_rounded,          label: l.profile,  index: 4, current: _tab, onTap: go)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Nav item ─────────────────────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index, current;
  final Function(int) onTap;

  const _NavItem({required this.icon, required this.label, required this.index, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final selected = index == current;
    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.accent.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: selected ? AppTheme.accent : context.appTextSecondary, size: 24),
          SizedBox(height: 3),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? AppTheme.accent : context.appTextSecondary,
                fontSize: 11, fontWeight: selected ? FontWeight.w500 : FontWeight.w500,
              )),
        ]),
      ),
    );
  }
}

// ─── Centre "accept rides" button ─────────────────────────────────────────────
class _AcceptRidesButton extends StatelessWidget {
  final String label;
  final bool online, busy;
  final VoidCallback onTap;
  const _AcceptRidesButton({required this.label, required this.online, required this.busy, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = busy ? AppTheme.warning : AppTheme.accent;
    return GestureDetector(
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 62, height: 62,
          padding: online ? const EdgeInsets.all(8) : EdgeInsets.zero,
          decoration: BoxDecoration(
            // Online: ride illustration on white. Offline: the solid power icon.
            color: online ? Colors.white : color,
            shape: BoxShape.circle,
            border: Border.all(color: online ? color : context.appSurface, width: online ? 3 : 4),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 4))],
          ),
          child: online
              ? Image.asset('assets/ride.png', fit: BoxFit.contain,
                  errorBuilder: (_, _e, _s) => Icon(Icons.directions_car_filled_rounded, color: color, size: 28))
              : const Icon(Icons.power_settings_new_rounded, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 3),
        Text(label,
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

// ─── Dashboard ────────────────────────────────────────────────────────────────
class _DriverDashboard extends StatefulWidget {
  final DriverStatus driverStatus;
  final bool modeRide, modeDelivery, modeRental;
  final Function(bool) onToggle, onModeRide, onModeDelivery, onModeRental;
  final VoidCallback onBusy;
  final VoidCallback onTripCompleted;
  final ValueChanged<int> onOpenTab;

  const _DriverDashboard({
    required this.driverStatus,
    required this.onToggle,
    required this.modeRide,
    required this.modeDelivery,
    required this.modeRental,
    required this.onModeRide,
    required this.onModeDelivery,
    required this.onModeRental,
    required this.onBusy,
    required this.onTripCompleted,
    required this.onOpenTab,
  });

  bool get isOnline => driverStatus != DriverStatus.offline;
  bool get isBusy   => driverStatus == DriverStatus.busy;

  @override
  State<_DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<_DriverDashboard>
    with WidgetsBindingObserver {
  DriverStatsModel? _stats;
  UserModel? _user;
  DriverEarningsSummaryModel? _earnings;
  // Admin-managed driver banners (GET /banners) shown in the hero card.
  List<Map<String, dynamic>> _heroBanners = const [];
  int _heroPage = 0; // banner currently shown — its title is the hero title
  List<Map<String, dynamic>> _recentTrips = const [];
  RideModel?     _pendingRide;
  DeliveryModel? _pendingDelivery;
  Map<String, dynamic>? _pendingRental;
  RideModel?     _activeRide;
  DeliveryModel? _activeDelivery;
  SurgeInfo?     _surgeInfo;
  String?        _locationZone;
  // Ride and delivery offers (and their withdrawal) arrive instantly over
  // Reverb (driver.{id} channel); the poll stays as a fallback — fast when the
  // socket is down, slower otherwise (still needed for self-serve rides, which
  // aren't pushed to anyone in particular).
  late final AdaptivePoller _requestPoller = AdaptivePoller(
    onPoll:       _pollRequests,
    fastInterval: const Duration(seconds: 5),
    slowInterval: const Duration(seconds: 10),
  );
  RealtimeSubscription? _offerSub;
  Timer? _surgeTimer;
  int _missedUnseen = 0; // badge on the "missed requests" button

  // Requests this driver already declined / let expire / failed to accept
  // ('ride:12', 'delivery:5', 'rental:3') — never shown again this session,
  // even if the server keeps returning them.
  final Set<String> _dismissed = {};

  RideModel? _firstRide(List<RideModel> l) =>
      l.where((r) => !_dismissed.contains('ride:${r.id}')).firstOrNull;
  DeliveryModel? _firstDelivery(List<DeliveryModel> l) =>
      l.where((d) => !_dismissed.contains('delivery:${d.id}')).firstOrNull;
  Map<String, dynamic>? _firstRental(List<Map<String, dynamic>> l) =>
      l.where((r) => !_dismissed.contains('rental:${r['id']}')).firstOrNull;

  // Accept was refused (taken, cancelled, or "already have an active trip"):
  // drop the card and re-sync — a real active trip then shows as Resume.
  void _onAcceptFailed(String key) {
    _dismissed.add(key);
    setState(() {
      if (key.startsWith('ride:'))     _pendingRide = null;
      if (key.startsWith('delivery:')) _pendingDelivery = null;
      if (key.startsWith('rental:'))   _pendingRental = null;
    });
    _loadData();
  }

  Future<void> _loadMissedBadge() async {
    final n = await DriverMissedRequestsScreen.unseenCount();
    if (mounted) setState(() => _missedUnseen = n);
  }

  Future<void> _openMissedRequests() async {
    setState(() => _missedUnseen = 0);
    await Navigator.push(context,
        MaterialPageRoute(builder: (_) => const DriverMissedRequestsScreen()));
    if (mounted) setState(() => _missedUnseen = 0);
  }

  // A request card was declined or timed out — it's now in the history.
  void _onRequestMissed() => setState(() => _missedUnseen++);

  void _startRequestPolling({bool immediately = false}) {
    _requestPoller.start(immediately: immediately);
    ApiService.getUserId().then((id) {
      if (!mounted || id == null || !_requestPoller.isRunning || _offerSub != null) return;
      _offerSub = RealtimeService.instance.subscribe(
        'driver.$id',
        (_, __) => _requestPoller.pokeNow(),
      );
    });
  }

  void _stopRequestPolling() {
    _requestPoller.stop();
    _offerSub?.cancel();
    _offerSub = null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
    _loadSurge();
    if (widget.driverStatus == DriverStatus.online) {
      _startRequestPolling();
      _surgeTimer = Timer.periodic(const Duration(minutes: 2),  (_) => _loadSurge());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _stopRequestPolling();
      _surgeTimer?.cancel(); _surgeTimer = null;
    } else if (state == AppLifecycleState.resumed) {
      if (widget.driverStatus == DriverStatus.online) {
        _loadData();
        _loadSurge();
        _startRequestPolling(immediately: true);
        _surgeTimer?.cancel();
        _surgeTimer = Timer.periodic(const Duration(minutes: 2),  (_) => _loadSurge());
      }
    }
  }

  @override
  void didUpdateWidget(_DriverDashboard old) {
    super.didUpdateWidget(old);
    if (old.driverStatus != widget.driverStatus) {
      if (widget.driverStatus == DriverStatus.busy) {
        _stopRequestPolling();
        _surgeTimer?.cancel();
      } else if (widget.driverStatus == DriverStatus.online) {
        _surgeTimer?.cancel();
        _startRequestPolling(immediately: true);
        _surgeTimer = Timer.periodic(const Duration(minutes: 2),  (_) => _loadSurge());
        _loadSurge();
      } else {
        _stopRequestPolling();
        _surgeTimer?.cancel();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopRequestPolling();
    _surgeTimer?.cancel();
    super.dispose();
  }

  String _surgeSubtitle(SurgeInfo info) {
    final parts = <String>[];
    if (!info.youAreInside && info.nearbyDistanceKm != null) {
      parts.add(AppLocalizations.of(context).drvKmAway(info.nearbyDistanceKm!.toStringAsFixed(1)));
    }
    if (info.endsAt != null) {
      final diff = info.endsAt!.difference(DateTime.now());
      if (diff.inMinutes > 0) {
        parts.add(diff.inHours >= 1
            ? AppLocalizations.of(context).drvEndsInHm(diff.inHours, diff.inMinutes % 60)
            : AppLocalizations.of(context).drvEndsInMin(diff.inMinutes));
      }
    }
    if (parts.isNotEmpty) return parts.join(' · ');
    return info.youAreInside
        ? (info.message ?? AppLocalizations.of(context).highDemandInYourArea)
        : AppLocalizations.of(context).headThereForHigherEarnings;
  }

  Future<void> _loadSurge() async {
    try {
      double? lat, lng;
      try {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
        );
        lat = pos.latitude;
        lng = pos.longitude;
      } catch (_) {}

      final futures = await Future.wait([
        ApiService.checkSurge(lat: lat, lng: lng),
        if (lat != null && lng != null)
          MapsService.getAreaName(LatLng(lat, lng))
        else
          Future.value(null),
      ]);

      if (!mounted) return;
      final info = futures[0] as SurgeInfo;
      final zone = futures[1] as String?;
      setState(() {
        _surgeInfo    = info.shouldShowBanner ? info : null;
        if (zone != null) _locationZone = zone;
      });
    } catch (_) {}
  }

  Future<void> _loadData() async {
    _loadMissedBadge();
    try {
      final results = await Future.wait([
        ApiService.getDriverStats(),
        ApiService.getAvailableRides(),
        ApiService.getAvailableDeliveries(),
        ApiService.getActiveRide(),
        ApiService.getActiveDelivery(),
        ApiService.getMe(),
      ]);
      if (!mounted) return;
      final rawRide     = results[3] as RideModel?;
      final rawDelivery = results[4] as DeliveryModel?;

      // Only treat as truly active if the ride/delivery is still in-progress
      final activeRide     = (rawRide != null &&
          !rawRide.isCompleted && !rawRide.isCancelled) ? rawRide : null;
      final activeDelivery = (rawDelivery != null &&
          !rawDelivery.isCompleted && !rawDelivery.isCancelled &&
          rawDelivery.status != 'delivered') ? rawDelivery : null;

      final onTrip = activeRide != null || activeDelivery != null;
      setState(() {
        _stats = results[0] as DriverStatsModel;
        // While on a trip, no new requests are shown.
        final rides = results[1] as List<RideModel>;
        _pendingRide = onTrip ? null : _firstRide(rides);
        final deliveries = results[2] as List<DeliveryModel>;
        _pendingDelivery = onTrip ? null : _firstDelivery(deliveries);
        _activeRide     = activeRide;
        _activeDelivery = activeDelivery;
        _user           = results[5] as UserModel;
      });
      if ((activeRide != null || activeDelivery != null) && !widget.isBusy) {
        widget.onBusy();
      }
    } catch (_) {}

    // Dashboard extras — each on its own so one failing never blanks the rest.
    ApiService.getBanners().then((list) {
      final usable = list.where((b) =>
          ((b['image_url'] as String?) ?? (b['image'] as String?) ?? '').isNotEmpty).toList();
      if (mounted) setState(() { _heroBanners = usable; _heroPage = 0; });
    }, onError: (Object e) => debugPrint('[Driver] banners error: $e'));
    ApiService.getDriverEarningsSummary().then((e) {
      if (mounted) setState(() => _earnings = e);
    }, onError: (Object e) => debugPrint('[Driver] earnings summary error: $e'));
    ApiService.getDriverTrips().then((res) {
      final trips = ((res['data'] as List<dynamic>?) ?? const [])
          .whereType<Map<String, dynamic>>().take(3).toList();
      if (mounted) setState(() => _recentTrips = trips);
    }, onError: (Object e) => debugPrint('[Driver] recent trips error: $e'));

    // Fetched separately so a failure here (e.g. endpoint not yet deployed)
    // doesn't take down rides/deliveries loading above.
    try {
      final rentals = await ApiService.getAvailableRentals();
      if (!mounted) return;
      setState(() => _pendingRental = _firstRental(rentals));
    } catch (e) {
      debugPrint('[Driver] getAvailableRentals error: $e');
    }
  }

  Future<void> _openActiveTrip() async {
    if (_activeRide != null) {
      await Navigator.push(context, MaterialPageRoute(
        builder: (_) => DriverActiveTripScreen(ride: _activeRide!),
      ));
      if (!mounted) return;
      final stillActive = await ApiService.getActiveRide();
      if (!mounted) return;
      if (stillActive != null && !stillActive.isCompleted && !stillActive.isCancelled) {
        setState(() => _activeRide = stillActive);
      } else {
        setState(() => _activeRide = null);
        widget.onTripCompleted();
      }
    } else if (_activeDelivery != null) {
      final user = await ApiService.getSavedUser();
      final driverIdStr = user?.id.toString() ?? 'unknown';
      if (!mounted) return;
      await Navigator.push(context, MaterialPageRoute(
        builder: (_) => DriverDeliveryActiveScreen(
          delivery: _activeDelivery!,
          driverIdStr: driverIdStr,
        ),
      ));
      if (!mounted) return;
      // Re-check backend: driver may have backed out without completing.
      final stillActive = await ApiService.getActiveDelivery();
      if (!mounted) return;
      if (stillActive != null) {
        // Trip still in-progress — restore it on the dashboard.
        setState(() => _activeDelivery = stillActive);
      } else {
        setState(() => _activeDelivery = null);
        widget.onTripCompleted();
      }
    }
  }

  Future<void> _pollRequests() async {
    if (widget.driverStatus != DriverStatus.online) return;
    if (_activeRide != null || _activeDelivery != null) return; // on a trip
    // Always re-fetch, even while a request is already showing — /available
    // naturally excludes cancelled/taken rides, so this is how we detect a
    // passenger cancelling a request that's currently on screen. Previously
    // this only ran when _pendingRide was null, so a cancelled request just
    // sat there forever until the driver manually accepted/declined it.
    try {
      final rides = await ApiService.getAvailableRides();
      if (!mounted) return;
      if (_pendingRide != null && !rides.any((r) => r.id == _pendingRide!.id)) {
        setState(() => _pendingRide = null);
        NotificationService.instance.showTripUpdate(
          title: AppLocalizations.of(context).requestCancelled,
          body:  AppLocalizations.of(context).thePassengerCancelledThatRide,
        );
      } else if (_pendingRide == null) {
        final next = _firstRide(rides);
        if (next != null) setState(() => _pendingRide = next);
      }
    } catch (e) {
      debugPrint('[Driver] getAvailableRides error: $e');
    }
    try {
      final deliveries = await ApiService.getAvailableDeliveries();
      if (!mounted) return;
      if (_pendingDelivery != null && !deliveries.any((d) => d.id == _pendingDelivery!.id)) {
        setState(() => _pendingDelivery = null);
      } else if (_pendingDelivery == null) {
        final next = _firstDelivery(deliveries);
        if (next != null) setState(() => _pendingDelivery = next);
      }
    } catch (e) {
      debugPrint('[Driver] getAvailableDeliveries error: $e');
    }
    try {
      final rentals = await ApiService.getAvailableRentals();
      if (!mounted) return;
      if (_pendingRental != null && !rentals.any((r) => r['id'] == _pendingRental!['id'])) {
        setState(() => _pendingRental = null);
      } else if (_pendingRental == null) {
        final next = _firstRental(rentals);
        if (next != null) setState(() => _pendingRental = next);
      }
    } catch (e) {
      debugPrint('[Driver] getAvailableRentals error: $e');
    }
  }


  // ── Dashboard sections ───────────────────────────────────────────────────

  Color get _statusColor => widget.isBusy
      ? AppTheme.warning
      : widget.isOnline ? AppTheme.accent : context.appTextSecondary;

  String _statusLabel(AppLocalizations l) =>
      widget.isBusy ? l.busy : widget.isOnline ? l.online : l.offline;

  Widget _buildHeader(BuildContext context) {
    final l = AppLocalizations.of(context);
    final name  = (_user?.name ?? '').trim();
    final photo = _user?.photoUrl;
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(2.5),
        decoration: const BoxDecoration(color: AppTheme.accent, shape: BoxShape.circle),
        child: CircleAvatar(
          radius: 26,
          backgroundColor: AppTheme.accent.withValues(alpha: 0.12),
          backgroundImage: (photo != null && photo.isNotEmpty) ? NetworkImage(photo) : null,
          child: (photo == null || photo.isEmpty)
              ? Text(name.isNotEmpty ? name.characters.first.toUpperCase() : '?',
                  style: const TextStyle(color: AppTheme.accent, fontSize: 19, fontWeight: FontWeight.w500))
              : null,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name.isEmpty ? '${l.hello}!' : l.drvGreeting(name),
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: context.appTextPrimary, fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Row(children: [
            const Icon(Icons.star_rounded, color: AppTheme.gold, size: 18),
            const SizedBox(width: 3),
            Text(_user?.rating != null ? _user!.rating!.toStringAsFixed(2) : '--',
                style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w500, fontSize: 13)),
            Flexible(
              child: Text(' (${l.drvTripsCount(_user?.totalTrips ?? 0)})',
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: context.appTextSecondary, fontSize: 13)),
            ),
          ]),
        ]),
      ),
      // Missed requests ("missed calls")
      IconButton(
        onPressed: _openMissedRequests,
        tooltip: l.missedRequestsTitle,
        icon: Badge(
          isLabelVisible: _missedUnseen > 0,
          label: Text(_missedUnseen > 99 ? '99+' : '$_missedUnseen'),
          backgroundColor: AppTheme.danger,
          child: Icon(Icons.notifications_none_rounded, color: context.appTextPrimary, size: 28),
        ),
      ),
      Column(mainAxisSize: MainAxisSize.min, children: [
        Transform.scale(
          scale: 1.1,
          child: Switch(
            value: widget.isOnline,
            onChanged: widget.isBusy ? null : widget.onToggle,
            activeThumbColor: Colors.white,
            activeTrackColor: widget.isBusy ? AppTheme.warning : AppTheme.accent,
            // No extra 48px tap padding — keeps the label snug under the switch.
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(height: 4),
        Text(_statusLabel(l),
            style: TextStyle(color: _statusColor, fontSize: 11, fontWeight: FontWeight.w500)),
      ]),
    ]);
  }

  Widget _buildHero(BuildContext context) {
    final l = AppLocalizations.of(context);
    const ink = Colors.white; // on the banner's green left side
    const shadow = [Shadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 1))];
    final accent = widget.isBusy
        ? AppTheme.warning
        : widget.isOnline ? AppTheme.accent : context.appTextSecondary;
    // Online: the current backend banner's title (localized by the server via
    // X-Locale); the built-in text when there is no banner or it has no title.
    // Busy / offline keep their status text — it tells the driver what to do.
    final bannerTitle = _heroBanners.isEmpty
        ? ''
        : (_heroBanners[_heroPage.clamp(0, _heroBanners.length - 1)]['title'] as String? ?? '').trim();
    final title = widget.isBusy
        ? l.busyOnATrip
        : widget.isOnline
            ? (bannerTitle.isNotEmpty ? bannerTitle : l.drvFindingRides)
            : l.offline2;
    // Online needs no explanation — the title says it all.
    final String? subtitle = widget.isBusy
        ? l.completeYourTripToReceive
        : widget.isOnline ? null : l.toggleOnlineToAcceptRides;

    // Backend banners (auto-sliding); the bundled artwork when none are set.
    Widget banner = _HeroBanners(
      banners: _heroBanners,
      fallbackAsset: 'assets/driver_banner.png',
      onPageChanged: (i) => setState(() => _heroPage = i),
      // During a trip the whole card opens the trip instead of a banner link.
      onTapOverride: widget.isBusy ? _openActiveTrip : null,
    );
    // Offline: same artwork, greyed out.
    if (!widget.isOnline) {
      banner = ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0,      0,      0,      1, 0,
        ]),
        child: banner,
      );
    }

    return GestureDetector(
      onTap: widget.isBusy ? _openActiveTrip : null,
      behavior: HitTestBehavior.deferToChild,
      child: AspectRatio(
        aspectRatio: 2.4,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: widget.isBusy ? Border.all(color: AppTheme.warning, width: 2) : null,
            boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: Stack(fit: StackFit.expand, children: [
            banner,
            IgnorePointer(child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 0, 14),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: 0.52, // the tuk-tuk fills the right half
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: accent.withValues(alpha: 0.6)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(width: 8, height: 8,
                            decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            _locationZone != null
                                ? '${_statusLabel(l)} – $_locationZone'
                                : _statusLabel(l),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: accent == context.appTextSecondary ? const Color(0xFF334155) : accent,
                                fontSize: 11.5, fontWeight: FontWeight.w500),
                          ),
                        ),
                        if (widget.isBusy)
                          const Icon(Icons.chevron_right_rounded, color: AppTheme.warning, size: 16),
                      ]),
                    ),
                    const SizedBox(height: 10),
                    Flexible(
                      child: Text(title,
                          maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: ink, fontSize: 17, fontWeight: FontWeight.w500,
                              height: 1.3, shadows: shadow)),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Flexible(
                        child: Text(subtitle,
                            maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: ink.withValues(alpha: 0.92), fontSize: 12,
                                height: 1.4, shadows: shadow)),
                      ),
                    ],
                  ],
                ),
              ),
            )),
          ]),
        ),
      ),
    );
  }

  Widget _card({required Widget child, EdgeInsets? padding, VoidCallback? onTap}) => Material(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(padding: padding ?? const EdgeInsets.all(16), child: child),
        ),
      );

  Widget _buildTodayStats(BuildContext context) {
    final l = AppLocalizations.of(context);
    String date;
    try {
      date = DateFormat.yMMMd(Localizations.localeOf(context).languageCode).format(DateTime.now());
    } catch (_) {
      date = DateFormat('dd/MM/yyyy').format(DateTime.now());
    }
    return _card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(l.drvTodayStats,
                style: TextStyle(color: context.appTextPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
          ),
          Icon(Icons.calendar_month_outlined, size: 18, color: context.appTextSecondary),
          const SizedBox(width: 6),
          Text(date, style: TextStyle(color: context.appTextSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
        ]),
        const SizedBox(height: 14),
        // Equal heights even when one label wraps to two lines.
        IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _StatTile(icon: Icons.check_circle_rounded, color: AppTheme.accent,
              value: '${_stats?.acceptedRides ?? 0}', label: l.accepted),
          const SizedBox(width: 8),
          _StatTile(icon: Icons.task_alt_rounded, color: AppTheme.accentOrange,
              value: '${_stats?.completedRides ?? 0}', label: l.completed),
          const SizedBox(width: 8),
          _StatTile(icon: Icons.schedule_rounded, color: const Color(0xFF7C3AED),
              value: _stats == null ? '--' : '${_stats!.hoursOnline.toStringAsFixed(1)}h', label: l.hoursOnline),
          const SizedBox(width: 8),
          _StatTile(icon: Icons.verified_rounded, color: AppTheme.confirmBlue,
              value: _stats == null ? '--' : '${_stats!.acceptanceRate.toStringAsFixed(0)}%', label: l.acceptanceRate),
        ])),
      ]),
    );
  }

  Widget _buildMoneyRow(BuildContext context) {
    final l = AppLocalizations.of(context);
    Widget money(IconData icon, Color color, String label, String value, VoidCallback onTap) => Expanded(
          child: _card(
            onTap: onTap,
            padding: const EdgeInsets.fromLTRB(12, 14, 8, 14),
            child: Row(children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(value,
                        style: const TextStyle(color: AppTheme.accent, fontSize: 15, fontWeight: FontWeight.w500)),
                  ),
                ]),
              ),
              Icon(Icons.chevron_right_rounded, color: context.appTextSecondary, size: 20),
            ]),
          ),
        );
    return Row(children: [
      money(Icons.monetization_on_rounded, const Color(0xFFF59E0B), l.drvTodayEarnings,
          _earnings == null ? '--' : AppTheme.khr(_earnings!.todayKhr), () => widget.onOpenTab(1)),
      const SizedBox(width: 10),
      money(Icons.account_balance_wallet_rounded, AppTheme.accent, l.drvWalletBalance,
          _earnings == null ? '--' : AppTheme.khr(_earnings!.walletBalance), () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()));
        if (mounted) _loadData();
      }),
    ]);
  }

  Widget _buildQuickActions(BuildContext context) {
    final l = AppLocalizations.of(context);
    void push(Widget w) => Navigator.push(context, MaterialPageRoute(builder: (_) => w));
    final items = <(IconData, Color, String, VoidCallback, int)>[
      (Icons.rocket_launch_rounded,          AppTheme.accent,         l.missions,            () => widget.onOpenTab(2), 0),
      (Icons.payments_rounded,               AppTheme.danger,         l.earnings,            () => widget.onOpenTab(1), 0),
      (Icons.receipt_long_rounded,           AppTheme.confirmBlue,    l.tripHistory,         () => push(const DriverHistoryScreen()), 0),
      (Icons.phone_missed_rounded,           const Color(0xFF7C3AED), l.missedRequestsTitle, _openMissedRequests, _missedUnseen),
      (Icons.ev_station_rounded,             AppTheme.accentOrange,   l.charging,            () => widget.onOpenTab(3), 0),
      (Icons.headset_mic_rounded,            AppTheme.confirmBlue,    l.drvHelp,             () => push(const ChatScreen(isDriver: true)), 0),
      (Icons.account_balance_wallet_rounded, const Color(0xFF0D9488), l.wallet,              () => push(const WalletScreen()), 0),
      (Icons.settings_rounded,               const Color(0xFF475569), l.settings,            () => widget.onOpenTab(4), 0),
    ];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.92,
      children: [
        for (final (icon, color, label, onTap, badge) in items)
          _card(
            onTap: onTap,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Badge(
                isLabelVisible: badge > 0,
                label: Text(badge > 99 ? '99+' : '$badge'),
                backgroundColor: AppTheme.danger,
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(height: 8),
              Text(label,
                  maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                  style: TextStyle(color: context.appTextPrimary, fontSize: 11.5, fontWeight: FontWeight.w500, height: 1.25)),
            ]),
          ),
      ],
    );
  }

  Widget _buildRecentTrips(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
          child: Text(l.recentTrips,
              style: TextStyle(color: context.appTextPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
        ),
        TextButton(
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const DriverHistoryScreen())),
          style: TextButton.styleFrom(foregroundColor: AppTheme.accent, padding: EdgeInsets.zero),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(l.seeAll, style: const TextStyle(fontWeight: FontWeight.w500)),
            const Icon(Icons.chevron_right_rounded, size: 20),
          ]),
        ),
      ]),
      const SizedBox(height: 6),
      if (_recentTrips.isEmpty)
        _card(
          child: Row(children: [
            Icon(Icons.history_rounded, color: context.appTextSecondary),
            const SizedBox(width: 10),
            Expanded(child: Text(l.drvNoRecentTrips,
                style: TextStyle(color: context.appTextSecondary, fontSize: 13))),
          ]),
        )
      else
        for (final t in _recentTrips) ...[
          _RecentTripRow(
            trip: t,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const DriverHistoryScreen())),
          ),
          const SizedBox(height: 10),
        ],
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 18),
            _buildHero(context),
            const SizedBox(height: 16),

            // Surge zone banner — red when inside, amber when nearby
            if (_surgeInfo != null)
              Builder(builder: (_) {
                final inside = _surgeInfo!.youAreInside;
                final color  = inside ? AppTheme.danger : AppTheme.warning;
                final icon   = inside ? Icons.local_fire_department : Icons.directions_outlined;
                final title  = inside
                    ? '🔥 ${AppLocalizations.of(context).drvSurgeInside(_surgeInfo!.multiplier.toStringAsFixed(1))}'
                    : '📍 ${AppLocalizations.of(context).drvSurgeNearby(_surgeInfo!.multiplier.toStringAsFixed(1), _surgeInfo!.zone ?? AppLocalizations.of(context).drvZone)}';
                return Container(
                  margin: EdgeInsets.only(bottom: 14),
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withValues(alpha: 0.40)),
                  ),
                  child: Row(children: [
                    Icon(icon, color: color, size: 20),
                    SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(title,
                          style: TextStyle(color: color,
                              fontWeight: FontWeight.w700, fontSize: 13)),
                      Text(_surgeSubtitle(_surgeInfo!),
                          style: TextStyle(color: context.appTextSecondary, fontSize: 11)),
                    ])),
                    Icon(Icons.chevron_right, color: color.withValues(alpha: 0.6), size: 18),
                  ]),
                );
              }),

            // Service modes (multi-select, at least one active)
            Row(children: [
              _ModeTile(image: 'assets/ride.png', tint: AppTheme.accent, title: AppLocalizations.of(context).rideLabel,
                  subtitle: AppLocalizations.of(context).drvRideSub, active: widget.modeRide,
                  onTap: () => widget.onModeRide(!widget.modeRide)),
              const SizedBox(width: 10),
              _ModeTile(image: 'assets/Delivery.png', tint: AppTheme.accentOrange, title: AppLocalizations.of(context).delivery,
                  subtitle: AppLocalizations.of(context).drvDeliverySub, active: widget.modeDelivery,
                  onTap: () => widget.onModeDelivery(!widget.modeDelivery)),
              const SizedBox(width: 10),
              _ModeTile(image: 'assets/Rental.png', tint: const Color(0xFF9C27B0), title: AppLocalizations.of(context).rental,
                  subtitle: AppLocalizations.of(context).drvRentalSub, active: widget.modeRental,
                  onTap: () => widget.onModeRental(!widget.modeRental)),
            ]),
            const SizedBox(height: 18),

            // Active mode cards (one per active mode)
            if (widget.isOnline) ...[
              // While busy — show resume card
              if (widget.isBusy) ...[
                GestureDetector(
                  onTap: _openActiveTrip,
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.warning.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.warning.withValues(alpha: 0.35)),
                    ),
                    child: Row(children: [
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.warning.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _activeDelivery != null
                              ? Icons.delivery_dining
                              : Icons.electric_rickshaw,
                          color: AppTheme.warning, size: 24),
                      ),
                      SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(
                          _activeDelivery != null
                              ? (_activeDelivery!.isMoving ? AppLocalizations.of(context).movingInProgress : AppLocalizations.of(context).deliveryInProgress)
                              : AppLocalizations.of(context).rideInProgress,
                          style: TextStyle(color: AppTheme.warning, fontWeight: FontWeight.w700, fontSize: 15)),
                        SizedBox(height: 2),
                        Text(AppLocalizations.of(context).tapToOpenTheMap,
                            style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
                      ])),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.warning,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(AppLocalizations.of(context).resume,
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 14),
              ] else ...[
                if (widget.modeRide) ...[
                  if (_pendingRide != null) ...[
                    SectionHeader(title: AppLocalizations.of(context).incomingRideRequest),
                    const SizedBox(height: 14),
                    _RideRequestCard(
                      ride: _pendingRide!,
                      onDeclined: () { _dismissed.add('ride:${_pendingRide?.id}'); setState(() => _pendingRide = null); _onRequestMissed(); },
                      onAcceptFailed: () => _onAcceptFailed('ride:${_pendingRide?.id}'),
                      onAccept: (RideModel ride) async {
                        setState(() { _pendingRide = null; _pendingDelivery = null; _activeRide = ride; });
                        widget.onBusy();
                        await Navigator.push(context, MaterialPageRoute(
                          builder: (_) => DriverActiveTripScreen(ride: ride),
                        ));
                        if (mounted) {
                          setState(() => _activeRide = null);
                          widget.onTripCompleted();
                        }
                      },
                    ),
                  ] else ...[
                    _ModeEmptyCard(
                      image: 'assets/ride.png',
                      color: AppTheme.accent,
                      title: AppLocalizations.of(context).lookingForRideRequests,
                      subtitle: AppLocalizations.of(context).youLlBeNotifiedWhen,
                    ),
                  ],
                  const SizedBox(height: 14),
                ],
                if (widget.modeDelivery) ...[
                  if (_pendingDelivery != null) ...[
                    SectionHeader(title: AppLocalizations.of(context).incomingDeliveryRequest),
                    const SizedBox(height: 14),
                    _DeliveryRequestCard(
                      delivery: _pendingDelivery!,
                      onDeclined: () { _dismissed.add('delivery:${_pendingDelivery?.id}'); setState(() => _pendingDelivery = null); _onRequestMissed(); },
                      onAcceptFailed: () => _onAcceptFailed('delivery:${_pendingDelivery?.id}'),
                      onAccept: (DeliveryModel delivery) async {
                        // Same as rides: busy stops new offers until it's done.
                        setState(() { _pendingDelivery = null; _pendingRide = null; _activeDelivery = delivery; });
                        widget.onBusy();
                        final user = await ApiService.getSavedUser();
                        final driverIdStr = user?.id.toString() ?? 'unknown';
                        if (!mounted) return;
                        await Navigator.push(context, MaterialPageRoute(
                          builder: (_) => DriverDeliveryActiveScreen(
                            delivery: delivery,
                            driverIdStr: driverIdStr,
                          ),
                        ));
                        if (!mounted) return;
                        // Backed out mid-job? Keep showing the resume card.
                        final stillActive = await ApiService.getActiveDelivery();
                        if (!mounted) return;
                        if (stillActive != null) {
                          setState(() => _activeDelivery = stillActive);
                        } else {
                          setState(() => _activeDelivery = null);
                          widget.onTripCompleted();
                        }
                      },
                    ),
                  ] else ...[
                    _ModeEmptyCard(
                      image: 'assets/Delivery.png',
                      color: AppTheme.accentOrange,
                      title: AppLocalizations.of(context).deliveryModeActive,
                      subtitle: AppLocalizations.of(context).waitingForDeliveryOrdersIn,
                    ),
                  ],
                  const SizedBox(height: 14),
                ],
                if (widget.modeRental) ...[
                  if (_pendingRental != null) ...[
                    SectionHeader(title: AppLocalizations.of(context).incomingRentalRequest),
                    const SizedBox(height: 14),
                    _RentalRequestCard(
                      rental: _pendingRental!,
                      onDeclined: () { _dismissed.add('rental:${_pendingRental?['id']}'); setState(() => _pendingRental = null); _onRequestMissed(); },
                      onAcceptFailed: () => _onAcceptFailed('rental:${_pendingRental?['id']}'),
                      onAccept: (rental) async {
                        setState(() => _pendingRental = null);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(AppLocalizations.of(context).rentalRequestAccepted),
                          backgroundColor: AppTheme.success,
                          behavior: SnackBarBehavior.floating,
                        ));
                      },
                    ),
                  ] else ...[
                    _ModeEmptyCard(
                      image: 'assets/Rental.png',
                      color: const Color(0xFF9C27B0),
                      title: AppLocalizations.of(context).rentalModeActive,
                      subtitle: AppLocalizations.of(context).yourVehicleIsListedFor,
                    ),
                  ],
                  const SizedBox(height: 14),
                ],
              ],
            ],

            _buildTodayStats(context),
            const SizedBox(height: 14),
            _buildMoneyRow(context),
            const SizedBox(height: 14),
            _buildQuickActions(context),
            const SizedBox(height: 20),
            _buildRecentTrips(context),
            const SizedBox(height: 20),

            // Peak hour bonus tracker
            if (_stats != null) ...[
              Builder(builder: (context) {
                final peak = _stats!.peakHour;
                return Container(
                  padding: EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: context.appSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.warning.withValues(alpha: 0.4)),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Icon(Icons.bolt, color: AppTheme.warning, size: 20),
                      SizedBox(width: 8),
                      Text(AppLocalizations.of(context).peakHourBonus, style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
                      Spacer(),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (peak.active ? AppTheme.warning : context.appTextSecondary).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${peak.active ? AppLocalizations.of(context).active : AppLocalizations.of(context).drvInactive} ${peak.windowStart}–${peak.windowEnd}',
                          style: TextStyle(color: peak.active ? AppTheme.warning : context.appTextSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ]),
                    SizedBox(height: 10),
                    Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(AppLocalizations.of(context).drvPeakExtra(AppTheme.khr(peak.bonusPerTripKhr)), style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
                        SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: peak.progress,
                            backgroundColor: context.appCardBg,
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.warning),
                            minHeight: 6,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(AppLocalizations.of(context).drvPeakProgress(peak.tripsToday, peak.tripTarget), style: TextStyle(color: context.appTextSecondary, fontSize: 11)),
                      ])),
                      SizedBox(width: 14),
                      Column(children: [
                        Text('+${AppTheme.khr(peak.earnedTodayKhr)}', style: TextStyle(color: AppTheme.warning, fontWeight: FontWeight.w900, fontSize: 20)),
                        Text(AppLocalizations.of(context).earnedToday, style: TextStyle(color: context.appTextSecondary, fontSize: 10)),
                      ]),
                    ]),
                  ]),
                );
              }),
              SizedBox(height: 14),

              // 5-star streak rewards
              Builder(builder: (context) {
                final streak = _stats!.ratingStreak;
                return Container(
                  padding: EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: context.appSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.gold.withValues(alpha: 0.4)),
                  ),
                  child: Row(children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppTheme.gold.withValues(alpha: 0.15), shape: BoxShape.circle),
                      child: Icon(Icons.emoji_events, color: AppTheme.gold, size: 26),
                    ),
                    SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(AppLocalizations.of(context).n5StarStreak, style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w700)),
                      Text(AppLocalizations.of(context).drvStreakCount(streak.current), style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
                      SizedBox(height: 4),
                      Text(
                        streak.remaining > 0
                            ? AppLocalizations.of(context).drvStreakRemaining(streak.remaining, AppTheme.khr(streak.bonusKhr))
                            : AppLocalizations.of(context).drvStreakUnlocked(AppTheme.khr(streak.bonusKhr)),
                        style: TextStyle(color: AppTheme.gold, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ])),
                    Row(children: List.generate(5, (i) => Icon(
                      i < streak.current.clamp(0, 5) ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: i < streak.current.clamp(0, 5) ? AppTheme.gold : context.appTextSecondary, size: 18,
                    ))),
                  ]),
                );
              }),
              SizedBox(height: 20),
            ],

            SectionHeader(title: AppLocalizations.of(context).promotions),
            const SizedBox(height: 14),
            const PromoEventsSection(),
          ],
        ),
      ),
    );
  }
}

// ─── Hero banner background ───────────────────────────────────────────────────
// Admin-managed images (GET /banners, filtered to drivers by the server),
// auto-sliding when there are several; the bundled artwork when there are none.
class _HeroBanners extends StatefulWidget {
  final List<Map<String, dynamic>> banners;
  final String fallbackAsset;
  final VoidCallback? onTapOverride;
  final ValueChanged<int>? onPageChanged;
  const _HeroBanners({required this.banners, required this.fallbackAsset, this.onTapOverride, this.onPageChanged});

  @override
  State<_HeroBanners> createState() => _HeroBannersState();
}

class _HeroBannersState extends State<_HeroBanners> {
  final _controller = PageController();
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _restartTimer();
  }

  @override
  void didUpdateWidget(covariant _HeroBanners old) {
    super.didUpdateWidget(old);
    if (old.banners.length != widget.banners.length) {
      _page = 0;
      _restartTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _restartTimer() {
    _timer?.cancel();
    if (widget.banners.length < 2) return;
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_controller.hasClients) return;
      _controller.animateToPage((_page + 1) % widget.banners.length,
          duration: const Duration(milliseconds: 450), curve: Curves.easeOutCubic);
    });
  }

  Widget get _fallback => Image.asset(widget.fallbackAsset,
      fit: BoxFit.cover, alignment: Alignment.centerRight,
      // Asset missing from an old build (added without a full rebuild) —
      // plain green instead of Flutter's red error box.
      errorBuilder: (_, _e, _s) => const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF0F9D58), Color(0xFF34C77B)]),
            ),
          ));

  Future<void> _open(Map<String, dynamic> b) async {
    if (widget.onTapOverride != null) return widget.onTapOverride!();
    final uri = Uri.tryParse((b['deeplink'] as String?)?.trim() ?? '');
    if (uri == null || !uri.hasScheme) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final banners = widget.banners;
    if (banners.isEmpty) return _fallback;
    return Stack(fit: StackFit.expand, children: [
      PageView.builder(
        controller: _controller,
        itemCount: banners.length,
        onPageChanged: (i) {
          setState(() => _page = i);
          widget.onPageChanged?.call(i);
          _restartTimer(); // a manual swipe resets the countdown
        },
        itemBuilder: (_, i) {
          final b = banners[i];
          return GestureDetector(
            onTap: () => _open(b),
            child: CachedNetworkImage(
              imageUrl: (b['image_url'] as String?) ?? (b['image'] as String?) ?? '',
              fit: BoxFit.cover,
              alignment: Alignment.centerRight,
              placeholder: (_, _u) => _fallback,
              errorWidget: (_, _u, _e) => _fallback,
            ),
          );
        },
      ),
      if (banners.length > 1)
        Positioned(
          right: 14, bottom: 10,
          child: IgnorePointer(
            child: Row(children: List.generate(banners.length, (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: _page == i ? 16 : 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 2.5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: _page == i ? 0.95 : 0.55),
                borderRadius: BorderRadius.circular(3),
              ),
            ))),
          ),
        ),
    ]);
  }
}

// ─── Service mode tile ────────────────────────────────────────────────────────
class _ModeTile extends StatelessWidget {
  final String image; // same illustrations as the passenger home
  final Color tint;   // matches this mode's waiting card below
  final String title, subtitle;
  final bool active;
  final VoidCallback onTap; // toggles this mode; parent guards against all-off

  const _ModeTile({required this.image, required this.tint, required this.title, required this.subtitle, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = active ? tint : context.appTextSecondary;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          decoration: BoxDecoration(
            color: active ? tint.withValues(alpha: 0.10) : context.appSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: active ? tint : Colors.transparent, width: 1.5),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Inactive modes are shown greyed out.
            Opacity(
              opacity: active ? 1 : 0.45,
              child: Image.asset(image, height: 40, fit: BoxFit.contain,
                  errorBuilder: (_, _e, _s) => Icon(Icons.image_not_supported_outlined, color: color, size: 30)),
            ),
            const SizedBox(height: 4),
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(color: active ? tint : context.appTextPrimary,
                    fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(color: context.appTextSecondary, fontSize: 10)),
          ]),
        ),
      ),
    );
  }
}

// ─── Mode empty/waiting card ──────────────────────────────────────────────────
class _ModeEmptyCard extends StatelessWidget {
  final String image; // same illustration as the mode tile above
  final Color color;
  final String title;
  final String subtitle;

  const _ModeEmptyCard({
    required this.image,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(children: [
        Container(
          padding: EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Image.asset(image, width: 34, height: 34, fit: BoxFit.contain,
              errorBuilder: (_, _e, _s) => Icon(Icons.hourglass_empty_rounded, color: color, size: 28)),
        ),
        SizedBox(height: 12),
        Text(title,
            style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 15)),
        SizedBox(height: 6),
        Text(subtitle,
            style: TextStyle(color: context.appTextSecondary, fontSize: 12),
            textAlign: TextAlign.center),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          SizedBox(
            width: 8, height: 8,
            child: CircularProgressIndicator(
                color: color, strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text(AppLocalizations.of(context).waiting, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      ]),
    );
  }
}

// ─── Today stat tile ──────────────────────────────────────────────────────────
class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value, label;

  const _StatTile({required this.icon, required this.color, required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 12, 6, 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: TextStyle(color: color, fontSize: 17, fontWeight: FontWeight.w500)),
            ),
            const SizedBox(height: 2),
            Text(label, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: TextStyle(color: context.appTextSecondary, fontSize: 11, height: 1.25)),
          ]),
        ),
      );
}

// ─── Recent trip row ──────────────────────────────────────────────────────────
class _RecentTripRow extends StatelessWidget {
  final Map<String, dynamic> trip;
  final VoidCallback onTap;
  const _RecentTripRow({required this.trip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final created = DateTime.tryParse(trip['created_at']?.toString() ?? '')?.toLocal();
    final time    = created == null ? '--:--' : DateFormat('HH:mm').format(created);
    final from    = (trip['pickup_address']  as String?)?.trim() ?? '';
    final to      = (trip['dropoff_address'] as String?)?.trim() ?? '';
    final fare    = (trip['fare_khr'] as num?)?.toInt() ?? 0;
    final status  = trip['status']?.toString() ?? 'completed';
    final done    = status == 'completed';
    Widget place(Color color, String text) => Expanded(
          child: Row(children: [
            Icon(Icons.location_on_rounded, color: color, size: 18),
            const SizedBox(width: 3),
            Expanded(child: Text(text.isEmpty ? '--' : text,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(color: context.appTextPrimary, fontSize: 13, fontWeight: FontWeight.w500))),
          ]),
        );
    return Material(
      color: context.appSurface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
          child: Row(children: [
            Container(width: 10, height: 10,
                decoration: BoxDecoration(
                    color: done ? AppTheme.accent : context.appTextSecondary, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(time, style: TextStyle(color: context.appTextSecondary, fontSize: 13)),
            const SizedBox(width: 10),
            place(AppTheme.accent, from),
            const SizedBox(width: 6),
            place(AppTheme.danger, to),
            const SizedBox(width: 8),
            Text(fare > 0 ? AppTheme.khr(fare) : '--',
                style: TextStyle(color: done ? AppTheme.accent : context.appTextSecondary,
                    fontSize: 13, fontWeight: FontWeight.w500)),
            Icon(Icons.chevron_right_rounded, color: context.appTextSecondary, size: 20),
          ]),
        ),
      ),
    );
  }
}

// ─── Ride request card with countdown ─────────────────────────────────────────
class _RideRequestCard extends StatefulWidget {
  final RideModel    ride;
  // Parent dashboard owns navigation so it stays mounted for the full trip.
  final Future<void> Function(RideModel) onAccept;
  final VoidCallback onDeclined;
  final VoidCallback? onAcceptFailed; // server refused the accept

  const _RideRequestCard({
    required this.ride,
    required this.onAccept,
    required this.onDeclined,
    this.onAcceptFailed,
  });

  @override
  State<_RideRequestCard> createState() => _RideRequestCardState();
}

class _RideRequestCardState extends State<_RideRequestCard> {
  int _seconds = 30;
  Timer? _timer;
  bool _acting = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_seconds <= 1) {
        t.cancel();
        ApiService.recordMissedRequest('ride', widget.ride.id, 'missed');
        widget.onDeclined();
      } else {
        setState(() => _seconds--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _accept() async {
    if (_acting) return;
    _timer?.cancel();
    setState(() => _acting = true);
    try {
      // The accept response's `driver_info` just echoes the accepting
      // driver's own profile (name/vehicle) — not needed here since the
      // driver already has that locally. Keep using widget.ride, which
      // carries the full pickup/dropoff coordinates from the original
      // ride-request payload (the accept response's `ride` object omits
      // them per the backend spec).
      await ApiService.acceptRide(widget.ride.id);
      if (!mounted) return;
      // Delegate all state changes and navigation to the parent dashboard.
      // The card may be unmounted immediately after this call — that is fine
      // because the parent context stays alive for the whole trip.
      await widget.onAccept(widget.ride);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message),
        backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      // Refused by the server — this request can't be taken, so close it.
      if (widget.onAcceptFailed != null) {
        widget.onAcceptFailed!();
        return;
      }
      setState(() => _acting = false);
    } catch (_) {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _decline() async {
    if (_acting) return;
    _timer?.cancel();
    setState(() => _acting = true);
    ApiService.recordMissedRequest('ride', widget.ride.id, 'declined');
    try {
      await ApiService.declineRide(widget.ride.id);
    } catch (_) {}
    if (mounted) widget.onDeclined();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _seconds / 30.0;
    final urgent   = _seconds <= 8;
    final accentColor = urgent ? AppTheme.danger : AppTheme.accent;
    final passengerLabel = widget.ride.passenger?.name ?? AppLocalizations.of(context).drvPassengerNo(widget.ride.passengerId);

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [BoxShadow(
            color: accentColor.withValues(alpha: 0.15),
            blurRadius: 16, offset: Offset(0, 4))],
      ),
      child: Column(children: [
        // Header row: badge + countdown
        Row(children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20)),
            child: Text(urgent ? AppLocalizations.of(context).urgent : AppLocalizations.of(context).newRequest,
                style: TextStyle(color: accentColor,
                    fontWeight: FontWeight.w800, fontSize: 11)),
          ),
          Spacer(),
          Text(AppLocalizations.of(context).drvSecondsShort(_seconds), style: TextStyle(
              color: accentColor, fontWeight: FontWeight.w900, fontSize: 16)),
        ]),
        SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: context.appCardBg,
            valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            minHeight: 5,
          ),
        ),
        SizedBox(height: 12),

        // Passenger + fare
        Row(children: [
          CircleAvatar(
            backgroundColor: accentColor.withValues(alpha: 0.15),
            radius: 18,
            child: Text(passengerLabel[0],
                style: TextStyle(color: accentColor, fontWeight: FontWeight.w700)),
          ),
          SizedBox(width: 10),
          Expanded(child: Text(passengerLabel,
              style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w600))),
          widget.ride.noDestination
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(AppLocalizations.of(context).meteredFare,
                      style: TextStyle(color: AppTheme.accent, fontSize: 12, fontWeight: FontWeight.w700)),
                )
              : Text(AppTheme.khr(widget.ride.fareKhr),
                  style: TextStyle(color: context.appTextPrimary,
                      fontSize: 20, fontWeight: FontWeight.w800)),
        ]),
        SizedBox(height: 12),

        // Addresses
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: context.appCardBg,
              borderRadius: BorderRadius.circular(10)),
          child: Column(children: [
            Row(children: [
              Icon(Icons.circle, color: accentColor, size: 8),
              SizedBox(width: 8),
              Expanded(child: Text(widget.ride.pickupAddress,
                  style: TextStyle(color: context.appTextPrimary, fontSize: 13),
                  overflow: TextOverflow.ellipsis)),
            ]),
            SizedBox(height: 6),
            Row(children: [
              Icon(widget.ride.noDestination ? Icons.record_voice_over_outlined : Icons.location_on,
                  color: widget.ride.noDestination ? AppTheme.accent : AppTheme.danger, size: 10),
              SizedBox(width: 8),
              Expanded(child: Text(
                  widget.ride.noDestination
                      ? AppLocalizations.of(context).noDestinationPassengerWillTell
                      : widget.ride.dropoffAddress,
                  style: TextStyle(
                      color: widget.ride.noDestination ? AppTheme.accent : context.appTextSecondary,
                      fontSize: 13,
                      fontWeight: widget.ride.noDestination ? FontWeight.w600 : FontWeight.w400),
                  overflow: TextOverflow.ellipsis)),
            ]),
          ]),
        ),
        SizedBox(height: 14),

        // Buttons
        Row(children: [
          Expanded(child: GestureDetector(
            onTap: _acting ? null : _decline,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                  border: Border.all(color: context.appTextSecondary.withValues(alpha: 0.4)),
                  borderRadius: BorderRadius.circular(10)),
              child: Center(child: Text(AppLocalizations.of(context).decline,
                  style: TextStyle(color: context.appTextSecondary, fontWeight: FontWeight.w600))),
            ),
          )),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: GestureDetector(
            onTap: _acting ? null : _accept,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                  color: AppTheme.accent, borderRadius: BorderRadius.circular(10)),
              child: Center(child: _acting
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(AppLocalizations.of(context).acceptRide,
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
            ),
          )),
        ]),
      ]),
    );
  }
}

// ─── Delivery request card with countdown ─────────────────────────────────────
class _DeliveryRequestCard extends StatefulWidget {
  final DeliveryModel delivery;
  // Parent dashboard owns navigation so it stays mounted for the full delivery.
  final Future<void> Function(DeliveryModel) onAccept;
  final VoidCallback onDeclined;
  final VoidCallback? onAcceptFailed; // server refused the accept

  const _DeliveryRequestCard({
    required this.delivery,
    required this.onAccept,
    required this.onDeclined,
    this.onAcceptFailed,
  });

  @override
  State<_DeliveryRequestCard> createState() => _DeliveryRequestCardState();
}

class _DeliveryRequestCardState extends State<_DeliveryRequestCard> {
  int _seconds = 30;
  Timer? _timer;
  bool _acting = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_seconds <= 1) {
        t.cancel();
        ApiService.recordMissedRequest('delivery', widget.delivery.id, 'missed');
        widget.onDeclined();
      } else {
        setState(() => _seconds--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _accept() async {
    if (_acting) return;
    _timer?.cancel();
    setState(() => _acting = true);
    try {
      await ApiService.acceptDelivery(widget.delivery.id);
      if (!mounted) return;
      await widget.onAccept(widget.delivery);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message),
        backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      // Refused by the server — this request can't be taken, so close it.
      if (widget.onAcceptFailed != null) {
        widget.onAcceptFailed!();
        return;
      }
      setState(() => _acting = false);
    } catch (_) {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _decline() async {
    if (_acting) return;
    _timer?.cancel();
    ApiService.recordMissedRequest('delivery', widget.delivery.id, 'declined');
    widget.onDeclined();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _seconds / 30.0;
    final urgent   = _seconds <= 8;
    final senderLabel = widget.delivery.sender?.name
        ?? widget.delivery.senderName
        ?? AppLocalizations.of(context).drvSenderNo(widget.delivery.senderId);

    final cardColor = urgent ? AppTheme.danger : AppTheme.success;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardColor.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [BoxShadow(
            color: cardColor.withValues(alpha: 0.15),
            blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: cardColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20)),
            child: Text(
              urgent ? AppLocalizations.of(context).urgent
                  : widget.delivery.isMoving ? AppLocalizations.of(context).newMoving : AppLocalizations.of(context).newDelivery,
              style: TextStyle(color: cardColor,
                  fontWeight: FontWeight.w800, fontSize: 11),
            ),
          ),
          const Spacer(),
          Text(AppLocalizations.of(context).drvSecondsShort(_seconds), style: TextStyle(
              color: cardColor, fontWeight: FontWeight.w900, fontSize: 16)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: context.appCardBg,
            valueColor: AlwaysStoppedAnimation<Color>(cardColor),
            minHeight: 5,
          ),
        ),
        const SizedBox(height: 12),

        Row(children: [
          CircleAvatar(
            backgroundColor: cardColor.withValues(alpha: 0.15),
            radius: 18,
            child: Text(senderLabel[0],
                style: TextStyle(color: cardColor, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(senderLabel,
                style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w600)),
            if (widget.delivery.packageSize != null)
              Text(widget.delivery.packageSize!,
                  style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
          ])),
          Text(AppTheme.khr(widget.delivery.fee),
              style: TextStyle(color: context.appTextPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: context.appCardBg,
              borderRadius: BorderRadius.circular(10)),
          child: Column(children: [
            Row(children: [
              Icon(Icons.circle, color: cardColor, size: 8),
              const SizedBox(width: 8),
              Expanded(child: Text(widget.delivery.pickupAddress,
                  style: TextStyle(color: context.appTextPrimary, fontSize: 13),
                  overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.location_on, color: AppTheme.danger, size: 10),
              const SizedBox(width: 8),
              Expanded(child: Text(widget.delivery.dropoffAddress,
                  style: TextStyle(color: context.appTextSecondary, fontSize: 13),
                  overflow: TextOverflow.ellipsis)),
            ]),
          ]),
        ),

        // ── Moving details panel ─────────────────────────────────────────
        if (widget.delivery.isMoving) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.appCardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: cardColor.withValues(alpha: 0.3)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.local_shipping, color: cardColor, size: 14),
                const SizedBox(width: 6),
                Text(AppLocalizations.of(context).movingDetails, style: TextStyle(
                    color: context.appTextPrimary, fontWeight: FontWeight.w700, fontSize: 12)),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Icon(Icons.apartment_outlined, color: context.appTextSecondary, size: 14),
                const SizedBox(width: 6),
                Text(
                  AppLocalizations.of(context).drvFloors(widget.delivery.floorPickup ?? '?',
                      widget.delivery.floorDropoff ?? '?'),
                  style: TextStyle(color: context.appTextSecondary, fontSize: 12),
                ),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.elevator_outlined, color: context.appTextPrimary, size: 14),
                const SizedBox(width: 6),
                Text(
                  AppLocalizations.of(context).drvElevator((widget.delivery.hasElevator ?? true) ? AppLocalizations.of(context).yes : AppLocalizations.of(context).no),
                  style: TextStyle(color: context.appTextPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                if (widget.delivery.needsStairsCarry == true) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.stairs_outlined, color: context.appTextSecondary, size: 14),
                  Text(AppLocalizations.of(context).stairsCarry,
                      style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
                ],
              ]),
              const SizedBox(height: 4),
              if (widget.delivery.requiresHelpers != null)
                Row(children: [
                  Icon(Icons.people_outline, color: context.appTextSecondary, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    AppLocalizations.of(context).drvHelpers(widget.delivery.requiresHelpers!,
                        widget.delivery.helperType == 'heavy_carry' ? AppLocalizations.of(context).drvHeavyCarry : AppLocalizations.of(context).drvNormalCarry),
                    style: TextStyle(color: context.appTextSecondary, fontSize: 12),
                  ),
                ]),
              const SizedBox(height: 6),
              Wrap(spacing: 6, children: [
                if (widget.delivery.heavyItems == true)
                  _MovingFlag(label: AppLocalizations.of(context).heavyItems, color: cardColor),
                if (widget.delivery.packingService == true)
                  _MovingFlag(label: AppLocalizations.of(context).packing, color: cardColor),
              ]),
            ]),
          ),
        ],

        const SizedBox(height: 14),

        Row(children: [
          Expanded(child: GestureDetector(
            onTap: _acting ? null : _decline,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                  border: Border.all(color: context.appTextSecondary.withValues(alpha: 0.4)),
                  borderRadius: BorderRadius.circular(10)),
              child: Center(child: Text(AppLocalizations.of(context).decline,
                  style: TextStyle(color: context.appTextSecondary, fontWeight: FontWeight.w600))),
            ),
          )),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: GestureDetector(
            onTap: _acting ? null : _accept,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                  color: cardColor, borderRadius: BorderRadius.circular(10)),
              child: Center(child: _acting
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(AppLocalizations.of(context).acceptDelivery,
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
            ),
          )),
        ]),
      ]),
    );
  }
}

// ─── Rental request card ────────────────────────────────────────────────────

class _RentalRequestCard extends StatefulWidget {
  final Map<String, dynamic> rental;
  final Future<void> Function(Map<String, dynamic>) onAccept;
  final VoidCallback onDeclined;
  final VoidCallback? onAcceptFailed; // server refused the accept

  const _RentalRequestCard({
    required this.rental,
    required this.onAccept,
    required this.onDeclined,
    this.onAcceptFailed,
  });

  @override
  State<_RentalRequestCard> createState() => _RentalRequestCardState();
}

class _RentalRequestCardState extends State<_RentalRequestCard> {
  static const _color = Color(0xFF9C27B0);

  int _seconds = 30;
  Timer? _timer;
  bool _acting = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_seconds <= 1) {
        t.cancel();
        ApiService.recordMissedRequest('rental', _id, 'missed');
        widget.onDeclined();
      } else {
        setState(() => _seconds--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int get _id => ((widget.rental['id'] ?? widget.rental['rental_id']) as num?)?.toInt() ?? 0;

  Future<void> _accept() async {
    if (_acting) return;
    _timer?.cancel();
    setState(() => _acting = true);
    try {
      await ApiService.acceptRentalRequest(_id);
      if (!mounted) return;
      await widget.onAccept(widget.rental);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message),
        backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      // Refused by the server — this request can't be taken, so close it.
      if (widget.onAcceptFailed != null) {
        widget.onAcceptFailed!();
        return;
      }
      setState(() => _acting = false);
    } catch (_) {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _decline() async {
    if (_acting) return;
    _timer?.cancel();
    ApiService.recordMissedRequest('rental', _id, 'declined');
    try {
      await ApiService.declineRentalRequest(_id);
    } catch (_) {}
    widget.onDeclined();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _seconds / 30.0;
    final urgent   = _seconds <= 8;
    final cardColor = urgent ? AppTheme.danger : _color;

    final r = widget.rental;
    final customerName = (r['customer'] as Map<String, dynamic>?)?['name'] as String?
        ?? r['customer_name'] as String?
        ?? AppLocalizations.of(context).trCustomerNo(r['customer_id'] ?? '');
    final vehicleType = r['vehicle_type'] as String?;
    final pickup = r['pickup_location'] as String? ?? '--';
    final startDate = r['start_date'] as String?;
    final endDate = r['end_date'] as String?;
    final total = (r['total'] as num?)?.toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardColor.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [BoxShadow(
            color: cardColor.withValues(alpha: 0.15),
            blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: cardColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20)),
            child: Text(
              urgent ? AppLocalizations.of(context).urgent : AppLocalizations.of(context).newRental,
              style: TextStyle(color: cardColor,
                  fontWeight: FontWeight.w800, fontSize: 11),
            ),
          ),
          const Spacer(),
          Text(AppLocalizations.of(context).drvSecondsShort(_seconds), style: TextStyle(
              color: cardColor, fontWeight: FontWeight.w900, fontSize: 16)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: context.appCardBg,
            valueColor: AlwaysStoppedAnimation<Color>(cardColor),
            minHeight: 5,
          ),
        ),
        const SizedBox(height: 12),

        Row(children: [
          CircleAvatar(
            backgroundColor: cardColor.withValues(alpha: 0.15),
            radius: 18,
            child: Text(customerName.isNotEmpty ? customerName[0] : '?',
                style: TextStyle(color: cardColor, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(customerName,
                style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w600)),
            if (vehicleType != null)
              Text(vehicleType,
                  style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
          ])),
          if (total != null)
            Text('\$${total.toStringAsFixed(0)}',
                style: TextStyle(color: context.appTextPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: context.appCardBg,
              borderRadius: BorderRadius.circular(10)),
          child: Column(children: [
            Row(children: [
              Icon(Icons.location_on, color: cardColor, size: 14),
              const SizedBox(width: 8),
              Expanded(child: Text(pickup,
                  style: TextStyle(color: context.appTextPrimary, fontSize: 13),
                  overflow: TextOverflow.ellipsis)),
            ]),
            if (startDate != null && endDate != null) ...[
              const SizedBox(height: 6),
              Row(children: [
                Icon(Icons.date_range_rounded, color: context.appTextSecondary, size: 14),
                const SizedBox(width: 8),
                Expanded(child: Text('$startDate → $endDate',
                    style: TextStyle(color: context.appTextSecondary, fontSize: 13),
                    overflow: TextOverflow.ellipsis)),
              ]),
            ],
          ]),
        ),

        const SizedBox(height: 14),

        Row(children: [
          Expanded(child: GestureDetector(
            onTap: _acting ? null : _decline,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                  border: Border.all(color: context.appTextSecondary.withValues(alpha: 0.4)),
                  borderRadius: BorderRadius.circular(10)),
              child: Center(child: Text(AppLocalizations.of(context).decline,
                  style: TextStyle(color: context.appTextSecondary, fontWeight: FontWeight.w600))),
            ),
          )),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: GestureDetector(
            onTap: _acting ? null : _accept,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                  color: cardColor, borderRadius: BorderRadius.circular(10)),
              child: Center(child: _acting
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(AppLocalizations.of(context).acceptRental,
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
            ),
          )),
        ]),
      ]),
    );
  }
}

// ─── Earnings tab ─────────────────────────────────────────────────────────────
class _DriverEarnings extends StatefulWidget {
  final VoidCallback? onWalletChanged;
  const _DriverEarnings({this.onWalletChanged});

  @override
  State<_DriverEarnings> createState() => _DriverEarningsState();
}

class _DriverEarningsState extends State<_DriverEarnings> {
  // Balance
  WalletModel? _wallet;
  bool   _balanceLoading = true;
  String? _balanceError;

  // Transactions (paginated)
  final List<WalletTransactionModel> _transactions = [];
  int  _currentPage   = 1;
  int  _lastPage      = 1;
  int  _total         = 0;
  bool _txLoading     = false;
  bool _txLoadingMore = false;
  String? _txError;
  bool _showAllTx     = false; // false = today only, true = full history

  bool _isToday(String createdAt) {
    final dt = DateTime.tryParse(createdAt)?.toLocal();
    if (dt == null) return false;
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  List<WalletTransactionModel> get _visibleTx => _showAllTx
      ? _transactions
      : _transactions.where((t) => _isToday(t.createdAt)).toList();

  // No BuildContext at field-init time — resolved to the localized default
  // in didChangeDependencies below.
  String _bank       = '';
  bool   _withdrawing = false;
  final _payoutAccNumCtrl  = TextEditingController();
  final _payoutAccNameCtrl = TextEditingController();

  bool _bankDefaultApplied = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bankDefaultApplied) return;
    _bankDefaultApplied = true;
    _bank = AppLocalizations.of(context).abaBank;
  }

  List<Map<String, Object>> _banksFor(AppLocalizations l) => [
    {'name': l.abaBank,    'icon': Icons.account_balance,        'color': const Color(0xFF00D4AA), 'method': 'aba'},
    {'name': l.acledaBank, 'icon': Icons.account_balance_wallet, 'color': const Color(0xFF2196F3), 'method': 'acleda'},
    {'name': l.wingMoney,  'icon': Icons.phone_android,          'color': const Color(0xFFFF6B35), 'method': 'wing'},
    {'name': l.canadiaBank,'icon': Icons.credit_card,            'color': const Color(0xFF9C27B0), 'method': 'bank_transfer'},
  ];

  String _bankMethod(AppLocalizations l) =>
      (_banksFor(l).firstWhere((b) => b['name'] == _bank,
              orElse: () => _banksFor(l).first)['method'] as String?) ??
      'bank_transfer';

  @override
  void dispose() {
    _payoutAccNumCtrl.dispose();
    _payoutAccNameCtrl.dispose();
    super.dispose();
  }

  void _openBankSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.appSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        top: false,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: ctx.appCardBg, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(AppLocalizations.of(context).selectBank, style: TextStyle(
                  color: ctx.appTextPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
          Divider(height: 1, color: ctx.appCardBg),
          ..._banksFor(AppLocalizations.of(context)).map((b) {
            final name = b['name'] as String;
            final isSel = name == _bank;
            return InkWell(
              onTap: () { setState(() => _bank = name); Navigator.pop(ctx); },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: isSel
                          ? (b['color'] as Color).withValues(alpha: 0.12)
                          : ctx.appCardBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(b['icon'] as IconData,
                        color: isSel ? b['color'] as Color : Colors.grey, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(name, style: TextStyle(
                      color: ctx.appTextPrimary, fontWeight: FontWeight.w600, fontSize: 14))),
                  if (isSel) Icon(Icons.check_circle_rounded, color: b['color'] as Color, size: 20),
                ]),
              ),
            );
          }),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadBalance(), _loadTransactions(reset: true)]);
  }

  Future<void> _loadBalance() async {
    setState(() { _balanceLoading = true; _balanceError = null; });
    try {
      final w = await ApiService.getWallet();
      if (!mounted) return;
      setState(() { _wallet = w; _balanceLoading = false; });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() { _balanceError = e.message; _balanceLoading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _balanceError = e.toString(); _balanceLoading = false; });
    }
  }

  Future<void> _loadTransactions({bool reset = false}) async {
    if (_txLoading || _txLoadingMore) return;
    if (reset) {
      setState(() { _txLoading = true; _txError = null; _currentPage = 1; });
    } else {
      if (_currentPage >= _lastPage) return;
      setState(() { _txLoadingMore = true; });
    }
    try {
      final page   = reset ? 1 : _currentPage + 1;
      final result = await ApiService.getWalletTransactions(page: page);
      if (!mounted) return;
      setState(() {
        if (reset) _transactions.clear();
        _transactions.addAll(result.transactions);
        _currentPage   = result.currentPage;
        _lastPage      = result.lastPage;
        _total         = result.total;
        _txLoading     = false;
        _txLoadingMore = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() { _txError = e.message; _txLoading = false; _txLoadingMore = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _txError = e.toString(); _txLoading = false; _txLoadingMore = false; });
    }
  }

  // ── Computed stats from loaded transactions ───────────────────────────────────
  int get _tripEarnings => _transactions
      .where((t) => t.type == 'trip_earning')
      .fold<int>(0, (s, t) => s + t.amount);

  int get _bonuses => _transactions
      .where((t) => t.type == 'bonus')
      .fold<int>(0, (s, t) => s + t.amount);

  int get _platformFees => _transactions
      .where((t) => t.type == 'platform_commission')
      .fold<int>(0, (s, t) => s + t.amount);

  int get _topUps => _transactions
      .where((t) => t.type == 'top_up')
      .fold<int>(0, (s, t) => s + t.amount);

  // Approximate KHR → USD rate, same as used elsewhere in the app (e.g.
  // coupon discount conversion in car_rental_screen.dart).
  static const _khrPerUsd = 4100;

  Future<void> _confirmWithdraw() async {
    final balance = _wallet?.balance ?? 0;
    final canWithdraw   = _wallet?.canWithdraw ?? true;
    final minWithdrawal = _wallet?.minWithdrawalKhr ?? 0;
    final hasPending    = _wallet?.hasPendingWithdrawal ?? false;
    if (balance == 0 || _withdrawing || !canWithdraw || hasPending) return;
    if (minWithdrawal > 0 && balance < minWithdrawal) return;
    final usd = balance / _khrPerUsd;
    String? fieldError;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(AppLocalizations.of(context).confirmWithdrawal,
              style: TextStyle(fontWeight: FontWeight.w800)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(AppLocalizations.of(context).drvWithdrawConfirm(_bank),
                  style: TextStyle(color: context.appTextSecondary, fontSize: 13)),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.accentOrange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(children: [
                  Text(AppTheme.khr(balance),
                      style: const TextStyle(
                          color: AppTheme.accentOrange, fontWeight: FontWeight.w800, fontSize: 20)),
                  const SizedBox(height: 2),
                  Text('≈ \$${usd.toStringAsFixed(2)} USD',
                      style: TextStyle(color: context.appTextSecondary, fontSize: 13)),
                ]),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _payoutAccNumCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).accountNumber,
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _payoutAccNameCtrl,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).accountHolderName,
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              if (fieldError != null) ...[
                const SizedBox(height: 8),
                Text(fieldError!, style: const TextStyle(color: AppTheme.danger, fontSize: 12)),
              ],
            ]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(AppLocalizations.of(context).no),
            ),
            ElevatedButton(
              onPressed: () {
                if (_payoutAccNumCtrl.text.trim().isEmpty || _payoutAccNameCtrl.text.trim().isEmpty) {
                  setDialogState(() => fieldError = AppLocalizations.of(context).pleaseEnterYourAccountNumber);
                  return;
                }
                Navigator.pop(ctx, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(AppLocalizations.of(context).yesWithdraw),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    await _withdraw();
  }

  Future<void> _withdraw() async {
    final balance = _wallet?.balance ?? 0;
    if (balance == 0 || _withdrawing) return;
    setState(() => _withdrawing = true);
    try {
      // Goes into Driver Payouts, pending admin approval — not an instant
      // wallet debit.
      await ApiService.requestWithdrawal(
        amountKhr:     balance,
        paymentMethod: _bankMethod(AppLocalizations.of(context)),
        accountNumber: _payoutAccNumCtrl.text.trim(),
        accountName:   _payoutAccNameCtrl.text.trim(),
        bankName:      _bank,
      );
      if (!mounted) return;
      setState(() => _withdrawing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context).drvWithdrawSubmitted(AppTheme.khr(balance))),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      // Refresh full data to reflect any pending-payout state from backend
      _loadAll();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _withdrawing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message),
        backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _withdrawing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString()),
        backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final balance = _wallet?.balance ?? 0;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadAll,
        color: AppTheme.accentOrange,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(AppLocalizations.of(context).earnings,
                  style: TextStyle(
                      color: context.appTextPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800)),
              Spacer(),
              IconButton(
                icon: Icon(Icons.refresh,
                    color: context.appTextSecondary, size: 20),
                onPressed: _loadAll,
                tooltip: AppLocalizations.of(context).refresh,
              ),
            ]),
            const SizedBox(height: 16),

            // ── Balance card ──────────────────────────────────────────────
            GradientCard(
              colors: const [Color(0xFF00C48C), Color(0xFF00A37A)],
              child: _balanceLoading
                  ? const SizedBox(
                      height: 80,
                      child: Center(
                          child: CircularProgressIndicator(color: Colors.white)))
                  : _balanceError != null
                      ? Text(_balanceError!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13))
                      : Column(children: [
                          Text(AppLocalizations.of(context).availableBalance,
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 13)),
                          const SizedBox(height: 8),
                          Text(AppTheme.khr(balance),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 34,
                                  fontWeight: FontWeight.w800)),
                          Text(AppTheme.usd(balance / 4000),
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13)),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () async {
                              await Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const WalletScreen()));
                              widget.onWalletChanged?.call();
                              _loadAll();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(Icons.add_circle_outline, color: Colors.white, size: 16),
                                SizedBox(width: 6),
                                Text(AppLocalizations.of(context).topUp, style: TextStyle(
                                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                              ]),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _EarningItem(
                                  label: AppLocalizations.of(context).trips,
                                  value: AppTheme.khr(_tripEarnings),
                                  valueColor: Colors.white,
                                  labelColor: Colors.white70),
                              _EarningItem(
                                  label: AppLocalizations.of(context).bonuses,
                                  value: AppTheme.khr(_bonuses),
                                  valueColor: Colors.white,
                                  labelColor: Colors.white70),
                              _EarningItem(
                                  label: AppLocalizations.of(context).fees,
                                  value: '-${AppTheme.khr(_platformFees)}',
                                  valueColor: Colors.white,
                                  labelColor: Colors.white70),
                              if (_topUps > 0)
                                _EarningItem(
                                    label: AppLocalizations.of(context).topUps,
                                    value: AppTheme.khr(_topUps),
                                    valueColor: Colors.white,
                                    labelColor: Colors.white70),
                            ],
                          ),
                        ]),
            ),
            SizedBox(height: 20),

            // ── Transaction history ───────────────────────────────────────
            Row(children: [
              Expanded(child: SectionHeader(
                  title: _showAllTx ? AppLocalizations.of(context).transactionHistory : AppLocalizations.of(context).drvTodaysTransactions)),
              if (_showAllTx && _total > 0)
                Text(AppLocalizations.of(context).drvTotalCount(_total),
                    style: TextStyle(
                        color: context.appTextSecondary, fontSize: 12)),
              if (!_showAllTx)
                TextButton(
                  onPressed: () => setState(() => _showAllTx = true),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero,
                      minimumSize: Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  child: Text(AppLocalizations.of(context).showAll,
                      style: TextStyle(color: AppTheme.accentOrange, fontWeight: FontWeight.w600)),
                ),
            ]),
            SizedBox(height: 14),

            if (_txLoading)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(
                      color: AppTheme.accentOrange),
                ),
              )
            else if (_txError != null)
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: context.appSurface,
                    borderRadius: BorderRadius.circular(14)),
                child: Column(children: [
                  Text(_txError!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: context.appTextSecondary, fontSize: 13)),
                  SizedBox(height: 8),
                  TextButton(
                    onPressed: () => _loadTransactions(reset: true),
                    child: Text(AppLocalizations.of(context).retry,
                        style: TextStyle(color: AppTheme.accentOrange)),
                  ),
                ]),
              )
            else if (_visibleTx.isEmpty)
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                    color: context.appSurface,
                    borderRadius: BorderRadius.circular(14)),
                child: Center(
                  child: Text(_showAllTx ? AppLocalizations.of(context).noTransactionsYet : AppLocalizations.of(context).noTransactionsToday,
                      style: TextStyle(color: context.appTextSecondary)),
                ),
              )
            else ...[
              ..._visibleTx.map((t) => _TxnTile(txn: t)),
              if (_showAllTx && _currentPage < _lastPage)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: _txLoadingMore
                        ? CircularProgressIndicator(
                            color: AppTheme.accentOrange)
                        : TextButton.icon(
                            onPressed: () =>
                                _loadTransactions(reset: false),
                            icon: Icon(Icons.expand_more,
                                color: AppTheme.accentOrange),
                            label: Text(AppLocalizations.of(context).loadMore,
                                style: TextStyle(
                                    color: AppTheme.accentOrange)),
                          ),
                  ),
                ),
            ],

            SizedBox(height: 20),

            // ── Instant withdrawal ────────────────────────────────────────
            SectionHeader(title: AppLocalizations.of(context).instantWithdrawal),
            SizedBox(height: 12),
            if (_wallet?.hasPendingWithdrawal ?? false) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.schedule_rounded, color: AppTheme.warning, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(
                      AppLocalizations.of(context).youHaveAWithdrawalRequest,
                      style: TextStyle(color: context.appTextPrimary, fontSize: 12, fontWeight: FontWeight.w600))),
                ]),
              ),
              const SizedBox(height: 12),
            ],
            Builder(builder: (context) {
              final selected = _banksFor(AppLocalizations.of(context))
                  .firstWhere((b) => b['name'] == _bank);
              return GestureDetector(
                onTap: () => _openBankSheet(context),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: context.appSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: context.appCardBg),
                  ),
                  child: Row(children: [
                    Icon(selected['icon'] as IconData,
                        color: selected['color'] as Color, size: 22),
                    SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(AppLocalizations.of(context).bank, style: TextStyle(
                          color: context.appTextSecondary, fontSize: 10, fontWeight: FontWeight.w500)),
                      SizedBox(height: 2),
                      Text(selected['name'] as String,
                          style: TextStyle(
                              color: context.appTextPrimary,
                              fontWeight: FontWeight.w700, fontSize: 14)),
                    ])),
                    Icon(Icons.keyboard_arrow_down, color: context.appTextSecondary, size: 22),
                  ]),
                ),
              );
            }),
            const SizedBox(height: 16),
            Builder(builder: (context) {
              final canWithdraw   = _wallet?.canWithdraw ?? true;
              final minWithdrawal = _wallet?.minWithdrawalKhr ?? 0;
              final hasPending    = _wallet?.hasPendingWithdrawal ?? false;
              final belowMin      = minWithdrawal > 0 && balance < minWithdrawal;
              final disabled = balance == 0 || _withdrawing || !canWithdraw || hasPending || belowMin;

              String label;
              if (hasPending) {
                label = AppLocalizations.of(context).withdrawalPendingApproval;
              } else if (balance == 0) {
                label = AppLocalizations.of(context).noBalanceToWithdraw;
              } else if (belowMin) {
                label = AppLocalizations.of(context).drvMinWithdrawal(AppTheme.khr(minWithdrawal));
              } else if (!canWithdraw) {
                label = AppLocalizations.of(context).withdrawalsUnavailable;
              } else {
                label = AppLocalizations.of(context).drvWithdrawTo(AppTheme.khr(balance), _bank);
              }

              return SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: disabled ? null : _confirmWithdraw,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentOrange,
                    disabledBackgroundColor:
                        AppTheme.accentOrange.withValues(alpha: 0.4),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _withdrawing
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : Text(label,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 15)),
                ),
              );
            }),
            SizedBox(height: 8),
            Center(
              child: Text(AppLocalizations.of(context).reviewedByAdminBeforeFunds,
                  style: TextStyle(
                      color: context.appTextSecondary, fontSize: 12)),
            ),
          ]),
        ),
      ),
    );
  }
}

class _EarningItem extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  final Color? labelColor;

  const _EarningItem(
      {required this.label, required this.value,
       this.valueColor, this.labelColor});

  @override
  Widget build(BuildContext context) => Column(children: [
        Text(value,
            style: TextStyle(
                color: valueColor ?? context.appTextPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 12)),
        Text(label,
            style: TextStyle(
                color: labelColor ?? context.appTextSecondary, fontSize: 10)),
      ]);
}

class _TxnTile extends StatelessWidget {
  final WalletTransactionModel txn;

  const _TxnTile({required this.txn});

  IconData get _icon {
    switch (txn.type) {
      case 'trip_earning':        return Icons.electric_rickshaw;
      case 'platform_commission': return Icons.percent;
      case 'bonus':               return Icons.emoji_events;
      case 'top_up':              return Icons.add_circle_outline;
      case 'withdrawal':          return Icons.account_balance_outlined;
      case 'refund':              return Icons.undo;
      default:                    return Icons.swap_horiz;
    }
  }

  Color get _statusColor {
    switch (txn.status) {
      case 'completed':  return AppTheme.success;
      case 'pending':    return AppTheme.warning;
      case 'processing': return AppTheme.accentOrange;
      case 'failed':
      case 'rejected':
      case 'cancelled':  return AppTheme.danger;
      default:            return Colors.grey;
    }
  }

  IconData get _statusIcon {
    switch (txn.status) {
      case 'completed':  return Icons.check_circle_rounded;
      case 'pending':     return Icons.schedule_rounded;
      case 'processing': return Icons.autorenew_rounded;
      case 'failed':
      case 'rejected':
      case 'cancelled':  return Icons.cancel_rounded;
      default:            return Icons.circle;
    }
  }

  String get _statusLabel =>
      txn.status.isEmpty ? '' : txn.status[0].toUpperCase() + txn.status.substring(1);

  @override
  Widget build(BuildContext context) {
    final isCredit    = txn.isCredit;
    final itemColor   = isCredit ? AppTheme.success : AppTheme.accentOrange;
    final statusColor = _statusColor;
    final isPending    = txn.status == 'pending' || txn.status == 'processing';
    final amountStr = isCredit
        ? '+${AppTheme.khr(txn.amount)}'
        : '-${AppTheme.khr(txn.amount)}';

    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border(left: BorderSide(
              color: isPending ? statusColor : Colors.transparent, width: 3))),
      child: Row(children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: itemColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(_icon, color: itemColor, size: 18),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(txn.displayLabel,
                    style: TextStyle(
                        color: context.appTextPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                SizedBox(height: 3),
                Row(children: [
                  Text(txn.formattedDate,
                      style: TextStyle(
                          color: context.appTextSecondary,
                          fontSize: 11)),
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(_statusIcon, color: statusColor, size: 10),
                      const SizedBox(width: 3),
                      Text(_statusLabel,
                          style: TextStyle(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ]),
              ]),
        ),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(amountStr,
              style: TextStyle(
                  color: itemColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 13)),
          Text(AppLocalizations.of(context).drvBalanceShort(AppTheme.khr(txn.balanceAfter)),
              style: TextStyle(
                  color: context.appTextSecondary, fontSize: 10)),
        ]),
      ]),
    );
  }
}

// ─── Driver profile ───────────────────────────────────────────────────────────
class _DriverProfile extends StatefulWidget {
  const _DriverProfile({required this.onGoToEarnings, this.onWalletChanged});
  final VoidCallback onGoToEarnings;
  final VoidCallback? onWalletChanged;

  @override
  State<_DriverProfile> createState() => _DriverProfileState();
}

class _DriverProfileState extends State<_DriverProfile> {
  String _name         = '';
  String _phone        = '';
  String _vehicleName  = '';
  String _vehiclePlate = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final results = await Future.wait([
        ApiService.getMe(),
        ApiService.getVehicles(),
      ]);
      final user     = results[0] as UserModel;
      final vehicles = results[1] as List<VehicleModel>;
      if (!mounted) return;
      setState(() {
        _name  = user.name;
        _phone = user.phone;
        if (vehicles.isNotEmpty) {
          _vehicleName  = vehicles.first.displayName;
          _vehiclePlate = vehicles.first.licensePlate;
        }
        _loading = false;
      });
    } catch (_) {
      final saved = await ApiService.getSavedUser();
      if (!mounted) return;
      setState(() {
        _name  = saved?.name  ?? '';
        _phone = saved?.phone ?? '';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(children: [
          SizedBox(height: 20),
          Stack(children: [
            CircleAvatar(radius: 48, backgroundColor: AppTheme.accentOrange.withValues(alpha: 0.2),
              child: Icon(Icons.person, color: AppTheme.accentOrange, size: 48)),
            Positioned(bottom: 0, right: 0,
              child: Container(padding: EdgeInsets.all(4), decoration: BoxDecoration(color: AppTheme.success, shape: BoxShape.circle),
                child: Icon(Icons.check, color: Colors.white, size: 14))),
          ]),
          SizedBox(height: 12),
          _loading
              ? SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: AppTheme.accentOrange, strokeWidth: 2))
              : Text(_name, style: TextStyle(color: context.appTextPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
          SizedBox(height: 4),
          Text(_phone, style: TextStyle(color: context.appTextSecondary, fontSize: 13)),
          SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.star, color: AppTheme.gold, size: 18),
            SizedBox(width: 4),
            Text('4.87', style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w600)),
            SizedBox(width: 4),
            Text(AppLocalizations.of(context).n1204Trips2, style: TextStyle(color: context.appTextSecondary, fontSize: 13)),
          ]),
          SizedBox(height: 20),
          if (_vehicleName.isNotEmpty)
            Container(padding: EdgeInsets.all(16),
              decoration: BoxDecoration(color: context.appSurface, borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                Icon(Icons.directions_car, color: AppTheme.accentOrange, size: 36),
                SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_vehicleName,  style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w600)),
                  Text(_vehiclePlate, style: TextStyle(color: context.appTextSecondary, fontSize: 13)),
                ])),
                StatusBadge(label: AppLocalizations.of(context).verified, color: AppTheme.success),
              ]),
            ),
          const SizedBox(height: 20),
          Builder(builder: (context) {
            final l = AppLocalizations.of(context);
            return Column(children: [
              ...([
                (l.chat,            Icons.chat_bubble_outline,      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen(isDriver: true))), false),
                (l.bankPayouts,     Icons.account_balance_outlined, () => widget.onGoToEarnings(), false),
                (l.myEarnings,     Icons.account_balance_wallet_outlined, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverEarningsScreen())), false),
                (l.topUpWallet,   Icons.add_circle_outline,       () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()));
                  widget.onWalletChanged?.call();
                }, false),
                (l.helmetCheck,    Icons.security_rounded,         () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelmetCheckScreen())), false),
                (l.safetySettings,  Icons.shield_outlined,          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SafetyScreen())),  false),
                (l.documents,       Icons.description_outlined,     () {}, false),
                (l.tripHistory,     Icons.history_outlined,         () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverHistoryScreen())), false),
                (l.deleteAccountLabel, Icons.delete_forever_outlined, () => confirmAndDeleteAccount(context), true),
                (l.signOut, Icons.logout, () async {
                  await ApiService.logout();
                  if (!context.mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                    (_) => false,
                  );
                }, true),
              ].map((item) => Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Material(
                  color: context.appSurface,
                  borderRadius: BorderRadius.circular(14),
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    leading: Icon(item.$2, color: item.$4 ? AppTheme.danger : context.appTextSecondary, size: 20),
                    title: Text(item.$1, style: TextStyle(color: item.$4 ? AppTheme.danger : context.appTextPrimary, fontSize: 14)),
                    trailing: Icon(Icons.chevron_right, color: context.appTextSecondary, size: 18),
                    onTap: item.$3,
                  ),
                ),
              ))),
              // ── Dark mode ───────────────────────────────────────────────
              Consumer<ThemeProvider>(
                builder: (context, tp, _) => Container(
                  margin: EdgeInsets.only(bottom: 10),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                      color: context.appSurface,
                      borderRadius: BorderRadius.circular(14)),
                  child: Row(children: [
                    Icon(Icons.dark_mode_outlined,
                        color: context.appTextSecondary, size: 20),
                    SizedBox(width: 14),
                    Text(AppLocalizations.of(context).darkMode,
                        style: TextStyle(color: context.appTextPrimary,
                            fontSize: 14, fontWeight: FontWeight.w500)),
                    Spacer(),
                    Switch(
                      value: tp.isDark,
                      activeColor: AppTheme.accent,
                      onChanged: tp.setDark,
                    ),
                  ]),
                ),
              ),
              // ── Language ────────────────────────────────────────────────
              Container(
                margin: EdgeInsets.only(bottom: 10),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: context.appSurface, borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  Icon(Icons.language, color: context.appTextSecondary, size: 20),
                  SizedBox(width: 14),
                  Text(l.language, style: TextStyle(color: context.appTextPrimary, fontSize: 14)),
                  const Spacer(),
                  const LanguagePickerButton(),
                ]),
              ),
            ]);
          }),
        ]),
      ),
    );
  }
}

// ── Moving flag chip (driver card) ────────────────────────────────────────────

class _MovingFlag extends StatelessWidget {
  final String label;
  final Color color;
  const _MovingFlag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label, style: TextStyle(
          color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
