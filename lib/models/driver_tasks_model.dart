import 'ride_model.dart';

class DriverTasksModel {
  final List<RideModel> rides;
  final List<dynamic> deliveries;

  const DriverTasksModel({
    required this.rides,
    required this.deliveries,
  });

  factory DriverTasksModel.fromJson(Map<String, dynamic> json) {
    return DriverTasksModel(
      rides: (json['rides'] as List<dynamic>)
          .map((e) => RideModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      deliveries: json['deliveries'] as List<dynamic>? ?? [],
    );
  }

  List<RideModel> get pendingRides    => rides.where((r) => r.isPending).toList();
  List<RideModel> get acceptedRides   => rides.where((r) => r.isAccepted).toList();
  List<RideModel> get inProgressRides => rides.where((r) => r.isInProgress).toList();
  bool get hasAnyTask => rides.isNotEmpty || deliveries.isNotEmpty;
}
