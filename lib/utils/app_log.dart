import 'package:flutter/foundation.dart';

/// Lightweight logger — output is visible only in debug mode.
/// Tags are printed as [TAG] so you can filter the console easily.
/// Example: flutter logs | grep "\[Fare\]"
abstract class AppLog {
  static void d(String tag, String message) {
    if (kDebugMode) debugPrint('[$tag] $message');
  }

  static void e(String tag, String message, [Object? error, StackTrace? stack]) {
    if (!kDebugMode) return;
    debugPrint('[$tag][ERROR] $message');
    if (error != null) debugPrint('[$tag]  ↳ $error');
    if (stack != null) debugPrint('[$tag]  ↳ ${stack.toString().split('\n').take(6).join('\n')}');
  }

  static void w(String tag, String message) {
    if (kDebugMode) debugPrint('[$tag][WARN] $message');
  }
}
