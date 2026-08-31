import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/maps_service.dart';
import '../../widgets/roteh_location_map.dart';
import '../../widgets/guest_fields.dart';
import '../../widgets/location_picker_screen.dart';
import 'my_rentals_screen.dart';
import '../../models/marketplace_model.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart' show appLocale;

// ─────────────────────────────────────────────────────────────────────────────
// Duration options  (1M · 2M · 3M · 6M · 1Y · 2Y)
// ─────────────────────────────────────────────────────────────────────────────

enum _Dur { m1, m2, m3, m6, y1, y2 }

extension _DurX on _Dur {
  String get label {
    final l = AppLocalizations(appLocale.value);
    return switch (this) {
      _Dur.m1 => l.durMonth1,
      _Dur.m2 => l.durMonth2,
      _Dur.m3 => l.durMonth3,
      _Dur.m6 => l.durMonth6,
      _Dur.y1 => l.durYear1,
      _Dur.y2 => l.durYear2,
    };
  }
  IconData get icon => switch (this) {
    _Dur.m1 || _Dur.m2 || _Dur.m3 || _Dur.m6 => Icons.calendar_month_outlined,
    _Dur.y1 || _Dur.y2                         => Icons.calendar_today_outlined,
  };
  int get months => switch (this) {
    _Dur.m1 => 1,  _Dur.m2 => 2,  _Dur.m3 => 3,
    _Dur.m6 => 6,  _Dur.y1 => 12, _Dur.y2 => 24,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Location type  (Pick Up · Delivery)
// ─────────────────────────────────────────────────────────────────────────────

enum _LocType { pickup, delivery }

extension _LocTypeX on _LocType {
  String get label {
    final l = AppLocalizations(appLocale.value);
    return this == _LocType.pickup ? l.pickUpLabel : l.delivery;
  }
  String get subtitle {
    final l = AppLocalizations(appLocale.value);
    return this == _LocType.pickup ? l.collectCarMyself : l.deliverCarToAddress;
  }
  IconData get icon   => this == _LocType.pickup
      ? Icons.directions_walk_rounded
      : Icons.local_shipping_outlined;
  Color get pinColor  => this == _LocType.pickup ? AppTheme.accent : AppTheme.danger;
  String get hint {
    final l = AppLocalizations(appLocale.value);
    return this == _LocType.pickup ? l.tapToSetPickupLocation : l.tapToSetDeliveryLocation;
  }
  String get mapTitle {
    final l = AppLocalizations(appLocale.value);
    return this == _LocType.pickup ? l.setPickupLocationTitle : l.setDeliveryLocationTitle;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Rental catalog car
// ─────────────────────────────────────────────────────────────────────────────

class _RentalCar {
  final String  vehicleType; // sedan | suv | van | motorcycle | truck | tuk_tuk | electric
  final String  name;
  final String  description;
  final double  dailyRateUsd;
  final int?    marketplaceProductId;
  final String? imageUrl;

  const _RentalCar({
    required this.vehicleType,
    required this.name,
    required this.description,
    required this.dailyRateUsd,
    this.marketplaceProductId,
    this.imageUrl,
  });

  factory _RentalCar.fromJson(Map<String, dynamic> m) {
    final type    = m['vehicle_type'] as String? ?? m['type'] as String? ?? '';
    final product = m['product'] as Map<String, dynamic>?;
    return _RentalCar(
      vehicleType:          type,
      name:                 product?['title'] as String?
                                ?? m['name'] as String? ?? _labelFor(type),
      description:          m['description'] as String? ?? m['subtitle'] as String? ?? '',
      dailyRateUsd:         _toDouble(product?['rent_price_per_day']
                                ?? m['daily_rate_usd'] ?? m['price_per_day'] ?? m['rate']),
      marketplaceProductId: (m['marketplace_product_id'] as num?)?.toInt()
                                ?? (product?['id'] as num?)?.toInt(),
    );
  }

  static String _labelFor(String type) {
    final l = AppLocalizations(appLocale.value);
    return switch (type) {
      'suv'        => l.suvLabel,
      'van'        => l.van,
      'motorcycle' => l.motorcycle,
      'truck'      => l.truck,
      'tuk_tuk'    => l.tukTuk,
      'electric'   => l.electricLabel,
      _            => l.sedanLabel,
    };
  }

  static double _toDouble(dynamic v) =>
      v == null ? 0 : v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0;

  IconData get icon => switch (vehicleType) {
    'suv'        => Icons.airport_shuttle,
    'van'        => Icons.directions_bus_outlined,
    'motorcycle' => Icons.two_wheeler,
    'truck'      => Icons.local_shipping_outlined,
    'tuk_tuk'    => Icons.electric_rickshaw,
    'electric'   => Icons.electric_car_outlined,
    _            => Icons.directions_car_outlined,
  };

  String get rateLabel {
    final fmt = NumberFormat('#,##0.##', 'en_US');
    return '\$${fmt.format(dailyRateUsd)}/day';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data classes
// ─────────────────────────────────────────────────────────────────────────────

class _PayOpt {
  final String id, label, subtitle;
  final IconData icon;
  const _PayOpt({required this.id, required this.label,
      required this.subtitle, required this.icon});
}

// ─────────────────────────────────────────────────────────────────────────────
// Car Rental Screen
// ─────────────────────────────────────────────────────────────────────────────

class CarRentalScreen extends StatefulWidget {
  final MarketplaceProductModel? preselectedProduct;
  const CarRentalScreen({super.key, this.preselectedProduct});
  @override
  State<CarRentalScreen> createState() => _CarRentalScreenState();
}

class _CarRentalScreenState extends State<CarRentalScreen> {
  // Location
  _LocType _locType    = _LocType.pickup;
  String   _locAddress = '';
  LatLng?  _locLatLng;

  // Duration & dates
  _Dur     _duration  = _Dur.m1;
  DateTime _startDate = DateTime.now();
  DateTime get _endDate => _calcEndDate(_startDate, _duration);

  // Selected car from rental catalog
  _RentalCar? _selectedCar;

  // Payment
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

  // ── Pricing helpers ───────────────────────────────────────────────────────

  double get _dailyRate => _selectedCar?.dailyRateUsd ?? 0;
  int    get _totalDays => _duration.months * 30;
  double get _totalUsd  => _dailyRate * _totalDays;

  String _usd(double v) {
    final fmt = NumberFormat('#,##0.##', 'en_US');
    return '\$${fmt.format(v)}';
  }

  List<_PayOpt> get _payments {
    final l = AppLocalizations(appLocale.value);
    return [
      _PayOpt(id: 'cash',         label: l.cash,        subtitle: l.payInCashOnPickup,      icon: Icons.payments_outlined),
      _PayOpt(id: 'wallet',       label: l.rotehPay,     subtitle: l.inAppWalletBalance,    icon: Icons.account_balance_wallet_outlined),
      _PayOpt(id: 'aba',          label: l.abaPay,       subtitle: l.abaMobileBanking,      icon: Icons.account_balance),
      _PayOpt(id: 'wing',         label: l.wing,         subtitle: l.wingMobileWallet,      icon: Icons.flight_takeoff),
      _PayOpt(id: 'other_online', label: l.otherOnline,  subtitle: l.otherOnlinePayment,    icon: Icons.language_outlined),
    ];
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

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
    return '${mo[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  static String _fmtDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')}';

  @override
  void initState() {
    super.initState();
    final pre = widget.preselectedProduct;
    if (pre != null) {
      _selectedCar = _carBrowsePageToRentalCar(pre);
    }
    ApiService.isLoggedIn().then((v) {
      if (mounted) setState(() => _isGuest = !v);
    });
  }

  static _RentalCar _carBrowsePageToRentalCar(MarketplaceProductModel p) {
    final t = '${p.title} ${p.description ?? ''}'.toLowerCase();
    String vtype = 'sedan';
    if (t.contains('motorcycle') || t.contains('moto') || t.contains('bike')) vtype = 'motorcycle';
    else if (t.contains('truck'))    vtype = 'truck';
    else if (t.contains('van'))      vtype = 'van';
    else if (t.contains('suv'))      vtype = 'suv';
    else if (t.contains('tuk'))      vtype = 'tuk_tuk';
    else if (t.contains('electric')) vtype = 'electric';
    return _RentalCar(
      vehicleType:          vtype,
      name:                 p.title,
      description:          p.description ?? '',
      dailyRateUsd:         p.rentPricePerDay ?? p.price,
      marketplaceProductId: p.id,
      imageUrl:             p.images.isNotEmpty ? p.images.first : null,
    );
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
    final result = await Navigator.push<LocationPickResult>(
      context,
      MaterialPageRoute(builder: (_) => LocationPickerScreen(
        title:    _locType.mapTitle,
        pinColor: _locType.pinColor,
        initial:  _locLatLng,
      )),
    );
    if (result == null || !mounted) return;
    setState(() { _locAddress = result.address; _locLatLng = result.latLng; });
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
    setState(() => _startDate = DateTime(date.year, date.month, date.day));
  }

  void _openLocTypeSheet() {
    _openSheet<_LocType>(
      context: context,
      title: AppLocalizations.of(context).locationTypeLabel,
      items: _LocType.values.map((t) => _SheetItem(
        value: t, label: t.label, subtitle: t.subtitle, icon: t.icon,
      )).toList(),
      selected: _locType,
      onSelect: (t) => setState(() { _locType = t; _locAddress = ''; _locLatLng = null; }),
    );
  }

  Future<void> _browseCars() async {
    final picked = await Navigator.push<_RentalCar>(
      context,
      MaterialPageRoute(builder: (_) => _CarBrowsePage(
        selectedId: _selectedCar?.marketplaceProductId,
        duration:   _duration,
      )),
    );
    if (picked != null && mounted) setState(() => _selectedCar = picked);
  }

  void _openDurationSheet() {
    _openSheet<_Dur>(
      context: context,
      title: AppLocalizations.of(context).rentalDurationTitle,
      items: _Dur.values.map((d) => _SheetItem(
        value: d,
        label: d.label,
        subtitle: '${AppLocalizations.of(context).endsPrefix} ${_fmt(_calcEndDate(_startDate, d))}',
        icon: d.icon,
      )).toList(),
      selected: _duration,
      onSelect: (d) => setState(() => _duration = d),
    );
  }

  void _openPaymentSheet() {
    _openSheet<String>(
      context: context,
      title: AppLocalizations.of(context).paymentMethod,
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
      final subtotalKhr = (_totalUsd * 4100).round();
      final result   = await ApiService.applyPromoCode(code, subtotalKhr, serviceType: 'rental');
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
      setState(() { _couponError = AppLocalizations.of(context).failedToApplyCoupon; _applyingCoupon = false; _discountKhr = 0; _appliedCode = null; });
    }
  }

  void _removeCoupon() => setState(() {
    _couponCtrl.clear();
    _discountKhr = 0;
    _appliedCode = null;
    _couponError = null;
  });

  void _showConfirmation(Map<String, dynamic> r) {
    final product   = r['product']  as Map<String, dynamic>?;
    final user      = r['user']     as Map<String, dynamic>?;
    final vtype     = r['vehicle_type'] as String? ?? '';
    final title     = product?['title'] as String?
                          ?? (vtype.isEmpty ? AppLocalizations.of(context).vehicle : vtype[0].toUpperCase() + vtype.substring(1).replaceAll('_', ' '));
    final image     = product?['image']  as String?;
    // field names vary: total_days | days, daily_rate_usd | daily_rate, total_amount_usd | total_amount | total
    final days  = (r['total_days']  ?? r['days'])  as num?;
    final daily = (r['daily_rate_usd'] ?? r['daily_rate'] ?? r['price_per_day']) as num?;
    final total = (r['total_amount_usd'] ?? r['total_amount'] ?? r['total']) as num?;
    // rental id: rental_id | id
    final rentalId  = ((r['rental_id'] ?? r['id']) as num?)?.toInt() ?? 0;
    final status    = r['status']     as String? ?? 'pending';
    final startDate = r['start_date'] as String? ?? '';
    final endDate   = r['end_date']   as String? ?? '';
    final fmt       = NumberFormat('#,##0.##', 'en_US');
    String usd(double v) => '\$${fmt.format(v)}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // handle
          Center(child: Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: context.appCardBg,
              borderRadius: BorderRadius.circular(2),
            ),
          )),
          // car image
          if (image != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(image, height: 160, width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink()),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${AppLocalizations.of(context).bookedHashPrefix}$rentalId',
                      style: const TextStyle(
                          color: AppTheme.success,
                          fontWeight: FontWeight.w700, fontSize: 12)),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.appCardBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(status.toUpperCase(),
                      style: TextStyle(
                          color: context.appTextSecondary,
                          fontWeight: FontWeight.w600, fontSize: 11)),
                ),
              ]),
              const SizedBox(height: 10),
              Text(title,
                  style: TextStyle(
                      color: context.appTextPrimary,
                      fontWeight: FontWeight.w800, fontSize: 18)),
              const SizedBox(height: 14),
              if (startDate.isNotEmpty)
                _ConfRow(label: AppLocalizations.of(context).datesLabel, value: '$startDate → $endDate'),
              if (days != null)
                _ConfRow(label: AppLocalizations.of(context).duration, value: '${days.toInt()} ${AppLocalizations.of(context).daysLabel}'),
              if (daily != null)
                _ConfRow(label: AppLocalizations.of(context).dailyRateLabel, value: usd(daily.toDouble())),
              if (total != null)
                _ConfRow(label: AppLocalizations.of(context).total, value: usd(total.toDouble()), highlight: true),
              if (user != null) ...[
                const Divider(height: 24),
                _ConfRow(label: AppLocalizations.of(context).renterLabel, value: user['name'] as String? ?? ''),
                _ConfRow(label: AppLocalizations.of(context).phone,  value: user['phone'] as String? ?? ''),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const MyRentalsScreen()),
                      (route) => route.isFirst,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text(AppLocalizations.of(context).done,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
            ]),
          ),
        ]),
      ),
    );
  }

  Future<void> _bookNow() async {
    if (_selectedCar == null) {
      setState(() => _bookError = AppLocalizations.of(context).selectVehicleBeforeBooking);
      return;
    }
    if (_locType == _LocType.delivery && _locAddress.isEmpty) {
      setState(() => _bookError = AppLocalizations.of(context).setDeliveryLocationError);
      return;
    }
    if (_isGuest) {
      if (_guestNameCtrl.text.trim().isEmpty || _guestPhoneCtrl.text.trim().isEmpty) {
        setState(() => _bookError = AppLocalizations.of(context).enterNamePhoneError);
        return;
      }
    }
    setState(() { _booking = true; _bookError = null; });

    final pickupLocation = _locType == _LocType.pickup ? 'ROTEH CAMBODIA' : _locAddress;

    try {
      final result = await ApiService.createCarRental(
        pickupLocation:       pickupLocation,
        startDate:            _startDate,
        endDate:              _endDate,
        marketplaceProductId: _selectedCar!.marketplaceProductId,
        vehicleType:          _selectedCar!.vehicleType,
        pickupLat:            _locLatLng?.latitude,
        pickupLng:            _locLatLng?.longitude,
        paymentMethod:        _paymentId,
        notes:                _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      if (!mounted) return;
      _showConfirmation(result);
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
    final car        = _selectedCar;
    final totalUsd   = _totalUsd;
    final discountUsd = _discountKhr / 4100.0;
    final finalUsd   = (totalUsd - discountUsd).clamp(0.0, totalUsd);

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: Colors.black12,
        title: Text(AppLocalizations.of(context).rentalVehicleTitle,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
      ),
      body: Column(children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // ── Location ──────────────────────────────────────────────────
              _label(AppLocalizations.of(context).locationLabel),
              const SizedBox(height: 8),
              _DropdownTile(
                icon: _locType.icon,
                label: AppLocalizations.of(context).locationTypeLabel,
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

              // ── Vehicle for rent ─────────────────────────────────────────────
              _label(AppLocalizations.of(context).vehicleForRentLabel),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _browseCars,
                child: Container(
                  decoration: BoxDecoration(
                    color: context.appSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: car == null ? AppTheme.danger.withValues(alpha: 0.4) : context.appCardBg,
                    ),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                  child: car == null
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                          child: Row(children: [
                            Container(
                              width: 48, height: 48,
                              decoration: BoxDecoration(
                                color: AppTheme.accent.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.electric_rickshaw,
                                  color: AppTheme.accent, size: 26),
                            ),
                            const SizedBox(width: 14),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(AppLocalizations.of(context).browseAvailableVehicle,
                                  style: TextStyle(color: context.appTextPrimary,
                                      fontWeight: FontWeight.w700, fontSize: 14)),
                              const SizedBox(height: 2),
                              Text(AppLocalizations.of(context).tapToViewAllVehicles,
                                  style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
                            ])),
                            const Icon(Icons.chevron_right_rounded,
                                color: AppTheme.accent, size: 22),
                          ]),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                width: 58, height: 58,
                                child: car.imageUrl != null
                                    ? Image.network(car.imageUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: AppTheme.accent.withValues(alpha: 0.10),
                                          child: Icon(car.icon, color: AppTheme.accent, size: 28),
                                        ))
                                    : Container(
                                        color: AppTheme.accent.withValues(alpha: 0.10),
                                        child: Icon(car.icon, color: AppTheme.accent, size: 28),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(car.name,
                                  style: TextStyle(color: context.appTextPrimary,
                                      fontWeight: FontWeight.w700, fontSize: 14),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Text(car.rateLabel,
                                  style: const TextStyle(color: AppTheme.accent,
                                      fontWeight: FontWeight.w700, fontSize: 13)),
                              if (car.description.isNotEmpty)
                                Text(car.description,
                                    maxLines: 1, overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: context.appTextSecondary, fontSize: 11)),
                            ])),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppTheme.accent.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(AppLocalizations.of(context).change,
                                  style: const TextStyle(color: AppTheme.accent,
                                      fontSize: 12, fontWeight: FontWeight.w700)),
                            ),
                          ]),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Rental Period ─────────────────────────────────────────────
              _label(AppLocalizations.of(context).rentalPeriodLabel),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.appSurface,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6, offset: const Offset(0, 2))],
                ),
                child: Column(children: [
                  _DropdownTile(
                    icon: _duration.icon,
                    label: AppLocalizations.of(context).duration,
                    value: _duration.label,
                    subtitle: '$_totalDays ${AppLocalizations.of(context).daysLabel}  ·  ${AppLocalizations.of(context).endsLabel} ${_fmt(_endDate)}',
                    onTap: _openDurationSheet,
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: GestureDetector(
                      onTap: _pickStartDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                        decoration: BoxDecoration(
                          color: context.appCardBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(AppLocalizations.of(context).startDateLabel, style: TextStyle(
                              color: context.appTextSecondary,
                              fontSize: 10, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Row(children: [
                            const Icon(Icons.calendar_today_outlined,
                                color: AppTheme.accent, size: 13),
                            const SizedBox(width: 5),
                            Expanded(child: Text(_fmt(_startDate),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: context.appTextPrimary,
                                    fontWeight: FontWeight.w700, fontSize: 12))),
                          ]),
                        ]),
                      ),
                    )),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.arrow_forward_rounded,
                          color: AppTheme.accent, size: 16),
                    ),
                    Expanded(child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.18)),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(AppLocalizations.of(context).endDateAutoLabel, style: const TextStyle(
                            color: AppTheme.accent,
                            fontSize: 10, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Row(children: [
                          const Icon(Icons.event_available_outlined,
                              color: AppTheme.accent, size: 13),
                          const SizedBox(width: 5),
                          Expanded(child: Text(_fmt(_endDate),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppTheme.accent,
                                  fontWeight: FontWeight.w700, fontSize: 12))),
                        ]),
                      ]),
                    )),
                  ]),
                ]),
              ),
              const SizedBox(height: 16),

              // ── Payment ───────────────────────────────────────────────────
              _label(AppLocalizations.of(context).paymentMethod),
              const SizedBox(height: 8),
              _DropdownTile(
                icon: _payment.icon,
                label: AppLocalizations.of(context).paymentMethod,
                value: _payment.label,
                subtitle: _payment.subtitle,
                onTap: _openPaymentSheet,
              ),
              const SizedBox(height: 16),

              // ── Guest info ────────────────────────────────────────────────
              if (_isGuest) ...[
                _label(AppLocalizations.of(context).yourInformationLabel),
                const SizedBox(height: 8),
                GuestFields(
                    nameCtrl: _guestNameCtrl, phoneCtrl: _guestPhoneCtrl),
                const SizedBox(height: 20),
              ],

              // ── Notes ─────────────────────────────────────────────────────
              _label(AppLocalizations.of(context).notesOptionalLabel),
              const SizedBox(height: 8),
              TextField(
                controller: _notesCtrl,
                maxLines: 3,
                style: TextStyle(color: context.appTextPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context).anySpecialRequestsHint,
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
              _label(AppLocalizations.of(context).couponCodeLabel),
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
                      Text('- ${AppTheme.khr(_discountKhr)} ${AppLocalizations.of(context).discountAppliedSuffix}',
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
                        hintText: AppLocalizations.of(context).enterCouponCodeHint,
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
                          : Text(AppLocalizations.of(context).apply, style: const TextStyle(fontWeight: FontWeight.w700)),
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
                  Text(AppLocalizations.of(context).bookingSummaryLabel,
                      style: TextStyle(color: context.appTextPrimary,
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  _SummaryRow(AppLocalizations.of(context).vehicle,    car?.name ?? '—'),
                  const SizedBox(height: 8),
                  _SummaryRow(AppLocalizations.of(context).duration,   _duration.label),
                  const SizedBox(height: 8),
                  _SummaryRow(AppLocalizations.of(context).dailyRateLabel, car == null ? '—' : _usd(_dailyRate)),
                  const SizedBox(height: 8),
                  _SummaryRow(AppLocalizations.of(context).daysCapLabel, car == null ? '—' : '$_totalDays ${AppLocalizations.of(context).daysLabel}'),
                  const SizedBox(height: 8),
                  Row(children: [
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.local_offer_outlined, size: 14, color: AppTheme.accent),
                      const SizedBox(width: 4),
                      Text(
                        _appliedCode != null ? '${AppLocalizations.of(context).discountLabel} ($_appliedCode)' : AppLocalizations.of(context).discountLabel,
                        style: TextStyle(color: context.appTextSecondary, fontSize: 14),
                      ),
                    ]),
                    const Spacer(),
                    Text(
                      _discountKhr > 0 ? '- ${_usd(discountUsd)}' : '—',
                      style: TextStyle(
                        color: _discountKhr > 0 ? AppTheme.accent : context.appTextSecondary,
                        fontWeight: _discountKhr > 0 ? FontWeight.w600 : FontWeight.w400,
                        fontSize: 14,
                      ),
                    ),
                  ]),
                  Divider(color: context.appCardBg, height: 20),
                  Row(children: [
                    Text(AppLocalizations.of(context).total, style: TextStyle(color: context.appTextPrimary,
                        fontWeight: FontWeight.w700, fontSize: 16)),
                    const Spacer(),
                    Text(
                      car == null ? '—' : _usd(finalUsd),
                      style: const TextStyle(color: AppTheme.accent,
                          fontWeight: FontWeight.w900, fontSize: 20),
                    ),
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
                  : Text(AppLocalizations.of(context).bookNowLabel,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
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
// Generic bottom-sheet dropdown
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
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: TextStyle(color: context.appTextSecondary, fontSize: 14)),
    const SizedBox(width: 12),
    Expanded(
      child: Text(value, textAlign: TextAlign.right, style: TextStyle(color: context.appTextPrimary,
          fontWeight: FontWeight.w600, fontSize: 14)),
    ),
  ]);
}

