/// A package a Partner sent through ROTEH (backend: /v1/partner/packages).
class PartnerPackage {
  final int id;
  final String code;
  /// pending | confirmed | driver_assigned | picked_up | in_transit | completed
  /// | failed (not delivered, returning) | returned (back at the shop) | cancelled
  final String status;
  final String? reference;
  final String senderName;
  final String senderPhone;
  final String recipientName;
  final String recipientPhone;
  final String pickupAddress;
  final String dropoffAddress;
  final String? packageType;
  final String? details;
  final double? weight;
  final String size;
  final String serviceOption;
  final int fee;
  final int codAmount;
  final String paymentBy;
  final String paymentMethod;
  final String paymentStatus;
  /// cannot_contact | receiver_refused | wrong_address | receiver_postponed | other
  final String? failureReason;
  final Map<String, dynamic>? driver;
  final DateTime? createdAt;
  // Detail only
  final double? pickupLat, pickupLng, dropoffLat, dropoffLng;
  final String? notes;
  final String? photoUrl;
  final String? proofPhotoUrl;
  final String? qrPayload;
  final String? trackingUrl;
  final String? cancellationReason;
  final String? failureNote;
  final DateTime? failedAt;
  final DateTime? returnedAt;
  final DateTime? completedAt;
  final bool canCancel;
  final bool isLive;
  final List<PackageTimelineStep> timeline;

  const PartnerPackage({
    required this.id, required this.code, required this.status, this.reference,
    required this.senderName, required this.senderPhone,
    required this.recipientName, required this.recipientPhone,
    required this.pickupAddress, required this.dropoffAddress,
    this.packageType, this.details, this.weight, required this.size, required this.serviceOption,
    required this.fee, required this.codAmount, required this.paymentBy, required this.paymentMethod,
    required this.paymentStatus, this.failureReason, this.driver, this.createdAt,
    this.pickupLat, this.pickupLng, this.dropoffLat, this.dropoffLng, this.notes, this.photoUrl,
    this.proofPhotoUrl, this.qrPayload, this.trackingUrl, this.cancellationReason,
    this.failureNote, this.failedAt, this.returnedAt, this.completedAt,
    this.canCancel = false, this.isLive = false, this.timeline = const [],
  });

  static double? _d(dynamic v) => v == null ? null : double.tryParse(v.toString());
  static int _i(dynamic v) => v == null ? 0 : (num.tryParse(v.toString()) ?? 0).round();

  factory PartnerPackage.fromJson(Map<String, dynamic> j) => PartnerPackage(
    id:             _i(j['id']),
    code:           j['code']?.toString() ?? '#${j['id']}',
    status:         j['status']?.toString() ?? 'pending',
    reference:      j['partner_reference']?.toString(),
    senderName:     j['sender_name']?.toString() ?? '',
    senderPhone:    j['sender_phone']?.toString() ?? '',
    recipientName:  j['recipient_name']?.toString() ?? '',
    recipientPhone: j['recipient_phone']?.toString() ?? '',
    pickupAddress:  j['pickup_address']?.toString() ?? '',
    dropoffAddress: j['dropoff_address']?.toString() ?? '',
    packageType:    j['package_type']?.toString(),
    details:        j['package_details']?.toString(),
    weight:         _d(j['package_weight']),
    size:           j['package_size']?.toString() ?? 'small',
    serviceOption:  j['service_option']?.toString() ?? 'normal',
    fee:            _i(j['fee']),
    codAmount:      _i(j['package_amount']),
    paymentBy:      j['payment_by']?.toString() ?? 'sender',
    paymentMethod:  j['payment_method']?.toString() ?? 'cash',
    paymentStatus:  j['payment_status']?.toString() ?? 'unpaid',
    failureReason:  j['failure_reason']?.toString(),
    driver:         j['driver'] is Map ? Map<String, dynamic>.from(j['driver'] as Map) : null,
    createdAt:      DateTime.tryParse(j['created_at']?.toString() ?? '')?.toLocal(),
    pickupLat:      _d(j['pickup_lat']),
    pickupLng:      _d(j['pickup_lng']),
    dropoffLat:     _d(j['dropoff_lat']),
    dropoffLng:     _d(j['dropoff_lng']),
    notes:          j['notes']?.toString(),
    photoUrl:       j['photo_url']?.toString(),
    proofPhotoUrl:  j['proof_photo_url']?.toString(),
    qrPayload:      j['qr_payload']?.toString(),
    trackingUrl:    j['tracking_url']?.toString(),
    cancellationReason: j['cancellation_reason']?.toString(),
    failureNote:    j['failure_note']?.toString(),
    failedAt:       DateTime.tryParse(j['failed_at']?.toString() ?? '')?.toLocal(),
    returnedAt:     DateTime.tryParse(j['returned_at']?.toString() ?? '')?.toLocal(),
    completedAt:    DateTime.tryParse(j['completed_at']?.toString() ?? '')?.toLocal(),
    canCancel:      j['can_cancel'] == true,
    isLive:         j['is_live'] == true,
    timeline:       (j['timeline'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => PackageTimelineStep.fromJson(Map<String, dynamic>.from(e)))
        .toList(),
  );

  bool get isFinished => status == 'completed' || status == 'returned' || status == 'cancelled';
}

class PackageTimelineStep {
  final String status;
  final String? note;
  final DateTime? at;
  const PackageTimelineStep({required this.status, this.note, this.at});

  factory PackageTimelineStep.fromJson(Map<String, dynamic> j) => PackageTimelineStep(
    status: j['status']?.toString() ?? '',
    note:   j['note']?.toString(),
    at:     DateTime.tryParse(j['at']?.toString() ?? '')?.toLocal(),
  );
}

/// Partner registration state (GET /v1/partner/profile).
class PartnerStatus {
  final bool isPartner;
  /// none | pending | approved | rejected | suspended
  final String status;
  final Map<String, dynamic>? profile;
  const PartnerStatus({required this.isPartner, required this.status, this.profile});

  factory PartnerStatus.fromJson(Map<String, dynamic> j) => PartnerStatus(
    isPartner: j['is_partner'] == true,
    status:    j['status']?.toString() ?? 'none',
    profile:   j['profile'] is Map ? Map<String, dynamic>.from(j['profile'] as Map) : null,
  );

  static const none = PartnerStatus(isPartner: false, status: 'none');
  String? get rejectionReason => profile?['rejection_reason']?.toString();
  String? get businessName => profile?['business_name']?.toString();
}
