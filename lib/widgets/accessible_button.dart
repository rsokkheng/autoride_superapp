import 'package:flutter/material.dart';

/// Wraps any tappable widget with a Semantics label for screen readers.
/// Use instead of bare GestureDetector when the child has no inherent label.
class AccessibleButton extends StatelessWidget {
  final String label;
  final String? hint;
  final VoidCallback? onTap;
  final Widget child;
  final bool excludeSemantics;

  const AccessibleButton({
    super.key,
    required this.label,
    required this.child,
    this.hint,
    this.onTap,
    this.excludeSemantics = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      hint: hint,
      button: true,
      excludeSemantics: excludeSemantics,
      child: GestureDetector(
        onTap: onTap,
        child: child,
      ),
    );
  }
}

/// Wraps a section with a Semantics heading for screen readers.
class AccessibleHeading extends StatelessWidget {
  final String label;
  final Widget child;

  const AccessibleHeading({super.key, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: label,
      child: child,
    );
  }
}

/// Announces dynamic content changes to screen readers.
class AccessibleLiveRegion extends StatelessWidget {
  final Widget child;

  const AccessibleLiveRegion({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: child,
    );
  }
}
