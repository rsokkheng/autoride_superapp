import 'package:flutter/widgets.dart';

extension SheetInsets on MediaQueryData {
  /// Bottom space a bottom sheet / composer must leave: the keyboard while it
  /// is open, otherwise the system navigation bar (Android 3-button bar,
  /// iPhone home indicator) — `viewInsets` alone is 0 when the keyboard is
  /// closed, which put the sheet's main button under the navigation bar.
  double get sheetBottomInset =>
      viewInsets.bottom > 0 ? viewInsets.bottom : viewPadding.bottom;
}
