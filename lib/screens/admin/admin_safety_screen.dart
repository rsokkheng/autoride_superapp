import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class AdminSafetyScreen extends StatefulWidget {
  const AdminSafetyScreen({super.key});

  @override
  State<AdminSafetyScreen> createState() => _AdminSafetyScreenState();
}

class _AdminSafetyScreenState extends State<AdminSafetyScreen> {
  List<Map<String, dynamic>> _incidents = [];
  bool _loading = true;
  String? _error;
  String? _typeFilter;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await ApiService.getAdminSafetyIncidents(type: _typeFilter);
      if (!mounted) return;
      setState(() { _incidents = list; _loading = false; });
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
        title: const Text('Safety Incidents'),
        actions: [
          PopupMenuButton<String?>(
            color: AppTheme.surface,
            icon: Icon(Icons.filter_list_rounded, color: _typeFilter != null ? AppTheme.accent : AppTheme.textSecondary),
            onSelected: (v) { setState(() => _typeFilter = v); _load(); },
            itemBuilder: (_) => const [
              PopupMenuItem(value: null,    child: Text('All',         style: TextStyle(color: AppTheme.textPrimary))),
              PopupMenuItem(value: 'sos',   child: Text('SOS',         style: TextStyle(color: AppTheme.textPrimary))),
              PopupMenuItem(value: 'crash', child: Text('Crash',       style: TextStyle(color: AppTheme.textPrimary))),
              PopupMenuItem(value: 'report',child: Text('User Report', style: TextStyle(color: AppTheme.textPrimary))),
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
              : _incidents.isEmpty
                  ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.check_circle_outline, color: AppTheme.success, size: 48),
                      SizedBox(height: 12),
                      Text('No safety incidents.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
                    ]))
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppTheme.accent,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _incidents.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final inc   = _incidents[i];
                          final type  = inc['type'] as String? ?? 'incident';
                          final desc  = inc['description'] as String? ?? inc['message'] as String? ?? '';
                          final date  = inc['created_at'] as String? ?? '';
                          final short = date.length >= 16 ? date.substring(0, 16).replaceAll('T', ' ') : date;
                          final user  = (inc['user'] as Map?)?['name'] as String? ?? inc['user_name'] as String? ?? '—';
                          final status = inc['status'] as String? ?? 'open';
                          final isSos = type == 'sos';
                          final color = isSos ? AppTheme.danger : AppTheme.warning;
                          final resolved = status == 'resolved' || status == 'closed';

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: isSos && !resolved
                                  ? Border.all(color: AppTheme.danger.withValues(alpha: 0.4), width: 1.5)
                                  : null,
                            ),
                            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                                child: Icon(isSos ? Icons.sos_rounded : Icons.warning_amber_rounded, color: color, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Row(children: [
                                    Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2), decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                                      child: Text(type.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700))),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(user, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                    Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: resolved ? AppTheme.success.withValues(alpha: 0.12) : AppTheme.danger.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                                      child: Text(status.toUpperCase(), style: TextStyle(color: resolved ? AppTheme.success : AppTheme.danger, fontSize: 9, fontWeight: FontWeight.w700))),
                                  ]),
                                  if (desc.isNotEmpty) ...[
                                    const SizedBox(height: 5),
                                    Text(desc, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                                  ],
                                  if (short.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(short, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                                  ],
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
