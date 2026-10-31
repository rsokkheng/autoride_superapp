import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../l10n/app_localizations.dart';

class AdminWithdrawalsScreen extends StatefulWidget {
  const AdminWithdrawalsScreen({super.key});

  @override
  State<AdminWithdrawalsScreen> createState() => _AdminWithdrawalsScreenState();
}

class _AdminWithdrawalsScreenState extends State<AdminWithdrawalsScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  String _statusFilter = 'pending';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await ApiService.getAdminWithdrawals(status: _statusFilter == 'all' ? null : _statusFilter);
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
    final noteCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.appSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(AppLocalizations.of(context).trApproveWithdrawal, style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(AppLocalizations.of(context).trAddNoteOptional, style: TextStyle(color: context.appTextSecondary)),
          SizedBox(height: 10),
          TextField(controller: noteCtrl, style: TextStyle(color: context.appTextPrimary),
            decoration: InputDecoration(hintText: AppLocalizations.of(context).trEgTransferredAba, hintStyle: TextStyle(color: context.appTextSecondary), filled: true, fillColor: context.appCardBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(context).cancel, style: TextStyle(color: context.appTextSecondary))),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success), child: Text(AppLocalizations.of(context).trApprove)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ApiService.approveAdminWithdrawal(id, note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).trApprovedDot), backgroundColor: AppTheme.success, behavior: SnackBarBehavior.floating));
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
        title: Text(AppLocalizations.of(context).trRejectWithdrawal, style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(AppLocalizations.of(context).trReasonRequired, style: TextStyle(color: context.appTextSecondary)),
          SizedBox(height: 10),
          TextField(controller: ctrl, style: TextStyle(color: context.appTextPrimary),
            decoration: InputDecoration(hintText: AppLocalizations.of(context).trEgInvalidAccount, hintStyle: TextStyle(color: context.appTextSecondary), filled: true, fillColor: context.appCardBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(context).cancel, style: TextStyle(color: context.appTextSecondary))),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger), child: Text(AppLocalizations.of(context).trReject)),
        ],
      ),
    );
    if (ok != true || !mounted || ctrl.text.trim().isEmpty) return;
    try {
      await ApiService.rejectAdminWithdrawal(id, ctrl.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).trRejectedDot), backgroundColor: AppTheme.warning, behavior: SnackBarBehavior.floating));
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
        title: Text(AppLocalizations.of(context).trWithdrawals),
        actions: [
          PopupMenuButton<String>(
            color: context.appSurface,
            icon: Icon(Icons.filter_list_rounded, color: _statusFilter != 'all' ? AppTheme.accent : context.appTextSecondary),
            onSelected: (v) { setState(() => _statusFilter = v); _load(); },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'pending',   child: Text(AppLocalizations.of(context).trPending,   style: TextStyle(color: context.appTextPrimary))),
              PopupMenuItem(value: 'approved',  child: Text(AppLocalizations.of(context).trApproved,  style: TextStyle(color: context.appTextPrimary))),
              PopupMenuItem(value: 'rejected',  child: Text(AppLocalizations.of(context).trRejected,  style: TextStyle(color: context.appTextPrimary))),
              PopupMenuItem(value: 'all',       child: Text(AppLocalizations.of(context).all,       style: TextStyle(color: context.appTextPrimary))),
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
                  ElevatedButton(onPressed: _load, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent), child: Text(AppLocalizations.of(context).retry)),
                ]))
              : _items.isEmpty
                  ? Center(child: Text(AppLocalizations.of(context).trNoWithdrawalsFound, style: TextStyle(color: context.appTextSecondary)))
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppTheme.accent,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final w      = _items[i];
                          final amt    = w['amount_khr'] ?? w['amount'] ?? '—';
                          final status = w['status'] as String? ?? 'pending';
                          final method = w['payment_method'] as String? ?? '';
                          final user   = (w['user'] as Map?)?['name'] as String? ?? 'User';
                          final isPending = status == 'pending';

                          final Color sc = status == 'approved' ? AppTheme.success : status == 'rejected' ? AppTheme.danger : AppTheme.warning;

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
                              Text('$amt ៛  •  ${method.replaceAll('_', ' ')}', style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
                              if (isPending) ...[
                                const SizedBox(height: 10),
                                Row(children: [
                                  Expanded(child: ElevatedButton(
                                    onPressed: () => _approve(w),
                                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success, padding: const EdgeInsets.symmetric(vertical: 10), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                                    child: Text(AppLocalizations.of(context).trApprove, style: TextStyle(fontWeight: FontWeight.w700)),
                                  )),
                                  const SizedBox(width: 10),
                                  Expanded(child: OutlinedButton(
                                    onPressed: () => _reject(w),
                                    style: OutlinedButton.styleFrom(foregroundColor: AppTheme.danger, side: const BorderSide(color: AppTheme.danger), padding: const EdgeInsets.symmetric(vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                                    child: Text(AppLocalizations.of(context).trReject, style: TextStyle(fontWeight: FontWeight.w700)),
                                  )),
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
