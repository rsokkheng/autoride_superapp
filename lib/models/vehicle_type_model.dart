import 'package:flutter/material.dart';

class VehiclePricing {
  final int base;
  final int perKm;
  final int perMin;
  final int bookingFee;
  final int minimum;

  const VehiclePricing({
    required this.base,
    required this.perKm,
    required this.perMin,
    required this.bookingFee,
    required this.minimum,
  });

  factory VehiclePricing.fromJson(Map<String, dynamic> json) {
    int i(dynamic v) => v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;
    return VehiclePricing(
      base:       i(json['base']),
      perKm:      i(json['per_km']),
      perMin:     i(json['per_min']),
      bookingFee: i(json['booking_fee']),
      minimum:    i(json['minimum']),
    );
  }
}

class VehicleTypeModel {
  final int    id;
  final String serviceType;
  final String label;
  final String iconName; // FontAwesome name from backend, e.g. 'fa-motorcycle'
  final int    capacity;
  final VehiclePricing pricing;

  const VehicleTypeModel({
    required this.id,
    required this.serviceType,
    required this.label,
    required this.iconName,
    required this.capacity,
    required this.pricing,
  });

  factory VehicleTypeModel.fromJson(Map<String, dynamic> json) {
    return VehicleTypeModel(
      id:          json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      serviceType: json['service_type'] as String? ?? '',
      label:       json['label'] as String? ?? '',
      iconName:    json['icon'] as String? ?? '',
      capacity:    json['capacity'] is int ? json['capacity'] as int : int.tryParse(json['capacity']?.toString() ?? '') ?? 1,
      pricing:     VehiclePricing.fromJson((json['pricing'] as Map<String, dynamic>?) ?? const {}),
    );
  }

  // Maps the backend's FontAwesome icon name onto a bundled Material icon —
  // this app doesn't ship FontAwesome, so every 'fa-*' name gets translated.
  IconData get icon {
    switch (iconName) {
      case 'fa-motorcycle':    return Icons.two_wheeler;
      case 'fa-taxi':          return Icons.electric_rickshaw;
      case 'fa-car':           return Icons.directions_car;
      case 'fa-car-side':      return Icons.local_taxi;
      case 'fa-people-group':  return Icons.groups;
      case 'fa-van-shuttle':   return Icons.airport_shuttle;
      default:                 return Icons.directions_car;
    }
  }

  String get seatsLabel => '$capacity seat${capacity == 1 ? '' : 's'}';
}
