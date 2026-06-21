import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import 'trip_tracking_screen.dart';

// Vehicle options
class _VehicleOpt {
  final String type;
  final String label;
  final String desc;
  final IconData icon;
  final int maxPax;
  const _VehicleOpt({
    required this.type, required this.label,
    required this.desc, required this.icon, required this.maxPax,
  });
}

const _kVehicles = [
  _VehicleOpt(type: 'car', label: 'Sedan',  desc: 'Up to 4 pax',
      icon: Icons.directions_car_rounded, maxPax: 4),
  _VehicleOpt(type: 'van', label: 'SUV/Van', desc: 'Up to 6 pax',
      icon: Icons.airport_shuttle_rounded, maxPax: 6),
];

// Fallback zones if API is unavailable
final _kFallbackZones = [
  AirportZone(id: 1, name: 'Phnom Penh Intl', iataCode: 'PNH', lat: 11.5466, lng: 104.8440),
  AirportZone(id: 2, name: 'Siem Reap Intl',  iataCode: 'SAI', lat: 13.4107, lng: 103.8127),
  AirportZone(id: 3, name: 'Sihanoukville',   iataCode: 'KOS', lat: 10.5799, lng: 103.6373),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class AirportTripScreen extends StatefulWidget {
  const AirportTripScreen({super.key});

  @override
  State<AirportTripScreen> createState() => _AirportTripScreenState();
}

class _AirportTripScreenState extends State<AirportTripScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  // Direction: 0 = To Airport, 1 = From Airport
  int _direction = 0;

  // Airport zones from API
  List<AirportZone> _zones = [];
  bool _zonesLoading = true;
  AirportZone? _selectedZone;

  // Selections
  _VehicleOpt _vehicle    = _kVehicles[0];
  int         _passengers = 1;
  int         _luggage    = 1;

  // Fields
  final _addressCtrl  = TextEditingController();
  final _flightCtrl   = TextEditingController();
  final _terminalCtrl = TextEditingController();
  LatLng?   _userLatLng;
  DateTime? _flightTime;

  // Fare estimate
  AirportEstimate? _estimate;
  bool    _estimating = false;
  Timer?  _estimateDebounce;

  // Booking
  bool    _booking   = false;
  String? _bookError;

  bool get _toAirport => _direction == 0;

  AirportZone? get _zone => _selectedZone ?? _zones.firstOrNull;

  LatLng get _airportLatLng => _zone != null
      ? LatLng(_zone!.lat, _zone!.lng)
      : const LatLng(11.5466, 104.8440);

  LatLng get _pickupLatLng  => _toAirport ? (_userLatLng ?? _airportLatLng) : _airportLatLng;
  LatLng get _dropoffLatLng => _toAirport ? _airportLatLng : (_userLatLng ?? _airportLatLng);

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() {
      if (!_tab.indexIsChanging) {
        setState(() { _direction = _tab.index; _estimate = null; });
        _scheduleEstimate();
      }
    });
    _loadZones();
  }

  @override
  void dispose() {
    _tab.dispose();
    _addressCtrl.dispose();
    _flightCtrl.dispose();
    _terminalCtrl.dispose();
    _estimateDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadZones() async {
    try {
      final zones = await ApiService.getAirportZones();
      if (!mounted) return;
      setState(() {
        _zones        = zones.isNotEmpty ? zones : _kFallbackZones;
        _selectedZone = _zones.first;
        _zonesLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _zones        = _kFallbackZones;
        _selectedZone = _kFallbackZones.first;
        _zonesLoading = false;
      });
    }
  }

  void _scheduleEstimate() {
    _estimateDebounce?.cancel();
    if (_userLatLng == null || _zone == null) return;
    _estimateDebounce = Timer(const Duration(milliseconds: 600), _fetchEstimate);
  }

  Future<void> _fetchEstimate() async {
    if (_userLatLng == null || _zone == null) return;
    setState(() { _estimating = true; _estimate = null; });
    try {
      final est = await ApiService.estimateAirportRide(
        pickupLat:   _pickupLatLng.latitude,
        pickupLng:   _pickupLatLng.longitude,
        dropoffLat:  _dropoffLatLng.latitude,
        dropoffLng:  _dropoffLatLng.longitude,
        luggageCount: _luggage,
        serviceType:  _vehicle.type,
      );
      if (mounted) setState(() { _estimate = est; _estimating = false; });
    } catch (_) {
      if (mounted) setState(() => _estimating = false);
    }
  }

  Future<void> _pickDateTime() async {
    final now  = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _flightTime ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      builder: (c, child) => Theme(
        data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: AppTheme.accent)),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_flightTime ?? now),
      builder: (c, child) => Theme(
        data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: AppTheme.accent)),
        child: child!,
      ),
    );
    if (time == null) return;
    setState(() => _flightTime =
        DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  String _formatDateTime(DateTime dt) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} · $h:$m';
  }

  bool get _canBook =>
      _addressCtrl.text.trim().isNotEmpty &&
      _userLatLng != null &&
      _flightCtrl.text.trim().isNotEmpty &&
      _flightTime != null &&
      _zone != null;

  Future<void> _book() async {
    if (!_canBook) {
      setState(() => _bookError = 'Please fill in your address, flight number, and flight time.');
      return;
    }
    setState(() { _booking = true; _bookError = null; });

    final userAddress = _addressCtrl.text.trim();
    final zoneName    = _zone?.name ?? 'Airport';

    try {
      final ride = await ApiService.createRide(
        pickupAddress:  _toAirport ? userAddress : zoneName,
        dropoffAddress: _toAirport ? zoneName : userAddress,
        pickupLat:      _pickupLatLng.latitude,
        pickupLng:      _pickupLatLng.longitude,
        dropoffLat:     _dropoffLatLng.latitude,
        dropoffLng:     _dropoffLatLng.longitude,
        serviceType:    'airport',
        vehicleType:    _vehicle.type,
        scheduledAt:    _flightTime?.toIso8601String(),
        isAirportTrip:  true,
        flightNumber:   _flightCtrl.text.trim().toUpperCase(),
        terminal:       _terminalCtrl.text.trim().isEmpty ? null : _terminalCtrl.text.trim(),
        luggageCount:   _luggage,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TripTrackingScreen(
            rideId:       ride.id,
            fare:         AppTheme.khr(ride.fareKhr),
            from:         _toAirport ? userAddress : zoneName,
            to:           _toAirport ? zoneName : userAddress,
            pickupLatLng: _pickupLatLng,
            destLatLng:   _dropoffLatLng,
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() { _bookError = e.message; _booking = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _bookError = e.toString().replaceFirst('Exception: ', '');
        _booking   = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        title: Text('Airport Transfer'),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: AppTheme.accent,
          labelColor: AppTheme.accent,
          unselectedLabelColor: context.appTextSecondary,
          tabs: const [
            Tab(icon: Icon(Icons.flight_takeoff_rounded), text: 'To Airport'),
            Tab(icon: Icon(Icons.flight_land_rounded),    text: 'From Airport'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // ── Free wait banner (From Airport only) ─────────────────
                if (!_toAirport) ...[
                  _InfoBanner(
                    icon: Icons.access_time_rounded,
                    color: AppTheme.accent,
                    message: '60 minutes free wait included — we track your flight and adjust pickup automatically.',
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Airport selector ─────────────────────────────────────
                _SectionLabel(label: _toAirport ? 'Drop-off Airport' : 'Pick-up Airport'),
                const SizedBox(height: 10),
                _zonesLoading
                    ? const Center(child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: CircularProgressIndicator(color: AppTheme.accent, strokeWidth: 2)))
                    : Row(
                        children: _zones.map((z) {
                          final sel = z.id == _zone?.id;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() { _selectedZone = z; _estimate = null; });
                                  _scheduleEstimate();
                                },
                                child: AnimatedContainer(
                                  duration: Duration(milliseconds: 180),
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: sel ? AppTheme.accent.withValues(alpha: 0.12) : context.appSurface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: sel ? AppTheme.accent : context.appCardBg,
                                      width: sel ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Column(children: [
                                    Icon(Icons.flight_rounded,
                                        color: sel ? AppTheme.accent : context.appTextSecondary,
                                        size: 20),
                                    SizedBox(height: 4),
                                    Text(z.iataCode,
                                        style: TextStyle(
                                          color: sel ? AppTheme.accent : context.appTextPrimary,
                                          fontWeight: FontWeight.w800, fontSize: 13,
                                        )),
                                    Text(
                                      z.name.length > 12
                                          ? '${z.name.substring(0, 11)}…'
                                          : z.name,
                                      style: TextStyle(
                                          color: context.appTextSecondary, fontSize: 10),
                                    ),
                                  ]),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                const SizedBox(height: 20),

                // ── Your address ─────────────────────────────────────────
                _SectionLabel(label: _toAirport ? 'Pick-up Address' : 'Drop-off Address'),
                const SizedBox(height: 8),
                _AddressField(
                  controller: _addressCtrl,
                  hint: _toAirport
                      ? 'Enter your home / hotel address'
                      : 'Enter your destination address',
                  onChanged: (v) {
                    if (v.trim().isNotEmpty && _userLatLng == null) {
                      // In production, geocode via a places API.
                      // Use Phnom Penh city centre as a placeholder until geocoding is wired.
                      setState(() => _userLatLng = const LatLng(11.5625, 104.9160));
                      _scheduleEstimate();
                    } else if (v.trim().isEmpty) {
                      setState(() { _userLatLng = null; _estimate = null; });
                    }
                  },
                ),

                SizedBox(height: 20),

                // ── Flight details ───────────────────────────────────────
                _SectionLabel(label: 'Flight Details'),
                SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    child: _InputField(
                      controller: _flightCtrl,
                      hint: 'Flight no. (e.g. QH101)',
                      icon: Icons.confirmation_number_outlined,
                      inputFormatters: [UpperCaseFormatter()],
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _InputField(
                      controller: _terminalCtrl,
                      hint: 'Terminal (e.g. T1)',
                      icon: Icons.door_front_door_outlined,
                    ),
                  ),
                ]),
                SizedBox(height: 10),
                GestureDetector(
                  onTap: _pickDateTime,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: context.appSurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(children: [
                      Icon(Icons.schedule_rounded,
                          color: context.appTextSecondary, size: 18),
                      SizedBox(width: 8),
                      Text(
                        _flightTime != null
                            ? _formatDateTime(_flightTime!)
                            : _toAirport ? 'Departure time' : 'Arrival time',
                        style: TextStyle(
                          color: _flightTime != null
                              ? context.appTextPrimary
                              : context.appTextSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ]),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Vehicle type ─────────────────────────────────────────
                _SectionLabel(label: 'Vehicle Type'),
                const SizedBox(height: 10),
                Row(
                  children: _kVehicles.map((v) {
                    final sel = v.type == _vehicle.type;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _vehicle = v;
                              if (_passengers > v.maxPax) _passengers = v.maxPax;
                              _estimate = null;
                            });
                            _scheduleEstimate();
                          },
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 180),
                            padding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                            decoration: BoxDecoration(
                              color: sel ? AppTheme.accent.withValues(alpha: 0.12) : context.appSurface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: sel ? AppTheme.accent : context.appCardBg,
                                width: sel ? 1.5 : 1,
                              ),
                            ),
                            child: Row(children: [
                              Icon(v.icon,
                                  color: sel ? AppTheme.accent : context.appTextSecondary,
                                  size: 22),
                              SizedBox(width: 10),
                              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(v.label,
                                    style: TextStyle(
                                      color: sel ? AppTheme.accent : context.appTextPrimary,
                                      fontWeight: FontWeight.w700, fontSize: 14,
                                    )),
                                Text(v.desc,
                                    style: TextStyle(
                                        color: context.appTextSecondary, fontSize: 11)),
                              ]),
                            ]),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                SizedBox(height: 20),

                // ── Passengers & luggage ─────────────────────────────────
                _SectionLabel(label: 'Passengers & Luggage'),
                SizedBox(height: 10),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.appSurface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(children: [
                    _CounterRow(
                      icon: Icons.person_outline_rounded,
                      label: 'Passengers',
                      value: _passengers,
                      min: 1,
                      max: _vehicle.maxPax,
                      onChanged: (v) => setState(() => _passengers = v),
                    ),
                    Divider(height: 20, color: context.appCardBg),
                    _CounterRow(
                      icon: Icons.luggage_rounded,
                      label: 'Luggage bags',
                      value: _luggage,
                      min: 0,
                      max: 6,
                      onChanged: (v) {
                        setState(() { _luggage = v; _estimate = null; });
                        _scheduleEstimate();
                      },
                    ),
                  ]),
                ),

                const SizedBox(height: 20),

                // ── Fare breakdown ───────────────────────────────────────
                _FareCard(
                  estimate:   _estimate,
                  loading:    _estimating,
                  hasAddress: _userLatLng != null,
                ),

                if (_bookError != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.error_outline, color: AppTheme.danger, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_bookError!,
                          style: const TextStyle(color: AppTheme.danger, fontSize: 13))),
                    ]),
                  ),
                ],

                const SizedBox(height: 8),
              ]),
            ),
          ),

          // ── Sticky book button ───────────────────────────────────────────
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _booking ? null : _book,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    disabledBackgroundColor: AppTheme.accent.withValues(alpha: 0.4),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _booking
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Icons.flight_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            _estimate != null
                                ? 'Book Transfer · ${AppTheme.khr(_estimate!.totalKhr)}'
                                : 'Book Airport Transfer',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                          ),
                        ]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helper widgets ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});
  @override
  Widget build(BuildContext context) => Text(label,
      style: TextStyle(color: context.appTextPrimary,
          fontSize: 14, fontWeight: FontWeight.w700));
}

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final String   message;
  const _InfoBanner({required this.icon, required this.color, required this.message});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(width: 10),
      Expanded(child: Text(message,
          style: TextStyle(color: color, fontSize: 13, height: 1.4))),
    ]),
  );
}

