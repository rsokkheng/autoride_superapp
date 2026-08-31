import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../l10n/app_localizations.dart';

// Map Font Awesome class names → Flutter icons
IconData _planIcon(String icon) {
  if (icon.contains('crown'))  return Icons.workspace_premium_rounded;
  if (icon.contains('bolt'))   return Icons.bolt_rounded;
  if (icon.contains('star'))   return Icons.star_rounded;
  return Icons.card_membership_rounded;
}

// Parse "#rrggbb" hex colour
Color _hexColor(String hex) {
  try {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  } catch (_) {
    return AppTheme.accent;
  }
}

String _formatDate(BuildContext context, DateTime dt) {
  final l = AppLocalizations.of(context);
  final m = [l.jan, l.feb, l.mar, l.apr, l.may, l.jun,
              l.jul, l.aug, l.sep, l.oct, l.nov, l.dec];
  return '${dt.day} ${m[dt.month - 1]} ${dt.year}';
}

// ── Screen ────────────────────────────────────────────────────────────────────

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});
  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  List<SubscriptionPlan> _plans  = [];
  MySubscription?        _my;
  List<SubscriptionBill> _bills  = [];

  bool _loadingPlans   = true;
  bool _loadingMy      = true;
  bool _loadingHistory = false;
  bool _historyLoaded  = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() {
      if (!_tab.indexIsChanging && _tab.index == 1 && !_historyLoaded) {
        _loadHistory();
      }
    });
    _loadAll();
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  Future<void> _loadAll() async {
    await Future.wait([_loadPlans(), _loadMy()]);
  }

  Future<void> _loadPlans() async {
    setState(() => _loadingPlans = true);
    try {
      final p = await ApiService.getSubscriptionPlans();
      if (mounted) setState(() { _plans = p; _loadingPlans = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingPlans = false);
    }
  }

  Future<void> _loadMy() async {
    setState(() => _loadingMy = true);
    try {
      final m = await ApiService.getMySubscription();
      if (mounted) setState(() { _my = m; _loadingMy = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingMy = false);
    }
  }

  Future<void> _loadHistory() async {
    setState(() => _loadingHistory = true);
    try {
      final b = await ApiService.getSubscriptionHistory();
      if (mounted) setState(() { _bills = b; _historyLoaded = true; _loadingHistory = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingHistory = false);
    }
  }

  Future<void> _subscribe(SubscriptionPlan plan) async {
    final method = await _pickPaymentMethod();
    if (method == null || !mounted) return;

    final isUpgrade = _my != null && _my!.isActive;
    final l = AppLocalizations.of(context);
    final action    = isUpgrade ? l.upgradeToPrefix : l.subscribeToPrefix;
    final confirmed = await _confirm(
      title:   '$action ${plan.name}?',
      body:    '${AppTheme.khr(plan.priceKhr)} / ${plan.billingCycle}\n'
               '${l.paymentColonPrefix} ${_methodLabel(context, method)}',
      confirm: isUpgrade ? l.upgradeBtn : l.subscribeBtn,
    );
    if (confirmed != true || !mounted) return;

    try {
      final msg = isUpgrade
          ? await ApiService.upgradeSubscription(
              planSlug: plan.slug, paymentMethod: method)
          : await ApiService.subscribePlan(
              planSlug: plan.slug, paymentMethod: method);
      await _loadMy();
      if (mounted) _showSuccess(msg);
    } on ApiException catch (e) {
      if (mounted) _showError(e);
    }
  }

  Future<void> _cancel() async {
    final confirmed = await _confirm(
      title:   AppLocalizations.of(context).cancelSubscriptionQuestion,
      body:    AppLocalizations.of(context).benefitsContinueDesc,
      confirm: AppLocalizations.of(context).cancelPlanBtn,
      danger:  true,
    );
    if (confirmed != true || !mounted) return;
    try {
      final msg = await ApiService.cancelSubscription();
      await _loadMy();
      if (mounted) _showSuccess(msg);
    } on ApiException catch (e) {
      if (mounted) _showError(e);
    }
  }

  Future<void> _setAutoRenew(bool value) async {
    try {
      final result = await ApiService.toggleAutoRenew(value);
      if (mounted) setState(() {
        if (_my != null) {
          _my = MySubscription(
            id: _my!.id, planName: _my!.planName, planSlug: _my!.planSlug,
            planPriceKhr: _my!.planPriceKhr, status: _my!.status,
            isActive: _my!.isActive, paymentMethod: _my!.paymentMethod,
            autoRenew: result,
            startedAt: _my!.startedAt, expiresAt: _my!.expiresAt,
            expiresInDays: _my!.expiresInDays,
            usedRideCreditKhr: _my!.usedRideCreditKhr,
            remainingCreditKhr: _my!.remainingCreditKhr,
            usedCancellations: _my!.usedCancellations,
            remainingCancellations: _my!.remainingCancellations,
            renewalCount: _my!.renewalCount,
          );
        }
      });
    } on ApiException catch (e) {
      if (mounted) _showError(e);
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Future<String?> _pickPaymentMethod() => showModalBottomSheet<String>(
    context: context,
    backgroundColor: context.appSurface,
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => Padding(
      padding: EdgeInsets.all(20),
      child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(AppLocalizations.of(context).paymentMethod,
            style: TextStyle(color: context.appTextPrimary, fontSize: 16,
                fontWeight: FontWeight.w700)),
        SizedBox(height: 16),
        ...[
          ('wallet', Icons.account_balance_wallet_rounded, AppLocalizations.of(context).autoRideWalletLabel),
          ('card',   Icons.credit_card_rounded,            AppLocalizations.of(context).creditDebitCardLabel),
          ('qr',     Icons.qr_code_rounded,                AppLocalizations.of(context).qrPayment),
        ].map((e) => ListTile(
          leading: Icon(e.$2, color: AppTheme.accent),
          title: Text(e.$3, style: TextStyle(color: context.appTextPrimary)),
          contentPadding: EdgeInsets.zero,
          onTap: () => Navigator.pop(context, e.$1),
        )),
      ]),
    ),
  );

  Future<bool?> _confirm({
    required String title,
    required String body,
    required String confirm,
    bool danger = false,
  }) => showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: context.appSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title,
          style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w700)),
      content: Text(body,
          style: TextStyle(color: context.appTextSecondary, height: 1.5)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).cancel,
                style: TextStyle(color: context.appTextSecondary))),
        TextButton(onPressed: () => Navigator.pop(context, true),
            child: Text(confirm,
                style: TextStyle(
                    color: danger ? AppTheme.danger : AppTheme.accent,
                    fontWeight: FontWeight.w700))),
      ],
    ),
  );

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppTheme.success,
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _showError(ApiException e) {
    // Insufficient balance — show how much is needed
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(e.message),
      backgroundColor: AppTheme.danger,
      behavior: SnackBarBehavior.floating,
    ));
  }

  String _methodLabel(BuildContext context, String m) {
    final l = AppLocalizations.of(context);
    return switch (m) {
      'wallet' => l.autoRideWalletLabel,
      'card'   => l.cardLabel,
      'qr'     => l.qrPayment,
      _        => m,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).subscriptionPlansTitle),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: AppTheme.accent,
          labelColor: AppTheme.accent,
          unselectedLabelColor: context.appTextSecondary,
          tabs: [
            Tab(text: AppLocalizations.of(context).plansTab),
            Tab(text: AppLocalizations.of(context).history),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _PlansTab(
            plans:      _plans,
            my:         _my,
            loading:    _loadingPlans || _loadingMy,
            onSubscribe: _subscribe,
            onCancel:    _cancel,
            onAutoRenew: _setAutoRenew,
          ),
          _HistoryTab(
            bills:   _bills,
            loading: _loadingHistory,
          ),
        ],
      ),
    );
  }
}

