import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_log.dart';
import 'api_service.dart';
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

  static Future<bool>? _signingIn;

  /// Returns true once Firebase is signed in as the *current Laravel user*
  /// (uid `user_{id}`, via a backend-issued custom token). Firestore/Storage
  /// rules authorize on that token's `app_uid` claim — e.g. a driver may only
  /// write their own drivers_live doc — so callers about to touch Firestore
  /// should await this and check the result.
  ///
  /// Concurrent callers share one in-flight sign-in.
  static Future<bool> ensureSignedIn() =>
      _signingIn ??= _ensureSignedIn().whenComplete(() => _signingIn = null);

  static Future<bool> _ensureSignedIn() async {
    try {
      final userId = await ApiService.getUserId();
      if (userId == null) return false;

      // Also replaces a leftover anonymous / phone-auth / other-account session.
      final current = FirebaseAuth.instance.currentUser;
      if (current != null && current.uid == 'user_$userId') return true;

      final token = await ApiService.getFirebaseCustomToken();
      await FirebaseAuth.instance.signInWithCustomToken(token);
      return true;
    } catch (e, s) {
      AppLog.e('AuthService', 'Firebase custom-token sign-in failed', e, s);
      return false;
    }
  }

  static Future<void> signOutFirebase() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      AppLog.w('AuthService', 'Firebase signOut failed: $e');
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
