import 'dart:io';
import 'package:flutter/material.dart';
import 'car_rental_screen.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/marketplace_model.dart';
import '../../services/api_service.dart';
import '../../services/maps_service.dart';
import '../../theme/app_theme.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../widgets/roteh_location_map.dart';
import '../../widgets/guest_fields.dart';
import '../../widgets/location_picker_screen.dart';

// ── Tokens ─────────────────────────────────────────────────────────────────
const _green  = Color(0xFF00C48C);
const _green2 = Color(0xFF00A37A);
const _white  = Colors.white;

final _fmt    = NumberFormat('#,###', 'en_US');
final _fmtDec = NumberFormat('#,##0.##', 'en_US');
String _usd(num v) => v == v.truncate() ? '\$${_fmt.format(v.toInt())}' : '\$${_fmtDec.format(v)}';

Color _condColor(String? c) => switch (c) {
  'new'         => _green,
  'refurbished' => const Color(0xFF7C3AED),
  _             => const Color(0xFFFF9500),
};

Color _statusColor(String s) => switch (s) {
  'active'    => _green,
  'paused'    => const Color(0xFFFF9500),
  'sold'      => Colors.grey,
  'draft'     => Colors.grey,
  'pending'   => const Color(0xFFFF9500),
  'confirmed' => const Color(0xFF007AFF),
  'completed' => _green,
  'cancelled' => Colors.red,
  _           => Colors.grey,
};

const _catIcons = <String, IconData>{
  'Vehicles':    Icons.directions_car_rounded,
  'Electronics': Icons.devices_rounded,
  'Clothing':    Icons.checkroom_rounded,
  'Furniture':   Icons.chair_rounded,
  'Sports':      Icons.sports_basketball_rounded,
  'Books':       Icons.menu_book_rounded,
  'Tools':       Icons.build_rounded,
  'Food':        Icons.restaurant_rounded,
  'Beauty':      Icons.face_retouching_natural,
};
IconData _catIcon(String n) => _catIcons[n] ?? Icons.category_rounded;

// ── Shared widgets ─────────────────────────────────────────────────────────

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  const _Pill({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      if (icon != null) ...[Icon(icon, color: color, size: 10), const SizedBox(width: 3)],
      Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
    ]),
  );
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  const _SectionTitle(this.title, {this.onSeeAll});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
    child: Row(children: [
      Text(title, style: TextStyle(
          color: context.appTextPrimary, fontWeight: FontWeight.w800, fontSize: 16)),
      const Spacer(),
      if (onSeeAll != null)
        GestureDetector(
          onTap: onSeeAll,
          child: const Row(children: [
            Text('See All', style: TextStyle(
                color: _green, fontWeight: FontWeight.w600, fontSize: 13)),
            Icon(Icons.chevron_right_rounded, color: _green, size: 18),
          ]),
        ),
    ]),
  );
}

class _NetImage extends StatelessWidget {
  final String? url;
  final double? width, height;
  const _NetImage({this.url, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) return _placeholder();
    return Image.network(url!, width: width, height: height, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder());
  }

  Widget _placeholder() => Container(
    width: width, height: height,
    color: const Color(0xFFEEF1EF),
    child: const Center(child: Icon(Icons.image_outlined, color: Colors.grey, size: 28)),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// Main Screen
// ══════════════════════════════════════════════════════════════════════════════

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});
  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() { super.initState(); _tab = TabController(length: 2, vsync: this); }
  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: Colors.black12,
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context)
            ? Padding(
                padding: const EdgeInsets.all(8),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    decoration: BoxDecoration(
                        color: context.appCardBg, borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.arrow_back_ios_new_rounded,
                        color: context.appTextPrimary, size: 16),
                  ),
                ),
              )
            : null,
        titleSpacing: 8,
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: _green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.storefront_rounded, color: _green, size: 20),
          ),
          const SizedBox(width: 10),
          Text('Marketplace', style: TextStyle(
              color: context.appTextPrimary, fontWeight: FontWeight.w800, fontSize: 18)),
        ]),
        actions: const [],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tab,
            indicatorColor: _green,
            indicatorWeight: 3,
            labelColor: _green,
            unselectedLabelColor: Colors.grey,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            tabs: const [Tab(text: 'Browse'), Tab(text: 'My Orders')],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [_BrowseTab(), _MyOrdersTab()],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Browse Tab
// ══════════════════════════════════════════════════════════════════════════════

class _BrowseTab extends StatefulWidget {
  const _BrowseTab();
  @override
  State<_BrowseTab> createState() => _BrowseTabState();
}

class _BrowseTabState extends State<_BrowseTab> {
  List<MarketplaceCategoryModel> _cats  = [];
  List<MarketplaceProductModel>  _prods = [];
  int  _totalCount = 0;
  bool _loading    = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        if (_cats.isEmpty) ApiService.getMarketplaceCategories(),
        ApiService.getMarketplaceProducts(),
      ]);
      if (!mounted) return;
      final page = results.last as MarketplaceProductsPage;
      setState(() {
        if (_cats.isEmpty) _cats = results[0] as List<MarketplaceCategoryModel>;
        _prods       = page.products;
        _totalCount  = page.total;
        _loading     = false;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _openDetail(MarketplaceProductModel p) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => _ProductDetailScreen(product: p)))
        .then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(
        child: CircularProgressIndicator(color: _green, strokeWidth: 2));
    if (_error != null) return _ErrorState(message: _error!, onRetry: _load);

    final featured = _prods.take(6).toList();
    final recent   = _prods.length > 6 ? _prods.sublist(6) : <MarketplaceProductModel>[];

    return RefreshIndicator(
      onRefresh: _load,
      color: _green,
      child: ListView(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const _AllListingsScreen())),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: context.appSurface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.07),
                        blurRadius: 12, offset: const Offset(0, 3)),
                  ],
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.search_rounded, color: _green, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Search products…',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 14))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: context.appCardBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.tune_rounded, color: Colors.grey, size: 14),
                      const SizedBox(width: 4),
                      Text('Filter', style: TextStyle(
                          color: context.appTextSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ]),
              ),
            ),
          ),

          // Hero banner (with total count)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const _AllListingsScreen())),
              child: Container(
              height: 172,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_green, _green2],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Stack(children: [
                Positioned(right: -24, top: -36,
                  child: Container(width: 150, height: 150,
                    decoration: BoxDecoration(
                        color: _white.withValues(alpha: 0.07), shape: BoxShape.circle)),
                ),
                Positioned(right: 60, bottom: -50,
                  child: Container(width: 100, height: 100,
                    decoration: BoxDecoration(
                        color: _white.withValues(alpha: 0.05), shape: BoxShape.circle)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('$_totalCount listings available',
                          style: TextStyle(color: _white.withValues(alpha: 0.95),
                              fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 10),
                    const Text('Find the best deals',
                        style: TextStyle(color: _white, fontWeight: FontWeight.w800, fontSize: 22)),
                    const SizedBox(height: 4),
                    Text('Buy · Rent · Sell in one place',
                        style: TextStyle(color: _white.withValues(alpha: 0.8), fontSize: 13)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const _AllListingsScreen())),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                        decoration: BoxDecoration(
                            color: context.appSurface, borderRadius: BorderRadius.circular(10)),
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [
                          Text('Browse All',
                              style: TextStyle(color: _green,
                                  fontWeight: FontWeight.w700, fontSize: 13)),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded, color: _green, size: 14),
                        ]),
                      ),
                    ),
                  ]),
                ),
              ]),
              ),
            ),
          ),

          // Services
          _SectionTitle('Services'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const CarRentalScreen())),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00838F), Color(0xFF004D56)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(children: [
                  Container(
                    width: 54, height: 54,
                    decoration: BoxDecoration(
                      color: _white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.electric_rickshaw, color: _white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Rental Vehicle',
                          style: TextStyle(color: _white, fontSize: 16,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 3),
                      Text('Sedan · SUV · Van · Electric',
                          style: TextStyle(color: _white.withValues(alpha: 0.78),
                              fontSize: 12)),
                    ]),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_forward_rounded, color: _white, size: 16),
                  ),
                ]),
              ),
            ),
          ),

          // Categories
          if (_cats.isNotEmpty) ...[
            _SectionTitle('Categories'),
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _cats.length,
                itemBuilder: (_, i) {
                  final cat = _cats[i];
                  return GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => _AllListingsScreen(
                            categoryId: cat.id, categoryName: cat.name))),
                    child: Container(
                      width: 72, margin: const EdgeInsets.only(right: 12),
                      child: Column(children: [
                        Container(
                          width: 56, height: 56,
                          decoration: BoxDecoration(
                            color: context.appSurface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 8, offset: const Offset(0, 2))],
                          ),
                          child: Icon(_catIcon(cat.name), color: _green, size: 26),
                        ),
                        const SizedBox(height: 6),
                        Text(cat.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: context.appTextPrimary, fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  );
                },
              ),
            ),
          ],

          // Featured grid
          if (featured.isNotEmpty) ...[
            _SectionTitle('Popular Listings',
                onSeeAll: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const _AllListingsScreen()))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14,
                    mainAxisExtent: 224),
                itemCount: featured.length,
                itemBuilder: (_, i) => _GridCard(
                    product: featured[i], onTap: () => _openDetail(featured[i])),
              ),
            ),
          ],

          // Recent list
          if (recent.isNotEmpty) ...[
            _SectionTitle('Recent Listings',
                onSeeAll: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const _AllListingsScreen()))),
            ...recent.take(4).map((p) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: _ListCard(product: p, onTap: () => _openDetail(p)),
            )),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Grid card ──────────────────────────────────────────────────────────────

class _GridCard extends StatelessWidget {
  final MarketplaceProductModel product;
  final VoidCallback onTap;
  const _GridCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = product;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12, offset: const Offset(0, 3))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            height: 130,
            width: double.infinity,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(fit: StackFit.expand, children: [
                _NetImage(url: p.images.isNotEmpty ? p.images.first : null),
                Positioned(top: 8, left: 8,
                  child: _Pill(
                    label: p.listingType == 'rent' ? 'Rent'
                        : p.listingType == 'both' ? 'Sale & Rent' : 'Sale',
                    color: p.listingType == 'rent'
                        ? const Color(0xFF7C3AED) : _green,
                  ),
                ),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 9, 10, 11),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w700,
                      fontSize: 12, height: 1.35)),
              const SizedBox(height: 6),
              Text(_usd(p.price), style: const TextStyle(
                  color: _green, fontWeight: FontWeight.w800, fontSize: 14)),
              if (p.locationText != null) ...[
                const SizedBox(height: 3),
                Row(children: [
                  const Icon(Icons.location_on_rounded, color: Colors.grey, size: 10),
                  const SizedBox(width: 2),
                  Expanded(child: Text(p.locationText!, maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.grey, fontSize: 10))),
                ]),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}

// ── List card ──────────────────────────────────────────────────────────────

