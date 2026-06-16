import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class ScheduledRidesScreen extends StatefulWidget {
  const ScheduledRidesScreen({super.key});

  @override
  State<ScheduledRidesScreen> createState() => _ScheduledRidesScreenState();
}

class _ScheduledRidesScreenState extends State<ScheduledRidesScreen> {
  List<Map<String, dynamic>> _rides = [];
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
      final rides = await ApiService.getScheduledRides();
      if (!mounted) return;
      setState(() { _rides = rides; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  String _formatDate(String? scheduledAt) {
    if (scheduledAt == null) return '';
    final dt = DateTime.tryParse(scheduledAt);
    if (dt == null) return scheduledAt;
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final wd  = weekdays[dt.weekday - 1];
    final mon = months[dt.month - 1];
    final day = dt.day;
    final h   = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final min = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$wd, $mon $day · ${h.toString().padLeft(2, '0')}:$min $ampm';
  }

  String _countdown(String? scheduledAt) {
    if (scheduledAt == null) return '';
    final dt = DateTime.tryParse(scheduledAt);
    if (dt == null) return '';
    final diff = dt.difference(DateTime.now());
    if (diff.isNegative) return 'Past';
    if (diff.inDays > 1) return 'in ${diff.inDays} days';
    if (diff.inHours >= 1) return 'in ${diff.inHours} hrs';
    return 'in ${diff.inMinutes} min';
  }

  Future<void> _confirmCancel(Map<String, dynamic> ride) async {
    final id = ride['id'] as int?;
    if (id == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Ride',
            style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
        content: const Text(
          'Are you sure you want to cancel this scheduled ride?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep', style: TextStyle(color: AppTheme.accent)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel Ride', style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await ApiService.cancelScheduledRide(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ride cancelled.'), backgroundColor: AppTheme.success),
      );
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppTheme.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      appBar: AppBar(
        title: const Text('Scheduled Rides'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.error_outline, color: AppTheme.danger, size: 48),
                      const SizedBox(height: 12),
                      Text(_error!, textAlign: TextAlign.center,
                          style: const TextStyle(color: AppTheme.textSecondary)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _load, child: const Text('Retry')),
                    ]),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppTheme.accent,
                  child: _rides.isEmpty
                      ? ListView(children: [
                          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                          Column(mainAxisSize: MainAxisSize.min, children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppTheme.accent.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.calendar_today_outlined,
                                  color: AppTheme.accent, size: 48),
                            ),
                            const SizedBox(height: 16),
                            const Text('No upcoming rides',
                                style: TextStyle(color: AppTheme.textPrimary,
                                    fontSize: 18, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 8),
                            const Text('Schedule a ride to see it here.',
                                style: TextStyle(color: AppTheme.textSecondary)),
                          ]),
                        ])
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _rides.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, i) => _RideCard(
                            ride: _rides[i],
                            formattedDate: _formatDate(_rides[i]['scheduled_at'] as String?),
                            countdown: _countdown(_rides[i]['scheduled_at'] as String?),
                            onCancel: () => _confirmCancel(_rides[i]),
                          ),
                        ),
                ),
    );
  }
}

class _RideCard extends StatelessWidget {
  final Map<String, dynamic> ride;
  final String formattedDate;
  final String countdown;
  final VoidCallback onCancel;

  const _RideCard({
    required this.ride,
    required this.formattedDate,
    required this.countdown,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final pickup   = ride['pickup_address']  as String? ?? '--';
    final dropoff  = ride['dropoff_address'] as String? ?? '--';
    final service  = ride['service_type']    as String? ?? 'ride';
    final fareKhr  = ride['fare_khr'] ?? ride['estimated_fare'] ?? 0;
    final isRide   = service.toLowerCase() != 'delivery';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(formattedDate,
                  style: const TextStyle(color: AppTheme.textPrimary,
                      fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            if (countdown.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: countdown == 'Past'
                      ? AppTheme.textSecondary.withValues(alpha: 0.15)
                      : AppTheme.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(countdown,
                    style: TextStyle(
                      color: countdown == 'Past' ? AppTheme.textSecondary : AppTheme.accent,
                      fontSize: 12, fontWeight: FontWeight.w600,
                    )),
              ),
          ]),
          const SizedBox(height: 12),
          _AddressRow(icon: Icons.radio_button_checked, color: AppTheme.success, label: pickup),
          const SizedBox(height: 6),
          _AddressRow(icon: Icons.location_on, color: AppTheme.danger, label: dropoff),
          const SizedBox(height: 12),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isRide
                    ? AppTheme.accent.withValues(alpha: 0.1)
                    : AppTheme.accentOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(isRide ? Icons.directions_car_outlined : Icons.delivery_dining_outlined,
                    size: 14,
                    color: isRide ? AppTheme.accent : AppTheme.accentOrange),
                const SizedBox(width: 4),
                Text(isRide ? 'Ride' : 'Delivery',
                    style: TextStyle(
                      color: isRide ? AppTheme.accent : AppTheme.accentOrange,
                      fontSize: 12, fontWeight: FontWeight.w600,
                    )),
              ]),
            ),
            const Spacer(),
            Text(AppTheme.khr(fareKhr is num ? fareKhr : int.tryParse(fareKhr.toString()) ?? 0),
                style: const TextStyle(color: AppTheme.textPrimary,
                    fontSize: 15, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Modify coming soon.')),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.accent),
                  foregroundColor: AppTheme.accent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Modify'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextButton(
                onPressed: onCancel,
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.danger,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _AddressRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  const _AddressRow({required this.icon, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, color: color, size: 16),
      const SizedBox(width: 8),
      Expanded(child: Text(label,
          maxLines: 1, overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
    ]);
  }
}
