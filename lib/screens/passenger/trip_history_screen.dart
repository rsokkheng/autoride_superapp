import 'package:flutter/material.dart';
import 'package:autoride_superapp/theme/app_theme.dart';
import 'package:autoride_superapp/widgets/common_widgets.dart';
import '../../services/api_service.dart';
import '../../models/ride_model.dart';
import 'rate_driver_screen.dart';

class TripHistoryScreen extends StatefulWidget {
  const TripHistoryScreen({super.key});

  @override
  State<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends State<TripHistoryScreen> {
  List<RideModel> _rides = [];
  bool _loading = true;
  String? _error;
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _loadRides();
  }

  Future<void> _loadRides() async {
    setState(() { _loading = true; _error = null; });
    try {
      final rides = await ApiService.getRides();
      if (!mounted) return;
      setState(() { _rides = rides; _loading = false; });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  List<RideModel> get _filtered {
    if (_filter == 'All') return _rides;
    final statusKey = _filter.toLowerCase().replaceAll(' ', '_');
    return _rides.where((r) => r.status == statusKey).toList();
  }

  int get _completedCount => _rides.where((r) => r.isCompleted).length;

  int get _totalSpent => _rides
      .where((r) => r.isCompleted)
      .fold(0, (sum, r) => sum + r.fareKhr);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRides,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterSheet(context),
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
                      const Icon(Icons.error_outline, color: AppTheme.danger, size: 40),
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: AppTheme.danger), textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadRides,
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
                        child: const Text('Retry', style: TextStyle(color: AppTheme.primary)),
                      ),
                    ]),
                  ),
                )
              : Column(
                  children: [
                    // Summary stats
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF00E676)]),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatBubble(label: 'Total Trips', value: '${_rides.length}',         icon: Icons.directions_car),
                          _StatBubble(label: 'Completed',   value: '$_completedCount',         icon: Icons.check_circle_outline,           highlight: true),
                          _StatBubble(label: 'Total Spent', value: AppTheme.khr(_totalSpent),  icon: Icons.account_balance_wallet_outlined, highlight: true),
                        ],
                      ),
                    ),

                    // Filter chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: ['All', 'Completed', 'In Progress', 'Pending', 'Cancelled'].map((f) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _filter = f),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: _filter == f ? AppTheme.accent : AppTheme.surface,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(f, style: TextStyle(
                                color: _filter == f ? AppTheme.primary : AppTheme.textSecondary,
                                fontWeight: FontWeight.w600, fontSize: 13,
                              )),
                            ),
                          ),
                        )).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Expanded(
                      child: _filtered.isEmpty
                          ? const Center(child: Text('No trips found', style: TextStyle(color: AppTheme.textSecondary)))
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                              itemCount: _filtered.length,
                              itemBuilder: (_, i) {
                                final ride = _filtered[i];
                                return _TripHistoryCard(
                                  ride: ride,
                                  onRate: () => Navigator.push(context, MaterialPageRoute(
                                    builder: (_) => RateDriverScreen(
                                      rideId:      ride.id,
                                      driverName:  ride.driver?.name ?? 'Driver',
                                      fare:        AppTheme.khr(ride.fareKhr),
                                      distanceKm:  ride.distanceKm,
                                      durationMin: ride.durationMin,
                                    ),
                                  )),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Filter Trips', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          Wrap(spacing: 8, children: ['All', 'Completed', 'In Progress', 'Pending', 'Cancelled'].map((f) =>
            GestureDetector(
              onTap: () { setState(() => _filter = f); Navigator.pop(context); },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _filter == f ? AppTheme.accent : AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(f, style: TextStyle(color: _filter == f ? AppTheme.primary : AppTheme.textSecondary, fontWeight: FontWeight.w600)),
              ),
            )
          ).toList()),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }
}

class _StatBubble extends StatelessWidget {
  final String   label, value;
  final IconData icon;
  final bool     highlight;
  const _StatBubble({
    required this.label, required this.value, required this.icon,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Icon(icon, color: Colors.white, size: 22),
      const SizedBox(height: 4),
      Text(value,
          style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800, fontSize: 16)),
      Text(label,
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 11, fontWeight: FontWeight.w500)),
    ]);
  }
}

class _TripHistoryCard extends StatelessWidget {
  final RideModel ride;
  final VoidCallback onRate;
  const _TripHistoryCard({required this.ride, required this.onRate});

  Color get _statusColor {
    switch (ride.status) {
      case 'completed':   return AppTheme.success;
      case 'cancelled':   return AppTheme.danger;
      case 'in_progress': return AppTheme.accentOrange;
      default:            return AppTheme.textSecondary;
    }
  }

  String get _statusLabel {
    switch (ride.status) {
      case 'in_progress': return 'In Progress';
      case 'completed':   return 'Completed';
      case 'cancelled':   return 'Cancelled';
      case 'pending':     return 'Pending';
      default:            return ride.status;
    }
  }

  String get _dateLabel {
    if (ride.createdAt.length < 16) return ride.createdAt;
    final date = ride.createdAt.substring(0, 10);
    final time = ride.createdAt.substring(11, 16);
    return '$date · $time';
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = ride.isCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                StatusBadge(label: _statusLabel, color: _statusColor),
                const Spacer(),
                Text(_dateLabel, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Column(children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.accent, shape: BoxShape.circle)),
                  Container(width: 1, height: 20, color: AppTheme.textSecondary),
                  const Icon(Icons.location_on, color: AppTheme.accentOrange, size: 10),
                ]),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(ride.pickupAddress,  style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 12),
                  Text(ride.dropoffAddress, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(AppTheme.khr(ride.fareKhr), style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w800, fontSize: 16)),
                  Text(ride.serviceType,  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                ]),
              ]),
              if (ride.driver != null) ...[
                const SizedBox(height: 10),
                const Divider(color: AppTheme.cardBg, height: 1),
                const SizedBox(height: 8),
                Row(children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppTheme.accentOrange.withValues(alpha: 0.2),
                    child: Text(
                      ride.driver!.name.isNotEmpty ? ride.driver!.name[0] : 'D',
                      style: const TextStyle(color: AppTheme.accentOrange, fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(ride.driver!.name, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ]),
              ],
            ]),
          ),
          if (isCompleted)
            GestureDetector(
              onTap: onRate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: const BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                ),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.refresh, color: AppTheme.accent, size: 14),
                  SizedBox(width: 6),
                  Text('Book again', style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w600, fontSize: 13)),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}