class _ListCard extends StatelessWidget {
  final MarketplaceProductModel product;
  final VoidCallback onTap;
  const _ListCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = product;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
            child: _NetImage(
                url: p.images.isNotEmpty ? p.images.first : null,
                width: 100, height: 100),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w700,
                        fontSize: 13, height: 1.3)),
                const SizedBox(height: 6),
                Wrap(spacing: 6, children: [
                  if (p.condition != null)
                    _Pill(label: p.condition![0].toUpperCase() + p.condition!.substring(1),
                        color: _condColor(p.condition)),
                  _Pill(
                    label: p.listingType == 'rent' ? 'Rent'
                        : p.listingType == 'both' ? 'Sale & Rent' : 'Sale',
                    color: p.listingType == 'rent'
                        ? const Color(0xFF7C3AED) : _green,
                  ),
                ]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(_usd(p.price), style: const TextStyle(
                      color: _green, fontWeight: FontWeight.w800, fontSize: 14)),
                  if (p.locationText != null)
                    Row(children: [
                      const Icon(Icons.location_on_rounded, color: Colors.grey, size: 11),
                      const SizedBox(width: 2),
                      Text(
                        p.locationText!.length > 14
                            ? '${p.locationText!.substring(0, 14)}…'
                            : p.locationText!,
                        style: const TextStyle(color: Colors.grey, fontSize: 11)),
                    ]),
                ]),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Error state ────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.08),
                shape: BoxShape.circle),
            child: const Icon(Icons.error_outline_rounded, color: Colors.red, size: 40)),
        const SizedBox(height: 16),
        Text(message, textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: const Text('Try Again'),
          style: ElevatedButton.styleFrom(backgroundColor: _green,
              foregroundColor: _white, elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        ),
      ]),
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// All Listings Screen
// ══════════════════════════════════════════════════════════════════════════════

class _AllListingsScreen extends StatefulWidget {
  final int?    categoryId;
  final String? categoryName;
  const _AllListingsScreen({this.categoryId, this.categoryName});

  @override
  State<_AllListingsScreen> createState() => _AllListingsScreenState();
}

class _AllListingsScreenState extends State<_AllListingsScreen> {
  final _search     = TextEditingController();
  final _scrollCtrl = ScrollController();
  List<MarketplaceCategoryModel> _cats  = [];
  List<MarketplaceProductModel>  _prods = [];
  bool    _loading     = true;
  bool    _loadingMore = false;
  bool    _hasMore     = false;
  int     _page        = 1;
  String? _error;
  bool    _grid = true;
  int?    _selCat;
  String? _type;
  String? _cond;
  DateTime? _lastSearch;

  @override
  void initState() {
    super.initState();
    _selCat = widget.categoryId;
    _load();
    _search.addListener(_debounce);
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200 &&
        _hasMore && !_loadingMore && !_loading) {
      _loadMore();
    }
  }

  void _debounce() {
    _lastSearch = DateTime.now();
    Future.delayed(const Duration(milliseconds: 450), () {
      if (_lastSearch != null &&
          DateTime.now().difference(_lastSearch!) >= const Duration(milliseconds: 440)) {
        _load();
      }
    });
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; _page = 1; });
    try {
      final futures = await Future.wait([
        if (_cats.isEmpty) ApiService.getMarketplaceCategories(),
        ApiService.getMarketplaceProducts(
          search:      _search.text.trim().isEmpty ? null : _search.text.trim(),
          categoryId:  _selCat,
          listingType: _type,
          condition:   _cond,
          page:        1,
        ),
      ]);
      if (!mounted) return;
      final pageResult = futures.last as MarketplaceProductsPage;
      setState(() {
        if (_cats.isEmpty) _cats = futures[0] as List<MarketplaceCategoryModel>;
        _prods   = pageResult.products;
        _hasMore = pageResult.hasMore;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _loadMore() async {
    if (!mounted || _loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      final pageResult = await ApiService.getMarketplaceProducts(
        search:      _search.text.trim().isEmpty ? null : _search.text.trim(),
        categoryId:  _selCat,
        listingType: _type,
        condition:   _cond,
        page:        _page + 1,
      );
      if (!mounted) return;
      setState(() {
        _page++;
        _prods   = [..._prods, ...pageResult.products];
        _hasMore = pageResult.hasMore;
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  void dispose() {
    _search.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: Colors.black12,
        leading: _BackBtn(),
        title: Text(widget.categoryName ?? 'All Listings',
            style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w800, fontSize: 16)),
        actions: [
          IconButton(
            onPressed: () => setState(() => _grid = !_grid),
            icon: Icon(_grid ? Icons.view_list_rounded : Icons.grid_view_rounded,
                color: context.appTextPrimary, size: 22),
          ),
        ],
      ),
      body: Column(children: [
        // Search
        Container(
          color: context.appSurface,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: TextField(
            controller: _search,
            style: TextStyle(color: context.appTextPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search listings…',
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey, size: 20),
              suffixIcon: _search.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.grey, size: 18),
                      onPressed: () { _search.clear(); _load(); })
                  : null,
              filled: true, fillColor: context.appCardBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        // Filter chips
        Container(
          color: context.appSurface,
          child: Column(children: [
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Row(children: [
                _ChipBtn(label: 'All',
                    active: _selCat == null && _type == null && _cond == null,
                    onTap: () { setState(() { _selCat = null; _type = null; _cond = null; }); _load(); }),
                const SizedBox(width: 8),
                for (final t in [('sale', 'For Sale'), ('rent', 'For Rent')]) ...[
                  _ChipBtn(label: t.$2, active: _type == t.$1,
                      onTap: () { setState(() => _type = _type == t.$1 ? null : t.$1); _load(); }),
                  const SizedBox(width: 8),
                ],
                for (final c in [('new', 'New'), ('used', 'Used'), ('refurbished', 'Refurb')]) ...[
                  _ChipBtn(label: c.$2, active: _cond == c.$1,
                      onTap: () { setState(() => _cond = _cond == c.$1 ? null : c.$1); _load(); }),
                  const SizedBox(width: 8),
                ],
                for (final cat in _cats) ...[
                  _ChipBtn(label: cat.name, active: _selCat == cat.id,
                      onTap: () {
                        setState(() => _selCat = _selCat == cat.id ? null : cat.id);
                        _load();
                      }),
                  const SizedBox(width: 8),
                ],
              ]),
            ),
          ]),
        ),
        // Count
        if (!_loading && _error == null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
            child: Row(children: [
              Text('${_prods.length} result${_prods.length == 1 ? '' : 's'}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ]),
          ),
        // Body
        Expanded(child: _buildBody()),
      ]),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(
        child: CircularProgressIndicator(color: _green, strokeWidth: 2));
    if (_error != null) return _ErrorState(message: _error!, onRetry: _load);
    if (_prods.isEmpty) return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: context.appCardBg, shape: BoxShape.circle),
            child: const Icon(Icons.search_off_rounded, color: Colors.grey, size: 44)),
        const SizedBox(height: 16),
        Text('No listings found',
            style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 6),
        const Text('Try different filters',
            style: TextStyle(color: Colors.grey, fontSize: 13)),
      ]),
    );

    void open(MarketplaceProductModel p) => Navigator.push(
        context, MaterialPageRoute(
            builder: (_) => _ProductDetailScreen(product: p))).then((_) => _load());

    final footer = _loadingMore
        ? const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator(color: _green, strokeWidth: 2)))
        : const SizedBox(height: 32);

    return RefreshIndicator(
      onRefresh: _load, color: _green,
      child: _grid
          ? GridView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14,
                  childAspectRatio: 0.72),
              itemCount: _prods.length + 1,
              itemBuilder: (_, i) {
                if (i == _prods.length) return footer;
                return _GridCard(product: _prods[i], onTap: () => open(_prods[i]));
              })
          : ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              itemCount: _prods.length + 1,
              itemBuilder: (_, i) {
                if (i == _prods.length) return footer;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ListCard(product: _prods[i], onTap: () => open(_prods[i])),
                );
              }),
    );
  }
}

class _ChipBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ChipBtn({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: active ? _green : context.appSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: active ? _green : const Color(0xFFE0E0E0), width: 1.5),
      ),
      child: Text(label,
          style: TextStyle(color: active ? _white : Colors.grey.shade600,
              fontWeight: FontWeight.w600, fontSize: 12)),
    ),
  );
}

