import 'package:flutter/material.dart';
import 'package:autoride_superapp/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/trip_model.dart';
import 'rate_driver_screen.dart';

class TripHistoryScreen extends StatefulWidget {
  const TripHistoryScreen({super.key});

  @override
  State<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends State<TripHistoryScreen> {
  // ── Filter state ──────────────────────────────────────────────────────────
  String _dateFilter = 'recent'; // recent | day | month
  String _typeFilter = 'all';    // all | ride | delivery | moving
  String _statusFilter = 'all';  // all | completed | cancelled
  String? _selectedDate;         // 2026-06-15
  String? _selectedMonth;        // 2026-06
  String  _selectedMonthLabel = '';

  // ── Data ──────────────────────────────────────────────────────────────────
  TripListResult? _result;
  List<TripMonthOption> _months = [];
  bool  _loading     = true;
  bool  _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTrips(reset: true);
    _loadMonths();
  }

  Future<void> _loadMonths() async {
    try {
      final months = await ApiService.getTripMonths();
      if (!mounted) return;
      setState(() {
        _months = months;
        if (_selectedMonth == null && months.isNotEmpty) {
          _selectedMonth      = months.first.value;
          _selectedMonthLabel = months.first.label;
        }
      });
    } catch (_) {}
  }

  Future<void> _loadTrips({bool reset = false}) async {
    if (!reset && (_loadingMore || !(_result?.hasMore ?? false))) return;

    if (reset) {
      setState(() { _loading = true; _error = null; });
    } else {
      setState(() => _loadingMore = true);
    }

    try {
      final page = reset ? 1 : (_result?.currentPage ?? 0) + 1;
      final res  = await ApiService.getTrips(
        filter: _dateFilter,
        date:   _dateFilter == 'day'   ? _selectedDate  : null,
        month:  _dateFilter == 'month' ? _selectedMonth : null,
        type:   _typeFilter,
        status: _statusFilter,
        page:   page,
      );
      if (!mounted) return;
      setState(() {
        if (reset) {
          _result = res;
        } else {
          _result = TripListResult(
            trips:       [...(_result?.trips ?? []), ...res.trips],
            grouped:     res.grouped,
            stats:       res.stats ?? _result?.stats,
            filter:      res.filter,
            type:        res.type,
            currentPage: res.currentPage,
            lastPage:    res.lastPage,
            total:       res.total,
            hasMore:     res.hasMore,
          );
        }
        _loading     = false;
        _loadingMore = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() { _error = e.message; _loading = false; _loadingMore = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; _loadingMore = false; });
    }
  }

  void _applyFilter() => _loadTrips(reset: true);

  Future<void> _pickDay() async {
    final now  = DateTime.now();
    final pick = await showDatePicker(
      context:     context,
      initialDate: _selectedDate != null ? DateTime.tryParse(_selectedDate!) ?? now : now,
      firstDate:   DateTime(2020),
      lastDate:    now,
      builder:     (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: AppTheme.accent),
        ),
        child: child!,
      ),
    );
    if (pick == null || !mounted) return;
    setState(() {
      _selectedDate  = '${pick.year.toString().padLeft(4, '0')}-'
          '${pick.month.toString().padLeft(2, '0')}-'
          '${pick.day.toString().padLeft(2, '0')}';
      _dateFilter    = 'day';
    });
    _applyFilter();
  }

  @override
  Widget build(BuildContext context) {
    final stats = _result?.stats;

    return Scaffold(
      backgroundColor: AppTheme.primary,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        elevation: 0,
        title: const Text('Trip History',
            style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.textSecondary),
            onPressed: () => _loadTrips(reset: true),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Stats bar ──────────────────────────────────────────────────
          _StatsBar(stats: stats),

          // ── Date filter (Recent / Day / Month) ─────────────────────────
          _DateFilterRow(
            selected:       _dateFilter,
            selectedDate:   _selectedDate,
            selectedMonth:  _selectedMonthLabel,
            months:         _months,
            onRecent: () {
              setState(() => _dateFilter = 'recent');
              _applyFilter();
            },
            onDay: _pickDay,
            onMonthSelected: (opt) {
              setState(() {
                _dateFilter         = 'month';
                _selectedMonth      = opt.value;
                _selectedMonthLabel = opt.label;
              });
              _applyFilter();
            },
          ),

          // ── Type chips (All / Ride / Delivery / Moving) ────────────────
          _ChipRow(
            options: const [
              ('all',      'All',      Icons.grid_view_rounded),
              ('ride',     'Ride',     Icons.directions_car_outlined),
              ('delivery', 'Delivery', Icons.delivery_dining_outlined),
              ('moving',   'Moving',   Icons.local_shipping_outlined),
            ],
            selected: _typeFilter,
            onSelect: (v) {
              setState(() => _typeFilter = v);
              _applyFilter();
            },
          ),

          // ── Status chips (All / Completed / Cancelled) ─────────────────
          _StatusRow(
            selected: _statusFilter,
            onSelect: (v) {
              setState(() => _statusFilter = v);
              _applyFilter();
            },
          ),

          // ── Body ───────────────────────────────────────────────────────
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.accent));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, color: AppTheme.danger, size: 40),
            const SizedBox(height: 12),
            Text(_error!,
                style: const TextStyle(color: AppTheme.danger),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadTrips(reset: true),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
              child: const Text('Retry', style: TextStyle(color: AppTheme.primary)),
            ),
          ]),
        ),
      );
    }

    final grouped = _result?.grouped ?? [];
    final flat    = _result?.trips   ?? [];

    // Show grouped months view when filter=recent and server returned groups
    if (_dateFilter == 'recent' && grouped.isNotEmpty) {
      return _GroupedList(
        groups:      grouped,
        hasMore:     _result?.hasMore ?? false,
        loadingMore: _loadingMore,
        onLoadMore:  () => _loadTrips(),
        onRate:      _openRate,
      );
    }

    // Flat list for day / month / or recent without groups
    if (flat.isEmpty) {
      return const Center(
        child: Text('No trips found',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
      );
    }
    return _FlatList(
      trips:       flat,
      hasMore:     _result?.hasMore ?? false,
      loadingMore: _loadingMore,
      onLoadMore:  () => _loadTrips(),
      onRate:      _openRate,
    );
  }

  void _openRate(TripModel trip) {
    if (!trip.canRate && trip.type != 'ride') return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => RateDriverScreen(
        rideId:      trip.id,
        driverName:  trip.otherParty?.name ?? 'Driver',
        fare:        AppTheme.khr(trip.amount),
        distanceKm:  0,
        durationMin: 0,
      ),
    ));
  }
}

