import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The payment methods the app supports: cash, ABA, ACLEDA and ROTEH Pay.
const kPaymentMethods = ['cash', 'aba', 'acleda', 'wallet'];

/// Logo for a payment method. Bank logos use the official artwork when it is
/// added at assets/banks/aba.png / assets/banks/acleda.png; until then a badge
/// in the bank's colours is drawn.
class PaymentLogo extends StatelessWidget {
  final String method; // cash | aba | acleda | wallet
  final double size;
  const PaymentLogo({super.key, required this.method, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.26);
    switch (method) {
      case 'aba':
        return _bank(context, 'assets/banks/aba.png', 'ABA', const Color(0xFF005D80), const Color(0xFFE31837), radius);
      case 'acleda':
        return _bank(context, 'assets/banks/acleda.png', 'ACLEDA', const Color(0xFF0B3D91), const Color(0xFFF2A900), radius);
      case 'wallet':
        return _tile(radius, AppTheme.accent,
            ClipRRect(
              borderRadius: BorderRadius.circular(size * 0.18),
              child: Image.asset('assets/library/icon_fa.png', width: size * 0.62, height: size * 0.62,
                  errorBuilder: (_, _e, _s) => Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: size * 0.55)),
            ),
            background: AppTheme.accent.withValues(alpha: 0.12));
      default: // cash
        return _tile(radius, const Color(0xFF16A34A),
            Icon(Icons.payments_rounded, color: const Color(0xFF16A34A), size: size * 0.55),
            background: const Color(0xFF16A34A).withValues(alpha: 0.12));
    }
  }

  Widget _tile(BorderRadius radius, Color color, Widget child, {required Color background}) => Container(
        width: size, height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: background, borderRadius: radius),
        child: child,
      );

  Widget _bank(BuildContext context, String asset, String name, Color brand, Color accent, BorderRadius radius) {
    final badge = Container(
      width: size, height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: brand,
        borderRadius: radius,
        border: Border(bottom: BorderSide(color: accent, width: size * 0.08)),
      ),
      padding: EdgeInsets.symmetric(horizontal: size * 0.08),
      child: FittedBox(
        child: Text(name,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900,
                fontSize: size * 0.34, letterSpacing: name.length > 3 ? 0 : 0.5)),
      ),
    );
    return ClipRRect(
      borderRadius: radius,
      child: Image.asset(asset, width: size, height: size, fit: BoxFit.cover,
          errorBuilder: (_, _e, _s) => badge),
    );
  }
}