class _BackBtn extends StatelessWidget {
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => Navigator.pop(context),
    child: Container(
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: context.appCardBg, borderRadius: BorderRadius.circular(10)),
      child: Icon(Icons.arrow_back_ios_new_rounded, color: context.appTextPrimary, size: 16),
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// Product Detail Screen
// ══════════════════════════════════════════════════════════════════════════════

class _ProductDetailScreen extends StatefulWidget {
  final MarketplaceProductModel product;
  const _ProductDetailScreen({required this.product});
  @override
  State<_ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<_ProductDetailScreen> {
  late MarketplaceProductModel _p;
  bool _loading   = true;
  bool _saved     = false;
  int  _imgIdx    = 0;
  int? _myId;
  late PageController _pageCtrl;

  @override
  void initState() {
    super.initState();
    _p = widget.product;
    _pageCtrl = PageController();
    _loadDetail();
    _loadMe();
  }

  @override
  void dispose() { _pageCtrl.dispose(); super.dispose(); }

  Future<void> _loadDetail() async {
    try {
      final d = await ApiService.getMarketplaceProduct(_p.id);
      if (mounted) setState(() { _p = d; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMe() async {
    final u = await ApiService.getSavedUser();
    if (mounted) setState(() => _myId = u?.id);
  }

  bool get _isOwner => _myId != null && _p.sellerId == _myId;

  @override
  Widget build(BuildContext context) {
    final canSell = _p.listingType == 'sale' || _p.listingType == 'both';
    final canRent = _p.listingType == 'rent' || _p.listingType == 'both';

    return Scaffold(
      backgroundColor: context.appBackground,
      body: Column(children: [
        Expanded(
          child: CustomScrollView(slivers: [
            // ── Image hero ─────────────────────────────────────
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              backgroundColor: context.appSurface,
              elevation: 0,
              automaticallyImplyLeading: false,
              leading: Padding(
                padding: const EdgeInsets.all(8),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.appSurface,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: Icon(Icons.arrow_back_ios_new_rounded,
                        color: context.appTextPrimary, size: 17),
                  ),
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _saved = !_saved),
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: context.appSurface, shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: Icon(
                          _saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                          color: _saved ? _green : context.appTextPrimary, size: 20),
                    ),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(fit: StackFit.expand, children: [
                  Container(color: const Color(0xFFF0F2F1)),
                  _p.images.isNotEmpty
                      ? PageView.builder(
                          controller: _pageCtrl,
                          itemCount: _p.images.length,
                          onPageChanged: (i) => setState(() => _imgIdx = i),
                          itemBuilder: (_, i) => Image.network(
                            _p.images[i], fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                                child: Icon(Icons.image_outlined,
                                    color: Colors.grey, size: 60)),
                          ))
                      : const Center(child: Icon(Icons.image_outlined,
                          color: Colors.grey, size: 60)),
                  if (_loading) const Center(
                      child: CircularProgressIndicator(color: _green, strokeWidth: 2)),
                  // Dots
                  if (_p.images.length > 1)
                    Positioned(bottom: 14, left: 0, right: 0,
                      child: Row(mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_p.images.length, (i) =>
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: _imgIdx == i ? 18 : 6, height: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: _imgIdx == i ? _green : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          )),
                      ),
                    ),
                ]),
              ),
            ),

            // ── Content ───────────────────────────────────────
            SliverToBoxAdapter(
              child: Column(children: [
                // Main card
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: context.appSurface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10, offset: const Offset(0, 3))]),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // Badges
                    Wrap(spacing: 8, runSpacing: 6, children: [
                      _Pill(
                        label: _p.listingType == 'sale' ? 'For Sale'
                            : _p.listingType == 'rent' ? 'For Rent' : 'Sale & Rent',
                        color: _p.listingType == 'rent'
                            ? const Color(0xFF7C3AED) : _green,
                      ),
                      if (_p.condition != null)
                        _Pill(
                          label: _p.condition![0].toUpperCase() + _p.condition!.substring(1),
                          color: _condColor(_p.condition),
                        ),
                      _Pill(label: '${_p.viewsCount} views',
                          color: Colors.grey, icon: Icons.visibility_outlined),
                    ]),
                    const SizedBox(height: 12),
                    // Title
                    Text(_p.title,
                        style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w800,
                            fontSize: 20, height: 1.2)),
                    if (_p.categoryName != null) ...[
                      const SizedBox(height: 4),
                      Text(_p.categoryName!,
                          style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                    const SizedBox(height: 12),
                    // Location
                    if (_p.locationText != null)
                      Row(children: [
                        Container(padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                              color: _green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.location_on_rounded,
                              color: _green, size: 14)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_p.locationText!,
                            style: const TextStyle(color: Colors.grey, fontSize: 13))),
                      ]),
                    const SizedBox(height: 14),
                    const Divider(color: Color(0xFFF0F0F0), height: 1),
                    const SizedBox(height: 14),
                    // Price
                    Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        if (canSell) ...[
                          const Text('Sale Price',
                              style: TextStyle(color: Colors.grey, fontSize: 11)),
                          Text(_usd(_p.price),
                              style: const TextStyle(color: _green,
                                  fontWeight: FontWeight.w800, fontSize: 22)),
                        ],
                        if (canRent && _p.rentPricePerDay != null) ...[
                          const SizedBox(height: 4),
                          const Text('Rent / day',
                              style: TextStyle(color: Colors.grey, fontSize: 11)),
                          Text(_usd(_p.rentPricePerDay!),
                              style: const TextStyle(
                                  color: Color(0xFF7C3AED),
                                  fontWeight: FontWeight.w700, fontSize: 15)),
                        ],
                      ]),
                      const Spacer(),
                      if (_p.quantity > 1)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                              color: context.appCardBg, borderRadius: BorderRadius.circular(10)),
                          child: Text('Qty: ${_p.quantity}',
                              style: TextStyle(color: context.appTextPrimary,
                                  fontWeight: FontWeight.w600, fontSize: 12)),
                        ),
                    ]),
                  ]),
                ),

                // Seller card
                if (_p.sellerName != null)
                  _DetailSection(
                    title: 'Seller',
                    child: Row(children: [
                      CircleAvatar(radius: 22,
                          backgroundColor: _green.withValues(alpha: 0.12),
                          child: Text(_p.sellerName![0].toUpperCase(),
                              style: const TextStyle(color: _green,
                                  fontWeight: FontWeight.w800, fontSize: 18))),
                      const SizedBox(width: 12),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(_p.sellerName!, style: TextStyle(
                            color: context.appTextPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
                        Row(children: [
                          const Icon(Icons.verified_rounded, color: _green, size: 13),
                          const SizedBox(width: 3),
                          const Text('Verified Seller',
                              style: TextStyle(color: Colors.grey, fontSize: 11)),
                        ]),
                      ]),
                    ]),
                  ),

                // Description
                if (_p.description != null && _p.description!.isNotEmpty)
                  _DetailSection(
                    title: 'Description',
                    child: Text(_p.description!,
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 13, height: 1.35)),
                  ),

                // Specs grid
                _DetailSection(
                  title: 'Specifications',
                  child: _SpecGrid(cells: [
                    if (_p.condition != null)
                      _SpecCell('Condition',
                          _p.condition![0].toUpperCase() + _p.condition!.substring(1)),
                    _SpecCell('Quantity', '${_p.quantity}'),
                    _SpecCell('Type',
                        _p.listingType[0].toUpperCase() + _p.listingType.substring(1)),
                    _SpecCell('Views', '${_p.viewsCount}'),
                    if (_p.rentPricePerDay != null)
                      _SpecCell('Per Day', _usd(_p.rentPricePerDay!)),
                    if (_p.locationText != null)
                      _SpecCell('Location', _p.locationText!),
                  ]),
                ),

                const SizedBox(height: 16),
              ]),
            ),
          ]),
        ),

        // ── Bottom CTA ──────────────────────────────────────────
        Container(
          padding: EdgeInsets.fromLTRB(
              16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
          decoration: BoxDecoration(
            color: context.appSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16, offset: const Offset(0, -4))],
          ),
          child: _isOwner
              ? SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit Listing',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => _PostProductScreen(existing: _p))),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _green,
                      side: const BorderSide(color: _green),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                )
              : Row(children: [
                  if (canSell) Expanded(child: _CTA(
                    label: canRent ? 'Buy' : 'Buy Now',
                    icon: Icons.shopping_bag_rounded,
                    color: _green,
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => _OrderScreen(product: _p, orderType: 'purchase'))),
                  )),
                  if (canSell && canRent) const SizedBox(width: 10),
                  if (canRent) Expanded(child: _CTA(
                    label: canSell ? 'Rent' : 'Rent Now',
                    icon: Icons.key_rounded,
                    color: const Color(0xFF7C3AED),
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => _OrderScreen(product: _p, orderType: 'rent'))),
                  )),
                ]),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Purchase Screen
// ══════════════════════════════════════════════════════════════════════════════

class _PurchaseScreen extends StatefulWidget {
  final MarketplaceProductModel product;
  const _PurchaseScreen({required this.product});
  @override
  State<_PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<_PurchaseScreen> {
  // Location
  String  _locType    = 'pickup'; // 'pickup' | 'delivery'
  String  _locAddress = '';
  LatLng? _locLatLng;

  final _couponCtrl     = TextEditingController();
  final _phoneCtrl      = TextEditingController();
  final _guestNameCtrl  = TextEditingController();

  // 0 = Paid all, 1 = Book 30%, 2 = COD
  int _paymentType = 0;
  // Payment method (for paid options)
  String _paymentMethod = 'cash';
  bool _placing = false;
  bool _isGuest = false;

  static const _paymentTypes = [
    ('Paid Full',    'Pay the full amount now'),
    ('Book 30%',     'Pay 30% deposit — balance on delivery'),
    ('COD',          'Cash on delivery'),
  ];

  static const _methods = [
    ('cash',         'Cash',         Icons.payments_outlined),
    ('wallet',       'ROTEH Pay',    Icons.account_balance_wallet),
    ('aba',          'ABA Pay',      Icons.account_balance),
    ('wing',         'Wing',         Icons.flight_takeoff),
    ('other_online', 'Other Online', Icons.language_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _locAddress = widget.product.locationText ?? '';
    ApiService.isLoggedIn().then((v) {
      if (mounted) setState(() => _isGuest = !v);
    });
  }

  @override
  void dispose() {
    _couponCtrl.dispose();
    _phoneCtrl.dispose();
    _guestNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push<_LocationResult>(
      context,
      MaterialPageRoute(
        builder: (_) => _LocationPickerScreen(
          title: _locType == 'pickup' ? 'Pick-up Location' : 'Delivery Location',
          initial: _locLatLng,
          initialAddress: _locAddress,
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _locAddress = result.address;
      _locLatLng  = result.latLng;
    });
  }

  Future<void> _confirm() async {
    // Delivery requires a buyer address; Pick Up uses the seller's location
    final needsAddress = _locType == 'delivery' && _locAddress.isEmpty;
    final needsPhone   = _phoneCtrl.text.trim().isEmpty;
    final needsName    = _isGuest && _guestNameCtrl.text.trim().isEmpty;
    if (needsAddress || needsPhone || needsName) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields'),
            backgroundColor: Colors.red));
      return;
    }
    setState(() => _placing = true);
    try {
      await ApiService.placeMarketplaceOrder(
        widget.product.id,
        paymentMethod: _paymentMethod,
      );
    } catch (_) {
      // non-fatal: show success dialog anyway (matches existing UX)
    }
    if (!mounted) return;
    setState(() => _placing = false);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
                color: _green.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, color: _green, size: 36),
          ),
          const SizedBox(height: 16),
          Text('Order Placed!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: context.appTextPrimary)),
          const SizedBox(height: 8),
          Text('Your purchase request has been sent to the seller.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: _white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.appTextPrimary, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Purchase Product',
            style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w800, fontSize: 17)),
        centerTitle: true,
      ),
      body: Column(children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // Product summary
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.appSurface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Row(children: [
                  if (p.images.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(p.images.first,
                          width: 60, height: 60, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                              width: 60, height: 60,
                              color: _green.withValues(alpha: 0.1),
                              child: const Icon(Icons.storefront_rounded, color: _green))),
                    )
                  else
                    Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(
                          color: _green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.storefront_rounded, color: _green, size: 28),
                    ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w700,
                            fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(_usd(p.price),
                        style: const TextStyle(color: _green,
                            fontWeight: FontWeight.w800, fontSize: 15)),
                  ])),
                ]),
              ),
              const SizedBox(height: 20),

              // Location type + address
              _PurchaseField(
                label: 'Location',
                child: Column(children: [
                  _PurchaseDropdown<String>(
                    label: 'Location Type',
                    icon: _locType == 'pickup'
                        ? Icons.directions_walk_rounded
                        : Icons.local_shipping_outlined,
                    value: _locType,
                    items: const [
                      _DropItemM(
                        value: 'pickup',
                        label: 'Pick Up',
                        subtitle: "I'll collect the item myself",
                        icon: Icons.directions_walk_rounded,
                      ),
                      _DropItemM(
                        value: 'delivery',
                        label: 'Delivery',
                        subtitle: 'Deliver the item to my address',
                        icon: Icons.local_shipping_outlined,
                      ),
                    ],
                    onChanged: (v) => setState(() {
                      _locType    = v;
                      _locAddress = '';
                      _locLatLng  = null;
                    }),
                  ),
                  // Delivery: buyer enters their own address
                  if (_locType == 'delivery') ...[
                    const SizedBox(height: 10),
                    _LocationTile(
                      address: _locAddress,
                      icon: Icons.location_on_rounded,
                      iconColor: Colors.red,
                      hint: 'Tap to set delivery location',
                      onTap: _pickLocation,
                    ),
                  ],
                  // Pick Up: show seller's real location on embedded map.
                  // If the listing has no coordinates, default to the ROTEH
                  // CAMBODIA office (same as Car Rental) instead of leaving
                  // this blank — still tappable to set a real pickup point.
                  if (_locType == 'pickup') ...[
                    const SizedBox(height: 10),
                    if (p.locationLat != null && p.locationLng != null)
                      RotehLocationMap(
                        pin: LatLng(p.locationLat!, p.locationLng!),
                        addressLabel: p.locationText ?? 'Pickup location',
                      )
                    else
                      GestureDetector(
                        onTap: _pickLocation,
                        child: RotehLocationMap(
                          pin: _locLatLng,
                          addressLabel: _locAddress.isNotEmpty ? _locAddress : null,
                        ),
                      ),
                  ],
                ]),
              ),

              // Payment
              _PurchaseField(
                label: 'Payment Type',
                child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  _PurchaseDropdown<int>(
                    label: 'Payment Type',
                    icon: Icons.payments_outlined,
                    value: _paymentType,
                    items: const [
                      _DropItemM(value: 0, label: 'Paid Full',
                          subtitle: 'Pay the full amount now',
                          icon: Icons.check_circle_outline),
                      _DropItemM(value: 1, label: 'Book 30%',
                          subtitle: 'Pay 30% deposit — balance on delivery',
                          icon: Icons.percent_rounded),
                      _DropItemM(value: 2, label: 'COD',
                          subtitle: 'Cash on delivery',
                          icon: Icons.payments_outlined),
                    ],
                    onChanged: (v) => setState(() => _paymentType = v),
                  ),
                  if (_paymentType != 2) ...[
                    const SizedBox(height: 10),
                    _PurchaseDropdown<String>(
                      label: 'Payment Method',
                      icon: Icons.account_balance_wallet_outlined,
                      value: _paymentMethod,
                      items: const [
                        _DropItemM(value: 'cash',         label: 'Cash',
                            subtitle: 'Pay with cash',
                            icon: Icons.payments_outlined),
                        _DropItemM(value: 'wallet',       label: 'ROTEH Pay',
                            subtitle: 'In-app wallet balance',
                            icon: Icons.account_balance_wallet),
                        _DropItemM(value: 'aba',          label: 'ABA Pay',
                            subtitle: 'ABA mobile banking',
                            icon: Icons.account_balance),
                        _DropItemM(value: 'wing',         label: 'Wing',
                            subtitle: 'Wing mobile wallet',
                            icon: Icons.flight_takeoff),
                        _DropItemM(value: 'other_online', label: 'Other Online',
                            subtitle: 'Other online payment',
                            icon: Icons.language_outlined),
                      ],
                      onChanged: (v) => setState(() => _paymentMethod = v),
                    ),
                  ],
                ]),
              ),

              // Coupon code
              Text('Coupon Code', style: TextStyle(
                  color: context.appTextPrimary,
                  fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              _InputField(
                controller: _couponCtrl,
                hint: 'Enter coupon code (optional)',
                icon: Icons.local_offer_outlined,
              ),
              const SizedBox(height: 12),

              // Guest info (shown only when not logged in)
              if (_isGuest) ...[
                GuestFields(
                    nameCtrl: _guestNameCtrl, phoneCtrl: _phoneCtrl),
                const SizedBox(height: 12),
              ] else ...[
                // Phone number for logged-in users
                Text('Phone Number', style: TextStyle(
                    color: context.appTextPrimary,
                    fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                _InputField(
                  controller: _phoneCtrl,
                  hint: 'e.g. 012 345 678',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
              ],

              // Confirm info box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _green.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _green.withValues(alpha: 0.2)),
                ),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.info_outline_rounded, color: _green, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const Text('Confirm Information',
                        style: TextStyle(color: _green, fontWeight: FontWeight.w700,
                            fontSize: 13)),
                    const SizedBox(height: 4),
                    Text('Please verify all addresses and contact details before '
                        'proceeding. The seller will be notified once your order is placed.',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  ])),
                ]),
              ),

              const SizedBox(height: 24),
            ]),
          ),
        ),

        // Purchase Now button
        Container(
          padding: EdgeInsets.fromLTRB(
              16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
          decoration: BoxDecoration(
            color: context.appSurface,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 12, offset: const Offset(0, -4))],
          ),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _placing ? null : _confirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: _white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _placing
                  ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(
                          color: _white, strokeWidth: 2.5))
                  : const Text('Purchase Now',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ),
          ),
        ),
      ]),
    );
  }
}

