import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/maps_service.dart';
import '../../widgets/roteh_location_map.dart';
import '../../widgets/guest_fields.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Duration options  (1M · 2M · 3M · 6M · 1Y · 2Y)
// ─────────────────────────────────────────────────────────────────────────────

enum _Dur { m1, m2, m3, m6, y1, y2 }

extension _DurX on _Dur {
  String get label => switch (this) {
    _Dur.m1 => '1 Month',
    _Dur.m2 => '2 Months',
    _Dur.m3 => '3 Months',
    _Dur.m6 => '6 Months',
    _Dur.y1 => '1 Year',
    _Dur.y2 => '2 Years',
  };
  IconData get icon => switch (this) {
    _Dur.m1 || _Dur.m2 || _Dur.m3 || _Dur.m6 => Icons.calendar_month_outlined,
    _Dur.y1 || _Dur.y2                         => Icons.calendar_today_outlined,
  };
  // total months equivalent
  int get months => switch (this) {
    _Dur.m1 => 1,  _Dur.m2 => 2,  _Dur.m3 => 3,
    _Dur.m6 => 6,  _Dur.y1 => 12, _Dur.y2 => 24,
  };
  String get unitLabel => months < 12 ? '/mo' : '/yr';
}

// ─────────────────────────────────────────────────────────────────────────────
// Location type  (Pick Up · Delivery)
// ─────────────────────────────────────────────────────────────────────────────

enum _LocType { pickup, delivery }

extension _LocTypeX on _LocType {
  String get label    => this == _LocType.pickup ? 'Pick Up' : 'Delivery';
  String get subtitle => this == _LocType.pickup
      ? "I'll collect the car myself"
      : "Deliver the car to my address";
  IconData get icon   => this == _LocType.pickup
      ? Icons.directions_walk_rounded
      : Icons.local_shipping_outlined;
  Color get pinColor  => this == _LocType.pickup ? AppTheme.accent : AppTheme.danger;
  String get hint     => this == _LocType.pickup
      ? 'Tap to set pickup location'
      : 'Tap to set delivery location';
  String get mapTitle => this == _LocType.pickup
      ? 'Set Pickup Location'
      : 'Set Delivery Location';
}

// ─────────────────────────────────────────────────────────────────────────────
// Data classes
// ─────────────────────────────────────────────────────────────────────────────

class _VehicleOpt {
  final String id, label, subtitle;
  final IconData icon;
  final int pricePerDay;
  const _VehicleOpt({
    required this.id, required this.label, required this.subtitle,
    required this.icon, required this.pricePerDay,
  });

  int get _monthlyRate => (pricePerDay * 30 * 0.85).round();
  int get _yearlyRate  => (pricePerDay * 365 * 0.80).round();

  int unitPrice(_Dur dur) => dur.months < 12 ? _monthlyRate : _yearlyRate;

  int totalPrice(_Dur dur) => dur.months < 12
      ? _monthlyRate * dur.months
      : _yearlyRate  * (dur.months ~/ 12);
}

class _PayOpt {
  final String id, label, subtitle;
  final IconData icon;
  const _PayOpt({required this.id, required this.label,
      required this.subtitle, required this.icon});
}

class _LocResult {
  final String address;
  final LatLng latLng;
  const _LocResult({required this.address, required this.latLng});
}

// ─────────────────────────────────────────────────────────────────────────────
// Car Rental Screen
// ─────────────────────────────────────────────────────────────────────────────

class CarRentalScreen extends StatefulWidget {
  const CarRentalScreen({super.key});
  @override
  State<CarRentalScreen> createState() => _CarRentalScreenState();
}

class _CarRentalScreenState extends State<CarRentalScreen> {
  // Location
  _LocType _locType    = _LocType.pickup;
  String   _locAddress = '';

  // Duration & dates
  _Dur     _duration  = _Dur.m1;
  DateTime _startDate = DateTime.now().add(const Duration(hours: 2));
  DateTime get _endDate => _calcEndDate(_startDate, _duration);

  // Selections
  String _vehicleId = 'sedan';
  String _paymentId = 'cash';

  // Coupon
  final _couponCtrl     = TextEditingController();
  bool   _applyingCoupon = false;
  String? _couponError;
  int    _discountKhr   = 0;
  String? _appliedCode;

  final _notesCtrl  = TextEditingController();
  bool _booking = false;
  String? _bookError;

