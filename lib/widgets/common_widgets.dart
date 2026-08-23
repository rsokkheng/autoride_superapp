import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:autoride_superapp/theme/app_theme.dart';
import 'package:autoride_superapp/models/promo_event_model.dart';
import 'package:autoride_superapp/services/api_service.dart';

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
                // An asset image already carries its own artwork/background —
                // a tinted square behind it just looks like a boxy halo, so
                // only icon-based cards get the color tint.
                color: imagePath != null ? Colors.transparent : color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: imagePath != null
                  ? Image.asset(imagePath!, width: 49, height: 49, fit: BoxFit.contain)
                  : Icon(icon, color: color, size: 26),
            ),
            Text(title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: context.appTextPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12)),
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

// ─── Promo events (shown in place of "Recent Trips" on the home screens) ──────

/// Hero-banner style promo card — gradient background, headline + body on
/// the left, the event's own image bleeding off the right edge, and a pill
/// CTA. Matches the "Special Offers" banner look (green gradient, bold
/// discount headline, product photo, "Shop Now" pill) rather than a plain
/// list-item card, since a promo is meant to grab attention like an ad.
class PromoEventCard extends StatelessWidget {
  final PromoEventModel event;
  final VoidCallback? onTap;
  const PromoEventCard({super.key, required this.event, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.accent, Color(0xFF00863B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: AppTheme.accent.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(children: [
          // Decorative circles, same treatment as the marketplace hero banner.
          Positioned(right: -30, top: -40,
            child: Container(width: 140, height: 140,
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08), shape: BoxShape.circle))),
          Positioned(right: 40, bottom: -60,
            child: Container(width: 110, height: 110,
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06), shape: BoxShape.circle))),

          // Event photo, bleeding off the right edge.
          if (event.imageUrl != null)
            Positioned(
              right: -10, top: 0, bottom: 0, width: 150,
              child: ClipRRect(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(24)),
                child: CachedNetworkImage(
                  imageUrl: event.imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const SizedBox.shrink(),
                  errorWidget: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          height: 1.15)),
                  const SizedBox(height: 6),
                  Text(event.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                ]),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('View',
                      style: TextStyle(
                          color: AppTheme.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

/// Self-fetching promo-events list — drop-in replacement for a screen's old
/// "recent trips" block. Fetches once on mount; shows nothing (not even an
/// empty-state card) when there are no active events, so it doesn't clutter
/// the home screen when marketing has nothing running.
class PromoEventsSection extends StatefulWidget {
  const PromoEventsSection({super.key});

  @override
  State<PromoEventsSection> createState() => _PromoEventsSectionState();
}

class _PromoEventsSectionState extends State<PromoEventsSection> {
  List<PromoEventModel> _events = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final events = await ApiService.getPromoEvents();
      if (!mounted) return;
      setState(() { _events = events; _loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _events.isEmpty) return const SizedBox.shrink();
    return Column(
      children: _events
          .map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: PromoEventCard(event: e),
              ))
          .toList(),
    );
  }
}
