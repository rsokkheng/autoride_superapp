import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

const _green = Color(0xFF00C48C);

class AdminDriverApprovalScreen extends StatefulWidget {
  const AdminDriverApprovalScreen({super.key});

  @override
  State<AdminDriverApprovalScreen> createState() =>
      _AdminDriverApprovalScreenState();
}

class _AdminDriverApprovalScreenState
    extends State<AdminDriverApprovalScreen> {
  List<Map<String, dynamic>> _drivers = [];
  bool    _loading = true;
  String? _error;
  final Set<int> _processing = {};

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await ApiService.getAdminPendingDrivers();
      if (mounted) setState(() { _drivers = list; _loading = false; });
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _approve(Map<String, dynamic> driver) async {
    final id = driver['id'] as int;
    setState(() => _processing.add(id));
    try {
      await ApiService.adminApproveDriver(id, action: 'approve');
      if (!mounted) return;
      setState(() {
        _drivers.removeWhere((d) => d['id'] == id);
        _processing.remove(id);
      });
      _snack('Driver approved', _green);
    } on ApiException catch (e) {
      if (mounted) { setState(() => _processing.remove(id)); _snack(e.message, AppTheme.danger); }
    } catch (_) {
      if (mounted) setState(() => _processing.remove(id));
    }
  }

  Future<void> _reject(Map<String, dynamic> driver) async {
    final id = driver['id'] as int;
    final reason = await _askReason();
    if (reason == null) return;
    setState(() => _processing.add(id));
    try {
      await ApiService.adminApproveDriver(id,
          action: 'reject', reason: reason);
      if (!mounted) return;
      setState(() {
        _drivers.removeWhere((d) => d['id'] == id);
        _processing.remove(id);
      });
      _snack('Driver rejected', AppTheme.warning);
    } on ApiException catch (e) {
      if (mounted) { setState(() => _processing.remove(id)); _snack(e.message, AppTheme.danger); }
    } catch (_) {
      if (mounted) setState(() => _processing.remove(id));
    }
  }

  Future<String?> _askReason() async {
    String reason = '';
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Rejection Reason'),
        content: TextField(
          autofocus: true,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Explain why the driver is rejected…',
            filled: true, fillColor: AppTheme.cardBg,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none),
          ),
          onChanged: (v) => reason = v,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, reason.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger, foregroundColor: Colors.white,
              elevation: 0, shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _snack(String msg, Color c) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), backgroundColor: c,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      appBar: AppBar(
        backgroundColor: AppTheme.surface, elevation: 0,
        leading: const BackButton(color: AppTheme.textPrimary),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Driver Approvals',
              style: TextStyle(color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700)),
          if (!_loading && _error == null)
            Text('${_drivers.length} pending',
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.textSecondary),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _green))
          : _error != null
              ? _ErrorView(error: _error!, onRetry: _load)
              : _drivers.isEmpty
                  ? const _EmptyView()
                  : RefreshIndicator(
                      onRefresh: _load, color: _green,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _drivers.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (_, i) => _DriverCard(
                          driver:     _drivers[i],
                          processing: _processing.contains(
                              _drivers[i]['id'] as int? ?? 0),
                          onApprove:  () => _approve(_drivers[i]),
                          onReject:   () => _reject(_drivers[i]),
                        ),
                      ),
                    ),
    );
  }
}

// ─── Driver card ──────────────────────────────────────────────────────────────

class _DriverCard extends StatelessWidget {
  final Map<String, dynamic> driver;
  final bool       processing;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _DriverCard({
    required this.driver, required this.processing,
    required this.onApprove, required this.onReject,
  });

  String get _name  => driver['name']  as String? ?? 'Unknown';
  String get _email => driver['email'] as String? ?? '';
  String get _phone => driver['phone'] as String? ?? '';
  String get _date  {
    final raw = driver['created_at'] as String?;
    if (raw == null) return '';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.35)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header row
        Row(children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppTheme.warning.withValues(alpha: 0.15),
            child: Text(_name.isNotEmpty ? _name[0].toUpperCase() : '?',
                style: const TextStyle(color: AppTheme.warning,
                    fontWeight: FontWeight.w800, fontSize: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_name, style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700, fontSize: 15)),
            if (_email.isNotEmpty)
              Text(_email, style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 12)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('PENDING',
                style: TextStyle(color: AppTheme.warning,
                    fontSize: 10, fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 12),

        // Info chips
        Wrap(spacing: 8, runSpacing: 6, children: [
          if (_phone.isNotEmpty) _InfoChip(Icons.phone_outlined, _phone),
          if (_date.isNotEmpty)  _InfoChip(Icons.calendar_today_outlined,
              'Applied $_date'),
        ]),
        const SizedBox(height: 14),

        // Vehicle info if present
        if (driver['vehicles'] != null) ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              const Icon(Icons.directions_car_outlined,
                  color: AppTheme.textSecondary, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(
                _vehicleText(driver['vehicles']),
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12),
              )),
            ]),
          ),
          const SizedBox(height: 12),
        ],

        // Action buttons
        processing
            ? const Center(child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: CircularProgressIndicator(color: _green,
                    strokeWidth: 2)))
            : Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.danger,
                      side: const BorderSide(color: AppTheme.danger),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Reject',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onApprove,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green, foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Approve',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ]),
      ]),
    );
  }

  String _vehicleText(dynamic vehicles) {
    if (vehicles is List && vehicles.isNotEmpty) {
      final v = vehicles.first as Map<String, dynamic>?;
      if (v == null) return 'Vehicle registered';
      final make  = v['make']  as String? ?? '';
      final model = v['model'] as String? ?? '';
      final plate = v['license_plate'] as String? ?? v['plate'] as String? ?? '';
      return '$make $model${plate.isNotEmpty ? ' · $plate' : ''}'.trim();
    }
    return 'Vehicle registered';
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String   label;
  const _InfoChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: AppTheme.textSecondary, size: 13),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(
          color: AppTheme.textSecondary, fontSize: 12)),
    ]);
}

// ─── Empty / Error ────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) => const Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.check_circle_outline, color: _green, size: 60),
      SizedBox(height: 16),
      Text('All caught up!', style: TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 17, fontWeight: FontWeight.w700)),
      SizedBox(height: 6),
      Text('No pending driver applications.',
          style: TextStyle(color: AppTheme.textSecondary)),
    ]),
  );
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline, color: AppTheme.danger, size: 48),
      const SizedBox(height: 12),
      Text(error, textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.textSecondary)),
      const SizedBox(height: 16),
      ElevatedButton(onPressed: onRetry,
          style: ElevatedButton.styleFrom(backgroundColor: _green,
              foregroundColor: Colors.white, elevation: 0),
          child: const Text('Retry')),
    ]),
  );
}