// ─── Stats bar ────────────────────────────────────────────────────────────────
class _StatsBar extends StatelessWidget {
  final TripStats? stats;
  const _StatsBar({this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF00C48C), Color(0xFF00A37A)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Bubble('Total', '${stats?.totalTrips ?? '--'}',     Icons.receipt_long_outlined),
          _Vdivider(),
          _Bubble('Done',  '${stats?.completed  ?? '--'}',     Icons.check_circle_outline),
          _Vdivider(),
          _Bubble('Spent', stats != null ? AppTheme.khr(stats!.totalSpentKhr) : '--',
              Icons.account_balance_wallet_outlined),
        ],
      ),
    );
  }
}

class _Vdivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.15));
}

class _Bubble extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _Bubble(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) => Column(children: [
    Icon(icon, color: Colors.white, size: 18),
    const SizedBox(height: 4),
    Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
    Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 10)),
  ]);
}

// ─── Date filter row ──────────────────────────────────────────────────────────
class _DateFilterRow extends StatelessWidget {
  final String selected;
  final String? selectedDate;
  final String  selectedMonth;
  final List<TripMonthOption> months;
  final VoidCallback onRecent;
  final VoidCallback onDay;
  final void Function(TripMonthOption) onMonthSelected;

  const _DateFilterRow({
    required this.selected,
    required this.selectedDate,
    required this.selectedMonth,
    required this.months,
    required this.onRecent,
    required this.onDay,
    required this.onMonthSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            _DateChip(
              label:    'Recent',
              active:   selected == 'recent',
              onTap:    onRecent,
            ),
            const SizedBox(width: 8),
            _DateChip(
              label:    selectedDate != null && selected == 'day' ? selectedDate! : 'By Day',
              active:   selected == 'day',
              icon:     Icons.calendar_today_outlined,
              onTap:    onDay,
            ),
            const SizedBox(width: 8),
            _DateChip(
              label:    selected == 'month' && selectedMonth.isNotEmpty
                            ? selectedMonth
                            : 'By Month',
              active:   selected == 'month',
              icon:     Icons.calendar_month_outlined,
              onTap:    () => _showMonthPicker(context),
            ),
          ]),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  void _showMonthPicker(BuildContext context) {
    if (months.isEmpty) return;
    showModalBottomSheet(
      context:         context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Select Month',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          ...months.map((m) => ListTile(
            title: Text(m.label,
                style: TextStyle(
                  color: m.value == selectedMonth ? AppTheme.accent : AppTheme.textPrimary,
                  fontWeight: m.value == selectedMonth ? FontWeight.w700 : FontWeight.w400,
                )),
            trailing: m.value == selectedMonth
                ? const Icon(Icons.check, color: AppTheme.accent, size: 18)
                : null,
            onTap: () {
              Navigator.pop(context);
              onMonthSelected(m);
            },
          )),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final String label;
  final bool   active;
  final IconData? icon;
  final VoidCallback onTap;