  // Guest mode
  bool _isGuest = false;
  final _guestNameCtrl  = TextEditingController();
  final _guestPhoneCtrl = TextEditingController();

  // ── Static data ──────────────────────────────────────────────────────────

  static const _vehicles = [
    _VehicleOpt(id: 'sedan',      label: 'Sedan',      subtitle: 'Economy — city trips',        icon: Icons.directions_car_outlined,  pricePerDay: 60000),
    _VehicleOpt(id: 'suv',        label: 'SUV',        subtitle: 'Spacious — families & groups', icon: Icons.airport_shuttle,          pricePerDay: 100000),
    _VehicleOpt(id: 'van',        label: 'Van',        subtitle: 'Large groups or cargo',        icon: Icons.directions_bus_outlined,  pricePerDay: 120000),
    _VehicleOpt(id: 'motorcycle', label: 'Motorcycle', subtitle: 'Quick city rides',              icon: Icons.two_wheeler,              pricePerDay: 20000),
    _VehicleOpt(id: 'truck',      label: 'Truck',      subtitle: 'Heavy-duty transport',         icon: Icons.local_shipping_outlined,  pricePerDay: 150000),
    _VehicleOpt(id: 'tuk_tuk',   label: 'Tuk Tuk',   subtitle: 'Classic Cambodian style',      icon: Icons.electric_rickshaw,        pricePerDay: 30000),
    _VehicleOpt(id: 'electric',   label: 'Electric',   subtitle: 'Eco-friendly EV',              icon: Icons.electric_car_outlined,    pricePerDay: 80000),
  ];

  static const _payments = [
    _PayOpt(id: 'cash',   label: 'Cash',      subtitle: 'Pay in cash on pickup',   icon: Icons.payments_outlined),
    _PayOpt(id: 'aba',    label: 'ABA Pay',   subtitle: 'ABA mobile banking',      icon: Icons.account_balance),
    _PayOpt(id: 'acleda', label: 'ACLEDA',   subtitle: 'ACLEDA mobile banking',   icon: Icons.account_balance),
    _PayOpt(id: 'wing',   label: 'Wing',      subtitle: 'Wing mobile wallet',      icon: Icons.flight_takeoff),
    _PayOpt(id: 'wallet', label: 'ROTEH Pay', subtitle: 'In-app wallet balance',   icon: Icons.account_balance_wallet_outlined),
  ];

  // ── Helpers ──────────────────────────────────────────────────────────────

  _VehicleOpt get _vehicle =>
      _vehicles.firstWhere((v) => v.id == _vehicleId, orElse: () => _vehicles.first);

  _PayOpt get _payment =>
      _payments.firstWhere((p) => p.id == _paymentId, orElse: () => _payments.first);

  static DateTime _calcEndDate(DateTime start, _Dur dur) {
    int m = start.month + dur.months;
    final y = start.year + (m - 1) ~/ 12;
    m = ((m - 1) % 12) + 1;
    final maxDay = DateTime(y, m + 1, 0).day;
    return DateTime(y, m, start.day.clamp(1, maxDay), start.hour, start.minute);
  }

  String _fmt(DateTime dt) {
    const mo = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final h   = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final min = dt.minute.toString().padLeft(2, '0');
    final ap  = dt.hour >= 12 ? 'PM' : 'AM';
    return '${mo[dt.month - 1]} ${dt.day}, ${dt.year}  ${h.toString().padLeft(2, '0')}:$min $ap';
  }

