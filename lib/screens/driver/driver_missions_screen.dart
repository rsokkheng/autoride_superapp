import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/delivery_model.dart';
import '../../services/api_service.dart';
import 'driver_delivery_active_screen.dart';

class DriverMissionsScreen extends StatefulWidget {
  const DriverMissionsScreen({super.key});

  @override
  State<DriverMissionsScreen> createState() => _DriverMissionsScreenState();
}

class _DriverMissionsScreenState extends State<DriverMissionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<DeliveryModel> _deliveries = [];
  List<DeliveryModel> _movings    = [];
  bool   _loadingDeliveries = true;
  bool   _loadingMovings    = true;
  String? _errorDeliveries;
  String? _errorMovings;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDeliveries();
    _loadMovings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDeliveries() async {
    setState(() { _loadingDeliveries = true; _errorDeliveries = null; });
    try {
      final list = await ApiService.getDeliveries();
      if (mounted) setState(() { _deliveries = list; _loadingDeliveries = false; });
    } on ApiException catch (e) {
      if (mounted) setState(() { _errorDeliveries = e.message; _loadingDeliveries = false; });
    } catch (_) {
      if (mounted) setState(() { _errorDeliveries = 'Failed to load deliveries.'; _loadingDeliveries = false; });
    }
  }

  Future<void> _loadMovings() async {
    setState(() { _loadingMovings = true; _errorMovings = null; });
    try {
      final list = await ApiService.getMovings();
      if (mounted) setState(() { _movings = list; _loadingMovings = false; });
    } on ApiException catch (e) {
      if (mounted) setState(() { _errorMovings = e.message; _loadingMovings = false; });
    } catch (_) {
      if (mounted) setState(() { _errorMovings = 'Failed to load movings.'; _loadingMovings = false; });
    }
  }

  // Active = accepted or in_progress
  List<DeliveryModel> get _activeDeliveries =>
      _deliveries.where((d) => d.isAccepted || d.isInProgress).toList();
  List<DeliveryModel> get _activeMovings =>
      _movings.where((d) => d.isAccepted || d.isInProgress).toList();

  @override
  Widget build(BuildContext context) {
    final totalActive = _activeDeliveries.length + _activeMovings.length;

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Missions'),
            if (totalActive > 0) ...[
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.accentOrange,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$totalActive',
                  style: TextStyle(
                      color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accentOrange,
          labelColor: AppTheme.accentOrange,
          unselectedLabelColor: context.appTextSecondary,
          tabs: [
            Tab(
              child: _TabLabel(
                icon: Icons.delivery_dining_outlined,
                label: 'Delivery',
                count: _activeDeliveries.length,
              ),
            ),
            Tab(
              child: _TabLabel(
                icon: Icons.local_shipping_outlined,
                label: 'Moving',
                count: _activeMovings.length,
              ),
            ),
            const Tab(icon: Icon(Icons.car_rental_outlined), text: 'Rental'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Delivery tab ───────────────────────────────────────────────
          _MissionList(
            loading:  _loadingDeliveries,
            error:    _errorDeliveries,
            items:    _deliveries,
            type:     _MissionType.delivery,
            onRefresh: _loadDeliveries,
          ),
          // ── Moving tab ─────────────────────────────────────────────────
          _MissionList(
            loading:  _loadingMovings,
            error:    _errorMovings,
            items:    _movings,
            type:     _MissionType.moving,
            onRefresh: _loadMovings,
          ),
          // ── Rental tab ─────────────────────────────────────────────────
          const _RentalPlaceholder(),
        ],
      ),
    );
  }
}

// ─── Tab label with active-count badge ───────────────────────────────────────

class _TabLabel extends StatelessWidget {
  final IconData icon;
  final String   label;
  final int      count;
  const _TabLabel({required this.icon, required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 18),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 13)),
      if (count > 0) ...[
        const SizedBox(width: 4),
        Container(
          width: 16, height: 16,
          decoration: const BoxDecoration(
              color: AppTheme.accentOrange, shape: BoxShape.circle),
          child: Center(
            child: Text('$count',
                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
          ),
        ),
      ],
    ]);
  }
}

// ─── Mission type ─────────────────────────────────────────────────────────────

enum _MissionType { delivery, moving }

// ─── Mission list tab ─────────────────────────────────────────────────────────

class _MissionList extends StatelessWidget {
  final bool                    loading;
  final String?                 error;
  final List<DeliveryModel>     items;
  final _MissionType            type;
  final Future<void> Function() onRefresh;

