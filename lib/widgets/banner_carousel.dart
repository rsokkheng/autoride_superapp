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
      // Only show banners that have an image.
      final usable = list.where((b) {
        final image = (b['image_url'] as String?) ?? (b['image'] as String?) ?? '';
        return image.isNotEmpty;
      }).toList();
      setState(() { _banners = usable; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _banners.isEmpty) return const SizedBox.shrink();

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
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_banners.length, (i) => AnimatedContainer(
            duration: Duration(milliseconds: 200),
            width: _page == i ? 18 : 6,
            height: 6,
            margin: EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: _page == i ? AppTheme.accent : context.appCardBg,
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) => Center(
            child: Icon(Icons.image_not_supported_outlined,
                color: AppTheme.accent.withValues(alpha: 0.4), size: 32),
          ),
        ),
      ),
    );
  }
}
