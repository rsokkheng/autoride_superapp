import 'user_model.dart';

class ConversationModel {
  final int id;
  final int passengerId;
  final int driverId;
  final String topic;
  final String status;
  final String createdAt;
  final String updatedAt;
  final UserModel? passenger;
  final UserModel? driver;

  const ConversationModel({
    required this.id,
    required this.passengerId,
    required this.driverId,
    required this.topic,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.passenger,
    this.driver,
  });

  static int _i(dynamic v) => v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id:          _i(json['id']),
      passengerId: _i(json['passenger_id']),
      driverId:    _i(json['driver_id']),
      topic:       json['topic'] as String? ?? '',
      status:      json['status'] as String? ?? 'active',
      createdAt:   json['created_at'] as String? ?? '',
      updatedAt:   json['updated_at'] as String? ?? '',
      passenger:   json['passenger'] != null
          ? UserModel.fromJson(json['passenger'] as Map<String, dynamic>)
          : null,
      driver:      json['driver'] != null
          ? UserModel.fromJson(json['driver'] as Map<String, dynamic>)
          : null,
    );
  }
}
