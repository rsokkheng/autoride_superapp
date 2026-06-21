import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class AdminRidesScreen extends StatefulWidget {
  const AdminRidesScreen({super.key});

  @override
  State<AdminRidesScreen> createState() => _AdminRidesScreenState();
}

class _AdminRidesScreenState extends State<AdminRidesScreen> {
  List<Map<String, dynamic>> _rides = [];
  bool _loading = true;
  String? _error;
  String? _statusFilter;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await ApiService.getAdminRides(status: _statusFilter);
      if (!mounted) return;
      setState(() { _rides = list; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  Future<void> _cancel(Map<String, dynamic> ride) async {
    final id = (ride['id'] as num?)?.toInt();
    if (id == null) return;
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.appSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Cancel Ride', style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Reason for cancellation:', style: TextStyle(color: context.appTextSecondary)),
          SizedBox(height: 10),
          TextField(
            controller: ctrl,
            style: TextStyle(color: context.appTextPrimary),
            decoration: InputDecoration(hintText: 'e.g. Policy violation', hintStyle: TextStyle(color: context.appTextSecondary), filled: true, fillColor: context.appCardBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Back', style: TextStyle(color: context.appTextSecondary))),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger), child: const Text('Cancel Ride')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ApiService.cancelAdminRide(id, ctrl.text.trim().isEmpty ? 'Admin cancelled' : ctrl.text.trim());
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
        title: Text('Rides'),
        actions: [
          PopupMenuButton<String?>(
            color: context.appSurface,
            icon: Icon(Icons.filter_list_rounded, color: _statusFilter != null ? AppTheme.accent : context.appTextSecondary),
            onSelected: (v) { setState(() => _statusFilter = v); _load(); },
            itemBuilder: (_) => [
              PopupMenuItem(value: null,         child: Text('All',       style: TextStyle(color: context.appTextPrimary))),
              PopupMenuItem(value: 'pending',    child: Text('Pending',   style: TextStyle(color: context.appTextPrimary))),
              PopupMenuItem(value: 'active',     child: Text('Active',    style: TextStyle(color: context.appTextPrimary))),
              PopupMenuItem(value: 'completed',  child: Text('Completed', style: TextStyle(color: context.appTextPrimary))),
              PopupMenuItem(value: 'cancelled',  child: Text('Cancelled', style: TextStyle(color: context.appTextPrimary))),
            ],
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.error_outline, color: AppTheme.danger, size: 40),
                  SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: context.appTextSecondary), textAlign: TextAlign.center),
                  SizedBox(height: 16),
                  ElevatedButton(onPressed: _load, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent), child: Text('Retry')),
                ]))
              : _rides.isEmpty
                  ? Center(child: Text('No rides found.', style: TextStyle(color: context.appTextSecondary)))
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppTheme.accent,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _rides.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _RideTile(ride: _rides[i], onCancel: () => _cancel(_rides[i])),
                      ),
                    ),
    );
  }
}

class _RideTile extends StatelessWidget {
  final Map<String, dynamic> ride;
  final VoidCallback onCancel;
  const _RideTile({required this.ride, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final id      = ride['id']?.toString() ?? '—';
    final status  = ride['status'] as String? ?? 'unknown';
    final pickup  = ride['pickup_address']  as String? ?? ride['from'] as String? ?? '—';
    final dropoff = ride['dropoff_address'] as String? ?? ride['to']   as String? ?? '—';
    final fare    = ride['fare_khr'] ?? ride['fare'] ?? '—';
    final active  = status == 'pending' || status == 'active' || status == 'in_progress';

    final Color statusColor = status == 'completed' ? AppTheme.success
        : status == 'cancelled' ? AppTheme.danger
        : status == 'active' || status == 'in_progress' ? AppTheme.accent
        : AppTheme.warning;

    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(color: context.appSurface, borderRadius: BorderRadius.circular(12)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(Icons.directions_car_rounded, color: statusColor, size: 20),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('#$id', style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w700)),
              ),
            ]),
            SizedBox(height: 4),
            Text('From: $pickup', style: TextStyle(color: context.appTextSecondary, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('To: $dropoff',   style: TextStyle(color: context.appTextSecondary, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('Fare: $fare ៛',  style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w600, fontSize: 12)),
          ]),
        ),
        if (active)
          TextButton(
            onPressed: onCancel,
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger, padding: EdgeInsets.zero, minimumSize: const Size(50, 30)),
            child: const Text('Cancel', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
      ]),
    );
  }
}