// ─────────────────────────────────────────────────────────────────────────────
// Car browse page
// ─────────────────────────────────────────────────────────────────────────────

class _CarBrowsePage extends StatefulWidget {
  final int?  selectedId; // marketplace product id
  final _Dur  duration;
  const _CarBrowsePage({this.selectedId, required this.duration});
  @override
  State<_CarBrowsePage> createState() => _CarBrowsePageState();
}

class _CarBrowsePageState extends State<_CarBrowsePage> {
  bool _loading = true;
  String? _error;
  List<MarketplaceProductModel> _products = [];
  MarketplaceProductModel? _selected;

  List<MarketplaceVehicleTypeModel>  _vTypes  = [];
  List<MarketplaceVehicleColorModel> _vColors = [];
  List<MarketplaceVehicleSizeModel>  _vSizes  = [];
  int? _vTypeId;
  int? _vColorId;
  int? _vSizeId;
  bool get _hasActiveFilters => _vTypeId != null || _vColorId != null || _vSizeId != null;

  // Map vehicle_type keyword from title/condition to icon
  IconData _iconFor(MarketplaceProductModel p) {
    final t = '${p.title} ${p.description ?? ''}'.toLowerCase();
    if (t.contains('motorcycle') || t.contains('moto') || t.contains('bike')) return Icons.two_wheeler;
    if (t.contains('truck'))    return Icons.local_shipping_outlined;
    if (t.contains('van'))      return Icons.directions_bus_outlined;
    if (t.contains('suv'))      return Icons.airport_shuttle;
    if (t.contains('tuk'))      return Icons.electric_rickshaw;
    if (t.contains('electric')) return Icons.electric_car_outlined;
    return Icons.directions_car_outlined;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final needsRefData = _vTypes.isEmpty;
      final results = await Future.wait([
        if (needsRefData) ApiService.getMarketplaceVehicleTypes(),
        if (needsRefData) ApiService.getMarketplaceVehicleColors(),
        if (needsRefData) ApiService.getMarketplaceVehicleSizes(),
        ApiService.getMarketplaceProducts(
          listingType:    'rent',
          vehicleTypeId:  _vTypeId,
          vehicleColorId: _vColorId,
          vehicleSizeId:  _vSizeId,
        ),
      ]);
      if (!mounted) return;
      final page = results.last as MarketplaceProductsPage;
      setState(() {
        if (needsRefData) {
          _vTypes  = results[0] as List<MarketplaceVehicleTypeModel>;
          _vColors = results[1] as List<MarketplaceVehicleColorModel>;
          _vSizes  = results[2] as List<MarketplaceVehicleSizeModel>;
        }
        _products = page.products;
        _selected = widget.selectedId == null ? null
            : page.products.cast<MarketplaceProductModel?>()
                .firstWhere((p) => p!.id == widget.selectedId, orElse: () => null);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _openFilterSheet() async {
    final result = await showModalBottomSheet<_RentalFilterSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RentalFilterSheet(
        vehicleTypes: _vTypes,
        vehicleSizes: _vSizes,
        vehicleColors: _vColors,
        initial: _RentalFilterSelection(
          vehicleTypeId: _vTypeId, vehicleSizeId: _vSizeId, vehicleColorId: _vColorId,
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _vTypeId  = result.vehicleTypeId;
      _vSizeId  = result.vehicleSizeId;
      _vColorId = result.vehicleColorId;
    });
    _load();
  }

  // Convert a marketplace product → _RentalCar for the booking flow
  _RentalCar _toRentalCar(MarketplaceProductModel p) {
    final t = '${p.title} ${p.description ?? ''}'.toLowerCase();
    String vtype = 'sedan';
    if (t.contains('motorcycle') || t.contains('moto') || t.contains('bike')) vtype = 'motorcycle';
    else if (t.contains('truck'))    vtype = 'truck';
    else if (t.contains('van'))      vtype = 'van';
    else if (t.contains('suv'))      vtype = 'suv';
    else if (t.contains('tuk'))      vtype = 'tuk_tuk';
    else if (t.contains('electric')) vtype = 'electric';
    return _RentalCar(
      vehicleType:          vtype,
      name:                 p.title,
      description:          p.description ?? '',
      dailyRateUsd:         p.rentPricePerDay ?? p.price,
      marketplaceProductId: p.id,
      imageUrl:             p.images.isNotEmpty ? p.images.first : null,
    );
  }

  String _usd(double v) {
    final fmt = NumberFormat('#,##0.##', 'en_US');
    return '\$${fmt.format(v)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: Colors.black12,
        title: Text(AppLocalizations.of(context).vehicleForRentLabel,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        actions: [
          IconButton(
            onPressed: _openFilterSheet,
            icon: Badge(
              isLabelVisible: _hasActiveFilters,
              smallSize: 8,
              backgroundColor: AppTheme.accent,
              child: Icon(Icons.tune_rounded, color: context.appTextPrimary, size: 22),
            ),
          ),
        ],
      ),
      body: Column(children: [
        if (_vTypes.isNotEmpty)
          Container(
            width: double.infinity,
            color: context.appSurface,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _VehicleTypePill(
                  label: AppLocalizations.of(context).all,
                  active: _vTypeId == null,
                  onTap: () { setState(() => _vTypeId = null); _load(); },
                ),
                const SizedBox(width: 8),
                for (final vt in _vTypes) ...[
                  _VehicleTypePill(
                    label: vt.name(appLocale.value.languageCode),
                    active: _vTypeId == vt.id,
                    onTap: () { setState(() => _vTypeId = _vTypeId == vt.id ? null : vt.id); _load(); },
                  ),
                  const SizedBox(width: 8),
                ],
              ]),
            ),
          ),
        if (_hasActiveFilters)
          Container(
            width: double.infinity,
            color: context.appSurface,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Wrap(spacing: 8, runSpacing: 8, children: [
              if (_vTypeId != null)
                _RentalFilterChip(
                  label: _vTypes.firstWhere((t) => t.id == _vTypeId).name(appLocale.value.languageCode),
                  onClear: () { setState(() => _vTypeId = null); _load(); }),
              if (_vSizeId != null)
                _RentalFilterChip(
                  label: _vSizes.firstWhere((s) => s.id == _vSizeId).label,
                  onClear: () { setState(() => _vSizeId = null); _load(); }),
              if (_vColorId != null)
                _RentalFilterChip(
                  label: _vColors.firstWhere((c) => c.id == _vColorId).name(appLocale.value.languageCode),
                  onClear: () { setState(() => _vColorId = null); _load(); }),
              GestureDetector(
                onTap: () {
                  setState(() { _vTypeId = null; _vSizeId = null; _vColorId = null; });
                  _load();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(AppLocalizations.of(context).clearAll,
                      style: const TextStyle(color: Colors.grey, fontSize: 12, decoration: TextDecoration.underline)),
                ),
              ),
            ]),
          ),
        Expanded(child: _buildBody(context)),
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
              onPressed: _selected == null ? null
                  : () => Navigator.pop(context, _toRentalCar(_selected!)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppTheme.accent.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Text(
                _selected == null ? AppLocalizations.of(context).selectAVehicleLabel : '${AppLocalizations.of(context).rentDashPrefix} ${_selected!.title}',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.accent));
    }
    if (_error != null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, color: AppTheme.danger, size: 40),
        const SizedBox(height: 12),
        Text(AppLocalizations.of(context).failedToLoadVehicles,
            style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextButton(onPressed: _load, child: Text(AppLocalizations.of(context).retry)),
      ]));
    }
    if (_products.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context).noVehicleAvailableForRent,
          style: TextStyle(color: context.appTextSecondary)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _products.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (ctx, i) {
        final p        = _products[i];
        final selected = p.id == _selected?.id;
        final daily    = p.rentPricePerDay ?? p.price;
        return GestureDetector(
          onTap: () => setState(() => _selected = p),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: context.appSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? AppTheme.accent : context.appCardBg,
                width: selected ? 2 : 1,
              ),
              boxShadow: [BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8, offset: const Offset(0, 2),
              )],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Image or icon placeholder
              Stack(children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                  child: p.images.isNotEmpty
                      ? Image.network(
                          p.images.first,
                          height: 190, width: double.infinity, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _imagePlaceholder(context, p),
                        )
                      : _imagePlaceholder(context, p),
                ),
                if (selected)
                  Positioned(
                    top: 10, right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                          color: AppTheme.accent, shape: BoxShape.circle),
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                    ),
                  ),
                if (p.images.length > 1)
                  Positioned(
                    bottom: 8, right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('+${p.images.length - 1} ${AppLocalizations.of(context).photosCountSuffix}',
                          style: const TextStyle(color: Colors.white, fontSize: 11)),
                    ),
                  ),
              ]),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(
                      child: Text(p.title,
                          style: TextStyle(
                            color: selected ? AppTheme.accent : context.appTextPrimary,
                            fontWeight: FontWeight.w700, fontSize: 15,
                          )),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('${_usd(daily)}/day',
                          style: const TextStyle(
                              color: AppTheme.accent,
                              fontWeight: FontWeight.w800, fontSize: 13)),
                    ),
                  ]),
                  if (p.description != null && p.description!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(p.description!,
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
                  ],
                  if (p.locationText != null) ...[
                    const SizedBox(height: 6),
                    Row(children: [
                      Icon(Icons.location_on_outlined,
                          color: context.appTextSecondary, size: 13),
                      const SizedBox(width: 3),
                      Expanded(child: Text(p.locationText!,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: context.appTextSecondary, fontSize: 11))),
                    ]),
                  ],
                ]),
              ),
            ]),
          ),
        );
      },
    );
  }

  Widget _imagePlaceholder(BuildContext context, MarketplaceProductModel p) =>
      Container(
        height: 190, color: context.appCardBg,
        child: Center(child: Icon(_iconFor(p), size: 64,
            color: context.appTextSecondary.withValues(alpha: 0.4))),
      );
}