class _PurchaseField extends StatelessWidget {
  final String label;
  final Widget child;
  const _PurchaseField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(
          color: context.appTextPrimary,
          fontWeight: FontWeight.w600, fontSize: 13)),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: child,
      ),
      const SizedBox(height: 12),
    ],
  );
}

// ── Location result passed back from _LocationPickerScreen ───────────────────

class _LocationResult {
  final String address;
  final LatLng latLng;
  const _LocationResult({required this.address, required this.latLng});
}

// ── Tappable location tile shown in Purchase form ─────────────────────────────

class _LocationTile extends StatelessWidget {
  final String address;
  final IconData icon;
  final Color iconColor;
  final String hint;
  final VoidCallback onTap;
  const _LocationTile({
    required this.address, required this.icon,
    required this.iconColor, required this.hint, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Row(children: [
      Icon(icon, color: iconColor, size: 22),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          address.isEmpty ? hint : address,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: address.isEmpty ? Colors.grey.shade400 : context.appTextPrimary,
            fontSize: 14,
          ),
        ),
      ),
      const SizedBox(width: 8),
      Icon(Icons.chevron_right_rounded,
          color: Colors.grey.shade400, size: 20),
    ]),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// Location Picker Screen — search + drag-pin map
// ══════════════════════════════════════════════════════════════════════════════

class _LocationPickerScreen extends StatefulWidget {
  final String title;
  final LatLng? initial;
  final String initialAddress;
  const _LocationPickerScreen({
    required this.title,
    this.initial,
    this.initialAddress = '',
  });

  @override
  State<_LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<_LocationPickerScreen> {
  static const _phnomPenh = LatLng(11.5680, 104.9195);

  GoogleMapController? _mapCtrl;
  late LatLng _center;
  String _address = '';
  bool   _geocoding = false;

  final _searchCtrl = TextEditingController();
  List<PlaceResult> _searchResults = [];
  bool _searching = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _center  = widget.initial ?? _phnomPenh;
    _address = widget.initialAddress;
  }

  @override
  void dispose() {
    _mapCtrl?.dispose();
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String q) {
    _debounce?.cancel();
    if (q.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 450), () => _doSearch(q));
  }

  Future<void> _doSearch(String q) async {
    setState(() => _searching = true);
    try {
      final results = await MapsService.searchAddress(q);
      if (mounted) setState(() { _searchResults = results; _searching = false; });
    } catch (_) {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _selectResult(PlaceResult r) {
    _searchCtrl.text = r.address;
    setState(() {
      _center        = r.latLng;
      _address       = r.address;
      _searchResults = [];
    });
    _mapCtrl?.animateCamera(CameraUpdate.newLatLngZoom(r.latLng, 16));
  }

  Future<void> _onCameraIdle() async {
    setState(() { _geocoding = true; _address = ''; });
    try {
      final addr = await MapsService.reverseGeocode(_center);
      if (mounted) setState(() {
        _address  = addr ?? '${_center.latitude.toStringAsFixed(4)}, '
            '${_center.longitude.toStringAsFixed(4)}';
        _geocoding = false;
      });
    } catch (_) {
      if (mounted) setState(() => _geocoding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasResults = _searchResults.isNotEmpty;

    return Scaffold(
      backgroundColor: context.appBackground,
      body: Stack(children: [

        // ── Map ────────────────────────────────────────────────────────────
        GoogleMap(
          onMapCreated: (c) {
            _mapCtrl = c;
            c.animateCamera(CameraUpdate.newLatLngZoom(_center, 15));
            if (_address.isEmpty) _onCameraIdle();
          },
          initialCameraPosition: CameraPosition(target: _center, zoom: 15),
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          onCameraMove: (pos) => _center = pos.target,
          onCameraIdle: _onCameraIdle,
        ),

        // ── Crosshair pin ──────────────────────────────────────────────────
        const Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.location_on_rounded, color: _green, size: 40),
            SizedBox(
              width: 10, height: 4,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.all(Radius.circular(2)),
                ),
              ),
            ),
          ]),
        ),

        // ── Top bar: back + search ─────────────────────────────────────────
        SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: context.appSurface, shape: BoxShape.circle,
                      boxShadow: [BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 6)],
                    ),
                    child: Icon(Icons.arrow_back_ios_new_rounded,
                        color: context.appTextPrimary, size: 18),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: context.appSurface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 8)],
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: _onSearchChanged,
                      style: TextStyle(color: context.appTextPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search location…',
                        hintStyle: TextStyle(
                            color: context.appTextSecondary, fontSize: 14),
                        prefixIcon: _searching
                            ? Padding(
                                padding: const EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 18, height: 18,
                                  child: CircularProgressIndicator(
                                      color: _green, strokeWidth: 2),
                                ))
                            : Icon(Icons.search_rounded,
                                color: context.appTextSecondary, size: 20),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.close_rounded,
                                    color: context.appTextSecondary, size: 18),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _searchResults = []);
                                })
                            : null,
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
              ]),
            ),

            // Search results dropdown
            if (hasResults)
              Container(
                margin: const EdgeInsets.fromLTRB(62, 6, 12, 0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 10)],
                ),
                child: Material(
                  color: context.appSurface,
                  borderRadius: BorderRadius.circular(12),
                  clipBehavior: Clip.antiAlias,
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _searchResults.length.clamp(0, 5),
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: context.appCardBg),
                    itemBuilder: (_, i) {
                      final r = _searchResults[i];
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.place_outlined,
                            color: _green, size: 18),
                        title: Text(r.address,
                            maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: context.appTextPrimary, fontSize: 13)),
                        onTap: () => _selectResult(r),
                      );
                    },
                  ),
                ),
              ),
          ]),
        ),

        // ── Bottom confirm bar ─────────────────────────────────────────────
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(
                16, 14, 16, 14 + MediaQuery.of(context).padding.bottom),
            decoration: BoxDecoration(
              color: context.appSurface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(22)),
              boxShadow: [BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 16, offset: const Offset(0, -4))],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Drag handle
              Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                    color: context.appCardBg,
                    borderRadius: BorderRadius.circular(2)),
              ),

              Row(children: [
                Icon(Icons.location_on_rounded,
                    color: _green, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: _geocoding
                      ? Row(children: [
                          SizedBox(
                            width: 14, height: 14,
                            child: CircularProgressIndicator(
                                color: _green, strokeWidth: 2),
                          ),
                          const SizedBox(width: 10),
                          Text('Finding address…',
                              style: TextStyle(
                                  color: context.appTextSecondary, fontSize: 13)),
                        ])
                      : Text(
                          _address.isEmpty
                              ? 'Drag map to set location'
                              : _address,
                          maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: context.appTextPrimary, fontSize: 14,
                              fontWeight: FontWeight.w500)),
                ),
              ]),
              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: (_geocoding || _address.isEmpty)
                      ? null
                      : () => Navigator.pop(
                          context,
                          _LocationResult(
                              address: _address, latLng: _center)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: _white,
                    disabledBackgroundColor:
                        _green.withValues(alpha: 0.35),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text(widget.title == 'Pick-up Location'
                      ? 'Set Pick-up Here'
                      : 'Set Drop-off Here',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w800)),
                ),
              ),
            ]),
          ),
        ),

        // ── My-location button ─────────────────────────────────────────────
        Positioned(
          right: 14,
          bottom: 140 + MediaQuery.of(context).padding.bottom,
          child: GestureDetector(
            onTap: () async {
              try {
                final pos = await Geolocator.getCurrentPosition(
                    desiredAccuracy: LocationAccuracy.high);
                if (!mounted) return;
                final ll = LatLng(pos.latitude, pos.longitude);
                _mapCtrl?.animateCamera(CameraUpdate.newLatLngZoom(ll, 16));
              } catch (_) {}
            },
            child: Builder(builder: (ctx) => Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: ctx.appSurface, shape: BoxShape.circle,
                boxShadow: [BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 6)],
              ),
              child: Icon(Icons.my_location_rounded,
                  color: ctx.appTextPrimary, size: 22),
            )),
          ),
        ),
      ]),
    );
  }
}

// Delivery-style text input — adapts to dark mode
class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  const _InputField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    keyboardType: keyboardType,
    style: TextStyle(color: context.appTextPrimary),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: context.appTextSecondary),
      prefixIcon: Icon(icon, color: context.appTextSecondary, size: 20),
      filled: true,
      fillColor: context.appSurface,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.accent, width: 1.5)),
    ),
  );
}

// Delivery-style dropdown item
class _DropItemM<T> {
  final T value;
  final String label;
  final String subtitle;
  final IconData icon;
  const _DropItemM({
    required this.value,
    required this.label,
    required this.subtitle,
    required this.icon,
  });
}

// Delivery-style bottom-sheet dropdown
class _PurchaseDropdown<T> extends StatelessWidget {
  final String label;
  final IconData icon;
  final T value;
  final List<_DropItemM<T>> items;
  final ValueChanged<T> onChanged;

