import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static Future<void> signInAnon() async {
    try {
      if (FirebaseAuth.instance.currentUser != null) return;
      await FirebaseAuth.instance.signInAnonymously();
    } catch (e) {
      // Anonymous auth not enabled or network error — Firestore writes will
      // fail with permission-denied until enabled in the Firebase Console.
    }
  }
}
