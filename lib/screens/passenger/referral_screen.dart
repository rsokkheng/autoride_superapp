import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  Map<String, dynamic> _data = {
    'code': 'ROTEH',
    'referred_count': 0,
    'points_earned': 0,
    'referrals': [],
  };
  bool _loading = true;
  String? _error;
  bool _copied = false;
  final _shareKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService.getReferralInfo();
      if (!mounted) return;
      setState(() { _data = data; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  String get _code => _data['code'] as String? ?? 'ROTEH';
  int get _referredCount => _data['referred_count'] as int? ?? 0;
  int get _pointsEarned => _data['points_earned'] as int? ?? 0;
  List<dynamic> get _referrals => _data['referrals'] as List<dynamic>? ?? [];

  Future<void> _copyCode() async {
    await Clipboard.setData(ClipboardData(text: _code));
    if (!mounted) return;
    setState(() => _copied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied!'),
        backgroundColor: AppTheme.success,
        duration: Duration(seconds: 1),
      ),
    );
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  void _share() {
    final box = _shareKey.currentContext?.findRenderObject() as RenderBox?;
    Share.share(
      'Join ROTEH with my code: $_code and get 10,000 ៛ off your first ride!\n'
      'Download ROTEH now.',
      sharePositionOrigin:
          box != null ? box.localToGlobal(Offset.zero) & box.size : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(title: Text('Referral')),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : _error != null
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(_error!, style: TextStyle(color: context.appTextSecondary)),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: _load, child: const Text('Retry')),
                  ]),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppTheme.accent,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildHeroSection(),
                      const SizedBox(height: 24),
                      _buildCodeCard(),
                      const SizedBox(height: 16),
                      _buildShareButton(),
                      const SizedBox(height: 24),
                      _buildStats(),
                      const SizedBox(height: 24),
                      if (_referrals.isNotEmpty) _buildReferralList(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeroSection() {
    return Column(children: [
      Container(
        padding: EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppTheme.accent.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.card_giftcard,
            color: AppTheme.accent, size: 56),
      ),
      SizedBox(height: 20),
      Text('Share & Earn',
          style: TextStyle(color: context.appTextPrimary,
              fontSize: 26, fontWeight: FontWeight.w900)),
      SizedBox(height: 10),
      Text(
        'Give friends 10,000 ៛ off their first ride.\nYou earn 500 points per referral.',
        textAlign: TextAlign.center,
        style: TextStyle(color: context.appTextSecondary, fontSize: 15, height: 1.5),
      ),
    ]);
  }

  Widget _buildCodeCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [BoxShadow(color: AppTheme.accent.withValues(alpha: 0.1),
            blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(children: [
        Text('Your Referral Code',
            style: TextStyle(color: context.appTextSecondary, fontSize: 13)),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(_code,
              style: const TextStyle(
                color: AppTheme.accent,
                fontSize: 30,
                fontWeight: FontWeight.w900,
                fontFamily: 'monospace',
                letterSpacing: 4,
              )),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _copyCode,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _copied
                    ? AppTheme.success.withValues(alpha: 0.15)
                    : AppTheme.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _copied ? Icons.check : Icons.copy_outlined,
                color: _copied ? AppTheme.success : AppTheme.accent,
                size: 20,
              ),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _buildShareButton() {
    return ElevatedButton.icon(
      key: _shareKey,
      onPressed: _share,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.accent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
      icon: const Icon(Icons.share_outlined),
      label: const Text('Share with Friends',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
    );
  }

  Widget _buildStats() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        Expanded(child: _StatItem(
          label: 'Friends Referred',
          value: '$_referredCount',
          icon: Icons.people_outline,
        )),
        Container(width: 1, height: 48, color: context.appCardBg),
        Expanded(child: _StatItem(
          label: 'Points Earned',
          value: '$_pointsEarned pts',
          icon: Icons.star_outline,
        )),
      ]),
    );
  }

  Widget _buildReferralList() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Friends Who Joined',
          style: TextStyle(color: context.appTextPrimary,
              fontSize: 17, fontWeight: FontWeight.w700)),
      SizedBox(height: 12),
      Container(
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(children: [
          for (int i = 0; i < _referrals.length; i++) ...[
            if (i > 0) Divider(height: 1, color: context.appCardBg, indent: 60),
            _ReferralRow(item: _referrals[i] as Map<String, dynamic>),
          ],
        ]),
      ),
    ]);
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatItem({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Icon(icon, color: AppTheme.accent, size: 24),
      SizedBox(height: 6),
      Text(value,
          style: TextStyle(color: context.appTextPrimary,
              fontSize: 18, fontWeight: FontWeight.w800)),
      SizedBox(height: 2),
      Text(label,
          style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
    ]);
  }
}

class _ReferralRow extends StatelessWidget {
  final Map<String, dynamic> item;
  const _ReferralRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final name   = item['name'] as String? ?? 'Friend';
    final date   = item['joined_at'] as String? ?? item['created_at'] as String? ?? '';
    final short  = date.length >= 10 ? date.substring(0, 10) : date;
    final pts    = item['points_awarded'] as int? ?? 500;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        CircleAvatar(
          backgroundColor: AppTheme.accent.withValues(alpha: 0.15),
          radius: 20,
          child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w700)),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name,
                style: TextStyle(color: context.appTextPrimary,
                    fontWeight: FontWeight.w600)),
            if (short.isNotEmpty)
              Text('Joined $short',
                  style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
          ]),
        ),
        Text('+$pts pts',
            style: const TextStyle(color: AppTheme.success,
                fontWeight: FontWeight.w700)),
      ]),
    );
  }
}