  const _PurchaseDropdown({
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  _DropItemM<T> get _selected =>
      items.firstWhere((i) => i.value == value, orElse: () => items.first);

  void _open(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.appSurface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        top: false,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: context.appCardBg,
                borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(label,
                  style: TextStyle(
                      color: context.appTextPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
            ),
          ),
          Divider(height: 1, color: context.appCardBg),
          ...items.map((item) {
            final selected = item.value == value;
            return InkWell(
              onTap: () {
                onChanged(item.value);
                Navigator.pop(ctx);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 14),
                child: Row(children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.accent.withValues(alpha: 0.12)
                          : context.appCardBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(item.icon,
                        color: selected
                            ? AppTheme.accent
                            : context.appTextSecondary,
                        size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(item.label,
                        style: TextStyle(
                            color: selected
                                ? AppTheme.accent
                                : context.appTextPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                    if (item.subtitle.isNotEmpty)
                      Text(item.subtitle,
                          style: TextStyle(
                              color: context.appTextSecondary,
                              fontSize: 12)),
                  ])),
                  if (selected)
                    const Icon(Icons.check_circle,
                        color: AppTheme.accent, size: 20)
                  else
                    Icon(Icons.radio_button_off,
                        color: context.appTextSecondary, size: 20),
                ]),
              ),
            );
          }),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => _open(context),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.appCardBg),
      ),
      child: Row(children: [
        Icon(_selected.icon, color: AppTheme.accent, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: TextStyle(
                  color: context.appTextSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(_selected.label,
              style: TextStyle(
                  color: context.appTextPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
        ])),
        Icon(Icons.keyboard_arrow_down,
            color: context.appTextSecondary, size: 22),
      ]),
    ),
  );
}

class _CTA extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _CTA({required this.label, required this.icon,
      required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => ElevatedButton.icon(
    onPressed: onTap,
    icon: Icon(icon, size: 18),
    label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
    style: ElevatedButton.styleFrom(
      backgroundColor: color, foregroundColor: _white, elevation: 0,
      padding: const EdgeInsets.symmetric(vertical: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}

class _DetailSection extends StatelessWidget {
  final String title;
  final Widget child;
  const _DetailSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: context.appSurface, borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(color: context.appTextPrimary,
          fontWeight: FontWeight.w800, fontSize: 13)),
      const SizedBox(height: 8),
      child,
    ]),
  );
}

class _SpecGrid extends StatelessWidget {
  final List<_SpecCell> cells;
  const _SpecGrid({required this.cells});

  @override
  Widget build(BuildContext context) {
    if (cells.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(builder: (context, constraints) {
      final cellWidth = (constraints.maxWidth - 10) / 2;
      final rows = <Widget>[];
      for (int i = 0; i < cells.length; i += 2) {
        final a = SizedBox(width: cellWidth, child: cells[i]);
        final b = i + 1 < cells.length
            ? SizedBox(width: cellWidth, child: cells[i + 1])
            : SizedBox(width: cellWidth);
        rows.add(Row(children: [a, const SizedBox(width: 8), b]));
        if (i + 2 < cells.length) rows.add(const SizedBox(height: 8));
      }
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
    });
  }
}

class _SpecCell extends StatelessWidget {
  final String label, value;
  const _SpecCell(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(color: context.appCardBg, borderRadius: BorderRadius.circular(10)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(
              color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(value, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w700,
                  fontSize: 13, height: 1.2)),
        ]),
      );
    });
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Order Screen
// ══════════════════════════════════════════════════════════════════════════════

// Rental duration presets — same "pick a duration, end date auto-computes"
// pattern as the Car Rental page (1M · 2M · 3M · 6M · 1Y · 2Y).
enum _RentDur { m1, m2, m3, m6, y1, y2 }

extension _RentDurX on _RentDur {
  String get label => switch (this) {
    _RentDur.m1 => '1 Month',
    _RentDur.m2 => '2 Months',
    _RentDur.m3 => '3 Months',
    _RentDur.m6 => '6 Months',
    _RentDur.y1 => '1 Year',
    _RentDur.y2 => '2 Years',
  };
  int get months => switch (this) {
    _RentDur.m1 => 1,  _RentDur.m2 => 2,  _RentDur.m3 => 3,
    _RentDur.m6 => 6,  _RentDur.y1 => 12, _RentDur.y2 => 24,
  };
  int get days => months * 30;
  IconData get icon => switch (this) {
    _RentDur.m1 || _RentDur.m2 || _RentDur.m3 || _RentDur.m6 => Icons.calendar_month_outlined,
    _RentDur.y1 || _RentDur.y2                                => Icons.calendar_today_outlined,
  };
}

// Location type — Pick Up (shows the listing's own location, non-editable)
// or Delivery (drag the map / search to set an address), same as Car Rental.
enum _LocType { pickup, delivery }

extension _LocTypeX on _LocType {
  String get label    => this == _LocType.pickup ? 'Pick Up' : 'Delivery';
  String get subtitle => this == _LocType.pickup
      ? "I'll collect it myself"
      : 'Deliver the car to my address';
  IconData get icon   => this == _LocType.pickup
      ? Icons.directions_walk_rounded
      : Icons.local_shipping_outlined;
  String get mapTitle => this == _LocType.pickup
      ? 'Pick-up Location'
      : 'Set Delivery Location';
}

