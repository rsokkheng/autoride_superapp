import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class AdminDeliveriesScreen extends StatefulWidget {
  const AdminDeliveriesScreen({super.key});

  @override
  State<AdminDeliveriesScreen> createState() => _AdminDeliveriesScreenState();
}

class _AdminDeliveriesScreenState extends State<AdminDeliveriesScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  String? _statusFilter;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await ApiService.getAdminDeliveries(status: _statusFilter);
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
      backgroundColor: context.appBackground,
      appBar: AppBar(
        title: Text('Deliveries'),
        actions: [
          PopupMenuButton<String?>(
            color: context.appSurface,
            icon: Icon(Icons.filter_list_rounded, color: _statusFilter != null ? AppTheme.accent : context.appTextSecondary),
            onSelected: (v) { setState(() => _statusFilter = v); _load(); },
            itemBuilder: (_) => [
              PopupMenuItem(value: null,          child: Text('All',         style: TextStyle(color: context.appTextPrimary))),
              PopupMenuItem(value: 'pending',     child: Text('Pending',     style: TextStyle(color: context.appTextPrimary))),
              PopupMenuItem(value: 'in_progress', child: Text('In Progress', style: TextStyle(color: context.appTextPrimary))),
              PopupMenuItem(value: 'completed',   child: Text('Completed',   style: TextStyle(color: context.appTextPrimary))),
              PopupMenuItem(value: 'cancelled',   child: Text('Cancelled',   style: TextStyle(color: context.appTextPrimary))),
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
                  ? Center(child: Text('No deliveries found.', style: TextStyle(color: context.appTextSecondary)))
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppTheme.accent,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final d      = _items[i];
                          final id     = d['id']?.toString() ?? '—';
                          final status = d['status'] as String? ?? 'unknown';
                          final type   = d['service_type'] as String? ?? d['type'] as String? ?? '';
                          final from   = d['pickup_address']  as String? ?? '—';
                          final to     = d['dropoff_address'] as String? ?? '—';

                          final Color sc = status == 'completed' ? AppTheme.success
                              : status == 'cancelled' ? AppTheme.danger
                              : status == 'in_progress' ? AppTheme.accent : AppTheme.warning;

                          return Container(
                            padding: EdgeInsets.all(14),
                            decoration: BoxDecoration(color: context.appSurface, borderRadius: BorderRadius.circular(12)),
                            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Container(padding: EdgeInsets.all(8), decoration: BoxDecoration(color: sc.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                child: Icon(Icons.local_shipping_rounded, color: sc, size: 20)),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Row(children: [
                                    Text('#$id', style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
                                    if (type.isNotEmpty) ...[SizedBox(width: 6), Container(padding: EdgeInsets.symmetric(horizontal: 6, vertical: 1), decoration: BoxDecoration(color: AppTheme.accentOrange.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)), child: Text(type, style: TextStyle(color: AppTheme.accentOrange, fontSize: 9, fontWeight: FontWeight.w700)))],
                                    Spacer(),
                                    Container(padding: EdgeInsets.symmetric(horizontal: 6, vertical: 1), decoration: BoxDecoration(color: sc.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)), child: Text(status.toUpperCase(), style: TextStyle(color: sc, fontSize: 9, fontWeight: FontWeight.w700))),
                                  ]),
                                  SizedBox(height: 4),
                                  Text('From: $from', style: TextStyle(color: context.appTextSecondary, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  Text('To: $to',     style: TextStyle(color: context.appTextSecondary, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                                ]),
                              ),
                            ]),
                          );
                        },
                      ),
                    ),
    );
  }
}
