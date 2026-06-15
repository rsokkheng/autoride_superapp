import 'package:flutter/material.dart';
import 'package:autoride_superapp/theme/app_theme.dart';
import 'package:autoride_superapp/widgets/common_widgets.dart';
import '../../models/wallet_model.dart';
import '../../services/api_service.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Balance
  WalletModel? _wallet;
  bool    _balanceLoading = true;
  String? _balanceError;

  // Transactions (paginated)
  final List<WalletTransactionModel> _transactions = [];
  int  _currentPage  = 1;
  int  _lastPage     = 1;
  int  _total        = 0;
  bool _txLoading    = false;
  bool _txLoadingMore = false;
  String? _txError;

  static const _topUpAmounts = [10000, 20000, 40000, 100000, 200000];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadBalance(), _loadTransactions(reset: true)]);
  }

  Future<void> _loadBalance() async {
    setState(() { _balanceLoading = true; _balanceError = null; });
    try {
      final w = await ApiService.getWallet();
      if (!mounted) return;
      setState(() { _wallet = w; _balanceLoading = false; });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() { _balanceError = e.message; _balanceLoading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _balanceError = e.toString(); _balanceLoading = false; });
    }
  }

  Future<void> _loadTransactions({bool reset = false}) async {
    if (_txLoading || _txLoadingMore) return;
    if (reset) {
      setState(() { _txLoading = true; _txError = null; _currentPage = 1; });
    } else {
      if (_currentPage >= _lastPage) return;
      setState(() { _txLoadingMore = true; });
    }
    try {
      final page = reset ? 1 : _currentPage + 1;
      final result = await ApiService.getWalletTransactions(page: page);
      if (!mounted) return;
      setState(() {
        if (reset) _transactions.clear();
        _transactions.addAll(result.transactions);
        _currentPage  = result.currentPage;
        _lastPage     = result.lastPage;
        _total        = result.total;
        _txLoading    = false;
        _txLoadingMore = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() { _txError = e.message; _txLoading = false; _txLoadingMore = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _txError = e.toString(); _txLoading = false; _txLoadingMore = false; });
    }
  }

  Future<void> _showTransferSheet(BuildContext context) async {
    final phoneCtrl  = TextEditingController();
    final amountCtrl = TextEditingController();
    final noteCtrl   = TextEditingController();
    bool sending = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            )),
            const SizedBox(height: 16),
            const Text('Send Money',
                style: TextStyle(color: AppTheme.textPrimary,
                    fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: "Recipient's phone number",
                hintStyle: const TextStyle(color: AppTheme.textSecondary),
                filled: true, fillColor: AppTheme.cardBg,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.phone_outlined,
                    color: AppTheme.textSecondary),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Amount (KHR, min 1,000)',
                hintStyle: const TextStyle(color: AppTheme.textSecondary),
                filled: true, fillColor: AppTheme.cardBg,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.account_balance_wallet_outlined,
                    color: AppTheme.textSecondary),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Note (optional)',
                hintStyle: const TextStyle(color: AppTheme.textSecondary),
                filled: true, fillColor: AppTheme.cardBg,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.notes_outlined,
                    color: AppTheme.textSecondary),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: sending ? null : () async {
                  final phone  = phoneCtrl.text.trim();
                  final amount = int.tryParse(amountCtrl.text.trim().replaceAll(',', ''));
                  if (phone.isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                      content: Text('Enter recipient phone number.'),
                      behavior: SnackBarBehavior.floating));
                    return;
                  }
                  if (amount == null || amount < 1000) {
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                      content: Text('Minimum transfer amount is 1,000 KHR.'),
                      behavior: SnackBarBehavior.floating));
                    return;
                  }
                  setSheet(() => sending = true);
                  try {
                    final result = await ApiService.walletTransfer(
                        phone: phone,
                        amountKhr: amount,
                        note: noteCtrl.text.trim().isEmpty
                            ? null : noteCtrl.text.trim());
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(result.message),
                      backgroundColor: AppTheme.success,
                      behavior: SnackBarBehavior.floating,
                    ));
                    _loadAll();
                  } on ApiException catch (e) {
                    if (!ctx.mounted) return;
                    setSheet(() => sending = false);
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                      content: Text(e.message),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ));
                  } catch (_) {
                    if (ctx.mounted) setSheet(() => sending = false);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: sending
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : const Text('Send',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
              ),
            ),
          ]),
        ),
      ),
    );

    phoneCtrl.dispose();
    amountCtrl.dispose();
    noteCtrl.dispose();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AutoRide Pay'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accent,
          labelColor: AppTheme.accent,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: const [Tab(text: 'Wallet'), Tab(text: 'Top Up')],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAll,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _WalletTab(
            wallet:        _wallet,
            balanceLoading: _balanceLoading,
            balanceError:   _balanceError,
            transactions:   _transactions,
            total:          _total,
            txLoading:      _txLoading,
            txLoadingMore:  _txLoadingMore,
            txError:        _txError,
            hasMore:        _currentPage < _lastPage,
            onRefresh:      _loadAll,
            onLoadMore:     () => _loadTransactions(reset: false),
            onRetryTx:      () => _loadTransactions(reset: true),
            onSend:         () => _showTransferSheet(context),
          ),
          _TopUpTab(
            balance:       _wallet?.balance ?? 0,
            amounts:       _topUpAmounts,
            onTopUpSuccess: _loadAll,
          ),
        ],
      ),
    );
  }
}