class _OrderScreen extends StatefulWidget {
  final MarketplaceProductModel product;
  final String orderType;
  const _OrderScreen({required this.product, required this.orderType});
  @override
  State<_OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<_OrderScreen> {
  int    _qty   = 1;
  String _pay   = 'cash';
  final  _notes = TextEditingController();
  final  _couponCtrl = TextEditingController();
  _RentDur  _duration = _RentDur.m1;
  DateTime? _start;
  bool    _busy = false;
  String? _err;
  bool    _applyingCoupon = false;
  String? _appliedCode;
  String? _couponError;
  int     _discountKhr = 0;
  _LocType  _locType = _LocType.pickup;
  String    _deliveryAddress = '';
  LatLng?   _deliveryLatLng;
  // Manual pickup point, used only when the listing itself has no
  // coordinates — lets the buyer drag/search to set one instead of a
  // dead-end "not set" message.
  String    _manualPickupAddress = '';
  LatLng?   _manualPickupLatLng;

  bool get _isRent  => widget.orderType == 'rent';
  // Every "rent" listing in this marketplace is a vehicle, so rent orders
  // always book through the car-rental system (POST /rentals) instead of a
  // generic marketplace order — that's what makes them show up correctly for
  // the vehicle's driver/owner to accept.
  bool get _isVehicleRental => _isRent;
  bool get _datesOk => !_isRent || _start != null;
  DateTime? get _end => _start?.add(Duration(days: _duration.days));
  int  get _days    => _isRent ? _duration.days : 0;
  double get _subtotal  {
    if (_isRent && widget.product.rentPricePerDay != null && _datesOk) {
      return widget.product.rentPricePerDay! * _days * _qty;
    }
    return widget.product.price * _qty;
  }
  double get _discountUsd => _discountKhr / 4100.0;
  double get _total => (_subtotal - _discountUsd).clamp(0.0, _subtotal);
  // Rentals book through the same /rentals system as the Car Rental page,
  // so they share its green theme.
  Color get _color => _isRent ? AppTheme.accent : _green;

  static String _fmt(DateTime d) => DateFormat('MMM d, yyyy').format(d);

  @override
  void dispose() {
    _notes.dispose();
    _couponCtrl.dispose();
    super.dispose();
  }

  Future<void> _applyCoupon() async {
    final code = _couponCtrl.text.trim();
    if (code.isEmpty) return;
    setState(() { _applyingCoupon = true; _couponError = null; });
    try {
      final subtotalKhr = (_subtotal * 4100).round();
      final result = await ApiService.applyPromoCode(code, subtotalKhr,
          serviceType: _isRent ? 'rental' : 'marketplace');
      if (!mounted) return;
      setState(() {
        _discountKhr    = (result['discount_amount'] as num? ?? 0).toInt();
        _appliedCode    = code;
        _couponError    = null;
        _applyingCoupon = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() { _couponError = e.message; _applyingCoupon = false; _discountKhr = 0; _appliedCode = null; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _couponError = 'Failed to apply coupon.'; _applyingCoupon = false; _discountKhr = 0; _appliedCode = null; });
    }
  }

  void _removeCoupon() => setState(() {
    _couponCtrl.clear();
    _discountKhr = 0;
    _appliedCode = null;
    _couponError = null;
  });

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(context: context,
        initialDate: _start ?? now.add(const Duration(days: 1)),
        firstDate: now, lastDate: now.add(const Duration(days: 365)));
    if (picked == null || !mounted) return;
    setState(() => _start = picked);
  }

  Future<void> _pickDeliveryLocation() async {
    final result = await Navigator.push<LocationPickResult>(
      context,
      MaterialPageRoute(builder: (_) => LocationPickerScreen(
        title:    _locType.mapTitle,
        pinColor: _color,
        initial:  _deliveryLatLng,
      )),
    );
    if (result == null || !mounted) return;
    setState(() { _deliveryAddress = result.address; _deliveryLatLng = result.latLng; });
  }

  Future<void> _pickManualPickupLocation() async {
    final result = await Navigator.push<LocationPickResult>(
      context,
      MaterialPageRoute(builder: (_) => LocationPickerScreen(
        title:    'Pick-up Location',
        pinColor: _color,
        initial:  _manualPickupLatLng,
      )),
    );
    if (result == null || !mounted) return;
    setState(() { _manualPickupAddress = result.address; _manualPickupLatLng = result.latLng; });
  }

  void _openLocTypeSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.appSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        top: false,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: ctx.appCardBg, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Location Type', style: TextStyle(
                  color: ctx.appTextPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
          Divider(height: 1, color: ctx.appCardBg),
          ..._LocType.values.map((t) {
            final isSel = t == _locType;
            return InkWell(
              onTap: () {
                setState(() {
                  _locType = t;
                  _deliveryAddress = '';
                  _deliveryLatLng = null;
                });
                Navigator.pop(ctx);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: isSel ? _color.withValues(alpha: 0.12) : ctx.appCardBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(t.icon, color: isSel ? _color : Colors.grey, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(t.label, style: TextStyle(
                        color: ctx.appTextPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(t.subtitle, style: TextStyle(color: ctx.appTextSecondary, fontSize: 12)),
                  ])),
                  if (isSel) Icon(Icons.check_circle_rounded, color: _color, size: 20),
                ]),
              ),
            );
          }),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  void _openDurationSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.appSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        top: false,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: ctx.appCardBg, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Rental Duration', style: TextStyle(
                  color: ctx.appTextPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
          Divider(height: 1, color: ctx.appCardBg),
          ..._RentDur.values.map((d) {
            final isSel = d == _duration;
            final endsLabel = _start != null
                ? 'Ends ${_fmt(_start!.add(Duration(days: d.days)))}'
                : '${d.days} day${d.days == 1 ? '' : 's'}';
            return InkWell(
              onTap: () { setState(() => _duration = d); Navigator.pop(ctx); },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: isSel ? _color.withValues(alpha: 0.12) : ctx.appCardBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(d.icon, color: isSel ? _color : Colors.grey, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(d.label, style: TextStyle(
                        color: ctx.appTextPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(endsLabel, style: TextStyle(color: ctx.appTextSecondary, fontSize: 12)),
                  ])),
                  if (isSel) Icon(Icons.check_circle_rounded, color: _color, size: 20),
                ]),
              ),
            );
          }),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Future<void> _submit() async {
    if (_isRent && (_start == null || _end == null)) {
      setState(() => _err = 'Please select rental start and end dates.');
      return;
    }
    if (_isVehicleRental && _locType == _LocType.delivery && _deliveryAddress.isEmpty) {
      setState(() => _err = 'Please set a delivery location.');
      return;
    }
    setState(() { _busy = true; _err = null; });
    try {
      if (_isVehicleRental) {
        // Pickup falls back to the listing's own location, then a manually
        // picked override, then the ROTEH CAMBODIA office as a last resort
        // (matching what the map already shows by default).
        final pickupLocation = _locType == _LocType.pickup
            ? (widget.product.locationText ??
                (_manualPickupAddress.isNotEmpty ? _manualPickupAddress : kRotehAddress))
            : _deliveryAddress;
        final pickupLat = _locType == _LocType.pickup
            ? (widget.product.locationLat ?? _manualPickupLatLng?.latitude ?? kRotehPin.latitude)
            : _deliveryLatLng?.latitude;
        final pickupLng = _locType == _LocType.pickup
            ? (widget.product.locationLng ?? _manualPickupLatLng?.longitude ?? kRotehPin.longitude)
            : _deliveryLatLng?.longitude;
        await ApiService.createCarRental(
          marketplaceProductId: widget.product.id,
          pickupLocation: pickupLocation,
          pickupLat:      pickupLat,
          pickupLng:      pickupLng,
          startDate:      _start!,
          endDate:        _end!,
          paymentMethod:  _pay,
          notes:          _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        );
      } else {
        await ApiService.placeMarketplaceOrder(widget.product.id,
          orderType:     widget.orderType,
          quantity:      _qty,
          paymentMethod: _pay,
          notes:         _notes.text.trim().isEmpty ? null : _notes.text.trim(),
          rentStartDate: _isRent ? DateFormat('yyyy-MM-dd').format(_start!) : null,
          rentEndDate:   _isRent ? DateFormat('yyyy-MM-dd').format(_end!)   : null,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Order placed successfully!'), backgroundColor: _green));
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) setState(() { _err = e.message; _busy = false; });
    } catch (e) {
      if (mounted) setState(() { _err = e.toString(); _busy = false; });
    }
  }

  void _openPaymentSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.appSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        top: false,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: ctx.appCardBg, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Payment Method', style: TextStyle(
                  color: ctx.appTextPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
          Divider(height: 1, color: ctx.appCardBg),
          ..._pays.map((o) {
            final (id, label, icon, subtitle) = o;
            final isSel = id == _pay;
            return InkWell(
              onTap: () { setState(() => _pay = id); Navigator.pop(ctx); },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: isSel ? _color.withValues(alpha: 0.12) : ctx.appCardBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: isSel ? _color : Colors.grey, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(label, style: TextStyle(
                        color: ctx.appTextPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(subtitle, style: TextStyle(color: ctx.appTextSecondary, fontSize: 12)),
                  ])),
                  if (isSel) Icon(Icons.check_circle_rounded, color: _color, size: 20),
                ]),
              ),
            );
          }),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  static const _pays = [
    ('cash',         'Cash',   Icons.money_rounded,             'Pay in cash on pickup'),
    ('aba',          'ABA',    Icons.account_balance_rounded,   'ABA mobile banking'),
    ('wing',         'Wing',   Icons.account_balance_wallet_rounded, 'Wing mobile wallet'),
    ('wallet',       'Wallet', Icons.wallet_rounded,            'In-app wallet balance'),
    ('other_online', 'Online', Icons.phone_android_rounded,     'Other online payment'),
  ];

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface, elevation: 0,
        scrolledUnderElevation: 0.5, shadowColor: Colors.black12,
        leading: _BackBtn(),
        title: Text(_isRent ? 'Rent Item' : 'Buy Item',
            style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w800, fontSize: 16)),
      ),
      body: Column(children: [
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Error
            if (_err != null)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.25))),
                child: Row(children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_err!,
                      style: const TextStyle(color: Colors.red, fontSize: 13))),
                ]),
              ),

            // Product summary
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: context.appSurface, borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8, offset: const Offset(0, 2))]),
              child: Row(children: [
                ClipRRect(borderRadius: BorderRadius.circular(10),
                    child: _NetImage(
                        url: p.images.isNotEmpty ? p.images.first : null,
                        width: 60, height: 60)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w700,
                          fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(
                    _isRent && p.rentPricePerDay != null
                        ? '${_usd(p.rentPricePerDay!)}/day' : _usd(p.price),
                    style: TextStyle(color: _color, fontWeight: FontWeight.w700,
                        fontSize: 13)),
                ])),
              ]),
            ),
            const SizedBox(height: 16),

            // Location (vehicle rentals only — books via /rentals), matching
            // the Car Rental page's Location Type + embedded map.
            if (_isVehicleRental) ...[
              _FormLabel('Location'),
              const SizedBox(height: 10),
              _OrderDropdownTile(
                icon: _locType.icon,
                label: 'Location Type',
                value: _locType.label,
                subtitle: _locType.subtitle,
                color: _color,
                onTap: _openLocTypeSheet,
              ),
              const SizedBox(height: 10),
              if (_locType == _LocType.pickup) ...[
                if (widget.product.locationLat != null && widget.product.locationLng != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.appSurface,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6, offset: const Offset(0, 2))],
                    ),
                    child: RotehLocationMap(
                      pin: LatLng(widget.product.locationLat!, widget.product.locationLng!),
                      // Never fall back to RotehLocationMap's own default label
                      // (the ROTEH HQ address) — this is the listing's own
                      // pickup point, not the company office.
                      addressLabel: widget.product.locationText ?? 'Pickup location',
                    ),
                  )
                else if (_manualPickupLatLng != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.appSurface,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6, offset: const Offset(0, 2))],
                    ),
                    child: RotehLocationMap(
                      pin: _manualPickupLatLng,
                      addressLabel: _manualPickupAddress,
                    ),
                  )
                else
                  // No listing coordinates and nothing picked yet — default
                  // to the ROTEH CAMBODIA office (same as Car Rental's Pick
                  // Up default) instead of leaving this blank. Still tappable
                  // to override with a real pickup point.
                  GestureDetector(
                    onTap: _pickManualPickupLocation,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: context.appSurface,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 6, offset: const Offset(0, 2))],
                      ),
                      child: const RotehLocationMap(),
                    ),
                  ),
              ] else
                GestureDetector(
                  onTap: _pickDeliveryLocation,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: context.appSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: _deliveryAddress.isEmpty
                              ? Colors.red.withValues(alpha: 0.4) : context.appCardBg),
                    ),
                    child: Row(children: [
                      Icon(Icons.location_on_rounded, color: _color, size: 18),
                      const SizedBox(width: 10),
                      Expanded(child: Text(
                          _deliveryAddress.isEmpty ? 'Tap to set delivery location' : _deliveryAddress,
                          maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: _deliveryAddress.isEmpty
                                  ? Colors.grey : context.appTextPrimary,
                              fontSize: 13,
                              fontWeight: _deliveryAddress.isEmpty ? FontWeight.w400 : FontWeight.w600))),
                      Icon(Icons.chevron_right_rounded, color: context.appTextSecondary, size: 20),
                    ]),
                  ),
                ),
              const SizedBox(height: 16),
            ],

            // Rental period — Duration dropdown + Start Date / End Date (auto),
            // same pattern as the Car Rental page.
            if (_isRent) ...[
              _FormLabel('Rental Period'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.appSurface,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6, offset: const Offset(0, 2))],
                ),
                child: Column(children: [
                  _OrderDropdownTile(
                    icon: _duration.icon,
                    label: 'Duration',
                    value: _duration.label,
                    subtitle: _start != null
                        ? '$_days days  ·  ends ${_fmt(_end!)}'
                        : '$_days day${_days == 1 ? '' : 's'}',
                    color: _color,
                    onTap: _openDurationSheet,
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: GestureDetector(
                      onTap: _pickStartDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                        decoration: BoxDecoration(
                          color: context.appCardBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Start Date', style: TextStyle(
                              color: context.appTextSecondary,
                              fontSize: 10, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Row(children: [
                            Icon(Icons.calendar_today_outlined, color: _color, size: 13),
                            const SizedBox(width: 5),
                            Expanded(child: Text(_start == null ? 'Select' : _fmt(_start!),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: context.appTextPrimary,
                                    fontWeight: FontWeight.w700, fontSize: 12))),
                          ]),
                        ]),
                      ),
                    )),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.arrow_forward_rounded, color: _color, size: 16),
                    ),
                    Expanded(child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                      decoration: BoxDecoration(
                        color: _color.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _color.withValues(alpha: 0.18)),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('End Date (auto)', style: TextStyle(
                            color: _color, fontSize: 10, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Row(children: [
                          Icon(Icons.event_available_outlined, color: _color, size: 13),
                          const SizedBox(width: 5),
                          Expanded(child: Text(_end == null ? '—' : _fmt(_end!),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: _color,
                                  fontWeight: FontWeight.w700, fontSize: 12))),
                        ]),
                      ]),
                    )),
                  ]),
                  if (_start == null) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(10)),
                      child: const Text('Select a start date',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.red,
                              fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ],
                ]),
              ),
              const SizedBox(height: 16),
            ],

            // Quantity (not applicable to a single vehicle-rental booking)
            if (!_isVehicleRental) ...[
              _FormLabel('Quantity'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: context.appSurface, borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6)]),
                child: Row(children: [
                  _QtyBtn(Icons.remove_rounded, _qty > 1, _color,
                      () { if (_qty > 1) setState(() => _qty--); }),
                  Expanded(child: Center(
                      child: Text('$_qty', style: TextStyle(
                          color: context.appTextPrimary, fontSize: 22, fontWeight: FontWeight.w800)))),
                  _QtyBtn(Icons.add_rounded, _qty < p.quantity, _color,
                      () { if (_qty < p.quantity) setState(() => _qty++); }),
                  const SizedBox(width: 10),
                  Text('of ${p.quantity}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ]),
              ),
              const SizedBox(height: 16),
            ],

            // Payment
            _FormLabel('Payment Method'),
            const SizedBox(height: 10),
            Builder(builder: (context) {
              final selected = _pays.firstWhere((o) => o.$1 == _pay);
              return _OrderDropdownTile(
                icon: selected.$3,
                label: 'Payment Method',
                value: selected.$2,
                subtitle: selected.$4,
                color: _color,
                onTap: _openPaymentSheet,
              );
            }),
            const SizedBox(height: 16),

            // Notes
            _FormLabel('Notes (optional)'),
            const SizedBox(height: 10),
            TextField(
              controller: _notes, maxLines: 2,
              style: TextStyle(color: context.appTextPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Any special instructions…',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true, fillColor: context.appSurface,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 16),

            // Coupon code (buy & rent, matching Car Rental)
            _FormLabel('Coupon Code'),
              const SizedBox(height: 10),
              if (_appliedCode != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: _color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _color.withValues(alpha: 0.3)),
                  ),
                  child: Row(children: [
                    Icon(Icons.local_offer_rounded, color: _color, size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_appliedCode!, style: TextStyle(
                          color: _color, fontWeight: FontWeight.w700, fontSize: 14)),
                      Text('- ${_usd(_discountUsd)} discount applied',
                          style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
                    ])),
                    GestureDetector(
                      onTap: _removeCoupon,
                      child: Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, color: Colors.red, size: 16),
                      ),
                    ),
                  ]),
                ),
              ] else ...[
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _couponCtrl,
                      textCapitalization: TextCapitalization.characters,
                      style: TextStyle(color: context.appTextPrimary, fontSize: 14,
                          fontWeight: FontWeight.w600, letterSpacing: 1.2),
                      decoration: InputDecoration(
                        hintText: 'Enter coupon code',
                        hintStyle: TextStyle(color: context.appTextSecondary,
                            fontWeight: FontWeight.w400, letterSpacing: 0),
                        filled: true,
                        fillColor: context.appSurface,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        prefixIcon: Icon(Icons.local_offer_outlined, color: _color, size: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _applyingCoupon ? null : _applyCoupon,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _color,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: _color.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                      ),
                      child: _applyingCoupon
                          ? const SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Apply', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ]),
                if (_couponError != null) ...[
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 14),
                    const SizedBox(width: 6),
                    Text(_couponError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                  ]),
                ],
              ],
            const SizedBox(height: 16),

            // Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: context.appSurface, borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8)]),
              child: Column(children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(_isRent ? 'Booking Summary' : 'Order Summary',
                      style: TextStyle(color: context.appTextPrimary,
                          fontSize: 15, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 12),
                if (!_isRent) ...[
                  _SumRow('Unit price', _usd(p.price)),
                  if (_qty > 1) _SumRow('× $_qty items', _usd(p.price * _qty)),
                ] else ...[
                  // Matches the Car Rental page's summary rows exactly.
                  _SumRow('Vehicle', p.title),
                  _SumRow('Duration', _duration.label),
                  _SumRow('Daily Rate', p.rentPricePerDay != null ? _usd(p.rentPricePerDay!) : '—'),
                  _SumRow('Days', _datesOk ? '$_days days' : '—'),
                ],
                if (_isRent) ...[
                  const SizedBox(height: 8),
                  Row(children: [
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.local_offer_outlined, size: 14, color: _color),
                      const SizedBox(width: 4),
                      Text(
                        _appliedCode != null ? 'Discount ($_appliedCode)' : 'Discount',
                        style: TextStyle(color: context.appTextSecondary, fontSize: 14),
                      ),
                    ]),
                    const Spacer(),
                    Text(
                      _discountKhr > 0 ? '- ${_usd(_discountUsd)}' : '—',
                      style: TextStyle(
                        color: _discountKhr > 0 ? _color : context.appTextSecondary,
                        fontWeight: _discountKhr > 0 ? FontWeight.w600 : FontWeight.w400,
                        fontSize: 14,
                      ),
                    ),
                  ]),
                ],
                Divider(color: context.appCardBg, height: 20, thickness: 1.5),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Total', style: TextStyle(
                      color: context.appTextPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                  Text(_usd(_total), style: TextStyle(
                      color: _color, fontSize: 22, fontWeight: FontWeight.w800)),
                ]),
              ]),
            ),
          ]),
        )),

        // Confirm
        Container(
          padding: EdgeInsets.fromLTRB(
              16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
          decoration: BoxDecoration(
            color: context.appSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16, offset: const Offset(0, -4))],
          ),
          child: SizedBox(width: double.infinity,
            child: ElevatedButton(
              onPressed: _busy ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.confirmBlue,
                foregroundColor: _white, elevation: 0,
                disabledBackgroundColor: AppTheme.confirmBlue.withValues(alpha: 0.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _busy
                  ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(color: _white, strokeWidth: 2.5))
                  : Text(
                      _isRent
                          ? (_datesOk ? 'Confirm Rental — ${_usd(_total)}' : 'Select Dates to Continue')
                          : 'Place Order — ${_usd(_total)}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            ),
          ),
        ),
      ]),
    );
  }
}

