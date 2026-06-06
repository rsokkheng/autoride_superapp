import 'user_model.dart';
import 'vehicle_model.dart';

class DeliveryModel {
  final int id;
  final int senderId;
  final int? driverId;
  final int? vehicleId;
  final String? senderName;
  final String? recipientName;
  final String? recipientPhone;
  final String? packageSize;
  final String pickupAddress;
  final String dropoffAddress;
  final String? scheduledAt;
  final String status;
  final String packageDetails;
  final int fee;
  final String paymentBy;
  final String paymentMethod;
  final String? notes;
  final String createdAt;
  final String updatedAt;
  final UserModel? sender;
  final UserModel? driver;
  final VehicleModel? vehicle;
  final double? rating;
  final String? ratingComment;

  // ── Moving-specific fields ────────────────────────────────────────────────
  final String? serviceType;      // 'delivery' | 'moving'
  final int?    floorPickup;
  final int?    floorDropoff;
  final bool?   hasElevator;
  final bool?   needsStairsCarry;
  final bool?   heavyItems;
  final bool?   packingService;
  final int?    requiresHelpers;  // 1–4
  final String? helperType;       // 'normal' | 'heavy'
  // Vehicle type (delivery-specific)
  final String? vehicleType;      // 'motorbike' | 'small_car' | 'van' | 'truck'
  // Payment model (moving-specific)
  final String? paymentModel;     // 'customer' | 'partner' | 'split' | 'sponsored'
  final String? partnerCode;      // for 'partner' and 'split'
  final int?    splitPercent;     // customer's share 0–100, for 'split'

  const DeliveryModel({
    required this.id,
    required this.senderId,
    this.driverId,
    this.vehicleId,
    this.senderName,
    this.recipientName,
    this.recipientPhone,
    this.packageSize,
    required this.pickupAddress,
    required this.dropoffAddress,
    this.scheduledAt,
    required this.status,
    required this.packageDetails,
    required this.fee,
    this.paymentBy     = 'sender',
    this.paymentMethod = 'cash',
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.sender,
    this.driver,
    this.vehicle,
    this.rating,
    this.ratingComment,
    // delivery vehicle
    this.vehicleType,
    // moving
    this.serviceType,
    this.floorPickup,
    this.floorDropoff,
    this.hasElevator,
    this.needsStairsCarry,
    this.heavyItems,
    this.packingService,
    this.requiresHelpers,
    this.helperType,
    this.paymentModel,
    this.partnerCode,
    this.splitPercent,
  });

  bool get isMoving => serviceType == 'moving';

  factory DeliveryModel.fromJson(Map<String, dynamic> json) {
    return DeliveryModel(
      id:             json['id'] as int,
      senderId:       json['sender_id'] as int,
      driverId:       json['driver_id'] as int?,
      vehicleId:      json['vehicle_id'] as int?,
      senderName:     json['sender_name'] as String?,
      recipientName:  json['recipient_name'] as String?,
      recipientPhone: json['recipient_phone'] as String?,
      packageSize:    json['package_size'] as String?,
      pickupAddress:  json['pickup_address'] as String,
      dropoffAddress: json['dropoff_address'] as String,
      scheduledAt:    json['scheduled_at'] as String?,
      status:         json['status'] as String,
      packageDetails: json['package_details'] as String? ?? '',
      fee:            _toInt(json['fee']),
      paymentBy:      json['payment_by']?.toString()     ?? 'sender',
      paymentMethod:  json['payment_method']?.toString() ?? 'cash',
      notes:          json['notes']?.toString(),
      createdAt:      json['created_at']?.toString() ?? '',
      updatedAt:      json['updated_at']?.toString() ?? '',
      sender: json['sender'] != null
          ? UserModel.fromJson(json['sender'] as Map<String, dynamic>)
          : null,
      driver: json['driver'] != null
          ? UserModel.fromJson(json['driver'] as Map<String, dynamic>)
          : null,
      vehicle: json['vehicle'] != null
          ? VehicleModel.fromJson(json['vehicle'] as Map<String, dynamic>)
          : null,
      rating:        json['rating'] == null ? null : (json['rating'] as num).toDouble(),
      ratingComment: json['rating_comment'] as String?,
      // delivery vehicle
      vehicleType:      json['vehicle_type'] as String?,
      // moving
      serviceType:      json['service_type'] as String?,
      floorPickup:      json['floor_pickup'] as int?,
      floorDropoff:     json['floor_dropoff'] as int?,
      hasElevator:      json['has_elevator'] == null ? null : _toBool(json['has_elevator']),
      needsStairsCarry: json['needs_stairs_carry'] == null ? null : _toBool(json['needs_stairs_carry']),
      heavyItems:       json['heavy_items'] == null ? null : _toBool(json['heavy_items']),
      packingService:   json['packing_service'] == null ? null : _toBool(json['packing_service']),
      requiresHelpers:  json['requires_helpers'] as int?,
      helperType:       json['helper_type'] as String?,
      paymentModel:     json['payment_model'] as String?,
      partnerCode:      json['partner_code'] as String?,
      splitPercent:     json['split_percent'] as int?,
    );
  }

