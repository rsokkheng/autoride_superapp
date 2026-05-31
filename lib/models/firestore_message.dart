import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreMessage {
  final String id;
  final int senderId;
  final String senderName;
  final String message;
  final DateTime? timestamp;

  const FirestoreMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.message,
    this.timestamp,
  });

  factory FirestoreMessage.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final rawId = data['sender_id'];
    return FirestoreMessage(
      id:         doc.id,
      senderId:   rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '') ?? 0,
      senderName: data['sender_name'] as String? ?? '',
      message:    data['message']     as String? ?? '',
      timestamp:  (data['timestamp']  as Timestamp?)?.toDate(),
    );
  }

  String get timeLabel {
    if (timestamp == null) return '';
    final t = timestamp!;
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }
}