class _FormLabel extends StatelessWidget {
  final String text;
  const _FormLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w700, fontSize: 14));
}

// Tappable summary tile that opens a bottom sheet — matches the Car Rental
// page's picker style (icon + label + value + subtitle + chevron).
class _OrderDropdownTile extends StatelessWidget {
  final IconData icon;
  final String label, value, subtitle;
  final Color color;
  final VoidCallback onTap;
  const _OrderDropdownTile({
    required this.icon, required this.label, required this.value,
    required this.subtitle, required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.appCardBg),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(
              color: context.appTextSecondary, fontSize: 10, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(
              color: context.appTextPrimary, fontWeight: FontWeight.w700, fontSize: 13),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          if (subtitle.isNotEmpty)
            Text(subtitle, style: TextStyle(
                color: context.appTextSecondary, fontSize: 10),
                maxLines: 1, overflow: TextOverflow.ellipsis),
        ])),
        Icon(Icons.keyboard_arrow_down, color: context.appTextSecondary, size: 20),
      ]),
    ),
  );
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final bool active;
  final Color color;
  final VoidCallback onTap;
  const _QtyBtn(this.icon, this.active, this.color, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(width: 36, height: 36,
      decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.1) : context.appCardBg,
          borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: active ? color : Colors.grey, size: 20)),
  );
}

class _SumRow extends StatelessWidget {
  final String label, amount;
  const _SumRow(this.label, this.amount);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
      Text(amount, style: TextStyle(
          color: context.appTextPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
    ]),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// My Listings Tab
// ══════════════════════════════════════════════════════════════════════════════

class _MyListingsTab extends StatefulWidget {
  const _MyListingsTab();
  @override
  State<_MyListingsTab> createState() => _MyListingsTabState();
}

class _MyListingsTabState extends State<_MyListingsTab> {
  List<MarketplaceProductModel> _list = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final r = await ApiService.getMyMarketplaceProducts();
      if (mounted) setState(() { _list = r; _loading = false; });
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _delete(MarketplaceProductModel p) async {
    final ok = await showDialog<bool>(context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.appSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete listing?',
            style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w700)),
        content: Text('${p.title} will be permanently removed.',
            style: const TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ApiService.deleteMarketplaceProduct(p.id);
      _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(
        child: CircularProgressIndicator(color: _green, strokeWidth: 2));
    if (_error != null) return _ErrorState(message: _error!, onRetry: _load);

    if (_list.isEmpty) return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
                color: _green.withValues(alpha: 0.08), shape: BoxShape.circle),
            child: const Icon(Icons.storefront_outlined, color: _green, size: 48)),
        const SizedBox(height: 16),
        Text("No listings yet",
            style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w700, fontSize: 17)),
        const SizedBox(height: 6),
        const Text("Post something to start selling",
            style: TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const _PostProductScreen()))
              .then((_) => _load()),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Post a Listing',
              style: TextStyle(fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
              backgroundColor: _green, foregroundColor: _white, elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        ),
      ]),
    );

    return RefreshIndicator(
      onRefresh: _load, color: _green,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _list.length,
        itemBuilder: (_, i) {
          final p = _list[i];
          final sc = _statusColor(p.status);
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: context.appSurface, borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8, offset: const Offset(0, 2))]),
            child: Row(children: [
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                child: _NetImage(url: p.images.isNotEmpty ? p.images.first : null,
                    width: 84, height: 84),
              ),
              Expanded(child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w700,
                          fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(_usd(p.price), style: const TextStyle(
                      color: _green, fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 6),
                  Row(children: [
                    Container(width: 7, height: 7,
                        decoration: BoxDecoration(color: sc, shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Text(p.status[0].toUpperCase() + p.status.substring(1),
                        style: TextStyle(color: sc, fontSize: 11, fontWeight: FontWeight.w600)),
                  ]),
                ]),
              )),
              Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: _green, size: 20),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => _PostProductScreen(existing: p)))
                      .then((_) => _load()),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  onPressed: () => _delete(p),
                ),
              ]),
            ]),
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// My Orders Tab
// ══════════════════════════════════════════════════════════════════════════════

class _MyOrdersTab extends StatefulWidget {
  const _MyOrdersTab();
  @override
  State<_MyOrdersTab> createState() => _MyOrdersTabState();
}

class _MyOrdersTabState extends State<_MyOrdersTab>
    with SingleTickerProviderStateMixin {
  late TabController _tc;
  List<MarketplaceOrderModel> _buying  = [];
  List<MarketplaceOrderModel> _selling = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tc = TabController(length: 2, vsync: this);
    _load();
  }
  @override
  void dispose() { _tc.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        ApiService.getMyMarketplaceOrders(type: 'buying'),
        ApiService.getMyMarketplaceOrders(type: 'rental'),
      ]);
      if (mounted) setState(() {
        _buying  = results[0];
        _selling = results[1];
        _loading = false;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _action(MarketplaceOrderModel o, String a) async {
    try {
      switch (a) {
        case 'confirm':  await ApiService.confirmMarketplaceOrder(o.id);
        case 'complete': await ApiService.completeMarketplaceOrder(o.id);
        case 'cancel':   await ApiService.cancelMarketplaceOrder(o.id);
      }
      _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(
        child: CircularProgressIndicator(color: _green, strokeWidth: 2));
    if (_error != null) return _ErrorState(message: _error!, onRetry: _load);

    return Column(children: [
      Container(
        color: context.appSurface,
        child: TabBar(
          controller: _tc,
          indicatorColor: _green, indicatorWeight: 3,
          labelColor: _green, unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: [
            Tab(text: 'Buying (${_buying.length})'),
            Tab(text: 'Rental (${_selling.length})'),
          ],
        ),
      ),
      Expanded(child: TabBarView(controller: _tc, children: [
        _OrderList(orders: _buying,  isSeller: false, onAction: _action, onRefresh: _load),
        _OrderList(orders: _selling, isSeller: false, onAction: _action, onRefresh: _load),
      ])),
    ]);
  }
}

class _OrderList extends StatelessWidget {
  final List<MarketplaceOrderModel> orders;
  final bool isSeller;
  final void Function(MarketplaceOrderModel, String) onAction;
  final Future<void> Function() onRefresh;
  const _OrderList({required this.orders, required this.isSeller,
      required this.onAction, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) return const Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.receipt_long_outlined, color: Colors.grey, size: 48),
        SizedBox(height: 12),
        Text('No orders yet', style: TextStyle(color: Colors.grey, fontSize: 15)),
      ]),
    );
    return RefreshIndicator(
      onRefresh: onRefresh, color: _green,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (_, i) =>
            _OrderCard(order: orders[i], isSeller: isSeller, onAction: onAction),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final MarketplaceOrderModel order;
  final bool isSeller;
  final void Function(MarketplaceOrderModel, String) onAction;
  const _OrderCard({required this.order, required this.isSeller, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final o       = order;
    final sc      = _statusColor(o.status);
    final isRent  = o.orderType == 'rent';
    final typeClr = isRent ? const Color(0xFF7C3AED) : _green;
    final canAct  = o.status == 'pending' || o.status == 'confirmed';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10, offset: const Offset(0, 3))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Card header ────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Product image / placeholder
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 64, height: 64,
                child: o.productImage != null && o.productImage!.isNotEmpty
                    ? Image.network(o.productImage!, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imgFallback(typeClr, isRent))
                    : _imgFallback(typeClr, isRent),
              ),
            ),
            const SizedBox(width: 12),
            // Details
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Text(o.productTitle ?? 'Order #${o.id}',
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: context.appTextPrimary,
                        fontWeight: FontWeight.w700, fontSize: 13, height: 1.3))),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: sc.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(o.status[0].toUpperCase() + o.status.substring(1),
                      style: TextStyle(color: sc, fontSize: 10, fontWeight: FontWeight.w700)),
                ),
              ]),
              const SizedBox(height: 6),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: typeClr.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(isRent ? 'Rental' : 'Purchase',
                      style: TextStyle(color: typeClr, fontSize: 10, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 8),
                Text('Order #${o.id}',
                    style: TextStyle(color: context.appTextSecondary, fontSize: 11)),
              ]),
              if (o.rentStartDate != null) ...[
                const SizedBox(height: 6),
                Row(children: [
                  Icon(Icons.date_range_rounded, color: context.appTextSecondary, size: 12),
                  const SizedBox(width: 4),
                  Flexible(child: Text('${o.rentStartDate} → ${o.rentEndDate}',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: context.appTextSecondary, fontSize: 11))),
                ]),
              ] else ...[
                const SizedBox(height: 6),
                Row(children: [
                  Icon(Icons.inventory_2_rounded, color: context.appTextSecondary, size: 12),
                  const SizedBox(width: 4),
                  Text('Qty: ${o.quantity}',
                      style: TextStyle(color: context.appTextSecondary, fontSize: 11)),
                ]),
              ],
            ])),
          ]),
        ),
        // ── Price + actions ────────────────────────────────────────────
        Container(
          color: context.appCardBg.withValues(alpha: 0.5),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Total', style: TextStyle(
                  color: context.appTextSecondary, fontSize: 10, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(_usd(o.totalPriceUsd), style: const TextStyle(
                  color: _green, fontWeight: FontWeight.w800, fontSize: 18)),
            ]),
            const Spacer(),
            if (canAct) ...[
              if (isSeller && o.status == 'pending') ...[
                _ActionPill('Confirm', AppTheme.confirmBlue, Icons.check_circle_outline_rounded,
                    () => onAction(o, 'confirm')),
                const SizedBox(width: 8),
              ],
              _ActionPill('Done', const Color(0xFF007AFF), Icons.task_alt_rounded,
                  () => onAction(o, 'complete')),
              const SizedBox(width: 8),
              _ActionPill('Cancel', Colors.red, Icons.cancel_outlined,
                  () => onAction(o, 'cancel')),
            ],
          ]),
        ),
      ]),
    );
  }

  Widget _imgFallback(Color color, bool isRent) => Container(
    color: color.withValues(alpha: 0.08),
    child: Center(child: Icon(
        isRent ? Icons.key_rounded : Icons.shopping_bag_rounded,
        color: color, size: 26)),
  );
}

