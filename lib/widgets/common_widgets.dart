import 'package:flutter/material.dart';
import 'package:autoride_superapp/theme/app_theme.dart';

class GradientCard extends StatelessWidget {
  final Widget child;
  final List<Color> colors;
  final EdgeInsets? padding;
  final double radius;

  const GradientCard({
    super.key,
    required this.child,
    this.colors = const [],
    this.padding,
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors.isEmpty ? [context.appSurface, context.appCardBg] : colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: child,
    );
  }
}

class ServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;
  // When set, renders this PNG (from assets/) instead of the Material icon.
  final String? imagePath;

  const ServiceCard({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 59,
              height: 59,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: imagePath != null
                  ? Image.asset(imagePath!, width: 49, height: 49, fit: BoxFit.contain)
                  : Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 8),
            Text(title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: context.appTextPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const StatusBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class AppTextField extends StatelessWidget {
  final String hint;
  final IconData? icon;
  final bool obscure;
  final TextEditingController? controller;

  const AppTextField({
    super.key,
    required this.hint,
    this.icon,
    this.obscure = false,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: TextStyle(color: context.appTextPrimary),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon, color: context.appTextSecondary, size: 20) : null,
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final bool fullWidth;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? AppTheme.accent,
          foregroundColor: AppTheme.primary,
        ),
        child: Text(label),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const SectionHeader({super.key, required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: TextStyle(
                color: context.appTextPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Text(action!,
                style: const TextStyle(color: AppTheme.accent, fontSize: 13)),
          ),
      ],
    );
  }
}
