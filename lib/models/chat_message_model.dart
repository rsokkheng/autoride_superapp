import 'user_model.dart';

class ChatMessageModel {
  final int id;
  final int conversationId;
  final int senderId;
  final String message;
  final String? readAt;
  final String createdAt;
  final UserModel? sender;

  const ChatMessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.message,
    this.readAt,
    required this.createdAt,
    this.sender,
  });

  static int _i(dynamic v) => v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id:             _i(json['id']),
      conversationId: _i(json['conversation_id']),
      senderId:       _i(json['sender_id']),
      message:        json['message'] as String? ?? '',
      readAt:         json['read_at'] as String?,
      createdAt:      json['created_at'] as String? ?? '',
      sender:         json['sender'] != null
          ? UserModel.fromJson(json['sender'] as Map<String, dynamic>)
          : null,
    );
  }

  bool get isRead => readAt != null;

  String get timeLabel {
    if (createdAt.length < 16) return '';
    return createdAt.substring(11, 16);
  }
}