// ── Wallet Tab ────────────────────────────────────────────────────────────────

class _WalletTab extends StatelessWidget {
  final WalletModel? wallet;
  final bool   balanceLoading;
  final String? balanceError;
  final List<WalletTransactionModel> transactions;
  final int    total;
  final bool   txLoading;
  final bool   txLoadingMore;
  final String? txError;
  final bool   hasMore;
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;
  final VoidCallback onRetryTx;
  final VoidCallback onSend;

  const _WalletTab({
    required this.wallet,
    required this.balanceLoading,
    required this.balanceError,
    required this.transactions,
    required this.total,
    required this.txLoading,
    required this.txLoadingMore,
    required this.txError,
    required this.hasMore,
    required this.onRefresh,
    required this.onLoadMore,
    required this.onRetryTx,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppTheme.accent,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Balance card ─────────────────────────────────────────────
          if (balanceLoading)
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                  child: CircularProgressIndicator(color: AppTheme.accent)),
            )
          else if (balanceError != null)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(20)),
              child: Column(children: [
                Text(balanceError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13)),
              ]),
            )
          else
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00D4AA), Color(0xFF0094FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(children: [
                  const Icon(Icons.account_balance_wallet,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Text('AutoRide Pay Balance',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(wallet!.currency,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ),
                ]),
                const SizedBox(height: 12),
                Text(AppTheme.khr(wallet!.balance),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(AppTheme.usd(wallet!.balance / 4000),
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 2),
                const Text('Available balance',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 20),
                Row(children: [
                  _WalletAction(
                      icon: Icons.add, label: 'Top Up', onTap: () {}),
                  const SizedBox(width: 16),
                  _WalletAction(
                      icon: Icons.send, label: 'Send', onTap: onSend),
                  const SizedBox(width: 16),
                  _WalletAction(
                      icon: Icons.history, label: 'History', onTap: () {}),
                ]),
              ]),
            ),
          const SizedBox(height: 20),

          // ── Points / Rewards ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: AppTheme.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.emoji_events,
                    color: AppTheme.gold, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AutoRide Points',
                          style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w700)),
                      Text('1,240 pts  ·  Gold Member',
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12)),
                    ]),
              ),
              const Text('Redeem',
                  style: TextStyle(
                      color: AppTheme.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
            ]),
          ),
          const SizedBox(height: 20),

          // ── Transactions ─────────────────────────────────────────────
          Row(children: [
            const Expanded(
              child: SectionHeader(title: 'Transactions'),
            ),
            if (total > 0)
              Text('$total total',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12)),
          ]),
          const SizedBox(height: 12),

          if (txLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: AppTheme.accent),
              ),
            )
          else if (txError != null)
            _TxErrorBanner(message: txError!, onRetry: onRetryTx)
          else if (transactions.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No transactions yet',
                    style: TextStyle(color: AppTheme.textSecondary)),
              ),
            )
          else ...[
            ...transactions.map((t) => _TxnTile(txn: t)),
            if (hasMore)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: txLoadingMore
                      ? const CircularProgressIndicator(
                          color: AppTheme.accent)
                      : TextButton.icon(
                          onPressed: onLoadMore,
                          icon: const Icon(Icons.expand_more,
                              color: AppTheme.accent),
                          label: const Text('Load more',
                              style: TextStyle(color: AppTheme.accent)),
                        ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _TxErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _TxErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14)),
        child: Column(children: [
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13)),
          const SizedBox(height: 12),
          TextButton(
              onPressed: onRetry,
              child: const Text('Retry',
                  style: TextStyle(color: AppTheme.accent))),
        ]),
      );
}

