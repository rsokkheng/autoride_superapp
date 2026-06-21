import 'package:flutter/material.dart';
import 'package:autoride_superapp/theme/app_theme.dart';
import 'package:share_plus/share_plus.dart';

class TripReceiptScreen extends StatelessWidget {
  final int?    rideId;
  final String  from;
  final String  to;
  final String  driverName;
  final int     starsGiven;
  final String  fareTotal;
  final int     baseFareKhr;
  final int     distanceFeeKhr;
  final int     surgeKhr;
  final int     promoDiscountKhr;
  final double? distanceKm;
  final int?    durationMin;
  final String  paymentMethod;
  final DateTime? tripDate;

  const TripReceiptScreen({
    super.key,
    this.rideId,
    required this.from,
    required this.to,
    required this.driverName,
    required this.starsGiven,
    required this.fareTotal,
    required this.baseFareKhr,
    required this.distanceFeeKhr,
    required this.surgeKhr,
    required this.promoDiscountKhr,
    this.distanceKm,
    this.durationMin,
    required this.paymentMethod,
    this.tripDate,
  });

  String get _paymentLabel {
    switch (paymentMethod.toLowerCase()) {
      case 'cash':
        return 'Cash';
      case 'wallet':
        return 'ROTEH Wallet';
      case 'aba':
        return 'ABA Pay';
      default:
        return paymentMethod;
    }
  }

  String get _paymentIcon {
    switch (paymentMethod.toLowerCase()) {
      case 'cash':
        return '💵';
      case 'wallet':
        return '👛';
      case 'aba':
        return '🏦';
      default:
        return '💳';
    }
  }

  String get _formattedDate {
    if (tripDate == null) return '—';
    final d = tripDate!;
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
    final minute = d.minute.toString().padLeft(2, '0');
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    return '${months[d.month - 1]} ${d.day}, ${d.year}  $hour:$minute $ampm';
  }

