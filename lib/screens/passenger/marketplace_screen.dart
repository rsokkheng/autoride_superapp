import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:autoride_superapp/theme/app_theme.dart';
import 'package:autoride_superapp/widgets/common_widgets.dart';
import '../../models/marketplace_model.dart';
import '../../services/api_service.dart';

// ── Helpers ────────────────────────────────────────────────────────────────

final _khr = NumberFormat('#,###', 'en_US');
String _fmtKhr(int amount) => '${_khr.format(amount)} ៛';

Color _conditionColor(String? c) => switch (c) {
  'new'         => AppTheme.success,
  'refurbished' => AppTheme.accent,
  _             => AppTheme.gold,
};

Color _statusColor(String s) => switch (s) {
  'active'    => AppTheme.success,
  'paused'    => AppTheme.gold,
  'sold'      => AppTheme.accent,
  'draft'     => AppTheme.textSecondary,
  'pending'   => AppTheme.gold,
  'confirmed' => AppTheme.accent,
  'completed' => AppTheme.success,
  'cancelled' => AppTheme.danger,
  _           => AppTheme.textSecondary,
};

// ── Main Screen ────────────────────────────────────────────────────────────

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});
  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        title: const Text('Marketplace',
            style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined, color: AppTheme.accent),
            tooltip: 'Post a product',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const _PostProductScreen()),
            ).then((_) => setState(() {})),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          indicatorColor: AppTheme.accent,
          labelColor: AppTheme.accent,
          unselectedLabelColor: AppTheme.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(text: 'Browse'),
            Tab(text: 'My Listings'),
            Tab(text: 'My Orders'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          _BrowseTab(),
          _MyListingsTab(),
          _MyOrdersTab(),
        ],
      ),
    );
  }
}

// ── Browse Tab ─────────────────────────────────────────────────────────────

class _BrowseTab extends StatefulWidget {
  const _BrowseTab();
  @override
  State<_BrowseTab> createState() => _BrowseTabState();
}

class _BrowseTabState extends State<_BrowseTab> {
  final _searchCtrl = TextEditingController();

  List<MarketplaceCategoryModel> _categories = [];
  List<MarketplaceProductModel>  _products   = [];
  bool   _loading   = true;
  String? _error;

  int?    _selectedCategory;
  String? _listingType;  // null = all | sale | rent | both
  String? _condition;    // null = all | new | used | refurbished

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(() => _debounceSearch());
  }

  DateTime? _lastSearch;
  void _debounceSearch() {
    _lastSearch = DateTime.now();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (DateTime.now().difference(_lastSearch!) >= const Duration(milliseconds: 480)) {
        _load();
      }
    });
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        if (_categories.isEmpty) ApiService.getMarketplaceCategories(),
        ApiService.getMarketplaceProducts(
          search:      _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
          categoryId:  _selectedCategory,
          listingType: _listingType,
          condition:   _condition,
        ),
      ]);
      if (!mounted) return;
      setState(() {
        if (_categories.isEmpty) _categories = results[0] as List<MarketplaceCategoryModel>;
        _products = results.last as List<MarketplaceProductModel>;
        _loading  = false;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Search bar
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: TextField(
          controller: _searchCtrl,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'Search products…',
            hintStyle: const TextStyle(color: AppTheme.textSecondary),
            prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.textSecondary, size: 18),
                    onPressed: () { _searchCtrl.clear(); _load(); },
                  )
                : null,
            filled: true,
            fillColor: AppTheme.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
      // Filter chips
      _FilterBar(
        categories:      _categories,
        selectedCategory: _selectedCategory,
        listingType:     _listingType,
        condition:       _condition,
        onCategoryChanged: (v) { setState(() => _selectedCategory = v); _load(); },
        onListingTypeChanged: (v) { setState(() => _listingType = v); _load(); },
        onConditionChanged: (v) { setState(() => _condition = v); _load(); },
      ),
      // Results
      Expanded(child: _buildBody()),
    ]);
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppTheme.accent));
    if (_error != null) return Center(child: Text(_error!, style: const TextStyle(color: AppTheme.danger)));
    if (_products.isEmpty) {
      return const Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.storefront_outlined, color: AppTheme.textSecondary, size: 56),
          SizedBox(height: 12),
          Text('No products found', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 16)),
          SizedBox(height: 6),
          Text('Try adjusting your filters', style: TextStyle(color: AppTheme.textSecondary)),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AppTheme.accent,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        itemCount: _products.length,
        itemBuilder: (_, i) => _ProductCard(
          product: _products[i],
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => _ProductDetailScreen(product: _products[i])),
          ).then((_) => _load()),
        ),
      ),
    );
  }
}

