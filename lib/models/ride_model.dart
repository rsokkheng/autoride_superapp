import 'user_model.dart';
import 'vehicle_model.dart';

class RideModel {
  final int    id;
  final int    passengerId;
  final int?   driverId;
  final int?   vehicleId;
  final String pickupAddress;
  final String dropoffAddress;
  final String? scheduledAt;
  final String  status;
  final String  fare;
  final String  serviceType;
  final String? paymentMethod;
  final double? distanceKm;
  final int?    durationMin;
  final double? passengerRating;
  final String? notes;
  final String  createdAt;
  final String  updatedAt;
  // Coordinates — returned by backend after improvement (Issue #8)
  final double? pickupLat;
  final double? pickupLng;
  final double? dropoffLat;
  final double? dropoffLng;
  // Pricing
  final double? surgeMultiplier;
  // Status timestamps — returned after backend improvement (Issue #9)
  final String? acceptedAt;
  final String? startedAt;
  final String? completedAt;
  // Relations
  final UserModel?    passenger;
  final UserModel?    driver;
  final VehicleModel? vehicle;

  const RideModel({
    required this.id,
    required this.passengerId,
    this.driverId,
    this.vehicleId,
    required this.pickupAddress,
    required this.dropoffAddress,
    this.scheduledAt,
    required this.status,
    required this.fare,
    required this.serviceType,
    this.paymentMethod,
    this.distanceKm,
    this.durationMin,
    this.passengerRating,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.pickupLat,
    this.pickupLng,
    this.dropoffLat,
    this.dropoffLng,
    this.surgeMultiplier,
    this.acceptedAt,
    this.startedAt,
    this.completedAt,
    this.passenger,
    this.driver,
    this.vehicle,
  });

  static int  _toInt(dynamic v) =>
      v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;
  static int? _toIntOrNull(dynamic v) =>
      v == null ? null : (v is int ? v : int.tryParse(v.toString()));
  static double? _toDoubleOrNull(dynamic v) =>
      v == null ? null : num.tryParse(v.toString())?.toDouble();

  // Backend returns fare as KHR int (e.g. 12200).
  // Legacy USD float values ≤ 1000 are converted at 4000 KHR/USD.
  int get fareKhr {
    final n = num.tryParse(fare) ?? 0;
    return n > 1000 ? n.round() : (n * 4000).round();
  }

  factory RideModel.fromJson(Map<String, dynamic> json) {
    final rawFare = json['fare'];
    final fare    = rawFare == null ? '0' : rawFare.toString();

    return RideModel(
      id:             _toInt(json['id']),
      passengerId:    _toInt(json['passenger_id']),
      driverId:       _toIntOrNull(json['driver_id']),
      vehicleId:      _toIntOrNull(json['vehicle_id']),
      pickupAddress:  json['pickup_address']?.toString()  ?? '',
      dropoffAddress: json['dropoff_address']?.toString() ?? '',
      scheduledAt:    json['scheduled_at']?.toString(),
      status:         json['status']?.toString()          ?? 'requested',
      fare:           fare,
      serviceType:    json['service_type']?.toString()    ?? 'standard',
      paymentMethod:  json['payment_method']?.toString(),
      distanceKm:     _toDoubleOrNull(json['distance_km']),
      durationMin:    _toIntOrNull(json['duration_min']),
      passengerRating: _toDoubleOrNull(json['passenger_rating']),
      notes:          json['notes']?.toString(),
      createdAt:      json['created_at']?.toString()  ?? '',
      updatedAt:      json['updated_at']?.toString()  ?? '',
      pickupLat:      _toDoubleOrNull(json['pickup_lat']),
      pickupLng:      _toDoubleOrNull(json['pickup_lng']),
      dropoffLat:     _toDoubleOrNull(json['dropoff_lat']),
      dropoffLng:     _toDoubleOrNull(json['dropoff_lng']),
      surgeMultiplier: _toDoubleOrNull(json['surge_multiplier']),
      acceptedAt:     json['accepted_at']?.toString(),
      startedAt:      json['started_at']?.toString(),
      completedAt:    json['completed_at']?.toString(),
      passenger: json['passenger'] != null
          ? UserModel.fromJson(json['passenger'] as Map<String, dynamic>)
          : null,
      driver: json['driver'] != null
          ? UserModel.fromJson(json['driver'] as Map<String, dynamic>)
          : null,
      vehicle: json['vehicle'] != null
          ? VehicleModel.fromJson(json['vehicle'] as Map<String, dynamic>)
          : null,
    );
  }

  bool get isRequested  => status == 'requested';
  bool get isAccepted   => status == 'accepted';
  bool get isCompleted  => status == 'completed';
  bool get isCancelled  => status == 'cancelled';
  bool get isPending    => status == 'pending'     || status == 'requested';
  bool get isInProgress => status == 'in_progress' || status == 'accepted';
}
