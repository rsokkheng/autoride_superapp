import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

/// Big green "Continue as Guest" call-to-action (welcome + login screens).
class GuestShopButton extends StatelessWidget {
  final VoidCallback? onTap;
  const GuestShopButton({super.key, required this.onTap});

  static const green = Color(0xFF16A34A);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Material(
      color: onTap == null ? green.withValues(alpha: 0.5) : green,
      borderRadius: BorderRadius.circular(14),
      elevation: 0,
      shadowColor: green.withValues(alpha: 0.4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(children: [
            const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l.continueAsGuest,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(l.continueAsGuestSub,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85), fontSize: 12)),
              ]),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 26),
          ]),
        ),
      ),
    );
  }
}