// ── Filter Bar ──────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final List<MarketplaceCategoryModel> categories;
  final int?    selectedCategory;
  final String? listingType;
  final String? condition;
  final ValueChanged<int?>    onCategoryChanged;
  final ValueChanged<String?> onListingTypeChanged;
  final ValueChanged<String?> onConditionChanged;

  const _FilterBar({
    required this.categories,
    required this.selectedCategory,
    required this.listingType,
    required this.condition,
    required this.onCategoryChanged,
    required this.onListingTypeChanged,
    required this.onConditionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Row(children: [
        // All products chip
        _Chip(
          label: 'All',
          active: selectedCategory == null && listingType == null && condition == null,
          onTap: () {
            onCategoryChanged(null);
            onListingTypeChanged(null);
            onConditionChanged(null);
          },
        ),
        const SizedBox(width: 8),
        // Listing type chips
        for (final type in ['sale', 'rent']) ...[
          _Chip(
            label: type == 'sale' ? 'For Sale' : 'For Rent',
            active: listingType == type,
            color: type == 'rent' ? AppTheme.accent : AppTheme.success,
            onTap: () => onListingTypeChanged(listingType == type ? null : type),
          ),
          const SizedBox(width: 8),
        ],
        // Condition chips
        for (final cond in ['new', 'used', 'refurbished']) ...[
          _Chip(
            label: cond[0].toUpperCase() + cond.substring(1),
            active: condition == cond,
            color: _conditionColor(cond),
            onTap: () => onConditionChanged(condition == cond ? null : cond),
          ),
          const SizedBox(width: 8),
        ],
        // Category chips
        for (final cat in categories) ...[
          _Chip(
            label: cat.name,
            active: selectedCategory == cat.id,
            onTap: () => onCategoryChanged(selectedCategory == cat.id ? null : cat.id),
          ),
          const SizedBox(width: 8),
        ],
      ]),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.active,
    this.color = AppTheme.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? color : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? color : AppTheme.surface),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : AppTheme.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

// ── Product Card ────────────────────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  final MarketplaceProductModel product;
  final VoidCallback onTap;

  const _ProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = product;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(18)),
            child: SizedBox(
              width: 110,
              height: 110,
              child: p.images.isNotEmpty
                  ? Image.network(p.images.first, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _PlaceholderImg())
                  : _PlaceholderImg(),
            ),
          ),
          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
                const SizedBox(height: 6),
                Text(_fmtKhr(p.price),
                    style: const TextStyle(
                        color: AppTheme.accent, fontWeight: FontWeight.w800, fontSize: 15)),
                if (p.rentPricePerDay != null && p.listingType != 'sale')
                  Text('${_fmtKhr(p.rentPricePerDay!)}/day',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                const SizedBox(height: 8),
                Wrap(spacing: 6, runSpacing: 4, children: [
                  if (p.condition != null)
                    _Badge(label: p.condition!, color: _conditionColor(p.condition)),
                  if (p.listingType != 'sale')
                    _Badge(label: p.listingType == 'rent' ? 'Rent' : 'Sale & Rent',
                        color: AppTheme.accent),
                  if (p.locationText != null)
                    _Badge(
                        label: p.locationText!.length > 20
                            ? '${p.locationText!.substring(0, 20)}…'
                            : p.locationText!,
                        color: AppTheme.textSecondary,
                        icon: Icons.location_on_outlined),
                ]),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

class _PlaceholderImg extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    color: AppTheme.cardBg,
    child: const Center(child: Icon(Icons.image_outlined, color: AppTheme.textSecondary, size: 32)),
  );
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const _Badge({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, color: color, size: 11), const SizedBox(width: 3)],
        Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

// ── Product Detail Screen ──────────────────────────────────────────────────

class _ProductDetailScreen extends StatefulWidget {
  final MarketplaceProductModel product;
  const _ProductDetailScreen({required this.product});

