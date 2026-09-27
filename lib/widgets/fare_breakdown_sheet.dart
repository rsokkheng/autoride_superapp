import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/api_service.dart' show FareInfo;
import '../theme/app_theme.dart';

/// Bottom sheet explaining how a fare quote adds up — base, distance, time,
/// and any night / weekend / holiday / surge surcharge — so a higher-than-usual
/// price never comes without a reason.
Future<void> showFareBreakdownSheet(
  BuildContext context, {
  required FareInfo fare,
  required String title,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: context.appSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _FareBreakdown(fare: fare, title: title),
  );
}

/// One-line summary of the surcharges in effect, e.g. "🌙 Night · ⚡ 1.5×",
/// or null when the fare is the normal price.
String? fareSurchargeSummary(BuildContext context, FareInfo fare) {
  final l = AppLocalizations.of(context);
  final parts = <String>[
    if ((fare.breakdown['night_surcharge'] ?? 0) > 0) '🌙 ${l.nightSurcharge}',
    if ((fare.breakdown['weekend_surcharge'] ?? 0) > 0) '📅 ${l.weekendSurcharge}',
    if ((fare.breakdown['holiday_surcharge'] ?? 0) > 0) '🎉 ${fare.holidayLabel ?? l.holidaySurcharge}',
    if (fare.surgeMultiplier > 1.0) '⚡ ${fare.surgeMultiplier.toStringAsFixed(1)}×',
  ];
  return parts.isEmpty ? null : parts.join(' · ');
}

class _FareBreakdown extends StatelessWidget {
  final FareInfo fare;
  final String title;
  const _FareBreakdown({required this.fare, required this.title});

  @override
  Widget build(BuildContext context) {
    final l  = AppLocalizations.of(context);
    final bd = fare.breakdown;
    int v(String key) => bd[key] ?? 0;

    final surge = fare.surgeMultiplier > 1.0 ? v('surge_amount') : 0;
    final lines = <(String, int)>[
      (l.baseFare, v('base_fare')),
      (l.bookingFee, v('booking_fee')),
      (l.distanceFare, v('distance_fare')),
      (l.timeFare, v('time_fare')),
      (l.nightSurcharge, v('night_surcharge')),
      (l.weekendSurcharge, v('weekend_surcharge')),
      (fare.holidayLabel != null ? '${l.holidaySurcharge} (${fare.holidayLabel})' : l.holidaySurcharge,
          v('holiday_surcharge')),
      ('${l.surgeFee} (${fare.surgeMultiplier.toStringAsFixed(1)}×)', surge),
    ].where((e) => e.$2 > 0).toList();

    // Whatever the components don't explain: rounding up to 100 ៛, the
    // minimum fare, or (when there's no surge) the backend's surge_amount
    // bucket, which carries both.
    final adjustment = fare.total - lines.fold<int>(0, (sum, e) => sum + e.$2);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: context.appTextSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('${l.fareBreakdown} · $title',
              style: TextStyle(color: context.appTextPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          for (final (label, amount) in lines) _row(context, label, amount),
          if (adjustment != 0) _row(context, l.fareRoundingAdjustment, adjustment),
          Divider(height: 24, color: context.appTextSecondary.withValues(alpha: 0.2)),
          _row(context, l.totalFare, fare.total, bold: true),
        ]),
      ),
    );
  }

  Widget _row(BuildContext context, String label, int amount, {bool bold = false}) {
    final style = TextStyle(
      color: bold ? context.appTextPrimary : context.appTextSecondary,
      fontSize: bold ? 16 : 14,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Expanded(child: Text(label, style: style)),
        Text('${amount < 0 ? '−' : ''}${AppTheme.khr(amount.abs())}',
            style: style.copyWith(color: bold ? AppTheme.accent : context.appTextPrimary)),
      ]),
    );
  }
}
