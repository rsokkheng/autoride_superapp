import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class AdminTopupsScreen extends StatefulWidget {
  const AdminTopupsScreen({super.key});

  @override
  State<AdminTopupsScreen> createState() => _AdminTopupsScreenState();
}

class _AdminTopupsScreenState extends State<AdminTopupsScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  String _statusFilter = 'pending';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await ApiService.getAdminTopups(status: _statusFilter == 'all' ? null : _statusFilter);
      if (!mounted) return;
      setState(() { _items = list; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  Future<void> _approve(Map<String, dynamic> item) async {
    final id = (item['id'] as num?)?.toInt();
    if (id == null) return;
    try {
      await ApiService.approveAdminTopup(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Top-up approved & wallet credited.'), backgroundColor: AppTheme.success, behavior: SnackBarBehavior.floating));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: AppTheme.danger, behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _reject(Map<String, dynamic> item) async {
    final id = (item['id'] as num?)?.toInt();
    if (id == null) return;
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reject Top-up', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Reason:', style: TextStyle(color: AppTheme.textSecondary)), const SizedBox(height: 10),
          TextField(controller: ctrl, style: const TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(hintText: 'Enter reason', hintStyle: const TextStyle(color: AppTheme.textSecondary), filled: true, fillColor: AppTheme.cardBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary))),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger), child: const Text('Reject')),
        ],
      ),
    );
    if (ok != true || !mounted || ctrl.text.trim().isEmpty) return;
    try {
      await ApiService.rejectAdminTopup(id, ctrl.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rejected.'), backgroundColor: AppTheme.warning, behavior: SnackBarBehavior.floating));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: AppTheme.danger, behavior: SnackBarBehavior.floating));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      appBar: AppBar(
        title: const Text('Top-up Requests'),
        actions: [
          PopupMenuButton<String>(
            color: AppTheme.surface,
            icon: const Icon(Icons.filter_list_rounded),
            onSelected: (v) { setState(() => _statusFilter = v); _load(); },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'pending',  child: Text('Pending',  style: TextStyle(color: AppTheme.textPrimary))),
              PopupMenuItem(value: 'approved', child: Text('Approved', style: TextStyle(color: AppTheme.textPrimary))),
              PopupMenuItem(value: 'rejected', child: Text('Rejected', style: TextStyle(color: AppTheme.textPrimary))),
              PopupMenuItem(value: 'all',      child: Text('All',      style: TextStyle(color: AppTheme.textPrimary))),
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
                  ? const Center(child: Text('No top-up requests.', style: TextStyle(color: AppTheme.textSecondary)))
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppTheme.accent,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final t      = _items[i];
                          final amt    = t['amount_khr'] ?? t['amount'] ?? '—';
                          final status = t['status'] as String? ?? 'pending';
                          final user   = (t['user'] as Map?)?['name'] as String? ?? 'User';
                          final method = t['payment_method'] as String? ?? t['method'] as String? ?? '';
                          final isPending = status == 'pending';
                          final sc = status == 'approved' ? AppTheme.success : status == 'rejected' ? AppTheme.danger : AppTheme.warning;
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12)),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Expanded(child: Text(user, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 14))),
                                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: sc.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                                  child: Text(status.toUpperCase(), style: TextStyle(color: sc, fontSize: 10, fontWeight: FontWeight.w700))),
                              ]),
                              const SizedBox(height: 6),
                              Text('$amt ៛${method.isNotEmpty ? '  •  $method' : ''}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                              if (isPending) ...[
                                const SizedBox(height: 10),
                                Row(children: [
                                  Expanded(child: ElevatedButton(onPressed: () => _approve(t), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success, padding: const EdgeInsets.symmetric(vertical: 10), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text('Approve', style: TextStyle(fontWeight: FontWeight.w700)))),
                                  const SizedBox(width: 10),
                                  Expanded(child: OutlinedButton(onPressed: () => _reject(t), style: OutlinedButton.styleFrom(foregroundColor: AppTheme.danger, side: const BorderSide(color: AppTheme.danger), padding: const EdgeInsets.symmetric(vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.w700)))),
                                ]),
                              ],
                            ]),
                          );
                        },
                      ),
                    ),
    );
  }
}
