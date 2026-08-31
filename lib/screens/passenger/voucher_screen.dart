import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../l10n/app_localizations.dart';

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
      backgroundColor: context.appBackground,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).vouchersTitle),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: AppTheme.accent,
          labelColor: AppTheme.accent,
          unselectedLabelColor: context.appTextSecondary,
          tabs: [
            Tab(icon: const Icon(Icons.store_outlined), text: AppLocalizations.of(context).storeTabLabel),
            Tab(icon: const Icon(Icons.wallet_giftcard_rounded), text: AppLocalizations.of(context).myVouchersTabLabel),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [StoreTab(), MyVouchersTab()],
      ),
    );
  }
}

// ── Store tab ─────────────────────────────────────────────────────────────────

class StoreTab extends StatefulWidget {
  const StoreTab();

  @override
  State<StoreTab> createState() => _StoreTabState();
}

class _StoreTabState extends State<StoreTab> {
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context).voucherClaimedCheckMy),
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
        Icon(Icons.error_outline, color: AppTheme.danger, size: 40),
        SizedBox(height: 12),
        Text(_error!, style: TextStyle(color: context.appTextSecondary), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: _load, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent), child: Text(AppLocalizations.of(context).retry)),
      ]));
    }
    if (_vouchers.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.discount_outlined, color: context.appTextSecondary, size: 48),
        SizedBox(height: 12),
        Text(AppLocalizations.of(context).noVouchersAvailable, style: TextStyle(color: context.appTextSecondary, fontSize: 15)),
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
            actionLabel: AppLocalizations.of(context).claimBtn,
            onAction:   () => _claim(v),
          );
        },
      ),
    );
  }
}

// ── My Vouchers tab ───────────────────────────────────────────────────────────

class MyVouchersTab extends StatefulWidget {
  const MyVouchersTab();

  @override
  State<MyVouchersTab> createState() => _MyVouchersTabState();
}

class _MyVouchersTabState extends State<MyVouchersTab> {
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
        Icon(Icons.error_outline, color: AppTheme.danger, size: 40),
        SizedBox(height: 12),
        Text(_error!, style: TextStyle(color: context.appTextSecondary), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: _load, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent), child: Text(AppLocalizations.of(context).retry)),
      ]));
    }
    if (_vouchers.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.wallet_giftcard_rounded, color: context.appTextSecondary, size: 48),
        SizedBox(height: 12),
        Text(AppLocalizations.of(context).noVouchersYet, style: TextStyle(color: context.appTextSecondary, fontSize: 15)),
        SizedBox(height: 6),
        Text(AppLocalizations.of(context).claimFromStoreTab, style: TextStyle(color: context.appTextSecondary, fontSize: 13)),
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
            actionLabel: used ? AppLocalizations.of(context).usedBadge : AppLocalizations.of(context).available,
            onAction:   null,
            badge:      used ? AppLocalizations.of(context).usedBadgeCap : (short.isNotEmpty ? '${AppLocalizations.of(context).expPrefix} $short' : null),
            badgeColor: used ? context.appTextSecondary : AppTheme.accent,
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
    final title    = voucher['title']       as String? ?? voucher['name'] as String? ?? AppLocalizations.of(context).voucherFallback;
    final desc     = voucher['description'] as String? ?? '';
    final discount = voucher['discount_value'] ?? voucher['discount'] ?? '';
    final type     = (voucher['discount_type'] as String? ?? '').toLowerCase();
    final discText = type == 'percentage' ? '$discount%' : '$discount ៛';

    return Container(
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appCardBg),
      ),
      child: Row(children: [
        Container(
          width: 72,
          decoration: BoxDecoration(
            color: AppTheme.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.horizontal(left: Radius.circular(16)),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.discount_rounded, color: AppTheme.accent, size: 28),
            SizedBox(height: 6),
            Text(discText, style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w900, fontSize: 13), textAlign: TextAlign.center),
          ]),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(title, style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w700, fontSize: 14))),
                if (badge != null)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: (badgeColor ?? AppTheme.accent).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(badge!, style: TextStyle(color: badgeColor ?? AppTheme.accent, fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
              ]),
              if (desc.isNotEmpty) ...[
                SizedBox(height: 4),
                Text(desc, style: TextStyle(color: context.appTextSecondary, fontSize: 12, height: 1.4)),
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
