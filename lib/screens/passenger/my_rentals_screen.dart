import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../widgets/responsive.dart';
import '../../l10n/app_localizations.dart';

const _purple      = Color(0xFF7C3AED);

Color _mint(BuildContext c) => AppTheme.accent.withValues(
    alpha: Theme.of(c).brightness == Brightness.dark ? 0.16 : 0.08);

enum _Sort { newest, oldest, priceHigh, priceLow }

class MyRentalsScreen extends StatefulWidget {
  const MyRentalsScreen({super.key});
  @override
  State<MyRentalsScreen> createState() => _MyRentalsScreenState();
}

class _MyRentalsScreenState extends State<MyRentalsScreen> {
  static const _statuses = <String?>[null, 'pending', 'confirmed', 'completed', 'cancelled'];

  final _searchCtrl = TextEditingController();
  bool    _searching = false;
  String? _status;
  _Sort   _sort = _Sort.newest;

  bool    _loading = true;
  String? _error;
  List<Map<String, dynamic>> _rentals = [];

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await ApiService.getRentalHistory(status: _status);
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

  void _selectStatus(String? s) {
    if (s == _status) return;
    setState(() => _status = s);
    _load();
  }

  // Search + sort are applied locally on top of the server's status filter.
  List<Map<String, dynamic>> get _visible {
    final q = _searchCtrl.text.trim().toLowerCase();
    final list = q.isEmpty
        ? [..._rentals]
        : _rentals.where((r) {
            final product = r['product'] as Map<String, dynamic>?;
            final id = (r['rental_id'] ?? r['order_id'] ?? r['id'])?.toString() ?? '';
            return [product?['title'], r['pickup_location'], r['vehicle_type'], id]
                .whereType<Object>()
                .any((v) => v.toString().toLowerCase().contains(q));
          }).toList();
    num price(Map<String, dynamic> r) => (r['total'] as num?) ?? 0;
    String created(Map<String, dynamic> r) => r['created_at'] as String? ?? '';
    switch (_sort) {
      case _Sort.newest:    list.sort((a, b) => created(b).compareTo(created(a)));
      case _Sort.oldest:    list.sort((a, b) => created(a).compareTo(created(b)));
      case _Sort.priceHigh: list.sort((a, b) => price(b).compareTo(price(a)));
      case _Sort.priceLow:  list.sort((a, b) => price(a).compareTo(price(b)));
    }
    return list;
  }

  String _sortLabel(AppLocalizations l, _Sort s) => switch (s) {
    _Sort.newest    => l.sortNewest,
    _Sort.oldest    => l.sortOldest,
    _Sort.priceHigh => l.sortPriceHigh,
    _Sort.priceLow  => l.sortPriceLow,
  };

