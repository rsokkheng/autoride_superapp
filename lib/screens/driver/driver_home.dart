import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../l10n/app_localizations.dart';
import '../../services/api_service.dart';
import '../../models/user_model.dart';
import '../../models/vehicle_model.dart';
import '../../models/delivery_model.dart';
import '../../models/ride_model.dart';
import '../../models/driver_stats_model.dart';
import '../../models/wallet_model.dart';
import '../auth/role_selection.dart';
import '../auth/login_screen.dart';
import '../shared/chat_screen.dart';
import '../passenger/safety_screen.dart';
import 'driver_active_trip_screen.dart';
import 'driver_missions_screen.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  int _tab = 0;
  bool _isOnline = true;
  bool _togglingOnline = false;
  bool _modeRide     = true;
  bool _modeDelivery = false;
  bool _modeRental   = false;

  Future<void> _toggleOnline(bool value) async {
    if (_togglingOnline) return;
    setState(() => _togglingOnline = true);
    try {
      if (value) {
        await ApiService.goOnline();
      } else {
        await ApiService.goOffline();
      }
      if (mounted) setState(() => _isOnline = value);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.message),
          backgroundColor: AppTheme.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } finally {
      if (mounted) setState(() => _togglingOnline = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _DriverDashboard(
        isOnline:    _isOnline,
        onToggle:    _toggleOnline,
        modeRide:     _modeRide,
        modeDelivery: _modeDelivery,
        modeRental:   _modeRental,
        onModeRide:     (v) => setState(() {
          // at least one mode must stay active
          if (!v && !_modeDelivery && !_modeRental) return;
          _modeRide = v;
        }),
        onModeDelivery: (v) => setState(() {
          if (!v && !_modeRide && !_modeRental) return;
          _modeDelivery = v;
        }),
        onModeRental: (v) => setState(() {
          if (!v && !_modeRide && !_modeDelivery) return;
          _modeRental = v;
        }),
      ),
      const _DriverEarnings(),
      const DriverMissionsScreen(),
      const ChatScreen(isDriver: true),
      _DriverProfile(onGoToEarnings: () => setState(() => _tab = 1)),
    ];

    return Scaffold(
      body: pages[_tab],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20)],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(icon: Icons.dashboard_outlined,           label: 'Home',     index: 0, current: _tab, onTap: (i) => setState(() => _tab = i)),
                _NavItem(icon: Icons.account_balance_wallet_outlined, label: AppLocalizations.of(context).earnings, index: 1, current: _tab, onTap: (i) => setState(() => _tab = i)),
                _NavItem(icon: Icons.rocket_launch_outlined,       label: 'Missions', index: 2, current: _tab, onTap: (i) => setState(() => _tab = i)),
                _NavItem(icon: Icons.chat_bubble_outline,          label: AppLocalizations.of(context).chat,     index: 3, current: _tab, onTap: (i) => setState(() => _tab = i)),
                _NavItem(icon: Icons.person_outline,               label: AppLocalizations.of(context).profile,  index: 4, current: _tab, onTap: (i) => setState(() => _tab = i)),
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
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.accentOrange.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: selected ? AppTheme.accentOrange : AppTheme.textSecondary, size: 22),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(
            color: selected ? AppTheme.accentOrange : AppTheme.textSecondary,
            fontSize: 10, fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          )),
        ]),
      ),
    );
  }
}

// ─── Dashboard ────────────────────────────────────────────────────────────────
class _DriverDashboard extends StatefulWidget {
  final bool isOnline, modeRide, modeDelivery, modeRental;
  final Function(bool) onToggle, onModeRide, onModeDelivery, onModeRental;

  const _DriverDashboard({
    required this.isOnline,
    required this.onToggle,
    required this.modeRide,
    required this.modeDelivery,
    required this.modeRental,
    required this.onModeRide,
    required this.onModeDelivery,
    required this.onModeRental,
  });

