import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class VoucherScreen extends StatefulWidget {
  const VoucherScreen({super.key});

  @override
  State<VoucherScreen> createState() => _VoucherScreenState();
}

class _VoucherScreenState extends State<VoucherScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      appBar: AppBar(
        title: const Text('Vouchers'),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: AppTheme.accent,
          labelColor: AppTheme.accent,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: const [
            Tab(icon: Icon(Icons.store_outlined), text: 'Store'),
            Tab(icon: Icon(Icons.wallet_giftcard_rounded), text: 'My Vouchers'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [_StoreTab(), _MyVouchersTab()],
      ),
    );
  }
}

// ── Store tab ─────────────────────────────────────────────────────────────────

class _StoreTab extends StatefulWidget {
  const _StoreTab();

  @override
  State<_StoreTab> createState() => _StoreTabState();
}

class _StoreTabState extends State<_StoreTab> {
  List<Map<String, dynamic>> _vouchers = [];
  bool _loading = true;
  String? _error;
  Set<int> _claiming = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await ApiService.getAvailableVouchers();
      if (!mounted) return;
      setState(() { _vouchers = list; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  Future<void> _claim(Map<String, dynamic> v) async {
    final id = (v['id'] as num?)?.toInt();
    if (id == null) return;
    setState(() => _claiming.add(id));
    try {
      await ApiService.claimVoucher(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Voucher claimed! Check My Vouchers.'),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
      ));
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message),
        backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _claiming.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppTheme.accent));
    if (_error != null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, color: AppTheme.danger, size: 40),
        const SizedBox(height: 12),
        Text(_error!, style: const TextStyle(color: AppTheme.textSecondary), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: _load, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent), child: const Text('Retry')),
      ]));
    }
    if (_vouchers.isEmpty) {
      return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.discount_outlined, color: AppTheme.textSecondary, size: 48),
        SizedBox(height: 12),
        Text('No vouchers available', style: TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
      ]));
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AppTheme.accent,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _vouchers.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final v  = _vouchers[i];
          final id = (v['id'] as num?)?.toInt() ?? 0;
          return _VoucherCard(
            voucher:  v,
            isClaiming: _claiming.contains(id),
            actionLabel: 'Claim',
            onAction:   () => _claim(v),
          );
        },
      ),
    );
  }
}

// ── My Vouchers tab ───────────────────────────────────────────────────────────

class _MyVouchersTab extends StatefulWidget {
  const _MyVouchersTab();

  @override
  State<_MyVouchersTab> createState() => _MyVouchersTabState();
}

class _MyVouchersTabState extends State<_MyVouchersTab> {
  List<Map<String, dynamic>> _vouchers = [];
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
      final list = await ApiService.getMyVouchers();
      if (!mounted) return;
      setState(() { _vouchers = list; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppTheme.accent));
    if (_error != null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, color: AppTheme.danger, size: 40),
        const SizedBox(height: 12),
        Text(_error!, style: const TextStyle(color: AppTheme.textSecondary), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: _load, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent), child: const Text('Retry')),
      ]));
    }
    if (_vouchers.isEmpty) {
      return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.wallet_giftcard_rounded, color: AppTheme.textSecondary, size: 48),
        SizedBox(height: 12),
        Text('No vouchers yet', style: TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
        SizedBox(height: 6),
        Text('Claim from the Store tab', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
      ]));
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AppTheme.accent,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _vouchers.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final v      = _vouchers[i];
          final used   = v['used_at'] != null || v['status'] == 'used';
          final expiry = v['expires_at'] as String? ?? v['voucher']?['expires_at'] as String? ?? '';
          final short  = expiry.length >= 10 ? expiry.substring(0, 10) : expiry;
          return _VoucherCard(
            voucher:    v['voucher'] as Map<String, dynamic>? ?? v,
            isClaiming: false,
            actionLabel: used ? 'Used' : 'Available',
            onAction:   null,
            badge:      used ? 'USED' : (short.isNotEmpty ? 'Exp $short' : null),
            badgeColor: used ? AppTheme.textSecondary : AppTheme.accent,
          );
        },
      ),
    );
  }
}

// ── Shared voucher card ───────────────────────────────────────────────────────

class _VoucherCard extends StatelessWidget {
  final Map<String, dynamic> voucher;
  final bool isClaiming;
  final String actionLabel;
  final VoidCallback? onAction;
  final String? badge;
  final Color? badgeColor;

  const _VoucherCard({
    required this.voucher,
    required this.isClaiming,
    required this.actionLabel,
    required this.onAction,
    this.badge,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    final title    = voucher['title']       as String? ?? voucher['name'] as String? ?? 'Voucher';
    final desc     = voucher['description'] as String? ?? '';
    final discount = voucher['discount_value'] ?? voucher['discount'] ?? '';
    final type     = (voucher['discount_type'] as String? ?? '').toLowerCase();
    final discText = type == 'percentage' ? '$discount%' : '$discount ៛';

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBg),
      ),
      child: Row(children: [
        Container(
          width: 72,
          decoration: BoxDecoration(
            color: AppTheme.accent.withValues(alpha: 0.12),
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.discount_rounded, color: AppTheme.accent, size: 28),
            const SizedBox(height: 6),
            Text(discText, style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w900, fontSize: 13), textAlign: TextAlign.center),
          ]),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 14))),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: (badgeColor ?? AppTheme.accent).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(badge!, style: TextStyle(color: badgeColor ?? AppTheme.accent, fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
              ]),
              if (desc.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4)),
              ],
              if (onAction != null) ...[
                const SizedBox(height: 10),
                SizedBox(
                  height: 32,
                  child: ElevatedButton(
                    onPressed: isClaiming ? null : onAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      disabledBackgroundColor: AppTheme.accent.withValues(alpha: 0.4),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    child: isClaiming
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(actionLabel),
                  ),
                ),
              ],
            ]),
          ),
        ),
      ]),
    );
  }
}