  @override
  State<_ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<_ProductDetailScreen> {
  late MarketplaceProductModel _product;
  bool _loading = true;
  int  _imgIndex = 0;
  late PageController _pageCtrl;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    _pageCtrl = PageController();
    _loadDetail();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    try {
      final detail = await ApiService.getMarketplaceProduct(_product.id);
      if (mounted) setState(() { _product = detail; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _product;
    final canSell = p.listingType == 'sale' || p.listingType == 'both';
    final canRent = p.listingType == 'rent' || p.listingType == 'both';

    return Scaffold(
      backgroundColor: AppTheme.primary,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        title: Text(p.title,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
      ),
      body: Column(children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Images
              SizedBox(
                height: 240,
                child: Stack(children: [
                  p.images.isNotEmpty
                      ? PageView.builder(
                          controller: _pageCtrl,
                          itemCount: p.images.length,
                          onPageChanged: (i) => setState(() => _imgIndex = i),
                          itemBuilder: (_, i) => Image.network(p.images[i],
                              fit: BoxFit.cover, width: double.infinity,
                              errorBuilder: (_, __, ___) => Container(
                                color: AppTheme.cardBg,
                                child: const Center(child: Icon(Icons.image_outlined,
                                    color: AppTheme.textSecondary, size: 56)),
                              )),
                        )
                      : Container(
                          color: AppTheme.cardBg,
                          child: const Center(child: Icon(Icons.image_outlined,
                              color: AppTheme.textSecondary, size: 72)),
                        ),
                  if (p.images.length > 1)
                    Positioned(
                      bottom: 12, left: 0, right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(p.images.length, (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: _imgIndex == i ? 18 : 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: _imgIndex == i ? AppTheme.accent : AppTheme.textSecondary.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        )),
                      ),
                    ),
                  if (_loading)
                    const Positioned.fill(
                      child: Center(child: CircularProgressIndicator(color: AppTheme.accent)),
                    ),
                ]),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Title + price
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(p.title,
                            style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.w800)),
                        if (p.categoryName != null)
                          Text(p.categoryName!,
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      ]),
                    ),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      if (canSell)
                        Text(_fmtKhr(p.price),
                            style: const TextStyle(
                                color: AppTheme.accent,
                                fontSize: 20,
                                fontWeight: FontWeight.w800)),
                      if (canRent && p.rentPricePerDay != null)
                        Text('${_fmtKhr(p.rentPricePerDay!)}/day',
                            style: const TextStyle(
                                color: AppTheme.gold, fontSize: 14, fontWeight: FontWeight.w600)),
                    ]),
                  ]),
                  const SizedBox(height: 12),

                  // Badges row
                  Wrap(spacing: 8, runSpacing: 6, children: [
                    if (p.condition != null)
                      _Badge(label: p.condition![0].toUpperCase() + p.condition!.substring(1),
                          color: _conditionColor(p.condition)),
                    _Badge(
                        label: p.listingType == 'sale' ? 'For Sale' : p.listingType == 'rent' ? 'For Rent' : 'Sale & Rent',
                        color: AppTheme.accent),
                    _Badge(label: '${p.viewsCount} views', color: AppTheme.textSecondary, icon: Icons.visibility_outlined),
                    if (p.quantity > 1)
                      _Badge(label: 'Qty: ${p.quantity}', color: AppTheme.textSecondary),
                  ]),
                  const SizedBox(height: 16),

                  // Description
                  if (p.description != null && p.description!.isNotEmpty) ...[
                    const SectionHeader(title: 'Description'),
                    const SizedBox(height: 8),
                    Text(p.description!,
                        style: const TextStyle(
                            color: AppTheme.textSecondary, height: 1.6, fontSize: 13)),
                    const SizedBox(height: 16),
                  ],

                  // Location
                  if (p.locationText != null) ...[
                    const SectionHeader(title: 'Location'),
                    const SizedBox(height: 8),
                    Row(children: [
                      const Icon(Icons.location_on_outlined, color: AppTheme.accent, size: 16),
                      const SizedBox(width: 6),
                      Expanded(child: Text(p.locationText!,
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
                    ]),
                    const SizedBox(height: 16),
                  ],

                  // Seller info
                  if (p.sellerName != null) ...[
                    const SectionHeader(title: 'Seller'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(children: [
                        CircleAvatar(
                          backgroundColor: AppTheme.accent.withValues(alpha: 0.2),
                          radius: 20,
                          child: Text(
                            p.sellerName![0].toUpperCase(),
                            style: const TextStyle(
                                color: AppTheme.accent, fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(p.sellerName!,
                            style: const TextStyle(
                                color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                    const SizedBox(height: 8),
                  ],
                ]),
              ),
            ]),
          ),
        ),

        // Sticky bottom buttons
        Container(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + MediaQuery.of(context).padding.bottom),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.15))),
          ),
          child: Row(children: [
            if (canSell) Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _openOrder(context, 'purchase'),
                icon: const Icon(Icons.shopping_cart_outlined, size: 18),
                label: const Text('Buy', style: TextStyle(fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            if (canSell && canRent) const SizedBox(width: 10),
            if (canRent) Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _openOrder(context, 'rent'),
                icon: const Icon(Icons.key_outlined, size: 18),
                label: const Text('Rent', style: TextStyle(fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.gold,
                  foregroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  void _openOrder(BuildContext ctx, String orderType) {
    Navigator.push(ctx, MaterialPageRoute(
      builder: (_) => _OrderScreen(product: _product, orderType: orderType),
    ));
  }
}

// ── Order Screen ───────────────────────────────────────────────────────────

class _OrderScreen extends StatefulWidget {
  final MarketplaceProductModel product;
  final String orderType; // purchase | rent

  const _OrderScreen({required this.product, required this.orderType});

  @override
  State<_OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<_OrderScreen> {
  int    _quantity     = 1;
  String _paymentMethod = 'cash';
  final  _notesCtrl   = TextEditingController();

  DateTime _rentStart = DateTime.now().add(const Duration(days: 1));
  DateTime _rentEnd   = DateTime.now().add(const Duration(days: 4));

  bool   _submitting = false;
  String? _error;

  bool get _isRent => widget.orderType == 'rent';
  int  get _rentDays => _rentEnd.difference(_rentStart).inDays.clamp(1, 365);

  int get _total {
    if (_isRent && widget.product.rentPricePerDay != null) {
      return widget.product.rentPricePerDay! * _rentDays * _quantity;
    }
    return widget.product.price * _quantity;
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() { _submitting = true; _error = null; });
    try {
      await ApiService.placeMarketplaceOrder(
        widget.product.id,
        orderType:     widget.orderType,
        quantity:      _quantity,
        paymentMethod: _paymentMethod,
        notes:         _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        rentStartDate: _isRent ? DateFormat('yyyy-MM-dd').format(_rentStart) : null,
        rentEndDate:   _isRent ? DateFormat('yyyy-MM-dd').format(_rentEnd)   : null,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order placed successfully!'), backgroundColor: AppTheme.success),
      );
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _submitting = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _submitting = false; });
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initial  = isStart ? _rentStart : _rentEnd;
    final first    = isStart ? now.add(const Duration(days: 1)) : _rentStart.add(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isStart) {
        _rentStart = picked;
        if (_rentEnd.isBefore(picked.add(const Duration(days: 1)))) {
          _rentEnd = picked.add(const Duration(days: 1));
        }
      } else {
        _rentEnd = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    return Scaffold(
      backgroundColor: AppTheme.primary,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        title: Text(_isRent ? 'Rent: ${p.title}' : 'Buy: ${p.title}',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
      ),
      body: Column(children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.danger.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.danger.withValues(alpha: 0.4)),
                  ),
                  child: Text(_error!, style: const TextStyle(color: AppTheme.danger, fontSize: 13)),
                ),
              ],

              // Dates (rent only)
              if (_isRent) ...[
                const SectionHeader(title: 'Rental Dates'),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _DateCard(
                    label: 'Start',
                    date: _rentStart,
                    onTap: () => _pickDate(isStart: true),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _DateCard(
                    label: 'End',
                    date: _rentEnd,
                    onTap: () => _pickDate(isStart: false),
                  )),
                ]),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.date_range_outlined, color: AppTheme.accent, size: 16),
                    const SizedBox(width: 6),
                    Text('$_rentDays day${_rentDays == 1 ? '' : 's'}',
                        style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w700)),
                  ]),
                ),
                const SizedBox(height: 20),
              ],

              // Quantity
              const SectionHeader(title: 'Quantity'),
              const SizedBox(height: 12),
              Row(children: [
                IconButton(
                  onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                  icon: const Icon(Icons.remove_circle_outline, color: AppTheme.accent),
                ),
                Text('$_quantity',
                    style: const TextStyle(
                        color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
                IconButton(
                  onPressed: _quantity < p.quantity
                      ? () => setState(() => _quantity++)
                      : null,
                  icon: const Icon(Icons.add_circle_outline, color: AppTheme.accent),
                ),
                Text('(max ${p.quantity})', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ]),
              const SizedBox(height: 20),

              // Payment method
              const SectionHeader(title: 'Payment Method'),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8,
                children: ['cash', 'aba', 'wing', 'wallet', 'other_online'].map((m) =>
                  GestureDetector(
                    onTap: () => setState(() => _paymentMethod = m),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _paymentMethod == m ? AppTheme.accent : AppTheme.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: _paymentMethod == m ? AppTheme.accent : AppTheme.surface),
                      ),
                      child: Text(
                        m[0].toUpperCase() + m.substring(1),
                        style: TextStyle(
                          color: _paymentMethod == m ? Colors.white : AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ).toList(),
              ),
              const SizedBox(height: 20),

              // Notes
              const SectionHeader(title: 'Notes (optional)'),
              const SizedBox(height: 8),
              TextField(
                controller: _notesCtrl,
                maxLines: 2,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Any special instructions…',
                  hintStyle: const TextStyle(color: AppTheme.textSecondary),
                  filled: true,
                  fillColor: AppTheme.surface,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),

              // Price summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: AppTheme.surface, borderRadius: BorderRadius.circular(16)),
                child: Column(children: [
                  if (!_isRent)
                    _PriceRow('${_fmtKhr(p.price)} × $_quantity', _fmtKhr(p.price * _quantity)),
                  if (_isRent && p.rentPricePerDay != null) ...[
                    _PriceRow('${_fmtKhr(p.rentPricePerDay!)} × $_rentDays days',
                        _fmtKhr(p.rentPricePerDay! * _rentDays)),
                    if (_quantity > 1)
                      _PriceRow('× $_quantity items', _fmtKhr(p.rentPricePerDay! * _rentDays * _quantity)),
                  ],
                  const Divider(color: AppTheme.cardBg, height: 20),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Total',
                        style: TextStyle(
                            color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
                    Text(_fmtKhr(_total),
                        style: const TextStyle(
                            color: AppTheme.accent, fontSize: 20, fontWeight: FontWeight.w800)),
                  ]),
                ]),
              ),
            ]),
          ),
        ),

        // Confirm button
        Container(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + MediaQuery.of(context).padding.bottom),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.15))),
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isRent ? AppTheme.gold : AppTheme.accent,
                foregroundColor: _isRent ? AppTheme.primary : Colors.white,
                disabledBackgroundColor: AppTheme.accent.withValues(alpha: 0.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _submitting
                  ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : Text(
                      _isRent
                          ? 'Confirm Rental — ${_fmtKhr(_total)}'
                          : 'Place Order — ${_fmtKhr(_total)}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            ),
          ),
        ),
      ]),
    );
  }
}