  String get _shareText {
    final buffer = StringBuffer();
    buffer.writeln('AutoRide Trip Receipt');
    if (rideId != null) buffer.writeln('Ride #$rideId');
    buffer.writeln();
    buffer.writeln('From: $from');
    buffer.writeln('To:   $to');
    buffer.writeln('Date: $_formattedDate');
    if (distanceKm != null) buffer.writeln('Distance: ${distanceKm!.toStringAsFixed(1)} km');
    if (durationMin != null) buffer.writeln('Duration: $durationMin min');
    buffer.writeln();
    buffer.writeln('Fare Breakdown');
    buffer.writeln('Base fare:     ${AppTheme.khr(baseFareKhr)}');
    buffer.writeln('Distance fee:  ${AppTheme.khr(distanceFeeKhr)}');
    if (surgeKhr > 0) buffer.writeln('Surge:         ${AppTheme.khr(surgeKhr)}');
    if (promoDiscountKhr > 0) buffer.writeln('Promo:        -${AppTheme.khr(promoDiscountKhr)}');
    buffer.writeln('Total:         $fareTotal');
    buffer.writeln();
    buffer.writeln('Driver: $driverName');
    buffer.writeln('Your rating: ${'★' * starsGiven}${'☆' * (5 - starsGiven)}');
    buffer.writeln('Payment: $_paymentLabel');
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    _buildHeader(context),
                    const SizedBox(height: 20),
                    _buildFareCard(context),
                    const SizedBox(height: 16),
                    _buildTripDetailsCard(context),
                    const SizedBox(height: 16),
                    _buildDriverCard(context),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.success.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle_rounded,
            color: AppTheme.success,
            size: 52,
          ),
        ),
        SizedBox(height: 14),
        Text(
          'Trip Complete',
          style: TextStyle(
            color: context.appTextPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        if (rideId != null) ...[
          SizedBox(height: 4),
          Text(
            'Ride #$rideId',
            style: TextStyle(
              color: context.appTextSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFareCard(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fare Breakdown',
            style: TextStyle(
              color: context.appTextPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          if (baseFareKhr > 0)
            _FareRow(label: 'Base fare', amount: AppTheme.khr(baseFareKhr)),
          if (distanceFeeKhr > 0)
            _FareRow(label: 'Distance fee', amount: AppTheme.khr(distanceFeeKhr)),
          if (surgeKhr > 0)
            _FareRow(
              label: 'Surge fee',
              amount: AppTheme.khr(surgeKhr),
              amountColor: AppTheme.warning,
            ),
          if (promoDiscountKhr > 0)
            _FareRow(
              label: 'Promo discount',
              amount: '-${AppTheme.khr(promoDiscountKhr)}',
              amountColor: AppTheme.success,
            ),
          if (baseFareKhr > 0 || distanceFeeKhr > 0 || surgeKhr > 0 || promoDiscountKhr > 0)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(color: context.appCardBg, height: 1),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: TextStyle(
                  color: context.appTextPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                fareTotal,
                style: const TextStyle(
                  color: AppTheme.accent,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTripDetailsCard(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trip Details',
            style: TextStyle(
              color: context.appTextPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 14),
          _TripAddressRow(icon: Icons.radio_button_checked, color: AppTheme.success, label: 'Pickup', address: from),
          Padding(
            padding: EdgeInsets.only(left: 9),
            child: Container(
              width: 2,
              height: 20,
              color: context.appCardBg,
            ),
          ),
          _TripAddressRow(icon: Icons.location_on, color: AppTheme.danger, label: 'Dropoff', address: to),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: context.appCardBg, height: 1),
          ),
          _DetailRow(icon: Icons.calendar_today_outlined, label: 'Date & Time', value: _formattedDate),
          if (distanceKm != null)
            _DetailRow(
              icon: Icons.route_outlined,
              label: 'Distance',
              value: '${distanceKm!.toStringAsFixed(1)} km',
            ),
          if (durationMin != null)
            _DetailRow(
              icon: Icons.timer_outlined,
              label: 'Duration',
              value: '$durationMin min',
            ),
          _DetailRow(
            icon: Icons.payments_outlined,
            label: 'Payment',
            value: '$_paymentIcon  $_paymentLabel',
          ),
        ],
      ),
    );
  }

  Widget _buildDriverCard(BuildContext context) {
    return _Card(
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppTheme.accent.withOpacity(0.12),
            child: Icon(Icons.person_rounded, color: AppTheme.accent, size: 30),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driverName,
                  style: TextStyle(
                    color: context.appTextPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Your Driver',
                  style: TextStyle(
                    color: context.appTextSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    i < starsGiven ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: AppTheme.gold,
                    size: 20,
                  );
                }),
              ),
              SizedBox(height: 4),
              Text(
                'Your rating',
                style: TextStyle(
                  color: context.appTextSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appSurface,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.accent,
                side: const BorderSide(color: AppTheme.accent, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              onPressed: () async {
                final box = context.findRenderObject() as RenderBox?;
                await Share.share(_shareText,
                    subject: 'AutoRide Trip Receipt #$rideId',
                    sharePositionOrigin: box != null
                        ? box.localToGlobal(Offset.zero) & box.size
                        : null);
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.share_outlined, size: 18),
                  SizedBox(width: 8),
                  Text('Share Receipt'),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.of(context).popUntil((r) => r.isFirst);
              },
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Private layout helpers ────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _FareRow extends StatelessWidget {
  final String label;
  final String amount;
  final Color? amountColor;

  const _FareRow({
    required this.label,
    required this.amount,
    this.amountColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: context.appTextSecondary, fontSize: 14),
          ),
          Text(
            amount,
            style: TextStyle(
              color: amountColor ?? context.appTextPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TripAddressRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String address;

  const _TripAddressRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 20),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: context.appTextSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                address,
                style: TextStyle(
                  color: context.appTextPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: context.appTextSecondary, size: 18),
          SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(color: context.appTextSecondary, fontSize: 13),
          ),
          Spacer(),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: context.appTextPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
