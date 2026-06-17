import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class DriverWithdrawalScreen extends StatefulWidget {
  const DriverWithdrawalScreen({super.key});

  @override
  State<DriverWithdrawalScreen> createState() => _DriverWithdrawalScreenState();
}

class _DriverWithdrawalScreenState extends State<DriverWithdrawalScreen>
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
        title: const Text('Withdraw Earnings'),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: AppTheme.accent,
          labelColor: AppTheme.accent,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: const [
            Tab(icon: Icon(Icons.send_rounded), text: 'Withdraw'),
            Tab(icon: Icon(Icons.history_rounded), text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [_WithdrawForm(), _WithdrawHistory()],
      ),
    );
  }
}

// ── Withdraw form ─────────────────────────────────────────────────────────────

class _WithdrawForm extends StatefulWidget {
  const _WithdrawForm();

  @override
  State<_WithdrawForm> createState() => _WithdrawFormState();
}

class _WithdrawFormState extends State<_WithdrawForm> {
  final _amtCtrl     = TextEditingController();
  final _accNumCtrl  = TextEditingController();
  final _accNameCtrl = TextEditingController();
  final _bankCtrl    = TextEditingController();
  String _method     = 'bank_transfer';
  bool _submitting   = false;
  String? _error;

  static const _methods = [
    ('bank_transfer', 'Bank Transfer', Icons.account_balance_rounded),
    ('aba',           'ABA Bank',      Icons.credit_card_rounded),
    ('wing',          'Wing',          Icons.phone_android_rounded),
    ('acleda',        'ACLEDA',        Icons.account_balance_outlined),
  ];

  @override
  void dispose() {
    _amtCtrl.dispose();
    _accNumCtrl.dispose();
    _accNameCtrl.dispose();
    _bankCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amt = int.tryParse(_amtCtrl.text.trim());
    if (amt == null || amt <= 0) { setState(() => _error = 'Enter a valid amount.'); return; }
    if (_accNumCtrl.text.trim().isEmpty) { setState(() => _error = 'Enter account number.'); return; }
    if (_accNameCtrl.text.trim().isEmpty) { setState(() => _error = 'Enter account holder name.'); return; }

    setState(() { _submitting = true; _error = null; });
    try {
      await ApiService.requestWithdrawal(
        amountKhr:     amt,
        paymentMethod: _method,
        accountNumber: _accNumCtrl.text.trim(),
        accountName:   _accNameCtrl.text.trim(),
        bankName:      _bankCtrl.text.trim().isEmpty ? null : _bankCtrl.text.trim(),
      );
      if (!mounted) return;
      _amtCtrl.clear();
      _accNumCtrl.clear();
      _accNameCtrl.clear();
      _bankCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Withdrawal request submitted!'),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
      ));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (_error != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppTheme.danger.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
            ),
            child: Text(_error!, style: const TextStyle(color: AppTheme.danger, fontSize: 13)),
          ),
        ],

        const Text('Amount (KHR)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        _Field(controller: _amtCtrl, hint: '0', type: TextInputType.number, suffix: '៛'),

        const SizedBox(height: 20),
        const Text('Payment Method', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: _methods.map((m) {
          final selected = _method == m.$1;
          return GestureDetector(
            onTap: () => setState(() => _method = m.$1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? AppTheme.accent.withValues(alpha: 0.12) : AppTheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: selected ? AppTheme.accent : AppTheme.cardBg, width: selected ? 1.5 : 1),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(m.$3, color: selected ? AppTheme.accent : AppTheme.textSecondary, size: 18),
                const SizedBox(width: 6),
                Text(m.$2, style: TextStyle(color: selected ? AppTheme.accent : AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
              ]),
            ),
          );
        }).toList()),

        const SizedBox(height: 20),
        const Text('Account Number', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        _Field(controller: _accNumCtrl, hint: 'e.g. 000123456789', type: TextInputType.number),

        const SizedBox(height: 16),
        const Text('Account Holder Name', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        _Field(controller: _accNameCtrl, hint: 'Full name as on account'),

        const SizedBox(height: 16),
        const Text('Bank Name (optional)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        _Field(controller: _bankCtrl, hint: 'e.g. ABA, ACLEDA, Wing…'),

        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              disabledBackgroundColor: AppTheme.accent.withValues(alpha: 0.4),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _submitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Request Withdrawal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
          ),
        ),
      ]),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? type;
  final String? suffix;

  const _Field({required this.controller, required this.hint, this.type, this.suffix});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: type,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.textSecondary),
        suffixText: suffix,
        suffixStyle: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w700),
        filled: true,
        fillColor: AppTheme.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.accent, width: 1.5),
        ),
      ),
    );
  }
}

// ── Withdrawal history ────────────────────────────────────────────────────────

class _WithdrawHistory extends StatefulWidget {
  const _WithdrawHistory();

  @override
  State<_WithdrawHistory> createState() => _WithdrawHistoryState();
}

class _WithdrawHistoryState extends State<_WithdrawHistory> {
  List<Map<String, dynamic>> _items = [];
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
      final list = await ApiService.getWithdrawalHistory();
      if (!mounted) return;
      setState(() { _items = list; _loading = false; });
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
    if (_items.isEmpty) {
      return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.receipt_long_outlined, color: AppTheme.textSecondary, size: 48),
        SizedBox(height: 12),
        Text('No withdrawal history', style: TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
      ]));
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AppTheme.accent,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _WithdrawTile(item: _items[i]),
      ),
    );
  }
}

class _WithdrawTile extends StatelessWidget {
  final Map<String, dynamic> item;
  const _WithdrawTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final amount = item['amount_khr'] ?? item['amount'] ?? 0;
    final status = item['status'] as String? ?? 'pending';
    final method = item['payment_method'] as String? ?? '';
    final date   = item['created_at'] as String? ?? '';
    final short  = date.length >= 10 ? date.substring(0, 10) : date;

    final Color statusColor = status == 'completed' || status == 'approved'
        ? AppTheme.success
        : status == 'pending' || status == 'processing'
            ? AppTheme.warning
            : AppTheme.danger;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(Icons.send_rounded, color: statusColor, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(method.replaceAll('_', ' ').toUpperCase(),
                style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
            if (short.isNotEmpty)
              Text(short, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('$amount ៛', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
            child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w700)),
          ),
        ]),
      ]),
    );
  }
}