class _DateCard extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  const _DateCard({required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          const SizedBox(height: 4),
          Text(DateFormat('dd MMM yyyy').format(date),
              style: const TextStyle(
                  color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
        ]),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label, amount;
  const _PriceRow(this.label, this.amount);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        Text(amount, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
      ]),
    );
  }
}

// ── My Listings Tab ────────────────────────────────────────────────────────

class _MyListingsTab extends StatefulWidget {
  const _MyListingsTab();
  @override
  State<_MyListingsTab> createState() => _MyListingsTabState();
}

class _MyListingsTabState extends State<_MyListingsTab> {
  List<MarketplaceProductModel> _products = [];
  bool    _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await ApiService.getMyMarketplaceProducts();
      if (mounted) setState(() { _products = list; _loading = false; });
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _delete(MarketplaceProductModel p) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Delete product?', style: TextStyle(color: AppTheme.textPrimary)),
        content: Text('${p.title} will be permanently deleted.',
            style: const TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary))),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: AppTheme.danger))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ApiService.deleteMarketplaceProduct(p.id);
      _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppTheme.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppTheme.accent));
    if (_error != null) return Center(child: Text(_error!, style: const TextStyle(color: AppTheme.danger)));
    if (_products.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.add_box_outlined, color: AppTheme.textSecondary, size: 56),
          const SizedBox(height: 12),
          const Text("You haven't listed anything yet",
              style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const _PostProductScreen()))
                .then((_) => _load()),
            icon: const Icon(Icons.add),
            label: const Text('Post a Product'),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent, foregroundColor: Colors.white),
          ),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AppTheme.accent,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _products.length,
        itemBuilder: (_, i) {
          final p = _products[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 64, height: 64,
                  child: p.images.isNotEmpty
                      ? Image.network(p.images.first, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppTheme.cardBg,
                            child: const Icon(Icons.image_outlined, color: AppTheme.textSecondary),
                          ))
                      : Container(
                          color: AppTheme.cardBg,
                          child: const Icon(Icons.image_outlined, color: AppTheme.textSecondary)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(_fmtKhr(p.price),
                    style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Row(children: [
                  Container(
                    width: 6, height: 6,
                    decoration: BoxDecoration(color: _statusColor(p.status), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 5),
                  Text(p.status[0].toUpperCase() + p.status.substring(1),
                      style: TextStyle(color: _statusColor(p.status), fontSize: 11, fontWeight: FontWeight.w600)),
                ]),
              ])),
              Column(children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: AppTheme.accent, size: 20),
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => _PostProductScreen(existing: p)))
                      .then((_) => _load()),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppTheme.danger, size: 20),
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

