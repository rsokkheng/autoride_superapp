import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class LoyaltyScreen extends StatefulWidget {
  const LoyaltyScreen({super.key});

  @override
  State<LoyaltyScreen> createState() => _LoyaltyScreenState();
}

class _LoyaltyScreenState extends State<LoyaltyScreen> {
  Map<String, dynamic> _data = {'points': 0, 'tier': 'bronze', 'history': []};
  bool _loading = true;
  String? _error;
  bool _redeeming = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService.getLoyaltyPoints();
      if (!mounted) return;
      setState(() { _data = data; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  int get _points {
    final p = _data['points'];
    if (p is int) return p;
    if (p is double) return p.toInt();
    return int.tryParse(p?.toString() ?? '0') ?? 0;
  }

  String get _tier {
    if (_points >= 5000) return 'Gold';
    if (_points >= 1000) return 'Silver';
    return 'Bronze';
  }

  Color get _tierColor {
    switch (_tier) {
      case 'Gold':   return AppTheme.gold;
      case 'Silver': return Colors.grey.shade400;
      default:       return const Color(0xFFCD7F32);
    }
  }

  int get _nextTierPoints {
    if (_points < 1000) return 1000;
    if (_points < 5000) return 5000;
    return 5000;
  }

  double get _tierProgress {
    if (_points >= 5000) return 1.0;
    if (_points >= 1000) return (_points - 1000) / 4000;
    return _points / 1000;
  }

  String get _nextTierLabel {
    if (_points >= 5000) return 'Max tier reached';
    if (_points >= 1000) return '${_nextTierPoints - _points} pts to Gold';
    return '${_nextTierPoints - _points} pts to Silver';
  }

  Future<void> _showRedeemDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Redeem Points',
            style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
        content: const Text(
          'Redeem 500 pts for 5,000 ៛ discount on your next ride?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _redeeming = true);
    try {
      await ApiService.redeemPoints(500);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('500 pts redeemed! Discount applied to next ride.'),
          backgroundColor: AppTheme.success,
        ),
      );
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppTheme.danger),
      );
    } finally {
      if (mounted) setState(() => _redeeming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      appBar: AppBar(title: const Text('AutoRide Rewards')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : _error != null
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(_error!, style: const TextStyle(color: AppTheme.textSecondary)),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: _load, child: const Text('Retry')),
                  ]),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppTheme.accent,
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 16),
                      _buildHowToEarn(),
                      const SizedBox(height: 16),
                      _buildHistory(),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ElevatedButton(
                          onPressed: _points >= 500 && !_redeeming ? _showRedeemDialog : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _redeeming
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : const Text('Redeem 500 pts',
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.accent, AppTheme.accent.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('AutoRide Points',
                style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 4),
            Text('$_points pts',
                style: const TextStyle(color: Colors.white,
                    fontSize: 36, fontWeight: FontWeight.w900)),
          ]),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _tierColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.star, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              Text(_tier,
                  style: const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w800, fontSize: 14)),
            ]),
          ),
        ]),
        const SizedBox(height: 20),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _tierProgress,
            backgroundColor: Colors.white.withValues(alpha: 0.25),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 8),
        Text(_nextTierLabel,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ]),
    );
  }

  Widget _buildHowToEarn() {
    const items = [
      _EarnItem(Icons.directions_car_outlined, 'Complete a trip', '10 pts per 1,000 ៛'),
      _EarnItem(Icons.star_outline, 'Rate your driver', '50 pts bonus'),
      _EarnItem(Icons.person_add_alt_outlined, 'Refer a friend', '500 pts per referral'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('How to Earn',
            style: TextStyle(color: AppTheme.textPrimary,
                fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(children: [
            for (int i = 0; i < items.length; i++) ...[
              if (i > 0)
                const Divider(height: 1, color: AppTheme.cardBg, indent: 56),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(items[i].icon, color: AppTheme.accent, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(items[i].title,
                          style: const TextStyle(color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600)),
                      Text(items[i].subtitle,
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    ]),
                  ),
                ]),
              ),
            ],
          ]),
        ),
      ]),
    );
  }

  Widget _buildHistory() {
    final history = (_data['history'] as List<dynamic>?) ?? [];
    if (history.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Points Activity',
            style: TextStyle(color: AppTheme.textPrimary,
                fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(children: [
            for (int i = 0; i < history.length; i++) ...[
              if (i > 0)
                const Divider(height: 1, color: AppTheme.cardBg, indent: 16),
              _HistoryRow(item: history[i] as Map<String, dynamic>),
            ],
          ]),
        ),
      ]),
    );
  }
}

class _EarnItem {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EarnItem(this.icon, this.title, this.subtitle);
}

class _HistoryRow extends StatelessWidget {
  final Map<String, dynamic> item;
  const _HistoryRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final desc   = item['description'] as String? ?? item['type'] as String? ?? 'Points';
    final pts    = item['points'] as int? ?? 0;
    final earned = pts >= 0;
    final date   = item['created_at'] as String? ?? '';
    final short  = date.length >= 10 ? date.substring(0, 10) : date;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: earned
                ? AppTheme.success.withValues(alpha: 0.1)
                : AppTheme.danger.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(earned ? Icons.add : Icons.remove,
              color: earned ? AppTheme.success : AppTheme.danger, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(desc,
                style: const TextStyle(color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600, fontSize: 13)),
            if (short.isNotEmpty)
              Text(short, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          ]),
        ),
        Text('${earned ? '+' : ''}$pts pts',
            style: TextStyle(
              color: earned ? AppTheme.success : AppTheme.danger,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            )),
      ]),
    );
  }
}
