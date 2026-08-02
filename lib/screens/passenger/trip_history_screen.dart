import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:autoride_superapp/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/trip_model.dart';
import 'rate_driver_screen.dart';
import 'trip_tracking_screen.dart';
import 'delivery_tracking_screen.dart';
import 'ride_booking.dart';

class TripHistoryScreen extends StatefulWidget {
  const TripHistoryScreen({super.key});

  @override
  State<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends State<TripHistoryScreen> {
  // ── Filter state ──────────────────────────────────────────────────────────
  String _dateFilter = 'recent'; // recent | day | month
  String _typeFilter = 'all'; // all | ride | delivery | moving
  String _statusFilter = 'all'; // all | completed | cancelled
  String? _selectedDate; // 2026-06-15
  String? _selectedMonth; // 2026-06
  String _selectedMonthLabel = '';

  // ── Data ──────────────────────────────────────────────────────────────────
  TripListResult? _result;
  List<TripMonthOption> _months = [];
  bool _loading = true;
  bool _loadingMore = false;
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
          _selectedMonth = months.first.value;
          _selectedMonthLabel = months.first.label;
        }
      });
    } catch (_) {}
  }

  Future<void> _loadTrips({bool reset = false}) async {
    if (!reset && (_loadingMore || !(_result?.hasMore ?? false))) return;

    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else {
      setState(() => _loadingMore = true);
    }

    try {
      final page = reset ? 1 : (_result?.currentPage ?? 0) + 1;
      final res = await ApiService.getTrips(
        filter: _dateFilter,
        date: _dateFilter == 'day' ? _selectedDate : null,
        month: _dateFilter == 'month' ? _selectedMonth : null,
        type: _typeFilter,
        status: _statusFilter,
        page: page,
      );
      if (!mounted) return;
      setState(() {
        if (reset) {
          _result = res;
        } else {
          _result = TripListResult(
            trips: [...(_result?.trips ?? []), ...res.trips],
            grouped: res.grouped,
            stats: res.stats ?? _result?.stats,
            filter: res.filter,
            type: res.type,
            currentPage: res.currentPage,
            lastPage: res.lastPage,
            total: res.total,
            hasMore: res.hasMore,
          );
        }
        _loading = false;
        _loadingMore = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  void _applyFilter() => _loadTrips(reset: true);

  static const _typeLabels = {
    'ride': 'Ride',
    'delivery': 'Delivery',
    'moving': 'Moving'
  };
  static const _statusLabels = {
    'completed': 'Completed',
    'cancelled': 'Cancelled'
  };

  String _filterSummary() {
    final parts = <String>[];
    if (_dateFilter == 'day' && _selectedDate != null) {
      parts.add(_selectedDate!);
    } else if (_dateFilter == 'month' && _selectedMonthLabel.isNotEmpty) {
      parts.add(_selectedMonthLabel);
    }
    if (_typeFilter != 'all')
      parts.add(_typeLabels[_typeFilter] ?? _typeFilter);
    if (_statusFilter != 'all')
      parts.add(_statusLabels[_statusFilter] ?? _statusFilter);
    return parts.isEmpty ? 'All trips' : parts.join(' · ');
  }

  Future<void> _openFilterSheet() async {
    final result = await showModalBottomSheet<_FilterSheetResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.appSurface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _FilterSheet(
        dateFilter: _dateFilter,
        selectedDate: _selectedDate,
        selectedMonth: _selectedMonth,
        selectedMonthLabel: _selectedMonthLabel,
        typeFilter: _typeFilter,
        statusFilter: _statusFilter,
        months: _months,
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _dateFilter = result.dateFilter;
      _selectedDate = result.selectedDate;
      _selectedMonth = result.selectedMonth;
      _selectedMonthLabel = result.selectedMonthLabel;
      _typeFilter = result.typeFilter;
      _statusFilter = result.statusFilter;
    });
    _applyFilter();
  }

  @override
  Widget build(BuildContext context) {
    final stats = _result?.stats;

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appBackground,
        elevation: 0,
        title: Text('Trip',
            style: TextStyle(
                color: context.appTextPrimary, fontWeight: FontWeight.w700)),
        iconTheme: IconThemeData(color: context.appTextPrimary),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: context.appTextSecondary),
            onPressed: () => _loadTrips(reset: true),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Stats bar ──────────────────────────────────────────────────
          _StatsBar(stats: stats),

          // ── Filter bar (opens filter bottom sheet) ──────────────────────
          _FilterBar(
            summary: _filterSummary(),
            active: _dateFilter != 'recent' ||
                _typeFilter != 'all' ||
                _statusFilter != 'all',
            onTap: _openFilterSheet,
          ),

          // ── Body ───────────────────────────────────────────────────────
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.accent));
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
              child: const Text('Retry',
                  style: TextStyle(color: AppTheme.primary)),
            ),
          ]),
        ),
      );
    }

    final grouped = _result?.grouped ?? [];
    final flat = _result?.trips ?? [];

    // Show grouped months view when filter=recent and server returned groups
    if (_dateFilter == 'recent' && grouped.isNotEmpty) {
      return _GroupedList(
        groups: grouped,
        hasMore: _result?.hasMore ?? false,
        loadingMore: _loadingMore,
        onLoadMore: () => _loadTrips(),
        onRate: _openRate,
      );
    }

    // Flat list for day / month / or recent without groups
    if (flat.isEmpty) {
      return Center(
        child: Text('No trips found',
            style: TextStyle(color: context.appTextSecondary, fontSize: 15)),
      );
    }
    return _FlatList(
      trips: flat,
      hasMore: _result?.hasMore ?? false,
      loadingMore: _loadingMore,
      onLoadMore: () => _loadTrips(),
      onRate: _openRate,
    );
  }

  void _openRate(TripModel trip) {
    if (!trip.canRate && trip.type != 'ride') return;
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RateDriverScreen(
            rideId: trip.id,
            driverName: trip.otherParty?.name ?? 'Driver',
            fare: AppTheme.khr(trip.amount),
            distanceKm: 0,
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
        color: const Color(0xFF00B14F),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Bubble('Total', '${stats?.totalTrips ?? '--'}',
              Icons.receipt_long_outlined),
          _Vdivider(),
          _Bubble('Done', '${stats?.completed ?? '--'}',
              Icons.check_circle_outline),
          _Vdivider(),
          _Bubble(
              'Spent',
              stats != null ? AppTheme.khr(stats!.totalSpentKhr) : '--',
              Icons.account_balance_wallet_outlined),
        ],
      ),
    );
  }
}

