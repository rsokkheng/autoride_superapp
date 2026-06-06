import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/ride_model.dart';

class DriverTripSummaryScreen extends StatelessWidget {
  final RideModel ride;

  const DriverTripSummaryScreen({super.key, required this.ride});

  static const _kGreen    = Color(0xFF00B14F);
  static const _kTextMain = Color(0xFF1A1A1A);
  static const _kTextSub  = Color(0xFF6B7280);
  static const _kDivider  = Color(0xFFE5E7EB);
  static const _kBg       = Color(0xFFF7F7F7);

  String get _passengerName =>
      ride.passenger?.name ?? 'Passenger #${ride.passengerId}';

  String get _passengerRating =>
      ride.passengerRating != null ? ride.passengerRating!.toStringAsFixed(1) : '5.0';

  String get _serviceLabel {
    switch (ride.serviceType) {
      case 'premium': return 'Premium';
      case 'xl':      return 'ROTEH XL';
      case 'ev':      return 'EV Ride';
      default:        return 'Standard';
    }
  }

  @override
  Widget build(BuildContext context) {
    final fareKhr = ride.fareKhr;

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                // ── Success header ──────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  decoration: BoxDecoration(
                    color: _kGreen.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(children: [
                    Container(
                      width: 68, height: 68,
                      decoration: const BoxDecoration(color: _kGreen, shape: BoxShape.circle),
                      child: const Icon(Icons.check, color: Colors.white, size: 36),
                    ),
                    const SizedBox(height: 14),
                    const Text('Trip Completed!',
                        style: TextStyle(color: _kTextMain, fontSize: 22, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('Ride #${ride.id}',
                        style: const TextStyle(color: _kTextSub, fontSize: 13)),
                  ]),
                ),
                const SizedBox(height: 16),

                // ── Passenger card ──────────────────────────────────────────
                _Card(child: Row(children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: _kGreen.withValues(alpha: 0.15),
                    child: Text(
                      _passengerName.isNotEmpty ? _passengerName[0].toUpperCase() : 'P',
                      style: const TextStyle(color: _kGreen, fontWeight: FontWeight.w800, fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_passengerName,
                        style: const TextStyle(color: _kTextMain, fontWeight: FontWeight.w700, fontSize: 15)),
                    Row(children: [
                      const Icon(Icons.star_rounded, color: Color(0xFFFACC15), size: 15),
                      const SizedBox(width: 3),
                      Text(_passengerRating, style: const TextStyle(color: _kTextSub, fontSize: 12)),
                    ]),
                  ])),
                  // Service badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _kGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(_serviceLabel,
                        style: const TextStyle(color: _kGreen, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ])),
                const SizedBox(height: 12),

