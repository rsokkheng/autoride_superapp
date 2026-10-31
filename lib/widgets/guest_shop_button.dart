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
          // Content centred on the button; the chevron sits on the right
          // edge without pushing the text off-centre.
          child: Stack(alignment: Alignment.center, children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 26),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(l.continueAsGuest,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
                ]),
                const SizedBox(height: 2),
                Text(l.continueAsGuestSub,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85), fontSize: 12)),
              ]),
            ),
            const Align(
              alignment: Alignment.centerRight,
              child: Icon(Icons.chevron_right_rounded, color: Colors.white, size: 26),
            ),
          ]),
        ),
      ),
    );
  }
}
