import 'package:flutter/material.dart';
import 'package:autoride_superapp/theme/app_theme.dart';
import 'package:autoride_superapp/widgets/common_widgets.dart';

class ChargingStationsScreen extends StatefulWidget {
  const ChargingStationsScreen({super.key});

  @override
  State<ChargingStationsScreen> createState() => _ChargingStationsScreenState();
}

class _ChargingStationsScreenState extends State<ChargingStationsScreen> {
  bool _showList = false;

  final _stations = [
    {'name': 'AEON Mall EV Station', 'address': 'AEON Mall, Phnom Penh', 'distance': '0.8 km', 'available': 4, 'total': 6, 'power': '50 kW', 'price': '\$0.15/kWh', 'status': 'Available'},
    {'name': 'Naga World Charging', 'address': 'NagaWorld Hotel, Riverside', 'distance': '1.2 km', 'available': 1, 'total': 4, 'power': '150 kW', 'price': '\$0.20/kWh', 'status': 'Busy'},
    {'name': 'Phnom Penh Tower EV', 'address': 'CamboHub Tower, BKK1', 'distance': '2.1 km', 'available': 3, 'total': 3, 'power': '22 kW', 'price': '\$0.12/kWh', 'status': 'Available'},
    {'name': 'TK Avenue Station', 'address': 'TK Avenue Mall, Toul Kork', 'distance': '3.5 km', 'available': 0, 'total': 2, 'power': '50 kW', 'price': '\$0.15/kWh', 'status': 'Full'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EV Charging Stations'),
        actions: [
          IconButton(
            icon: Icon(_showList ? Icons.map_outlined : Icons.list_outlined, color: AppTheme.textPrimary),
            onPressed: () => setState(() => _showList = !_showList),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!_showList) ...[
            // Map view
            Container(
              height: 280,
              color: AppTheme.surface,
              child: Stack(
                children: [
                  // Map placeholder with pins
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map, color: AppTheme.accent.withValues(alpha: 0.3), size: 64),
                        Text('Google Maps Integration', style: TextStyle(color: AppTheme.textSecondary)),
                        Text('(requires google_maps_flutter plugin)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                      ],
                    ),
                  ),
                  // Sample pins
                  Positioned(left: 80, top: 100, child: _MapPin(color: AppTheme.success, label: '4')),
                  Positioned(left: 200, top: 80, child: _MapPin(color: AppTheme.warning, label: '1')),
                  Positioned(left: 160, top: 180, child: _MapPin(color: AppTheme.success, label: '3')),
                  Positioned(left: 270, top: 150, child: _MapPin(color: AppTheme.danger, label: '0')),
                ],
              ),
            ),
          ],
          // Filter chips
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(label: 'All', selected: true),
                  const SizedBox(width: 8),
                  _FilterChip(label: 'Available', color: AppTheme.success),
                  const SizedBox(width: 8),
                  _FilterChip(label: 'Fast Charge (>50kW)', color: AppTheme.warning),
                ],
              ),
            ),
          ),
          // Station list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _stations.length,
              itemBuilder: (context, i) => _StationCard(station: _stations[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  final Color color;
  final String label;

  const _MapPin({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.ev_station, color: Colors.white, size: 14),
            const SizedBox(width: 2),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
          ]),
        ),
        Container(width: 2, height: 8, color: color),
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;

  const _FilterChip({required this.label, this.selected = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? AppTheme.accent : AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: color != null ? Border.all(color: color!.withValues(alpha: 0.5)) : null,
      ),
      child: Text(label, style: TextStyle(color: selected ? AppTheme.primary : (color ?? AppTheme.textSecondary), fontSize: 12, fontWeight: FontWeight.w500)),
    );
  }
}

class _StationCard extends StatelessWidget {
  final Map<String, dynamic> station;

  const _StationCard({required this.station});

  @override
  Widget build(BuildContext context) {
    final status = station['status'] as String;
    final available = station['available'] as int;
    final total = station['total'] as int;
    final statusColor = status == 'Available' ? AppTheme.success : status == 'Busy' ? AppTheme.warning : AppTheme.danger;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.ev_station, color: statusColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(station['name'] as String, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 3),
                    Text(station['address'] as String, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatusBadge(label: status, color: statusColor),
                  const SizedBox(height: 4),
                  Text(station['distance'] as String, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatItem(icon: Icons.bolt, label: station['power'] as String, color: AppTheme.warning),
              const SizedBox(width: 16),
              _StatItem(icon: Icons.attach_money, label: station['price'] as String, color: AppTheme.accent),
              const SizedBox(width: 16),
              _StatItem(icon: Icons.electrical_services, label: '$available/$total ports', color: statusColor),
              const Spacer(),
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(color: AppTheme.accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                  child: const Text('Navigate', style: TextStyle(color: AppTheme.accent, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Availability bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total > 0 ? available / total : 0,
              backgroundColor: AppTheme.cardBg,
              valueColor: AlwaysStoppedAnimation(statusColor),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatItem({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, color: color, size: 14),
      const SizedBox(width: 3),
      Text(label, style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
    ]);
  }
}