  static int _toInt(dynamic v) =>
      v == null ? 0 : v is int ? v : (v is num ? v.round() : int.tryParse(v.toString()) ?? 0);

  static bool _toBool(dynamic v) =>
      v == true || v == 1 || v.toString() == 'true' || v.toString() == '1';

  bool get isRequested  => status == 'requested';
  bool get isAccepted   => status == 'accepted';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted  => status == 'completed';
  bool get isCancelled  => status == 'cancelled';
  bool get isPending    => status == 'pending';
  bool get isRated      => rating != null;
}

// ─── Nearby driver (for GET /deliveries/nearby-drivers) ──────────────────────

class NearbyDriverModel {
  final int id;
  final String name;
  final String phone;
  final double rating;
  final int totalRatings;
  final double distanceKm;
  final double score;
  final VehicleModel? vehicle;

  const NearbyDriverModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.rating,
    required this.totalRatings,
    required this.distanceKm,
    required this.score,
    this.vehicle,
  });

  factory NearbyDriverModel.fromJson(Map<String, dynamic> json) {
    return NearbyDriverModel(
      id:           json['id'] as int,
      name:         json['name']?.toString() ?? '',
      phone:        json['phone']?.toString() ?? '',
      rating:       (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalRatings: json['total_ratings'] as int? ?? 0,
      distanceKm:   (json['distance_km'] as num?)?.toDouble() ?? 0.0,
      score:        (json['score'] as num?)?.toDouble() ?? 0.0,
      vehicle: json['vehicle'] != null
          ? VehicleModel.fromJson(json['vehicle'] as Map<String, dynamic>)
          : null,
    );
  }
}

// ─── Estimate (for POST /deliveries/estimate) ─────────────────────────────────

class DeliveryEstimateModel {
  final int estimatedFee;
  final String currency;
  final int baseFee;
  final double distanceKm;
  final int perKmRate;
  final int surcharge;

  const DeliveryEstimateModel({
    required this.estimatedFee,
    required this.currency,
    required this.baseFee,
    required this.distanceKm,
    required this.perKmRate,
    required this.surcharge,
  });

  factory DeliveryEstimateModel.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map<String, dynamic>?) ?? json;
    final breakdown = data['breakdown'] as Map<String, dynamic>? ?? {};
    return DeliveryEstimateModel(
      estimatedFee: _toInt(data['estimated_fee']),
      currency:     data['currency']?.toString() ?? 'KHR',
      baseFee:      _toInt(breakdown['base_fee']),
      distanceKm:   (breakdown['distance_km'] as num?)?.toDouble() ?? 0.0,
      perKmRate:    _toInt(breakdown['per_km_rate']),
      surcharge:    _toInt(breakdown['surcharge']),
    );
  }

  static int _toInt(dynamic v) =>
      v == null ? 0 : v is int ? v : (v is num ? v.round() : int.tryParse(v.toString()) ?? 0);
}

// ─── Tracking (for POST /deliveries/{id}/track) ───────────────────────────────

class DeliveryTrackingModel {
  final DeliveryModel delivery;
  final String status;
  final int etaMinutes;
  final int? driverId;
  final String? driverName;
  final String? driverPhone;

  const DeliveryTrackingModel({
    required this.delivery,
    required this.status,
    required this.etaMinutes,
    this.driverId,
    this.driverName,
    this.driverPhone,
  });

  factory DeliveryTrackingModel.fromJson(Map<String, dynamic> json) {
    final data     = (json['data'] as Map<String, dynamic>?) ?? json;
    final tracking = data['tracking'] as Map<String, dynamic>? ?? {};
    final driver   = tracking['driver'] as Map<String, dynamic>?;
    return DeliveryTrackingModel(
      delivery:    DeliveryModel.fromJson(data['delivery'] as Map<String, dynamic>),
      status:      tracking['status']?.toString() ?? '',
      etaMinutes:  _toInt(tracking['eta_minutes']),
      driverId:    driver == null ? null : _toInt(driver['id']),
      driverName:  driver?['name']?.toString(),
      driverPhone: driver?['phone']?.toString(),
    );
  }

  static int _toInt(dynamic v) =>
      v == null ? 0 : v is int ? v : (v is num ? v.round() : int.tryParse(v.toString()) ?? 0);
}
