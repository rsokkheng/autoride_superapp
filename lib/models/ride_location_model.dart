class RideLocationModel {
  final int? id;
  final int rideId;
  final double latitude;
  final double longitude;
  final double? speed;
  final double? heading;
  final String? status;
  final String? createdAt;

  const RideLocationModel({
    this.id,
    required this.rideId,
    required this.latitude,
    required this.longitude,
    this.speed,
    this.heading,
    this.status,
    this.createdAt,
  });

  factory RideLocationModel.fromJson(Map<String, dynamic> json) {
    return RideLocationModel(
      id:        json['id'] as int?,
      rideId:    json['ride_id'] as int? ?? 0,
      latitude:  (json['latitude']  as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      speed:     (json['speed']   as num?)?.toDouble(),
      heading:   (json['heading'] as num?)?.toDouble(),
      status:    json['status']     as String?,
      createdAt: json['created_at'] as String?,
    );
  }
}
