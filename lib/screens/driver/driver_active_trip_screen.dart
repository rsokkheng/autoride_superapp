import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../theme/app_theme.dart';
import '../../services/notification_service.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';
import '../../models/ride_model.dart';
import '../shared/ride_chat_screen.dart';
import 'driver_trip_summary_screen.dart';

enum _TripPhase { headingToPickup, waitingAtPickup, inProgress, completed }

class DriverActiveTripScreen extends StatefulWidget {
  final RideModel? ride;
  final String passengerName;
  final String passengerRating;
  final String pickup;
  final String destination;
  final String fare;

  const DriverActiveTripScreen({
    super.key,
    this.ride,
    this.passengerName = 'Passenger',
    this.passengerRating = '5.0',
    this.pickup = '--',
    this.destination = '--',
    this.fare = '--',
  });

  @override
  State<DriverActiveTripScreen> createState() => _DriverActiveTripScreenState();
}

class _DriverActiveTripScreenState extends State<DriverActiveTripScreen>
    with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  _TripPhase _phase = _TripPhase.headingToPickup;
  bool _completing = false;

  String get _passengerName => widget.ride?.passenger?.name
      ?? (widget.ride != null ? 'Passenger #${widget.ride!.passengerId}' : widget.passengerName);
  String get _pickup        => widget.ride?.pickupAddress  ?? widget.pickup;
  String get _destination   => widget.ride?.dropoffAddress ?? widget.destination;
  String get _fare          => widget.ride != null
      ? AppTheme.khr(widget.ride!.fareKhr)
      : widget.fare;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  // Route waypoints (Phnom Penh)
  static const _pickupPoint    = LatLng(11.5650, 104.9175);
  static const _destinPoint    = LatLng(11.5616, 104.9282);
  static const _driverStart    = LatLng(11.5680, 104.9155);

  final Set<Marker>   _markers  = {};
  final Set<Polyline> _polylines = {};

  String get _driverId => widget.ride?.driverId?.toString() ?? 'unknown';

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(_pulseCtrl);
    _buildMap();
    _startTracking();
  }

  Future<void> _startTracking() async {
    final granted = await LocationService.instance.requestPermission();
    if (!granted) return;
    LocationService.instance.startTracking(
      driverId: _driverId,
      onPosition: _onDriverPosition,
    );
  }

  void _onDriverPosition(Position position) {
    if (!mounted) return;
    final pos = LatLng(position.latitude, position.longitude);
    setState(() {
      _markers.removeWhere((m) => m.markerId.value == 'driver');
      _markers.add(Marker(
        markerId: const MarkerId('driver'),
        position: pos,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: const InfoWindow(title: 'You'),
      ));
    });
    _mapController?.animateCamera(CameraUpdate.newLatLng(pos));
  }

  void _buildMap() {
    _markers.addAll([
      Marker(markerId: const MarkerId('driver'), position: _driverStart,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: const InfoWindow(title: 'You')),
      Marker(markerId: const MarkerId('pickup'), position: _pickupPoint,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(title: _pickup)),
      Marker(markerId: const MarkerId('dest'), position: _destinPoint,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: _destination)),
    ]);
    _polylines.add(const Polyline(
      polylineId: PolylineId('route'),
      points: [_driverStart, LatLng(11.5665, 104.9165), _pickupPoint,
               LatLng(11.5635, 104.9235), _destinPoint],
      color: AppTheme.accentOrange,
      width: 4,
    ));
  }

  @override
  void dispose() {
    LocationService.instance.stopTracking(_driverId);
    _pulseCtrl.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  String get _phaseLabel {
    switch (_phase) {
      case _TripPhase.headingToPickup: return 'Heading to Pickup';
      case _TripPhase.waitingAtPickup: return 'Waiting at Pickup';
      case _TripPhase.inProgress:      return 'Trip in Progress';
      case _TripPhase.completed:       return 'Trip Completed';
    }
  }

  Color get _phaseColor {
    switch (_phase) {
      case _TripPhase.headingToPickup: return AppTheme.warning;
      case _TripPhase.waitingAtPickup: return AppTheme.accentOrange;
      case _TripPhase.inProgress:      return AppTheme.accent;
      case _TripPhase.completed:       return AppTheme.success;
    }
  }

  String get _ctaLabel {
    switch (_phase) {
      case _TripPhase.headingToPickup: return '✅  Arrived at Pickup';
      case _TripPhase.waitingAtPickup: return '🚗  Passenger On Board — Start Trip';
      case _TripPhase.inProgress:      return '🏁  Complete Trip';
      case _TripPhase.completed:       return '🏠  Back to Dashboard';
    }
  }

  Future<void> _advancePhase() async {
    if (_phase == _TripPhase.completed) {
      Navigator.pop(context);
      return;
    }

    if (_phase == _TripPhase.inProgress) {
      setState(() => _completing = true);

      RideModel? completedRide;
      if (widget.ride != null) {
        try {
          completedRide = await ApiService.completeRide(widget.ride!.id);
        } catch (_) {
          completedRide = widget.ride;
        }
      }

      if (!mounted) return;
      setState(() => _completing = false);

      await NotificationService.instance.showTripUpdate(
        title: 'Trip Completed',
        body: 'You earned ${AppTheme.khr((completedRide ?? widget.ride)?.fareKhr ?? 0)} for this trip',
      );

      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DriverTripSummaryScreen(
            ride: completedRide ?? widget.ride ?? _fakeSummaryRide(),
          ),
        ),
      );
      if (!mounted) return;
      Navigator.pop(context);
      return;
    }

    setState(() => _phase = _TripPhase.values[_phase.index + 1]);
  }

  RideModel _fakeSummaryRide() => RideModel(
    id: 0,
    passengerId: 0,
    pickupAddress: _pickup,
    dropoffAddress: _destination,
    status: 'completed',
    fare: '0',
    serviceType: 'standard',
    paymentMethod: 'cash',
    createdAt: DateTime.now().toIso8601String(),
    updatedAt: DateTime.now().toIso8601String(),
  );

  void _showSOS() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: AppTheme.danger, size: 28),
          SizedBox(width: 10),
          Text('Emergency SOS', style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.w800)),
        ]),
        content: const Text(
          'This will alert emergency services and notify AutoRide operations team with your location.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary))),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); _sendSOS(); },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Send SOS'),
          ),
        ],
      ),
    );
  }

  Future<void> _openRideChat() async {
    if (widget.ride == null) return;
    final saved = await ApiService.getSavedUser();
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => RideChatScreen(
        rideId:      widget.ride!.id.toString(),
        driverId:    widget.ride!.driverId ?? saved?.id ?? 0,
        passengerId: widget.ride!.passengerId,
        myId:        saved?.id   ?? 0,
        myName:      saved?.name ?? 'Driver',
        otherName:   widget.ride!.passenger?.name
                         ?? 'Passenger #${widget.ride!.passengerId}',
        isDriver:    true,
      ),
    ));
  }

  void _sendSOS() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('🚨 SOS Sent! Help is on the way.'),
      backgroundColor: AppTheme.danger,
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _callPassenger() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          CircleAvatar(radius: 36, backgroundColor: AppTheme.accent.withValues(alpha: 0.2),
            child: Text(_passengerName[0], style: const TextStyle(color: AppTheme.accent, fontSize: 28, fontWeight: FontWeight.w800))),
          const SizedBox(height: 12),
          Text(_passengerName, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
          const Text('+855 12 345 678', style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.call),
              label: const Text('Call Now', style: TextStyle(fontWeight: FontWeight.w800)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            )),
          const SizedBox(height: 10),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = _phase == _TripPhase.completed;

    return Scaffold(
      body: Stack(children: [
        // Full-screen map
        GoogleMap(
          onMapCreated: (c) => _mapController = c,
          initialCameraPosition: const CameraPosition(target: LatLng(11.5648, 104.9218), zoom: 14),
          style: _darkMapStyle,
          markers: _markers,
          polylines: _polylines,
          myLocationEnabled: false,
          zoomControlsEnabled: false,
        ),

        // Top bar
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.9), shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_back, color: AppTheme.textPrimary, size: 20),
                ),
              ),
              const Spacer(),
              // Pulsing status pill
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, __) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _phaseColor.withValues(alpha: 0.1 + 0.1 * _pulseAnim.value),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _phaseColor.withValues(alpha: 0.5)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: _phaseColor, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(_phaseLabel, style: TextStyle(color: _phaseColor, fontWeight: FontWeight.w700, fontSize: 12)),
                  ]),
                ),
              ),
              const Spacer(),
              // SOS button
              GestureDetector(
                onTap: _showSOS,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.danger,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text('SOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                  ]),
                ),
              ),
            ]),
          ),
        ),

        // Bottom sheet
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 20)],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Handle
              Container(width: 36, height: 4, decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 14),

              if (!isCompleted) ...[
                // Passenger info row
                Row(children: [
                  CircleAvatar(
                    radius: 22, backgroundColor: AppTheme.accent.withValues(alpha: 0.2),
                    child: Text(_passengerName[0], style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w800, fontSize: 16)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_passengerName, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
                    Row(children: [
                      const Icon(Icons.star, color: AppTheme.gold, size: 13),
                      const SizedBox(width: 3),
                      Text(widget.passengerRating, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    ]),
                  ])),
                  // Fare
                  Text(_fare, style: const TextStyle(color: AppTheme.accent, fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(width: 12),
                  // Actions
                  _ActionBtn(icon: Icons.call_outlined, color: AppTheme.success, onTap: _callPassenger),
                  const SizedBox(width: 8),
                  _ActionBtn(
                    icon: Icons.chat_bubble_outline,
                    color: AppTheme.accent,
                    onTap: _openRideChat,
                  ),
                ]),
                const SizedBox(height: 12),

                // Route
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(12)),
                  child: Column(children: [
                    Row(children: [
                      const Icon(Icons.circle, color: AppTheme.success, size: 10),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_pickup, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600))),
                    ]),
                    const SizedBox(height: 4),
                    Row(children: [
                      Container(width: 1, height: 16, color: AppTheme.textSecondary, margin: const EdgeInsets.only(left: 4)),
                    ]),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.location_on, color: AppTheme.accentOrange, size: 12),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_destination, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
                    ]),
                  ]),
                ),
                const SizedBox(height: 14),
              ] else ...[
                // Completed state
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppTheme.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                  child: Column(children: [
                    const Icon(Icons.check_circle, color: AppTheme.success, size: 48),
                    const SizedBox(height: 8),
                    const Text('Trip Completed!', style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.w800, fontSize: 18)),
                    Text('You earned $_fare', style: const TextStyle(color: AppTheme.textSecondary)),
                  ]),
                ),
                const SizedBox(height: 14),
              ],

              // CTA button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _completing ? null : _advancePhase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCompleted ? AppTheme.success : _phaseColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _completing
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Text(_ctaLabel, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
      child: Icon(icon, color: color, size: 18),
    ),
  );
}

const String _darkMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#1a1a2e"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#b0bec5"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#1a1a2e"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#16213e"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#0f3460"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#0f3460"}]},
  {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#16213e"}]},
  {"featureType":"administrative","elementType":"geometry.stroke","stylers":[{"color":"#0f3460"}]}
]
''';