class _Vdivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
      width: 1, height: 32, color: Colors.white.withValues(alpha: 0.15));
}

class _Bubble extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _Bubble(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) => Column(children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 15)),
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75), fontSize: 10)),
      ]);
}

// ─── Compact filter bar ─────────────────────────────────────────────────────
class _FilterBar extends StatelessWidget {
  final String summary;
  final bool active;
  final VoidCallback onTap;

  const _FilterBar(
      {required this.summary, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: active
                  ? AppTheme.accent.withValues(alpha: 0.1)
                  : context.appSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: active ? AppTheme.accent : Colors.transparent),
            ),
            child: Row(children: [
              Icon(Icons.tune_rounded,
                  color: active ? AppTheme.accent : context.appTextSecondary,
                  size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(summary,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: active ? AppTheme.accent : context.appTextPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    )),
              ),
              Icon(Icons.keyboard_arrow_down_rounded,
                  color: active ? AppTheme.accent : context.appTextSecondary,
                  size: 20),
            ]),
          ),
        ),
      );
}

// ─── Filter bottom sheet ────────────────────────────────────────────────────

class _FilterSheetResult {
  final String dateFilter;
  final String? selectedDate;
  final String? selectedMonth;
  final String selectedMonthLabel;
  final String typeFilter;
  final String statusFilter;

  const _FilterSheetResult({
    required this.dateFilter,
    required this.selectedDate,
    required this.selectedMonth,
    required this.selectedMonthLabel,
    required this.typeFilter,
    required this.statusFilter,
  });
}

class _FilterSheet extends StatefulWidget {
  final String dateFilter;
  final String? selectedDate;
  final String? selectedMonth;
  final String selectedMonthLabel;
  final String typeFilter;
  final String statusFilter;
  final List<TripMonthOption> months;