// ── Plans tab ─────────────────────────────────────────────────────────────────

class _PlansTab extends StatelessWidget {
  final List<SubscriptionPlan> plans;
  final MySubscription?        my;
  final bool                   loading;
  final ValueChanged<SubscriptionPlan> onSubscribe;
  final VoidCallback           onCancel;
  final ValueChanged<bool>     onAutoRenew;

  const _PlansTab({
    required this.plans, required this.my, required this.loading,
    required this.onSubscribe, required this.onCancel, required this.onAutoRenew,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.accent));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Active subscription card
        if (my != null && my!.isActive) ...[
          _ActiveSubCard(sub: my!, onCancel: onCancel, onAutoRenew: onAutoRenew),
          const SizedBox(height: 20),
          _Label(AppLocalizations.of(context).changePlanLabel),
          const SizedBox(height: 12),
        ] else ...[
          _Label(AppLocalizations.of(context).choosePlanLabel),
          const SizedBox(height: 12),
        ],

        // Plan cards
        ...plans.map((p) {
          final isCurrent = my?.planSlug == p.slug && my!.isActive;
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _PlanCard(
              plan:      p,
              isCurrent: isCurrent,
              onTap:     isCurrent ? null : () => onSubscribe(p),
            ),
          );
        }),

        const SizedBox(height: 8),
      ],
    );
  }
}

