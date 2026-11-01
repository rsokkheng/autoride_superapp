import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../l10n/app_localizations.dart';
import '../../models/wallet_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/wallet_txn_tile.dart';

/// Full wallet history: grouped by day, filterable (all / income /
/// deductions), loads the next page automatically near the bottom. The
/// earnings tab only shows the latest few so the withdraw button stays close.
class DriverTransactionsScreen extends StatefulWidget {
  const DriverTransactionsScreen({super.key});

  @override
  State<DriverTransactionsScreen> createState() => _DriverTransactionsScreenState();
}

enum _TxFilter { all, income, deductions }

class _DriverTransactionsScreenState extends State<DriverTransactionsScreen> {
  final _scroll = ScrollController();
  final List<WalletTransactionModel> _items = [];
  int  _page = 1, _lastPage = 1, _total = 0;
  bool _loading = true, _loadingMore = false;
  String? _error;
  _TxFilter _filter = _TxFilter.all;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 300) _loadMore();
    });
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final r = await ApiService.getWalletTransactions(page: 1);
      if (!mounted) return;
      setState(() {
        _items..clear()..addAll(r.transactions);
        _page = r.currentPage; _lastPage = r.lastPage; _total = r.total;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e is ApiException ? e.message : e.toString(); _loading = false; });
    }
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || _page >= _lastPage) return;
    setState(() => _loadingMore = true);
    try {
      final r = await ApiService.getWalletTransactions(page: _page + 1);
      if (!mounted) return;
      setState(() {
        _items.addAll(r.transactions);
        _page = r.currentPage; _lastPage = r.lastPage;
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  List<WalletTransactionModel> get _visible => switch (_filter) {
        _TxFilter.all        => _items,
        _TxFilter.income     => _items.where((t) => t.isCredit).toList(),
        _TxFilter.deductions => _items.where((t) => t.isDebit).toList(),
      };

  String _dayLabel(DateTime d, AppLocalizations l) {
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day   = DateTime(d.year, d.month, d.day);
    if (day == today) return l.today;
    if (day == today.subtract(const Duration(days: 1))) return l.yesterday;
    try {
      return DateFormat.yMMMd(Localizations.localeOf(context).languageCode).format(d);
    } catch (_) {
      return DateFormat('dd/MM/yyyy').format(d);
    }
  }

  // Day headers between groups of rows.
  List<Widget> _rows(AppLocalizations l) {
    final out = <Widget>[];
    String? lastDay;
    for (final t in _visible) {
      final d = DateTime.tryParse(t.createdAt)?.toLocal();
      final label = d == null ? '' : _dayLabel(d, l);
      if (label != lastDay) {
        lastDay = label;
        out.add(Padding(
          padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
          child: Text(label,
              style: TextStyle(color: context.appTextSecondary, fontSize: 12, fontWeight: FontWeight.w700)),
        ));
      }
      out.add(WalletTxnTile(txn: t));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.transactionHistory),
        actions: [
          if (_total > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(l.drvTotalCount(_total),
                    style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
              ),
            ),
        ],
      ),
      body: Column(children: [
        // Filter chips
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(children: [
            for (final (f, label) in [
              (_TxFilter.all, l.all),
              (_TxFilter.income, l.txFilterIncome),
              (_TxFilter.deductions, l.txFilterDeductions),
            ]) ...[
              ChoiceChip(
                label: Text(label),
                selected: _filter == f,
                onSelected: (_) { setState(() => _filter = f); _loadMore(); },
                selectedColor: AppTheme.accent,
                backgroundColor: context.appCardBg,
                labelStyle: TextStyle(
                  color: _filter == f ? Colors.white : context.appTextPrimary,
                  fontWeight: FontWeight.w600, fontSize: 13,
                ),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              const SizedBox(width: 8),
            ],
          ]),
        ),
        Expanded(
          child: RefreshIndicator(
            color: AppTheme.accent,
            onRefresh: _load,
            child: _loading
                ? ListView(children: const [
                    SizedBox(height: 120),
                    Center(child: CircularProgressIndicator(color: AppTheme.accent)),
                  ])
                : _error != null
                    ? ListView(padding: const EdgeInsets.all(32), children: [
                        Text(_error!, textAlign: TextAlign.center,
                            style: TextStyle(color: context.appTextSecondary)),
                        const SizedBox(height: 12),
                        Center(child: TextButton(onPressed: _load, child: Text(l.retry))),
                      ])
                    : _visible.isEmpty
                        ? ListView(padding: const EdgeInsets.all(48), children: [
                            Icon(Icons.receipt_long_outlined, size: 48,
                                color: context.appTextSecondary.withValues(alpha: 0.5)),
                            const SizedBox(height: 12),
                            Text(l.txNoneForFilter, textAlign: TextAlign.center,
                                style: TextStyle(color: context.appTextSecondary)),
                          ])
                        : ListView(
                            controller: _scroll,
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            children: [
                              ..._rows(l),
                              if (_loadingMore)
                                const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(child: CircularProgressIndicator(color: AppTheme.accent)),
                                ),
                            ],
                          ),
          ),
        ),
      ]),
    );
  }
}