class _AddressField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  const _AddressField({required this.controller, required this.hint, required this.onChanged});
  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    onChanged: onChanged,
    style: TextStyle(color: context.appTextPrimary),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: context.appTextSecondary),
      prefixIcon: Icon(Icons.location_on_outlined, color: context.appTextSecondary, size: 20),
      filled: true,
      fillColor: context.appSurface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.accent, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
  );
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final List<TextInputFormatter>? inputFormatters;
  const _InputField({required this.controller, required this.hint,
      required this.icon, this.inputFormatters});
  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    inputFormatters: inputFormatters,
    style: TextStyle(color: context.appTextPrimary),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: context.appTextSecondary),
      prefixIcon: Icon(icon, color: context.appTextSecondary, size: 18),
      filled: true,
      fillColor: context.appSurface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.accent, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
  );
}

class _CounterRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final int      value;
  final int      min;
  final int      max;
  final ValueChanged<int> onChanged;
  const _CounterRow({required this.icon, required this.label, required this.value,
      required this.min, required this.max, required this.onChanged});
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, color: AppTheme.accent, size: 20),
    SizedBox(width: 12),
    Expanded(child: Text(label,
        style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w500))),
    _CounterBtn(icon: Icons.remove, enabled: value > min, onTap: () => onChanged(value - 1)),
    SizedBox(
      width: 36,
      child: Text('$value',
          textAlign: TextAlign.center,
          style: TextStyle(color: context.appTextPrimary,
              fontWeight: FontWeight.w700, fontSize: 16)),
    ),
    _CounterBtn(icon: Icons.add, enabled: value < max, onTap: () => onChanged(value + 1)),
  ]);
}

