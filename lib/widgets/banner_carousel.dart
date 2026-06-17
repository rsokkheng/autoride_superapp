import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class BannerCarousel extends StatefulWidget {
  const BannerCarousel({super.key});

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  List<Map<String, dynamic>> _banners = [];
  bool _loading = true;
  final _controller = PageController();
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final list = await ApiService.getBanners();
      if (!mounted) return;
      setState(() { _banners = list; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        height: 140,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16)),
      );
    }
    if (_banners.isEmpty) return const SizedBox.shrink();

    return Column(children: [
      SizedBox(
        height: 140,
        child: PageView.builder(
          controller: _controller,
          itemCount: _banners.length,
          onPageChanged: (i) => setState(() => _page = i),
          itemBuilder: (_, i) => _BannerItem(banner: _banners[i]),
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
              color: _page == i ? AppTheme.accent : AppTheme.cardBg,
              borderRadius: BorderRadius.circular(3),
            ),
          )),
        ),
      ],
    ]);
  }
}

class _BannerItem extends StatelessWidget {
  final Map<String, dynamic> banner;
  const _BannerItem({required this.banner});

  @override
  Widget build(BuildContext context) {
    final imageUrl = banner['image_url'] as String? ?? banner['image'] as String? ?? '';
    final title    = banner['title']     as String? ?? '';
    final subtitle = banner['subtitle']  as String? ?? banner['description'] as String? ?? '';
    final bgColor  = _parseColor(banner['bg_color'] as String?) ?? AppTheme.accent.withValues(alpha: 0.12);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(fit: StackFit.expand, children: [
        if (imageUrl.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        if (title.isNotEmpty || subtitle.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (title.isNotEmpty)
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12, height: 1.4)),
                ],
              ],
            ),
          ),
      ]),
    );
  }

  Color? _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    try {
      final cleaned = hex.replaceFirst('#', '');
      return Color(int.parse(cleaned.length == 6 ? 'FF$cleaned' : cleaned, radix: 16));
    } catch (_) {
      return null;
    }
  }
}
