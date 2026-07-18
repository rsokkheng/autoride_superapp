import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class DriverHistoryScreen extends StatefulWidget {
  const DriverHistoryScreen({super.key});

  @override
  State<DriverHistoryScreen> createState() => _DriverHistoryScreenState();
}

class _DriverHistoryScreenState extends State<DriverHistoryScreen> {
  String _filter = 'all';
  final List<Map<String, dynamic>> _trips = [];
  int  _page        = 1;
  bool _loading     = true;
  bool _loadingMore = false;
  bool _hasMore     = true;

  static const _filters = [
    ('all',         'All'),
    ('rides',       'Rides'),
    ('deliveries',  'Deliveries'),
    ('completed',   'Completed'),
    ('cancelled',   'Cancelled'),
  ];

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      setState(() { _loading = true; _page = 1; _hasMore = true; _trips.clear(); });
    } else {
      if (_loadingMore || !_hasMore) return;
      setState(() => _loadingMore = true);
    }

    try {
      final page   = reset ? 1 : _page;
      final result = await ApiService.getDriverTrips(
        page:   page,
        filter: _filter == 'all' ? null : _filter,
      );
      if (!mounted) return;

      final List<dynamic> data = (result['data'] as List<dynamic>?) ?? [];
      final total = (result['total'] as num?)?.toInt() ?? 0;
      final newTrips = data.whereType<Map<String, dynamic>>().toList();

      setState(() {
        if (reset) {
          _trips.clear();
          _page = 1;
        }
        _trips.addAll(newTrips);
        _page       = _page + 1;
        _hasMore    = _trips.length < total && newTrips.isNotEmpty;
        _loading    = false;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() { _loading = false; _loadingMore = false; });
    }
  }

  String _dateLabel(DateTime dt) {
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d     = DateTime(dt.year, dt.month, dt.day);
    if (d == today) return 'Today';
    if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months   = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${weekdays[dt.weekday - 1]}, ${months[dt.month - 1]} ${dt.day}';
  }

  String _timeLabel(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final h  = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final m  = dt.minute.toString().padLeft(2, '0');
      final amPm = dt.hour < 12 ? 'AM' : 'PM';
      return '$h:$m $amPm';
    } catch (_) {
      return '';
    }
  }

  List<MapEntry<String, List<Map<String, dynamic>>>> _groupByDate(
      List<Map<String, dynamic>> trips) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final trip in trips) {
      final raw = (trip['created_at'] as String?) ?? '';
      String label;
      try {
        label = _dateLabel(DateTime.parse(raw).toLocal());
      } catch (_) {
        label = 'Unknown';
      }
      grouped.putIfAbsent(label, () => []).add(trip);
    }
    return grouped.entries.toList();
  }

  Color _serviceColor(String? type) {
    switch (type) {
      case 'delivery': return AppTheme.accentOrange;
      case 'moving':   return const Color(0xFF9C27B0);
      default:         return AppTheme.accent;
    }
  }

  String _serviceLabel(String? type) {
    switch (type) {
      case 'delivery': return 'Delivery';
      case 'moving':   return 'Moving';
      default:         return 'Ride';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () {},
            tooltip: 'Filter',
          ),
        ],
      ),
      body: Column(children: [
        // Filter chips
        Container(
          color: context.appSurface,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filters.map((f) {
                final selected = _filter == f.$1;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      if (_filter == f.$1) return;
                      setState(() => _filter = f.$1);
                      _load(reset: true);
                    },
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 180),
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? AppTheme.accent : context.appCardBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        f.$2,
                        style: TextStyle(
                          color: selected ? Colors.white : context.appTextSecondary,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        Divider(height: 1, color: context.appCardBg),

        // Body
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
              : _trips.isEmpty
                  ? _EmptyState()
                  : RefreshIndicator(
                      onRefresh: () => _load(reset: true),
                      color: AppTheme.accent,
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          if (notification is ScrollEndNotification &&
                              notification.metrics.extentAfter < 120) {
                            _load();
                          }
                          return false;
                        },
                        child: ListView(
                          padding: EdgeInsets.all(16),
                          children: [
                            ..._groupByDate(_trips).expand((entry) => [
                              Padding(
                                padding: EdgeInsets.only(bottom: 10, top: 6),
                                child: Text(
                                  entry.key,
                                  style: TextStyle(
                                    color: context.appTextSecondary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              ...entry.value.map((trip) => _TripCard(
                                trip:          trip,
                                timeLabel:     _timeLabel(trip['created_at'] as String? ?? ''),
                                serviceColor:  _serviceColor(trip['service_type'] as String?),
                                serviceLabel:  _serviceLabel(trip['service_type'] as String?),
                              )),
                            ]),
                            if (_loadingMore)
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: AppTheme.accent, strokeWidth: 2),
                                ),
                              ),
                            if (!_hasMore && _trips.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: Text(
                                    'No more trips',
                                    style: TextStyle(
                                        color: context.appTextSecondary, fontSize: 13),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
        ),
      ]),
    );
  }
}

// ── Trip card ──────────────────────────────────────────────────────────────────

class _TripCard extends StatelessWidget {
  final Map<String, dynamic> trip;
  final String timeLabel;
  final Color  serviceColor;
  final String serviceLabel;

  const _TripCard({
    required this.trip,
    required this.timeLabel,
    required this.serviceColor,
    required this.serviceLabel,
  });

  @override
  Widget build(BuildContext context) {
    final from     = trip['pickup_address']  as String? ?? '--';
    final to       = trip['dropoff_address'] as String? ?? '--';
    final fareKhr  = (trip['fare_khr'] as num?)?.toInt() ?? 0;
    final distKm   = (trip['distance_km'] as num?)?.toDouble();
    final durMin   = (trip['duration_min'] as num?)?.toInt();

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          // Service type chip
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: serviceColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              serviceLabel,
              style: TextStyle(
                color: serviceColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Spacer(),
          Text(
            timeLabel,
            style: TextStyle(color: context.appTextSecondary, fontSize: 12),
          ),
        ]),
        SizedBox(height: 10),

        // From → To
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.circle, color: AppTheme.success, size: 10),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              from,
              style: TextStyle(
                color: context.appTextPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ]),
        Padding(
          padding: EdgeInsets.only(left: 4),
          child: Container(
            width: 1,
            height: 14,
            color: context.appCardBg,
            margin: EdgeInsets.symmetric(vertical: 2),
          ),
        ),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.location_on, color: AppTheme.accentOrange, size: 12),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              to,
              style: TextStyle(color: context.appTextSecondary, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ]),
        SizedBox(height: 10),

        Row(children: [
          if (distKm != null) ...[
            Icon(Icons.route_outlined, color: context.appTextSecondary, size: 13),
            const SizedBox(width: 4),
            Text(
              '${distKm.toStringAsFixed(1)} km',
              style: TextStyle(color: context.appTextSecondary, fontSize: 12),
            ),
            SizedBox(width: 10),
          ],
          if (durMin != null) ...[
            Icon(Icons.timer_outlined, color: context.appTextSecondary, size: 13),
            SizedBox(width: 4),
            Text(
              '$durMin min',
              style: TextStyle(color: context.appTextSecondary, fontSize: 12),
            ),
          ],
          const Spacer(),
          Text(
            '+${AppTheme.khr(fareKhr)}',
            style: const TextStyle(
              color: AppTheme.accent,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ]),
      ]),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.directions_car_outlined,
                color: AppTheme.accent, size: 40),
          ),
          SizedBox(height: 20),
          Text(
            'No trips yet',
            style: TextStyle(
              color: context.appTextPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Your completed trips will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.appTextSecondary, fontSize: 13),
          ),
        ]),
      ),
    );
  }
}