  const _DateChip({required this.label, required this.active, this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: active ? AppTheme.accent : AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: active ? AppTheme.accent : AppTheme.surface),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, size: 13,
              color: active ? AppTheme.primary : AppTheme.textSecondary),
          const SizedBox(width: 4),
        ],
        Flexible(child: Text(label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: active ? AppTheme.primary : AppTheme.textSecondary,
              fontSize: 12, fontWeight: FontWeight.w600,
            ))),
      ]),
    ),
  );
}

// ─── Type chip row ────────────────────────────────────────────────────────────
class _ChipRow extends StatelessWidget {
  final List<(String, String, IconData)> options;
  final String selected;
  final void Function(String) onSelect;

  const _ChipRow({required this.options, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
    child: Row(
      children: options.map((opt) {
        final (value, label, icon) = opt;
        final active = selected == value;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => onSelect(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: active ? AppTheme.accentOrange.withValues(alpha: 0.12) : AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: active
                        ? AppTheme.accentOrange
                        : Colors.transparent),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon, size: 14,
                    color: active ? AppTheme.accentOrange : AppTheme.textSecondary),
                const SizedBox(width: 5),
                Text(label, style: TextStyle(
                  color: active ? AppTheme.accentOrange : AppTheme.textSecondary,
                  fontSize: 12, fontWeight: FontWeight.w600,
                )),
              ]),
            ),
          ),
        );
      }).toList(),
    ),
  );
}

// ─── Status row ───────────────────────────────────────────────────────────────
class _StatusRow extends StatelessWidget {
  final String selected;
  final void Function(String) onSelect;

  const _StatusRow({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
    child: Row(children: [
      _StatusChip(label: 'All',       value: 'all',       selected: selected, onTap: onSelect),
      const SizedBox(width: 8),
      _StatusChip(label: 'Completed', value: 'completed', selected: selected, onTap: onSelect, color: AppTheme.success),
      const SizedBox(width: 8),
      _StatusChip(label: 'Cancelled', value: 'cancelled', selected: selected, onTap: onSelect, color: AppTheme.danger),
    ]),
  );
}

class _StatusChip extends StatelessWidget {
  final String label, value, selected;
  final void Function(String) onTap;
  final Color color;

  const _StatusChip({
    required this.label, required this.value, required this.selected,
    required this.onTap, this.color = AppTheme.accent,
  });

  bool get _active => selected == value;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => onTap(value),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: _active ? color.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _active ? color : AppTheme.surface),
      ),
      child: Text(label, style: TextStyle(
        color: _active ? color : AppTheme.textSecondary,
        fontSize: 12, fontWeight: FontWeight.w600,
      )),
    ),
  );
}

// ─── Grouped list ─────────────────────────────────────────────────────────────
class _GroupedList extends StatelessWidget {
  final List<TripGroup> groups;
  final bool hasMore, loadingMore;
  final VoidCallback onLoadMore;
  final void Function(TripModel) onRate;

  const _GroupedList({
    required this.groups, required this.hasMore, required this.loadingMore,
    required this.onLoadMore, required this.onRate,
  });

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    for (final g in groups) {
      items.add(_MonthHeader(month: g.month, count: g.count));
      items.addAll(g.trips.map((t) => _TripCard(trip: t, onRate: onRate)));
    }
    if (hasMore) {
      items.add(_LoadMoreButton(loading: loadingMore, onTap: onLoadMore));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: items,
    );
  }
}

// ─── Flat list ────────────────────────────────────────────────────────────────
class _FlatList extends StatelessWidget {
  final List<TripModel> trips;
  final bool hasMore, loadingMore;
  final VoidCallback onLoadMore;
  final void Function(TripModel) onRate;

  const _FlatList({
    required this.trips, required this.hasMore, required this.loadingMore,
    required this.onLoadMore, required this.onRate,
  });

  @override
  Widget build(BuildContext context) => ListView.builder(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
    itemCount: trips.length + (hasMore ? 1 : 0),
    itemBuilder: (_, i) {
      if (i == trips.length) {
        return _LoadMoreButton(loading: loadingMore, onTap: onLoadMore);
      }
      return _TripCard(trip: trips[i], onRate: onRate);
    },
  );
}

// ─── Month header ─────────────────────────────────────────────────────────────
class _MonthHeader extends StatelessWidget {
  final String month;
  final int    count;
  const _MonthHeader({required this.month, required this.count});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Row(children: [
      Text(month,
          style: const TextStyle(
              color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
            color: AppTheme.surface, borderRadius: BorderRadius.circular(10)),
        child: Text('$count', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
      ),
    ]),
  );
}

