import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Returns the [BitmapDescriptor] used for a driver's live position marker —
/// just the ride.png artwork, no circle/border behind it. Same icon for
/// every vehicle type; the [vehicleType] argument is kept only so callers
/// (and the preload cache) don't need to change.
///
/// Result is cached — the asset is decoded exactly once per session.
class MarkerIconService {
  MarkerIconService._();

  static Future<BitmapDescriptor>? _pending;
  static BitmapDescriptor? _icon;

  // Native pixel size of assets/ride.png, used to compute imagePixelRatio
  // so it renders at a sane on-map display width regardless of screen density.
  static const _nativeWidthPx = 512.0;
  static const _displayWidthDp = 56.0;

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Returns the marker icon. Subsequent calls are instant (in-memory cache).
  /// [vehicleType] is accepted for API compatibility with callers but no
  /// longer changes the result.
  static Future<BitmapDescriptor> forType(String vehicleType) async {
    if (_icon != null) return _icon!;
    return _pending ??= _load().then((icon) {
      _icon = icon;
      return icon;
    });
  }

  /// Pre-warm the cache so the icon is ready before the first marker update
  /// arrives. [types] is accepted for API compatibility; only one icon is
  /// ever painted now, so any non-empty list triggers the same load.
  static Future<void> preload(List<String> types) async {
    if (types.isEmpty) return;
    await forType(types.first);
  }

  /// Synchronous look-up — returns the cached icon or null if not yet loaded.
  static BitmapDescriptor? cached(String vehicleType) => _icon;

  static Future<BitmapDescriptor> _load() async {
    final data = await rootBundle.load('assets/ride.png');
    return BitmapDescriptor.bytes(
      data.buffer.asUint8List(),
      imagePixelRatio: _nativeWidthPx / _displayWidthDp,
    );
  }
}