// Maps the backend's vehicle-color `code` (a plain slug like 'black'/'red',
// not a hex value) to an actual swatch color.
Color _rentalSwatchFor(String code) => switch (code) {
      'black' => const Color(0xFF1A1A1A),
      'white' => const Color(0xFFF5F5F5),
      'red'   => const Color(0xFFE53935),
      'blue'  => const Color(0xFF1976D2),
      'gray' || 'grey' => const Color(0xFF9E9E9E),
      'green' => const Color(0xFF43A047),
      'yellow' => const Color(0xFFFDD835),
      'orange' => const Color(0xFFFB8C00),
      'silver' => const Color(0xFFC0C0C0),
      'brown' => const Color(0xFF6D4C41),
      _       => const Color(0xFF9E9E9E),
    };

// Icon-over-label tab for the vehicle-type quick filter row — matches the
// same style used on the Marketplace listings screen.
// Matches the same pill style used on the Marketplace listings screen.
class _VehicleTypePill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _VehicleTypePill({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: active ? AppTheme.accent.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: active ? AppTheme.accent : const Color(0xFFE0E0E0), width: 1.5),
      ),
      child: Text(label,
          style: TextStyle(color: active ? AppTheme.accent : Colors.grey.shade600,
              fontWeight: FontWeight.w600, fontSize: 12)),
    ),
  );
}

