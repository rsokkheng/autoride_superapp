import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:autoride_superapp/theme/app_theme.dart';
import 'package:autoride_superapp/widgets/common_widgets.dart';
import 'package:autoride_superapp/l10n/app_localizations.dart';
import 'package:autoride_superapp/services/notification_service.dart';
import 'package:autoride_superapp/services/api_service.dart';
import 'trip_tracking_screen.dart';
import 'promo_screen.dart';

class RideBookingScreen extends StatefulWidget {
  const RideBookingScreen({super.key});

  @override
  State<RideBookingScreen> createState() => _RideBookingScreenState();
}

class _RideBookingScreenState extends State<RideBookingScreen> {
  GoogleMapController? _mapController;
  bool _isScheduled = false;
  String _selectedRide = 'Standard';
  DateTime _scheduledTime = DateTime.now().add(const Duration(hours: 1));
  bool _isBooking = false;
  String? _error;

  final _pickupCtrl  = TextEditingController();
  final _dropoffCtrl = TextEditingController();

  static const _pickup = LatLng(11.5650, 104.9175);
  static const _destination = LatLng(11.5616, 104.9282);

  final _markers = <Marker>{
    const Marker(
      markerId: MarkerId('pickup'),
      position: _pickup,
      infoWindow: InfoWindow(title: 'Pickup', snippet: 'Pickup'),
    ),
    Marker(
      markerId: const MarkerId('destination'),
      position: _destination,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: const InfoWindow(title: 'Destination', snippet: 'Drop-off'),
    ),
  };

  final _polylines = <Polyline>{
    const Polyline(
      polylineId: PolylineId('route'),
      points: [
        LatLng(11.5650, 104.9175),
        LatLng(11.5645, 104.9200),
        LatLng(11.5635, 104.9240),
        LatLng(11.5616, 104.9282),
      ],
      color: AppTheme.accent,
      width: 4,
    ),
  };

  final _rideTypes = [
    {'name': 'Standard', 'serviceType': 'standard', 'icon': Icons.directions_car, 'price': '\$3.50', 'eta': '3 min', 'desc': '4 seats'},
    {'name': 'Premium',  'serviceType': 'premium',  'icon': Icons.local_taxi,     'price': '\$6.00', 'eta': '5 min', 'desc': 'Luxury car'},
    {'name': 'Shared',   'serviceType': 'shared',   'icon': Icons.airport_shuttle,'price': '\$2.50', 'eta': '7 min', 'desc': 'Shared ride'},
  ];

  String get _selectedFare {
    final r = _rideTypes.firstWhere((r) => r['name'] == _selectedRide);
    return r['price'] as String;
  }