  @override
  void initState() {
    super.initState();
    ApiService.isLoggedIn().then((v) {
      if (mounted) setState(() => _isGuest = !v);
    });
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _couponCtrl.dispose();
    _guestNameCtrl.dispose();
    _guestPhoneCtrl.dispose();
    super.dispose();
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _pickLocation() async {
    final result = await Navigator.push<_LocResult>(
      context,
      MaterialPageRoute(builder: (_) => _CarLocationPickerScreen(
        title:    _locType.mapTitle,
        pinColor: _locType.pinColor,
      )),
    );
    if (result == null || !mounted) return;
    setState(() => _locAddress = result.address);
  }

  Future<void> _pickStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme: Theme.of(ctx).colorScheme.copyWith(primary: AppTheme.accent)),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startDate),
    );
    if (!mounted) return;
    setState(() {
      _startDate = DateTime(date.year, date.month, date.day,
          time?.hour ?? _startDate.hour, time?.minute ?? _startDate.minute);
    });
  }

  void _openLocTypeSheet() {
    _openSheet<_LocType>(
      context: context,
      title: 'Location Type',
      items: _LocType.values.map((t) => _SheetItem(
        value: t, label: t.label, subtitle: t.subtitle, icon: t.icon,
      )).toList(),
      selected: _locType,
      onSelect: (t) => setState(() { _locType = t; _locAddress = ''; }),
    );
  }

  void _openVehicleSheet() {
    _openSheet<String>(
      context: context,
      title: 'Vehicle Type',
      items: _vehicles.map((v) => _SheetItem(
        value: v.id, label: v.label,
        subtitle: '${AppTheme.khr(v.unitPrice(_duration))}${_duration.unitLabel}',
        icon: v.icon,
      )).toList(),
      selected: _vehicleId,
      onSelect: (v) => setState(() => _vehicleId = v),
    );
  }

  void _openDurationSheet() {
    _openSheet<_Dur>(
      context: context,
      title: 'Rental Duration',
      items: _Dur.values.map((d) => _SheetItem(
        value: d,
        label: d.label,
        subtitle: 'Ends ${_fmt(_calcEndDate(_startDate, d))}',
        icon: d.icon,
      )).toList(),
      selected: _duration,
      onSelect: (d) => setState(() => _duration = d),
    );
  }

  void _openPaymentSheet() {
    _openSheet<String>(
      context: context,
      title: 'Payment Method',
      items: _payments.map((p) => _SheetItem(
        value: p.id, label: p.label, subtitle: p.subtitle, icon: p.icon,
      )).toList(),
      selected: _paymentId,
      onSelect: (v) => setState(() => _paymentId = v),
    );
  }

  Future<void> _applyCoupon() async {
    final code = _couponCtrl.text.trim();
    if (code.isEmpty) return;
    setState(() { _applyingCoupon = true; _couponError = null; });
    try {
      final subtotal = _vehicle.totalPrice(_duration);
      final result   = await ApiService.applyPromoCode(code, subtotal, serviceType: 'rental');
      if (!mounted) return;
      setState(() {
        _discountKhr    = (result['discount_amount'] as num? ?? 0).toInt();
        _appliedCode    = code;
        _couponError    = null;
        _applyingCoupon = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() { _couponError = e.message; _applyingCoupon = false; _discountKhr = 0; _appliedCode = null; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _couponError = 'Failed to apply coupon.'; _applyingCoupon = false; _discountKhr = 0; _appliedCode = null; });
    }
  }

  void _removeCoupon() => setState(() {
    _couponCtrl.clear();
    _discountKhr = 0;
    _appliedCode = null;
    _couponError = null;
  });

  Future<void> _bookNow() async {
    if (_locType == _LocType.delivery && _locAddress.isEmpty) {
      setState(() => _bookError = 'Please set a delivery location.');
      return;
    }
    if (_isGuest) {
      if (_guestNameCtrl.text.trim().isEmpty || _guestPhoneCtrl.text.trim().isEmpty) {
        setState(() => _bookError = 'Please enter your name and phone number.');
        return;
      }
    }
    setState(() { _booking = true; _bookError = null; });
    try {
      await ApiService.createCarRental(
        pickupLocation:   _locType == _LocType.pickup ? 'ROTEH CAMBODIA' : 'Depot',
        deliveryLocation: _locType == _LocType.delivery ? _locAddress : null,
        startDate:        _startDate,
        endDate:          _endDate,
        vehicleType:      _vehicleId,
        paymentMethod:    _paymentId,
        couponCode:       _appliedCode,
        notes:            _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        guestName:        _isGuest ? _guestNameCtrl.text.trim() : null,
        guestPhone:       _isGuest ? _guestPhoneCtrl.text.trim() : null,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Rental booked successfully!'),
          backgroundColor: AppTheme.success));
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() { _bookError = e.message; _booking = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _bookError = e.toString(); _booking = false; });
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final v        = _vehicle;
    final subtotal = v.totalPrice(_duration);
    final unitPr   = v.unitPrice(_duration);
    final total    = (subtotal - _discountKhr).clamp(0, subtotal);

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: Colors.black12,
        title: const Text('Car Rental',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
      ),
      body: Column(children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // ── Location ──────────────────────────────────────────────────
              _label('Location'),
              const SizedBox(height: 8),
              _DropdownTile(
                icon: _locType.icon,
                label: 'Location Type',
                value: _locType.label,
                subtitle: _locType.subtitle,
                onTap: _openLocTypeSheet,
              ),
              const SizedBox(height: 10),
              if (_locType == _LocType.pickup)
                const RotehLocationMap()
              else
                _Tile(
                  icon: Icons.location_on_rounded,
                  iconColor: _locType.pinColor,
                  text: _locAddress.isEmpty ? _locType.hint : _locAddress,
                  placeholder: _locAddress.isEmpty,
                  onTap: _pickLocation,
                ),
              const SizedBox(height: 16),

              // ── Vehicle type ──────────────────────────────────────────────
              _label('Vehicle Type'),
              const SizedBox(height: 8),
              _DropdownTile(
                icon: v.icon,
                label: 'Vehicle Type',
                value: v.label,
                subtitle: '${AppTheme.khr(v.unitPrice(_duration))}${_duration.unitLabel}',
                onTap: _openVehicleSheet,
              ),
              const SizedBox(height: 16),

              // ── Duration ──────────────────────────────────────────────────
              _label('Duration'),
              const SizedBox(height: 8),
              _DropdownTile(
                icon: _duration.icon,
                label: 'Rental Duration',
                value: _duration.label,
                subtitle: 'Ends ${_fmt(_endDate)}',
                onTap: _openDurationSheet,
              ),
              const SizedBox(height: 16),

              // ── Start date ────────────────────────────────────────────────
              _label('Start Date & Time'),
              const SizedBox(height: 8),
              _Tile(
                icon: Icons.calendar_today_outlined,
                iconColor: AppTheme.accent,
                text: _fmt(_startDate),
                onTap: _pickStartDate,
              ),
              const SizedBox(height: 10),

              // ── End date (auto) ───────────────────────────────────────────
              _label('End Date & Time  (auto)'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.accent.withValues(alpha: 0.2)),
                ),
                child: Row(children: [
                  const Icon(Icons.event_available_outlined, color: AppTheme.accent, size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_fmt(_endDate),
                      style: const TextStyle(color: AppTheme.accent,
                          fontWeight: FontWeight.w600))),
                ]),
              ),
              const SizedBox(height: 16),

              // ── Payment ───────────────────────────────────────────────────
              _label('Payment Method'),
              const SizedBox(height: 8),
              _DropdownTile(
                icon: _payment.icon,
                label: 'Payment Method',
                value: _payment.label,
                subtitle: _payment.subtitle,
                onTap: _openPaymentSheet,
              ),
              const SizedBox(height: 16),

              // ── Guest info ────────────────────────────────────────────────
              if (_isGuest) ...[
                _label('Your Information'),
                const SizedBox(height: 8),
                GuestFields(
                    nameCtrl: _guestNameCtrl, phoneCtrl: _guestPhoneCtrl),
                const SizedBox(height: 20),
              ],

              // ── Notes ─────────────────────────────────────────────────────
              _label('Notes (optional)'),
              const SizedBox(height: 8),
              TextField(
                controller: _notesCtrl,
                maxLines: 3,
                style: TextStyle(color: context.appTextPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Any special requests…',
                  hintStyle: TextStyle(color: context.appTextSecondary),
                  filled: true,
                  fillColor: context.appSurface,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              const SizedBox(height: 20),

              // ── Coupon code ───────────────────────────────────────────────
              _label('Coupon Code'),
              const SizedBox(height: 8),
              if (_appliedCode != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.local_offer_rounded, color: AppTheme.accent, size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_appliedCode!, style: const TextStyle(
                          color: AppTheme.accent, fontWeight: FontWeight.w700, fontSize: 14)),
                      Text('- ${AppTheme.khr(_discountKhr)} discount applied',
                          style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
                    ])),
                    GestureDetector(
                      onTap: _removeCoupon,
                      child: Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: AppTheme.danger.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, color: AppTheme.danger, size: 16),
                      ),
                    ),
                  ]),
                ),
              ] else ...[
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _couponCtrl,
                      textCapitalization: TextCapitalization.characters,
                      style: TextStyle(color: context.appTextPrimary, fontSize: 14,
                          fontWeight: FontWeight.w600, letterSpacing: 1.2),
                      decoration: InputDecoration(
                        hintText: 'Enter coupon code',
                        hintStyle: TextStyle(color: context.appTextSecondary,
                            fontWeight: FontWeight.w400, letterSpacing: 0),
                        filled: true,
                        fillColor: context.appSurface,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        prefixIcon: const Icon(Icons.local_offer_outlined,
                            color: AppTheme.accent, size: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _applyingCoupon ? null : _applyCoupon,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppTheme.accent.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                      ),
                      child: _applyingCoupon
                          ? const SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Apply', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ]),
                if (_couponError != null) ...[
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.error_outline, color: AppTheme.danger, size: 14),
                    const SizedBox(width: 6),
                    Text(_couponError!, style: const TextStyle(
                        color: AppTheme.danger, fontSize: 12)),
                  ]),
                ],
              ],
              const SizedBox(height: 20),

              // ── Summary ───────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.appSurface,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Column(children: [
                  Text('Booking Summary',
                      style: TextStyle(color: context.appTextPrimary,
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  _SummaryRow('Vehicle',  v.label),
                  const SizedBox(height: 8),
                  _SummaryRow('Duration', _duration.label),
                  const SizedBox(height: 8),
                  _SummaryRow('Rate', '${AppTheme.khr(unitPr)}${_duration.unitLabel}'),
                  const SizedBox(height: 8),
                  Row(children: [
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.local_offer_outlined, size: 14, color: AppTheme.accent),
                      const SizedBox(width: 4),
                      Text(
                        _appliedCode != null ? 'Discount ($_appliedCode)' : 'Discount',
                        style: TextStyle(color: context.appTextSecondary, fontSize: 14),
                      ),
                    ]),
                    const Spacer(),
                    Text(
                      _discountKhr > 0 ? '- ${AppTheme.khr(_discountKhr)}' : '—',
                      style: TextStyle(
                        color: _discountKhr > 0 ? AppTheme.accent : context.appTextSecondary,
                        fontWeight: _discountKhr > 0 ? FontWeight.w600 : FontWeight.w400,
                        fontSize: 14,
                      ),
                    ),
                  ]),
                  Divider(color: context.appCardBg, height: 20),
                  Row(children: [
                    Text('Total', style: TextStyle(color: context.appTextPrimary,
                        fontWeight: FontWeight.w700, fontSize: 16)),
                    const Spacer(),
                    Text(AppTheme.khr(total), style: const TextStyle(color: AppTheme.accent,
                        fontWeight: FontWeight.w900, fontSize: 20)),
                  ]),
                ]),
              ),

              // ── Error ─────────────────────────────────────────────────────
              if (_bookError != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.danger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline, color: AppTheme.danger, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_bookError!,
                        style: const TextStyle(color: AppTheme.danger, fontSize: 12))),
                  ]),
                ),
              ],
              const SizedBox(height: 20),
            ]),
          ),
        ),

        // ── Book Now button ───────────────────────────────────────────────
        Container(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
          decoration: BoxDecoration(
            color: context.appSurface,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 12, offset: const Offset(0, -4))],
          ),
          child: SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: _booking ? null : _bookNow,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _booking
                  ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : const Text('Book Now',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _label(String text) => Text(text,
      style: TextStyle(color: context.appTextPrimary,
          fontWeight: FontWeight.w600, fontSize: 13));
}