  @override
  State<_DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<_DriverDashboard> {
  DriverStatsModel? _stats;
  RideModel?     _pendingRide;
  DeliveryModel? _pendingDelivery;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _pollRequests());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        ApiService.getDriverStats(),
        ApiService.getAvailableRides(),
        ApiService.getAvailableDeliveries(),
      ]);
      if (!mounted) return;
      setState(() {
        _stats = results[0] as DriverStatsModel;
        final rides = results[1] as List<RideModel>;
        _pendingRide = rides.isNotEmpty ? rides.first : null;
        final deliveries = results[2] as List<DeliveryModel>;
        _pendingDelivery = deliveries.isNotEmpty ? deliveries.first : null;
      });
    } catch (_) {}
  }

  Future<void> _pollRequests() async {
    if (_pendingRide == null) {
      try {
        final rides = await ApiService.getAvailableRides();
        if (!mounted) return;
        if (rides.isNotEmpty) setState(() => _pendingRide = rides.first);
      } catch (_) {}
    }
    if (_pendingDelivery == null) {
      try {
        final deliveries = await ApiService.getAvailableDeliveries();
        if (!mounted) return;
        if (deliveries.isNotEmpty) setState(() => _pendingDelivery = deliveries.first);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Driver Dashboard', style: TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
                Row(children: [
                  const Icon(Icons.star, color: AppTheme.gold, size: 16),
                  const SizedBox(width: 4),
                  const Text('4.87', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                  Text(' · 1,204 trips', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                ]),
              ]),
              const Spacer(),
              Column(children: [
                Switch(value: widget.isOnline, onChanged: widget.onToggle, activeThumbColor: AppTheme.success, activeTrackColor: AppTheme.success.withValues(alpha: 0.4)),
                Text(widget.isOnline ? 'Online' : 'Offline',
                    style: TextStyle(color: widget.isOnline ? AppTheme.success : AppTheme.textSecondary, fontSize: 11)),
              ]),
            ]),
            const SizedBox(height: 16),

            // Surge zone alert banner
            if (widget.isOnline)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.danger.withValues(alpha: 0.4)),
                ),
                child: Row(children: [
                  const Icon(Icons.local_fire_department, color: AppTheme.danger, size: 20),
                  const SizedBox(width: 10),
                  const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('🔥 Surge Zone Active', style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.w700, fontSize: 13)),
                    Text('1.8× near Aeon Mall Sen Sok · 6 PM–9 PM', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                  ])),
                  const Icon(Icons.chevron_right, color: AppTheme.textSecondary, size: 18),
                ]),
              ),

            // Status card
            GradientCard(
              colors: widget.isOnline ? [const Color(0xFF0F3460), const Color(0xFF003B2F)] : [AppTheme.surface, AppTheme.cardBg],
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  StatusBadge(label: widget.isOnline ? '🟢 Online — Ready' : '⭕ Offline', color: widget.isOnline ? AppTheme.success : AppTheme.textSecondary),
                  const SizedBox(height: 8),
                  Text(widget.isOnline ? 'Waiting for requests...' : 'Toggle online to accept rides',
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                ])),
                Icon(Icons.directions_car, color: widget.isOnline ? AppTheme.success : AppTheme.textSecondary, size: 50),
              ]),
            ),
            const SizedBox(height: 16),

            // Service modes (multi-select, at least one active)
            const SectionHeader(title: 'Service Modes'),
            const SizedBox(height: 10),
            Row(children: [
              _ModeChip(icon: Icons.directions_car_outlined,  label: 'Ride',     active: widget.modeRide,     color: AppTheme.accent,         onTap: () => widget.onModeRide(!widget.modeRide)),
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
                _StatCard(label: 'Accepted',        value: '${_stats?.acceptedRides  ?? 0}', icon: Icons.check_circle_outline,  color: AppTheme.accent),
                _StatCard(label: 'Completed',        value: '${_stats?.completedRides ?? 0}', icon: Icons.directions_car,        color: AppTheme.accentOrange),
                _StatCard(label: 'Hours Online',     value: '5.2h',    icon: Icons.access_time,        color: const Color(0xFF9C27B0)),
                _StatCard(label: 'Acceptance Rate',  value: '94%',     icon: Icons.thumb_up_outlined,  color: AppTheme.success),
              ],
            ),
            const SizedBox(height: 20),

            // Peak hour bonus tracker
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.warning.withValues(alpha: 0.4)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.bolt, color: AppTheme.warning, size: 20),
                  const SizedBox(width: 8),
                  const Text('Peak Hour Bonus', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppTheme.warning.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                    child: const Text('Active 6–9 PM', style: TextStyle(color: AppTheme.warning, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Extra \$0.50 per trip during peak hours', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: 0.6,
                        backgroundColor: AppTheme.cardBg,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.warning),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text('3 of 5 peak-hour trips completed today', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                  ])),
                  const SizedBox(width: 14),
                  const Column(children: [
                    Text('+\$1.50', style: TextStyle(color: AppTheme.warning, fontWeight: FontWeight.w900, fontSize: 20)),
                    Text('earned today', style: TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
                  ]),
                ]),
              ]),
            ),
            const SizedBox(height: 14),

            // 5-star streak rewards
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.gold.withValues(alpha: 0.4)),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppTheme.gold.withValues(alpha: 0.15), shape: BoxShape.circle),
                  child: const Icon(Icons.emoji_events, color: AppTheme.gold, size: 26),
                ),
                const SizedBox(width: 12),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('5-Star Streak 🔥', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
                  Text('4 consecutive 5-star ratings!', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  SizedBox(height: 4),
                  Text('1 more 5-star = Earn \$5 bonus', style: TextStyle(color: AppTheme.gold, fontSize: 12, fontWeight: FontWeight.w600)),
                ])),
                Row(children: List.generate(5, (i) => Icon(
                  i < 4 ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: i < 4 ? AppTheme.gold : AppTheme.textSecondary, size: 18,
                ))),
              ]),
            ),
            const SizedBox(height: 20),

            // Active mode cards (one per active mode)
            if (widget.isOnline) ...[
              if (widget.modeRide) ...[
                if (_pendingRide != null) ...[
                  const SectionHeader(title: 'Incoming Ride Request'),
                  const SizedBox(height: 14),
                  _RideRequestCard(
                    ride: _pendingRide!,
                    onAccepted: () => setState(() => _pendingRide = null),
                    onDeclined: () => setState(() => _pendingRide = null),
                  ),
                ] else ...[
                  _ModeEmptyCard(
                    icon: Icons.directions_car_outlined,
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
                    onAccepted: () => setState(() => _pendingDelivery = null),
                    onDeclined: () => setState(() => _pendingDelivery = null),
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
                _ModeEmptyCard(
                  icon: Icons.car_rental_outlined,
                  color: const Color(0xFF9C27B0),
                  title: 'Rental Mode Active',
                  subtitle: 'Your vehicle is listed for hourly rentals.',
                ),
                const SizedBox(height: 14),
              ],
            ],

            const SectionHeader(title: 'Recent Trips'),
            const SizedBox(height: 14),
            const _RecentRidesSection(),
          ],
        ),
      ),
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
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.15) : AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? color : AppTheme.surface),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: active ? color : AppTheme.textSecondary, size: 20),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: active ? color : AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 12),
        Text(title,
            style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 6),
        Text(subtitle,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 20),
        const Spacer(),
        Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w800)),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
      ]),
    );
  }
}

