class DriverStatsModel {
  final int driverId;
  final int acceptedRides;
  final int completedRides;
  final bool available;

  const DriverStatsModel({
    required this.driverId,
    required this.acceptedRides,
    required this.completedRides,
    required this.available,
  });

  factory DriverStatsModel.fromJson(Map<String, dynamic> json) {
    return DriverStatsModel(
      driverId:       json['driver_id'] as int,
      acceptedRides:  json['accepted_rides'] as int,
      completedRides: json['completed_rides'] as int,
      available:      json['available'] as bool? ?? false,
    );
  }
}
