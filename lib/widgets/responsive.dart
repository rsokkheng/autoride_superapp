import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Phone layouts stretched across a tablet look broken, so wide screens get
/// extra side padding that keeps content centered at [maxWidth]. On phones
/// this is exactly the normal padding ([horizontal] on each side).
EdgeInsets responsivePadding(
  BuildContext context, {
  double maxWidth = 760,
  double horizontal = 16,
  double top = 0,
  double bottom = 0,
}) {
  final width = MediaQuery.sizeOf(context).width;
  final side = math.max(horizontal, (width - maxWidth) / 2 + horizontal);
  return EdgeInsets.fromLTRB(side, top, side, bottom);
}

/// Product/listing grids: as many columns as fit at ~[tileWidth] each —
/// 2 on phones, 3–4 on tablets — instead of a fixed 2 that turns every card
/// huge on an iPad.
SliverGridDelegate responsiveGrid({
  required double mainAxisExtent,
  double tileWidth = 280,
  double spacing = 12,
}) =>
    SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: tileWidth,
      mainAxisExtent: mainAxisExtent,
      mainAxisSpacing: spacing,
      crossAxisSpacing: spacing,
    );
