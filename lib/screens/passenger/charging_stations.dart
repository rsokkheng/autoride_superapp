import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:autoride_superapp/theme/app_theme.dart';
import '../../services/api_service.dart';

class ChargingStationsScreen extends StatefulWidget {
  const ChargingStationsScreen({super.key});

  @override
  State<ChargingStationsScreen> createState() => _ChargingStationsScreenState();
}

class _ChargingStationsScreenState extends State<ChargingStationsScreen> {
  bool _showList = false;
  List<ChargingStationModel> _stations = [];
  bool    _loading = true;
  String? _error;
  Position? _position;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    // Best-effort location — proceed without if denied
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      _position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low)
          .timeout(const Duration(seconds: 5));
    } catch (_) {}

    try {
      final stations = await ApiService.getChargingStations(
        lat: _position?.latitude,
        lng: _position?.longitude,
      );
      if (!mounted) return;
      setState(() { _stations = stations; _loading = false; });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('EV Charging Stations'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _load,
          ),
          IconButton(
            icon: Icon(_showList ? Icons.map_outlined : Icons.list_outlined,
                color: context.appTextPrimary),
            onPressed: () => setState(() => _showList = !_showList),
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : _error != null
              ? Center(child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.error_outline,
                        color: AppTheme.danger, size: 40),
                    SizedBox(height: 12),
                    Text(_error!,
                        style: TextStyle(color: AppTheme.danger),
                        textAlign: TextAlign.center),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _load,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accent),
                      child: Text('Retry',
                          style: TextStyle(color: AppTheme.primary)),
                    ),
                  ]),
                ))
              : Column(
                  children: [
                    if (!_showList) ...[
                      // Map view placeholder
                      Container(
                        height: 280,
                        color: context.appSurface,
                        child: Stack(
                          children: [
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.map,
                                      color: AppTheme.accent.withValues(alpha: 0.3),
                                      size: 64),
                                  Text('${_stations.length} stations nearby',
                                      style: TextStyle(
                                          color: context.appTextSecondary)),
                                ],
                              ),
                            ),
                            // Overlay pins for first 4 stations
                            ..._stations.take(4).toList().asMap().entries.map((e) {
                              final offsets = [
                                const Offset(80, 100),
                                const Offset(200, 80),
                                const Offset(160, 180),
                                const Offset(270, 150),
                              ];
                              final offset = offsets[e.key];
                              return Positioned(
                                left: offset.dx,
                                top: offset.dy,
                                child: _MapPin(
                                  color: AppTheme.success,
                                  label: e.value.name.substring(0, 1),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],

                    if (_position != null)
                      Padding(
                        padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Row(children: [
                          Icon(Icons.location_on,
                              color: AppTheme.accent, size: 14),
                          SizedBox(width: 4),
                          Text('Sorted by distance from your location',
                              style: TextStyle(
                                  color: context.appTextSecondary, fontSize: 12)),
                        ]),
                      ),

                    SizedBox(height: 8),

                    Expanded(
                      child: _stations.isEmpty
                          ? Center(
                              child: Text('No charging stations found.',
                                  style: TextStyle(color: context.appTextSecondary)))
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _stations.length,
                              itemBuilder: (context, i) =>
                                  _StationCard(station: _stations[i]),
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
          decoration:
              BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.ev_station, color: Colors.white, size: 14),
            const SizedBox(width: 2),
            Text(label,
                style: const TextStyle(
                    color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
          ]),
        ),
        Container(width: 2, height: 8, color: color),
        Container(width: 6, height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      ],
    );
  }
}

class _StationCard extends StatelessWidget {
  final ChargingStationModel station;

  const _StationCard({required this.station});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: context.appSurface, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.ev_station,
                    color: AppTheme.success, size: 22),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(station.name,
                        style: TextStyle(
                            color: context.appTextPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                    SizedBox(height: 3),
                    Text(station.address,
                        style: TextStyle(
                            color: context.appTextSecondary, fontSize: 12)),
                  ],
                ),
              ),
              if (station.distanceKm != null)
                Text('${station.distanceKm!.toStringAsFixed(1)} km',
                    style: TextStyle(
                        color: context.appTextSecondary, fontSize: 12)),
            ],
          ),

          // Operator / rating / ports
          if (station.operator.isNotEmpty || station.rating != null || station.availablePorts > 0) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (station.operator.isNotEmpty)
                  _Chip(
                    icon: Icons.business_outlined,
                    label: station.operator,
                    color: AppTheme.accent,
                  ),
                if (station.availablePorts > 0)
                  _Chip(
                    icon: Icons.power_outlined,
                    label: '${station.availablePorts} ports',
                    color: AppTheme.success,
                  ),
                if (station.rating != null)
                  _Chip(
                    icon: Icons.star_rounded,
                    label: station.rating!.toStringAsFixed(1),
                    color: AppTheme.gold,
                  ),
              ],
            ),
          ],

          // Details
          if (station.details.isNotEmpty) ...[
            SizedBox(height: 8),
            Text(station.details,
                style: TextStyle(
                    color: context.appTextSecondary, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],

          const SizedBox(height: 12),

          // Navigate row
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  color: AppTheme.accent, size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${station.lat.toStringAsFixed(4)}, ${station.lng.toStringAsFixed(4)}',
                  style: TextStyle(
                      color: context.appTextSecondary, fontSize: 11),
                ),
              ),
              GestureDetector(
                onTap: () async {
                  final uri = Uri.parse(
                      'https://maps.google.com/?q=${station.lat},${station.lng}');
                  if (await canLaunchUrl(uri)) await launchUrl(uri);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8)),
                  child: const Text('Navigate',
                      style: TextStyle(
                          color: AppTheme.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Chip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