class _ActiveSubCard extends StatelessWidget {
  final MySubscription sub;
  final VoidCallback   onCancel;
  final ValueChanged<bool> onAutoRenew;
  const _ActiveSubCard({required this.sub, required this.onCancel,
      required this.onAutoRenew});

  @override
  Widget build(BuildContext context) {
    final color = sub.planSlug == 'premium'
        ? const Color(0xFFf59e0b)
        : sub.planSlug == 'plus'
            ? const Color(0xFF3b82f6)
            : const Color(0xFF64748b);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.85), color],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(_planIcon('fa-${sub.planSlug}'), color: Colors.white, size: 26),
          const SizedBox(width: 10),
          Text(sub.planName,
              style: const TextStyle(color: Colors.white, fontSize: 20,
                  fontWeight: FontWeight.w800)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(sub.status.toUpperCase(),
                style: const TextStyle(color: Colors.white,
                    fontSize: 10, fontWeight: FontWeight.w700,
                    letterSpacing: 1)),
          ),
        ]),

        const SizedBox(height: 16),

        // Credit usage bar
        if (sub.remainingCreditKhr > 0 || sub.usedRideCreditKhr > 0) ...[
          Row(children: [
            Text(AppLocalizations.of(context).rideCreditLabel,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12)),
            const Spacer(),
            Text('${AppTheme.khr(sub.remainingCreditKhr)} ${AppLocalizations.of(context).leftSuffix}',
                style: const TextStyle(color: Colors.white,
                    fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (sub.usedRideCreditKhr + sub.remainingCreditKhr) > 0
                  ? sub.remainingCreditKhr /
                    (sub.usedRideCreditKhr + sub.remainingCreditKhr)
                  : 1.0,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Stats row
        Row(children: [
          _StatChip(label: AppLocalizations.of(context).cancellationsLeftLabel,
              value: sub.remainingCancellations),
          const SizedBox(width: 10),
          if (sub.expiresAt != null)
            _StatChip(label: AppLocalizations.of(context).expiresPrefix,
                value: '${sub.expiresInDays}d · ${_formatDate(context, sub.expiresAt!)}'),
        ]),

        const SizedBox(height: 16),

        // Auto-renew + cancel
        Row(children: [
          Text(AppLocalizations.of(context).autoRenewLabel,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 13)),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => onAutoRenew(!sub.autoRenew),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44, height: 24,
              decoration: BoxDecoration(
                color: sub.autoRenew
                    ? Colors.white.withValues(alpha: 0.9)
                    : Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Align(
                alignment: sub.autoRenew
                    ? Alignment.centerRight : Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Container(
                    width: 18, height: 18,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: onCancel,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(AppLocalizations.of(context).cancelPlanBtn, style: const TextStyle(fontSize: 13)),
          ),
        ]),
      ]),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8),
                fontSize: 10)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(color: Colors.white,
                fontWeight: FontWeight.w700, fontSize: 13)),
      ]),
    ),
  );
}

