import 'package:flutter/material.dart';

/// Cream banner shown when a pull-to-refresh (or initial load) is taking
/// unusually long — nudges the user that a manual swipe-to-refresh might
/// help, rather than leaving them staring at a blank/skeleton screen with
/// no explanation.
class SlowConnectionBanner extends StatelessWidget {
  const SlowConnectionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFCF1D6),
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 8, height: 8,
          decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
        ),
        const SizedBox(height: 10),
        const Icon(Icons.touch_app_outlined, color: Color(0xFF3A3A3A), size: 28),
        const SizedBox(height: 14),
        const Text('Experiencing a slow connection?',
            style: TextStyle(color: Color(0xFF1A1A1A), fontSize: 17, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text('Swipe down and release to refresh',
            style: TextStyle(color: Colors.black.withValues(alpha: 0.55), fontSize: 13)),
      ]),
    );
  }
}