  void _openSortSheet() {
    final l = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: context.appSurface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: context.appCardBg,
                    borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 14),
            Text(l.sortBy, style: TextStyle(color: context.appTextPrimary,
                fontWeight: FontWeight.w800, fontSize: 17)),
            const SizedBox(height: 8),
            for (final s in _Sort.values)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_sortLabel(l, s), style: TextStyle(
                    color: context.appTextPrimary,
                    fontWeight: s == _sort ? FontWeight.w700 : FontWeight.w500)),
                trailing: s == _sort
                    ? const Icon(Icons.check_circle_rounded, color: AppTheme.accent)
                    : null,
                onTap: () {
                  setState(() => _sort = s);
                  Navigator.pop(ctx);
                },
              ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final canPop = Navigator.canPop(context);
    final labels = [l.all, l.pendingStatus, l.confirmed, l.completed, l.cancelled2];
    const icons = [
      Icons.directions_car_filled_rounded,
      Icons.hourglass_top_rounded,
      Icons.event_available_rounded,
      Icons.task_alt_rounded,
      Icons.cancel_outlined,
    ];
    final visible = _loading || _error != null ? const <Map<String, dynamic>>[] : _visible;

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: Colors.black12,
        automaticallyImplyLeading: false,
        toolbarHeight: 64,
        centerTitle: true,
        leadingWidth: canPop ? 64 : null,
        leading: canPop
            ? Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 4, 10),
                child: _CircleIconBtn(
                  icon: Icons.arrow_back_ios_new_rounded, size: 16,
                  onTap: () => Navigator.pop(context),
                ),
              )
            : null,
        title: _searching
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: TextStyle(color: context.appTextPrimary, fontSize: 15),
                decoration: InputDecoration(
                  hintText: l.searchRentalsHint,
                  hintStyle: TextStyle(color: context.appTextSecondary, fontSize: 15),
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              )
            : Text(l.myRentals, style: TextStyle(color: context.appTextPrimary,
                fontWeight: FontWeight.w800, fontSize: 18)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: SizedBox(
              width: 44, height: 44,
              child: _CircleIconBtn(
                icon: _searching ? Icons.close_rounded : Icons.search_rounded,
                onTap: () => setState(() {
                  _searching = !_searching;
                  if (!_searching) _searchCtrl.clear();
                }),
              ),
            ),
          ),
        ],
      ),
      body: Column(children: [
        // Status chips
        SizedBox(
          height: 60,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: responsivePadding(context, top: 6, bottom: 10),
            itemCount: _statuses.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) => _StatusChip(
              icon: icons[i],
              label: labels[i],
              active: _statuses[i] == _status,
              onTap: () => _selectStatus(_statuses[i]),
            ),
          ),
        ),

        // Sort + result count
        Padding(
          padding: responsivePadding(context, top: 4, bottom: 8),
          child: Container(
            padding: const EdgeInsets.fromLTRB(8, 8, 14, 8),
            decoration: BoxDecoration(
              color: _mint(context),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _openSortSheet,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                        width: 34, height: 34,
                        decoration: BoxDecoration(
                            color: context.appSurface, shape: BoxShape.circle),
                        child: const Icon(Icons.swap_vert_rounded, color: AppTheme.accent, size: 20),
                      ),
                      const SizedBox(width: 10),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 180),
                        child: Text(
                          _sort == _Sort.newest ? l.sortBy : _sortLabel(l, _sort),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: context.appTextPrimary,
                              fontWeight: FontWeight.w700, fontSize: 14)),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                            color: context.appSurface, shape: BoxShape.circle),
                        child: Icon(Icons.arrow_drop_down_rounded,
                            color: context.appTextPrimary, size: 22),
                      ),
                    ]),
                  ),
                ),
              ),
              const Spacer(),
              if (!_loading && _error == null)
                Text('${visible.length} ${l.results}', style: TextStyle(
                    color: context.appTextSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
            ]),
          ),
        ),

        Expanded(child: _buildBody(context, visible)),
      ]),
    );
  }

  Widget _buildBody(BuildContext context, List<Map<String, dynamic>> visible) {
    final l = AppLocalizations.of(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.accent, strokeWidth: 2));
    }
    if (_error != null) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, color: AppTheme.danger, size: 40),
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center,
              style: TextStyle(color: context.appTextSecondary, fontSize: 13)),
          const SizedBox(height: 12),
          TextButton(onPressed: _load, child: Text(l.retry,
              style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w700))),
        ]),
      ));
    }
    if (visible.isEmpty) {
      return RefreshIndicator(
        color: AppTheme.accent,
        onRefresh: _load,
        child: ListView(children: [
          const SizedBox(height: 100),
          Center(child: Container(
            width: 88, height: 88,
            decoration: BoxDecoration(color: _mint(context), shape: BoxShape.circle),
            child: const Icon(Icons.electric_rickshaw, color: AppTheme.accent, size: 42),
          )),
          const SizedBox(height: 16),
          Center(child: Text(l.noRentalsFound, style: TextStyle(
              color: context.appTextSecondary, fontWeight: FontWeight.w600, fontSize: 15))),
        ]),
      );
    }
    return RefreshIndicator(
      color: AppTheme.accent,
      onRefresh: _load,
      child: ListView.separated(
        padding: responsivePadding(context, top: 6, bottom: 24),
        itemCount: visible.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (_, i) => _RentalCard(r: visible[i], onRefresh: _load),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _CircleIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  const _CircleIconBtn({required this.icon, required this.onTap, this.size = 22});

  @override
  Widget build(BuildContext context) => Material(
    color: _mint(context),
    shape: const CircleBorder(),
    child: InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Center(child: Icon(icon, color: context.appTextPrimary, size: size)),
    ),
  );
}

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _StatusChip({required this.icon, required this.label,
      required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fg = active ? Colors.white : context.appTextPrimary;
    return Material(
      color: active ? AppTheme.accent : context.appSurface,
      borderRadius: BorderRadius.circular(22),
      elevation: active ? 2 : 0.5,
      shadowColor: active ? AppTheme.accent.withValues(alpha: 0.4) : Colors.black12,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: fg, size: 18),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: fg,
                fontWeight: active ? FontWeight.w800 : FontWeight.w600, fontSize: 13)),
          ]),
        ),
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
    'confirmed'  => AppTheme.confirmBlue,
    'completed'  => AppTheme.accent,
    'cancelled'  => AppTheme.danger,
    _            => const Color(0xFFF59E0B),   // pending → amber
  };

  IconData _statusIcon(String s) => switch (s) {
    'confirmed'  => Icons.event_available_rounded,
    'completed'  => Icons.task_alt_rounded,
    'cancelled'  => Icons.cancel_rounded,
    _            => Icons.hourglass_top_rounded,
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

  // 'aba_pay' → 'Aba Pay'
  String _payLabel(String raw) => raw
      .split(RegExp(r'[_\s]+'))
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join(' ');

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
    final l         = AppLocalizations.of(context);
    final source    = r['source']    as String? ?? 'car_rental';
    final isOrder   = source == 'marketplace_order';
    final product   = r['product']  as Map<String, dynamic>?;
    final user      = r['user']     as Map<String, dynamic>?;
    final vtype     = r['vehicle_type']    as String?;
    final title     = product?['title'] as String? ?? _titleFor(context, vtype);
    final image     = product?['image'] as String?;
    final status    = r['status']   as String? ?? 'pending';
    final sc        = _statusColor(status);
    final id        = ((r['rental_id'] ?? r['order_id'] ?? r['id']) as num?)?.toInt() ?? 0;
    final days      = (r['days']        as num?)?.toInt();
    final daily     = r['daily_rate']   as num?;
    final total     = r['total']        as num?;
    final pay       = r['payment_method'] as String?;
    final pickup    = r['pickup_location'] as String?;
    final canCancel = status == 'pending' || status == 'confirmed';

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16, offset: const Offset(0, 5))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Photo + status badge
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 124, height: 150,
              child: Stack(fit: StackFit.expand, children: [
                image != null
                    ? Image.network(image, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(context, vtype))
                    : _placeholder(context, vtype),
                Positioned(top: 8, left: 8, right: 8,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: sc,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(_statusIcon(status), color: Colors.white, size: 12),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(_statusLabel(context, status),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white,
                                  fontWeight: FontWeight.w700, fontSize: 10)),
                        ),
                      ]),
                    ),
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(width: 12),

          // Title, tags, location, dates
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: context.appTextPrimary,
                        fontWeight: FontWeight.w800, fontSize: 15, height: 1.3)),
                const SizedBox(height: 8),
                Wrap(spacing: 6, runSpacing: 6, children: [
                  _Tag(
                    icon: isOrder ? Icons.storefront_rounded : Icons.bolt_rounded,
                    label: isOrder ? l.marketplace : l.rentalVehicleBadge,
                    color: isOrder ? AppTheme.accent : _purple,
                  ),
                  _Tag(
                    label: '${isOrder ? l.orderHashPrefix : l.rentalHashPrefix}$id',
                    color: AppTheme.confirmBlue,
                  ),
                ]),
                const SizedBox(height: 10),
                if (pickup != null) ...[
                  _InfoRow(icon: Icons.location_on_outlined, value: pickup),
                  const SizedBox(height: 6),
                ],
                _InfoRow(
                  icon: Icons.calendar_month_outlined,
                  value: '${_date(r['start_date'] as String?)}  →  ${_date(r['end_date'] as String?)}',
                ),
                if (user != null) ...[
                  const SizedBox(height: 6),
                  _InfoRow(icon: Icons.person_outline_rounded,
                      value: '${user['name'] ?? ''}'
                          '${user['phone'] != null ? '  ·  ${user['phone']}' : ''}'),
                ],
              ]),
            ),
          ),
        ]),

        // Stat tiles
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _StatTile(
              icon: Icons.timelapse_rounded,
              label: l.daysCapLabel,
              value: days != null ? '$days' : '—')),
          const SizedBox(width: 8),
          Expanded(child: _StatTile(
              icon: Icons.sell_outlined,
              label: l.dailyRateLabel,
              value: _usd(daily))),
          if (pay != null && pay.isNotEmpty) ...[
            const SizedBox(width: 8),
            Expanded(child: _StatTile(
                icon: Icons.account_balance_wallet_outlined,
                label: l.paymentMethod,
                value: _payLabel(pay))),
          ],
        ]),

        // Total + action
        const SizedBox(height: 12),
        Row(children: [
          const SizedBox(width: 4),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.total, style: TextStyle(color: context.appTextSecondary, fontSize: 11)),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(_usd(total), style: const TextStyle(color: AppTheme.accent,
                    fontWeight: FontWeight.w900, fontSize: 24, height: 1.15)),
              ),
            ]),
          ),
          if (canCancel)
            OutlinedButton.icon(
              onPressed: () => _cancel(context),
              icon: const Icon(Icons.close_rounded, size: 18),
              label: Text(l.cancelRentalTitle),
              // Same size/shape as AppTheme.confirmButtonStyle, outlined.
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.danger,
                side: const BorderSide(color: AppTheme.danger, width: 1.3),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                minimumSize: const Size(0, 44),
                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
        ]),
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
    color: _mint(context),
    child: Center(child: Icon(_vehicleIcon(vtype),
        size: 48, color: AppTheme.accent.withValues(alpha: 0.5))),
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

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  const _Tag({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      if (icon != null) ...[
        Icon(icon, color: color, size: 13),
        const SizedBox(width: 4),
      ],
      Flexible(
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
      ),
    ]),
  );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String value;
  const _InfoRow({required this.icon, required this.value});
  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Icon(icon, size: 15, color: context.appTextSecondary),
    const SizedBox(width: 6),
    Expanded(child: Text(value,
        style: TextStyle(color: context.appTextSecondary, fontSize: 12),
        maxLines: 2, overflow: TextOverflow.ellipsis)),
  ]);
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _StatTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
    decoration: BoxDecoration(
      color: context.appSurface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: context.appCardBg, width: 1.2),
    ),
    child: Row(children: [
      Icon(icon, color: AppTheme.accent, size: 20),
      const SizedBox(width: 8),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: context.appTextSecondary, fontSize: 10)),
          const SizedBox(height: 2),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: context.appTextPrimary,
                  fontWeight: FontWeight.w700, fontSize: 13)),
        ]),
      ),
    ]),
  );
}