class _RentalFilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onClear;
  const _RentalFilterChip({required this.label, required this.onClear});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.only(left: 10, right: 4, top: 4, bottom: 4),
    decoration: BoxDecoration(
      color: AppTheme.accent.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppTheme.accent.withValues(alpha: 0.4)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(label, style: const TextStyle(color: AppTheme.accent, fontSize: 12, fontWeight: FontWeight.w600)),
      GestureDetector(
        onTap: onClear,
        child: const Padding(
          padding: EdgeInsets.all(4),
          child: Icon(Icons.close_rounded, size: 14, color: AppTheme.accent),
        ),
      ),
    ]),
  );
}

class _RentalFilterSelection {
  final int? vehicleTypeId;
  final int? vehicleSizeId;
  final int? vehicleColorId;
  const _RentalFilterSelection({this.vehicleTypeId, this.vehicleSizeId, this.vehicleColorId});
}

class _RentalFilterSheet extends StatefulWidget {
  final List<MarketplaceVehicleTypeModel>  vehicleTypes;
  final List<MarketplaceVehicleSizeModel>  vehicleSizes;
  final List<MarketplaceVehicleColorModel> vehicleColors;
  final _RentalFilterSelection initial;
  const _RentalFilterSheet({
    required this.vehicleTypes, required this.vehicleSizes,
    required this.vehicleColors, required this.initial,
  });