                // ── Route card ──────────────────────────────────────────────
                _Card(child: Column(children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Column(children: [
                      const SizedBox(height: 2),
                      Container(
                        width: 10, height: 10,
                        decoration: const BoxDecoration(color: _kGreen, shape: BoxShape.circle),
                      ),
                      Container(width: 1.5, height: 36, color: _kDivider),
                      const Icon(Icons.location_on, color: Colors.red, size: 14),
                    ]),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Pickup', style: TextStyle(color: _kTextSub, fontSize: 11)),
                      const SizedBox(height: 2),
                      Text(ride.pickupAddress,
                          style: const TextStyle(color: _kTextMain, fontSize: 13, fontWeight: FontWeight.w600),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 16),
                      const Text('Destination', style: TextStyle(color: _kTextSub, fontSize: 11)),
                      const SizedBox(height: 2),
                      Text(ride.dropoffAddress,
                          style: const TextStyle(color: _kTextMain, fontSize: 13, fontWeight: FontWeight.w600),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                    ])),
                  ]),
                ])),
                const SizedBox(height: 12),

                // ── Trip stats ──────────────────────────────────────────────
                _Card(child: Row(children: [
                  _StatItem(
                    icon: Icons.straighten_outlined,
                    label: 'Distance',
                    value: ride.distanceKm != null
                        ? '${ride.distanceKm!.toStringAsFixed(1)} km'
                        : '--',
                  ),
                  _Divider(),
                  _StatItem(
                    icon: Icons.access_time_outlined,
                    label: 'Duration',
                    value: ride.durationMin != null ? '${ride.durationMin} min' : '--',
                  ),
                  _Divider(),
                  _StatItem(
                    icon: Icons.directions_car_outlined,
                    label: 'Type',
                    value: _serviceLabel,
                  ),
                ])),
                const SizedBox(height: 12),

                // ── Fare summary ────────────────────────────────────────────
                _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('FARE SUMMARY',
                      style: TextStyle(color: _kTextSub, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                  const SizedBox(height: 14),
                  if (ride.distanceKm != null) ...[
                    _FareRow(
                      label: 'Base fare',
                      value: AppTheme.khr(3000),
                    ),
                    const SizedBox(height: 8),
                    _FareRow(
                      label: 'Distance (${ride.distanceKm!.toStringAsFixed(1)} km)',
                      value: AppTheme.khr((fareKhr - 3000).clamp(0, fareKhr)),
                    ),
                    const SizedBox(height: 8),
                    Divider(color: _kDivider, height: 16),
                  ],
                  Row(children: [
                    const Text('Total Fare',
                        style: TextStyle(color: _kTextMain, fontWeight: FontWeight.w700, fontSize: 15)),
                    const Spacer(),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(AppTheme.khr(fareKhr),
                          style: const TextStyle(color: _kGreen, fontWeight: FontWeight.w800, fontSize: 18)),
                      Text(AppTheme.usd(fareKhr / 4000),
                          style: const TextStyle(color: _kTextSub, fontSize: 11)),
                    ]),
                  ]),
                ])),
                const SizedBox(height: 12),

                // ── Payment method ──────────────────────────────────────────
                _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('PAYMENT METHOD',
                      style: TextStyle(color: _kTextSub, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                  const SizedBox(height: 14),
                  _PaymentMethodDisplay(method: ride.paymentMethod ?? 'cash'),
                ])),
                const SizedBox(height: 24),
              ]),
            ),
          ),

          // ── Bottom button ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Back to Dashboard',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Local widgets ────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: child,
  );
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(children: [
      Icon(icon, color: DriverTripSummaryScreen._kGreen, size: 20),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(color: DriverTripSummaryScreen._kTextMain, fontWeight: FontWeight.w700, fontSize: 13)),
      Text(label, style: const TextStyle(color: DriverTripSummaryScreen._kTextSub, fontSize: 11)),
    ]),
  );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 1, height: 36,
    color: DriverTripSummaryScreen._kDivider,
    margin: const EdgeInsets.symmetric(horizontal: 4),
  );
}

class _FareRow extends StatelessWidget {
  final String label;
  final String value;
  const _FareRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(children: [
    Text(label, style: const TextStyle(color: DriverTripSummaryScreen._kTextSub, fontSize: 13)),
    const Spacer(),
    Text(value, style: const TextStyle(color: DriverTripSummaryScreen._kTextMain, fontSize: 13, fontWeight: FontWeight.w600)),
  ]);
}

class _PaymentMethodDisplay extends StatelessWidget {
  final String method;
  const _PaymentMethodDisplay({required this.method});

  static const _methods = [
    _PayMethod('cash',        'Cash',        Icons.payments_outlined,    Color(0xFF6B7280)),
    _PayMethod('aba',         'ABA Pay',     Icons.account_balance,      Color(0xFF003087)),
    _PayMethod('acleda',      'ACLEDA',      Icons.account_balance,      Color(0xFF006B3F)),
    _PayMethod('wing',        'Wing',        Icons.flight_takeoff,       Color(0xFFFF6B00)),
    _PayMethod('wallet',      'ROTEH Pay',Icons.account_balance_wallet,Color(0xFF00B14F)),
    _PayMethod('other_online','Online Pay',  Icons.language,             Color(0xFF2196F3)),
  ];

  @override
  Widget build(BuildContext context) {
    final matched = _methods.firstWhere(
      (m) => m.key == method,
      orElse: () => _methods.first,
    );

    return Row(children: [
      Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: matched.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(matched.icon, color: matched.color, size: 22),
      ),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(matched.label,
            style: const TextStyle(color: DriverTripSummaryScreen._kTextMain, fontWeight: FontWeight.w700, fontSize: 15)),
        const Text('Payment received', style: TextStyle(color: DriverTripSummaryScreen._kTextSub, fontSize: 12)),
      ]),
      const Spacer(),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF00B14F).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text('Confirmed',
            style: TextStyle(color: Color(0xFF00B14F), fontSize: 11, fontWeight: FontWeight.w700)),
      ),
    ]);
  }
}

class _PayMethod {
  final String key;
  final String label;
  final IconData icon;
  final Color color;
  const _PayMethod(this.key, this.label, this.icon, this.color);
}