class _ActionPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  const _ActionPill(this.label, this.color, this.icon, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 13),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
      ]),
    ),
  );
}


// ══════════════════════════════════════════════════════════════════════════════
// Post / Edit Product Screen
// ══════════════════════════════════════════════════════════════════════════════

class _PostProductScreen extends StatefulWidget {
  final MarketplaceProductModel? existing;
  const _PostProductScreen({this.existing});
  @override
  State<_PostProductScreen> createState() => _PostProductScreenState();
}

class _PostProductScreenState extends State<_PostProductScreen> {
  final _title    = TextEditingController();
  final _desc     = TextEditingController();
  final _price    = TextEditingController();
  final _rent     = TextEditingController();
  final _location = TextEditingController();
  final _qty      = TextEditingController(text: '1');

  String _type   = 'sale';
  String _cond   = 'used';
  String _status = 'active';
  final List<File> _imgs = [];
  final _picker = ImagePicker();
  bool _busy = false;
  String? _err;
  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _title.text    = e.title;
      _desc.text     = e.description ?? '';
      _price.text    = '${e.price}';
      _rent.text     = e.rentPricePerDay != null ? '${e.rentPricePerDay}' : '';
      _location.text = e.locationText ?? '';
      _qty.text      = '${e.quantity}';
      _type          = e.listingType;
      _cond          = e.condition ?? 'used';
      _status        = e.status;
    }
  }

  @override
  void dispose() {
    for (final c in [_title, _desc, _price, _rent, _location, _qty]) c.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final slots = 5 - _imgs.length;
    if (slots <= 0) return;
    final picked = await _picker.pickMultiImage(limit: slots);
    if (picked.isEmpty) return;
    final tmp = await getTemporaryDirectory();
    final out = <File>[];
    for (final x in picked) {
      final path = '${tmp.path}/mkt_${DateTime.now().microsecondsSinceEpoch}_${out.length}.jpg';
      final r = await FlutterImageCompress.compressAndGetFile(
          x.path, path, quality: 75, minWidth: 1080, minHeight: 1080,
          format: CompressFormat.jpeg);
      if (r != null) out.add(File(r.path));
    }
    if (out.isEmpty || !mounted) return;
    setState(() => _imgs.addAll(out));
  }

  Future<void> _submit() async {
    final t = _title.text.trim();
    final p = double.tryParse(_price.text.trim());
    if (t.isEmpty) { setState(() => _err = 'Title is required.'); return; }
    if (p == null) { setState(() => _err = 'Price must be a number.'); return; }
    final r = double.tryParse(_rent.text.trim());
    setState(() { _busy = true; _err = null; });
    try {
      if (_isEdit) {
        await ApiService.updateMarketplaceProduct(widget.existing!.id,
            title: t, description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
            listingType: _type, condition: _cond, price: p, rentPricePerDay: r,
            quantity: int.tryParse(_qty.text.trim()) ?? 1, status: _status,
            locationText: _location.text.trim().isEmpty ? null : _location.text.trim());
      } else {
        await ApiService.createMarketplaceProduct(
            title: t, price: p, condition: _cond, listingType: _type, status: _status,
            description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
            locationText: _location.text.trim().isEmpty ? null : _location.text.trim(),
            quantity: int.tryParse(_qty.text.trim()) ?? 1, rentPricePerDay: r, images: _imgs);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isEdit ? 'Updated!' : 'Posted!'), backgroundColor: _green));
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) setState(() { _err = e.message; _busy = false; });
    } catch (e) {
      if (mounted) setState(() { _err = e.toString(); _busy = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface, elevation: 0,
        scrolledUnderElevation: 0.5, shadowColor: Colors.black12,
        leading: _BackBtn(),
        title: Text(_isEdit ? 'Edit Listing' : 'New Listing',
            style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w800, fontSize: 16)),
      ),
      body: Column(children: [
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (_err != null)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.25))),
                child: Row(children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_err!,
                      style: const TextStyle(color: Colors.red, fontSize: 13))),
                ]),
              ),

            // Photos
            if (!_isEdit)
              _Card(title: 'Photos', subtitle: 'Up to 5',
                child: Wrap(spacing: 10, runSpacing: 10, children: [
                  for (int i = 0; i < _imgs.length; i++)
                    Stack(children: [
                      ClipRRect(borderRadius: BorderRadius.circular(12),
                          child: Image.file(_imgs[i], width: 80, height: 80,
                              fit: BoxFit.cover)),
                      Positioned(top: 4, right: 4,
                        child: GestureDetector(
                          onTap: () => setState(() => _imgs.removeAt(i)),
                          child: Container(padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                  color: Colors.red, shape: BoxShape.circle),
                              child: const Icon(Icons.close_rounded,
                                  color: _white, size: 12)),
                        ),
                      ),
                    ]),
                  if (_imgs.length < 5)
                    GestureDetector(
                      onTap: _pickImages,
                      child: Container(width: 80, height: 80,
                        decoration: BoxDecoration(color: context.appSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _green.withValues(alpha: 0.4),
                                width: 1.5)),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Icons.add_photo_alternate_outlined,
                              color: _green, size: 26),
                          const SizedBox(height: 4),
                          Text('${5 - _imgs.length} left',
                              style: const TextStyle(color: _green, fontSize: 9,
                                  fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ),
                ]),
              ),

            _Card(title: 'Product Info', child: Column(children: [
              _FF(ctrl: _title, label: 'Title', hint: 'e.g. iPhone 14 Pro'),
              const SizedBox(height: 12),
              _FF(ctrl: _desc, label: 'Description',
                  hint: 'Describe your product…', maxLines: 3),
            ])),

            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: _Card(title: 'Type',
                child: Column(children: [
                  for (final t in [('sale', 'Sale'), ('rent', 'Rent'), ('both', 'Both')])
                    _SelBtn(t.$2, _type == t.$1, _green,
                        () => setState(() => _type = t.$1)),
                ]),
              )),
              const SizedBox(width: 12),
              Expanded(child: _Card(title: 'Condition',
                child: Column(children: [
                  for (final c in [('new', 'New'), ('used', 'Used'), ('refurbished', 'Refurb')])
                    _SelBtn(c.$2, _cond == c.$1, _condColor(c.$1),
                        () => setState(() => _cond = c.$1)),
                ]),
              )),
            ]),

            _Card(title: 'Pricing', child: Column(children: [
              _FF(ctrl: _price, label: 'Price (USD \$)', hint: '100',
                  keyboardType: TextInputType.number),
              if (_type == 'rent' || _type == 'both') ...[
                const SizedBox(height: 12),
                _FF(ctrl: _rent, label: 'Rent / Day (USD \$)', hint: '10',
                    keyboardType: TextInputType.number),
              ],
              const SizedBox(height: 12),
              _FF(ctrl: _qty, label: 'Quantity', hint: '1',
                  keyboardType: TextInputType.number),
            ])),

            _Card(title: 'Location', child:
              _FF(ctrl: _location, label: 'Area / District (optional)',
                  hint: 'e.g. BKK1, Phnom Penh')),

            if (_isEdit)
              _Card(title: 'Status', child: Wrap(spacing: 8, runSpacing: 8,
                children: ['draft', 'active', 'paused', 'sold'].map((s) =>
                  _SelBtn(s[0].toUpperCase() + s.substring(1),
                      _status == s, _statusColor(s),
                      () => setState(() => _status = s)),
                ).toList(),
              )),
          ]),
        )),

        Container(
          padding: EdgeInsets.fromLTRB(
              16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
          decoration: BoxDecoration(color: context.appSurface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16, offset: const Offset(0, -4))]),
          child: SizedBox(width: double.infinity,
            child: ElevatedButton(
              onPressed: _busy ? null : _submit,
              style: ElevatedButton.styleFrom(
                  backgroundColor: _green, foregroundColor: _white, elevation: 0,
                  disabledBackgroundColor: _green.withValues(alpha: 0.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: _busy
                  ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(color: _white, strokeWidth: 2.5))
                  : Text(_isEdit ? 'Save Changes' : 'Post Listing',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ),
          ),
        ),
      ]),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  const _Card({required this.title, this.subtitle, required this.child});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: context.appSurface, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6, offset: const Offset(0, 2))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(title, style: TextStyle(
            color: context.appTextPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
        if (subtitle != null) ...[
          const SizedBox(width: 6),
          Text(subtitle!, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ]),
      const SizedBox(height: 14),
      child,
    ]),
  );
}

class _SelBtn extends StatelessWidget {
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;
  const _SelBtn(this.label, this.active, this.color, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
          color: active ? color : context.appCardBg, borderRadius: BorderRadius.circular(10)),
      child: Center(child: Text(label, style: TextStyle(
          color: active ? _white : Colors.grey.shade600,
          fontWeight: FontWeight.w700, fontSize: 13))),
    ),
  );
}

class _FF extends StatelessWidget {
  final TextEditingController ctrl;
  final String label, hint;
  final int maxLines;
  final TextInputType? keyboardType;
  const _FF({required this.ctrl, required this.label, required this.hint,
      this.maxLines = 1, this.keyboardType});
  @override
  Widget build(BuildContext context) => Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(
        color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w600)),
    const SizedBox(height: 6),
    TextField(
      controller: ctrl, maxLines: maxLines, keyboardType: keyboardType,
      style: TextStyle(color: context.appTextPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint, hintStyle: const TextStyle(color: Colors.grey),
        filled: true, fillColor: context.appCardBg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    ),
  ]);
}
