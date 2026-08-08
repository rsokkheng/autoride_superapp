import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Paints a custom round vehicle icon and returns a [BitmapDescriptor] that
/// can be dropped straight into a [Marker].
///
/// Results are cached — each vehicle type is painted exactly once per session.
class MarkerIconService {
  MarkerIconService._();

  static final Map<String, BitmapDescriptor> _cache = {};

  // ── Vehicle type catalogue ─────────────────────────────────────────────────

  static const _vehicles = {
    'motorbike': _VehicleSpec(emoji: '🛺', bg: Color(0xFF1A3FAA), label: 'Bike'),
    'tuk_tuk':   _VehicleSpec(emoji: '🛺', bg: Color(0xFF1A3FAA), label: 'Tuk-Tuk'),
    'car':       _VehicleSpec(emoji: '🚗', bg: Color(0xFF2E7D32), label: 'Car'),
    'small_car': _VehicleSpec(emoji: '🚗', bg: Color(0xFF2E7D32), label: 'Car'),
    'van':       _VehicleSpec(emoji: '🚐', bg: Color(0xFFE65100), label: 'Van'),
    'truck':     _VehicleSpec(emoji: '🚛', bg: Color(0xFFB71C1C), label: 'Truck'),
  };

  static const _fallback = _VehicleSpec(
    emoji: '🛺', bg: Color(0xFF1A3FAA), label: 'Driver',
  );

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Returns a [BitmapDescriptor] for [vehicleType].  Subsequent calls for
  /// the same type are instant (returned from in-memory cache).
  static Future<BitmapDescriptor> forType(String vehicleType) async {
    final key = vehicleType.toLowerCase().trim();
    if (_cache.containsKey(key)) return _cache[key]!;

    final spec = _vehicles[key] ?? _fallback;
    final icon = await _paint(spec);
    _cache[key] = icon;
    return icon;
  }

  /// Pre-warm the cache for a list of vehicle types.  Call this in initState
  /// so icons are ready before the first marker update arrives.
  static Future<void> preload(List<String> types) async {
    await Future.wait(types.map(forType));
  }

  /// Synchronous look-up — returns cached icon or [null] if not yet painted.
  static BitmapDescriptor? cached(String vehicleType) =>
      _cache[vehicleType.toLowerCase().trim()];

  // ── Painting ───────────────────────────────────────────────────────────────

  static Future<BitmapDescriptor> _paint(_VehicleSpec spec) async {
    const double size = 96; // physical pixels of the square canvas
    const double r    = size / 2;

    final recorder = ui.PictureRecorder();
    final canvas   = Canvas(recorder, const Rect.fromLTWH(0, 0, size, size));

    // ── Shadow ──────────────────────────────────────────────────────────────
    canvas.drawCircle(
      const Offset(r, r + 3),
      r - 4,
      Paint()..color = Colors.black.withValues(alpha: 0.25),
    );

    // ── Circle background ────────────────────────────────────────────────────
    canvas.drawCircle(
      const Offset(r, r),
      r - 4,
      Paint()..color = spec.bg,
    );

    // ── White border ─────────────────────────────────────────────────────────
    canvas.drawCircle(
      const Offset(r, r),
      r - 4,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5,
    );

    // ── Emoji ─────────────────────────────────────────────────────────────────
    // We must use ui.ParagraphBuilder because Canvas.drawParagraph is the only
    // way to render emoji glyphs at arbitrary positions.
    const emojiSize = size * 0.46;
    final pb = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign:   TextAlign.center,
        maxLines:    1,
        ellipsis:    '.',
      ), // ignore: prefer_const_constructors — dart:ui ParagraphStyle is not a Flutter const
    )
      ..pushStyle(ui.TextStyle(fontSize: emojiSize, locale: const Locale('en')))
      ..addText(spec.emoji);

    final para = pb.build()
      ..layout(const ui.ParagraphConstraints(width: size));

    // Vertically centre the glyph
    final dy = (size - para.height) / 2 - 2;
    canvas.drawParagraph(para, Offset(0, dy));

    // ── Convert to PNG bytes ──────────────────────────────────────────────────
    final picture = recorder.endRecording();
    final image   = await picture.toImage(size.toInt(), size.toInt());
    final bytes   = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();

    // 96-px canvas rendered at 48 logical pixels → imagePixelRatio = 2
    return BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      imagePixelRatio: 2.0,
    );
  }
}

// ── Internal spec ─────────────────────────────────────────────────────────────

class _VehicleSpec {
  final String emoji;
  final Color  bg;
  final String label;
  const _VehicleSpec({
    required this.emoji,
    required this.bg,
    required this.label,
  });
}