  @override
  State<_RentalFilterSheet> createState() => _RentalFilterSheetState();
}

class _RentalFilterSheetState extends State<_RentalFilterSheet> {
  int? _vType;
  int? _vSize;
  int? _vColor;

  @override
  void initState() {
    super.initState();
    _vType  = widget.initial.vehicleTypeId;
    _vSize  = widget.initial.vehicleSizeId;
    _vColor = widget.initial.vehicleColorId;
  }

  Widget _checkboxRow(String label, bool checked, VoidCallback onTap) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Checkbox(value: checked, activeColor: AppTheme.accent, onChanged: (_) => onTap()),
        Expanded(child: Text(label, style: TextStyle(color: context.appTextPrimary, fontSize: 14))),
      ]),
    ),
  );

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 4),
    child: Text(text, style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
  );

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 40, height: 4,
              decoration: BoxDecoration(color: context.appCardBg, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(AppLocalizations.of(context).filter, style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w800, fontSize: 16)),
              GestureDetector(
                onTap: () => setState(() { _vType = null; _vSize = null; _vColor = null; }),
                child: Text(AppLocalizations.of(context).clearAll, style: const TextStyle(color: AppTheme.accent, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ]),
          ),
          const Divider(height: 20),
          Expanded(
            child: ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                if (widget.vehicleTypes.isNotEmpty) ...[
                  _sectionTitle(AppLocalizations.of(context).vehicleType),
                  for (final vt in widget.vehicleTypes)
                    _checkboxRow(vt.name(appLocale.value.languageCode), _vType == vt.id,
                        () => setState(() => _vType = _vType == vt.id ? null : vt.id)),
                ],
                if (widget.vehicleSizes.isNotEmpty) ...[
                  _sectionTitle(AppLocalizations.of(context).size),
                  for (final vs in widget.vehicleSizes)
                    _checkboxRow(vs.label, _vSize == vs.id,
                        () => setState(() => _vSize = _vSize == vs.id ? null : vs.id)),
                ],
                if (widget.vehicleColors.isNotEmpty) ...[
                  _sectionTitle(AppLocalizations.of(context).color),
                  Wrap(spacing: 14, runSpacing: 10, children: [
                    for (final vc in widget.vehicleColors)
                      GestureDetector(
                        onTap: () => setState(() => _vColor = _vColor == vc.id ? null : vc.id),
                        child: Tooltip(
                          message: vc.name(appLocale.value.languageCode),
                          child: Container(
                            width: 26, height: 26,
                            decoration: BoxDecoration(
                              color: _rentalSwatchFor(vc.code),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: _vColor == vc.id ? AppTheme.accent : const Color(0xFFE0E0E0),
                                  width: _vColor == vc.id ? 2.5 : 1),
                            ),
                            child: _vColor == vc.id
                                ? Icon(Icons.check, size: 14,
                                    color: _rentalSwatchFor(vc.code).computeLuminance() > 0.5 ? Colors.black : Colors.white)
                                : null,
                          ),
                        ),
                      ),
                  ]),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context, _RentalFilterSelection(
                    vehicleTypeId: _vType, vehicleSizeId: _vSize, vehicleColorId: _vColor,
                  )),
                  child: Text(AppLocalizations.of(context).apply, style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _ConfRow extends StatelessWidget {
  final String label, value;
  final bool highlight;
  const _ConfRow({required this.label, required this.value, this.highlight = false});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [
      Text(label, style: TextStyle(color: context.appTextSecondary, fontSize: 13)),
      const Spacer(),
      Text(value, style: TextStyle(
        color: highlight ? AppTheme.accent : context.appTextPrimary,
        fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
        fontSize: highlight ? 15 : 13,
      )),
    ]),
  );
}
