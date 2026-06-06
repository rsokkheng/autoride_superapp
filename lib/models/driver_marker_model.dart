import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Snapshot of a single driver's state used to render a map marker.
class DriverMarkerModel {
  final String driverId;
  final LatLng position;
  final double heading;      // degrees 0–360, north = 0
  final String vehicleType;  // 'motorbike' | 'car' | 'van' | 'truck'
  final String driverName;
  final String plate;

  const DriverMarkerModel({
    required this.driverId,
    required this.position,
    this.heading     = 0.0,
    this.vehicleType = 'motorbike',
    this.driverName  = '',
    this.plate       = '',
  });

  DriverMarkerModel copyWith({
    LatLng? position,
    double? heading,
    String? vehicleType,
    String? driverName,
    String? plate,
  }) {
    return DriverMarkerModel(
      driverId:    driverId,
      position:    position    ?? this.position,
      heading:     heading     ?? this.heading,
      vehicleType: vehicleType ?? this.vehicleType,
      driverName:  driverName  ?? this.driverName,
      plate:       plate       ?? this.plate,
    );
  }

  static String normalise(String raw) {
    final s = raw.toLowerCase().trim();
    if (s.contains('motorbike') || s.contains('moto') || s.contains('bike')) {
      return 'motorbike';
    }
    if (s.contains('truck')) return 'truck';
    if (s.contains('van'))   return 'van';
    if (s.contains('car'))   return 'car';
    return 'motorbike'; // safest default for Cambodian ride-hailing
  }
}
