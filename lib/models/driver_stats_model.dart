class DriverStatsModel {
  final int driverId;
  final int acceptedRides;
  final int completedRides;
  final double hoursOnline;
  final double acceptanceRate;
  final bool available;

  const DriverStatsModel({
    required this.driverId,
    required this.acceptedRides,
    required this.completedRides,
    required this.hoursOnline,
    required this.acceptanceRate,
    required this.available,
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
    );
  }
}
