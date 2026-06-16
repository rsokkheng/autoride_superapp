import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class DriverEarningsScreen extends StatefulWidget {
  const DriverEarningsScreen({super.key});

  @override
  State<DriverEarningsScreen> createState() => _DriverEarningsScreenState();
}

class _DriverEarningsScreenState extends State<DriverEarningsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _periods = [
    ('today', 'Today'),
    ('week',  'This Week'),
    ('month', 'This Month'),
  ];

  Map<String, dynamic> _data     = {'total': 0, 'trips': [], 'trip_count': 0};
  bool   _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _periods.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) _loadData();
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _currentPeriod => _periods[_tabController.index].$1;

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final result = await ApiService.getDriverEarningsSummary(period: _currentPeriod);
      if (!mounted) return;
      setState(() { _data = result; _loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  String _timeLabel(String isoString) {
    try {
      final dt   = DateTime.parse(isoString).toLocal();
      final h    = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final m    = dt.minute.toString().padLeft(2, '0');
      final amPm = dt.hour < 12 ? 'AM' : 'PM';
      return '$h:$m $amPm';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalKhr   = ((_data['total'] as num?) ?? 0).toInt();
    final tripCount  = ((_data['trip_count'] as num?) ?? 0).toInt();
    final hoursOnline= ((_data['hours_online'] as num?) ?? 0).toDouble();
    final avgPerTrip = tripCount > 0 ? totalKhr ~/ tripCount : 0;
    final List<dynamic> tripList = (_data['trips'] as List<dynamic>?) ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Earnings'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: AppTheme.surface,
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.accent,
              indicatorWeight: 3,
              labelColor: AppTheme.accent,
              unselectedLabelColor: AppTheme.textSecondary,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              tabs: _periods.map((p) => Tab(text: p.$2)).toList(),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppTheme.accent,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.accent))
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF00C48C), Color(0xFF00A37A)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00C48C).withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(children: [
                        const Text(
                          'Total Earnings',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppTheme.khr(totalKhr),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: Colors.white24, height: 1),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _SummaryItem(
                              label: 'Trips',
                              value: '$tripCount',
                              icon: Icons.directions_car_outlined,
                            ),
                            Container(
                                width: 1, height: 36, color: Colors.white24),
                            _SummaryItem(
                              label: 'Hours Online',
                              value: '${hoursOnline.toStringAsFixed(1)}h',
                              icon: Icons.access_time_outlined,
                            ),
                            Container(
                                width: 1, height: 36, color: Colors.white24),
                            _SummaryItem(
                              label: 'Avg / Trip',
                              value: AppTheme.khr(avgPerTrip),
                              icon: Icons.trending_up_outlined,
                            ),
                          ],
                        ),
                      ]),
                    ),
                    const SizedBox(height: 24),

                    // Breakdown header
                    const Text(
                      'Breakdown',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (tripList.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Column(children: [
                          Icon(Icons.receipt_long_outlined,
                              color: AppTheme.textSecondary, size: 36),
                          SizedBox(height: 10),
                          Text(
                            'No trips in this period',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ]),
                      )
                    else
                      ...tripList.whereType<Map<String, dynamic>>().map((trip) {
                        final from    = trip['pickup_address']  as String? ?? '--';
                        final to      = trip['dropoff_address'] as String? ?? '--';
                        final fareKhr = (trip['fare_khr'] as num?)?.toInt() ?? 0;
                        final time    = _timeLabel(trip['created_at'] as String? ?? '');

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(children: [
                            Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color: AppTheme.success.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.directions_car,
                                  color: AppTheme.success, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    const Icon(Icons.circle,
                                        color: AppTheme.success, size: 7),
                                    const SizedBox(width: 5),
                                    Expanded(
                                      child: Text(
                                        from,
                                        style: const TextStyle(
                                          color: AppTheme.textPrimary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ]),
                                  const SizedBox(height: 3),
                                  Row(children: [
                                    const Icon(Icons.location_on,
                                        color: AppTheme.accentOrange, size: 9),
                                    const SizedBox(width: 5),
                                    Expanded(
                                      child: Text(
                                        to,
                                        style: const TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ]),
                                  if (time.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      time,
                                      style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '+${AppTheme.khr(fareKhr)}',
                              style: const TextStyle(
                                color: AppTheme.success,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ]),
                        );
                      }),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }
}

// ── Summary stat item ──────────────────────────────────────────────────────────

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Column(children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ]);
}
