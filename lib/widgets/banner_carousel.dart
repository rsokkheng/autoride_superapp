import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';

/// Promo banners managed in the admin panel (GET /banners). The server picks
/// the ones for the signed-in role (passenger / driver / all) that are active
/// and in their validity window. Renders nothing while loading or when empty.
class BannerCarousel extends StatefulWidget {
  /// Space below the carousel, only when there is something to show.
  final double bottomSpacing;
  const BannerCarousel({super.key, this.bottomSpacing = 0});

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  static const _autoAdvance = Duration(seconds: 5);

  List<Map<String, dynamic>> _banners = [];
  final _controller = PageController();
  int _page = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  static String _imageOf(Map<String, dynamic> b) =>
      (b['image_url'] as String?) ?? (b['image'] as String?) ?? '';

  Future<void> _load() async {
    try {
      final list = await ApiService.getBanners();
      if (!mounted) return;
      setState(() => _banners = list.where((b) => _imageOf(b).isNotEmpty).toList());
      _restartTimer();
    } catch (_) {
      // No banners is a normal state — the section just stays hidden.
    }
  }

  void _restartTimer() {
    _timer?.cancel();
    if (_banners.length < 2) return;
    _timer = Timer.periodic(_autoAdvance, (_) {
      if (!mounted || !_controller.hasClients) return;
      _controller.animateToPage((_page + 1) % _banners.length,
          duration: const Duration(milliseconds: 450), curve: Curves.easeOutCubic);
    });
  }

  Future<void> _open(Map<String, dynamic> banner) async {
    final link = (banner['deeplink'] as String?)?.trim() ?? '';
    final uri = Uri.tryParse(link);
    if (uri == null || !uri.hasScheme) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_banners.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(bottom: widget.bottomSpacing),
      child: Column(children: [
        AspectRatio(
          aspectRatio: 2.4,
          child: PageView.builder(
            controller: _controller,
            itemCount: _banners.length,
            onPageChanged: (i) {
              setState(() => _page = i);
              _restartTimer(); // a manual swipe resets the countdown
            },
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: _BannerItem(
                imageUrl: _imageOf(_banners[i]),
                title: _banners[i]['title'] as String? ?? '',
                onTap: () => _open(_banners[i]),
              ),
            ),
          ),
        ),
        if (_banners.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_banners.length, (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: _page == i ? 18 : 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: _page == i ? AppTheme.accent : context.appTextSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(3),
              ),
            )),
          ),
        ],
      ]),
    );
  }
}

class _BannerItem extends StatelessWidget {
  final String imageUrl;
  final String title;
  final VoidCallback onTap;
  const _BannerItem({required this.imageUrl, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: title,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            placeholder: (_, _u) => Container(color: context.appCardBg),
            errorWidget: (_, _u, _e) => Container(
              color: context.appCardBg,
              alignment: Alignment.center,
              child: Icon(Icons.image_not_supported_outlined,
                  color: AppTheme.accent.withValues(alpha: 0.4), size: 32),
            ),
          ),
        ),
      ),
    );
  }
}