  const _MissionList({
    required this.loading,
    required this.error,
    required this.items,
    required this.type,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.accentOrange));
    }

    if (error != null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.error_outline, color: AppTheme.danger, size: 40),
        SizedBox(height: 12),
        Text(error!,
            style: TextStyle(color: context.appTextSecondary),
            textAlign: TextAlign.center),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: onRefresh,
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentOrange),
          child: const Text('Retry'),
        ),
      ]));
    }

    final active    = items.where((d) => d.isAccepted || d.isInProgress).toList();
    final completed = items.where((d) => d.isCompleted || d.isCancelled).toList();

    if (items.isEmpty) {
      final label = type == _MissionType.delivery ? 'delivery' : 'moving';
      return RefreshIndicator(
        onRefresh: onRefresh,
        color: AppTheme.accentOrange,
        child: ListView(padding: EdgeInsets.all(32), children: [
          Icon(
            type == _MissionType.delivery
                ? Icons.delivery_dining_outlined
                : Icons.local_shipping_outlined,
            color: context.appTextSecondary,
            size: 56,
          ),
          SizedBox(height: 16),
          Text('No $label tasks right now',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.appTextSecondary, fontSize: 15)),
          SizedBox(height: 8),
          Text('Accept a job from the home screen\nto see it here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
        ]),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppTheme.accentOrange,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Summary header ──────────────────────────────────────────────
          if (active.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF0F3460), Color(0xFF1A2A4A)]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(children: [
                const Icon(Icons.local_fire_department,
                    color: AppTheme.accentOrange, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(
                      '${active.length} active task${active.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                    const Text(
                      'Tap to refresh for latest status',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ]),
                ),
                IconButton(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh, color: Colors.white70, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ]),
            ),

          // ── Active tasks ────────────────────────────────────────────────
          if (active.isNotEmpty) ...[
            _SectionLabel('Active (${active.length})'),
            ...active.map((d) => _MissionCard(d: d, type: type)),
            const SizedBox(height: 8),
          ],

          // ── Completed / cancelled tasks ─────────────────────────────────
          if (completed.isNotEmpty) ...[
            _SectionLabel('Completed (${completed.length})'),
            ...completed.map((d) => _MissionCard(d: d, type: type)),
          ],
        ],
      ),
    );
  }
}

// ─── Section label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: 8, top: 4),
    child: Text(text,
        style: TextStyle(
            color: context.appTextSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6)),
  );
}

// ─── Progress stepper ─────────────────────────────────────────────────────────

class _ProgressStepper extends StatelessWidget {
  final List<String> steps;
  final int          currentStep; // 0-based index of current active step

  const _ProgressStepper({required this.steps, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(steps.length, (i) {
        final done   = i < currentStep;
        final active = i == currentStep;

        return Expanded(
          child: Column(children: [
            Row(children: [
              // Left connector line
              if (i > 0)
                Expanded(
                  child: Container(
                    height: 2,
                    color: done || active ? AppTheme.success : context.appCardBg,
                  ),
                ),
              // Step dot
              Container(
                width: 18, height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done
                      ? AppTheme.success
                      : active
                          ? AppTheme.accentOrange
                          : context.appCardBg,
                  border: Border.all(
                    color: done
                        ? AppTheme.success
                        : active
                            ? AppTheme.accentOrange
                            : context.appTextSecondary.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: done
                      ? Icon(Icons.check, size: 10, color: Colors.white)
                      : active
                          ? Container(
                              width: 7, height: 7,
                              decoration: BoxDecoration(
                                  color: Colors.white, shape: BoxShape.circle),
                            )
                          : null,
                ),
              ),
              // Right connector line
              if (i < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    color: done ? AppTheme.success : context.appCardBg,
                  ),
                ),
            ]),
            SizedBox(height: 4),
            Text(
              steps[i],
              textAlign: TextAlign.center,
              style: TextStyle(
                color: done || active
                    ? context.appTextPrimary
                    : context.appTextSecondary,
                fontSize: 9,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ]),
        );
      }),
    );
  }
}

// ─── Mission card (read-only, non-tappable) ───────────────────────────────────

class _MissionCard extends StatelessWidget {
  final DeliveryModel d;
  final _MissionType  type;

  const _MissionCard({required this.d, required this.type});

  static const _deliverySteps = ['Accepted', 'Picked Up', 'In Transit', 'Delivered'];
  static const _movingSteps   = ['Accepted', 'Arrived', 'Loading', 'In Transit', 'Done'];

  int _deliveryStep(String status) {
    switch (status) {
      case 'accepted':    return 0;
      case 'in_progress': return 2;
      case 'completed':   return 3;
      default:            return 0;
    }
  }

  int _movingStep(String status) {
    switch (status) {
      case 'accepted':    return 0;
      case 'in_progress': return 3;
      case 'completed':   return 4;
      default:            return 0;
    }
  }

  Color get _borderColor {
    if (d.isCompleted) return AppTheme.success;
    if (d.isCancelled) return AppTheme.danger;
    if (d.isInProgress) return AppTheme.accentOrange;
    return AppTheme.accent.withValues(alpha: 0.4);
  }