// ── My Orders Tab ──────────────────────────────────────────────────────────

class _MyOrdersTab extends StatefulWidget {
  const _MyOrdersTab();
  @override
  State<_MyOrdersTab> createState() => _MyOrdersTabState();
}

class _MyOrdersTabState extends State<_MyOrdersTab>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<MarketplaceOrderModel> _buying  = [];
  List<MarketplaceOrderModel> _selling = [];
  bool    _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        ApiService.getMyMarketplaceOrders(type: 'buying'),
        ApiService.getMyMarketplaceOrders(type: 'selling'),
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

  Future<void> _action(MarketplaceOrderModel order, String action) async {
    try {
      switch (action) {
        case 'confirm':  await ApiService.confirmMarketplaceOrder(order.id);
        case 'complete': await ApiService.completeMarketplaceOrder(order.id);
        case 'cancel':   await ApiService.cancelMarketplaceOrder(order.id);
      }
      _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppTheme.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppTheme.accent));
    if (_error != null) return Center(child: Text(_error!, style: const TextStyle(color: AppTheme.danger)));
    return Column(children: [
      TabBar(
        controller: _tab,
        indicatorColor: AppTheme.accent,
        labelColor: AppTheme.accent,
        unselectedLabelColor: AppTheme.textSecondary,
        tabs: [
          Tab(text: 'Buying (${_buying.length})'),
          Tab(text: 'Selling (${_selling.length})'),
        ],
      ),
      Expanded(
        child: TabBarView(
          controller: _tab,
          children: [
            _OrderList(orders: _buying,  isSeller: false, onAction: _action, onRefresh: _load),
            _OrderList(orders: _selling, isSeller: true,  onAction: _action, onRefresh: _load),
          ],
        ),
      ),
    ]);
  }
}

