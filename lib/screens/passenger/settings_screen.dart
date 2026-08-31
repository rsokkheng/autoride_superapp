import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:autoride_superapp/theme/app_theme.dart';
import 'package:autoride_superapp/providers/biometric_provider.dart';
import 'package:autoride_superapp/providers/theme_provider.dart';
import 'package:autoride_superapp/services/api_service.dart';
import 'package:autoride_superapp/l10n/app_localizations.dart';
import 'package:autoride_superapp/screens/auth/role_selection.dart';
import 'cancellation_policy_screen.dart';
import 'accessibility_screen.dart';
import 'safety_screen.dart';
import 'notifications_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appBackground,
        elevation: 0,
        title: Text(AppLocalizations.of(context).settingsTitle,
            style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w700)),
        iconTheme: IconThemeData(color: context.appTextPrimary),
      ),
      body: Builder(builder: (context) {
        final l = AppLocalizations.of(context);
        return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SettingsTile(
            icon: Icons.shield_outlined,
            label: l.safetySettings,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SafetyScreen())),
          ),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            label: l.notifications,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen())),
          ),
          _SettingsTile(
            icon: Icons.cancel_outlined,
            label: l.cancellationPolicyTitle,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const CancellationPolicyScreen())),
          ),
          _SettingsTile(
            icon: Icons.accessibility_new_rounded,
            label: l.accessibilityTitle,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AccessibilityScreen())),
          ),
          Consumer<BiometricProvider>(
            builder: (context, bio, _) {
              if (!bio.available) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                    color: context.appSurface, borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  Icon(Icons.fingerprint, color: context.appTextSecondary, size: 20),
                  const SizedBox(width: 14),
                  Text(l.biometricLogin,
                      style: TextStyle(color: context.appTextPrimary,
                          fontSize: 14, fontWeight: FontWeight.w500)),
                  const Spacer(),
                  Switch(
                    value: bio.enabled,
                    activeColor: AppTheme.accent,
                    onChanged: (v) async {
                      if (v) {
                        try {
                          final email = await ApiService.getEmail() ?? '';
                          await bio.enable(email: email);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(e.toString().replaceFirst('Exception: ', '')),
                              backgroundColor: AppTheme.danger,
                              behavior: SnackBarBehavior.floating,
                            ));
                          }
                        }
                      } else {
                        await bio.disable();
                      }
                    },
                  ),
                ]),
              );
            },
          ),
          Consumer<ThemeProvider>(
            builder: (context, tp, _) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                  color: context.appSurface, borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                Icon(Icons.dark_mode_outlined, color: context.appTextSecondary, size: 20),
                const SizedBox(width: 14),
                Text(l.darkMode,
                    style: TextStyle(color: context.appTextPrimary,
                        fontSize: 14, fontWeight: FontWeight.w500)),
                const Spacer(),
                Switch(
                  value: tp.isDark,
                  activeColor: AppTheme.accent,
                  onChanged: tp.setDark,
                ),
              ]),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: context.appSurface, borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              Icon(Icons.language, color: context.appTextSecondary, size: 20),
              const SizedBox(width: 14),
              Text(l.language,
                  style: TextStyle(color: context.appTextPrimary,
                      fontSize: 14, fontWeight: FontWeight.w500)),
              const Spacer(),
              const LanguagePickerButton(),
            ]),
          ),
        ],
        );
      }),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SettingsTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
            color: context.appSurface, borderRadius: BorderRadius.circular(14)),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(children: [
                Icon(icon, color: context.appTextSecondary, size: 20),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(label,
                      style: TextStyle(color: context.appTextPrimary,
                          fontSize: 14, fontWeight: FontWeight.w500)),
                ),
                Icon(Icons.chevron_right_rounded, color: context.appTextSecondary, size: 20),
              ]),
            ),
          ),
        ),
      );
}