// ─────────────────────────────────────────────────────────────────────────────
// Generic bottom-sheet dropdown (delivery style)
// ─────────────────────────────────────────────────────────────────────────────

class _SheetItem<T> {
  final T value;
  final String label, subtitle;
  final IconData icon;
  const _SheetItem({required this.value, required this.label,
      required this.subtitle, required this.icon});
}

void _openSheet<T>({
  required BuildContext context,
  required String title,
  required List<_SheetItem<T>> items,
  required T selected,
  required ValueChanged<T> onSelect,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: context.appSurface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => SafeArea(
      top: false,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          width: 40, height: 4,
          decoration: BoxDecoration(
              color: ctx.appCardBg, borderRadius: BorderRadius.circular(2)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(title, style: TextStyle(
                color: ctx.appTextPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
        Divider(height: 1, color: ctx.appCardBg),
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.55),
          child: ListView(shrinkWrap: true, children: items.map((item) {
            final isSel = item.value == selected;
            return InkWell(
              onTap: () { onSelect(item.value); Navigator.pop(ctx); },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: isSel ? AppTheme.accent.withValues(alpha: 0.12) : ctx.appCardBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(item.icon,
                        color: isSel ? AppTheme.accent : ctx.appTextSecondary, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(item.label, style: TextStyle(
                        color: isSel ? AppTheme.accent : ctx.appTextPrimary,
                        fontWeight: FontWeight.w600, fontSize: 14)),
                    if (item.subtitle.isNotEmpty)
                      Text(item.subtitle, style: TextStyle(
                          color: ctx.appTextSecondary, fontSize: 12)),
                  ])),
                  isSel
                      ? const Icon(Icons.check_circle, color: AppTheme.accent, size: 20)
                      : Icon(Icons.radio_button_off, color: ctx.appTextSecondary, size: 20),
                ]),
              ),
            );
          }).toList()),
        ),
        const SizedBox(height: 8),
      ]),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// UI helpers
