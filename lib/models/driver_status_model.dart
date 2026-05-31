import 'user_model.dart';
import 'ride_model.dart';

class DriverStatusModel {
  final UserModel driver;
  final List<RideModel> activeRides;
  final List<dynamic> activeDeliveries;

  const DriverStatusModel({
    required this.driver,
    required this.activeRides,
    required this.activeDeliveries,
  });

  factory DriverStatusModel.fromJson(Map<String, dynamic> json) {
    return DriverStatusModel(
      driver: UserModel.fromJson(json['driver'] as Map<String, dynamic>),
      activeRides: (json['active_rides'] as List<dynamic>)
          .map((e) => RideModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      activeDeliveries: json['active_deliveries'] as List<dynamic>? ?? [],
    );
  }

  bool get isAvailable  => driver.available;
  bool get hasActiveWork => activeRides.isNotEmpty || activeDeliveries.isNotEmpty;
}
