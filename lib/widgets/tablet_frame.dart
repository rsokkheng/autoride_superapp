import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

/// Marks a screen that lays itself out for wide screens (maps, adaptive
/// grids, admin tables) — it gets the full tablet width instead of the
/// centered column every other page is shown in.
abstract class TabletFullWidth {}

/// On tablets (and phones in landscape) a phone layout stretched edge to edge
/// looks broken, so pages are shown as a centered column of [maxWidth] with a
/// subtle backdrop on both sides. Inside the column, MediaQuery reports the
/// column's width, so every screen sizes itself as if on a large phone.
/// Phones in portrait are untouched.
class TabletFrame extends StatelessWidget {
  static const double maxWidth = 760;

  final Widget child;
  const TabletFrame({super.key, required this.child});

  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width > maxWidth + 48;

  @override
  Widget build(BuildContext context) {
    if (!isWide(context) || child is TabletFullWidth) return child;

    final mq    = MediaQuery.of(context);
    final theme = Theme.of(context);
    final dark  = theme.brightness == Brightness.dark;
    final side  = Color.alphaBlend(
        (dark ? Colors.white : Colors.black).withValues(alpha: dark ? 0.04 : 0.035),
        theme.scaffoldBackgroundColor);

    return ColoredBox(
      color: side,
      child: Center(
        child: Container(
          width: maxWidth,
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            boxShadow: [BoxShadow(
                color: Colors.black.withValues(alpha: dark ? 0.3 : 0.06), blurRadius: 24)],
          ),
          child: ClipRect(
            child: MediaQuery(
              data: mq.copyWith(size: Size(maxWidth, mq.size.height)),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Wraps the platform's normal page transition so every MaterialPageRoute is
/// framed on tablets — no per-screen changes needed. Screens implementing
/// [TabletFullWidth] are left full width.
class TabletFramePageTransitionsBuilder extends PageTransitionsBuilder {
  final PageTransitionsBuilder inner;
  const TabletFramePageTransitionsBuilder(this.inner);

  // route → does its page opt out? (computed once per route)
  static final Expando<bool> _fullWidth = Expando<bool>();

  static bool _isFullWidth(PageRoute<dynamic> route, BuildContext context) =>
      _fullWidth[route] ??=
          route is MaterialPageRoute && route.builder(context) is TabletFullWidth;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final transition =
        inner.buildTransitions(route, context, animation, secondaryAnimation, child);
    if (!TabletFrame.isWide(context) || _isFullWidth(route, context)) {
      return transition;
    }
    return TabletFrame(child: transition);
  }
}

/// Theme hook: platform-default transitions, framed on tablets.
const PageTransitionsTheme tabletAwarePageTransitions = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: TabletFramePageTransitionsBuilder(ZoomPageTransitionsBuilder()),
    TargetPlatform.iOS:     TabletFramePageTransitionsBuilder(CupertinoPageTransitionsBuilder()),
    TargetPlatform.macOS:   TabletFramePageTransitionsBuilder(CupertinoPageTransitionsBuilder()),
    TargetPlatform.fuchsia: TabletFramePageTransitionsBuilder(ZoomPageTransitionsBuilder()),
    TargetPlatform.linux:   TabletFramePageTransitionsBuilder(ZoomPageTransitionsBuilder()),
    TargetPlatform.windows: TabletFramePageTransitionsBuilder(ZoomPageTransitionsBuilder()),
  },
);
