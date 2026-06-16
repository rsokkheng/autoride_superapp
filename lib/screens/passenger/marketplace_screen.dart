import 'dart:io';
import 'package:flutter/material.dart';
import 'car_rental_screen.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/marketplace_model.dart';
import '../../services/api_service.dart';

// ── Tokens ─────────────────────────────────────────────────────────────────
const _green  = Color(0xFF00C48C);
const _green2 = Color(0xFF00A37A);
const _dark   = Color(0xFF1C1C1E);
const _gray   = Color(0xFFF2F4F3);
const _white  = Colors.white;

final _fmt = NumberFormat('#,###', 'en_US');
String _khr(int v) => '${_fmt.format(v)} ៛';

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
      Text(title, style: const TextStyle(
          color: _dark, fontWeight: FontWeight.w800, fontSize: 16)),
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
  void initState() { super.initState(); _tab = TabController(length: 3, vsync: this); }
  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _gray,
      appBar: AppBar(
        backgroundColor: _white,
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
                        color: _gray, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: _dark, size: 16),
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
          const Text('Marketplace', style: TextStyle(
              color: _dark, fontWeight: FontWeight.w800, fontSize: 18)),
        ]),
        actions: [
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const _PostProductScreen()))
                .then((_) => setState(() {})),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: _green,
                  borderRadius: BorderRadius.circular(10)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.add_rounded, color: _white, size: 16),
                SizedBox(width: 4),
                Text('Sell', style: TextStyle(color: _white,
                    fontWeight: FontWeight.w700, fontSize: 13)),
              ]),
            ),
          ),
        ],
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
            tabs: const [Tab(text: 'Browse'), Tab(text: 'My Listings'), Tab(text: 'My Orders')],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [_BrowseTab(), _MyListingsTab(), _MyOrdersTab()],
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
  List<MarketplaceCategoryModel> _cats = [];
  List<MarketplaceProductModel>  _prods = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });
    try {
      final r = await Future.wait([
        if (_cats.isEmpty) ApiService.getMarketplaceCategories(),
        ApiService.getMarketplaceProducts(),
      ]);
      if (!mounted) return;
      setState(() {
        if (_cats.isEmpty) _cats = r[0] as List<MarketplaceCategoryModel>;
        _prods  = r.last as List<MarketplaceProductModel>;
        _loading = false;
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
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const _AllListingsScreen())),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                decoration: BoxDecoration(
                  color: _white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Row(children: [
                  const Icon(Icons.search_rounded, color: Colors.grey, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Search products…',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 14))),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                        color: _green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.tune_rounded, color: _green, size: 16),
                  ),
                ]),
              ),
            ),
          ),

          // Hero banner
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_green, _green2],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(children: [
                // Decorative circles
                Positioned(right: -20, top: -30,
                  child: Container(width: 130, height: 130,
                    decoration: BoxDecoration(
                        color: _white.withValues(alpha: 0.08), shape: BoxShape.circle)),
                ),
                Positioned(right: 50, bottom: -40,
                  child: Container(width: 90, height: 90,
                    decoration: BoxDecoration(
                        color: _white.withValues(alpha: 0.06), shape: BoxShape.circle)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max, children: [
                    const Text('Find the best deals', style: TextStyle(
                        color: _white, fontWeight: FontWeight.w800, fontSize: 20)),
                    const SizedBox(height: 5),
                    Text('${_prods.length} listings available',
                        style: TextStyle(
                            color: _white.withValues(alpha: 0.85), fontSize: 13)),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const _AllListingsScreen())),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                            color: _white, borderRadius: BorderRadius.circular(10)),
                        child: const Text('Browse All',
                            style: TextStyle(color: _green,
                                fontWeight: FontWeight.w700, fontSize: 13)),
                      ),
                    ),
                  ]),
                ),
              ]),
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
                            color: _white,
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
                            style: const TextStyle(color: _dark, fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  );
                },
              ),
            ),
          ],

          // Services
          _SectionTitle('Services'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const CarRentalScreen())),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00838F), Color(0xFF006064)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: _white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.drive_eta_outlined, color: _white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Car Rental',
                          style: TextStyle(color: _white, fontSize: 16,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 3),
                      Text('Rent Economy, SUV & more',
                          style: TextStyle(color: _white.withValues(alpha: 0.8),
                              fontSize: 12)),
                    ]),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, color: _white, size: 16),
                ]),
              ),
            ),
          ),

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
          color: _white,
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
                  style: const TextStyle(color: _dark, fontWeight: FontWeight.w700,
                      fontSize: 12, height: 1.35)),
              const SizedBox(height: 6),
              Text(_khr(p.price), style: const TextStyle(
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
          color: _white,
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
                    style: const TextStyle(color: _dark, fontWeight: FontWeight.w700,
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
                  Text(_khr(p.price), style: const TextStyle(
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
  final _search = TextEditingController();
  List<MarketplaceCategoryModel> _cats  = [];
  List<MarketplaceProductModel>  _prods = [];
  bool    _loading = true;
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
    setState(() { _loading = true; _error = null; });
    try {
      final r = await Future.wait([
        if (_cats.isEmpty) ApiService.getMarketplaceCategories(),
        ApiService.getMarketplaceProducts(
          search:      _search.text.trim().isEmpty ? null : _search.text.trim(),
          categoryId:  _selCat,
          listingType: _type,
          condition:   _cond,
        ),
      ]);
      if (!mounted) return;
      setState(() {
        if (_cats.isEmpty) _cats = r[0] as List<MarketplaceCategoryModel>;
        _prods   = r.last as List<MarketplaceProductModel>;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  void dispose() { _search.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _gray,
      appBar: AppBar(
        backgroundColor: _white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: Colors.black12,
        leading: _BackBtn(),
        title: Text(widget.categoryName ?? 'All Listings',
            style: const TextStyle(color: _dark, fontWeight: FontWeight.w800, fontSize: 16)),
        actions: [
          IconButton(
            onPressed: () => setState(() => _grid = !_grid),
            icon: Icon(_grid ? Icons.view_list_rounded : Icons.grid_view_rounded,
                color: _dark, size: 22),
          ),
        ],
      ),
      body: Column(children: [
        // Search
        Container(
          color: _white,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: TextField(
            controller: _search,
            style: const TextStyle(color: _dark, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search listings…',
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey, size: 20),
              suffixIcon: _search.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.grey, size: 18),
                      onPressed: () { _search.clear(); _load(); })
                  : null,
              filled: true, fillColor: _gray,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        // Filter chips
        Container(
          color: _white,
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
            decoration: BoxDecoration(color: _gray, shape: BoxShape.circle),
            child: const Icon(Icons.search_off_rounded, color: Colors.grey, size: 44)),
        const SizedBox(height: 16),
        const Text('No listings found',
            style: TextStyle(color: _dark, fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 6),
        const Text('Try different filters',
            style: TextStyle(color: Colors.grey, fontSize: 13)),
      ]),
    );

    void open(MarketplaceProductModel p) => Navigator.push(
        context, MaterialPageRoute(
            builder: (_) => _ProductDetailScreen(product: p))).then((_) => _load());

    return RefreshIndicator(
      onRefresh: _load, color: _green,
      child: _grid
          ? GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14,
                  childAspectRatio: 0.72),
              itemCount: _prods.length,
              itemBuilder: (_, i) => _GridCard(
                  product: _prods[i], onTap: () => open(_prods[i])))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              itemCount: _prods.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ListCard(product: _prods[i], onTap: () => open(_prods[i])),
              )),
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
        color: active ? _green : _white,
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
      decoration: BoxDecoration(color: _gray, borderRadius: BorderRadius.circular(10)),
      child: const Icon(Icons.arrow_back_ios_new_rounded, color: _dark, size: 16),
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
      backgroundColor: _gray,
      body: Column(children: [
        Expanded(
          child: CustomScrollView(slivers: [
            // ── Image hero ─────────────────────────────────────
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              backgroundColor: _white,
              elevation: 0,
              automaticallyImplyLeading: false,
              leading: Padding(
                padding: const EdgeInsets.all(8),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: _dark, size: 17),
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
                        color: _white, shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: Icon(
                          _saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                          color: _saved ? _green : _dark, size: 20),
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
                  decoration: BoxDecoration(color: _white,
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
                        style: const TextStyle(color: _dark, fontWeight: FontWeight.w800,
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
                          Text(_khr(_p.price),
                              style: const TextStyle(color: _green,
                                  fontWeight: FontWeight.w800, fontSize: 22)),
                        ],
                        if (canRent && _p.rentPricePerDay != null) ...[
                          const SizedBox(height: 4),
                          const Text('Rent / day',
                              style: TextStyle(color: Colors.grey, fontSize: 11)),
                          Text(_khr(_p.rentPricePerDay!),
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
                              color: _gray, borderRadius: BorderRadius.circular(10)),
                          child: Text('Qty: ${_p.quantity}',
                              style: const TextStyle(color: _dark,
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
                        Text(_p.sellerName!, style: const TextStyle(
                            color: _dark, fontWeight: FontWeight.w700, fontSize: 14)),
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
                            color: Colors.grey, fontSize: 13, height: 1.6)),
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
                      _SpecCell('Per Day', _khr(_p.rentPricePerDay!)),
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
            color: _white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16, offset: const Offset(0, -4))],
          ),
          child: _isOwner
              ? Row(children: [
                  Expanded(child: _CTA(
                    label: 'Edit Listing', icon: Icons.edit_rounded,
                    color: _green,
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => _PostProductScreen(existing: _p)))
                        .then((_) => _loadDetail()),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _CTA(
                    label: 'My Listings', icon: Icons.storefront_rounded,
                    color: _dark,
                    onTap: () => Navigator.pop(context),
                  )),
                ])
              : Row(children: [
                  if (canSell) Expanded(child: _CTA(
                    label: 'Buy Now', icon: Icons.shopping_bag_rounded,
                    color: _green,
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => _OrderScreen(product: _p, orderType: 'purchase'))),
                  )),
                  if (canSell && canRent) const SizedBox(width: 10),
                  if (canRent) Expanded(child: _CTA(
                    label: 'Rent', icon: Icons.key_rounded,
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
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: _white, borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(color: _dark,
          fontWeight: FontWeight.w800, fontSize: 14)),
      const SizedBox(height: 12),
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
        rows.add(Row(children: [a, const SizedBox(width: 10), b]));
        if (i + 2 < cells.length) rows.add(const SizedBox(height: 10));
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: _gray, borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(
              color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _dark, fontWeight: FontWeight.w700,
                  fontSize: 13, height: 1.3)),
        ]),
      );
    });
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Order Screen
// ══════════════════════════════════════════════════════════════════════════════

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
  DateTime _start = DateTime.now().add(const Duration(days: 1));
  DateTime _end   = DateTime.now().add(const Duration(days: 4));
  bool    _busy = false;
  String? _err;

  bool get _isRent => widget.orderType == 'rent';
  int  get _days   => _end.difference(_start).inDays.clamp(1, 365);
  int  get _total  {
    if (_isRent && widget.product.rentPricePerDay != null) {
      return widget.product.rentPricePerDay! * _days * _qty;
    }
    return widget.product.price * _qty;
  }
  Color get _color => _isRent ? const Color(0xFF7C3AED) : _green;

  @override
  void dispose() { _notes.dispose(); super.dispose(); }

  Future<void> _pickDate(bool isStart) async {
    final now   = DateTime.now();
    final first = isStart ? now.add(const Duration(days: 1))
        : _start.add(const Duration(days: 1));
    final picked = await showDatePicker(context: context,
        initialDate: isStart ? _start : _end,
        firstDate: first, lastDate: now.add(const Duration(days: 365)));
    if (picked == null || !mounted) return;
    setState(() {
      if (isStart) {
        _start = picked;
        if (_end.isBefore(picked.add(const Duration(days: 1)))) {
          _end = picked.add(const Duration(days: 1));
        }
      } else { _end = picked; }
    });
  }

  Future<void> _submit() async {
    setState(() { _busy = true; _err = null; });
    try {
      await ApiService.placeMarketplaceOrder(widget.product.id,
        orderType:     widget.orderType,
        quantity:      _qty,
        paymentMethod: _pay,
        notes:         _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        rentStartDate: _isRent ? DateFormat('yyyy-MM-dd').format(_start) : null,
        rentEndDate:   _isRent ? DateFormat('yyyy-MM-dd').format(_end)   : null,
      );
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

  static const _pays = [
    ('cash',         'Cash',   Icons.money_rounded),
    ('aba',          'ABA',    Icons.account_balance_rounded),
    ('wing',         'Wing',   Icons.account_balance_wallet_rounded),
    ('wallet',       'Wallet', Icons.wallet_rounded),
    ('other_online', 'Online', Icons.phone_android_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    return Scaffold(
      backgroundColor: _gray,
      appBar: AppBar(
        backgroundColor: _white, elevation: 0,
        scrolledUnderElevation: 0.5, shadowColor: Colors.black12,
        leading: _BackBtn(),
        title: Text(_isRent ? 'Rent Item' : 'Buy Item',
            style: const TextStyle(color: _dark, fontWeight: FontWeight.w800, fontSize: 16)),
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
              decoration: BoxDecoration(color: _white, borderRadius: BorderRadius.circular(16),
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
                      style: const TextStyle(color: _dark, fontWeight: FontWeight.w700,
                          fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(
                    _isRent && p.rentPricePerDay != null
                        ? '${_khr(p.rentPricePerDay!)}/day' : _khr(p.price),
                    style: TextStyle(color: _color, fontWeight: FontWeight.w700,
                        fontSize: 13)),
                ])),
              ]),
            ),
            const SizedBox(height: 16),

            // Rental dates
            if (_isRent) ...[
              _FormLabel('Rental Dates'),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _DateTile('Start', _start, () => _pickDate(true))),
                const SizedBox(width: 12),
                Expanded(child: _DateTile('End', _end, () => _pickDate(false))),
              ]),
              const SizedBox(height: 8),
              Center(child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: _color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10)),
                child: Text('$_days day${_days == 1 ? '' : 's'} selected',
                    style: TextStyle(color: _color, fontWeight: FontWeight.w700, fontSize: 13)),
              )),
              const SizedBox(height: 16),
            ],

            // Quantity
            _FormLabel('Quantity'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: _white, borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6)]),
              child: Row(children: [
                _QtyBtn(Icons.remove_rounded, _qty > 1, _color,
                    () { if (_qty > 1) setState(() => _qty--); }),
                Expanded(child: Center(
                    child: Text('$_qty', style: const TextStyle(
                        color: _dark, fontSize: 22, fontWeight: FontWeight.w800)))),
                _QtyBtn(Icons.add_rounded, _qty < p.quantity, _color,
                    () { if (_qty < p.quantity) setState(() => _qty++); }),
                const SizedBox(width: 10),
                Text('of ${p.quantity}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ]),
            ),
            const SizedBox(height: 16),

            // Payment
            _FormLabel('Payment Method'),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 3, shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 2.2,
              children: _pays.map((o) {
                final active = _pay == o.$1;
                return GestureDetector(
                  onTap: () => setState(() => _pay = o.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: active ? _color : _white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: active ? _color : const Color(0xFFE0E0E0), width: 1.5),
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(o.$3, color: active ? _white : Colors.grey, size: 16),
                      const SizedBox(height: 3),
                      Text(o.$2, style: TextStyle(
                          color: active ? _white : Colors.grey,
                          fontSize: 10, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Notes
            _FormLabel('Notes (optional)'),
            const SizedBox(height: 10),
            TextField(
              controller: _notes, maxLines: 2,
              style: const TextStyle(color: _dark, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Any special instructions…',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true, fillColor: _white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 16),

            // Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: _white, borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8)]),
              child: Column(children: [
                if (!_isRent) _SumRow('Unit price', _khr(p.price)),
                if (!_isRent && _qty > 1) _SumRow('× $_qty items', _khr(p.price * _qty)),
                if (_isRent && p.rentPricePerDay != null) ...[
                  _SumRow('${_khr(p.rentPricePerDay!)} × $_days days',
                      _khr(p.rentPricePerDay! * _days)),
                  if (_qty > 1) _SumRow('× $_qty items',
                      _khr(p.rentPricePerDay! * _days * _qty)),
                ],
                Divider(color: _gray, height: 20, thickness: 1.5),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Total', style: TextStyle(
                      color: _dark, fontSize: 15, fontWeight: FontWeight.w700)),
                  Text(_khr(_total), style: TextStyle(
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
            color: _white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16, offset: const Offset(0, -4))],
          ),
          child: SizedBox(width: double.infinity,
            child: ElevatedButton(
              onPressed: _busy ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _color, foregroundColor: _white, elevation: 0,
                disabledBackgroundColor: _color.withValues(alpha: 0.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _busy
                  ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(color: _white, strokeWidth: 2.5))
                  : Text(
                      _isRent ? 'Confirm Rental — ${_khr(_total)}'
                          : 'Place Order — ${_khr(_total)}',
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
      style: const TextStyle(color: _dark, fontWeight: FontWeight.w700, fontSize: 14));
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
          color: active ? color.withValues(alpha: 0.1) : _gray,
          borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: active ? color : Colors.grey, size: 20)),
  );
}

class _DateTile extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;
  const _DateTile(this.label, this.date, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _white, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE0E0E0))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(
            color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 5),
        Text(DateFormat('dd MMM yyyy').format(date),
            style: const TextStyle(color: _dark, fontWeight: FontWeight.w700, fontSize: 13)),
      ]),
    ),
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
      Text(amount, style: const TextStyle(
          color: _dark, fontWeight: FontWeight.w600, fontSize: 13)),
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
        backgroundColor: _white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete listing?',
            style: TextStyle(color: _dark, fontWeight: FontWeight.w700)),
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
        const Text("No listings yet",
            style: TextStyle(color: _dark, fontWeight: FontWeight.w700, fontSize: 17)),
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
            decoration: BoxDecoration(color: _white, borderRadius: BorderRadius.circular(16),
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
                      style: const TextStyle(color: _dark, fontWeight: FontWeight.w700,
                          fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(_khr(p.price), style: const TextStyle(
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
      final r = await Future.wait([
        ApiService.getMyMarketplaceOrders(type: 'buying'),
        ApiService.getMyMarketplaceOrders(type: 'selling'),
      ]);
      if (mounted) setState(() {
        _buying = r[0]; _selling = r[1]; _loading = false;
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
        color: _white,
        child: TabBar(
          controller: _tc,
          indicatorColor: _green, indicatorWeight: 3,
          labelColor: _green, unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: [
            Tab(text: 'Buying (${_buying.length})'),
            Tab(text: 'Selling (${_selling.length})'),
          ],
        ),
      ),
      Expanded(child: TabBarView(controller: _tc, children: [
        _OrderList(orders: _buying,  isSeller: false, onAction: _action, onRefresh: _load),
        _OrderList(orders: _selling, isSeller: true,  onAction: _action, onRefresh: _load),
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
    final o  = order;
    final sc = _statusColor(o.status);
    final isRent = o.orderType == 'rent';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: _white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: (isRent ? const Color(0xFF7C3AED) : _green).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(isRent ? Icons.key_rounded : Icons.shopping_bag_rounded,
                  color: isRent ? const Color(0xFF7C3AED) : _green, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(o.productTitle ?? 'Order #${o.id}',
                  style: const TextStyle(color: _dark, fontWeight: FontWeight.w700,
                      fontSize: 13)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: sc.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(o.status[0].toUpperCase() + o.status.substring(1),
                  style: TextStyle(color: sc, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ]),
        ),
        Divider(height: 1, color: _gray),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.inventory_2_rounded, color: Colors.grey, size: 13),
              const SizedBox(width: 5),
              Text('Qty: ${o.quantity}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
              if (o.rentStartDate != null) ...[
                const SizedBox(width: 12),
                const Icon(Icons.date_range_rounded, color: Colors.grey, size: 13),
                const SizedBox(width: 5),
                Text('${o.rentStartDate} → ${o.rentEndDate}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ]),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Total', style: TextStyle(color: Colors.grey, fontSize: 12)),
              Text(_khr(o.total), style: const TextStyle(
                  color: _green, fontWeight: FontWeight.w800, fontSize: 17)),
            ]),
          ]),
        ),
        if (o.status == 'pending' || o.status == 'confirmed') ...[
          Divider(height: 1, color: _gray),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Row(children: [
              if (isSeller && o.status == 'pending') ...[
                Expanded(child: _OrdBtn('Confirm', _green,
                    Icons.check_circle_outline_rounded, () => onAction(o, 'confirm'))),
                const SizedBox(width: 8),
              ],
              Expanded(child: _OrdBtn('Complete', const Color(0xFF007AFF),
                  Icons.task_alt_rounded, () => onAction(o, 'complete'))),
              const SizedBox(width: 8),
              Expanded(child: _OrdBtn('Cancel', Colors.red,
                  Icons.cancel_outlined, () => onAction(o, 'cancel'))),
            ]),
          ),
        ],
      ]),
    );
  }
}