// ─── Load more ────────────────────────────────────────────────────────────────
class _LoadMoreButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;
  const _LoadMoreButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Center(
      child: loading
          ? const SizedBox(width: 22, height: 22,
              child: CircularProgressIndicator(color: AppTheme.accent, strokeWidth: 2.5))
          : GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                decoration: BoxDecoration(
                    color: AppTheme.surface, borderRadius: BorderRadius.circular(20)),
                child: const Text('Load more',
                    style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            ),
    ),
  );
}

// ─── Trip card ────────────────────────────────────────────────────────────────
class _TripCard extends StatelessWidget {
  final TripModel trip;
  final void Function(TripModel) onRate;
  const _TripCard({required this.trip, required this.onRate});

  Color get _typeColor {
    switch (trip.type) {
      case 'delivery': return AppTheme.accentOrange;
      case 'moving':   return const Color(0xFF9C27B0);
      default:         return AppTheme.accent;
    }
  }

  IconData get _typeIcon {
    switch (trip.type) {
      case 'delivery': return Icons.delivery_dining_outlined;
      case 'moving':   return Icons.local_shipping_outlined;
      default:         return Icons.directions_car_outlined;
    }
  }

  Color get _statusColor {
    switch (trip.status) {
      case 'completed':   return AppTheme.success;
      case 'cancelled':   return AppTheme.danger;
      case 'in_progress': return AppTheme.accentOrange;
      default:            return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final netAmount = trip.amount - trip.discount + trip.tip;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
          color: AppTheme.surface, borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Top row: type badge + ref + date
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: _typeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(_typeIcon, color: _typeColor, size: 12),
                  const SizedBox(width: 4),
                  Text(trip.typeLabel,
                      style: TextStyle(color: _typeColor, fontSize: 11, fontWeight: FontWeight.w700)),
                ]),
              ),
              const SizedBox(width: 8),
              Text(trip.ref,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(trip.statusLabel,
                    style: TextStyle(
                        color: _statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: 10),

            // Route
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Column(children: [
                Container(width: 8, height: 8,
                    decoration: BoxDecoration(color: _typeColor, shape: BoxShape.circle)),
                Container(width: 1, height: 18, color: AppTheme.textSecondary.withValues(alpha: 0.3)),
                const Icon(Icons.location_on, color: AppTheme.accentOrange, size: 10),
              ]),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(trip.pickup,
                    style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 10),
                Text(trip.dropoff,
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ])),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(AppTheme.khr(netAmount),
                    style: TextStyle(color: _typeColor, fontWeight: FontWeight.w800, fontSize: 15)),
                if (trip.discount > 0)
                  Text('-${AppTheme.khr(trip.discount)}',
                      style: const TextStyle(color: AppTheme.success, fontSize: 11)),
                if (trip.tip > 0)
                  Text('+${AppTheme.khr(trip.tip)} tip',
                      style: const TextStyle(color: AppTheme.warning, fontSize: 11)),
              ]),
            ]),

            const SizedBox(height: 10),
            const Divider(color: AppTheme.cardBg, height: 1),
            const SizedBox(height: 8),

            // Bottom row: driver / date / rating
            Row(children: [
              if (trip.otherParty != null) ...[
                CircleAvatar(
                  radius: 12,
                  backgroundColor: _typeColor.withValues(alpha: 0.15),
                  child: Text(
                    trip.otherParty!.name.isNotEmpty ? trip.otherParty!.name[0] : '?',
                    style: TextStyle(color: _typeColor, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(child: Text(trip.otherParty!.name,
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    overflow: TextOverflow.ellipsis)),
              ] else
                const Spacer(),
              if (trip.rating != null) ...[
                const Icon(Icons.star_rounded, color: AppTheme.gold, size: 13),
                const SizedBox(width: 2),
                Text('${trip.rating!.toStringAsFixed(1)}',
                    style: const TextStyle(color: AppTheme.gold, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
              ],
              Text(trip.dateLabel,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
            ]),
          ]),
        ),

        // Action row (Rebook / Rate)
        if (trip.canRebook || trip.canRate)
          Container(
            decoration: const BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(children: [
              if (trip.canRebook)
                Expanded(child: GestureDetector(
                  onTap: () {},
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.replay_rounded, color: AppTheme.accent, size: 14),
                      SizedBox(width: 5),
                      Text('Book Again',
                          style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w600, fontSize: 13)),
                    ]),
                  ),
                )),
              if (trip.canRebook && trip.canRate)
                Container(width: 1, height: 36, color: AppTheme.surface),
              if (trip.canRate)
                Expanded(child: GestureDetector(
                  onTap: () => onRate(trip),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.star_outline_rounded, color: AppTheme.warning, size: 14),
                      SizedBox(width: 5),
                      Text('Rate',
                          style: TextStyle(color: AppTheme.warning, fontWeight: FontWeight.w600, fontSize: 13)),
                    ]),
                  ),
                )),
            ]),
          ),
      ]),
    );
  }
}
