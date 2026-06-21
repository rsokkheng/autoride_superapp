import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

const _green = Color(0xFF00B14F);

/// Opened from a share link — no login required.
/// Usage: Navigator.push(ctx, MaterialPageRoute(
///   builder: (_) => PublicTrackingScreen(token: 'abc123')));
class PublicTrackingScreen extends StatefulWidget {
  final String token;
  const PublicTrackingScreen({super.key, required this.token});

  @override
  State<PublicTrackingScreen> createState() => _PublicTrackingScreenState();
}

class _PublicTrackingScreenState extends State<PublicTrackingScreen> {
  PublicTripModel? _trip;
  bool    _loading = true;
  String? _error;
  Timer?  _pollTimer;

  GoogleMapController? _mapCtrl;
  final Set<Marker>   _markers   = {};
  final Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _load();
    _pollTimer = Timer.periodic(
        const Duration(seconds: 8), (_) => _refresh());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _mapCtrl?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final trip = await ApiService.getPublicTrip(widget.token);
      if (!mounted) return;
      setState(() { _trip = trip; _loading = false; });
      _buildMarkers(trip);
      _animateCamera(trip);
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    try {
      final trip = await ApiService.getPublicTrip(widget.token);
      if (!mounted) return;
      setState(() => _trip = trip);
      _buildMarkers(trip);
      // Stop polling once the ride is no longer live
      if (!trip.isLive) {
        _pollTimer?.cancel();
        _pollTimer = null;
      }
    } catch (_) {}
  }

  void _buildMarkers(PublicTripModel trip) {
    _markers.clear();
    _markers.addAll([
      Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(trip.pickupLat, trip.pickupLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(title: 'Pickup', snippet: trip.pickupAddress),
      ),
      Marker(
        markerId: const MarkerId('dropoff'),
        position: LatLng(trip.dropoffLat, trip.dropoffLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: 'Destination',
            snippet: trip.dropoffAddress),
      ),
    ]);
    if (trip.driverLat != null && trip.driverLng != null) {
      _markers.add(Marker(
        markerId: const MarkerId('driver'),
        position: LatLng(trip.driverLat!, trip.driverLng!),
        icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure),
        infoWindow: InfoWindow(
            title: trip.driverName.isNotEmpty ? trip.driverName : 'Driver'),
      ));
    }
    if (mounted) setState(() {});
  }

  void _animateCamera(PublicTripModel trip) {
    if (_mapCtrl == null) return;
    final points = [
      LatLng(trip.pickupLat,  trip.pickupLng),
      LatLng(trip.dropoffLat, trip.dropoffLng),
      if (trip.driverLat != null)
        LatLng(trip.driverLat!, trip.driverLng!),
    ];
    if (points.isEmpty) return;
    double minLat = points.first.latitude,  maxLat = points.first.latitude;
    double minLng = points.first.longitude, maxLng = points.first.longitude;
    for (final p in points) {
      if (p.latitude  < minLat) minLat = p.latitude;
      if (p.latitude  > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    _mapCtrl!.animateCamera(CameraUpdate.newLatLngBounds(
      LatLngBounds(
        southwest: LatLng(minLat - 0.005, minLng - 0.005),
        northeast: LatLng(maxLat + 0.005, maxLng + 0.005),
      ), 60,
    ));
  }

  Color get _statusColor {
    switch (_trip?.status) {
      case 'accepted':
      case 'picking_up': return AppTheme.accent;
      case 'in_progress': return _green;
      case 'completed':   return context.appTextSecondary;
      default:            return AppTheme.warning;
    }
  }

  String get _statusLabel {
    switch (_trip?.status) {
      case 'requested':   return 'Finding driver…';
      case 'accepted':    return 'Driver on the way';
      case 'picking_up':  return 'Driver en route to pickup';
      case 'in_progress': return 'Trip in progress';
      case 'completed':   return 'Trip completed';
      case 'cancelled':   return 'Trip cancelled';
      default:            return _trip?.status ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: _green.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(Icons.directions_car_rounded,
                color: _green, size: 18),
          ),
          SizedBox(width: 10),
          Text('ROTEH — Live Trip',
              style: TextStyle(color: context.appTextPrimary,
                  fontWeight: FontWeight.w700, fontSize: 15)),
        ]),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _green))
          : _error != null
              ? _ErrorBody(error: _error!, onRetry: _load)
              : Column(children: [
                  Expanded(
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(
                          _trip?.pickupLat ?? 11.5680,
                          _trip?.pickupLng ?? 104.9195,
                        ),
                        zoom: 14,
                      ),
                      markers:  _markers,
                      polylines: _polylines,
                      onMapCreated: (ctrl) {
                        _mapCtrl = ctrl;
                        if (_trip != null) _animateCamera(_trip!);
                      },
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                    ),
                  ),
                  _InfoPanel(
                    trip:        _trip!,
                    statusLabel: _statusLabel,
                    statusColor: _statusColor,
                  ),
                ]),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  final PublicTripModel trip;
  final String statusLabel;
  final Color  statusColor;

  const _InfoPanel({
    required this.trip,
    required this.statusLabel,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10,
          offset: Offset(0, -2))],
    ),
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Center(child: Container(
        width: 40, height: 4,
        decoration: BoxDecoration(color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2)),
      )),
      const SizedBox(height: 14),

      // Status
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 8, height: 8,
              decoration: BoxDecoration(
                  color: statusColor, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(statusLabel,
              style: TextStyle(color: statusColor,
                  fontWeight: FontWeight.w700, fontSize: 13)),
          if (trip.etaMinutes != null) ...[
            const Text(' · ', style: TextStyle(color: Colors.grey)),
            Text('ETA ${trip.etaMinutes} min',
                style: TextStyle(color: statusColor, fontSize: 13)),
          ],
        ]),
      ),
      SizedBox(height: 14),

      // Route
      Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(children: [
          Row(children: [
            Icon(Icons.circle, color: _green, size: 8),
            SizedBox(width: 10),
            Expanded(child: Text(trip.pickupAddress,
                style: TextStyle(fontSize: 13,
                    color: context.appTextPrimary),
                maxLines: 1, overflow: TextOverflow.ellipsis)),
          ]),
          Padding(
            padding: EdgeInsets.only(left: 3),
            child: Column(children: List.generate(3, (_) => Container(
              width: 2, height: 4,
              margin: EdgeInsets.symmetric(vertical: 1),
              color: Colors.grey[400],
            ))),
          ),
          Row(children: [
            Icon(Icons.location_on, color: Colors.red, size: 10),
            SizedBox(width: 10),
            Expanded(child: Text(trip.dropoffAddress,
                style: TextStyle(fontSize: 13,
                    color: context.appTextPrimary),
                maxLines: 1, overflow: TextOverflow.ellipsis)),
          ]),
        ]),
      ),
      SizedBox(height: 12),

      // Driver info
      if (trip.driverName.isNotEmpty)
        Row(children: [
          Icon(Icons.person_outline,
              color: context.appTextSecondary, size: 16),
          SizedBox(width: 6),
          Text(trip.driverName,
              style: TextStyle(
                  color: context.appTextPrimary,
                  fontWeight: FontWeight.w600)),
          if (trip.vehicleType.isNotEmpty || trip.plate.isNotEmpty) ...[
            Text(' · ',
                style: TextStyle(color: context.appTextSecondary)),
            Text('${trip.vehicleType} ${trip.plate}'.trim(),
                style: TextStyle(color: context.appTextSecondary,
                    fontSize: 13)),
          ],
        ]),

      // Driver location status
      if (!trip.locationUpdated) ...[
        const SizedBox(height: 8),
        Row(children: [
          const Icon(Icons.location_searching,
              color: Color(0xFFFF9800), size: 14),
          const SizedBox(width: 6),
          const Text('Waiting for driver GPS…',
              style: TextStyle(color: Color(0xFFFF9800), fontSize: 12)),
        ]),
      ],

      const SizedBox(height: 8),
      const Text('This page updates automatically every 8 seconds.',
          style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 11)),
    ]),
  );
}

class _ErrorBody extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorBody({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.link_off_rounded,
            color: AppTheme.danger, size: 56),
        SizedBox(height: 16),
        Text('Trip not found',
            style: TextStyle(fontSize: 18,
                fontWeight: FontWeight.w700, color: context.appTextPrimary)),
        SizedBox(height: 8),
        Text(error, textAlign: TextAlign.center,
            style: TextStyle(
                color: context.appTextSecondary, fontSize: 13)),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: onRetry,
          style: ElevatedButton.styleFrom(
            backgroundColor: _green, foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Try again'),
        ),
      ]),
    ),
  );
}