  const _FilterSheet({
    required this.dateFilter,
    required this.selectedDate,
    required this.selectedMonth,
    required this.selectedMonthLabel,
    required this.typeFilter,
    required this.statusFilter,
    required this.months,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String _date = widget.dateFilter;
  late String? _selectedDate = widget.selectedDate;
  late String? _selectedMonth = widget.selectedMonth;
  late String _selectedMonthLabel = widget.selectedMonthLabel;
  late String _type = widget.typeFilter;
  late String _status = widget.statusFilter;

  static const _typeOptions = [
    ('all', 'All', Icons.grid_view_rounded),
    ('ride', 'Ride', Icons.directions_car_outlined),
    ('delivery', 'Delivery', Icons.delivery_dining_outlined),
    ('moving', 'Moving', Icons.local_shipping_outlined),
  ];

  static const _statusOptions = [
    ('all', 'All', AppTheme.accent),
    ('completed', 'Completed', AppTheme.success),
    ('cancelled', 'Cancelled', AppTheme.danger),
  ];

  Future<void> _pickDay() async {
    final now = DateTime.now();
    final pick = await showDatePicker(
      context: context,
      initialDate: _selectedDate != null
          ? DateTime.tryParse(_selectedDate!) ?? now
          : now,
      firstDate: DateTime(2020),
      lastDate: now,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: AppTheme.accent),
        ),
        child: child!,
      ),
    );
    if (pick == null || !mounted) return;
    setState(() {
      _selectedDate = '${pick.year.toString().padLeft(4, '0')}-'
          '${pick.month.toString().padLeft(2, '0')}-'
          '${pick.day.toString().padLeft(2, '0')}';
      _date = 'day';
    });
  }

  void _reset() {
    Navigator.pop(
        context,
        const _FilterSheetResult(
          dateFilter: 'recent',
          selectedDate: null,
          selectedMonth: null,
          selectedMonthLabel: '',
          typeFilter: 'all',
          statusFilter: 'all',
        ));
  }

  void _apply() {
    Navigator.pop(
        context,
        _FilterSheetResult(
          dateFilter: _date,
          selectedDate: _selectedDate,
          selectedMonth: _selectedMonth,
          selectedMonthLabel: _selectedMonthLabel,
          typeFilter: _type,
          statusFilter: _status,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: 20 + MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('Filter Trips',
                  style: TextStyle(
                      color: context.appTextPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w800)),
              const Spacer(),
              TextButton(onPressed: _reset, child: const Text('Reset')),
            ]),
            const SizedBox(height: 16),
            _SheetSectionLabel('Date'),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _Pill(
                  label: 'Recent',
                  active: _date == 'recent',
                  color: AppTheme.accent,
                  onTap: () => setState(() => _date = 'recent')),
              _Pill(
                  label: _date == 'day' && _selectedDate != null
                      ? _selectedDate!
                      : 'By Day',
                  active: _date == 'day',
                  color: AppTheme.accent,
                  icon: Icons.calendar_today_outlined,
                  onTap: _pickDay),
            ]),
            if (widget.months.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.months.map((m) {
                    final active =
                        _date == 'month' && _selectedMonth == m.value;
                    return _Pill(
                      label: m.label,
                      active: active,
                      color: AppTheme.accent,
                      icon: Icons.calendar_month_outlined,
                      onTap: () => setState(() {
                        _date = 'month';
                        _selectedMonth = m.value;
                        _selectedMonthLabel = m.label;
                      }),
                    );
                  }).toList()),
            ],
            const SizedBox(height: 20),
            _SheetSectionLabel('Type'),
            const SizedBox(height: 8),
            Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _typeOptions.map((opt) {
                  final (value, label, icon) = opt;
                  return _Pill(
                    label: label,
                    active: _type == value,
                    color: AppTheme.accentOrange,
                    icon: icon,
                    onTap: () => setState(() => _type = value),
                  );
                }).toList()),
            const SizedBox(height: 20),
            _SheetSectionLabel('Status'),
            const SizedBox(height: 8),
            Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _statusOptions.map((opt) {
                  final (value, label, color) = opt;
                  return _Pill(
                    label: label,
                    active: _status == value,
                    color: color,
                    onTap: () => setState(() => _status = value),
                  );
                }).toList()),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _apply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Apply Filters',
                    style: TextStyle(
                        color: AppTheme.primary, fontWeight: FontWeight.w800)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _SheetSectionLabel extends StatelessWidget {
  final String text;
  const _SheetSectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: TextStyle(
          color: context.appTextSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4));
}