class _OrderList extends StatelessWidget {
  final List<MarketplaceOrderModel> orders;
  final bool isSeller;
  final void Function(MarketplaceOrderModel, String) onAction;
  final Future<void> Function() onRefresh;

  const _OrderList({
    required this.orders,
    required this.isSeller,
    required this.onAction,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const Center(
        child: Text('No orders yet', style: TextStyle(color: AppTheme.textSecondary)),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppTheme.accent,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (_, i) => _OrderCard(order: orders[i], isSeller: isSeller, onAction: onAction),
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
    final o = order;
    final statusColor = _statusColor(o.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(
              o.productTitle ?? 'Order #${o.id}',
              style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              o.status[0].toUpperCase() + o.status.substring(1),
              style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Text('${o.orderType[0].toUpperCase()}${o.orderType.substring(1)}',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const Text(' · ', style: TextStyle(color: AppTheme.textSecondary)),
          Text('Qty: ${o.quantity}',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          if (o.rentStartDate != null) ...[
            const Text(' · ', style: TextStyle(color: AppTheme.textSecondary)),
            Text('${o.rentStartDate} → ${o.rentEndDate}',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          ],
        ]),
        const SizedBox(height: 4),
        Text(_fmtKhr(o.total),
            style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w800, fontSize: 15)),
        // Actions: pending → confirm/complete/cancel; confirmed → complete/cancel
        if (o.status == 'pending' || o.status == 'confirmed') ...[
          const SizedBox(height: 12),
          Row(children: [
            if (isSeller && o.status == 'pending') Expanded(
              child: OutlinedButton(
                onPressed: () => onAction(o, 'confirm'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.success),
                  foregroundColor: AppTheme.success,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ),
            if (isSeller && o.status == 'pending') const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () => onAction(o, 'complete'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.accent),
                  foregroundColor: AppTheme.accent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: const Text('Complete', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () => onAction(o, 'cancel'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.danger),
                  foregroundColor: AppTheme.danger,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ),
          ]),
        ],
      ]),
    );
  }
}

// ── Post / Edit Product Screen ─────────────────────────────────────────────

class _PostProductScreen extends StatefulWidget {
  final MarketplaceProductModel? existing;
  const _PostProductScreen({this.existing});

  @override
  State<_PostProductScreen> createState() => _PostProductScreenState();
}

class _PostProductScreenState extends State<_PostProductScreen> {
  final _titleCtrl    = TextEditingController();
  final _descCtrl     = TextEditingController();
  final _priceCtrl    = TextEditingController();
  final _rentCtrl     = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _qtyCtrl      = TextEditingController(text: '1');

  String  _listingType = 'sale';   // sale | rent | both
  String  _condition   = 'used';   // new | used | refurbished
  String  _status      = 'active'; // draft | active

  final List<File> _images = [];
  final _picker = ImagePicker();

  bool   _submitting = false;
  String? _error;

  bool get _isEdit => widget.existing != null;

  Future<void> _pickImages() async {
    final slots = 5 - _images.length;
    if (slots <= 0) return;
    final picked = await _picker.pickMultiImage(limit: slots);
    if (picked.isEmpty) return;

    final tmpDir = await getTemporaryDirectory();
    final compressed = <File>[];
    for (final x in picked) {
      final outPath = '${tmpDir.path}/mkt_${DateTime.now().microsecondsSinceEpoch}_${compressed.length}.jpg';
      final result = await FlutterImageCompress.compressAndGetFile(
        x.path,
        outPath,
        quality:   75,
        minWidth:  1080,
        minHeight: 1080,
        format:    CompressFormat.jpeg,
      );
      if (result != null) compressed.add(File(result.path));
    }
    if (compressed.isEmpty || !mounted) return;
    setState(() => _images.addAll(compressed));
  }

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _titleCtrl.text    = e.title;
      _descCtrl.text     = e.description ?? '';
      _priceCtrl.text    = '${e.price}';
      _rentCtrl.text     = e.rentPricePerDay != null ? '${e.rentPricePerDay}' : '';
      _locationCtrl.text = e.locationText ?? '';
      _qtyCtrl.text      = '${e.quantity}';
      _listingType       = e.listingType;
      _condition         = e.condition ?? 'used';
      _status            = e.status;
    }
  }

