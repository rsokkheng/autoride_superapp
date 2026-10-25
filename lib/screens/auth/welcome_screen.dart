import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/guest_shop_button.dart';
import '../passenger/marketplace_screen.dart';
import 'login_screen.dart';
import 'role_selection.dart' show LanguagePickerButton;

/// First screen for anyone without a session: shop as a guest, or sign in.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const _green = GuestShopButton.green;

  void _push(BuildContext context, Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  // Side by side → equal widths; stacked → natural height.
  static Widget _flexible(bool stacked, Widget child) =>
      stacked ? child : Expanded(child: child);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // Scale to the screen: Galaxy Z Flip cover screens / small phones are
    // ~260–340 dp wide and short, so fixed 26pt titles and side-by-side
    // buttons overflow or get cut off there.
    final size    = MediaQuery.sizeOf(context);
    final scale   = (size.width / 390).clamp(0.72, 1.0);
    final compact = size.width < 360;   // stack the quick sign-in buttons
    final short   = size.height < 640;  // flatter illustration
    double fs(double v) => v * scale;
    return Scaffold(
      backgroundColor: context.appBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(fs(20), 12, fs(20), 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            // ── Brand + language ─────────────────────────────────────────
            Row(children: [
              Image.asset('assets/library/icon_fa.png', width: fs(52), height: fs(52)),
              SizedBox(width: fs(10)),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text('ROTEH APP',
                        style: TextStyle(
                            color: _green, fontSize: fs(24), fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                  ),
                  const SizedBox(height: 2),
                  Text(l.welcomeTagline,
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: context.appTextSecondary, fontSize: fs(13))),
                ]),
              ),
              const LanguagePickerButton(),
            ]),

            SizedBox(height: fs(20)),
            _Hero(aspectRatio: short ? 2.2 : 1.45),
            SizedBox(height: fs(20)),

            // ── Headline ─────────────────────────────────────────────────
            Text(l.welcomeTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: context.appTextPrimary, fontSize: fs(26), fontWeight: FontWeight.w900,
                    height: 1.3)),
            SizedBox(height: fs(8)),
            Text(l.welcomeSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(color: context.appTextSecondary, fontSize: fs(15), height: 1.4)),

            SizedBox(height: fs(24)),

            // ── Primary actions ──────────────────────────────────────────
            GuestShopButton(onTap: () => _push(context, const MarketplaceScreen())),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => _push(context, const LoginScreen()),
              style: OutlinedButton.styleFrom(
                foregroundColor: _green,
                side: const BorderSide(color: _green, width: 1.5),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Row(children: [
                const Spacer(),
                Icon(Icons.person_outline_rounded, size: fs(24)),
                const SizedBox(width: 10),
                Flexible(
                  flex: 6,
                  child: Text(l.signIn, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: fs(16), fontWeight: FontWeight.w800)),
                ),
                const Spacer(),
                Icon(Icons.chevron_right_rounded, size: fs(24)),
              ]),
            ),

            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: Divider(color: context.appCardBg)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(l.orContinueWith,
                    style: TextStyle(color: context.appTextSecondary, fontSize: 13)),
              ),
              Expanded(child: Divider(color: context.appCardBg)),
            ]),
            const SizedBox(height: 16),

            // ── Quick sign-in (stacked on narrow screens) ────────────────
            Flex(
              direction: compact ? Axis.vertical : Axis.horizontal,
              // stretch = full-width buttons when stacked; side by side the
              // height is unbounded (inside the scroll view), so centre instead.
              crossAxisAlignment: compact ? CrossAxisAlignment.stretch : CrossAxisAlignment.center,
              children: [
                _flexible(compact, _QuickButton(
                  icon: const Icon(Icons.phone_rounded, color: _green, size: 22),
                  label: l.continueWithPhone,
                  onTap: () => _push(context, const LoginScreen(start: LoginStart.phone)),
                )),
                const SizedBox(width: 12, height: 10),
                _flexible(compact, _QuickButton(
                  icon: const Text('G',
                      style: TextStyle(
                          color: Color(0xFF4285F4), fontSize: 20, fontWeight: FontWeight.w900)),
                  label: l.continueWithGoogle,
                  onTap: () => _push(context, const LoginScreen(start: LoginStart.google)),
                )),
              ],
            ),

            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => _push(context, const LoginScreen()),
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(text: l.alreadyHaveAccount,
                        style: TextStyle(color: context.appTextSecondary, fontSize: 14)),
                    TextSpan(text: l.signIn,
                        style: const TextStyle(color: _green, fontSize: 14, fontWeight: FontWeight.w800)),
                    const WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Icon(Icons.chevron_right_rounded, color: _green, size: 20),
                    ),
                  ]),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Trust note ───────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(children: [
                const Icon(Icons.verified_user_rounded, color: _green, size: 30),
                Container(
                  width: 1, height: 32,
                  margin: const EdgeInsets.symmetric(horizontal: 14),
                  color: _green.withValues(alpha: 0.25),
                ),
                Expanded(
                  child: Text(l.secureCheckoutNote,
                      style: TextStyle(color: context.appTextSecondary, fontSize: 13, height: 1.35)),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _QuickButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback onTap;
  const _QuickButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.appSurface,
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            icon,
            const SizedBox(width: 8),
            Flexible(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: context.appTextPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Shop-and-deliver illustration built from icons, so it needs no image asset.
class _Hero extends StatelessWidget {
  final double aspectRatio;
  const _Hero({this.aspectRatio = 1.45});

  static const _green = GuestShopButton.green;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth, h = c.maxHeight;
        return Stack(clipBehavior: Clip.none, children: [
          // Soft backdrop
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [_green.withValues(alpha: 0.16), _green.withValues(alpha: 0.0)],
                  radius: 0.75,
                ),
              ),
            ),
          ),
          // Leaves
          Positioned(left: w * 0.06, bottom: h * 0.12,
              child: Icon(Icons.eco_rounded, size: h * 0.30, color: _green.withValues(alpha: 0.55))),
          Positioned(right: w * 0.04, bottom: h * 0.10,
              child: Icon(Icons.spa_rounded, size: h * 0.26, color: _green.withValues(alpha: 0.4))),
          // Phone storefront
          Positioned(
            left: w * 0.36, top: h * 0.02, width: w * 0.30, height: h * 0.88,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFF1F2937), width: 4),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 18, offset: const Offset(0, 8))],
              ),
              child: Column(children: [
                SizedBox(height: h * 0.06),
                const _Awning(),
                const Spacer(),
                Container(
                  width: w * 0.17, height: w * 0.17,
                  decoration: BoxDecoration(color: _green.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Stack(alignment: Alignment.center, children: [
                    Icon(Icons.shopping_cart_rounded, color: _green, size: w * 0.09),
                    Positioned(
                      right: w * 0.015, top: w * 0.015,
                      child: Icon(Icons.check_circle_rounded, color: _green, size: w * 0.045),
                    ),
                  ]),
                ),
                const Spacer(),
                for (final f in [0.6, 0.45]) ...[
                  Container(height: h * 0.025, width: w * 0.30 * f,
                      decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(3))),
                  SizedBox(height: h * 0.025),
                ],
                SizedBox(height: h * 0.04),
              ]),
            ),
          ),
          // Shopping bag
          Positioned(
            left: w * 0.16, bottom: h * 0.06,
            child: Icon(Icons.shopping_bag_rounded, color: _green, size: h * 0.46),
          ),
          // Parcel
          Positioned(
            left: w * 0.36, bottom: h * 0.02,
            child: Icon(Icons.inventory_2_rounded, color: const Color(0xFFC08A5B), size: h * 0.30),
          ),
          // Delivery scooter
          Positioned(
            right: w * 0.06, bottom: h * 0.04,
            child: Icon(Icons.delivery_dining_rounded, color: _green, size: h * 0.44),
          ),
          // Map pin
          Positioned(
            right: w * 0.14, top: h * 0.10,
            child: Icon(Icons.location_on_rounded, color: _green.withValues(alpha: 0.75), size: h * 0.18),
          ),
        ]);
      }),
    );
  }
}

class _Awning extends StatelessWidget {
  const _Awning();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(children: [
        for (var i = 0; i < 4; i++)
          Expanded(
            child: Container(
              height: 18,
              decoration: BoxDecoration(
                color: i.isEven ? GuestShopButton.green : Colors.white,
                border: Border.all(color: GuestShopButton.green, width: 1),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(9)),
              ),
            ),
          ),
      ]),
    );
  }
}