// ─────────────────────────────────────────────────────────────────────────────

class _Tile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;
  final bool placeholder;
  final VoidCallback onTap;
  const _Tile({required this.icon, required this.iconColor, required this.text,
      this.placeholder = false, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(text, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: placeholder ? context.appTextSecondary : context.appTextPrimary,
              fontWeight: placeholder ? FontWeight.w400 : FontWeight.w500,
              fontSize: 14,
            ))),
        Icon(Icons.chevron_right_rounded, color: context.appTextSecondary, size: 18),
      ]),
    ),
  );
}

class _DropdownTile extends StatelessWidget {
  final IconData icon;
  final String label, value, subtitle;
  final VoidCallback onTap;
  const _DropdownTile({required this.icon, required this.label,
      required this.value, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.appCardBg),
      ),
      child: Row(children: [
        Icon(icon, color: AppTheme.accent, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(
              color: context.appTextSecondary, fontSize: 10, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(
              color: context.appTextPrimary, fontWeight: FontWeight.w700, fontSize: 13),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          if (subtitle.isNotEmpty)
            Text(subtitle, style: TextStyle(
                color: context.appTextSecondary, fontSize: 10),
                maxLines: 1, overflow: TextOverflow.ellipsis),
        ])),
        Icon(Icons.keyboard_arrow_down, color: context.appTextSecondary, size: 20),
      ]),
    ),
  );
}

