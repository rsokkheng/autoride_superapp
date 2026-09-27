import 'package:autoride_superapp/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> quote({
    double surge = 1.0,
    int night = 0,
    int weekend = 0,
    Map<String, dynamic>? holiday,
    int surgeAmount = 0,
  }) => {
        'total': 12200,
        'minimum_fare': 5000,
        'surge_active': surge > 1.0,
        'surge_multiplier': surge,
        'night_rate': night > 0,
        'weekend_rate': weekend > 0,
        'holiday': holiday,
        'breakdown': {
          'booking_fee': 1000, 'base_fare': 3000, 'distance_fare': 6000, 'time_fare': 0,
          'night_surcharge': night, 'weekend_surcharge': weekend, 'holiday_surcharge': 0,
          'surge_amount': surgeAmount,
        },
      };

  test('parses surcharges and holiday label from an estimate', () {
    final f = FareInfo.fromJson(quote(surge: 1.5, weekend: 900, holiday: {'label': 'Khmer New Year', 'rate': 0.3}));
    expect(f.total, 12200);
    expect(f.surgeMultiplier, 1.5);
    expect(f.weekendRate, isTrue);
    expect(f.holidayLabel, 'Khmer New Year');
    expect(f.breakdown['weekend_surcharge'], 900);
    expect(f.hasSurcharge, isTrue);
  });

  test('rounding in surge_amount alone is not a surcharge', () {
    // Backend surge_amount = total − subtotal, so rounding up to 100 ៛ lands
    // there even with no surge at all.
    final f = FareInfo.fromJson(quote(surgeAmount: 50));
    expect(f.surgeMultiplier, 1.0);
    expect(f.hasSurcharge, isFalse);
  });

  test('older backend without the new fields still parses', () {
    final f = FareInfo.fromJson({'total': 8000, 'minimum_fare': 5000, 'breakdown': <String, dynamic>{}});
    expect(f.surgeMultiplier, 1.0);
    expect(f.weekendRate, isFalse);
    expect(f.holidayLabel, isNull);
    expect(f.hasSurcharge, isFalse);
  });
}
