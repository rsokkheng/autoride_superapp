import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class AdminTransactionsScreen extends StatefulWidget {
  const AdminTransactionsScreen({super.key});

  @override
  State<AdminTransactionsScreen> createState() => _AdminTransactionsScreenState();
}

class _AdminTransactionsScreenState extends State<AdminTransactionsScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  String? _typeFilter;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await ApiService.getAdminTransactions(type: _typeFilter);
      if (!mounted) return;
      setState(() { _items = list; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          PopupMenuButton<String?>(
            color: AppTheme.surface,
            icon: Icon(Icons.filter_list_rounded, color: _typeFilter != null ? AppTheme.accent : AppTheme.textSecondary),
            onSelected: (v) { setState(() => _typeFilter = v); _load(); },
            itemBuilder: (_) => const [
              PopupMenuItem(value: null,       child: Text('All',      style: TextStyle(color: AppTheme.textPrimary))),
              PopupMenuItem(value: 'credit',   child: Text('Credit',   style: TextStyle(color: AppTheme.textPrimary))),
              PopupMenuItem(value: 'debit',    child: Text('Debit',    style: TextStyle(color: AppTheme.textPrimary))),
              PopupMenuItem(value: 'topup',    child: Text('Top-up',   style: TextStyle(color: AppTheme.textPrimary))),
              PopupMenuItem(value: 'withdraw', child: Text('Withdraw', style: TextStyle(color: AppTheme.textPrimary))),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.error_outline, color: AppTheme.danger, size: 40), const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: AppTheme.textSecondary), textAlign: TextAlign.center), const SizedBox(height: 16),
                  ElevatedButton(onPressed: _load, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent), child: const Text('Retry')),
                ]))
              : _items.isEmpty
                  ? const Center(child: Text('No transactions.', style: TextStyle(color: AppTheme.textSecondary)))
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppTheme.accent,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final t     = _items[i];
                          final type  = t['type'] as String? ?? '—';
                          final amt   = t['amount_khr'] ?? t['amount'] ?? '—';
                          final user  = (t['user'] as Map?)?['name'] as String? ?? t['user_name'] as String? ?? '—';
                          final desc  = t['description'] as String? ?? t['note'] as String? ?? '';
                          final date  = t['created_at'] as String? ?? '';
                          final short = date.length >= 10 ? date.substring(0, 10) : date;
                          final isCredit = type == 'credit' || type == 'topup';
                          final color = isCredit ? AppTheme.success : AppTheme.danger;

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12)),
                            child: Row(children: [
                              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                                child: Icon(isCredit ? Icons.add : Icons.remove, color: color, size: 16)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(user, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                                  if (desc.isNotEmpty) Text(desc, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  if (short.isNotEmpty) Text(short, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                                ]),
                              ),
                              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                Text('${isCredit ? '+' : '-'}$amt ៛', style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14)),
                                Container(margin: const EdgeInsets.only(top: 3), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1), decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                                  child: Text(type.toUpperCase(), style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700))),
                              ]),
                            ]),
                          );
                        },
                      ),
                    ),
    );
  }
}