  @override
  void dispose() {
    for (final c in [_titleCtrl, _descCtrl, _priceCtrl, _rentCtrl, _locationCtrl, _qtyCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final price = int.tryParse(_priceCtrl.text.trim());
    if (title.isEmpty) { setState(() => _error = 'Title is required.'); return; }
    if (price == null) { setState(() => _error = 'Price must be a valid number.'); return; }
    final rentPerDay = int.tryParse(_rentCtrl.text.trim());

    setState(() { _submitting = true; _error = null; });
    try {
      if (_isEdit) {
        await ApiService.updateMarketplaceProduct(
          widget.existing!.id,
          title:           title,
          description:     _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          listingType:     _listingType,
          condition:       _condition,
          price:           price,
          rentPricePerDay: rentPerDay,
          quantity:        int.tryParse(_qtyCtrl.text.trim()) ?? 1,
          status:          _status,
          locationText:    _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
        );
      } else {
        await ApiService.createMarketplaceProduct(
          title:           title,
          price:           price,
          condition:       _condition,
          listingType:     _listingType,
          status:          _status,
          description:     _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          locationText:    _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
          quantity:        int.tryParse(_qtyCtrl.text.trim()) ?? 1,
          rentPricePerDay: rentPerDay,
          images:          _images,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdit ? 'Product updated!' : 'Product posted!'),
          backgroundColor: AppTheme.success,
        ),
      );
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _submitting = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _submitting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        title: Text(_isEdit ? 'Edit Product' : 'Post a Product',
            style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
      ),
      body: Column(children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.danger.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.danger.withValues(alpha: 0.4)),
                  ),
                  child: Text(_error!, style: const TextStyle(color: AppTheme.danger, fontSize: 13)),
                ),
              ],

