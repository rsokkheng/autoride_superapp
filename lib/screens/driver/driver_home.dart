import 'dart:async';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../l10n/app_localizations.dart';
import '../../services/api_service.dart';
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
import '../auth/login_screen.dart';
import '../passenger/passenger_home.dart';
import '../passenger/wallet_screen.dart';
import '../shared/chat_screen.dart';
import '../passenger/safety_screen.dart';
import 'driver_active_trip_screen.dart';
import 'driver_delivery_active_screen.dart';
import 'driver_missions_screen.dart';
import 'driver_history_screen.dart';
import 'driver_earnings_screen.dart';
import 'helmet_check_screen.dart';

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
          const Expanded(child: Text('Top Up Required', style: TextStyle(fontWeight: FontWeight.w800))),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            message ??
                'Your wallet balance is too low to go online. Please top up at least ${AppTheme.khr(_minBalanceKhr)} to continue.',
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
              child: Text('Short by ${AppTheme.khr(shortfall)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.danger, fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ],
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
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
            child: const Text('Top Up Now'),
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
      ),
      _DriverEarnings(onWalletChanged: _loadGoOnlineGate),
      const DriverMissionsScreen(),
      const ChatScreen(isDriver: true),
      _DriverProfile(onGoToEarnings: () => setState(() => _tab = 1),
          onWalletChanged: _loadGoOnlineGate),
    ];

    return Scaffold(
      body: pages[_tab],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: context.appSurface,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20)],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: [
                Expanded(child: _NavItem(icon: Icons.dashboard_outlined,           label: 'Home',     index: 0, current: _tab, onTap: (i) => setState(() => _tab = i))),
                Expanded(child: _NavItem(icon: Icons.account_balance_wallet_outlined, label: AppLocalizations.of(context).earnings, index: 1, current: _tab, onTap: (i) => setState(() => _tab = i))),
                Expanded(child: _NavItem(icon: Icons.rocket_launch_outlined,       label: 'Missions', index: 2, current: _tab, onTap: (i) => setState(() => _tab = i))),
                Expanded(child: _NavItem(icon: Icons.chat_bubble_outline,          label: AppLocalizations.of(context).chat,     index: 3, current: _tab, onTap: (i) => setState(() => _tab = i))),
                Expanded(child: _NavItem(icon: Icons.person_outline,               label: AppLocalizations.of(context).profile,  index: 4, current: _tab, onTap: (i) => setState(() => _tab = i))),
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
          color: selected ? AppTheme.accentOrange.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: selected ? AppTheme.accentOrange : context.appTextSecondary, size: 22),
          SizedBox(height: 3),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? AppTheme.accentOrange : context.appTextSecondary,
                fontSize: 10, fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              )),
        ]),
      ),
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
  });

  bool get isOnline => driverStatus != DriverStatus.offline;
  bool get isBusy   => driverStatus == DriverStatus.busy;

  @override
  State<_DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<_DriverDashboard>
    with WidgetsBindingObserver {
  DriverStatsModel? _stats;
  RideModel?     _pendingRide;
  DeliveryModel? _pendingDelivery;
  Map<String, dynamic>? _pendingRental;
  RideModel?     _activeRide;
  DeliveryModel? _activeDelivery;
  SurgeInfo?     _surgeInfo;
  String?        _locationZone;
  Timer? _pollTimer;
  Timer? _surgeTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
    _loadSurge();
    if (widget.driverStatus == DriverStatus.online) {
      _pollTimer  = Timer.periodic(const Duration(seconds: 5),  (_) => _pollRequests());
      _surgeTimer = Timer.periodic(const Duration(minutes: 2),  (_) => _loadSurge());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pollTimer?.cancel();  _pollTimer  = null;
      _surgeTimer?.cancel(); _surgeTimer = null;
    } else if (state == AppLifecycleState.resumed) {
      if (widget.driverStatus == DriverStatus.online) {
        _loadData();
        _loadSurge();
        _pollTimer?.cancel();
        _pollTimer  = Timer.periodic(const Duration(seconds: 5),  (_) => _pollRequests());
        _surgeTimer = Timer.periodic(const Duration(minutes: 2),  (_) => _loadSurge());
      }
    }
  }

  @override
  void didUpdateWidget(_DriverDashboard old) {
    super.didUpdateWidget(old);
    if (old.driverStatus != widget.driverStatus) {
      if (widget.driverStatus == DriverStatus.busy) {
        _pollTimer?.cancel();
        _surgeTimer?.cancel();
      } else if (widget.driverStatus == DriverStatus.online) {
        _pollTimer?.cancel();
        _surgeTimer?.cancel();
        _pollTimer  = Timer.periodic(const Duration(seconds: 5),  (_) => _pollRequests());
        _surgeTimer = Timer.periodic(const Duration(minutes: 2),  (_) => _loadSurge());
        _pollRequests();
        _loadSurge();
      } else {
        _pollTimer?.cancel();
        _surgeTimer?.cancel();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    _surgeTimer?.cancel();
    super.dispose();
  }

  String _surgeSubtitle(SurgeInfo info) {
    final parts = <String>[];
    if (!info.youAreInside && info.nearbyDistanceKm != null) {
      parts.add('${info.nearbyDistanceKm!.toStringAsFixed(1)} km away');
    }
    if (info.endsAt != null) {
      final diff = info.endsAt!.difference(DateTime.now());
      if (diff.inMinutes > 0) {
        parts.add(diff.inHours >= 1
            ? 'ends in ${diff.inHours}h ${diff.inMinutes % 60}m'
            : 'ends in ${diff.inMinutes} min');
      }
    }
    if (parts.isNotEmpty) return parts.join(' · ');
    return info.youAreInside
        ? (info.message ?? 'High demand in your area')
        : 'Head there for higher earnings';
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
    try {
      final results = await Future.wait([
        ApiService.getDriverStats(),
        ApiService.getAvailableRides(),
        ApiService.getAvailableDeliveries(),
        ApiService.getActiveRide(),
        ApiService.getActiveDelivery(),
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

      setState(() {
        _stats = results[0] as DriverStatsModel;
        final rides = results[1] as List<RideModel>;
        _pendingRide = rides.isNotEmpty ? rides.first : null;
        final deliveries = results[2] as List<DeliveryModel>;
        _pendingDelivery = deliveries.isNotEmpty ? deliveries.first : null;
        _activeRide     = activeRide;
        _activeDelivery = activeDelivery;
      });
      if ((activeRide != null || activeDelivery != null) && !widget.isBusy) {
        widget.onBusy();
      }
    } catch (_) {}

    // Fetched separately so a failure here (e.g. endpoint not yet deployed)
    // doesn't take down rides/deliveries loading above.
    try {
      final rentals = await ApiService.getAvailableRentals();
      if (!mounted) return;
      setState(() => _pendingRental = rentals.isNotEmpty ? rentals.first : null);
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
    if (_pendingRide == null) {
      try {
        final rides = await ApiService.getAvailableRides();
        if (!mounted) return;
        if (rides.isNotEmpty) setState(() => _pendingRide = rides.first);
      } catch (e) {
        debugPrint('[Driver] getAvailableRides error: $e');
      }
    }
    if (_pendingDelivery == null) {
      try {
        final deliveries = await ApiService.getAvailableDeliveries();
        if (!mounted) return;
        if (deliveries.isNotEmpty) setState(() => _pendingDelivery = deliveries.first);
      } catch (e) {
        debugPrint('[Driver] getAvailableDeliveries error: $e');
      }
    }
    if (_pendingRental == null) {
      try {
        final rentals = await ApiService.getAvailableRentals();
        if (!mounted) return;
        if (rentals.isNotEmpty) setState(() => _pendingRental = rentals.first);
      } catch (e) {
        debugPrint('[Driver] getAvailableRentals error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Driver Dashboard', style: TextStyle(color: context.appTextPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
                Row(children: [
                  Icon(Icons.star, color: AppTheme.gold, size: 16),
                  SizedBox(width: 4),
                  Text('4.87', style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w600)),
                  Text(' · 1,204 trips', style: TextStyle(color: context.appTextSecondary, fontSize: 13)),
                ]),
              ]),
              Spacer(),
              Column(children: [
                Switch(
                  value: widget.isOnline,
                  onChanged: widget.isBusy ? null : widget.onToggle,
                  activeThumbColor: widget.isBusy ? AppTheme.warning : AppTheme.success,
                  activeTrackColor: (widget.isBusy ? AppTheme.warning : AppTheme.success).withValues(alpha: 0.4),
                ),
                Text(
                  widget.isBusy ? 'Busy' : widget.isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    color: widget.isBusy ? AppTheme.warning : widget.isOnline ? AppTheme.success : context.appTextSecondary,
                    fontSize: 11,
                  ),
                ),
              ]),
            ]),
            const SizedBox(height: 16),

            // Surge zone banner — red when inside, amber when nearby
            if (_surgeInfo != null)
              Builder(builder: (_) {
                final inside = _surgeInfo!.youAreInside;
                final color  = inside ? AppTheme.danger : AppTheme.warning;
                final icon   = inside ? Icons.local_fire_department : Icons.directions_outlined;
                final title  = inside
                    ? '🔥 ${_surgeInfo!.multiplier.toStringAsFixed(1)}× Surge Zone — You\'re Inside!'
                    : '📍 ${_surgeInfo!.multiplier.toStringAsFixed(1)}× Surge Nearby — ${_surgeInfo!.zone ?? 'Zone'}';
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

            // Status card
            GradientCard(
              colors: widget.isBusy
                  ? [Color(0xFFE65100), Color(0xFFBF360C)]
                  : widget.isOnline
                      ? [Color(0xFF00C48C), Color(0xFF00A37A)]
                      : [context.appSurface, context.appCardBg],
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  StatusBadge(
                    label: widget.isBusy ? '🟡 Busy — On a Trip' : widget.isOnline ? '🟢 Online — Ready' : '⭕ Offline',
                    color: widget.isBusy ? Colors.white : widget.isOnline ? Colors.white : context.appTextSecondary,
                  ),
                  SizedBox(height: 8),
                  Text(
                    widget.isBusy ? 'Complete your trip to receive new requests' : widget.isOnline ? 'Waiting for requests...' : 'Toggle online to accept rides',
                    style: TextStyle(
                      color: (widget.isBusy || widget.isOnline) ? Colors.white : context.appTextPrimary,
                      fontSize: 14, fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_locationZone != null) ...[
                    SizedBox(height: 6),
                    Row(children: [
                      Icon(Icons.location_on_outlined,
                          color: (widget.isBusy || widget.isOnline)
                              ? Colors.white70
                              : context.appTextSecondary,
                          size: 13),
                      SizedBox(width: 3),
                      Flexible(child: Text(
                        _locationZone!,
                        style: TextStyle(
                          color: (widget.isBusy || widget.isOnline)
                              ? Colors.white70
                              : context.appTextSecondary,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      )),
                    ]),
                  ],
                ])),
                Icon(Icons.electric_rickshaw,
                    color: widget.isBusy ? Colors.white : widget.isOnline ? Colors.white : context.appTextSecondary,
                    size: 50),
              ]),
            ),
            const SizedBox(height: 16),

            // Service modes (multi-select, at least one active)
            const SectionHeader(title: 'Service Modes'),
            const SizedBox(height: 10),
            Row(children: [
              _ModeChip(icon: Icons.electric_rickshaw,  label: 'Ride',     active: widget.modeRide,     color: AppTheme.accent,         onTap: () => widget.onModeRide(!widget.modeRide)),
              const SizedBox(width: 8),
              _ModeChip(icon: Icons.delivery_dining_outlined, label: 'Delivery', active: widget.modeDelivery, color: AppTheme.accentOrange,    onTap: () => widget.onModeDelivery(!widget.modeDelivery)),
              const SizedBox(width: 8),
              _ModeChip(icon: Icons.car_rental_outlined,      label: 'Rental',   active: widget.modeRental,   color: const Color(0xFF9C27B0), onTap: () => widget.onModeRental(!widget.modeRental)),
            ]),
            const SizedBox(height: 20),

            // Today's stats
            const SectionHeader(title: "Today's Performance"),
            const SizedBox(height: 14),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: [
                _StatCard(label: 'Accepted',       value: '${_stats?.acceptedRides  ?? 0}',                                     icon: Icons.check_circle_outline, color: AppTheme.accent),
                _StatCard(label: 'Completed',      value: '${_stats?.completedRides ?? 0}',                                     icon: Icons.electric_rickshaw,       color: AppTheme.accentOrange),
                _StatCard(label: 'Hours Online',   value: _stats == null ? '--' : '${_stats!.hoursOnline.toStringAsFixed(1)}h', icon: Icons.access_time,          color: const Color(0xFF9C27B0)),
                _StatCard(label: 'Acceptance Rate',value: _stats == null ? '--' : '${_stats!.acceptanceRate.toStringAsFixed(0)}%', icon: Icons.thumb_up_outlined, color: AppTheme.success),
              ],
            ),
            SizedBox(height: 20),

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
                              ? (_activeDelivery!.isMoving ? 'Moving In Progress' : 'Delivery In Progress')
                              : 'Ride In Progress',
                          style: TextStyle(color: AppTheme.warning, fontWeight: FontWeight.w700, fontSize: 15)),
                        SizedBox(height: 2),
                        Text('Tap to open the map and see where to go.',
                            style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
                      ])),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.warning,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('Resume',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 14),
              ] else ...[
                if (widget.modeRide) ...[
                  if (_pendingRide != null) ...[
                    const SectionHeader(title: 'Incoming Ride Request'),
                    const SizedBox(height: 14),
                    _RideRequestCard(
                      ride: _pendingRide!,
                      onDeclined: () => setState(() => _pendingRide = null),
                      onAccept: (RideModel ride) async {
                        setState(() { _pendingRide = null; _activeRide = ride; });
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
                      icon: Icons.electric_rickshaw,
                      color: AppTheme.accent,
                      title: 'Looking for Ride Requests',
                      subtitle: 'You\'ll be notified when a passenger nearby needs a ride.',
                    ),
                  ],
                  const SizedBox(height: 14),
                ],
                if (widget.modeDelivery) ...[
                  if (_pendingDelivery != null) ...[
                    const SectionHeader(title: 'Incoming Delivery Request'),
                    const SizedBox(height: 14),
                    _DeliveryRequestCard(
                      delivery: _pendingDelivery!,
                      onDeclined: () => setState(() => _pendingDelivery = null),
                      onAccept: (DeliveryModel delivery) async {
                        setState(() { _pendingDelivery = null; _activeDelivery = delivery; });
                        final user = await ApiService.getSavedUser();
                        final driverIdStr = user?.id.toString() ?? 'unknown';
                        if (!mounted) return;
                        await Navigator.push(context, MaterialPageRoute(
                          builder: (_) => DriverDeliveryActiveScreen(
                            delivery: delivery,
                            driverIdStr: driverIdStr,
                          ),
                        ));
                        if (mounted) setState(() => _activeDelivery = null);
                      },
                    ),
                  ] else ...[
                    _ModeEmptyCard(
                      icon: Icons.delivery_dining_outlined,
                      color: AppTheme.accentOrange,
                      title: 'Delivery Mode Active',
                      subtitle: 'Waiting for delivery orders in your area.',
                    ),
                  ],
                  const SizedBox(height: 14),
                ],
                if (widget.modeRental) ...[
                  if (_pendingRental != null) ...[
                    const SectionHeader(title: 'Incoming Rental Request'),
                    const SizedBox(height: 14),
                    _RentalRequestCard(
                      rental: _pendingRental!,
                      onDeclined: () => setState(() => _pendingRental = null),
                      onAccept: (rental) async {
                        setState(() => _pendingRental = null);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Rental request accepted.'),
                          backgroundColor: AppTheme.success,
                          behavior: SnackBarBehavior.floating,
                        ));
                      },
                    ),
                  ] else ...[
                    _ModeEmptyCard(
                      icon: Icons.car_rental_outlined,
                      color: const Color(0xFF9C27B0),
                      title: 'Rental Mode Active',
                      subtitle: 'Your vehicle is listed for hourly rentals.',
                    ),
                  ],
                  const SizedBox(height: 14),
                ],
              ],
            ],

            // Share location card
            _DriverShareLocationCard(isOnline: widget.isOnline),
            const SizedBox(height: 20),

            // Peak hour bonus tracker
            Container(
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
                  Text('Peak Hour Bonus', style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
                  Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppTheme.warning.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                    child: Text('Active 6–9 PM', style: TextStyle(color: AppTheme.warning, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ]),
                SizedBox(height: 10),
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Extra \$0.50 per trip during peak hours', style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
                    SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: 0.6,
                        backgroundColor: context.appCardBg,
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.warning),
                        minHeight: 6,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text('3 of 5 peak-hour trips completed today', style: TextStyle(color: context.appTextSecondary, fontSize: 11)),
                  ])),
                  SizedBox(width: 14),
                  Column(children: [
                    Text('+\$1.50', style: TextStyle(color: AppTheme.warning, fontWeight: FontWeight.w900, fontSize: 20)),
                    Text('earned today', style: TextStyle(color: context.appTextSecondary, fontSize: 10)),
                  ]),
                ]),
              ]),
            ),
            SizedBox(height: 14),

            // 5-star streak rewards
            Container(
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
                  Text('5-Star Streak 🔥', style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w700)),
                  Text('4 consecutive 5-star ratings!', style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
                  SizedBox(height: 4),
                  Text('1 more 5-star = Earn \$5 bonus', style: TextStyle(color: AppTheme.gold, fontSize: 12, fontWeight: FontWeight.w600)),
                ])),
                Row(children: List.generate(5, (i) => Icon(
                  i < 4 ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: i < 4 ? AppTheme.gold : context.appTextSecondary, size: 18,
                ))),
              ]),
            ),
            SizedBox(height: 20),

            const SectionHeader(title: 'Recent Trips'),
            const SizedBox(height: 14),
            const _RecentRidesSection(),
          ],
        ),
      ),
    );
  }
}

