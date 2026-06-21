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
        backgroundColor: context.appSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Reject Top-up', style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Reason:', style: TextStyle(color: context.appTextSecondary)), SizedBox(height: 10),
          TextField(controller: ctrl, style: TextStyle(color: context.appTextPrimary),
            decoration: InputDecoration(hintText: 'Enter reason', hintStyle: TextStyle(color: context.appTextSecondary), filled: true, fillColor: context.appCardBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: TextStyle(color: context.appTextSecondary))),
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
      backgroundColor: context.appBackground,
      appBar: AppBar(
        title: Text('Top-up Requests'),
        actions: [
          PopupMenuButton<String>(
            color: context.appSurface,
            icon: const Icon(Icons.filter_list_rounded),
            onSelected: (v) { setState(() => _statusFilter = v); _load(); },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'pending',  child: Text('Pending',  style: TextStyle(color: context.appTextPrimary))),
              PopupMenuItem(value: 'approved', child: Text('Approved', style: TextStyle(color: context.appTextPrimary))),
              PopupMenuItem(value: 'rejected', child: Text('Rejected', style: TextStyle(color: context.appTextPrimary))),
              PopupMenuItem(value: 'all',      child: Text('All',      style: TextStyle(color: context.appTextPrimary))),
            ],
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.error_outline, color: AppTheme.danger, size: 40), SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: context.appTextSecondary), textAlign: TextAlign.center), SizedBox(height: 16),
                  ElevatedButton(onPressed: _load, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent), child: Text('Retry')),
                ]))
              : _items.isEmpty
                  ? Center(child: Text('No top-up requests.', style: TextStyle(color: context.appTextSecondary)))
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
                            padding: EdgeInsets.all(14),
                            decoration: BoxDecoration(color: context.appSurface, borderRadius: BorderRadius.circular(12)),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Expanded(child: Text(user, style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w700, fontSize: 14))),
                                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: sc.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                                  child: Text(status.toUpperCase(), style: TextStyle(color: sc, fontSize: 10, fontWeight: FontWeight.w700))),
                              ]),
                              const SizedBox(height: 6),
                              Text('$amt ៛${method.isNotEmpty ? '  •  $method' : ''}', style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
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