class _SummaryRow extends StatelessWidget {
  final String label, value;
  const _SummaryRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Row(children: [
    Text(label, style: TextStyle(color: context.appTextSecondary, fontSize: 14)),
    const Spacer(),
    Text(value, style: TextStyle(color: context.appTextPrimary,
        fontWeight: FontWeight.w600, fontSize: 14)),
  ]);
}

// ─────────────────────────────────────────────────────────────────────────────
// Location picker screen
// ─────────────────────────────────────────────────────────────────────────────

class _CarLocationPickerScreen extends StatefulWidget {
  final String title;
  final Color  pinColor;
  const _CarLocationPickerScreen({
    this.title    = 'Set Location',
    this.pinColor = AppTheme.accent,
  });
  @override
  State<_CarLocationPickerScreen> createState() => _CarLocationPickerScreenState();
}

class _CarLocationPickerScreenState extends State<_CarLocationPickerScreen> {
  static const _phnomPenh = LatLng(11.5680, 104.9195);

  GoogleMapController? _mapCtrl;
  LatLng _center   = _phnomPenh;
  String _address  = '';
  bool   _geocoding = false;

  final _searchCtrl = TextEditingController();
  List<PlaceResult> _results = [];
  bool  _searching = false;
  Timer? _debounce;

  @override
  void dispose() {
    _mapCtrl?.dispose();
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String q) {
    _debounce?.cancel();
    if (q.trim().isEmpty) { setState(() => _results = []); return; }
    _debounce = Timer(const Duration(milliseconds: 450), () => _doSearch(q));
  }

