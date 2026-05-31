import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/delivery_model.dart';
import '../../services/api_service.dart';

class DriverMissionsScreen extends StatefulWidget {
  const DriverMissionsScreen({super.key});

  @override
  State<DriverMissionsScreen> createState() => _DriverMissionsScreenState();
}

class _DriverMissionsScreenState extends State<DriverMissionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Delivery tab state
  List<DeliveryModel> _deliveries = [];
  bool _loading = true;
  String? _error;
  final Set<int> _accepting = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await ApiService.getDeliveries();
      if (mounted) setState(() { _deliveries = list; _loading = false; });
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _error = 'Failed to load deliveries.'; _loading = false; });
    }
  }

  Future<void> _accept(DeliveryModel d) async {
    setState(() => _accepting.add(d.id));
    try {
      final updated = await ApiService.acceptDelivery(d.id);
      if (!mounted) return;
      setState(() {
        final idx = _deliveries.indexWhere((x) => x.id == updated.id);
        if (idx >= 0) _deliveries[idx] = updated;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Delivery accepted!'),
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
    } finally {
      if (mounted) setState(() => _accepting.remove(d.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Missions'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accentOrange,
          labelColor: AppTheme.accentOrange,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: const [
            Tab(icon: Icon(Icons.delivery_dining_outlined), text: 'Delivery'),
            Tab(icon: Icon(Icons.car_rental_outlined),      text: 'Car Rental'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _DeliveryTab(
            loading:   _loading,
            error:     _error,
            deliveries: _deliveries,
            accepting: _accepting,
            onRefresh: _load,
            onAccept:  _accept,
          ),
          const _RentalPlaceholder(),
        ],
      ),
    );
  }
}

// ─── Delivery tab ─────────────────────────────────────────────────────────────

class _DeliveryTab extends StatelessWidget {
  final bool loading;
  final String? error;
  final List<DeliveryModel> deliveries;
  final Set<int> accepting;
  final Future<void> Function() onRefresh;
  final Future<void> Function(DeliveryModel) onAccept;

  const _DeliveryTab({
    required this.loading,
    required this.error,
    required this.deliveries,
    required this.accepting,
    required this.onRefresh,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.accentOrange));
    }

    if (error != null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.error_outline, color: AppTheme.danger, size: 40),
        const SizedBox(height: 12),
        Text(error!, style: const TextStyle(color: AppTheme.textSecondary), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: onRefresh,
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentOrange),
          child: const Text('Retry'),
        ),
      ]));
    }

    final requested   = deliveries.where((d) => d.isRequested).toList();
    final active      = deliveries.where((d) => d.isAccepted || d.isInProgress).toList();
    final completed   = deliveries.where((d) => d.isCompleted || d.isCancelled).toList();

    if (deliveries.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        color: AppTheme.accentOrange,
        child: ListView(padding: const EdgeInsets.all(32), children: [
          const Icon(Icons.delivery_dining_outlined, color: AppTheme.textSecondary, size: 56),
          const SizedBox(height: 16),
          const Text('No delivery jobs right now', textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
          const SizedBox(height: 8),
          const Text('Pull to refresh', textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        ]),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppTheme.accentOrange,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        // Summary banner
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF0F3460), Color(0xFF1A2A00)]),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(children: [
            const Icon(Icons.local_fire_department, color: AppTheme.accentOrange, size: 24),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                '${requested.length} new job${requested.length == 1 ? '' : 's'} available',
                style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700),
              ),
              if (active.isNotEmpty)
                Text('${active.length} active delivery',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ])),
          ]),
        ),

        if (active.isNotEmpty) ...[
          _SectionLabel('Active (${active.length})'),
          ...active.map((d) => _DeliveryCard(d: d, accepting: accepting, onAccept: onAccept)),
          const SizedBox(height: 8),
        ],

        if (requested.isNotEmpty) ...[
          _SectionLabel('Available (${requested.length})'),
          ...requested.map((d) => _DeliveryCard(d: d, accepting: accepting, onAccept: onAccept)),
          const SizedBox(height: 8),
        ],

        if (completed.isNotEmpty) ...[
          _SectionLabel('Completed (${completed.length})'),
          ...completed.map((d) => _DeliveryCard(d: d, accepting: accepting, onAccept: onAccept)),
        ],
      ]),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(
      color: AppTheme.textSecondary,
      fontSize: 12,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
    )),
  );
}