class _WalletAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _WalletAction(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ]),
      );
}

class _TxnTile extends StatelessWidget {
  final WalletTransactionModel txn;

  const _TxnTile({required this.txn});

  IconData get _icon {
    switch (txn.type) {
      case 'top_up':              return Icons.add_circle_outline;
      case 'trip_earning':        return Icons.directions_car;
      case 'platform_commission': return Icons.percent;
      case 'bonus':               return Icons.card_giftcard;
      case 'trip_payment':        return Icons.payment;
      case 'refund':              return Icons.undo;
      default:                    return Icons.swap_horiz;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCredit = txn.isCredit;
    final amountColor = isCredit ? AppTheme.success : AppTheme.accentOrange;
    final amountStr   = isCredit
        ? '+${AppTheme.khr(txn.amount)}'
        : '-${AppTheme.khr(txn.amount)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: amountColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(_icon, color: amountColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(txn.displayLabel,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Row(children: [
                  Text(txn.formattedDate,
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 11)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                            color: AppTheme.textSecondary.withValues(alpha: 0.3))),
                    child: Text(
                      txn.status,
                      style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ]),
              ]),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(amountStr,
                style: TextStyle(
                    color: amountColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
            Text('Bal: ${AppTheme.khr(txn.balanceAfter)}',
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 10)),
          ],
        ),
      ]),
    );
  }
}

// ── Top Up Tab ────────────────────────────────────────────────────────────────

class _TopUpTab extends StatefulWidget {
  final int          balance;
  final List<int>    amounts;
  final VoidCallback onTopUpSuccess;

  const _TopUpTab({
    required this.balance,
    required this.amounts,
    required this.onTopUpSuccess,
  });

  @override
  State<_TopUpTab> createState() => _TopUpTabState();
}

class _TopUpTabState extends State<_TopUpTab> {
  int?   _selectedAmount;
  // API method key
  String _methodKey = 'cash';
  final  _noteCtrl  = TextEditingController();
  bool   _submitting = false;

