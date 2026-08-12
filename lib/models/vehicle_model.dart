import 'user_model.dart';

class VehicleModel {
  final int    id;
  final int    userId;
  final String licensePlate;
  final String make;
  final String model;
  final int    year;
  final String type;
  final String status;
  final int    capacity;
  final String details;
  final String color;
  final String vehicleUrl;
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
    this.color = '',
    this.vehicleUrl = '',
    this.driver,
  });

  static int    _int(dynamic v)    => v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;
  static String _str(dynamic v)    => v?.toString() ?? '';

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id:           _int(json['id']),
      userId:       _int(json['user_id']),
      // Backend sometimes sends the bare `plate` key (e.g. the ride-accept
      // response's driver_info.vehicle) instead of `license_plate`.
      licensePlate: _str(json['license_plate'] ?? json['plate']),
      make:         _str(json['make']),
      model:        _str(json['model']),
      year:         _int(json['year']),
      type:         _str(json['type']),
      status:       _str(json['status']),
      capacity:     _int(json['capacity']),
      details:      _str(json['details']),
      color:        _str(json['color']),
      vehicleUrl:   _str(json['vehicle_url']),
      driver: json['driver'] != null
          ? UserModel.fromJson(json['driver'] as Map<String, dynamic>)
          : null,
    );
  }

  String get displayName => '$year $make $model';
  bool   get isActive    => status == 'active';
}
