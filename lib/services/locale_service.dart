import 'package:flutter/services.dart';

/// Propagates Flutter locale changes to the native Maps SDK so that
/// Google Maps labels update to match the in-app language selection.
class LocaleService {
  static const _channel = MethodChannel('app/locale');

  static Future<void> setLocale(String languageCode) async {
    try {
      await _channel.invokeMethod('setLocale', languageCode);
    } catch (_) {
      // Silently ignore — map labels may not update until next map open
    }
  }
}