  Future<void> _openDetail(BuildContext context) async {
    final user = await ApiService.getSavedUser();
    final driverIdStr = user?.id.toString() ?? 'unknown';
    if (!context.mounted) return;
    // Active jobs open fully interactive so the driver can continue/complete.
    // Only completed/cancelled jobs are shown read-only.
    final ro = d.isCompleted || d.isCancelled;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DriverDeliveryActiveScreen(
          delivery:    d,
          driverIdStr: driverIdStr,
          readOnly:    ro,
        ),
      ),
    );
  }

  Widget build(BuildContext context) {
    final isMoving = type == _MissionType.moving;
    final steps    = isMoving ? _movingSteps : _deliverySteps;
    final step     = isMoving ? _movingStep(d.status) : _deliveryStep(d.status);

    return GestureDetector(
      onTap: () => _openDetail(context),
      child: Container(
      margin: EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor, width: 1.5),
      ),
      child: Padding(
        padding: EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Header: icon + title + status badge ───────────────────────
          Row(children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.accentOrange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isMoving
                    ? Icons.local_shipping_outlined
                    : Icons.delivery_dining_outlined,
                color: AppTheme.accentOrange,
                size: 20,
              ),
            ),
            SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                _title(),
                style: TextStyle(
                    color: context.appTextPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14),
              ),
              Text(
                isMoving ? 'MOVING' : (d.packageSize?.toUpperCase() ?? 'DELIVERY'),
                style: TextStyle(
                    color: AppTheme.accentOrange.withValues(alpha: 0.8),
                    fontSize: 10,
                    fontWeight: FontWeight.w600),
              ),
            ])),
            _StatusBadge(status: d.status),
          ]),

          SizedBox(height: 12),

          // ── Progress stepper ───────────────────────────────────────────
          if (!d.isCancelled)
            _ProgressStepper(steps: steps, currentStep: step),

          if (d.isCancelled)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.cancel_outlined, color: AppTheme.danger, size: 14),
                SizedBox(width: 6),
                Text('This order was cancelled',
                    style: TextStyle(color: AppTheme.danger, fontSize: 12)),
              ]),
            ),

          SizedBox(height: 12),

          // ── Route ─────────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: context.appCardBg, borderRadius: BorderRadius.circular(10)),
            child: Column(children: [
              Row(children: [
                Icon(Icons.circle, color: AppTheme.success, size: 8),
                SizedBox(width: 8),
                Expanded(child: Text(
                  d.pickupAddress,
                  style: TextStyle(color: context.appTextSecondary, fontSize: 12),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                )),
              ]),
              Container(
                margin: EdgeInsets.only(left: 3),
                width: 2, height: 12,
                color: context.appCardBg,
              ),
              Row(children: [
                Icon(Icons.location_on, color: AppTheme.accentOrange, size: 10),
                SizedBox(width: 8),
                Expanded(child: Text(
                  d.dropoffAddress,
                  style: TextStyle(color: context.appTextSecondary, fontSize: 12),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                )),
              ]),
            ]),
          ),

          SizedBox(height: 10),

          // ── Footer: fee + recipient ────────────────────────────────────
          Row(children: [
            if (d.fee > 0) ...[
              Icon(Icons.payments_outlined, color: context.appTextSecondary, size: 14),
              SizedBox(width: 4),
              Text(AppTheme.khr(d.fee),
                  style: TextStyle(
                      color: context.appTextPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
              SizedBox(width: 12),
            ],
            if (d.recipientName != null) ...[
              Icon(Icons.person_outline, color: context.appTextSecondary, size: 14),
              SizedBox(width: 4),
              Expanded(child: Text(
                d.recipientName!,
                style: TextStyle(color: context.appTextSecondary, fontSize: 12),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              )),
            ] else
              const Spacer(),
          ]),
        ]),
      ),
    )); // GestureDetector + Container
  }

  String _title() {
    if (type == _MissionType.moving) {
      return 'Moving #${d.id}';
    }
    if (d.packageDetails.isNotEmpty && d.packageDetails != 'No description') {
      return d.packageDetails.length > 38
          ? '${d.packageDetails.substring(0, 38)}…'
          : d.packageDetails;
    }
    if (d.packageSize != null) {
      return '${d.packageSize![0].toUpperCase()}${d.packageSize!.substring(1)} Package';
    }
    return 'Delivery #${d.id}';
  }
}

// ─── Status badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _label(),
        style: TextStyle(
            color: color, fontSize: 10, fontWeight: FontWeight.w800),
      ),
    );
  }

  String _label() {
    switch (status) {
      case 'accepted':    return 'ACCEPTED';
      case 'in_progress': return 'IN PROGRESS';
      case 'completed':   return 'DONE';
      case 'cancelled':   return 'CANCELLED';
      default:            return status.toUpperCase();
    }
  }

  Color _color() {
    switch (status) {
      case 'accepted':    return AppTheme.accent;
      case 'in_progress': return AppTheme.accentOrange;
      case 'completed':   return AppTheme.success;
      case 'cancelled':   return AppTheme.danger;
      default:            return AppTheme.textSecondary;
    }
  }
}

// ─── Car Rental placeholder tab ───────────────────────────────────────────────

class _RentalPlaceholder extends StatelessWidget {
  const _RentalPlaceholder();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.car_rental_outlined, color: context.appTextSecondary, size: 56),
      SizedBox(height: 16),
      Text('Rental Vehicle missions',
          style: TextStyle(
              color: context.appTextPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
      SizedBox(height: 8),
      Text('Coming soon',
          style: TextStyle(color: context.appTextSecondary, fontSize: 13)),
    ]),
  );
}
