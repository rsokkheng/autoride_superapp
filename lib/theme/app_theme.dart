import 'package:flutter/material.dart';

class AppTheme {
  // ── Light (Grab-style) ───────────────────────────────────────────────────
  static const Color primary       = Color(0xFFF5F7F5);
  static const Color accent        = Color(0xFF00B14F); // Grab green
  static const Color accentOrange  = Color(0xFFFF6B00);
  static const Color surface       = Color(0xFFFFFFFF);
  static const Color cardBg        = Color(0xFFF0F4F0);
  static const Color textPrimary   = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF767676);
  static const Color success       = Color(0xFF00B14F);
  static const Color warning       = Color(0xFFFFB300);
  static const Color danger        = Color(0xFFEE0033);
  static const Color gold          = Color(0xFFFFD700);
  static const Color confirmBlue   = Color(0xFF2196F3);

  // ── Dark ─────────────────────────────────────────────────────────────────
  static const Color darkPrimary       = Color(0xFF121212);
  static const Color darkSurface       = Color(0xFF1E1E1E);
  static const Color darkCardBg        = Color(0xFF2A2A2A);
  static const Color darkTextPrimary   = Color(0xFFF5F5F5);
  static const Color darkTextSecondary = Color(0xFF9E9E9E);

  // ── Vehicle types ─────────────────────────────────────────────────────────
  static const List<VehicleTypeOption> vehicleTypes = [
    VehicleTypeOption(type: 'car',     label: 'Car',     icon: Icons.directions_car,    description: 'Comfortable sedan'),
    VehicleTypeOption(type: 'bike',    label: 'Bike',    icon: Icons.two_wheeler,       description: 'Fast & affordable'),
    VehicleTypeOption(type: 'tuk_tuk', label: 'Tuk-Tuk', icon: Icons.electric_rickshaw, description: 'Classic tuk-tuk'),
    VehicleTypeOption(type: 'van',     label: 'Van',     icon: Icons.airport_shuttle,   description: 'Groups & luggage'),
  ];

  // ── Currency helpers ──────────────────────────────────────────────────────

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

  static String usd(num amount) => '≈ \$${amount.toStringAsFixed(2)}';

  // ── Light theme ───────────────────────────────────────────────────────────

  static ThemeData get lightTheme => ThemeData(
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
            color: textPrimary, fontSize: 18, fontWeight: FontWeight.w600,
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
          color: surface, elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
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
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none,
          ),
          hintStyle: const TextStyle(color: textSecondary),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      );

  // Keep backward-compat alias used throughout the app
  static ThemeData get darkTheme => lightTheme;

  // ── Dark theme ────────────────────────────────────────────────────────────

  static ThemeData get darkModeTheme => ThemeData(
        brightness: Brightness.dark,
        primaryColor: accent,
        scaffoldBackgroundColor: darkPrimary,
        colorScheme: const ColorScheme.dark(
          primary: accent,
          secondary: accentOrange,
          surface: darkSurface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: darkSurface,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: darkTextPrimary, fontSize: 18, fontWeight: FontWeight.w600,
          ),
          iconTheme: IconThemeData(color: darkTextPrimary),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: darkSurface,
          selectedItemColor: accent,
          unselectedItemColor: darkTextSecondary,
          type: BottomNavigationBarType.fixed,
          elevation: 20,
        ),
        cardTheme: CardThemeData(
          color: darkSurface, elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: darkCardBg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none,
          ),
          hintStyle: const TextStyle(color: darkTextSecondary),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      );
}

// ── Adaptive color extension ─────────────────────────────────────────────────
// Use context.appTextPrimary instead of AppTheme.textPrimary so colors adapt
// automatically when the user switches between light and dark mode.

extension AppColorsX on BuildContext {
  bool get _isDark => Theme.of(this).brightness == Brightness.dark;

  Color get appTextPrimary    => _isDark ? AppTheme.darkTextPrimary   : AppTheme.textPrimary;
  Color get appTextSecondary  => _isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
  Color get appSurface        => _isDark ? AppTheme.darkSurface       : AppTheme.surface;
  Color get appCardBg         => _isDark ? AppTheme.darkCardBg        : AppTheme.cardBg;
  Color get appBackground     => _isDark ? AppTheme.darkPrimary       : AppTheme.primary;
}

// ── Vehicle type option ───────────────────────────────────────────────────────

class VehicleTypeOption {
  final String   type;
  final String   label;
  final IconData icon;
  final String   description;
  const VehicleTypeOption({
    required this.type,
    required this.label,
    required this.icon,
    required this.description,
  });
}