  // Display label → API key
  static const _methods = [
    {'key': 'cash',           'name': 'Cash',           'icon': Icons.payments_outlined,   'color': Color(0xFF00D4AA)},
    {'key': 'online',         'name': 'Online Banking', 'icon': Icons.account_balance,      'color': Color(0xFF2196F3)},
    {'key': 'company_credit', 'name': 'Company Credit', 'icon': Icons.business_center,      'color': Color(0xFF9C27B0)},
  ];

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedAmount == null || _submitting) return;
    setState(() => _submitting = true);
    try {
      final req = await ApiService.requestTopUp(
        amount: _selectedAmount!,
        method: _methodKey,
        note:   _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      );
      if (!mounted) return;
      setState(() { _submitting = false; _selectedAmount = null; });
      _noteCtrl.clear();
      _showPendingDialog(req);
      widget.onTopUpSuccess();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message),
        backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString()),
        backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  void _showPendingDialog(TopUpRequestModel req) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
                color: AppTheme.warning.withValues(alpha: 0.15),
                shape: BoxShape.circle),
            child: const Icon(Icons.hourglass_top,
                color: AppTheme.warning, size: 32),
          ),
          const SizedBox(height: 16),
          const Text('Top-up Submitted',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(AppTheme.khr(req.amount),
              style: const TextStyle(
                  color: AppTheme.accent,
                  fontSize: 26,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Request #${req.id}',
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
                color: AppTheme.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppTheme.warning.withValues(alpha: 0.3))),
            child: const Text('Pending approval',
                style: TextStyle(
                    color: AppTheme.warning,
                    fontWeight: FontWeight.w600,
                    fontSize: 12)),
          ),
          const SizedBox(height: 10),
          const Text(
            'Your top-up is being reviewed.\nFunds will be credited once approved.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK',
                style: TextStyle(
                    color: AppTheme.accent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final methodName = _methods
        .firstWhere((m) => m['key'] == _methodKey)['name'] as String;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Current balance
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            const Icon(Icons.account_balance_wallet,
                color: AppTheme.accent, size: 20),
            const SizedBox(width: 10),
            const Text('Current Balance',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            const Spacer(),
            Text(AppTheme.khr(widget.balance),
                style: const TextStyle(
                    color: AppTheme.accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 15)),
          ]),
        ),
        const SizedBox(height: 20),

        const SectionHeader(title: 'Select Amount'),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.8,
          children: widget.amounts.map((a) => GestureDetector(
            onTap: () => setState(() => _selectedAmount = a),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: _selectedAmount == a
                    ? AppTheme.accent
                    : AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: _selectedAmount == a
                        ? AppTheme.accent
                        : AppTheme.surface),
              ),
              alignment: Alignment.center,
              child: Text(
                AppTheme.khr(a),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _selectedAmount == a
                      ? AppTheme.primary
                      : AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          )).toList(),
        ),
        const SizedBox(height: 20),

        const SectionHeader(title: 'Payment Method'),
        const SizedBox(height: 12),
        ..._methods.map((m) => GestureDetector(
          onTap: () => setState(() => _methodKey = m['key'] as String),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: _methodKey == m['key']
                      ? AppTheme.accent
                      : Colors.transparent),
            ),
            child: Row(children: [
              Icon(m['icon'] as IconData,
                  color: m['color'] as Color, size: 22),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(m['name'] as String,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600)),
                Text(m['key'] as String,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 11)),
              ]),
              const Spacer(),
              Icon(
                _methodKey == m['key']
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: _methodKey == m['key']
                    ? AppTheme.accent
                    : AppTheme.textSecondary,
                size: 20,
              ),
            ]),
          ),
        )),
        const SizedBox(height: 16),

        // Optional note
        TextField(
          controller: _noteCtrl,
          style: const TextStyle(color: AppTheme.textPrimary),
          maxLength: 255,
          decoration: InputDecoration(
            hintText: 'Note (optional, e.g. ABA transfer)',
            hintStyle: const TextStyle(color: AppTheme.textSecondary),
            prefixIcon: const Icon(Icons.notes_outlined,
                color: AppTheme.textSecondary, size: 20),
            filled: true,
            fillColor: AppTheme.surface,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: AppTheme.accent, width: 1.5)),
            counterStyle:
                const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
          ),
        ),
        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (_selectedAmount == null || _submitting) ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              disabledBackgroundColor:
                  AppTheme.accent.withValues(alpha: 0.4),
              foregroundColor: AppTheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: _submitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: AppTheme.primary, strokeWidth: 2.5))
                : Text(
                    _selectedAmount == null
                        ? 'Select an amount'
                        : 'Request Top-up  ${AppTheme.khr(_selectedAmount!)}  via $methodName',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        const Center(
          child: Text(
            'Top-up requests are reviewed and approved by admin.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
        ),
      ]),
    );
  }
}
