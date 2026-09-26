import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/firestore_message.dart';
import 'api_service.dart';
import 'auth_service.dart';

class FirestoreChatService {
  static final _db = FirebaseFirestore.instance;
  static final _storage = FirebaseStorage.instance;

  /// Messages loaded per chat. Ride chats are short-lived, so this is a cap
  /// on read cost rather than something users will scroll past.
  static const int _messageLimit = 100;

  // chatId → [driverId, passengerId], stamped onto every message so the
  // security rules (and the read query) can check membership per message.
  static final Map<String, List<int>> _participants = {};

  // Finds the existing chat doc for a ride, or creates one.
  // Returns the Firestore chat document ID.
  static Future<String> getOrCreateChat({
    required String rideId,
    required int    driverId,
    required int    passengerId,
  }) async {
    await AuthService.ensureSignedIn();
    final myId = await ApiService.getUserId();

    // Rules only allow reading chats you're in, so the query must say so
    // too — Firestore rejects a query that *could* return someone else's doc.
    final myField = myId == driverId ? 'driver_id' : 'passenger_id';
    final query = await _db
        .collection('chats')
        .where('ride_id', isEqualTo: rideId)
        .where(myField, isEqualTo: myId)
        .limit(1)
        .get();

    final String chatId;
    if (query.docs.isNotEmpty) {
      chatId = query.docs.first.id;
    } else {
      final ref = await _db.collection('chats').add({
        'ride_id':      rideId,
        'driver_id':    driverId,
        'passenger_id': passengerId,
        'status':       'active',
        'created_at':   FieldValue.serverTimestamp(),
      });
      chatId = ref.id;
    }
    _participants[chatId] = [driverId, passengerId];
    return chatId;
  }

  // Real-time stream of the latest messages for a chat, oldest → newest.
  // Needs the composite index in firestore.indexes.json.
  static Stream<List<FirestoreMessage>> messagesStream(String chatId) async* {
    await AuthService.ensureSignedIn();
    final myId = await ApiService.getUserId();
    yield* _db
        .collection('messages')
        .where('conversation_id', isEqualTo: chatId)
        .where('participants', arrayContains: myId)
        .orderBy('created_at')
        .limitToLast(_messageLimit)
        .snapshots()
        .map((snap) => snap.docs.map((d) => FirestoreMessage.fromDoc(d)).toList());
  }

  // Append a message to the messages collection.
  static Future<void> sendMessage({
    required String chatId,
    required int    senderId,
    required String senderName,
    String?         senderAvatar,
    required String message,
  }) async {
    await AuthService.ensureSignedIn();
    await _db.collection('messages').add({
      'conversation_id': chatId,
      'participants':     await _participantsOf(chatId),
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
    await AuthService.ensureSignedIn();
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_$senderId.jpg';
    final ref = _storage.ref().child('chat_images/$chatId/$fileName');
    // Storage rules only accept image/* uploads.
    await ref.putFile(image, SettableMetadata(contentType: 'image/jpeg'));
    final url = await ref.getDownloadURL();
    await _db.collection('messages').add({
      'conversation_id': chatId,
      'participants':     await _participantsOf(chatId),
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

  static Future<List<int>> _participantsOf(String chatId) async {
    final cached = _participants[chatId];
    if (cached != null) return cached;
    final chat = (await _db.collection('chats').doc(chatId).get()).data() ?? const {};
    final ids = [
      (chat['driver_id'] as num?)?.toInt() ?? 0,
      (chat['passenger_id'] as num?)?.toInt() ?? 0,
    ];
    return _participants[chatId] = ids;
  }
}
