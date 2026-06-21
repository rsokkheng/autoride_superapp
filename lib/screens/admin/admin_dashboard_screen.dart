import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../auth/login_screen.dart';
import 'fare_management_screen.dart';
import 'surge_promo_screen.dart';
import 'admin_driver_approval_screen.dart';
import 'admin_users_screen.dart';
import 'admin_rides_screen.dart';
import 'admin_deliveries_screen.dart';
import 'admin_withdrawals_screen.dart';
import 'admin_topups_screen.dart';
import 'admin_support_screen.dart';
import 'admin_banners_screen.dart';
import 'admin_pricing_screen.dart';
import 'admin_safety_screen.dart';
import 'admin_transactions_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic> _stats = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService.getAdminStats();
      if (!mounted) return;
      setState(() { _stats = data; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  Map<String, dynamic> get _overview =>
      (_stats['overview'] as Map<String, dynamic>?) ?? _stats;

  Map<String, dynamic> get _alerts =>
      (_stats['pending_alerts'] as Map<String, dynamic>?) ?? {};

  dynamic _o(String key) => _overview[key];

  String _str(String key) => _o(key)?.toString() ?? '—';

  String _khr(String key) {
    final v = _o(key);
    if (v == null) return '—';
    final n = (v is num) ? v.toInt() : int.tryParse(v.toString()) ?? 0;
    return '${(n / 1000).toStringAsFixed(0)}K ៛';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: AppTheme.accent, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          const Text('Admin Dashboard'),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load, tooltip: 'Refresh'),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () async {
              await ApiService.adminLogout();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.error_outline, color: AppTheme.danger, size: 40),
                  SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: context.appTextSecondary), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _load, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent), child: const Text('Retry')),
                ]))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppTheme.accent,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildAlertBanner(),
                      const SizedBox(height: 16),
                      _buildOverviewGrid(),
                      const SizedBox(height: 24),
                      _buildRevenueChart(),
                      const SizedBox(height: 24),
                      _buildManagementGrid(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildAlertBanner() {
    final approvals   = (_alerts['driver_approvals']    as num?)?.toInt() ?? 0;
    final withdrawals = (_alerts['withdrawal_requests'] as num?)?.toInt() ?? 0;
    final tickets     = (_alerts['open_tickets']        as num?)?.toInt() ?? 0;
    final topups      = (_alerts['topup_requests']      as num?)?.toInt() ?? 0;
    final total = approvals + withdrawals + tickets + topups;
    if (total == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.notification_important_rounded, color: AppTheme.warning, size: 18),
          const SizedBox(width: 8),
          Text('$total pending actions', style: const TextStyle(color: AppTheme.warning, fontWeight: FontWeight.w700, fontSize: 13)),
        ]),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 6, children: [
          if (approvals   > 0) _AlertChip(label: '$approvals Driver Approvals', onTap: () => _push(const AdminDriverApprovalScreen())),
          if (withdrawals > 0) _AlertChip(label: '$withdrawals Withdrawals',    onTap: () => _push(const AdminWithdrawalsScreen())),
          if (tickets     > 0) _AlertChip(label: '$tickets Tickets',            onTap: () => _push(const AdminSupportScreen())),
          if (topups      > 0) _AlertChip(label: '$topups Top-ups',             onTap: () => _push(const AdminTopupsScreen())),
        ]),
      ]),
    );
  }

  Widget _buildOverviewGrid() {
    final cards = [
      _StatCard(icon: Icons.person_outline,         label: 'Passengers',       value: _str('passengers'),       color: const Color(0xFF2196F3)),
      _StatCard(icon: Icons.drive_eta_outlined,     label: 'Drivers Total',    value: _str('drivers_total'),    color: AppTheme.accent),
      _StatCard(icon: Icons.wifi_tethering_rounded, label: 'Online Drivers',   value: _str('drivers_online'),   color: AppTheme.success),
      _StatCard(icon: Icons.pending_outlined,       label: 'Pending Drivers',  value: _str('drivers_pending'),  color: AppTheme.warning),
      _StatCard(icon: Icons.directions_car_rounded, label: 'Rides Today',      value: _str('rides_today'),      color: AppTheme.accent),
      _StatCard(icon: Icons.directions_car_filled,  label: 'Active Rides',     value: _str('rides_active'),     color: AppTheme.success),
      _StatCard(icon: Icons.local_shipping_rounded, label: 'Deliveries Today', value: _str('deliveries_today'), color: AppTheme.accentOrange),
      _StatCard(icon: Icons.attach_money_rounded,   label: 'Revenue Today',    value: _khr('revenue_today'),    color: AppTheme.gold),
      _StatCard(icon: Icons.show_chart_rounded,     label: 'Revenue Week',     value: _khr('revenue_week'),     color: AppTheme.gold),
      _StatCard(icon: Icons.trending_up_rounded,    label: 'Growth',           value: '${_str('revenue_growth_pct')}%', color: AppTheme.success),
      _StatCard(icon: Icons.support_agent_rounded,  label: 'Open Tickets',     value: _str('support_open'),     color: AppTheme.danger),
      _StatCard(icon: Icons.security_rounded,       label: 'Safety Incidents', value: _str('safety_incidents'), color: AppTheme.danger),
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Overview', style: TextStyle(color: context.appTextPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.6,
        children: cards,
      ),
    ]);
  }

  Widget _buildRevenueChart() {
    final chart = (_stats['revenue_chart'] as List<dynamic>?) ?? [];
    if (chart.isEmpty) return const SizedBox.shrink();

    final maxRevenue = chart
        .map((e) => (e as Map)['revenue'] as num? ?? 0)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
    if (maxRevenue == 0) return const SizedBox.shrink();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Revenue (7 days)', style: TextStyle(color: context.appTextPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
      SizedBox(height: 12),
      Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(color: context.appSurface, borderRadius: BorderRadius.circular(14)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: chart.map((e) {
            final m = e as Map;
            final rev  = (m['revenue'] as num? ?? 0).toDouble();
            final date = (m['date'] as String? ?? '').length >= 10 ? (m['date'] as String).substring(5) : '';
            final h    = (rev / maxRevenue) * 80;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 3),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    height: h.clamp(4.0, 80.0),
                    decoration: BoxDecoration(color: AppTheme.accent, borderRadius: BorderRadius.circular(4)),
                  ),
                  SizedBox(height: 4),
                  Text(date, style: TextStyle(color: context.appTextSecondary, fontSize: 9)),
                ]),
              ),
            );
          }).toList(),
        ),
      ),
    ]);
  }

  Widget _buildManagementGrid() {
    const sections = [
      ('Users', Icons.people_outline, Color(0xFF2196F3), false),
      ('Drivers', Icons.drive_eta_outlined, Color(0xFF00B14F), false),
      ('Rides', Icons.directions_car_outlined, Color(0xFF00B14F), false),
      ('Deliveries', Icons.local_shipping_outlined, Color(0xFFFF6B2B), false),
      ('Withdrawals', Icons.account_balance_outlined, Color(0xFFFFD700), false),
      ('Top-ups', Icons.add_card_rounded, Color(0xFF4CAF50), false),
      ('Support', Icons.support_agent_outlined, Color(0xFF9C27B0), false),
      ('Transactions', Icons.receipt_long_outlined, Color(0xFF607D8B), false),
      ('Fare Rules', Icons.price_change_outlined, Color(0xFF00B14F), false),
      ('Surge Zones', Icons.bolt_outlined, Color(0xFFFF6B2B), false),
      ('Pricing', Icons.tune_rounded, Color(0xFF00BCD4), false),
      ('Banners', Icons.image_outlined, Color(0xFF9C27B0), false),
      ('Safety', Icons.security_rounded, Color(0xFFF44336), false),
    ];

    final screens = <Widget>[
      const AdminUsersScreen(),
      const AdminDriverApprovalScreen(),
      const AdminRidesScreen(),
      const AdminDeliveriesScreen(),
      const AdminWithdrawalsScreen(),
      const AdminTopupsScreen(),
      const AdminSupportScreen(),
      const AdminTransactionsScreen(),
      const FareManagementScreen(),
      const SurgePromoScreen(),
      const AdminPricingScreen(),
      const AdminBannersScreen(),
      const AdminSafetyScreen(),
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Management', style: TextStyle(color: context.appTextPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.0,
        ),
        itemCount: sections.length,
        itemBuilder: (_, i) {
          final s = sections[i];
          return _ManageTile(
            icon: s.$2, label: s.$1, color: s.$3,
            onTap: () => _push(screens[i]),
          );
        },
      ),
      const SizedBox(height: 32),
    ]);
  }

  void _push(Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _AlertChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _AlertChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.warning.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.warning.withValues(alpha: 0.5)),
        ),
        child: Text(label, style: const TextStyle(color: AppTheme.warning, fontSize: 11, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(color: context.appSurface, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 18),
        ),
        Spacer(),
        Text(value, style: TextStyle(color: context.appTextPrimary, fontSize: 18, fontWeight: FontWeight.w900)),
        SizedBox(height: 1),
        Text(label, style: TextStyle(color: context.appTextSecondary, fontSize: 11)),
      ]),
    );
  }
}

class _ManageTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ManageTile({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: context.appSurface, borderRadius: BorderRadius.circular(12)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 22),
          ),
          SizedBox(height: 8),
          Text(label, style: TextStyle(color: context.appTextPrimary, fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}