  String get _selectedServiceType {
    final r = _rideTypes.firstWhere((r) => r['name'] == _selectedRide);
    return r['serviceType'] as String;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l.bookRide)),
      body: Column(
        children: [
          // Google Map — full-width, fixed height
          SizedBox(
            height: 220,
            child: GoogleMap(
              onMapCreated: (c) {
                _mapController = c;
                c.animateCamera(CameraUpdate.newLatLngBounds(
                  LatLngBounds(
                    southwest: const LatLng(11.5610, 104.9165),
                    northeast: const LatLng(11.5660, 104.9295),
                  ),
                  60,
                ));
              },
              initialCameraPosition: const CameraPosition(
                target: LatLng(11.5633, 104.9228),
                zoom: 14,
              ),
              style: _darkMapStyle,
              markers: _markers,
              polylines: _polylines,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapType: MapType.normal,
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pickup & Drop-off
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.danger.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.danger.withValues(alpha: 0.4)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.error_outline, color: AppTheme.danger, size: 18),
                        const SizedBox(width: 10),
                        Expanded(child: Text(_error!, style: const TextStyle(color: AppTheme.danger, fontSize: 13))),
                      ]),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(16)),
                    child: Column(children: [
                      Row(children: [
                        const Icon(Icons.circle, color: AppTheme.accent, size: 12),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _pickupCtrl,
                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                            decoration: const InputDecoration(
                              hintText: 'Pickup address',
                              hintStyle: TextStyle(color: AppTheme.textSecondary),
                              isDense: true,
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ]),
                      const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Divider(color: AppTheme.cardBg)),
                      Row(children: [
                        const Icon(Icons.location_on, color: AppTheme.accentOrange, size: 14),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _dropoffCtrl,
                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                            decoration: const InputDecoration(
                              hintText: 'Destination address',
                              hintStyle: TextStyle(color: AppTheme.textSecondary),
                              isDense: true,
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ]),
                    ]),
                  ),
                  const SizedBox(height: 20),

                  // Schedule toggle
                  Row(children: [
                    Text(l.scheduleForLater,
                        style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Switch(
                      value: _isScheduled,
                      onChanged: (v) => setState(() => _isScheduled = v),
                      activeThumbColor: AppTheme.accent,
                      activeTrackColor: AppTheme.accent.withValues(alpha: 0.4),
                    ),
                  ]),

                  if (_isScheduled) ...[
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () async {
                        final date = await _pickDateTime(context);
                        if (date != null) setState(() => _scheduledTime = date);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.accent.withValues(alpha: 0.4)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.schedule, color: AppTheme.accent, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            '${_scheduledTime.day}/${_scheduledTime.month}/${_scheduledTime.year}  '
                            '${_scheduledTime.hour}:${_scheduledTime.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w500),
                          ),
                          const Spacer(),
                          const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                        ]),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),

                  SectionHeader(title: l.chooseRide),
                  const SizedBox(height: 14),
                  ..._rideTypes.map((ride) => _RideTypeCard(
                    name: ride['name'] as String,
                    icon: ride['icon'] as IconData,
                    price: ride['price'] as String,
                    eta: ride['eta'] as String,
                    desc: ride['desc'] as String,
                    selected: _selectedRide == ride['name'],
                    onTap: () => setState(() => _selectedRide = ride['name'] as String),
                  )),
                  const SizedBox(height: 20),

                  // Promo code
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PromoScreen())),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [
                        const Icon(Icons.local_offer_outlined,
                            color: AppTheme.warning, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Text(l.promoCode,
                                style:
                                    TextStyle(color: AppTheme.textSecondary))),
                        const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Book button
                  ElevatedButton(
                    onPressed: _isBooking ? null : _bookRide,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                      backgroundColor: _isScheduled ? AppTheme.warning : AppTheme.accent,
                      foregroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isBooking
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                color: AppTheme.primary, strokeWidth: 2.5))
                        : Text(
                            _isScheduled
                                ? '📅  ${l.scheduleRide} — $_selectedFare'
                                : '🚗  ${l.bookNow} — $_selectedFare',
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 15)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _bookRide() async {
    final pickup  = _pickupCtrl.text.trim();
    final dropoff = _dropoffCtrl.text.trim();
    if (pickup.isEmpty || dropoff.isEmpty) {
      setState(() => _error = 'Please enter pickup and destination addresses.');
      return;
    }
    setState(() { _isBooking = true; _error = null; });

    try {
      final ride = await ApiService.createRide(
        pickupAddress:  pickup,
        dropoffAddress: dropoff,
        serviceType:    _selectedServiceType,
        scheduledAt: _isScheduled
            ? '${_scheduledTime.year}-${_scheduledTime.month.toString().padLeft(2,'0')}-${_scheduledTime.day.toString().padLeft(2,'0')} '
              '${_scheduledTime.hour.toString().padLeft(2,'0')}:${_scheduledTime.minute.toString().padLeft(2,'0')}:00'
            : null,
      );

      await NotificationService.instance.showTripUpdate(
        title: 'Ride Requested!',
        body: 'Looking for a driver...',
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TripTrackingScreen(
            rideId:   ride.id,
            fare:     '\$${ride.fare}',
            from:     ride.pickupAddress,
            to:       ride.dropoffAddress,
            isScheduled: _isScheduled,
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() { _isBooking = false; _error = e.message; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _isBooking = false; _error = e.toString(); });
    }
  }

  Future<DateTime?> _pickDateTime(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 7)),
      builder: (c, child) => Theme(
        data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(primary: AppTheme.accent)),
        child: child!,
      ),
    );
    if (date == null || !mounted) return null;
    // ignore: use_build_context_synchronously
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledTime),
      builder: (c, child) => Theme(
        data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(primary: AppTheme.accent)),
        child: child!,
      ),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  @override
  void dispose() {
    _pickupCtrl.dispose();
    _dropoffCtrl.dispose();
    _mapController?.dispose();
    super.dispose();
  }
}

class _RideTypeCard extends StatelessWidget {
  final String name, price, eta, desc;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RideTypeCard(
      {required this.name,
      required this.price,
      required this.eta,
      required this.desc,
      required this.icon,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected ? AppTheme.accent : Colors.transparent, width: 1.5),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: (selected ? AppTheme.accent : AppTheme.textSecondary)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon,
                color: selected ? AppTheme.accent : AppTheme.textSecondary,
                size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name,
                  style: const TextStyle(
                      color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
              Text(desc,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(price,
                style: TextStyle(
                    color: selected ? AppTheme.accent : AppTheme.textPrimary,
                    fontWeight: FontWeight.w700)),
            Text(eta,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12)),
          ]),
          const SizedBox(width: 8),
          Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppTheme.accent : AppTheme.textSecondary,
              size: 20),
        ]),
      ),
    );
  }
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