              const SectionHeader(title: 'Product Info'),
              const SizedBox(height: 12),
              _Field(ctrl: _titleCtrl, label: 'Title', hint: 'e.g. iPhone 14 Pro 128GB'),
              const SizedBox(height: 12),
              _Field(ctrl: _descCtrl, label: 'Description', hint: 'Describe your product…', maxLines: 3),
              const SizedBox(height: 20),

              const SectionHeader(title: 'Listing Type'),
              const SizedBox(height: 10),
              Wrap(spacing: 8, children: ['sale', 'rent', 'both'].map((t) =>
                GestureDetector(
                  onTap: () => setState(() => _listingType = t),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _listingType == t ? AppTheme.accent : AppTheme.surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      t[0].toUpperCase() + t.substring(1),
                      style: TextStyle(
                        color: _listingType == t ? Colors.white : AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ).toList()),
              const SizedBox(height: 20),

              const SectionHeader(title: 'Condition'),
              const SizedBox(height: 10),
              Wrap(spacing: 8, children: ['new', 'used', 'refurbished'].map((c) =>
                GestureDetector(
                  onTap: () => setState(() => _condition = c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _condition == c ? _conditionColor(c) : AppTheme.surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      c[0].toUpperCase() + c.substring(1),
                      style: TextStyle(
                        color: _condition == c ? Colors.white : AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ).toList()),
              const SizedBox(height: 20),

              const SectionHeader(title: 'Pricing'),
              const SizedBox(height: 12),
              _Field(ctrl: _priceCtrl, label: 'Price (KHR)', hint: 'e.g. 1500000', keyboardType: TextInputType.number),
              if (_listingType == 'rent' || _listingType == 'both') ...[
                const SizedBox(height: 12),
                _Field(ctrl: _rentCtrl, label: 'Rent Price / Day (KHR)',
                    hint: 'e.g. 50000', keyboardType: TextInputType.number),
              ],
              const SizedBox(height: 12),
              _Field(ctrl: _qtyCtrl, label: 'Quantity', hint: '1', keyboardType: TextInputType.number),
              const SizedBox(height: 20),

              if (!_isEdit) ...[
                const SectionHeader(title: 'Images (up to 5)'),
                const SizedBox(height: 12),
                Wrap(spacing: 10, runSpacing: 10, children: [
                  // Thumbnails
                  for (int i = 0; i < _images.length; i++)
                    Stack(children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(_images[i],
                            width: 72, height: 72, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 2, right: 2,
                        child: GestureDetector(
                          onTap: () => setState(() => _images.removeAt(i)),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: AppTheme.danger, shape: BoxShape.circle),
                            child: const Icon(Icons.close, color: Colors.white, size: 12),
                          ),
                        ),
                      ),
                    ]),
                  // Add button
                  if (_images.length < 10)
                    GestureDetector(
                      onTap: _pickImages,
                      child: Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppTheme.accent.withValues(alpha: 0.4),
                              style: BorderStyle.solid),
                        ),
                        child: const Icon(Icons.add_photo_alternate_outlined,
                            color: AppTheme.accent, size: 28),
                      ),
                    ),
                ]),
                const SizedBox(height: 20),
              ],

              const SectionHeader(title: 'Location'),
              const SizedBox(height: 12),
              _Field(ctrl: _locationCtrl, label: 'Location (optional)', hint: 'e.g. BKK1, Phnom Penh'),
              const SizedBox(height: 20),

              if (_isEdit) ...[
                const SectionHeader(title: 'Status'),
                const SizedBox(height: 10),
                Wrap(spacing: 8, children: ['draft', 'active', 'paused', 'sold'].map((s) =>
                  GestureDetector(
                    onTap: () => setState(() => _status = s),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _status == s ? _statusColor(s) : AppTheme.surface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        s[0].toUpperCase() + s.substring(1),
                        style: TextStyle(
                          color: _status == s ? Colors.white : AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ).toList()),
                const SizedBox(height: 8),
              ],
            ]),
          ),
        ),

        Container(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + MediaQuery.of(context).padding.bottom),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.15))),
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppTheme.accent.withValues(alpha: 0.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _submitting
                  ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : Text(_isEdit ? 'Save Changes' : 'Post Product',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ),
          ),
        ),
      ]),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label, hint;
  final int maxLines;
  final TextInputType? keyboardType;

  const _Field({
    required this.ctrl,
    required this.label,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppTheme.textSecondary),
          filled: true,
          fillColor: AppTheme.surface,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    ]);
  }
}
