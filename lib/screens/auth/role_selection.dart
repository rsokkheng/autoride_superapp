import 'package:flutter/material.dart';
import 'package:autoride_superapp/screens/driver/driver_home.dart';
import 'package:autoride_superapp/screens/passenger/passenger_home.dart';
import 'package:autoride_superapp/theme/app_theme.dart';
import 'package:autoride_superapp/l10n/app_localizations.dart';
import 'package:autoride_superapp/main.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.accent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.electric_car,
                        color: AppTheme.primary, size: 24),
                  ),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.appName,
                          style: TextStyle(
                              color: context.appTextPrimary,
                              fontSize: 26,
                              fontWeight: FontWeight.w800)),
                      Text(l.tagline,
                          style: TextStyle(
                              color: AppTheme.accent,
                              fontSize: 12,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                  Spacer(),
                  LanguagePickerButton(),
                ],
              ),
              SizedBox(height: 48),
              Text(l.whoAreYou,
                  style: TextStyle(
                      color: context.appTextPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w800)),
              SizedBox(height: 8),
              Text(l.selectRole,
                  style: TextStyle(
                      color: context.appTextSecondary, fontSize: 15)),
              SizedBox(height: 40),
              _RoleCard(
                icon: Icons.person_outline,
                title: l.passenger,
                subtitle: l.passengerSub,
                color: AppTheme.accent,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => PassengerHomeScreen())),
              ),
              SizedBox(height: 16),
              _RoleCard(
                icon: Icons.drive_eta_outlined,
                title: l.driver,
                subtitle: l.driverSub,
                color: AppTheme.accentOrange,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => DriverHomeScreen())),
              ),
              Spacer(),
              Center(
                child: Text(l.copyright,
                    style: TextStyle(
                        color: context.appTextSecondary, fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Reusable language switcher — drop it anywhere (AppBar action, profile row, etc.)
class LanguagePickerButton extends StatelessWidget {
  const LanguagePickerButton({super.key});

  static const _langs = [
    {'code': 'km', 'flag': '🇰🇭', 'name': 'ភាសាខ្មែរ'},
    {'code': 'zh', 'flag': '🇨🇳', 'name': '中文'},
    {'code': 'en', 'flag': '🇺🇸', 'name': 'English'},
  ];

  String _flagFor(String code) =>
      _langs.firstWhere((l) => l['code'] == code,
          orElse: () => _langs.first)['flag'] as String;

  void _show(BuildContext context) {
    final l = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: context.appSurface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.fromLTRB(24, 20, 24, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.selectLanguage,
                  style: TextStyle(
                      color: context.appTextPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              ..._langs.map((lang) {
                final selected =
                    appLocale.value.languageCode == lang['code'];
                return GestureDetector(
                  onTap: () {
                    appLocale.value = Locale(lang['code'] as String);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    margin: EdgeInsets.only(bottom: 10),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.accent.withValues(alpha: 0.1)
                          : context.appCardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: selected
                              ? AppTheme.accent
                              : Colors.transparent,
                          width: 1.5),
                    ),
                    child: Row(children: [
                      Text(lang['flag'] as String,
                          style: TextStyle(fontSize: 24)),
                      SizedBox(width: 14),
                      Text(lang['name'] as String,
                          style: TextStyle(
                              color: selected
                                  ? AppTheme.accent
                                  : context.appTextPrimary,
                              fontSize: 15,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500)),
                      if (selected) ...[
                        const Spacer(),
                        const Icon(Icons.check_circle,
                            color: AppTheme.accent, size: 22),
                      ],
                    ]),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: appLocale,
      builder: (context, locale, _) => GestureDetector(
        onTap: () => _show(context),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: context.appSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppTheme.accent.withValues(alpha: 0.3), width: 1),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(_flagFor(locale.languageCode),
                style: TextStyle(fontSize: 18)),
            SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down,
                color: context.appTextSecondary, size: 16),
          ]),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: context.appTextPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                  SizedBox(height: 6),
                  Text(subtitle,
                      style: TextStyle(
                          color: context.appTextSecondary,
                          fontSize: 13,
                          height: 1.4)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ],
        ),
      ),
    );
  }
}
