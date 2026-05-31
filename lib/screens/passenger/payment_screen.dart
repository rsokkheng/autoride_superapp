import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../services/websocket_service.dart';
import '../../theme/app_theme.dart';
import 'rate_driver_screen.dart';

const _kGreen    = Color(0xFF00B14F);
const _kTextMain = Color(0xFF1A1A1A);
const _kTextSub  = Color(0xFF757575);
const _kDivider  = Color(0xFFEEEEEE);
const _kBg       = Color(0xFFF7F7F7);

class PaymentScreen extends StatefulWidget {
  final String from;
  final String fromAddress;
  final String to;
  final String toAddress;
  final double baseFare;    // KHR
  final double distanceKm;
  final int    durationMin;
  final double serviceFee;  // KHR
  final int?   rideId;
  final String? driverName;

  const PaymentScreen({
    super.key,
    this.from        = 'My location',
    this.fromAddress = 'St. 123, BKK 1, Phnom Penh',
    this.to          = 'Aeon Mall Phnom Penh',
    this.toAddress   = 'Samdach Sothearos Blvd, Phnom Penh',
    this.baseFare    = 10000,
    this.distanceKm  = 4.2,
    this.durationMin = 12,
    this.serviceFee  = 2000,
    this.rideId,
    this.driverName,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  GoogleMapController? _mapController;
  String _selectedMethod = 'cash';
  bool   _paying         = false;

  double get _distanceFare => (widget.distanceKm * 800).roundToDouble();
  double get _timeFare     => (widget.durationMin * 150).roundToDouble();
  double get _total        => widget.baseFare + _distanceFare + _timeFare + widget.serviceFee;

  static const _methods = [
    _PayMethod(key: 'cash',    label: 'Cash',       subtitle: 'Pay driver directly',   color: Color(0xFF6B7280), icon: Icons.payments_outlined),
    _PayMethod(key: 'aba',     label: 'ABA Pay',    subtitle: 'ABA Mobile / QR',       color: Color(0xFF004B87), icon: Icons.account_balance),
    _PayMethod(key: 'acleda',  label: 'ACLEDA',     subtitle: 'ACLEDA Mobile Banking', color: Color(0xFF006B3F), icon: Icons.account_balance),
    _PayMethod(key: 'wing',    label: 'Wing Money', subtitle: 'Wing Mobile Wallet',    color: Color(0xFFFF6B00), icon: Icons.flutter_dash),
    _PayMethod(key: 'wallet',  label: 'AutoRide Pay',subtitle: 'Your wallet balance',  color: _kGreen,           icon: Icons.account_balance_wallet_outlined),
  ];

  Future<void> _pay() async {
    setState(() => _paying = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _paying = false);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => RateDriverScreen(
          rideId:        widget.rideId,
          driverName:    widget.driverName ?? 'Driver',
          fare:          AppTheme.khr(_total),
          paymentMethod: _selectedMethod,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: const BackButton(color: _kTextMain),
        centerTitle: true,
        title: const Text('Confirm & Pay',
            style: TextStyle(color: _kTextMain, fontSize: 17, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(children: [
          // ── Map ─────────────────────────────────────────────────────────
          SizedBox(
            height: 160,
            child: GoogleMap(
              onMapCreated: (c) => _mapController = c,
              initialCameraPosition: const CameraPosition(
                  target: LatLng(11.5680, 104.9195), zoom: 13.5),
              markers: {
                Marker(
                  markerId: const MarkerId('pickup'),
                  position: WebSocketService.pickupPoint,
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                ),
                Marker(
                  markerId: const MarkerId('destination'),
                  position: WebSocketService.destinationPoint,
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                ),
              },
              polylines: {
                Polyline(
                  polylineId: const PolylineId('route'),
                  points: WebSocketService.driverRoute,
                  color: _kGreen,
                  width: 4,
                ),
              },
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              scrollGesturesEnabled: false,
              zoomGesturesEnabled: false,
            ),
          ),
          const SizedBox(height: 12),

          // ── Trip summary ─────────────────────────────────────────────────
          _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Trip Summary',
                style: TextStyle(color: _kTextMain, fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),

            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Column(children: [
                const SizedBox(height: 2),
                Container(width: 10, height: 10,
                    decoration: const BoxDecoration(color: _kGreen, shape: BoxShape.circle)),
                Container(width: 1.5, height: 32, color: _kDivider),
                const Icon(Icons.location_on, color: Colors.red, size: 14),
              ]),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.from,
                    style: const TextStyle(color: _kTextMain, fontSize: 14, fontWeight: FontWeight.w600)),
                if (widget.fromAddress.isNotEmpty)
                  Text(widget.fromAddress,
                      style: const TextStyle(color: _kTextSub, fontSize: 12),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 20),
                Text(widget.to,
                    style: const TextStyle(color: _kTextMain, fontSize: 14, fontWeight: FontWeight.w600)),
                if (widget.toAddress.isNotEmpty)
                  Text(widget.toAddress,
                      style: const TextStyle(color: _kTextSub, fontSize: 12),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
              ])),
            ]),

            const SizedBox(height: 16),
            const Divider(color: _kDivider, height: 1),
            const SizedBox(height: 14),

            _FareRow('Base fare',                                       AppTheme.khr(widget.baseFare)),
            const SizedBox(height: 8),
            _FareRow('Distance (${widget.distanceKm.toStringAsFixed(1)} km)', AppTheme.khr(_distanceFare)),
            const SizedBox(height: 8),
            _FareRow('Time (${widget.durationMin} min)',                 AppTheme.khr(_timeFare)),
            const SizedBox(height: 8),
            Row(children: [
              const Text('Service fee', style: TextStyle(color: _kTextSub, fontSize: 14)),
              const SizedBox(width: 4),
              const Icon(Icons.info_outline, color: _kTextSub, size: 14),
              const Spacer(),
              Text(AppTheme.khr(widget.serviceFee),
                  style: const TextStyle(color: _kTextMain, fontSize: 14)),
            ]),

            const SizedBox(height: 14),
            const Divider(color: _kDivider, height: 1),
            const SizedBox(height: 14),

            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Total',
                  style: TextStyle(color: _kTextMain, fontSize: 16, fontWeight: FontWeight.w700)),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(AppTheme.khr(_total),
                    style: const TextStyle(color: _kGreen, fontSize: 20, fontWeight: FontWeight.w800)),
                Text(AppTheme.usd(_total / 4000),
                    style: const TextStyle(color: _kTextSub, fontSize: 11)),
              ]),
            ]),
          ])),

          const SizedBox(height: 12),

          // ── Payment method ───────────────────────────────────────────────
          _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Payment Method',
                style: TextStyle(color: _kTextMain, fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('Choose how you want to pay',
                style: TextStyle(color: _kTextSub, fontSize: 12)),
            const SizedBox(height: 14),

            ...List.generate(_methods.length, (i) {
              final m = _methods[i];
              final isSelected = _selectedMethod == m.key;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() => _selectedMethod = m.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                      decoration: BoxDecoration(
                        color: isSelected ? m.color.withValues(alpha: 0.06) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? m.color : _kDivider,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(children: [
                        // Radio dot
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 22, height: 22,
                          decoration: BoxDecoration(
                            color: isSelected ? m.color : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? m.color : Colors.grey.shade400,
                              width: 1.8,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, color: Colors.white, size: 14)
                              : null,
                        ),
                        const SizedBox(width: 12),

                        // Method icon badge
                        Container(
                          width: 42, height: 30,
                          decoration: BoxDecoration(
                            color: m.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(m.icon, color: m.color, size: 18),
                        ),
                        const SizedBox(width: 12),

                        // Labels
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(m.label,
                              style: TextStyle(
                                color: isSelected ? _kTextMain : _kTextMain,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                fontSize: 14,
                              )),
                          Text(m.subtitle,
                              style: const TextStyle(color: _kTextSub, fontSize: 12)),
                        ])),

                        if (m.key == 'cash')
                          _Badge('No fee', Colors.green)
                        else if (m.key == 'wallet')
                          _Badge('Instant', _kGreen),
                      ]),
                    ),
                  ),
                ),
              );
            }),
          ])),

          const SizedBox(height: 12),

          // ── Promo ────────────────────────────────────────────────────────
          _Card(child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {},
              child: Row(children: [
                const Icon(Icons.local_offer_outlined, color: _kGreen, size: 20),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Have a promo code?',
                      style: TextStyle(color: _kTextMain, fontSize: 14, fontWeight: FontWeight.w500)),
                ),
                const Icon(Icons.chevron_right, color: _kTextSub),
              ]),
            ),
          )),
        ]),
      ),

      // ── Bottom bar ────────────────────────────────────────────────────────
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: _kDivider)),
        ),
        padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Selected method reminder
          Row(children: [
            const Icon(Icons.payment, color: _kTextSub, size: 16),
            const SizedBox(width: 6),
            Text(
              'Paying with ${_methods.firstWhere((m) => m.key == _selectedMethod).label}',
              style: const TextStyle(color: _kTextSub, fontSize: 12),
            ),
            const Spacer(),
            Text(AppTheme.usd(_total / 4000),
                style: const TextStyle(color: _kTextSub, fontSize: 12)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Total to pay', style: TextStyle(color: _kTextSub, fontSize: 12)),
              Text(AppTheme.khr(_total),
                  style: const TextStyle(color: _kGreen, fontSize: 20, fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _paying ? null : _pay,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kGreen,
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  icon: _paying
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.lock_outline, color: Colors.white, size: 18),
                  label: Text(_paying ? 'Processing…' : 'Confirm & Pay',
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _PayMethod {
  final String key, label, subtitle;
  final Color color;
  final IconData icon;
  const _PayMethod({required this.key, required this.label, required this.subtitle,
    required this.color, required this.icon});
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.symmetric(horizontal: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
    ),
    child: child,
  );
}

class _FareRow extends StatelessWidget {
  final String label, value;
  const _FareRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(color: _kTextSub, fontSize: 14)),
      Text(value,  style: const TextStyle(color: _kTextMain, fontSize: 14)),
    ],
  );
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge(this.text, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
  );
}
