import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:autoride_superapp/theme/app_theme.dart';
import '../../models/wallet_model.dart';
import '../../services/api_service.dart';
import '../../utils/phone_utils.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  WalletModel? _wallet;
  bool _balanceLoading = true;
  String? _balanceError;

  List<WalletTransactionModel> _transactions = [];
  bool _txLoading = false;
  String? _txError;
  bool get _hasMore => _currentPage < _lastPage;
  int _currentPage = 1;
  int _lastPage = 1;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadBalance(), _loadTransactions(reset: true)]);
  }

  Future<void> _loadBalance() async {
    setState(() {
      _balanceLoading = true;
      _balanceError = null;
    });
    try {
      final w = await ApiService.getWallet();
      if (!mounted) return;
      setState(() {
        _wallet = w;
        _balanceLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _balanceError = e.message;
        _balanceLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _balanceError = e.toString();
        _balanceLoading = false;
      });
    }
  }

  Future<void> _loadTransactions({bool reset = false}) async {
    if (_txLoading) return;
    final page = reset ? 1 : _currentPage + 1;
    if (!reset && page > _lastPage) return;
    setState(() {
      _txLoading = true;
      if (reset) _txError = null;
    });
    try {
      final result = await ApiService.getWalletTransactions(page: page);
      if (!mounted) return;
      setState(() {
        if (reset) {
          _transactions = List.from(result.transactions);
        } else {
          _transactions = [..._transactions, ...result.transactions];
        }
        _currentPage = result.currentPage;
        _lastPage = result.lastPage;
        _txLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _txError = e.message;
        _txLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _txError = e.toString();
        _txLoading = false;
      });
    }
  }

  String _relativeTime(String? isoString) {
    if (isoString == null) return '';
    final dt = DateTime.tryParse(isoString);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hrs ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays} days ago';
  }

  ({IconData icon, Color color}) _txStyle(WalletTransactionModel txn) {
    switch (txn.type) {
      case 'topup':
      case 'top_up':
      case 'deposit':
      case 'credit':
        return (icon: Icons.arrow_downward, color: AppTheme.success);
      case 'payment':
      case 'ride':
      case 'trip':
      case 'trip_payment':
      case 'debit':
        return (icon: Icons.arrow_upward, color: AppTheme.danger);
      case 'refund':
        return (icon: Icons.undo, color: AppTheme.accent);
      case 'transfer':
      case 'send':
        return (icon: Icons.send, color: AppTheme.accentOrange);
      default:
        return (icon: Icons.swap_horiz, color: context.appTextSecondary);
    }
  }

  void _showTopUpSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.appSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _TopUpSheet(
        onSubmitted: (request) async {
          final approved = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => TopUpStatusScreen(topUpId: request.id)),
          );
          if (!mounted) return;
          if (approved == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Balance updated'),
                backgroundColor: AppTheme.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            );
          }
          _loadAll();
        },
      ),
    );
  }

  void _showSendSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.appSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _SendMoneySheet(
        onSuccess: () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Sent successfully'),
                backgroundColor: AppTheme.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            );
            _loadAll();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        title: const Text('ROTEH Pay'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAll,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAll,
        color: AppTheme.accent,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            _buildHeaderCard(),
            _buildQuickActions(),
            _buildTransactionsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00843A), Color(0xFF00B14F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF00B14F),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet,
                  color: Colors.white70, size: 18),
              const SizedBox(width: 6),
              const Text(
                'ROTEH Pay',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _showTopUpSheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Reload',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_balanceLoading)
            const SizedBox(
              height: 46,
              child: Center(
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              ),
            )
          else if (_balanceError != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _balanceError!,
                  style:
                      const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _loadBalance,
                  child: const Text(
                    'Tap to retry',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white),
                  ),
                ),
              ],
            )
          else ...[
            Text(
              AppTheme.khr(_wallet?.balance ?? 0),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5),
            ),
            const SizedBox(height: 4),
            Text(
              AppTheme.usd((_wallet?.balance ?? 0) / 4000),
              style: const TextStyle(color: Colors.white60, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _QuickActionButton(
            icon: Icons.add_circle_outline,
            label: 'Top Up',
            color: AppTheme.accent,
            onTap: _showTopUpSheet,
          ),
          _QuickActionButton(
            icon: Icons.send,
            label: 'Send',
            color: AppTheme.accentOrange,
            onTap: _showSendSheet,
          ),
          _QuickActionButton(
            icon: Icons.history,
            label: 'History',
            color: AppTheme.success,
            onTap: () => _loadTransactions(reset: true),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsSection() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Transactions',
            style: TextStyle(
                color: context.appTextPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 12),
          if (_txLoading && _transactions.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: AppTheme.accent),
              ),
            )
          else if (_txError != null && _transactions.isEmpty)
            _TxErrorBanner(
              message: _txError!,
              onRetry: () => _loadTransactions(reset: true),
            )
          else if (_transactions.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      color: context.appTextSecondary.withValues(alpha: 0.5),
                      size: 48,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'No transactions yet',
                      style: TextStyle(color: context.appTextSecondary),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            ..._transactions.take(10).map((t) {
              final style = _txStyle(t);
              return _TxnTile(
                txn: t,
                relativeTime: _relativeTime(t.createdAt),
                iconData: style.icon,
                iconColor: style.color,
              );
            }),
            const SizedBox(height: 12),
            if (_hasMore)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _txLoading
                    ? null
                    : () => _loadTransactions(reset: false),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.accent),
                  foregroundColor: AppTheme.accent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _txLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: AppTheme.accent, strokeWidth: 2),
                      )
                    : const Text(
                        'View all',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Quick action button ───────────────────────────────────────────────────────

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
                color: context.appTextPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ── Transaction tile ──────────────────────────────────────────────────────────

class _TxnTile extends StatelessWidget {
  final WalletTransactionModel txn;
  final String relativeTime;
  final IconData iconData;
  final Color iconColor;

  const _TxnTile({
    required this.txn,
    required this.relativeTime,
    required this.iconData,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isCredit = txn.isCredit;
    final amountColor = isCredit ? AppTheme.success : AppTheme.danger;
    final amountStr = isCredit
        ? '+${AppTheme.khr(txn.amount)}'
        : '-${AppTheme.khr(txn.amount)}';

    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(iconData, color: iconColor, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  txn.displayLabel,
                  style: TextStyle(
                      color: context.appTextPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 3),
                Text(
                  relativeTime.isNotEmpty ? relativeTime : txn.formattedDate,
                  style: TextStyle(
                      color: context.appTextSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            amountStr,
            style: TextStyle(
                color: amountColor,
                fontWeight: FontWeight.w700,
                fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ── Transaction error banner ──────────────────────────────────────────────────

class _TxErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _TxErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style:
                TextStyle(color: context.appTextSecondary, fontSize: 13),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onRetry,
            child:
                const Text('Retry', style: TextStyle(color: AppTheme.accent)),
          ),
        ],
      ),
    );
  }
}

// ── Top Up bottom sheet ───────────────────────────────────────────────────────

class _TopUpSheet extends StatefulWidget {
  final void Function(TopUpRequestModel request) onSubmitted;

  const _TopUpSheet({required this.onSubmitted});

  @override
  State<_TopUpSheet> createState() => _TopUpSheetState();
}

class _TopUpSheetState extends State<_TopUpSheet> {
  static const _amounts = [5000, 10000, 20000, 50000, 100000];

  static const _methods = [
    {'key': 'cash', 'label': 'Cash'},
    {'key': 'aba', 'label': 'ABA Pay'},
    {'key': 'acleda', 'label': 'ACLEDA'},
  ];

  int? _selectedAmount;
  String _selectedMethod = 'cash';
  final _customCtrl = TextEditingController();
  bool _useCustom = false;
  bool _submitting = false;

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  int? get _effectiveAmount {
    if (_useCustom) {
      return int.tryParse(_customCtrl.text.trim().replaceAll(',', ''));
    }
    return _selectedAmount;
  }

  Future<void> _submit() async {
    final amount = _effectiveAmount;
    if (amount == null || amount < 1000) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Minimum top-up amount is 1,000 KHR.'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() => _submitting = true);
    try {
      final request = await ApiService.requestTopUp(amount: amount, method: _selectedMethod);
      if (!mounted) return;
      Navigator.pop(context);
      widget.onSubmitted(request);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message),
        backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString()),
        backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Top Up ROTEH Pay',
              style: TextStyle(
                  color: context.appTextPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 20),

            // Preset amounts grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.2,
              children: _amounts.map((a) {
                final selected = !_useCustom && _selectedAmount == a;
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedAmount = a;
                    _useCustom = false;
                  }),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.accent : context.appCardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            selected ? AppTheme.accent : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      AppTheme.khr(a),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: selected ? Colors.white : context.appTextPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 12),

            // Custom amount field
            TextField(
              controller: _customCtrl,
              keyboardType: TextInputType.number,
              style: TextStyle(color: context.appTextPrimary),
              onChanged: (_) => setState(() => _useCustom = true),
              onTap: () => setState(() => _useCustom = true),
              decoration: InputDecoration(
                hintText: 'Custom amount (KHR)',
                hintStyle: TextStyle(color: context.appTextSecondary),
                filled: true,
                fillColor: _useCustom
                    ? AppTheme.accent.withValues(alpha: 0.08)
                    : context.appCardBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: AppTheme.accent, width: 1.5),
                ),
                prefixIcon: Icon(Icons.edit_outlined,
                    color: context.appTextSecondary, size: 18),
              ),
            ),
            SizedBox(height: 20),

            // Payment method chips
            Text(
              'Payment Method',
              style: TextStyle(
                  color: context.appTextSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _methods.map((m) {
                final key = m['key']!;
                final label = m['label']!;
                final selected = _selectedMethod == key;
                return ChoiceChip(
                  label: Text(label),
                  selected: selected,
                  onSelected: (_) =>
                      setState(() => _selectedMethod = key),
                  selectedColor: AppTheme.accent,
                  backgroundColor: context.appCardBg,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : context.appTextPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  side: BorderSide.none,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: AppTheme.confirmButtonStyle(),
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text('Confirm Top Up'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Top-up pending/approval status screen ─────────────────────────────────────
//
// Flow: driver/passenger submits a top-up request, which stays 'pending'
// until an admin approves or rejects it in the admin panel. This screen
// polls GET /wallet/topup/{id} until the status changes, then pops `true`
// (approved — balance changed) or `false` (rejected/left early).

class TopUpStatusScreen extends StatefulWidget {
  final int topUpId;
  const TopUpStatusScreen({super.key, required this.topUpId});

  @override
  State<TopUpStatusScreen> createState() => _TopUpStatusScreenState();
}

class _TopUpStatusScreenState extends State<TopUpStatusScreen> {
  TopUpRequestModel? _request;
  String? _error;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _check();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) => _check());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    try {
      final r = await ApiService.getTopUpRequest(widget.topUpId);
      if (!mounted) return;
      setState(() { _request = r; _error = null; });
      if (!r.isPending) _pollTimer?.cancel();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = _request;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) Navigator.pop(context, false);
      },
      child: Scaffold(
        backgroundColor: context.appBackground,
        appBar: AppBar(
          backgroundColor: context.appBackground,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Text('Top Up Status',
              style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w700)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              if (r == null) ...[
                const CircularProgressIndicator(color: AppTheme.accent),
                const SizedBox(height: 16),
                Text('Loading…', style: TextStyle(color: context.appTextSecondary)),
              ] else if (r.isPending) ...[
                const SizedBox(
                    width: 64, height: 64,
                    child: CircularProgressIndicator(color: AppTheme.warning, strokeWidth: 3)),
                const SizedBox(height: 20),
                Text('Waiting for admin approval…',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.appTextPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text('${AppTheme.khr(r.amount)} · ${r.method}',
                    style: TextStyle(color: context.appTextSecondary, fontSize: 13)),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Check later'),
                ),
              ] else if (r.isApproved) ...[
                const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 64),
                const SizedBox(height: 20),
                Text('Top-up approved!',
                    style: TextStyle(color: context.appTextPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text('${AppTheme.khr(r.amount)} has been added to your wallet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.appTextSecondary, fontSize: 13)),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ] else ...[
                const Icon(Icons.cancel_rounded, color: AppTheme.danger, size: 64),
                const SizedBox(height: 20),
                Text('Top-up rejected',
                    style: TextStyle(color: context.appTextPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
                if (r.adminNote != null && r.adminNote!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(r.adminNote!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: context.appTextSecondary, fontSize: 13)),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(color: AppTheme.danger, fontSize: 12)),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}

// ── Send Money bottom sheet ───────────────────────────────────────────────────

class _SendMoneySheet extends StatefulWidget {
  final VoidCallback onSuccess;

  const _SendMoneySheet({required this.onSuccess});

  @override
  State<_SendMoneySheet> createState() => _SendMoneySheetState();
}

class _SendMoneySheetState extends State<_SendMoneySheet> {
  final _phoneCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final phone = _phoneCtrl.text.trim();
    final amount =
        int.tryParse(_amountCtrl.text.trim().replaceAll(',', ''));

    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Enter recipient phone number.'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    final normalizedPhone = normalizeLocalPhone(phone);
    final phoneError = validateLocalPhone(normalizedPhone);
    if (phoneError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(phoneError),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    if (amount == null || amount < 1000) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Minimum transfer amount is 1,000 KHR.'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    setState(() => _submitting = true);
    try {
      await ApiService.walletTransfer(phone: normalizedPhone, amountKhr: amount);
      if (!mounted) return;
      Navigator.pop(context);
      widget.onSuccess();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message),
        backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString()),
        backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 0, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Send Money',
            style: TextStyle(
                color: context.appTextPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 20),

          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: TextStyle(color: context.appTextPrimary),
            decoration: InputDecoration(
              hintText: "Recipient's phone number",
              hintStyle: TextStyle(color: context.appTextSecondary),
              filled: true,
              fillColor: context.appCardBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: AppTheme.accent, width: 1.5),
              ),
              prefixIcon: Icon(Icons.phone_outlined,
                  color: context.appTextSecondary),
            ),
          ),
          SizedBox(height: 12),

          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            style: TextStyle(color: context.appTextPrimary),
            decoration: InputDecoration(
              hintText: 'Amount (KHR, min 1,000)',
              hintStyle: TextStyle(color: context.appTextSecondary),
              filled: true,
              fillColor: context.appCardBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: AppTheme.accent, width: 1.5),
              ),
              prefixIcon: Icon(Icons.account_balance_wallet_outlined,
                  color: context.appTextSecondary),
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: AppTheme.confirmButtonStyle(background: AppTheme.accent),
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text('Send'),
            ),
          ),
        ],
      ),
    );
  }
}
