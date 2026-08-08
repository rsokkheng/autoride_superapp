import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/firestore_message.dart';
import 'auth_service.dart';

class FirestoreChatService {
  static final _db = FirebaseFirestore.instance;
  static final _storage = FirebaseStorage.instance;

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
        .where('conversation_id', isEqualTo: chatId)
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
    String?         senderAvatar,
    required String message,
  }) async {
    await AuthService.signInAnon();
    await _db.collection('messages').add({
      'conversation_id': chatId,
      'sender_id':        senderId,
      'sender_name':      senderName,
      'sender_avatar':    senderAvatar,
      'message':          message,
      'type':             'text',
      'attachment_url':   null,
      'attachment_name':  null,
      'read_at':          null,
      'created_at':       FieldValue.serverTimestamp(),
    });
  }

  // Uploads an image (from file upload or camera) to Firebase Storage,
  // then appends a message pointing at it — same shape as a text message,
  // just with `attachment_url`/`type: image` set and `message` left null.
  static Future<void> sendImageMessage({
    required String chatId,
    required int    senderId,
    required String senderName,
    String?         senderAvatar,
    required File   image,
  }) async {
    await AuthService.signInAnon();
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_$senderId.jpg';
    final ref = _storage.ref().child('chat_images/$chatId/$fileName');
    await ref.putFile(image);
    final url = await ref.getDownloadURL();
    await _db.collection('messages').add({
      'conversation_id': chatId,
      'sender_id':        senderId,
      'sender_name':      senderName,
      'sender_avatar':    senderAvatar,
      'message':          null,
      'type':             'image',
      'attachment_url':   url,
      'attachment_name':  fileName,
      'read_at':          null,
      'created_at':       FieldValue.serverTimestamp(),
    });
  }
}
