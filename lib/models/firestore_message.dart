import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreMessage {
  final String id;
  final int senderId;
  final String senderName;
  final String? senderAvatar;
  final String message;
  final String type;
  final String? attachmentUrl;
  final String? attachmentName;
  final DateTime? readAt;
  final DateTime? timestamp;

  const FirestoreMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.message,
    this.type = 'text',
    this.attachmentUrl,
    this.attachmentName,
    this.readAt,
    this.timestamp,
  });

  bool get isImage => type == 'image' && attachmentUrl != null && attachmentUrl!.isNotEmpty;

  factory FirestoreMessage.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final rawId = data['sender_id'];
    return FirestoreMessage(
      id:             doc.id,
      senderId:       rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '') ?? 0,
      senderName:     data['sender_name']     as String? ?? '',
      senderAvatar:   data['sender_avatar']   as String?,
      message:        data['message']         as String? ?? '',
      type:           data['type']            as String? ?? 'text',
      attachmentUrl:  data['attachment_url']  as String?,
      attachmentName: data['attachment_name'] as String?,
      readAt:         (data['read_at']    as Timestamp?)?.toDate(),
      timestamp:      (data['created_at'] as Timestamp?)?.toDate(),
    );
  }

  String get timeLabel {
    if (timestamp == null) return '';
    final t = timestamp!;
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }
}