// ─── Driver share location card ───────────────────────────────────────────────

class _DriverShareLocationCard extends StatefulWidget {
  final bool isOnline;
  const _DriverShareLocationCard({required this.isOnline});

  @override
  State<_DriverShareLocationCard> createState() => _DriverShareLocationCardState();
}

class _DriverShareLocationCardState extends State<_DriverShareLocationCard> {
  bool _sharing = false;

  Future<void> _shareLocation() async {
    setState(() => _sharing = true);
    try {
      // Get current GPS position (try last known first, fallback to full fix)
      Position? pos = await Geolocator.getLastKnownPosition();
      pos ??= await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      if (!mounted) return;

      final lat = pos.latitude;
      final lng = pos.longitude;
      final mapsUrl = 'https://maps.google.com/?q=$lat,$lng';
      final text    = 'My current location as an ROTEH driver:\n$mapsUrl';

      final box = context.findRenderObject() as RenderBox?;
      await Share.share(text,
          subject: 'My live location',
          sharePositionOrigin:
              box != null ? box.localToGlobal(Offset.zero) & box.size : null);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Could not get your location. Make sure GPS is on.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.success.withValues(alpha: 0.35)),
      ),
      child: Row(children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.success.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.share_location, color: AppTheme.success, size: 22),
        ),
        SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Share My Location', style: TextStyle(
              color: context.appTextPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
          SizedBox(height: 2),
          Text('Send your live GPS link to friends or family via Telegram, SMS, etc.',
              style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
        ])),
        const SizedBox(width: 10),
        SizedBox(
          height: 36,
          child: ElevatedButton(
            onPressed: _sharing ? null : _shareLocation,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              elevation: 0,
            ),
            child: _sharing
                ? const SizedBox(width: 14, height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Share', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          ),
        ),
      ]),
    );
  }
}

