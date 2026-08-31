import 'package:autoride_superapp/l10n/app_localizations.dart';
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
      backgroundColor: context.appBackground,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).withdrawEarnings),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: AppTheme.accent,
          labelColor: AppTheme.accent,
          unselectedLabelColor: context.appTextSecondary,
          tabs: [
            Tab(icon: Icon(Icons.send_rounded), text: AppLocalizations.of(context).withdraw),
            Tab(icon: Icon(Icons.history_rounded), text: AppLocalizations.of(context).history),
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

  List<(String, String, IconData)> _methodsFor(AppLocalizations l) => [
    ('bank_transfer', l.bankTransfer, Icons.account_balance_rounded),
    ('aba',           l.abaBank,      Icons.credit_card_rounded),
    ('wing',          l.wing,         Icons.phone_android_rounded),
    ('acleda',        l.acleda,       Icons.account_balance_outlined),
  ];

  @override
  void dispose() {
    _amtCtrl.dispose();
    _accNumCtrl.dispose();
    _accNameCtrl.dispose();
    _bankCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmAndSubmit() async {
    final amt = int.tryParse(_amtCtrl.text.trim());
    if (amt == null || amt <= 0) { setState(() => _error = AppLocalizations.of(context).enterAValidAmount); return; }
    if (_accNumCtrl.text.trim().isEmpty) { setState(() => _error = AppLocalizations.of(context).enterAccountNumber); return; }
    if (_accNameCtrl.text.trim().isEmpty) { setState(() => _error = AppLocalizations.of(context).enterAccountHolderName); return; }

    final methodLabel = _methodsFor(AppLocalizations.of(context))
        .firstWhere((m) => m.$1 == _method).$2;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(AppLocalizations.of(context).confirmWithdrawal,
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          _ConfirmRow(AppLocalizations.of(context).amount, '${amt.toString()} ៛'),
          _ConfirmRow(AppLocalizations.of(context).method, methodLabel),
          _ConfirmRow(AppLocalizations.of(context).accountNumber, _accNumCtrl.text.trim()),
          _ConfirmRow(AppLocalizations.of(context).accountName, _accNameCtrl.text.trim()),
          if (_bankCtrl.text.trim().isNotEmpty)
            _ConfirmRow(AppLocalizations.of(context).bank, _bankCtrl.text.trim()),
          const SizedBox(height: 8),
          Text(AppLocalizations.of(context).pleaseMakeSureTheseDetails,
              style: TextStyle(color: Theme.of(ctx).textTheme.bodySmall?.color, fontSize: 12)),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: AppTheme.confirmButtonStyle(),
            child: Text(AppLocalizations.of(context).confirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _submit(amt);
  }

  Future<void> _submit(int amt) async {
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context).withdrawalRequestSubmitted),
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
            padding: EdgeInsets.all(12),
            margin: EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppTheme.danger.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
            ),
            child: Text(_error!, style: TextStyle(color: AppTheme.danger, fontSize: 13)),
          ),
        ],

        Text(AppLocalizations.of(context).amountKhr, style: TextStyle(color: context.appTextSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
        SizedBox(height: 8),
        _Field(controller: _amtCtrl, hint: '0', type: TextInputType.number, suffix: '៛'),

        SizedBox(height: 20),
        Text(AppLocalizations.of(context).paymentMethod, style: TextStyle(color: context.appTextSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: _methodsFor(AppLocalizations.of(context)).map((m) {
          final selected = _method == m.$1;
          return GestureDetector(
            onTap: () => setState(() => _method = m.$1),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? AppTheme.accent.withValues(alpha: 0.12) : context.appSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: selected ? AppTheme.accent : context.appCardBg, width: selected ? 1.5 : 1),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(m.$3, color: selected ? AppTheme.accent : context.appTextSecondary, size: 18),
                SizedBox(width: 6),
                Text(m.$2, style: TextStyle(color: selected ? AppTheme.accent : context.appTextPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
              ]),
            ),
          );
        }).toList()),

        SizedBox(height: 20),
        Text(AppLocalizations.of(context).accountNumber, style: TextStyle(color: context.appTextSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
        SizedBox(height: 8),
        _Field(controller: _accNumCtrl, hint: 'e.g. 000123456789', type: TextInputType.number),

        SizedBox(height: 16),
        Text(AppLocalizations.of(context).accountHolderName, style: TextStyle(color: context.appTextSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
        SizedBox(height: 8),
        _Field(controller: _accNameCtrl, hint: AppLocalizations.of(context).fullNameAsOnAccount),

        SizedBox(height: 16),
        Text(AppLocalizations.of(context).bankNameOptional, style: TextStyle(color: context.appTextSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        _Field(controller: _bankCtrl, hint: AppLocalizations.of(context).eGAbaAcledaWing),

        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _submitting ? null : _confirmAndSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              disabledBackgroundColor: AppTheme.accent.withValues(alpha: 0.4),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _submitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(AppLocalizations.of(context).requestWithdrawal, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
          ),
        ),
      ]),
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  final String label, value;
  const _ConfirmRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        width: 110,
        child: Text(label, style: TextStyle(color: context.appTextSecondary, fontSize: 13)),
      ),
      Expanded(
        child: Text(value,
            style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
      ),
    ]),
  );
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
      style: TextStyle(color: context.appTextPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: context.appTextSecondary),
        suffixText: suffix,
        suffixStyle: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w700),
        filled: true,
        fillColor: context.appSurface,
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
        Icon(Icons.error_outline, color: AppTheme.danger, size: 40),
        SizedBox(height: 12),
        Text(_error!, style: TextStyle(color: context.appTextSecondary), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: _load, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent), child: Text(AppLocalizations.of(context).retry)),
      ]));
    }
    if (_items.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.receipt_long_outlined, color: context.appTextSecondary, size: 48),
        SizedBox(height: 12),
        Text(AppLocalizations.of(context).noWithdrawalHistory, style: TextStyle(color: context.appTextSecondary, fontSize: 15)),
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
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: context.appSurface, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(Icons.send_rounded, color: statusColor, size: 20),
        ),
        SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(method.replaceAll('_', ' ').toUpperCase(),
                style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
            if (short.isNotEmpty)
              Text(short, style: TextStyle(color: context.appTextSecondary, fontSize: 11)),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('$amount ៛', style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
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