// ─── Ride request card with countdown ─────────────────────────────────────────
class _RideRequestCard extends StatefulWidget {
  final RideModel ride;
  final VoidCallback onAccepted;
  final VoidCallback onDeclined;

  const _RideRequestCard({
    required this.ride,
    required this.onAccepted,
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
      widget.onAccepted();
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => DriverActiveTripScreen(ride: widget.ride),
      ));
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
    final urgent = _seconds <= 8;
    final passengerLabel = widget.ride.passenger?.name ?? 'Passenger #${widget.ride.passengerId}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (urgent ? AppTheme.danger : AppTheme.accentOrange).withValues(alpha: 0.5), width: 1.5),
      ),
      child: Column(children: [
        Row(children: [
          StatusBadge(label: urgent ? '⚡ URGENT' : '🆕 NEW REQUEST', color: urgent ? AppTheme.danger : AppTheme.accentOrange),
          const Spacer(),
          Text('$_seconds s', style: TextStyle(color: urgent ? AppTheme.danger : AppTheme.accentOrange, fontWeight: FontWeight.w900, fontSize: 16)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppTheme.cardBg,
            valueColor: AlwaysStoppedAnimation<Color>(urgent ? AppTheme.danger : AppTheme.accentOrange),
            minHeight: 5,
          ),
        ),
        const SizedBox(height: 12),

        Row(children: [
          CircleAvatar(backgroundColor: AppTheme.accent.withValues(alpha: 0.2), radius: 18,
            child: Text(passengerLabel[0], style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w700))),
          const SizedBox(width: 10),
          Expanded(child: Text(passengerLabel, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600))),
          Text('\$${widget.ride.fare}', style: const TextStyle(color: AppTheme.accent, fontSize: 20, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(10)),
          child: Column(children: [
            Row(children: [
              const Icon(Icons.circle, color: AppTheme.accent, size: 10),
              const SizedBox(width: 8),
              Expanded(child: Text(widget.ride.pickupAddress, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13), overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.location_on, color: AppTheme.accentOrange, size: 10),
              const SizedBox(width: 8),
              Expanded(child: Text(widget.ride.dropoffAddress, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13), overflow: TextOverflow.ellipsis)),
            ]),
          ]),
        ),
        const SizedBox(height: 14),

        Row(children: [
          Expanded(child: GestureDetector(
            onTap: _acting ? null : _decline,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(10)),
              child: const Center(child: Text('Decline', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600))),
            ),
          )),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: GestureDetector(
            onTap: _acting ? null : _accept,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(color: AppTheme.accentOrange, borderRadius: BorderRadius.circular(10)),
              child: Center(child: _acting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Accept Ride', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
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
  final VoidCallback onAccepted;
  final VoidCallback onDeclined;

  const _DeliveryRequestCard({
    required this.delivery,
    required this.onAccepted,
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
      widget.onAccepted();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Delivery accepted! Go to Missions tab to manage it.'),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: (urgent ? AppTheme.danger : AppTheme.accentOrange).withValues(alpha: 0.5),
            width: 1.5),
      ),
      child: Column(children: [
        Row(children: [
          StatusBadge(label: urgent ? '⚡ URGENT' : '📦 NEW DELIVERY', color: urgent ? AppTheme.danger : AppTheme.accentOrange),
          const Spacer(),
          Text('$_seconds s', style: TextStyle(
              color: urgent ? AppTheme.danger : AppTheme.accentOrange,
              fontWeight: FontWeight.w900,
              fontSize: 16)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppTheme.cardBg,
            valueColor: AlwaysStoppedAnimation<Color>(
                urgent ? AppTheme.danger : AppTheme.accentOrange),
            minHeight: 5,
          ),
        ),
        const SizedBox(height: 12),

        Row(children: [
          CircleAvatar(
            backgroundColor: AppTheme.accentOrange.withValues(alpha: 0.2),
            radius: 18,
            child: Text(senderLabel[0],
                style: const TextStyle(
                    color: AppTheme.accentOrange, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(senderLabel,
                style: const TextStyle(
                    color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
            if (widget.delivery.packageSize != null)
              Text(widget.delivery.packageSize!,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12)),
          ])),
          Text(AppTheme.khr(widget.delivery.fee),
              style: const TextStyle(
                  color: AppTheme.accentOrange,
                  fontSize: 18,
                  fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(10)),
          child: Column(children: [
            Row(children: [
              const Icon(Icons.circle, color: AppTheme.accent, size: 10),
              const SizedBox(width: 8),
              Expanded(child: Text(widget.delivery.pickupAddress,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13),
                  overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.location_on, color: AppTheme.accentOrange, size: 10),
              const SizedBox(width: 8),
              Expanded(child: Text(widget.delivery.dropoffAddress,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13),
                  overflow: TextOverflow.ellipsis)),
            ]),
          ]),
        ),
        const SizedBox(height: 14),

        Row(children: [
          Expanded(child: GestureDetector(
            onTap: _acting ? null : _decline,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(10)),
              child: const Center(child: Text('Decline',
                  style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600))),
            ),
          )),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: GestureDetector(
            onTap: _acting ? null : _accept,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                  color: AppTheme.accentOrange,
                  borderRadius: BorderRadius.circular(10)),
              child: Center(child: _acting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Accept Delivery',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800))),
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
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        CircleAvatar(backgroundColor: AppTheme.accentOrange.withValues(alpha: 0.2), radius: 18,
          child: Text(passenger[0], style: const TextStyle(color: AppTheme.accentOrange, fontWeight: FontWeight.w700))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(passenger, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
          Text('$from → $to', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(earned, style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.w700)),
          Text(time,   style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(14)),
        child: const Center(child: Text('No recent trips', style: TextStyle(color: AppTheme.textSecondary))),
      );
    }
    return Column(
      children: _rides.map((ride) => _DriverTripCard(
        passenger: ride.driver?.name ?? 'Passenger #${ride.passengerId}',
        from:      ride.pickupAddress,
        to:        ride.dropoffAddress,
        earned:    '+\$${ride.fare}',
        time:      ride.createdAt.length >= 16 ? ride.createdAt.substring(11, 16) : '',
      )).toList(),
    );
  }
}

// ─── Earnings tab ─────────────────────────────────────────────────────────────
class _DriverEarnings extends StatefulWidget {
  const _DriverEarnings();

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

  String _bank       = 'ABA Bank';
  bool   _withdrawing = false;

  static const _banks = [
    {'name': 'ABA Bank',    'icon': Icons.account_balance,        'color': Color(0xFF00D4AA)},
    {'name': 'ACLEDA Bank', 'icon': Icons.account_balance_wallet, 'color': Color(0xFF2196F3)},
    {'name': 'Wing Money',  'icon': Icons.phone_android,           'color': Color(0xFFFF6B35)},
    {'name': 'Canadia Bank','icon': Icons.credit_card,             'color': Color(0xFF9C27B0)},
  ];

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

  Future<void> _withdraw() async {
    final balance = _wallet?.balance ?? 0;
    if (balance == 0 || _withdrawing) return;
    setState(() => _withdrawing = true);
    try {
      final result = await ApiService.withdraw(
        amount: balance,
        note:   'Withdrawal to $_bank',
      );
      if (!mounted) return;
      setState(() {
        _withdrawing = false;
        // Update displayed balance optimistically
        if (_wallet != null) {
          _wallet = WalletModel(
            balance:      result.newBalance,
            currency:     _wallet!.currency,
            transactions: _wallet!.transactions,
          );
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('✅ ${AppTheme.khr(balance)} sent to $_bank'),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      // Refresh full data to get updated transactions
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
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Text('Earnings',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh,
                    color: AppTheme.textSecondary, size: 20),
                onPressed: _loadAll,
                tooltip: 'Refresh',
              ),
            ]),
            const SizedBox(height: 16),

            // ── Balance card ──────────────────────────────────────────────
            GradientCard(
              colors: const [Color(0xFF0F3460), Color(0xFF1A3A00)],
              child: _balanceLoading
                  ? const SizedBox(
                      height: 80,
                      child: Center(
                          child: CircularProgressIndicator(
                              color: AppTheme.accent)))
                  : _balanceError != null
                      ? Text(_balanceError!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 13))
                      : Column(children: [
                          const Text('Available Balance',
                              style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 13)),
                          const SizedBox(height: 8),
                          Text(AppTheme.khr(balance),
                              style: const TextStyle(
                                  color: AppTheme.accent,
                                  fontSize: 34,
                                  fontWeight: FontWeight.w800)),
                          Text(AppTheme.usd(balance / 4000),
                              style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 13)),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _EarningItem(
                                  label: 'Trips',
                                  value: AppTheme.khr(_tripEarnings)),
                              _EarningItem(
                                  label: 'Bonuses',
                                  value: AppTheme.khr(_bonuses)),
                              _EarningItem(
                                  label: 'Fees',
                                  value: '-${AppTheme.khr(_platformFees)}',
                                  valueColor: AppTheme.danger),
                              if (_topUps > 0)
                                _EarningItem(
                                    label: 'Top-ups',
                                    value: AppTheme.khr(_topUps)),
                            ],
                          ),
                        ]),
            ),
            const SizedBox(height: 20),

            // ── Transaction history ───────────────────────────────────────
            Row(children: [
              const Expanded(child: SectionHeader(title: 'Transaction History')),
              if (_total > 0)
                Text('$_total total',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12)),
            ]),
            const SizedBox(height: 14),

            if (_txLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(
                      color: AppTheme.accentOrange),
                ),
              )
            else if (_txError != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(14)),
                child: Column(children: [
                  Text(_txError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 13)),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => _loadTransactions(reset: true),
                    child: const Text('Retry',
                        style: TextStyle(color: AppTheme.accentOrange)),
                  ),
                ]),
              )
            else if (_transactions.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(14)),
                child: const Center(
                  child: Text('No transactions yet',
                      style: TextStyle(color: AppTheme.textSecondary)),
                ),
              )
            else ...[
              ..._transactions.map((t) => _TxnTile(txn: t)),
              if (_currentPage < _lastPage)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: _txLoadingMore
                        ? const CircularProgressIndicator(
                            color: AppTheme.accentOrange)
                        : TextButton.icon(
                            onPressed: () =>
                                _loadTransactions(reset: false),
                            icon: const Icon(Icons.expand_more,
                                color: AppTheme.accentOrange),
                            label: const Text('Load more',
                                style: TextStyle(
                                    color: AppTheme.accentOrange)),
                          ),
                  ),
                ),
            ],

            const SizedBox(height: 20),

            // ── Instant withdrawal ────────────────────────────────────────
            const SectionHeader(title: 'Instant Withdrawal'),
            const SizedBox(height: 12),
            ..._banks.map((b) => GestureDetector(
              onTap: () => setState(() => _bank = b['name'] as String),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: _bank == b['name']
                          ? AppTheme.accent
                          : Colors.transparent),
                ),
                child: Row(children: [
                  Icon(b['icon'] as IconData,
                      color: b['color'] as Color, size: 22),
                  const SizedBox(width: 12),
                  Text(b['name'] as String,
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Icon(
                    _bank == b['name']
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: _bank == b['name']
                        ? AppTheme.accent
                        : AppTheme.textSecondary,
                    size: 20,
                  ),
                ]),
              ),
            )),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (balance == 0 || _withdrawing) ? null : _withdraw,
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
                    : Text(
                        balance == 0
                            ? 'No balance to withdraw'
                            : '💸  Withdraw ${AppTheme.khr(balance)} to $_bank',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text('Funds arrive within 5 minutes',
                  style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12)),
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

  const _EarningItem(
      {required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) => Column(children: [
        Text(value,
            style: TextStyle(
                color: valueColor ?? AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 12)),
        Text(label,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 10)),
      ]);
}