// ─── Service mode chip ────────────────────────────────────────────────────────
class _ModeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap; // toggles this mode; parent guards against all-off

  const _ModeChip({required this.icon, required this.label, required this.active, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.15) : context.appSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? color : context.appSurface),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: active ? color : context.appTextSecondary, size: 20),
          SizedBox(height: 4),
          Text(label, style: TextStyle(color: active ? color : context.appTextSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
      ),
    ),
  );
}

// ─── Mode empty/waiting card ──────────────────────────────────────────────────
class _ModeEmptyCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _ModeEmptyCard({
    required this.icon,
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
          child: Icon(icon, color: color, size: 28),
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
          Text('Waiting...', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      ]),
    );
  }
}

// ─── Stat card ────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(color: context.appSurface, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 20),
        Spacer(),
        Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w800)),
        Text(label, style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
      ]),
    );
  }
}

// ─── Ride request card with countdown ─────────────────────────────────────────
class _RideRequestCard extends StatefulWidget {
  final RideModel    ride;
  // Parent dashboard owns navigation so it stays mounted for the full trip.
  final Future<void> Function(RideModel) onAccept;
  final VoidCallback onDeclined;

  const _RideRequestCard({
    required this.ride,
    required this.onAccept,
    required this.onDeclined,
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
      setState(() => _acting = false);
    } catch (_) {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _decline() async {
    if (_acting) return;
    _timer?.cancel();
    setState(() => _acting = true);
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
    final passengerLabel = widget.ride.passenger?.name ?? 'Passenger #${widget.ride.passengerId}';

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
            child: Text(urgent ? '⚡ URGENT' : '🆕 NEW REQUEST',
                style: TextStyle(color: accentColor,
                    fontWeight: FontWeight.w800, fontSize: 11)),
          ),
          Spacer(),
          Text('$_seconds s', style: TextStyle(
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
                  child: const Text('Metered fare',
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
                      ? 'No destination — passenger will tell you'
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
              child: Center(child: Text('Decline',
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
                  : const Text('Accept Ride',
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

  const _DeliveryRequestCard({
    required this.delivery,
    required this.onAccept,
    required this.onDeclined,
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
      setState(() => _acting = false);
    } catch (_) {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _decline() async {
    if (_acting) return;
    _timer?.cancel();
    widget.onDeclined();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _seconds / 30.0;
    final urgent   = _seconds <= 8;
    final senderLabel = widget.delivery.sender?.name
        ?? widget.delivery.senderName
        ?? 'Sender #${widget.delivery.senderId}';

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
              urgent ? '⚡ URGENT'
                  : widget.delivery.isMoving ? '🚚 NEW MOVING' : '📦 NEW DELIVERY',
              style: TextStyle(color: cardColor,
                  fontWeight: FontWeight.w800, fontSize: 11),
            ),
          ),
          const Spacer(),
          Text('$_seconds s', style: TextStyle(
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
                Text('Moving Details', style: TextStyle(
                    color: context.appTextPrimary, fontWeight: FontWeight.w700, fontSize: 12)),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Icon(Icons.apartment_outlined, color: context.appTextSecondary, size: 14),
                const SizedBox(width: 6),
                Text(
                  'Floor: pickup ${widget.delivery.floorPickup ?? '?'} → '
                  'dropoff ${widget.delivery.floorDropoff ?? '?'}',
                  style: TextStyle(color: context.appTextSecondary, fontSize: 12),
                ),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.elevator_outlined, color: context.appTextPrimary, size: 14),
                const SizedBox(width: 6),
                Text(
                  'Elevator: ${(widget.delivery.hasElevator ?? true) ? "Yes" : "No"}',
                  style: TextStyle(color: context.appTextPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                if (widget.delivery.needsStairsCarry == true) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.stairs_outlined, color: context.appTextSecondary, size: 14),
                  Text(' Stairs carry',
                      style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
                ],
              ]),
              const SizedBox(height: 4),
              if (widget.delivery.requiresHelpers != null)
                Row(children: [
                  Icon(Icons.people_outline, color: context.appTextSecondary, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    '${widget.delivery.requiresHelpers} helper(s) — '
                    '${widget.delivery.helperType == 'heavy_carry' ? 'Heavy carry' : 'Normal carry'}',
                    style: TextStyle(color: context.appTextSecondary, fontSize: 12),
                  ),
                ]),
              const SizedBox(height: 6),
              Wrap(spacing: 6, children: [
                if (widget.delivery.heavyItems == true)
                  _MovingFlag(label: '⚠ Heavy items', color: cardColor),
                if (widget.delivery.packingService == true)
                  _MovingFlag(label: '📦 Packing', color: cardColor),
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
              child: Center(child: Text('Decline',
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
                  : const Text('Accept Delivery',
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

  const _RentalRequestCard({
    required this.rental,
    required this.onAccept,
    required this.onDeclined,
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
      setState(() => _acting = false);
    } catch (_) {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _decline() async {
    if (_acting) return;
    _timer?.cancel();
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
        ?? 'Customer #${r['customer_id'] ?? ''}';
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
              urgent ? '⚡ URGENT' : '🚗 NEW RENTAL',
              style: TextStyle(color: cardColor,
                  fontWeight: FontWeight.w800, fontSize: 11),
            ),
          ),
          const Spacer(),
          Text('$_seconds s', style: TextStyle(
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
              child: Center(child: Text('Decline',
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
                  : const Text('Accept Rental',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
            ),
          )),
        ]),
      ]),
    );
  }
}

// ─── Driver trip card ─────────────────────────────────────────────────────────
class _DriverTripCard extends StatelessWidget {
  final String passenger, from, to, earned, time;

  const _DriverTripCard({required this.passenger, required this.from, required this.to, required this.earned, required this.time});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(color: context.appSurface, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        CircleAvatar(backgroundColor: AppTheme.accentOrange.withValues(alpha: 0.2), radius: 18,
          child: Text(passenger[0], style: TextStyle(color: AppTheme.accentOrange, fontWeight: FontWeight.w700))),
        SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(passenger, style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
          Text('$from → $to', style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(earned, style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.w700)),
          Text(time,   style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
        ]),
      ]),
    );
  }
}

// ─── Recent rides section ─────────────────────────────────────────────────────
class _RecentRidesSection extends StatefulWidget {
  const _RecentRidesSection();

  @override
  State<_RecentRidesSection> createState() => _RecentRidesSectionState();
}

class _RecentRidesSectionState extends State<_RecentRidesSection> {
  List<RideModel> _rides = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rides = await ApiService.getRides();
      if (!mounted) return;
      setState(() { _rides = rides; _loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator(color: AppTheme.accentOrange)),
      );
    }
    if (_rides.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(color: context.appSurface, borderRadius: BorderRadius.circular(14)),
        child: Center(child: Text('No recent trips', style: TextStyle(color: context.appTextSecondary))),
      );
    }
    return Column(
      children: _rides.map((ride) => _DriverTripCard(
        passenger: ride.driver?.name ?? 'Passenger #${ride.passengerId}',
        from:      ride.pickupAddress,
        to:        ride.dropoffAddress.isNotEmpty ? ride.dropoffAddress : 'No destination set',
        earned:    '+${AppTheme.khr(ride.fareKhr)}',
        time:      ride.createdAt.length >= 16 ? ride.createdAt.substring(11, 16) : '',
      )).toList(),
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

  String _bank       = 'ABA Bank';
  bool   _withdrawing = false;
  final _payoutAccNumCtrl  = TextEditingController();
  final _payoutAccNameCtrl = TextEditingController();

  static const _banks = [
    {'name': 'ABA Bank',    'icon': Icons.account_balance,        'color': Color(0xFF00D4AA), 'method': 'aba'},
    {'name': 'ACLEDA Bank', 'icon': Icons.account_balance_wallet, 'color': Color(0xFF2196F3), 'method': 'acleda'},
    {'name': 'Wing Money',  'icon': Icons.phone_android,           'color': Color(0xFFFF6B35), 'method': 'wing'},
    {'name': 'Canadia Bank','icon': Icons.credit_card,             'color': Color(0xFF9C27B0), 'method': 'bank_transfer'},
  ];

  String get _bankMethod => (_banks.firstWhere((b) => b['name'] == _bank)['method'] as String?) ?? 'bank_transfer';

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
              child: Text('Select Bank', style: TextStyle(
                  color: ctx.appTextPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
          Divider(height: 1, color: ctx.appCardBg),
          ..._banks.map((b) {
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
          title: const Text('Confirm Withdrawal',
              style: TextStyle(fontWeight: FontWeight.w800)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Withdraw your full balance to $_bank?\nThis will be sent to admin for approval.',
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
                decoration: const InputDecoration(
                  labelText: 'Account Number',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _payoutAccNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Account Holder Name',
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
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_payoutAccNumCtrl.text.trim().isEmpty || _payoutAccNameCtrl.text.trim().isEmpty) {
                  setDialogState(() => fieldError = 'Please enter your account number and holder name.');
                  return;
                }
                Navigator.pop(ctx, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Yes, Withdraw'),
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
        paymentMethod: _bankMethod,
        accountNumber: _payoutAccNumCtrl.text.trim(),
        accountName:   _payoutAccNameCtrl.text.trim(),
        bankName:      _bank,
      );
      if (!mounted) return;
      setState(() => _withdrawing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('✅ Withdrawal request for ${AppTheme.khr(balance)} submitted — pending admin approval'),
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
              Text('Earnings',
                  style: TextStyle(
                      color: context.appTextPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800)),
              Spacer(),
              IconButton(
                icon: Icon(Icons.refresh,
                    color: context.appTextSecondary, size: 20),
                onPressed: _loadAll,
                tooltip: 'Refresh',
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
                          const Text('Available Balance',
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
                              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(Icons.add_circle_outline, color: Colors.white, size: 16),
                                SizedBox(width: 6),
                                Text('Top Up', style: TextStyle(
                                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                              ]),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _EarningItem(
                                  label: 'Trips',
                                  value: AppTheme.khr(_tripEarnings),
                                  valueColor: Colors.white,
                                  labelColor: Colors.white70),
                              _EarningItem(
                                  label: 'Bonuses',
                                  value: AppTheme.khr(_bonuses),
                                  valueColor: Colors.white,
                                  labelColor: Colors.white70),
                              _EarningItem(
                                  label: 'Fees',
                                  value: '-${AppTheme.khr(_platformFees)}',
                                  valueColor: Colors.white,
                                  labelColor: Colors.white70),
                              if (_topUps > 0)
                                _EarningItem(
                                    label: 'Top-ups',
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
                  title: _showAllTx ? 'Transaction History' : "Today's Transactions")),
              if (_showAllTx && _total > 0)
                Text('$_total total',
                    style: TextStyle(
                        color: context.appTextSecondary, fontSize: 12)),
              if (!_showAllTx)
                TextButton(
                  onPressed: () => setState(() => _showAllTx = true),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero,
                      minimumSize: Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  child: Text('Show All',
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
                    child: Text('Retry',
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
                  child: Text(_showAllTx ? 'No transactions yet' : 'No transactions today',
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
                            label: Text('Load more',
                                style: TextStyle(
                                    color: AppTheme.accentOrange)),
                          ),
                  ),
                ),
            ],

            SizedBox(height: 20),

            // ── Instant withdrawal ────────────────────────────────────────
            SectionHeader(title: 'Instant Withdrawal'),
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
                      'You have a withdrawal request pending admin approval.',
                      style: TextStyle(color: context.appTextPrimary, fontSize: 12, fontWeight: FontWeight.w600))),
                ]),
              ),
              const SizedBox(height: 12),
            ],
            Builder(builder: (context) {
              final selected = _banks.firstWhere((b) => b['name'] == _bank);
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
                      Text('Bank', style: TextStyle(
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
                label = 'Withdrawal pending approval';
              } else if (balance == 0) {
                label = 'No balance to withdraw';
              } else if (belowMin) {
                label = 'Minimum withdrawal: ${AppTheme.khr(minWithdrawal)}';
              } else if (!canWithdraw) {
                label = 'Withdrawals unavailable';
              } else {
                label = '💸  Withdraw ${AppTheme.khr(balance)} to $_bank';
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
              child: Text('Reviewed by admin before funds are sent',
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
          Text('Bal: ${AppTheme.khr(txn.balanceAfter)}',
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
            Text('(1,204 trips)', style: TextStyle(color: context.appTextSecondary, fontSize: 13)),
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
                StatusBadge(label: 'Verified', color: AppTheme.success),
              ]),
            ),
          const SizedBox(height: 20),
          Builder(builder: (context) {
            final l = AppLocalizations.of(context);
            return Column(children: [
              ...([
                (l.bankPayouts,     Icons.account_balance_outlined, () => widget.onGoToEarnings(), false),
                ('My Earnings',     Icons.account_balance_wallet_outlined, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverEarningsScreen())), false),
                ('Top Up Wallet',   Icons.add_circle_outline,       () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()));
                  widget.onWalletChanged?.call();
                }, false),
                ('Helmet Check',    Icons.security_rounded,         () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelmetCheckScreen())), false),
                (l.safetySettings,  Icons.shield_outlined,          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SafetyScreen())),  false),
                (l.documents,       Icons.description_outlined,     () {}, false),
                (l.tripHistory,     Icons.history_outlined,         () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverHistoryScreen())), false),
                (l.signOut, Icons.logout, () async {
                  await ApiService.logout();
                  if (!context.mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
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
              // ── Switch to Passenger Mode ────────────────────────────────
              GestureDetector(
                onTap: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => PassengerHomeScreen()),
                  (_) => false,
                ),
                child: Container(
                  margin: EdgeInsets.only(bottom: 10),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.accent.withValues(alpha: 0.25)),
                  ),
                  child: Row(children: [
                    Container(
                      padding: EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.person_outline, color: AppTheme.accent, size: 18),
                    ),
                    SizedBox(width: 12),
                    Expanded(child: Text('Switch to Passenger Mode',
                        style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w700, fontSize: 14))),
                    Icon(Icons.chevron_right, color: AppTheme.accent, size: 18),
                  ]),
                ),
              ),
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
                    Text('Dark Mode',
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
