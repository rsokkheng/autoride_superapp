import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../screens/auth/welcome_screen.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

/// Asks for confirmation, deletes the signed-in account (Google Play requires
/// in-app account deletion), then returns to the Welcome screen.
Future<void> confirmAndDeleteAccount(BuildContext context) async {
  final l = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(l.deleteAccountTitle, style: const TextStyle(fontWeight: FontWeight.w800)),
      content: Text(l.deleteAccountMessage),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: AppTheme.confirmButtonStyle(background: AppTheme.danger),
          child: Text(l.deleteAccountConfirm),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  try {
    await ApiService.deleteAccount();
  } on ApiException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppTheme.danger));
    }
    return;
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l.connectionErrorRetry), backgroundColor: AppTheme.danger));
    }
    return;
  }
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.deleteAccountDone)));
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const WelcomeScreen()),
    (_) => false,
  );
}
