import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/firestore_message.dart';
import 'auth_service.dart';

class FirestoreChatService {
  static final _db = FirebaseFirestore.instance;

  // Finds the existing chat doc for a ride, or creates one.
  // Returns the Firestore chat document ID.
  static Future<String> getOrCreateChat({
    required String rideId,
    required int    driverId,
    required int    passengerId,
  }) async {
    await AuthService.signInAnon();

    final query = await _db
        .collection('chats')
        .where('ride_id', isEqualTo: rideId)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) return query.docs.first.id;

    final ref = await _db.collection('chats').add({
      'ride_id':      rideId,
      'driver_id':    driverId,
      'passenger_id': passengerId,
      'status':       'active',
      'created_at':   FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  // Real-time stream of messages for a chat document, ordered oldest → newest.
  // Sorting is done client-side to avoid needing a composite Firestore index.
  static Stream<List<FirestoreMessage>> messagesStream(String chatId) {
    return _db
        .collection('messages')
        .where('chat_id', isEqualTo: chatId)
        .snapshots()
        .map((snap) {
          final msgs =
              snap.docs.map((d) => FirestoreMessage.fromDoc(d)).toList();
          msgs.sort((a, b) =>
              (a.timestamp ?? DateTime(0))
                  .compareTo(b.timestamp ?? DateTime(0)));
          return msgs;
        });
  }

  // Append a message to the messages collection.
  static Future<void> sendMessage({
    required String chatId,
    required int    senderId,
    required String senderName,
    required String message,
  }) async {
    await AuthService.signInAnon();
    await _db.collection('messages').add({
      'chat_id':     chatId,
      'sender_id':   senderId,
      'sender_name': senderName,
      'message':     message,
      'timestamp':   FieldValue.serverTimestamp(),
      'read_at':     null,
    });
  }
}
