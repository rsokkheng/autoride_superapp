import 'package:flutter/material.dart';
import 'package:autoride_superapp/l10n/app_localizations.dart';
import 'package:autoride_superapp/theme/app_theme.dart';
import 'package:share_plus/share_plus.dart';

class TripReceiptScreen extends StatelessWidget {
  final int?    rideId;
  final String  from;
  final String  to;
  /// Intermediate stop addresses, in order.
  final List<String> stops;
  final String  driverName;
  final int     starsGiven;
  final String  fareTotal;
  final int     baseFareKhr;
  final int     distanceFeeKhr;
  final int     surgeKhr;
  final int     promoDiscountKhr;
  final String? promoCode;
  final double? distanceKm;
  final int?    durationMin;
  final String  paymentMethod;
  final DateTime? tripDate;

  const TripReceiptScreen({
    super.key,
    this.rideId,
    required this.from,
    required this.to,
    this.stops = const [],
    required this.driverName,
    required this.starsGiven,
    required this.fareTotal,
    required this.baseFareKhr,
    required this.distanceFeeKhr,
    required this.surgeKhr,
    required this.promoDiscountKhr,
    this.promoCode,
    this.distanceKm,
    this.durationMin,
    required this.paymentMethod,
    this.tripDate,
  });

  String _paymentLabel(AppLocalizations l) {
    switch (paymentMethod.toLowerCase()) {
      case 'cash':
        return l.cash;
      case 'wallet':
        return l.rotehWallet;
      case 'aba':
        return 'ABA Pay'; // brand name — not translated
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

  static const _kMonths = {
    'en': ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
           'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
    'km': ['មករា', 'កុម្ភៈ', 'មីនា', 'មេសា', 'ឧសភា', 'មិថុនា',
           'កក្កដា', 'សីហា', 'កញ្ញា', 'តុលា', 'វិច្ឆិកា', 'ធ្នូ'],
    'zh': ['1月', '2月', '3月', '4月', '5月', '6月',
           '7月', '8月', '9月', '10月', '11月', '12月'],
  };

  String _formattedDate(Locale locale) {
    if (tripDate == null) return '—';
    final d = tripDate!;
    final months = _kMonths[locale.languageCode] ?? _kMonths['en']!;
    final hour = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
    final minute = d.minute.toString().padLeft(2, '0');
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    return '${months[d.month - 1]} ${d.day}, ${d.year}  $hour:$minute $ampm';
  }

  String _shareText(AppLocalizations l, Locale locale) {
    final buffer = StringBuffer();
    buffer.writeln('${l.appName} ${l.tripReceipt}');
    if (rideId != null) buffer.writeln('${l.ride} #$rideId');
    buffer.writeln();
    buffer.writeln('${l.from}: $from');
    for (int i = 0; i < stops.length; i++) {
      buffer.writeln('${l.stop} ${i + 1}: ${stops[i]}');
    }
    buffer.writeln('${l.to}: $to');
    buffer.writeln('${l.date}: ${_formattedDate(locale)}');
    if (distanceKm != null) {
      buffer.writeln('${l.distance}: ${distanceKm!.toStringAsFixed(1)} km');
    }
    if (durationMin != null) {
      buffer.writeln('${l.duration}: $durationMin ${l.minShort}');
    }
    buffer.writeln();
    buffer.writeln(l.fareBreakdown);
    buffer.writeln('${l.baseFare}: ${AppTheme.khr(baseFareKhr)}');
    buffer.writeln('${l.distanceFee}: ${AppTheme.khr(distanceFeeKhr)}');
    if (surgeKhr > 0) buffer.writeln('${l.surge}: ${AppTheme.khr(surgeKhr)}');
    if (promoDiscountKhr > 0) {
      buffer.writeln('${l.promo}: -${AppTheme.khr(promoDiscountKhr)}');
    }
    buffer.writeln('${l.total}: $fareTotal');
    buffer.writeln();
    buffer.writeln('${l.driver}: $driverName');
    buffer.writeln(
        '${l.yourRating}: ${'★' * starsGiven}${'☆' * (5 - starsGiven)}');
    buffer.writeln('${l.payment}: ${_paymentLabel(l)}');
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
          AppLocalizations.of(context).tripComplete,
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
            '${AppLocalizations.of(context).ride} #$rideId',
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
            AppLocalizations.of(context).fareBreakdown,
            style: TextStyle(
              color: context.appTextPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          if (baseFareKhr > 0)
            _FareRow(
                label: AppLocalizations.of(context).baseFare,
                amount: AppTheme.khr(baseFareKhr)),
          if (distanceFeeKhr > 0)
            _FareRow(
                label: AppLocalizations.of(context).distanceFee,
                amount: AppTheme.khr(distanceFeeKhr)),
          if (surgeKhr > 0)
            _FareRow(
              label: AppLocalizations.of(context).surgeFee,
              amount: AppTheme.khr(surgeKhr),
              amountColor: AppTheme.warning,
            ),
          if (promoDiscountKhr > 0)
            _FareRow(
              label: promoCode != null && promoCode!.isNotEmpty
                  ? '${AppLocalizations.of(context).promoDiscount} ($promoCode)'
                  : AppLocalizations.of(context).promoDiscount,
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
                AppLocalizations.of(context).total,
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
            AppLocalizations.of(context).tripDetails,
            style: TextStyle(
              color: context.appTextPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 14),
          _TripAddressRow(icon: Icons.radio_button_checked, color: AppTheme.success, label: AppLocalizations.of(context).pickup, address: from),
          for (int i = 0; i < stops.length; i++) ...[
            Padding(
              padding: EdgeInsets.only(left: 9),
              child: Container(
                width: 2,
                height: 20,
                color: context.appCardBg,
              ),
            ),
            _TripAddressRow(
              icon: Icons.location_on,
              color: AppTheme.warning,
              label: '${AppLocalizations.of(context).stop} ${i + 1}',
              address: stops[i],
            ),
          ],
          Padding(
            padding: EdgeInsets.only(left: 9),
            child: Container(
              width: 2,
              height: 20,
              color: context.appCardBg,
            ),
          ),
          _TripAddressRow(icon: Icons.location_on, color: AppTheme.danger, label: AppLocalizations.of(context).dropoff, address: to),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: context.appCardBg, height: 1),
          ),
          _DetailRow(
              icon: Icons.calendar_today_outlined,
              label: AppLocalizations.of(context).dateAndTime,
              value: _formattedDate(Localizations.localeOf(context))),
          if (distanceKm != null)
            _DetailRow(
              icon: Icons.route_outlined,
              label: AppLocalizations.of(context).distance,
              value: '${distanceKm!.toStringAsFixed(1)} km',
            ),
          if (durationMin != null)
            _DetailRow(
              icon: Icons.timer_outlined,
              label: AppLocalizations.of(context).duration,
              value: '$durationMin ${AppLocalizations.of(context).minShort}',
            ),
          _DetailRow(
            icon: Icons.payments_outlined,
            label: AppLocalizations.of(context).payment,
            value: '$_paymentIcon  ${_paymentLabel(AppLocalizations.of(context))}',
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
                  AppLocalizations.of(context).yourDriver,
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
                AppLocalizations.of(context).yourRating,
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
                final l = AppLocalizations.of(context);
                await Share.share(
                    _shareText(l, Localizations.localeOf(context)),
                    subject: '${l.appName} ${l.tripReceipt} #$rideId',
                    sharePositionOrigin: box != null
                        ? box.localToGlobal(Offset.zero) & box.size
                        : null);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.share_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text(AppLocalizations.of(context).shareReceipt),
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
              child: Text(AppLocalizations.of(context).done),
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
