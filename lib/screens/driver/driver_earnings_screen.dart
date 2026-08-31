import 'package:autoride_superapp/l10n/app_localizations.dart';
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

  // Fixed at 3 regardless of locale — only the labels need `context`, so the
  // keys stay a plain static list and the labels are resolved per-frame via
  // [_periodLabels].
  static const _periodKeys = ['daily', 'weekly', 'monthly'];

  List<(String, String)> _periodLabels(AppLocalizations l) => [
    ('daily',   l.today),
    ('weekly',  l.thisWeek),
    ('monthly', l.thisMonth),
  ];

  DriverEarningsModel? _data;
  List<DriverEarningsHistoryItem> _history = [];
  bool   _loading = true;
  bool   _historyLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _periodKeys.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) _loadData();
    });
    _loadData();
    _loadHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _currentPeriod => _periodKeys[_tabController.index];

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await ApiService.getDriverEarningsByPeriod(period: _currentPeriod);
      if (!mounted) return;
      setState(() { _data = result; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _loadHistory() async {
    setState(() => _historyLoading = true);
    try {
      final items = await ApiService.getDriverEarningsHistory(days: 30);
      if (!mounted) return;
      setState(() { _history = items; _historyLoading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() => _historyLoading = false);
    }
  }

  Future<void> _refresh() => Future.wait([_loadData(), _loadHistory()]);

  String _dayLabel(BuildContext context, String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      final l  = AppLocalizations.of(context);
      final wd = [l.mon, l.tue, l.wed, l.thu, l.fri, l.sat, l.sun];
      return wd[dt.weekday - 1];
    } catch (_) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data       = _data;
    final tripCount  = data?.tripCount ?? 0;
    final avgPerTrip = tripCount > 0 ? (data!.totalEarnings ~/ tripCount) : 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).myEarnings),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: context.appSurface,
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.accent,
              indicatorWeight: 3,
              labelColor: AppTheme.accent,
              unselectedLabelColor: context.appTextSecondary,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              tabs: _periodLabels(AppLocalizations.of(context))
                  .map((p) => Tab(text: p.$2)).toList(),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppTheme.accent,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
            : _error != null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 80),
                      Icon(Icons.error_outline, color: context.appTextSecondary, size: 40),
                      const SizedBox(height: 12),
                      Center(child: Text(_error!, style: TextStyle(color: context.appTextSecondary))),
                    ],
                  )
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
                            Text(
                              AppLocalizations.of(context).totalEarnings,
                              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AppTheme.khr(data?.totalEarnings ?? 0),
                              style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 16),
                            const Divider(color: Colors.white24, height: 1),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _SummaryItem(
                                  label: AppLocalizations.of(context).rides,
                                  value: AppTheme.khr(data?.rideEarnings ?? 0),
                                  icon: Icons.directions_car_outlined,
                                ),
                                Container(width: 1, height: 36, color: Colors.white24),
                                _SummaryItem(
                                  label: AppLocalizations.of(context).deliveries,
                                  value: AppTheme.khr(data?.deliveryEarnings ?? 0),
                                  icon: Icons.local_shipping_outlined,
                                ),
                                Container(width: 1, height: 36, color: Colors.white24),
                                _SummaryItem(
                                  label: AppLocalizations.of(context).avgTrip,
                                  value: AppTheme.khr(avgPerTrip),
                                  icon: Icons.trending_up_outlined,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Divider(color: Colors.white24, height: 1),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _SummaryItem(
                                  label: AppLocalizations.of(context).trips,
                                  value: '$tripCount',
                                  icon: Icons.confirmation_number_outlined,
                                ),
                                Container(width: 1, height: 36, color: Colors.white24),
                                _SummaryItem(
                                  label: AppLocalizations.of(context).deliveries,
                                  value: '${data?.deliveryCount ?? 0}',
                                  icon: Icons.inventory_2_outlined,
                                ),
                              ],
                            ),
                          ]),
                        ),
                        const SizedBox(height: 24),

                        // 30-day chart
                        Text(
                          AppLocalizations.of(context).last30Days,
                          style: TextStyle(color: context.appTextPrimary, fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 12),
                        _historyLoading
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Center(child: CircularProgressIndicator(color: AppTheme.accent)),
                              )
                            : _EarningsChart(history: _history, dayLabel: (d) => _dayLabel(context, d)),
                        const SizedBox(height: 24),

                        // Breakdown header
                        Text(
                          AppLocalizations.of(context).breakdown,
                          style: TextStyle(color: context.appTextPrimary, fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 12),

                        if (data == null || data.breakdown.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: context.appSurface,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(children: [
                              Icon(Icons.receipt_long_outlined, color: context.appTextSecondary, size: 36),
                              const SizedBox(height: 10),
                              Text(
                                _currentPeriod == 'daily'
                                    ? AppLocalizations.of(context).breakdownIsOnlyAvailableFor
                                    : AppLocalizations.of(context).noEarningsInThisPeriod,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: context.appTextSecondary, fontSize: 14),
                              ),
                            ]),
                          )
                        else
                          ...data.breakdown.map((entry) => Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: context.appSurface,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(children: [
                                  Container(
                                    padding: const EdgeInsets.all(9),
                                    decoration: BoxDecoration(
                                      color: AppTheme.success.withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.calendar_today_outlined, color: AppTheme.success, size: 16),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          entry.date,
                                          style: TextStyle(color: context.appTextPrimary, fontSize: 13, fontWeight: FontWeight.w700),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${entry.trips} trip${entry.trips == 1 ? '' : 's'}',
                                          style: TextStyle(color: context.appTextSecondary, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '+${AppTheme.khr(entry.total)}',
                                    style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.w800, fontSize: 14),
                                  ),
                                ]),
                              )),
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
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ]);
}

// ── 30-day earnings bar chart ───────────────────────────────────────────────────

class _EarningsChart extends StatelessWidget {
  final List<DriverEarningsHistoryItem> history;
  final String Function(String isoDate) dayLabel;

  const _EarningsChart({required this.history, required this.dayLabel});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: context.appSurface, borderRadius: BorderRadius.circular(14)),
        child: Center(
          child: Text(AppLocalizations.of(context).noEarningsHistoryYet, style: TextStyle(color: context.appTextSecondary)),
        ),
      );
    }

    final maxAmount = history.map((h) => h.amountKhr).fold<int>(0, (a, b) => a > b ? a : b);
    // Show at most the most recent 14 days as bars to keep them readable.
    final shown = history.length > 14 ? history.sublist(history.length - 14) : history;

    return Container(
      width: double.infinity,
      height: 160,
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      decoration: BoxDecoration(color: context.appSurface, borderRadius: BorderRadius.circular(14)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: shown.map((item) {
          final heightFrac = maxAmount > 0 ? item.amountKhr / maxAmount : 0.0;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    item.amountKhr > 0 ? '${(item.amountKhr / 1000).round()}k' : '',
                    style: TextStyle(color: context.appTextSecondary, fontSize: 8),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: heightFrac.clamp(0.04, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: item.amountKhr > 0 ? AppTheme.accent : context.appCardBg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    dayLabel(item.date),
                    style: TextStyle(color: context.appTextSecondary, fontSize: 9),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
