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

  // Starts Firebase's real SMS OTP flow. On some Android devices Firebase
  // can auto-detect the incoming SMS and skip straight to a credential
  // (verificationCompleted) without the user ever typing a code — that
  // case is surfaced via [onAutoVerified] so the caller can sign in and
  // skip the code-entry screen entirely.
  static Future<void> sendPhoneOtp({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String message) onFailed,
    required void Function(PhoneAuthCredential credential) onAutoVerified,
  }) {
    return FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: onAutoVerified,
      verificationFailed: (e) =>
          onFailed(e.message ?? 'Phone verification failed.'),
      codeSent: (verificationId, resendToken) => onCodeSent(verificationId),
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  // Confirms the user-entered SMS code and returns the Firebase ID token
  // to hand off to the backend (POST /auth/phone/verify).
  static Future<String> confirmPhoneCode({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
        verificationId: verificationId, smsCode: smsCode);
    return signInWithPhoneCredential(credential);
  }

  static Future<String> signInWithPhoneCredential(
      PhoneAuthCredential credential) async {
    final result = await FirebaseAuth.instance.signInWithCredential(credential);
    final idToken = await result.user?.getIdToken();
    if (idToken == null) {
      throw Exception('Could not obtain Firebase ID token.');
    }
    return idToken;
  }
}
