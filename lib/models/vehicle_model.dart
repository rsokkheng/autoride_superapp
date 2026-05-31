import 'user_model.dart';

class VehicleModel {
  final int id;
  final int userId;
  final String licensePlate;
  final String make;
  final String model;
  final int year;
  final String type;
  final String status;
  final int capacity;
  final String details;
  final UserModel? driver;

  const VehicleModel({
    required this.id,
    required this.userId,
    required this.licensePlate,
    required this.make,
    required this.model,
    required this.year,
    required this.type,
    required this.status,
    required this.capacity,
    required this.details,
    this.driver,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id:           json['id'] as int,
      userId:       json['user_id'] as int,
      licensePlate: json['license_plate'] as String,
      make:         json['make'] as String,
      model:        json['model'] as String,
      year:         json['year'] as int,
      type:         json['type'] as String,
      status:       json['status'] as String,
      capacity:     json['capacity'] as int,
      details:      json['details'] as String? ?? '',
      driver: json['driver'] != null
          ? UserModel.fromJson(json['driver'] as Map<String, dynamic>)
          : null,
    );
  }

  String get displayName => '$year $make $model';
  bool get isActive => status == 'active';
}
