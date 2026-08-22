import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A single shimmering grey placeholder block — the building block for
/// skeleton loading screens (used instead of spinners for content that
/// has a known shape, e.g. cards/list rows/text lines).
class SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  const SkeletonBox({
    super.key,
    this.width  = double.infinity,
    this.height = 14,
    this.radius = 6,
  });

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: context.appCardBg,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

/// Wraps [child] with a looping left-to-right shimmer sweep.
class _Shimmer extends StatefulWidget {
  final Widget child;
  const _Shimmer({required this.child});

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1300))..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) {
          final t = _ctrl.value;
          return LinearGradient(
            colors: [
              Colors.transparent,
              Colors.white.withValues(alpha: 0.35),
              Colors.transparent,
            ],
            stops: const [0.35, 0.5, 0.65],
            begin: Alignment(-1 - 2 * (1 - t), 0),
            end:   Alignment(1 + 2 * t, 0),
          ).createShader(bounds);
        },
        child: child,
      ),
      child: widget.child,
    );
  }
}

/// Skeleton placeholder for a single trip/order-style card — an avatar
/// circle, two text lines, and a trailing amount line.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        const SkeletonBox(width: 42, height: 42, radius: 21),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SkeletonBox(width: 140, height: 13),
            const SizedBox(height: 8),
            SkeletonBox(width: MediaQuery.of(context).size.width * 0.4, height: 11),
          ]),
        ),
        const SizedBox(width: 12),
        const SkeletonBox(width: 50, height: 13),
      ]),
    );
  }
}

/// A vertical list of [SkeletonCard]s — drop-in replacement for a
/// CircularProgressIndicator while a card/list-style section loads.
class SkeletonList extends StatelessWidget {
  final int count;
  const SkeletonList({super.key, this.count = 3});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(count, (_) => const SkeletonCard()),
    );
  }
}
