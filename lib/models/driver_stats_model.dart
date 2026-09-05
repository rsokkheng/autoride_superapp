class PeakHourBonus {
  final bool active;
  final String windowStart;
  final String windowEnd;
  final int bonusPerTripKhr;
  final int tripsToday;
  final int tripTarget;
  final int earnedTodayKhr;

  const PeakHourBonus({
    required this.active,
    required this.windowStart,
    required this.windowEnd,
    required this.bonusPerTripKhr,
    required this.tripsToday,
    required this.tripTarget,
    required this.earnedTodayKhr,
  });

  factory PeakHourBonus.fromJson(Map<String, dynamic>? json) {
    final j = json ?? const {};
    return PeakHourBonus(
      active:          j['active'] as bool? ?? false,
      windowStart:     j['window_start'] as String? ?? '',
      windowEnd:       j['window_end'] as String? ?? '',
      bonusPerTripKhr: (j['bonus_per_trip_khr'] as num?)?.toInt() ?? 0,
      tripsToday:      (j['trips_today'] as num?)?.toInt() ?? 0,
      tripTarget:      (j['trip_target'] as num?)?.toInt() ?? 0,
      earnedTodayKhr:  (j['earned_today_khr'] as num?)?.toInt() ?? 0,
    );
  }

  double get progress => tripTarget > 0 ? (tripsToday / tripTarget).clamp(0.0, 1.0) : 0.0;
}

class RatingStreak {
  final int current;
  final int target;
  final int bonusKhr;
  final int remaining;

  const RatingStreak({
    required this.current,
    required this.target,
    required this.bonusKhr,
    required this.remaining,
  });

  factory RatingStreak.fromJson(Map<String, dynamic>? json) {
    final j = json ?? const {};
    return RatingStreak(
      current:   (j['current'] as num?)?.toInt() ?? 0,
      target:    (j['target'] as num?)?.toInt() ?? 0,
      bonusKhr:  (j['bonus_khr'] as num?)?.toInt() ?? 0,
      remaining: (j['remaining'] as num?)?.toInt() ?? 0,
    );
  }
}

class DriverStatsModel {
  final int driverId;
  final int acceptedRides;
  final int completedRides;
  final double hoursOnline;
  final double acceptanceRate;
  final bool available;
  final PeakHourBonus peakHour;
  final RatingStreak ratingStreak;

  const DriverStatsModel({
    required this.driverId,
    required this.acceptedRides,
    required this.completedRides,
    required this.hoursOnline,
    required this.acceptanceRate,
    required this.available,
    required this.peakHour,
    required this.ratingStreak,
  });

  factory DriverStatsModel.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map<String, dynamic>?) ?? json;
    return DriverStatsModel(
      driverId:       data['driver_id'] as int? ?? 0,
      acceptedRides:  data['accepted_rides'] as int? ?? 0,
      completedRides: data['completed_rides'] as int? ?? 0,
      hoursOnline:    (data['hours_online'] as num?)?.toDouble() ?? 0.0,
      acceptanceRate: (data['acceptance_rate'] as num?)?.toDouble() ?? 0.0,
      available:      data['available'] as bool? ?? false,
      peakHour:       PeakHourBonus.fromJson(data['peak_hour'] as Map<String, dynamic>?),
      ratingStreak:   RatingStreak.fromJson(data['rating_streak'] as Map<String, dynamic>?),
    );
  }
}