class _OrdBtn extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  const _OrdBtn(this.label, this.color, this.icon, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25))),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
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
    final p = int.tryParse(_price.text.trim());
    if (t.isEmpty) { setState(() => _err = 'Title is required.'); return; }
    if (p == null) { setState(() => _err = 'Price must be a number.'); return; }
    final r = int.tryParse(_rent.text.trim());
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
      backgroundColor: _gray,
      appBar: AppBar(
        backgroundColor: _white, elevation: 0,
        scrolledUnderElevation: 0.5, shadowColor: Colors.black12,
        leading: _BackBtn(),
        title: Text(_isEdit ? 'Edit Listing' : 'New Listing',
            style: const TextStyle(color: _dark, fontWeight: FontWeight.w800, fontSize: 16)),
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
                        decoration: BoxDecoration(color: _white,
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
              _FF(ctrl: _price, label: 'Price (KHR ៛)', hint: '1,500,000',
                  keyboardType: TextInputType.number),
              if (_type == 'rent' || _type == 'both') ...[
                const SizedBox(height: 12),
                _FF(ctrl: _rent, label: 'Rent / Day (KHR ៛)', hint: '50,000',
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
          decoration: BoxDecoration(color: _white,
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
    decoration: BoxDecoration(color: _white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6, offset: const Offset(0, 2))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(title, style: const TextStyle(
            color: _dark, fontWeight: FontWeight.w700, fontSize: 14)),
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
          color: active ? color : _gray, borderRadius: BorderRadius.circular(10)),
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
      style: const TextStyle(color: _dark, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint, hintStyle: const TextStyle(color: Colors.grey),
        filled: true, fillColor: _gray,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    ),
  ]);
}