  Future<void> _doSearch(String q) async {
    setState(() => _searching = true);
    try {
      final r = await MapsService.searchAddress(q);
      if (mounted) setState(() { _results = r; _searching = false; });
    } catch (_) {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _selectResult(PlaceResult r) {
    _searchCtrl.text = r.address;
    setState(() { _center = r.latLng; _address = r.address; _results = []; });
    _mapCtrl?.animateCamera(CameraUpdate.newLatLngZoom(r.latLng, 16));
  }

  Future<void> _onCameraIdle() async {
    setState(() { _geocoding = true; _address = ''; });
    try {
      final a = await MapsService.reverseGeocode(_center);
      if (mounted) setState(() {
        _address  = a ?? '${_center.latitude.toStringAsFixed(4)}, ${_center.longitude.toStringAsFixed(4)}';
        _geocoding = false;
      });
    } catch (_) {
      if (mounted) setState(() => _geocoding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      body: Stack(children: [

        // Map
        GoogleMap(
          onMapCreated: (c) {
            _mapCtrl = c;
            c.animateCamera(CameraUpdate.newLatLngZoom(_center, 15));
            _onCameraIdle();
          },
          initialCameraPosition: CameraPosition(target: _center, zoom: 15),
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          onCameraMove: (pos) => _center = pos.target,
          onCameraIdle: _onCameraIdle,
        ),

        // Crosshair pin
        Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.location_on_rounded, color: widget.pinColor, size: 40),
            const SizedBox(
              width: 10, height: 4,
              child: DecoratedBox(decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.all(Radius.circular(2)))),
            ),
          ]),
        ),

        // Top: back + search
        SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: context.appSurface, shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 6)],
                    ),
                    child: Icon(Icons.arrow_back_ios_new_rounded,
                        color: context.appTextPrimary, size: 18),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: context.appSurface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 8)],
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: _onSearchChanged,
                      style: TextStyle(color: context.appTextPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search location…',
                        hintStyle: TextStyle(color: context.appTextSecondary, fontSize: 14),
                        prefixIcon: _searching
                            ? Padding(
                                padding: const EdgeInsets.all(12),
                                child: SizedBox(width: 18, height: 18,
                                    child: CircularProgressIndicator(
                                        color: AppTheme.accent, strokeWidth: 2)))
                            : Icon(Icons.search_rounded,
                                color: context.appTextSecondary, size: 20),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.close_rounded,
                                    color: context.appTextSecondary, size: 18),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _results = []);
                                })
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
              ]),
            ),

            // Search results
            if (_results.isNotEmpty)
              Container(
                margin: const EdgeInsets.fromLTRB(62, 6, 12, 0),
                decoration: BoxDecoration(
                  color: context.appSurface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 10)],
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _results.length.clamp(0, 5),
                  separatorBuilder: (_, __) => Divider(height: 1, color: context.appCardBg),
                  itemBuilder: (_, i) {
                    final r = _results[i];
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.place_outlined,
                          color: AppTheme.accent, size: 18),
                      title: Text(r.address, maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: context.appTextPrimary, fontSize: 13)),
                      onTap: () => _selectResult(r),
                    );
                  },
                ),
              ),
          ]),
        ),

        // Bottom confirm
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(
                16, 14, 16, 14 + MediaQuery.of(context).padding.bottom),
            decoration: BoxDecoration(
              color: context.appSurface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 16, offset: const Offset(0, -4))],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                    color: context.appCardBg, borderRadius: BorderRadius.circular(2)),
              ),
              Row(children: [
                Icon(Icons.location_on_rounded, color: widget.pinColor, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: _geocoding
                      ? Row(children: [
                          SizedBox(width: 14, height: 14,
                              child: CircularProgressIndicator(
                                  color: AppTheme.accent, strokeWidth: 2)),
                          const SizedBox(width: 10),
                          Text('Finding address…',
                              style: TextStyle(color: context.appTextSecondary, fontSize: 13)),
                        ])
                      : Text(_address.isEmpty ? 'Drag map to set location' : _address,
                          maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: context.appTextPrimary,
                              fontSize: 14, fontWeight: FontWeight.w500)),
                ),
              ]),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: (_geocoding || _address.isEmpty)
                      ? null
                      : () => Navigator.pop(context,
                          _LocResult(address: _address, latLng: _center)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.pinColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: widget.pinColor.withValues(alpha: 0.35),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text(widget.title,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                ),
              ),
            ]),
          ),
        ),

        // My location button
        Positioned(
          right: 14,
          bottom: 140 + MediaQuery.of(context).padding.bottom,
          child: GestureDetector(
            onTap: () async {
              try {
                final pos = await Geolocator.getCurrentPosition(
                    desiredAccuracy: LocationAccuracy.high);
                if (!mounted) return;
                _mapCtrl?.animateCamera(
                    CameraUpdate.newLatLngZoom(LatLng(pos.latitude, pos.longitude), 16));
              } catch (_) {}
            },
            child: Builder(builder: (ctx) => Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: ctx.appSurface, shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 6)],
              ),
              child: Icon(Icons.my_location_rounded, color: ctx.appTextPrimary, size: 22),
            )),
          ),
        ),
      ]),
    );
  }
}

// ── Shared guest name + phone fields ─────────────────────────────────────────