class _CounterBtn extends StatelessWidget {
  final IconData icon;
  final bool     enabled;
  final VoidCallback onTap;
  const _CounterBtn({required this.icon, required this.enabled, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: enabled ? onTap : null,
    child: Container(
      width: 32, height: 32,
      decoration: BoxDecoration(
        color: enabled ? AppTheme.accent.withValues(alpha: 0.1) : context.appCardBg,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: enabled ? AppTheme.accent : context.appTextSecondary, size: 16),
    ),
  );
}

// Shows the real itemised fare from the airport estimate API
class _FareCard extends StatelessWidget {
  final AirportEstimate? estimate;
  final bool loading;
  final bool hasAddress;
  const _FareCard({required this.estimate, required this.loading, required this.hasAddress});

  Widget _row(BuildContext context, String label, int khr, {bool bold = false, Color? color}) => Padding(
    padding: EdgeInsets.only(top: 6),
    child: Row(children: [
      Expanded(child: Text(label,
          style: TextStyle(
            color: color ?? context.appTextSecondary,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            fontSize: 13,
          ))),
      Text(AppTheme.khr(khr),
          style: TextStyle(
            color: color ?? context.appTextPrimary,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
            fontSize: bold ? 15 : 13,
          )),
    ]),
  );

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: CircularProgressIndicator(color: AppTheme.accent, strokeWidth: 2)));
    }
    if (!hasAddress) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: context.appSurface, borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          Icon(Icons.info_outline, color: context.appTextSecondary, size: 16),
          SizedBox(width: 8),
          Expanded(child: Text('Enter your address to see the estimated fare.',
              style: TextStyle(color: context.appTextSecondary, fontSize: 13))),
        ]),
      );
    }
    if (estimate == null) {
      return const SizedBox.shrink();
    }
    final est = estimate!;
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.local_offer_rounded, color: AppTheme.accent, size: 14),
          const SizedBox(width: 6),
          const Text('Fare Breakdown',
              style: TextStyle(color: AppTheme.accent, fontSize: 12,
                  fontWeight: FontWeight.w700)),
          const Spacer(),
          Text('${est.distanceKm.toStringAsFixed(1)} km',
              style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
        ]),
        Divider(height: 16, color: context.appCardBg),
        _row(context, 'Base fare', est.baseFareKhr),
        _row(context, 'Airport surcharge', est.surchargKhr),
        if (est.luggageCount > 0)
          _row(context, 'Luggage (${est.luggageCount} bag${est.luggageCount > 1 ? "s" : ""})',
              est.luggageFeeKhr),
        Divider(height: 16, color: context.appCardBg),
        _row(context, 'Total', est.totalKhr, bold: true, color: AppTheme.accent),
        SizedBox(height: 6),
        Text('Fixed price · No surge',
            style: TextStyle(color: context.appTextSecondary, fontSize: 11)),
      ]),
    );
  }
}

class UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue value) =>
      value.copyWith(text: value.text.toUpperCase(), selection: value.selection);
}