class _TxnTile extends StatelessWidget {
  final WalletTransactionModel txn;

  const _TxnTile({required this.txn});

  IconData get _icon {
    switch (txn.type) {
      case 'trip_earning':        return Icons.directions_car;
      case 'platform_commission': return Icons.percent;
      case 'bonus':               return Icons.emoji_events;
      case 'top_up':              return Icons.add_circle_outline;
      case 'refund':              return Icons.undo;
      default:                    return Icons.swap_horiz;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCredit  = txn.isCredit;
    final itemColor = isCredit ? AppTheme.success : AppTheme.accentOrange;
    final amountStr = isCredit
        ? '+${AppTheme.khr(txn.amount)}'
        : '-${AppTheme.khr(txn.amount)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: itemColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(_icon, color: itemColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(txn.displayLabel,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Row(children: [
                  Text(txn.formattedDate,
                      style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                        color: AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(4)),
                    child: Text(txn.status,
                        style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 10)),
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
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 10)),
        ]),
      ]),
    );
  }
}

// ─── Driver profile ───────────────────────────────────────────────────────────
class _DriverProfile extends StatefulWidget {
  const _DriverProfile({required this.onGoToEarnings});
  final VoidCallback onGoToEarnings;

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
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          const SizedBox(height: 20),
          Stack(children: [
            CircleAvatar(radius: 48, backgroundColor: AppTheme.accentOrange.withValues(alpha: 0.2),
              child: const Icon(Icons.person, color: AppTheme.accentOrange, size: 48)),
            Positioned(bottom: 0, right: 0,
              child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: AppTheme.success, shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Colors.white, size: 14))),
          ]),
          const SizedBox(height: 12),
          _loading
              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: AppTheme.accentOrange, strokeWidth: 2))
              : Text(_name, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(_phone, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.star, color: AppTheme.gold, size: 18),
            const SizedBox(width: 4),
            const Text('4.87', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
            const SizedBox(width: 4),
            Text('(1,204 trips)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          ]),
          const SizedBox(height: 20),
          if (_vehicleName.isNotEmpty)
            Container(padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                const Icon(Icons.directions_car, color: AppTheme.accentOrange, size: 36),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_vehicleName,  style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                  Text(_vehiclePlate, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
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
                (l.safetySettings,  Icons.shield_outlined,          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SafetyScreen())),  false),
                (l.documents,       Icons.description_outlined,     () {}, false),
                (l.tripHistory,     Icons.history_outlined,         () {}, false),
                (l.signOut, Icons.logout, () async {
                  await ApiService.logout();
                  if (!context.mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (_) => false,
                  );
                }, true),
              ].map((item) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(14)),
                child: ListTile(
                  leading: Icon(item.$2, color: item.$4 ? AppTheme.danger : AppTheme.textSecondary, size: 20),
                  title: Text(item.$1, style: TextStyle(color: item.$4 ? AppTheme.danger : AppTheme.textPrimary, fontSize: 14)),
                  trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary, size: 18),
                  onTap: item.$3,
                ),
              ))),
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  const Icon(Icons.language, color: AppTheme.textSecondary, size: 20),
                  const SizedBox(width: 14),
                  Text(l.language, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
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