class _Pill extends StatelessWidget {
  final String label;
  final bool active;
  final Color color;
  final IconData? icon;
  final VoidCallback onTap;

  const _Pill({
    required this.label,
    required this.active,
    required this.color,
    this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: active ? color.withValues(alpha: 0.12) : context.appCardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: active ? color : Colors.transparent),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 14, color: active ? color : context.appTextSecondary),
              const SizedBox(width: 5),
            ],
            Text(label,
                style: TextStyle(
                  color: active ? color : context.appTextSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                )),
          ]),
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
    required this.groups,
    required this.hasMore,
    required this.loadingMore,
    required this.onLoadMore,
    required this.onRate,
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
    required this.trips,
    required this.hasMore,
    required this.loadingMore,
    required this.onLoadMore,
    required this.onRate,
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
  final int count;
  const _MonthHeader({required this.month, required this.count});

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(top: 16, bottom: 8),
        child: Row(children: [
          Text(month,
              style: TextStyle(
                  color: context.appTextPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14)),
          SizedBox(width: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
                color: context.appSurface,
                borderRadius: BorderRadius.circular(10)),
            child: Text('$count',
                style:
                    TextStyle(color: context.appTextSecondary, fontSize: 11)),
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
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: loading
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: AppTheme.accent, strokeWidth: 2.5))
              : GestureDetector(
                  onTap: onTap,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                    decoration: BoxDecoration(
                        color: context.appSurface,
                        borderRadius: BorderRadius.circular(20)),
                    child: const Text('Load more',
                        style: TextStyle(
                            color: AppTheme.accent,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
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
      case 'delivery':
        return AppTheme.accentOrange;
      case 'moving':
        return const Color(0xFF9C27B0);
      default:
        return AppTheme.accent;
    }
  }

  IconData get _typeIcon {
    switch (trip.type) {
      case 'delivery':
        return Icons.delivery_dining_outlined;
      case 'moving':
        return Icons.local_shipping_outlined;
      default:
        return Icons.directions_car_outlined;
    }
  }

  Color get _statusColor {
    switch (trip.status) {
      case 'completed':
        return AppTheme.success;
      case 'cancelled':
        return AppTheme.danger;
      case 'in_progress':
        return AppTheme.accentOrange;
      default:
        return AppTheme.textSecondary;
    }
  }

  bool get _isInProgress =>
      trip.status != 'completed' && trip.status != 'cancelled';

  void _openTracking(BuildContext context) {
    final netAmount = trip.amount - trip.discount + trip.tip;
    final pickupLatLng = trip.pickupLat != null && trip.pickupLng != null
        ? LatLng(trip.pickupLat!, trip.pickupLng!)
        : null;
    final destLatLng = trip.dropoffLat != null && trip.dropoffLng != null
        ? LatLng(trip.dropoffLat!, trip.dropoffLng!)
        : null;

    if (trip.type == 'delivery' || trip.type == 'moving') {
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DeliveryTrackingScreen(
              deliveryId: trip.id,
              from: trip.pickup,
              to: trip.dropoff,
              fareDisplay: AppTheme.khr(netAmount),
              serviceType: trip.type,
              recipientName: trip.otherParty?.name ?? 'Recipient',
            ),
          ));
      return;
    }

    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TripTrackingScreen(
            rideId: trip.id,
            driverName: trip.otherParty?.name ?? 'Finding driver...',
            vehicle: trip.vehicle?.type ?? '--',
            vehicleType: trip.vehicle?.type ?? 'motorbike',
            plate: trip.vehicle?.plate ?? '--',
            from: trip.pickup,
            to: trip.dropoff,
            fare: AppTheme.khr(netAmount),
            pickupLatLng: pickupLatLng,
            destLatLng: destLatLng,
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    final netAmount = trip.amount - trip.discount + trip.tip;

    return GestureDetector(
      onTap: _isInProgress ? () => _openTracking(context) : null,
      child: Container(
        margin: EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
            color: context.appSurface, borderRadius: BorderRadius.circular(16)),
        child: Column(children: [
          Padding(
            padding: EdgeInsets.all(14),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Top row: type badge + ref + date
              Row(children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: _typeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(_typeIcon, color: _typeColor, size: 12),
                    SizedBox(width: 4),
                    Text(trip.typeLabel,
                        style: TextStyle(
                            color: _typeColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ]),
                ),
                SizedBox(width: 8),
                Text(trip.ref,
                    style: TextStyle(
                        color: context.appTextSecondary, fontSize: 11)),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(trip.statusLabel,
                      style: TextStyle(
                          color: _statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
              ]),
              SizedBox(height: 10),

              // Route
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Column(children: [
                  Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                          color: _typeColor, shape: BoxShape.circle)),
                  Container(
                      width: 1,
                      height: 18,
                      color: context.appTextSecondary.withValues(alpha: 0.3)),
                  Icon(Icons.location_on,
                      color: AppTheme.accentOrange, size: 10),
                ]),
                SizedBox(width: 10),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(trip.pickup,
                          style: TextStyle(
                              color: context.appTextPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      SizedBox(height: 10),
                      Text(trip.dropoff,
                          style: TextStyle(
                              color: context.appTextSecondary, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ])),
                const SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(AppTheme.khr(netAmount),
                      style: TextStyle(
                          color: _typeColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 15)),
                  if (trip.discount > 0)
                    Text('-${AppTheme.khr(trip.discount)}',
                        style: const TextStyle(
                            color: AppTheme.success, fontSize: 11)),
                  if (trip.tip > 0)
                    Text('+${AppTheme.khr(trip.tip)} tip',
                        style:
                            TextStyle(color: AppTheme.warning, fontSize: 11)),
                ]),
              ]),

              SizedBox(height: 10),
              Divider(color: context.appCardBg, height: 1),
              SizedBox(height: 8),

              // Bottom row: driver / date / rating
              Row(children: [
                if (trip.otherParty != null) ...[
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: _typeColor.withValues(alpha: 0.15),
                    child: Text(
                      trip.otherParty!.name.isNotEmpty
                          ? trip.otherParty!.name[0]
                          : '?',
                      style: TextStyle(
                          color: _typeColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  SizedBox(width: 6),
                  Expanded(
                      child: Text(trip.otherParty!.name,
                          style: TextStyle(
                              color: context.appTextSecondary, fontSize: 12),
                          overflow: TextOverflow.ellipsis)),
                ] else
                  const Spacer(),
                if (trip.rating != null) ...[
                  const Icon(Icons.star_rounded,
                      color: AppTheme.gold, size: 13),
                  const SizedBox(width: 2),
                  Text('${trip.rating!.toStringAsFixed(1)}',
                      style: TextStyle(
                          color: AppTheme.gold,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                  SizedBox(width: 8),
                ],
                Text(trip.dateLabel,
                    style: TextStyle(
                        color: context.appTextSecondary, fontSize: 11)),
              ]),
            ]),
          ),

          // Action row (Rebook / Rate)
          if (trip.canRebook || trip.canRate)
            Container(
              decoration: BoxDecoration(
                color: context.appCardBg,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(children: [
                if (trip.canRebook)
                  Expanded(
                      child: GestureDetector(
                    onTap: () {
                      if (trip.dropoffLat == null || trip.dropoffLng == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('This trip has no destination to rebook.'),
                          behavior: SnackBarBehavior.floating,
                        ));
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RideBookingScreen(
                            initialDestAddress: trip.dropoff,
                            initialDestLatLng:
                                LatLng(trip.dropoffLat!, trip.dropoffLng!),
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.replay_rounded,
                                color: AppTheme.accent, size: 14),
                            SizedBox(width: 5),
                            Text('Book Again',
                                style: TextStyle(
                                    color: AppTheme.accent,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                          ]),
                    ),
                  )),
                if (trip.canRebook && trip.canRate)
                  Container(width: 1, height: 36, color: context.appSurface),
                if (trip.canRate)
                  Expanded(
                      child: GestureDetector(
                    onTap: () => onRate(trip),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.star_outline_rounded,
                                color: AppTheme.warning, size: 14),
                            SizedBox(width: 5),
                            Text('Rate',
                                style: TextStyle(
                                    color: AppTheme.warning,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                          ]),
                    ),
                  )),
              ]),
            ),
        ]),
      ),
    );
  }
}
