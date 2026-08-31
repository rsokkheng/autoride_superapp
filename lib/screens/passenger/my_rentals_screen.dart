import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../l10n/app_localizations.dart';

class MyRentalsScreen extends StatefulWidget {
  const MyRentalsScreen({super.key});
  @override
  State<MyRentalsScreen> createState() => _MyRentalsScreenState();
}

class _MyRentalsScreenState extends State<MyRentalsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tc;

  static const _statuses = [null, 'pending', 'confirmed', 'completed', 'cancelled'];

  List<({String label, String? status})> _tabs(BuildContext context) {
    final l = AppLocalizations.of(context);
    final labels = [l.all, l.pendingStatus, l.confirmed, l.completed, l.cancelled2];
    return List.generate(_statuses.length,
        (i) => (label: labels[i], status: _statuses[i]));
  }

  @override
  void initState() {
    super.initState();
    _tc = TabController(length: _statuses.length, vsync: this);
  }

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: Colors.black12,
        title: Text(AppLocalizations.of(context).myRentals,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        bottom: TabBar(
          controller: _tc,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: AppTheme.accent,
          indicatorWeight: 3,
          labelColor: AppTheme.accent,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: _tabs(context).map((t) => Tab(text: t.label)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tc,
        children: _tabs(context)
            .map((t) => _RentalList(status: t.status))
            .toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _RentalList extends StatefulWidget {
  final String? status;
  const _RentalList({this.status});
  @override
  State<_RentalList> createState() => _RentalListState();
}

class _RentalListState extends State<_RentalList>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _rentals = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await ApiService.getRentalHistory(status: widget.status);
      if (!mounted) return;
      setState(() { _rentals = list; _loading = false; });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.accent));
    }
    if (_error != null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, color: AppTheme.danger, size: 40),
        const SizedBox(height: 12),
        Text(_error!, textAlign: TextAlign.center,
            style: TextStyle(color: context.appTextSecondary, fontSize: 13)),
        const SizedBox(height: 12),
        TextButton(onPressed: _load, child: Text(AppLocalizations.of(context).retry)),
      ]));
    }
    if (_rentals.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.directions_car_outlined,
            color: context.appTextSecondary.withValues(alpha: 0.4), size: 56),
        const SizedBox(height: 14),
        Text(AppLocalizations.of(context).noRentalsFound,
            style: TextStyle(color: context.appTextSecondary,
                fontWeight: FontWeight.w600, fontSize: 15)),
      ]));
    }
    return RefreshIndicator(
      color: AppTheme.accent,
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _rentals.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _RentalCard(r: _rentals[i], onRefresh: _load),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _RentalCard extends StatelessWidget {
  final Map<String, dynamic> r;
  final VoidCallback onRefresh;
  const _RentalCard({required this.r, required this.onRefresh});

  static final _numFmt = NumberFormat('#,##0.##', 'en_US');
  String _usd(num? v) => v == null ? '—' : '\$${_numFmt.format(v)}';

  String _date(String? raw) {
    if (raw == null) return '—';
    return raw.contains('T') ? raw.split('T').first : raw;
  }

  Color _statusColor(String s) => switch (s) {
    'confirmed'  => AppTheme.success,
    'completed'  => AppTheme.accent,
    'cancelled'  => AppTheme.danger,
    _            => const Color(0xFFF59E0B),   // pending → amber
  };

  IconData _vehicleIcon(String? type) => switch (type) {
    'suv'        => Icons.airport_shuttle,
    'van'        => Icons.directions_bus_outlined,
    'motorcycle' => Icons.two_wheeler,
    'truck'      => Icons.local_shipping_outlined,
    'tuk_tuk'    => Icons.electric_rickshaw,
    'electric'   => Icons.electric_car_outlined,
    _            => Icons.directions_car_outlined,
  };

  Future<void> _cancel(BuildContext context) async {
    final source  = r['source'] as String? ?? 'car_rental';
    final id      = ((r['rental_id'] ?? r['order_id'] ?? r['id']) as num?)?.toInt();
    if (id == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(AppLocalizations.of(context).cancelRentalTitle,
            style: const TextStyle(fontWeight: FontWeight.w800)),
        content: Text(AppLocalizations.of(context).cancelRentalConfirmMsg),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalizations.of(context).no)),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(AppLocalizations.of(context).yesCancelBtn,
                  style: TextStyle(color: AppTheme.danger))),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      if (source == 'marketplace_order') {
        await ApiService.cancelMarketplaceOrder(id);
      } else {
        await ApiService.cancelCarRental(id);
      }
      onRefresh();
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppTheme.danger));
    }
  }

  @override
  Widget build(BuildContext context) {
    final source    = r['source']    as String? ?? 'car_rental';
    final isOrder   = source == 'marketplace_order';
    final product   = r['product']  as Map<String, dynamic>?;
    final user      = r['user']     as Map<String, dynamic>?;
    final title     = product?['title'] as String?
                          ?? _titleFor(context, r['vehicle_type'] as String?);
    final image     = product?['image'] as String?;
    final status    = r['status']   as String? ?? 'pending';
    final sc        = _statusColor(status);
    final id        = ((r['rental_id'] ?? r['order_id'] ?? r['id']) as num?)?.toInt() ?? 0;
    final days      = (r['days']        as num?)?.toInt();
    final daily     = r['daily_rate']   as num?;
    final total     = r['total']        as num?;
    final startDate = _date(r['start_date'] as String?);
    final endDate   = _date(r['end_date']   as String?);
    final pickup    = r['pickup_location'] as String?;
    final vtype     = r['vehicle_type']    as String?;
    final canCancel = status == 'pending' || status == 'confirmed';

    return Container(
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10, offset: const Offset(0, 3))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Status accent bar
        Container(height: 3, color: sc),

        // Image / header
        if (image != null)
          Image.network(image,
              height: 140, width: double.infinity, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder(context, vtype))
        else
          _placeholder(context, vtype),

        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Title row
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: Text(title,
                  style: TextStyle(color: context.appTextPrimary,
                      fontWeight: FontWeight.w700, fontSize: 15),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: sc.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(_statusLabel(context, status),
                    style: TextStyle(color: sc,
                        fontWeight: FontWeight.w700, fontSize: 11)),
              ),
            ]),
            const SizedBox(height: 5),
            // ID + source badge
            Row(children: [
              Text(isOrder ? '${AppLocalizations.of(context).orderHashPrefix}$id' : '${AppLocalizations.of(context).rentalHashPrefix}$id',
                  style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (isOrder ? AppTheme.accent : const Color(0xFF7C3AED))
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(isOrder ? AppLocalizations.of(context).marketplace : AppLocalizations.of(context).rentalVehicleBadge,
                    style: TextStyle(
                      color: isOrder ? AppTheme.accent : const Color(0xFF7C3AED),
                      fontSize: 10, fontWeight: FontWeight.w700,
                    )),
              ),
            ]),
            const SizedBox(height: 12),
            Divider(height: 1, color: context.appCardBg),
            const SizedBox(height: 12),

            // Date range chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: context.appCardBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.date_range_rounded,
                    color: context.appTextSecondary, size: 13),
                const SizedBox(width: 6),
                Text(startDate, style: TextStyle(
                    color: context.appTextPrimary,
                    fontWeight: FontWeight.w600, fontSize: 12)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(Icons.arrow_forward_rounded,
                      color: context.appTextSecondary, size: 12),
                ),
                Text(endDate, style: TextStyle(
                    color: context.appTextPrimary,
                    fontWeight: FontWeight.w600, fontSize: 12)),
              ]),
            ),

            if (pickup != null) ...[
              const SizedBox(height: 8),
              _InfoRow(icon: Icons.location_on_outlined, value: pickup),
            ],
            if (user != null) ...[
              const SizedBox(height: 6),
              _InfoRow(icon: Icons.person_outline_rounded,
                  value: '${user['name'] ?? ''}'
                      '${user['phone'] != null ? '  ·  ${user['phone']}' : ''}'),
            ],

            const SizedBox(height: 12),
            // Pricing row
            Row(children: [
              if (days != null) ...[
                _Chip('${days}d'),
                const SizedBox(width: 6),
              ],
              if (daily != null) ...[
                _Chip('${_usd(daily)}/day'),
              ],
              const Spacer(),
              if (total != null)
                Text(_usd(total),
                    style: const TextStyle(color: AppTheme.accent,
                        fontWeight: FontWeight.w800, fontSize: 16)),
            ]),

            if (canCancel) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _cancel(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.danger,
                    side: const BorderSide(color: AppTheme.danger),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Text(AppLocalizations.of(context).cancelRentalTitle,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ]),
        ),
      ]),
    );
  }

  String _statusLabel(BuildContext context, String status) {
    final l = AppLocalizations.of(context);
    return switch (status) {
      'confirmed' => l.confirmed,
      'completed' => l.completed,
      'cancelled' => l.cancelled2,
      _           => l.pendingStatus,
    };
  }

  Widget _placeholder(BuildContext context, String? vtype) => Container(
    height: 120, color: context.appCardBg,
    child: Center(child: Icon(_vehicleIcon(vtype),
        size: 52, color: context.appTextSecondary.withValues(alpha: 0.35))),
  );

  String _titleFor(BuildContext context, String? type) {
    final l = AppLocalizations.of(context);
    return switch (type) {
      'suv'        => l.suvLabel,
      'van'        => l.van,
      'motorcycle' => l.motorcycle,
      'truck'      => l.truck,
      'tuk_tuk'    => l.tukTuk,
      'electric'   => l.electricVehicleLabel,
      _            => l.sedanLabel,
    };
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String value;
  const _InfoRow({required this.icon, required this.value});
  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Icon(icon, size: 14, color: context.appTextSecondary),
    const SizedBox(width: 6),
    Expanded(child: Text(value,
        style: TextStyle(color: context.appTextSecondary, fontSize: 12),
        maxLines: 2, overflow: TextOverflow.ellipsis)),
  ]);
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip(this.label);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: context.appCardBg,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(label,
        style: TextStyle(color: context.appTextSecondary,
            fontSize: 11, fontWeight: FontWeight.w600)),
  );
}
