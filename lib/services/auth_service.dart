import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_log.dart';
import '../l10n/app_localizations.dart';
import '../main.dart' show navigatorKey;

class AuthService {
  // Localized user-facing string, falling back to plain English when no
  // context is available yet (e.g. very early in app startup).
  static String _tr(String Function(AppLocalizations) pick, String fallback) {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return fallback;
    try {
      return pick(AppLocalizations.of(ctx));
    } catch (_) {
      return fallback;
    }
  }

  /// Returns true once a Firebase user (anonymous or otherwise) is signed
  /// in. Callers that are about to write to Firestore under rules gated on
  /// `request.auth != null` (e.g. drivers_live location updates) should
  /// await this and check the result — previously this failed silently, so
  /// a driver's live-location writes could permission-deny forever with no
  /// trace anywhere, leaving the passenger's map stuck on "Locating your
  /// driver…" indefinitely.
  static Future<bool> signInAnon() async {
    try {
      if (FirebaseAuth.instance.currentUser != null) return true;
      await FirebaseAuth.instance.signInAnonymously();
      return true;
    } catch (e, s) {
      // Anonymous auth not enabled or network error — Firestore writes will
      // fail with permission-denied until enabled in the Firebase Console.
      AppLog.e('AuthService', 'signInAnonymously failed', e, s);
      return false;
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
      verificationFailed: (e) => onFailed(e.message ??
          _tr((l) => l.phoneVerificationFailedMsg, 'Phone verification failed.')),
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
      throw Exception(
          _tr((l) => l.couldNotObtainFirebaseToken, 'Could not obtain Firebase ID token.'));
    }
    return idToken;
  }
}