class _DeliveryCard extends StatelessWidget {
  final DeliveryModel d;
  final Set<int> accepting;
  final Future<void> Function(DeliveryModel) onAccept;

  const _DeliveryCard({required this.d, required this.accepting, required this.onAccept});

  @override
  Widget build(BuildContext context) {
    final isAccepting = accepting.contains(d.id);
    final statusColor = _statusColor(d.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: d.isAccepted || d.isInProgress
            ? Border.all(color: AppTheme.success, width: 1.5)
            : d.isRequested
                ? Border.all(color: AppTheme.accentOrange.withValues(alpha: 0.5))
                : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.accentOrange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delivery_dining, color: AppTheme.accentOrange, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                _title(d),
                style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 14),
              ),
              Text(
                d.packageSize != null ? d.packageSize!.toUpperCase() : 'DELIVERY',
                style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ])),
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _statusLabel(d.status),
                style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w800),
              ),
            ),
          ]),
          const SizedBox(height: 10),

          // Route
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(10)),
            child: Column(children: [
              Row(children: [
                const Icon(Icons.circle, color: AppTheme.success, size: 8),
                const SizedBox(width: 8),
                Expanded(child: Text(d.pickupAddress,
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.location_on, color: AppTheme.accentOrange, size: 10),
                const SizedBox(width: 8),
                Expanded(child: Text(d.dropoffAddress,
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
            ]),
          ),
          const SizedBox(height: 10),

          // Fee + recipient + action button
          Row(children: [
            if (d.fee > 0) ...[
              const Icon(Icons.payments_outlined, color: AppTheme.textSecondary, size: 14),
              const SizedBox(width: 4),
              Text(AppTheme.khr(d.fee),
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(width: 12),
            ],
            if (d.recipientName != null) ...[
              const Icon(Icons.person_outline, color: AppTheme.textSecondary, size: 14),
              const SizedBox(width: 4),
              Expanded(child: Text(d.recipientName!,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
            ] else
              const Spacer(),

            if (d.isRequested)
              SizedBox(
                height: 34,
                child: ElevatedButton(
                  onPressed: isAccepting ? null : () => onAccept(d),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: isAccepting
                      ? const SizedBox(width: 14, height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Accept', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                ),
              )
            else if (d.isAccepted || d.isInProgress)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.check, color: AppTheme.success, size: 14),
                  SizedBox(width: 4),
                  Text('In Progress', style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.w700, fontSize: 12)),
                ]),
              ),
          ]),

          // Payment method row
          if (d.paymentMethod != 'cash') ...[
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.credit_card_outlined, color: AppTheme.textSecondary, size: 12),
              const SizedBox(width: 4),
              Text(d.paymentMethod.replaceAll('_', ' ').toUpperCase(),
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
            ]),
          ],
        ]),
      ),
    );
  }

  String _title(DeliveryModel d) {
    if (d.packageDetails.isNotEmpty && d.packageDetails != 'No description') {
      return d.packageDetails.length > 40 ? '${d.packageDetails.substring(0, 40)}…' : d.packageDetails;
    }
    if (d.packageSize != null) {
      return '${d.packageSize![0].toUpperCase()}${d.packageSize!.substring(1)} Package';
    }
    return 'Delivery #${d.id}';
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'requested':   return 'NEW';
      case 'accepted':    return 'ACCEPTED';
      case 'in_progress': return 'IN PROGRESS';
      case 'completed':   return 'DONE';
      case 'cancelled':   return 'CANCELLED';
      default:            return status.toUpperCase();
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'requested':   return AppTheme.accentOrange;
      case 'accepted':    return AppTheme.accent;
      case 'in_progress': return AppTheme.success;
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
  Widget build(BuildContext context) => const Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.car_rental_outlined, color: AppTheme.textSecondary, size: 56),
      SizedBox(height: 16),
      Text('Car Rental missions', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
      SizedBox(height: 8),
      Text('Coming soon', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
    ]),
  );
}
