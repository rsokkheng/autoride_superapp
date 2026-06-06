import 'package:flutter/material.dart';

class AppTheme {
  // ROTEH brand — light theme
  static const Color primary       = Color(0xFFF5F6FA); // page background
  static const Color accent        = Color(0xFF1A3FAA); // brand navy blue
  static const Color accentOrange  = Color(0xFFFF6B35); // secondary accent
  static const Color surface       = Color(0xFFFFFFFF); // card / surface white
  static const Color cardBg        = Color(0xFFF0F2F5); // secondary background / dividers
  static const Color textPrimary   = Color(0xFF1A1A2E); // dark text
  static const Color textSecondary = Color(0xFF6B7280); // gray text
  static const Color success       = Color(0xFF00C48C); // green
  static const Color warning       = Color(0xFFFFB300); // amber
  static const Color danger        = Color(0xFFD32F2F); // red / CTA confirm
  static const Color gold          = Color(0xFFFFD700); // gold

  // ── Currency helpers ──────────────────────────────────────────────────────

  /// Format a KHR amount: 12000 → "12,000 ៛"
  static String khr(num amount) {
    final int r = amount.round();
    final String s = r.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return '${buf.toString()} ៛';
  }

  /// Format a USD amount as secondary label: 3.25 → "≈ \$3.25"
  static String usd(num amount) => '≈ \$${amount.toStringAsFixed(2)}';

  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.light,
        primaryColor: accent,
        scaffoldBackgroundColor: primary,
        colorScheme: const ColorScheme.light(
          primary: accent,
          secondary: accentOrange,
          surface: surface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: surface,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: IconThemeData(color: textPrimary),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: surface,
          selectedItemColor: accent,
          unselectedItemColor: textSecondary,
          type: BottomNavigationBarType.fixed,
          elevation: 20,
        ),
        cardTheme: CardThemeData(
          color: surface,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: danger,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: cardBg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          hintStyle: const TextStyle(color: textSecondary),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      );
}