class _PlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final bool   isCurrent;
  final VoidCallback? onTap;
  const _PlanCard({required this.plan, required this.isCurrent, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _hexColor(plan.badgeColor);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCurrent ? color : context.appCardBg,
            width: isCurrent ? 2 : 1,
          ),
          boxShadow: isCurrent ? [
            BoxShadow(color: color.withValues(alpha: 0.2),
                blurRadius: 12, offset: Offset(0, 4)),
          ] : [],
        ),
        child: Column(children: [
          // Header band
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: Icon(_planIcon(plan.icon), color: color, size: 20),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Flexible(
                      child: Text(plan.name,
                          style: TextStyle(color: color, fontSize: 17,
                              fontWeight: FontWeight.w800)),
                    ),
                    if (isCurrent) ...[
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                            color: color, borderRadius: BorderRadius.circular(10)),
                        child: Text(AppLocalizations.of(context).currentBadge.toUpperCase(),
                            style: TextStyle(color: Colors.white,
                                fontSize: 9, fontWeight: FontWeight.w800,
                                letterSpacing: 0.5)),
                      ),
                    ],
                  ]),
                  if (plan.description != null)
                    Text(plan.description!,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: context.appTextSecondary,
                            fontSize: 12)),
                ]),
              ),
              const SizedBox(width: 8),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(AppTheme.khr(plan.priceKhr),
                    style: TextStyle(color: color, fontSize: 18,
                        fontWeight: FontWeight.w900)),
                Text('/ ${plan.billingCycle}',
                    style: TextStyle(color: context.appTextSecondary,
                        fontSize: 11)),
              ]),
            ]),
          ),

          // Features
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(children: [
              // Highlight pills
              Wrap(spacing: 8, runSpacing: 6, children: [
                if (plan.rideCreditKhr > 0)
                  _Pill(label: '${AppTheme.khr(plan.rideCreditKhr)} ${AppLocalizations.of(context).creditSuffix}',
                      color: color),
                if (plan.rideDiscountPct > 0)
                  _Pill(label: '${plan.rideDiscountPct}% ${AppLocalizations.of(context).offRidesSuffix}',
                      color: color),
                if (plan.deliveryDiscountPct > 0)
                  _Pill(label: '${plan.deliveryDiscountPct}% ${AppLocalizations.of(context).offDeliverySuffix}',
                      color: color),
                if (plan.surgeWaived)
                  _Pill(label: AppLocalizations.of(context).noSurgeLabel, color: color),
                if (plan.priorityMatching)
                  _Pill(label: AppLocalizations.of(context).priorityMatching, color: color),
              ]),
              SizedBox(height: 12),
              // Feature list
              ...plan.features.map((f) => Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.check_circle_rounded, color: color, size: 15),
                  SizedBox(width: 8),
                  Expanded(child: Text(f,
                      style: TextStyle(color: context.appTextSecondary,
                          fontSize: 13))),
                ]),
              )),
              const SizedBox(height: 4),
              // Cancellations & bonus
              _FeatureRow(icon: Icons.cancel_outlined,
                  label: '${plan.freeCancellations} ${AppLocalizations.of(context).freeCancellationsPerMonthSuffix}',
                  color: color),
              _FeatureRow(icon: Icons.stars_rounded,
                  label: '${plan.bonusPointsPct}% ${AppLocalizations.of(context).bonusLoyaltyPointsSuffix}',
                  color: color),
            ]),
          ),

          // Action button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: isCurrent
                  ? OutlinedButton(
                      onPressed: null,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: color.withValues(alpha: 0.3)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(AppLocalizations.of(context).currentPlanBtn,
                          style: TextStyle(color: color,
                              fontWeight: FontWeight.w700)),
                    )
                  : ElevatedButton(
                      onPressed: onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text(AppLocalizations.of(context).subscribeBtn,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color  color;
  const _Pill({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
  );
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;
  const _FeatureRow({required this.icon, required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: 6),
    child: Row(children: [
      Icon(icon, color: color, size: 15),
      SizedBox(width: 8),
      Expanded(child: Text(label,
          style: TextStyle(color: context.appTextSecondary, fontSize: 13))),
    ]),
  );
}

// ── History tab ───────────────────────────────────────────────────────────────

class _HistoryTab extends StatelessWidget {
  final List<SubscriptionBill> bills;
  final bool loading;
  const _HistoryTab({required this.bills, required this.loading});

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.accent));
    }
    if (bills.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.receipt_long_outlined, color: context.appTextSecondary, size: 48),
          SizedBox(height: 12),
          Text(AppLocalizations.of(context).noBillingHistoryYet,
              style: TextStyle(color: context.appTextSecondary)),
        ]),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: bills.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _BillCard(bill: bills[i]),
    );
  }
}

class _BillCard extends StatelessWidget {
  final SubscriptionBill bill;
  const _BillCard({required this.bill});

  @override
  Widget build(BuildContext context) {
    final color = _hexColor(bill.badgeColor);
    final isPaid = bill.status == 'paid';
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: context.appSurface, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
          child: Icon(Icons.card_membership_rounded, color: color, size: 20),
        ),
        SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(bill.planName,
              style: TextStyle(color: context.appTextPrimary,
                  fontWeight: FontWeight.w600, fontSize: 14)),
          Text('${_typeLabel(context, bill.type)} · ${bill.reference}',
              style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
          if (bill.paidAt != null)
            Text(_formatDate(context, bill.paidAt!),
                style: TextStyle(color: context.appTextSecondary, fontSize: 11)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(AppTheme.khr(bill.amountKhr),
              style: TextStyle(color: context.appTextPrimary,
                  fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isPaid
                  ? AppTheme.success.withValues(alpha: 0.1)
                  : AppTheme.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(bill.status.toUpperCase(),
                style: TextStyle(
                  color: isPaid ? AppTheme.success : AppTheme.warning,
                  fontSize: 10, fontWeight: FontWeight.w700,
                )),
          ),
        ]),
      ]),
    );
  }

  String _typeLabel(BuildContext context, String t) {
    final l = AppLocalizations.of(context);
    return switch (t) {
      'subscribe' => l.newSubscriptionLabel,
      'upgrade'   => l.upgradeBtn,
      'renew'     => l.renewalLabel,
      'cancel'    => l.cancellationLabel,
      _           => t,
    };
  }
}

// ── Shared ────────────────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: TextStyle(color: context.appTextPrimary, fontSize: 15,
          fontWeight: FontWeight.w700));
}
