import 'dart:io';
import 'package:autoride_superapp/widgets/payment_logo.dart';
import 'package:flutter/material.dart';
import 'car_rental_screen.dart';
import 'my_rentals_screen.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/marketplace_model.dart';
import '../../widgets/responsive.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart' show appLocale;
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../widgets/roteh_location_map.dart';
import '../../widgets/guest_fields.dart';
import '../../widgets/guest_phone_otp_sheet.dart';
import '../../widgets/location_picker_screen.dart';
import '../auth/welcome_screen.dart';
import '../../widgets/tablet_frame.dart';

// ── Tokens ─────────────────────────────────────────────────────────────────
const _green  = Color(0xFF00C48C);
const _white  = Colors.white;
const _purple        = Color(0xFF7C3AED);

// Soft emerald tint used behind icons, chips and info cards.
Color _mint(BuildContext c) => AppTheme.accent.withValues(
    alpha: Theme.of(c).brightness == Brightness.dark ? 0.16 : 0.08);

final _fmt    = NumberFormat('#,###', 'en_US');
final _fmtDec = NumberFormat('#,##0.##', 'en_US');
String _usd(num v) => v == v.truncate() ? '\$${_fmt.format(v.toInt())}' : '\$${_fmtDec.format(v)}';

Color _condColor(String? c) => switch (c) {
  'new'         => _green,
  'refurbished' => const Color(0xFF7C3AED),
  _             => const Color(0xFFFF9500),
};

// ── Localized label helpers ──────────────────────────────────────────────
// Backend values ('new'/'used'/'refurbished', 'sale'/'rent'/'both',
// 'active'/'paused'/'sold'/'draft', order/rental statuses) stay as-is for
// comparisons/filtering — only the displayed label is translated.
String _conditionLabel(AppLocalizations l, String? cond) => switch (cond) {
  'new'         => l.conditionNewLabel,
  'refurbished' => l.conditionRefurbishedLabel,
  'used'        => l.conditionUsedLabel,
  _             => cond ?? '',
};

String _listingTypeLabel(AppLocalizations l, String type) => switch (type) {
  'rent' => l.rent,
  'both' => l.saleAndRentLabel,
  _      => l.saleTypeLabel,
};

String _productStatusLabel(AppLocalizations l, String status) => switch (status) {
  'active' => l.active,
  'paused' => l.pausedStatusLabel,
  'sold'   => l.soldStatusLabel,
  'draft'  => l.draftStatusLabel,
  _        => status,
};

String _orderStatusLabel(AppLocalizations l, String status) => switch (status) {
  'confirmed' => l.confirmed,
  'completed' => l.completed,
  'cancelled' => l.cancelled2,
  _           => l.pendingStatus,
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

// ── Shared widgets ─────────────────────────────────────────────────────────

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
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
    padding: const EdgeInsets.fromLTRB(16, 26, 12, 14),
    child: Row(children: [
      Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: TextStyle(color: context.appTextPrimary,
              fontWeight: FontWeight.w800, fontSize: 18))),
      if (onSeeAll != null)
        GestureDetector(
          onTap: onSeeAll,
          child: Row(children: [
            Text(AppLocalizations.of(context).seeAll, style: const TextStyle(
                color: AppTheme.accent, fontWeight: FontWeight.w700, fontSize: 13)),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.accent, size: 18),
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

class MarketplaceScreen extends StatefulWidget implements TabletFullWidth {
  // 0 = Browse, 1 = My Orders — lets a successful purchase/order land
  // straight on the orders list instead of always defaulting to Browse.
  final int initialTab;
  const MarketplaceScreen({super.key, this.initialTab = 0});
  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  bool _isGuest = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this, initialIndex: widget.initialTab);
    ApiService.isLoggedIn().then((v) {
      if (mounted) setState(() => _isGuest = !v);
    });
  }
  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final canPop = Navigator.canPop(context);
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: Colors.black12,
        automaticallyImplyLeading: false,
        toolbarHeight: 64,
        leadingWidth: canPop ? 60 : null,
        leading: canPop
            ? Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
                child: Material(
                  color: _mint(context),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.arrow_back_ios_new_rounded,
                        color: context.appTextPrimary, size: 16),
                  ),
                ),
              )
            : null,
        titleSpacing: canPop ? 8 : 16,
        title: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppTheme.accent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: AppTheme.accent.withValues(alpha: 0.3),
                  blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: const Icon(Icons.storefront_rounded, color: _white, size: 22),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(l.marketplace, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(color: context.appTextPrimary,
                    fontWeight: FontWeight.w800, fontSize: 20)),
          ),
        ]),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: _isGuest ? 4 : 16),
            child: SizedBox(
              width: 42, height: 42,
              child: Material(
                color: _mint(context),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const _AllListingsScreen())),
                  child: const Icon(Icons.search_rounded, color: AppTheme.accent, size: 22),
                ),
              ),
            ),
          ),
          if (_isGuest)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const WelcomeScreen())),
                icon: const Icon(Icons.login_rounded, size: 18, color: AppTheme.accent),
                label: Text(l.signIn,
                    style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w700)),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tab,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          indicator: const UnderlineTabIndicator(
            borderSide: BorderSide(color: AppTheme.accent, width: 3),
            borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: context.appCardBg,
          labelColor: AppTheme.accent,
          unselectedLabelColor: context.appTextSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          tabs: [
            _IconTab(icon: Icons.storefront_outlined, label: l.browseTab),
            _IconTab(icon: Icons.event_note_rounded, label: l.myOrdersTab),
          ],
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
  final _searchCtrl = TextEditingController();
  List<MarketplaceProductModel>  _prods = [];
  int  _totalCount = 0;
  bool _loading    = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });
    try {
      final page = await ApiService.getMarketplaceProducts();
      if (!mounted) return;
      setState(() {
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

  void _openAll({String? search}) => Navigator.push(context,
      MaterialPageRoute(builder: (_) => _AllListingsScreen(search: search)));

  void _submitSearch(String q) {
    final s = q.trim();
    _openAll(search: s.isEmpty ? null : s);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(
        child: CircularProgressIndicator(color: AppTheme.accent, strokeWidth: 2));
    if (_error != null) return _ErrorState(message: _error!, onRetry: _load);

    final l        = AppLocalizations.of(context);
    final heroes   = _prods.where((p) => p.images.isNotEmpty).take(3).toList();
    final featured = _prods.take(6).toList();
    final recent   = _prods.length > 6 ? _prods.sublist(6) : <MarketplaceProductModel>[];

    return RefreshIndicator(
      onRefresh: _load,
      color: AppTheme.accent,
      child: ListView(
        padding: responsivePadding(context, maxWidth: 1100, horizontal: 0, bottom: 32),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _SearchBar(
              controller: _searchCtrl,
              onSubmitted: _submitSearch,
              onFilter: () => _openAll(),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _HeroCarousel(
              products: heroes,
              totalCount: _totalCount,
              onBrowse: () => _openAll(),
              onOpen: _openDetail,
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: _ServiceBanner(
              icon: Icons.electric_rickshaw,
              title: l.rentalVehicle,
              colors: const [AppTheme.accent],
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const CarRentalScreen())),
            ),
          ),

          if (featured.isNotEmpty) ...[
            _SectionTitle(l.popularListings, onSeeAll: () => _openAll()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: responsiveGrid(mainAxisExtent: _gridCardExtent),
                itemCount: featured.length,
                itemBuilder: (_, i) => _GridCard(
                    product: featured[i], onTap: () => _openDetail(featured[i])),
              ),
            ),
          ],

          if (recent.isNotEmpty) ...[
            _SectionTitle(l.recentListings, onSeeAll: () => _openAll()),
            ...recent.take(4).map((p) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: _ListCard(product: p, onTap: () => _openDetail(p)),
            )),
          ],
        ],
      ),
    );
  }
}

// ── Search bar ─────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onFilter;
  const _SearchBar({required this.controller, required this.onSubmitted, required this.onFilter});

  Widget _roundBtn(BuildContext context, IconData icon, Color color, VoidCallback onTap) =>
      Material(
        color: _mint(context),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(width: 44, height: 44, child: Icon(icon, color: color, size: 21)),
        ),
      );

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(
      color: context.appSurface,
      borderRadius: BorderRadius.circular(28),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 16, offset: const Offset(0, 4))],
    ),
    child: Row(children: [
      _roundBtn(context, Icons.tune_rounded, AppTheme.accent, onFilter),
      const SizedBox(width: 12),
      Expanded(
        child: TextField(
          controller: controller,
          textInputAction: TextInputAction.search,
          onSubmitted: onSubmitted,
          style: TextStyle(color: context.appTextPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context).searchListingsHint,
            hintStyle: TextStyle(color: context.appTextSecondary, fontSize: 14),
            filled: false,
            isDense: true,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
      const SizedBox(width: 8),
      _roundBtn(context, Icons.search_rounded, context.appTextPrimary,
          () => onSubmitted(controller.text)),
    ]),
  );
}

// ── Promo hero carousel ────────────────────────────────────────────────────
// Rotates through up to three listings with photos; falls back to a single
// illustrated slide when nothing has an image yet.

class _HeroCarousel extends StatefulWidget {
  final List<MarketplaceProductModel> products;
  final int totalCount;
  final VoidCallback onBrowse;
  final ValueChanged<MarketplaceProductModel> onOpen;
  const _HeroCarousel({
    required this.products,
    required this.totalCount,
    required this.onBrowse,
    required this.onOpen,
  });

  @override
  State<_HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<_HeroCarousel> {
  final _ctrl = PageController();
  Timer? _timer;
  int _idx = 0;

  int get _count => widget.products.isEmpty ? 1 : widget.products.length;

  @override
  void initState() { super.initState(); _startAuto(); }

  @override
  void didUpdateWidget(covariant _HeroCarousel old) {
    super.didUpdateWidget(old);
    if (old.products.length != widget.products.length) {
      if (_idx >= _count && _ctrl.hasClients) _ctrl.jumpToPage(0);
      _startAuto();
    }
  }

  void _startAuto() {
    _timer?.cancel();
    if (_count < 2) return;
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_ctrl.hasClients) return;
      _ctrl.animateToPage((_idx + 1) % _count,
          duration: const Duration(milliseconds: 450), curve: Curves.easeOutCubic);
    });
  }

  @override
  void dispose() { _timer?.cancel(); _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Container(
    height: 196,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      boxShadow: [BoxShadow(color: AppTheme.accent.withValues(alpha: 0.25),
          blurRadius: 18, offset: const Offset(0, 8))],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(children: [
        PageView.builder(
          controller: _ctrl,
          itemCount: _count,
          onPageChanged: (i) => setState(() => _idx = i),
          itemBuilder: (_, i) =>
              _slide(context, widget.products.isEmpty ? null : widget.products[i]),
        ),
        if (_count > 1)
          Positioned(right: 18, bottom: 7,
            child: Row(children: List.generate(_count, (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: _idx == i ? 16 : 6, height: 6,
              margin: const EdgeInsets.only(left: 4),
              decoration: BoxDecoration(
                color: _white.withValues(alpha: _idx == i ? 1 : 0.45),
                borderRadius: BorderRadius.circular(3),
              ),
            ))),
          ),
      ]),
    ),
  );

  Widget _slide(BuildContext context, MarketplaceProductModel? p) {
    final l = AppLocalizations.of(context);
    return Container(
      decoration: const BoxDecoration(color: AppTheme.accent),
      child: Stack(children: [
        Positioned(right: -40, top: -50,
          child: Container(width: 190, height: 190,
            decoration: BoxDecoration(
                color: _white.withValues(alpha: 0.07), shape: BoxShape.circle)),
        ),
        Positioned(left: -30, bottom: -60,
          child: Container(width: 140, height: 140,
            decoration: BoxDecoration(
                color: _white.withValues(alpha: 0.05), shape: BoxShape.circle)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 14, 20),
          child: Row(children: [
            Expanded(
              flex: 11,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.eco_rounded, color: _white, size: 12),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text('${widget.totalCount} ${l.listingsAvailable}',
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: _white,
                              fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ]),
                ),
                const SizedBox(height: 10),
                Text(l.findBestDeal, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _white,
                        fontWeight: FontWeight.w800, fontSize: 20, height: 1.25)),
                if (p != null) ...[
                  const SizedBox(height: 4),
                  Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: _white.withValues(alpha: 0.85), fontSize: 12)),
                ],
                const Spacer(),
                Material(
                  color: _white,
                  borderRadius: BorderRadius.circular(22),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: widget.onBrowse,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 9, 10, 9),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(l.browseAll, style: const TextStyle(color: AppTheme.accent,
                            fontWeight: FontWeight.w700, fontSize: 13)),
                        const SizedBox(width: 2),
                        const Icon(Icons.chevron_right_rounded, color: AppTheme.accent, size: 18),
                      ]),
                    ),
                  ),
                ),
              ]),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 9,
              child: p == null
                  ? Icon(Icons.electric_rickshaw,
                      color: _white.withValues(alpha: 0.85), size: 96)
                  : GestureDetector(
                      onTap: () => widget.onOpen(p),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 16, offset: const Offset(0, 6))],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: SizedBox.expand(child: _NetImage(url: p.images.first)),
                        ),
                      ),
                    ),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ── Service banner (rental) ─────────────────────────────────────

class _ServiceBanner extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Color> colors;
  final VoidCallback onTap;
  const _ServiceBanner({
    required this.icon,
    required this.title,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: Ink(
      decoration: BoxDecoration(
        color: colors.first,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: colors.first.withValues(alpha: 0.25),
            blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Stack(children: [
          // Faint route pins in the background.
          Positioned(right: 66, top: 10,
              child: Icon(Icons.location_on_rounded,
                  color: _white.withValues(alpha: 0.14), size: 22)),
          Positioned(right: 108, bottom: 8,
              child: Icon(Icons.location_on_outlined,
                  color: _white.withValues(alpha: 0.12), size: 20)),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                    color: _white.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: Icon(icon, color: _white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _white,
                        fontWeight: FontWeight.w800, fontSize: 16)),
              ),
              const SizedBox(width: 8),
              Container(
                width: 40, height: 40,
                decoration: const BoxDecoration(color: _white, shape: BoxShape.circle),
                child: const Icon(Icons.arrow_forward_rounded, color: AppTheme.accent, size: 20),
              ),
            ]),
          ),
        ]),
      ),
    ),
  );
}

// ── Grid card ──────────────────────────────────────────────────────────────

const double _gridCardExtent = 266;

class _GridCard extends StatelessWidget {
  final MarketplaceProductModel product;
  final VoidCallback onTap;
  const _GridCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = product;
    final l = AppLocalizations.of(context);
    final tag = p.vehicleTypeName(appLocale.value.languageCode)
        ?? _listingTypeLabel(l, p.listingType);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 14, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            height: 140,
            width: double.infinity,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(fit: StackFit.expand, children: [
                _NetImage(url: p.images.isNotEmpty ? p.images.first : null),
                Positioned(top: 8, left: 8, right: 44,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _ImageTag(icon: Icons.electric_rickshaw, label: tag),
                  ),
                ),
                if (p.listingType != 'sale')
                  Positioned(top: 8, right: 8,
                    child: Container(
                      width: 26, height: 26,
                      decoration: const BoxDecoration(color: _purple, shape: BoxShape.circle),
                      child: const Icon(Icons.key_rounded, color: _white, size: 14),
                    ),
                  ),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
            child: Text(p.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w700,
                    fontSize: 13, height: 1.35)),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
            child: Text(_usd(p.price), style: const TextStyle(
                color: AppTheme.accent, fontWeight: FontWeight.w800, fontSize: 18)),
          ),
        ]),
      ),
    );
  }
}

// Frosted label pinned over a product photo.
class _ImageTag extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ImageTag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFE7F7F0).withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: AppTheme.accent, size: 12),
      const SizedBox(width: 4),
      Flexible(
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppTheme.accent,
                fontSize: 10, fontWeight: FontWeight.w700)),
      ),
    ]),
  );
}

// ── List card ──────────────────────────────────────────────────────────────

class _ListCard extends StatelessWidget {
  final MarketplaceProductModel product;
  final VoidCallback onTap;
  const _ListCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = product;
    final l = AppLocalizations.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 14, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: _NetImage(
                url: p.images.isNotEmpty ? p.images.first : null,
                width: 96, height: 96),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w700,
                      fontSize: 13, height: 1.3)),
              const SizedBox(height: 6),
              Wrap(spacing: 6, runSpacing: 4, children: [
                if (p.condition != null)
                  _Pill(label: _conditionLabel(l, p.condition), color: _condColor(p.condition)),
                _Pill(
                  label: _listingTypeLabel(l, p.listingType),
                  color: p.listingType == 'rent' ? _purple : AppTheme.accent,
                ),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Text(_usd(p.price), style: const TextStyle(
                    color: AppTheme.accent, fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(width: 8),
                if (p.locationText != null)
                  Expanded(
                    child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                      Icon(Icons.location_on_rounded, color: context.appTextSecondary, size: 12),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(p.locationText!, maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: context.appTextSecondary, fontSize: 11)),
                      ),
                    ]),
                  ),
              ]),
            ]),
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
    child: SingleChildScrollView(
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
          label: Text(AppLocalizations.of(context).tryAgain),
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

class _AllListingsScreen extends StatefulWidget implements TabletFullWidth {
  final int?    categoryId;
  final String? categoryName;
  final String? search;
  const _AllListingsScreen({this.categoryId, this.categoryName, this.search});

  @override
  State<_AllListingsScreen> createState() => _AllListingsScreenState();
}

class _AllListingsScreenState extends State<_AllListingsScreen> {
  final _scrollCtrl = ScrollController();
  List<MarketplaceCategoryModel>     _cats    = [];
  List<MarketplaceVehicleTypeModel>  _vTypes  = [];
  List<MarketplaceVehicleColorModel> _vColors = [];
  List<MarketplaceVehicleSizeModel>  _vSizes  = [];
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
  int?    _vTypeId;
  int?    _vColorId;
  int?    _vSizeId;

  bool get _hasActiveFilters =>
      _selCat != null || _type != null || _cond != null ||
      _vTypeId != null || _vColorId != null || _vSizeId != null;

  @override
  void initState() {
    super.initState();
    _selCat = widget.categoryId;
    _load();
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200 &&
        _hasMore && !_loadingMore && !_loading) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; _page = 1; });
    try {
      final needsRefData = _cats.isEmpty;
      final futures = await Future.wait([
        if (needsRefData) ApiService.getMarketplaceCategories(),
        if (needsRefData) ApiService.getMarketplaceVehicleTypes(),
        if (needsRefData) ApiService.getMarketplaceVehicleColors(),
        if (needsRefData) ApiService.getMarketplaceVehicleSizes(),
        ApiService.getMarketplaceProducts(
          search:         widget.search,
          categoryId:     _selCat,
          listingType:    _type,
          condition:      _cond,
          vehicleTypeId:  _vTypeId,
          vehicleColorId: _vColorId,
          vehicleSizeId:  _vSizeId,
          page:           1,
        ),
      ]);
      if (!mounted) return;
      final pageResult = futures.last as MarketplaceProductsPage;
      setState(() {
        if (needsRefData) {
          _cats    = futures[0] as List<MarketplaceCategoryModel>;
          _vTypes  = futures[1] as List<MarketplaceVehicleTypeModel>;
          _vColors = futures[2] as List<MarketplaceVehicleColorModel>;
          _vSizes  = futures[3] as List<MarketplaceVehicleSizeModel>;
        }
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
        search:         widget.search,
        categoryId:     _selCat,
        listingType:    _type,
        condition:      _cond,
        vehicleTypeId:  _vTypeId,
        vehicleColorId: _vColorId,
        vehicleSizeId:  _vSizeId,
        page:           _page + 1,
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
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _openFilterSheet() async {
    final result = await showModalBottomSheet<_FilterSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(
        vehicleTypes: _vTypes,
        vehicleSizes: _vSizes,
        vehicleColors: _vColors,
        initial: _FilterSelection(
          categoryId: _selCat, listingType: _type, condition: _cond,
          vehicleTypeId: _vTypeId, vehicleSizeId: _vSizeId, vehicleColorId: _vColorId,
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _selCat   = result.categoryId;
      _type     = result.listingType;
      _cond     = result.condition;
      _vTypeId  = result.vehicleTypeId;
      _vSizeId  = result.vehicleSizeId;
      _vColorId = result.vehicleColorId;
    });
    _load();
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
        title: Text(widget.categoryName
            ?? (widget.search != null ? '“${widget.search}”' : AppLocalizations.of(context).allListingsTitle),
            style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w800, fontSize: 16)),
        actions: [
          IconButton(
            onPressed: _openFilterSheet,
            icon: Badge(
              isLabelVisible: _hasActiveFilters,
              smallSize: 8,
              backgroundColor: _green,
              child: Icon(Icons.tune_rounded, color: context.appTextPrimary, size: 22),
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _grid = !_grid),
            icon: Icon(_grid ? Icons.view_list_rounded : Icons.grid_view_rounded,
                color: context.appTextPrimary, size: 22),
          ),
        ],
      ),
      body: Column(children: [
        // Vehicle-type pills — always-visible shortcut for the two real
        // vehicle types, on top of the fuller filter sheet.
        if (_vTypes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _VehicleTypePill(
                  label: AppLocalizations.of(context).all,
                  active: _vTypeId == null,
                  onTap: () { setState(() => _vTypeId = null); _load(); },
                ),
                const SizedBox(width: 8),
                for (final vt in _vTypes) ...[
                  _VehicleTypePill(
                    label: vt.name(appLocale.value.languageCode),
                    active: _vTypeId == vt.id,
                    onTap: () { setState(() => _vTypeId = _vTypeId == vt.id ? null : vt.id); _load(); },
                  ),
                  const SizedBox(width: 8),
                ],
              ]),
            ),
          ),
        // Active-filter summary (only shown once something is applied) +
        // result count — the actual filter selection lives in the sheet
        // opened via the appBar's tune icon.
        Container(
          color: context.appSurface,
          child: Column(children: [
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            if (_hasActiveFilters)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                child: Row(children: [
                  if (_selCat != null)
                    _ActiveFilterChip(
                        label: _cats.firstWhere((c) => c.id == _selCat, orElse: () => const MarketplaceCategoryModel(id: 0, name: '')).name,
                        onClear: () { setState(() => _selCat = null); _load(); }),
                  if (_type != null)
                    _ActiveFilterChip(
                        label: _type == 'rent'
                            ? AppLocalizations.of(context).forRentLabel
                            : AppLocalizations.of(context).forSaleLabel,
                        onClear: () { setState(() => _type = null); _load(); }),
                  if (_cond != null)
                    _ActiveFilterChip(
                        label: _conditionLabel(AppLocalizations.of(context), _cond),
                        onClear: () { setState(() => _cond = null); _load(); }),
                  if (_vTypeId != null)
                    _ActiveFilterChip(
                        label: _vTypes.firstWhere((t) => t.id == _vTypeId).name(appLocale.value.languageCode),
                        onClear: () { setState(() => _vTypeId = null); _load(); }),
                  if (_vSizeId != null)
                    _ActiveFilterChip(
                        label: _vSizes.firstWhere((s) => s.id == _vSizeId).label,
                        onClear: () { setState(() => _vSizeId = null); _load(); }),
                  if (_vColorId != null)
                    _ActiveFilterChip(
                        label: _vColors.firstWhere((c) => c.id == _vColorId).name(appLocale.value.languageCode),
                        onClear: () { setState(() => _vColorId = null); _load(); }),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selCat = null; _type = null; _cond = null;
                        _vTypeId = null; _vColorId = null; _vSizeId = null;
                      });
                      _load();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: Text(AppLocalizations.of(context).clearAll,
                          style: const TextStyle(color: Colors.grey, fontSize: 12, decoration: TextDecoration.underline)),
                    ),
                  ),
                ]),
              ),
            if (!_loading && _error == null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                child: Row(children: [
                  Text('${_prods.length} ${AppLocalizations.of(context).results}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ]),
              ),
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
        Text(AppLocalizations.of(context).noListingsFound,
            style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 6),
        Text(AppLocalizations.of(context).tryDifferentFilters,
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
              padding: responsivePadding(context, maxWidth: 1100, top: 8),
              gridDelegate: responsiveGrid(mainAxisExtent: _gridCardExtent),
              itemCount: _prods.length + 1,
              itemBuilder: (_, i) {
                if (i == _prods.length) return footer;
                return _GridCard(product: _prods[i], onTap: () => open(_prods[i]));
              })
          : ListView.builder(
              controller: _scrollCtrl,
              padding: responsivePadding(context, top: 8),
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

// Small removable chip shown in the active-filters summary row.
// Icon-over-label tab for the vehicle-type quick filter row (All / one per
// real vehicle type) — matches the icon-tab reference style requested.
class _VehicleTypePill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _VehicleTypePill({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: active ? _green.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: active ? _green : const Color(0xFFE0E0E0), width: 1.5),
      ),
      child: Text(label,
          style: TextStyle(color: active ? _green : Colors.grey.shade600,
              fontWeight: FontWeight.w600, fontSize: 12)),
    ),
  );
}

class _ActiveFilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onClear;
  const _ActiveFilterChip({required this.label, required this.onClear});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: Container(
      padding: const EdgeInsets.only(left: 10, right: 4, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: _green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _green.withValues(alpha: 0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: const TextStyle(color: _green, fontSize: 12, fontWeight: FontWeight.w600)),
        GestureDetector(
          onTap: onClear,
          child: const Padding(
            padding: EdgeInsets.all(4),
            child: Icon(Icons.close_rounded, size: 14, color: _green),
          ),
        ),
      ]),
    ),
  );
}

// ── Filter bottom sheet ─────────────────────────────────────────────────────
// Draft selection returned to the caller only when "Apply" is tapped — avoids
// firing a network request on every single checkbox tap inside the sheet.
class _FilterSelection {
  final int?    categoryId;
  final String? listingType;
  final String? condition;
  final int?    vehicleTypeId;
  final int?    vehicleSizeId;
  final int?    vehicleColorId;
  const _FilterSelection({
    this.categoryId, this.listingType, this.condition,
    this.vehicleTypeId, this.vehicleSizeId, this.vehicleColorId,
  });
}

class _FilterSheet extends StatefulWidget {
  final List<MarketplaceVehicleTypeModel>  vehicleTypes;
  final List<MarketplaceVehicleSizeModel>  vehicleSizes;
  final List<MarketplaceVehicleColorModel> vehicleColors;
  final _FilterSelection initial;
  const _FilterSheet({
    required this.vehicleTypes,
    required this.vehicleSizes, required this.vehicleColors,
    required this.initial,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  int?    _cat;
  String? _type;
  String? _cond;
  int?    _vType;
  int?    _vSize;
  int?    _vColor;

  @override
  void initState() {
    super.initState();
    _cat    = widget.initial.categoryId;
    _type   = widget.initial.listingType;
    _cond   = widget.initial.condition;
    _vType  = widget.initial.vehicleTypeId;
    _vSize  = widget.initial.vehicleSizeId;
    _vColor = widget.initial.vehicleColorId;
  }

  // Single-select "radio" behaviour rendered as a checkbox row, per request —
  // every filter here maps to one backend id, so multi-select isn't meaningful.
  Widget _checkboxRow(String label, bool checked, VoidCallback onTap) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Checkbox(
          value: checked,
          activeColor: _green,
          onChanged: (_) => onTap(),
        ),
        Expanded(child: Text(label, style: TextStyle(color: context.appTextPrimary, fontSize: 14))),
      ]),
    ),
  );

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 4),
    child: Text(text, style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 40, height: 4,
              decoration: BoxDecoration(color: context.appCardBg, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(l.filter, style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w800, fontSize: 16)),
              GestureDetector(
                onTap: () => setState(() {
                  _cat = null; _type = null; _cond = null;
                  _vType = null; _vSize = null; _vColor = null;
                }),
                child: Text(l.clearAll, style: const TextStyle(color: _green, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ]),
          ),
          const Divider(height: 20),
          Expanded(
            child: ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _sectionTitle(l.listingTypeLabel),
                _checkboxRow(l.forSaleLabel, _type == 'sale', () => setState(() => _type = _type == 'sale' ? null : 'sale')),
                _checkboxRow(l.forRentLabel, _type == 'rent', () => setState(() => _type = _type == 'rent' ? null : 'rent')),

                _sectionTitle(l.condition),
                for (final c in [('new', l.conditionNewLabel), ('used', l.conditionUsedLabel), ('refurbished', l.conditionRefurbishedLabel)])
                  _checkboxRow(c.$2, _cond == c.$1, () => setState(() => _cond = _cond == c.$1 ? null : c.$1)),

                if (widget.vehicleTypes.isNotEmpty) ...[
                  _sectionTitle(l.vehicleType),
                  for (final vt in widget.vehicleTypes)
                    _checkboxRow(vt.name(appLocale.value.languageCode), _vType == vt.id,
                        () => setState(() => _vType = _vType == vt.id ? null : vt.id)),
                ],

                if (widget.vehicleSizes.isNotEmpty) ...[
                  _sectionTitle(l.size),
                  for (final vs in widget.vehicleSizes)
                    _checkboxRow(vs.label, _vSize == vs.id,
                        () => setState(() => _vSize = _vSize == vs.id ? null : vs.id)),
                ],

                if (widget.vehicleColors.isNotEmpty) ...[
                  _sectionTitle(l.color),
                  Wrap(spacing: 14, runSpacing: 10, children: [
                    for (final vc in widget.vehicleColors)
                      _ColorChip(
                        color: _swatchFor(vc.code),
                        label: vc.name(appLocale.value.languageCode),
                        active: _vColor == vc.id,
                        onTap: () => setState(() => _vColor = _vColor == vc.id ? null : vc.id),
                      ),
                  ]),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context, _FilterSelection(
                    categoryId: _cat, listingType: _type, condition: _cond,
                    vehicleTypeId: _vType, vehicleSizeId: _vSize, vehicleColorId: _vColor,
                  )),
                  child: Text(l.apply, style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// Maps the backend's vehicle-color `code` (a plain slug like 'black'/'red',
// not a hex value) to an actual swatch color. Unknown codes fall back to a
// neutral grey rather than breaking the filter row.
Color _swatchFor(String code) => switch (code) {
      'black' => const Color(0xFF1A1A1A),
      'white' => const Color(0xFFF5F5F5),
      'red'   => const Color(0xFFE53935),
      'blue'  => const Color(0xFF1976D2),
      'gray' || 'grey' => const Color(0xFF9E9E9E),
      'green' => const Color(0xFF43A047),
      'yellow' => const Color(0xFFFDD835),
      'orange' => const Color(0xFFFB8C00),
      'silver' => const Color(0xFFC0C0C0),
      'brown' => const Color(0xFF6D4C41),
      _       => const Color(0xFF9E9E9E),
    };

class _ColorChip extends StatelessWidget {
  final Color color;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ColorChip({required this.color, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Tooltip(
      message: label,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 26, height: 26,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
                color: active ? _green : const Color(0xFFE0E0E0),
                width: active ? 2.5 : 1),
            boxShadow: active
                ? [BoxShadow(color: _green.withValues(alpha: 0.3), blurRadius: 4)]
                : null,
          ),
          child: active
              ? Icon(Icons.check,
                  size: 14,
                  color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white)
              : null,
        ),
      ]),
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
  final _shareKey = GlobalKey();

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

  void _share(AppLocalizations l) {
    final box = _shareKey.currentContext?.findRenderObject() as RenderBox?;
    final price = _p.listingType == 'rent' && _p.rentPricePerDay != null
        ? '${_usd(_p.rentPricePerDay!)} · ${l.rentPerDay}'
        : _usd(_p.price);
    Share.share(
      [_p.title, price, if (_p.locationText != null) _p.locationText!].join('\n'),
      sharePositionOrigin: box != null ? box.localToGlobal(Offset.zero) & box.size : null,
    );
  }

  void _order(String type) => Navigator.push(context, MaterialPageRoute(
      builder: (_) => _OrderScreen(product: _p, orderType: type)));

  @override
  Widget build(BuildContext context) {
    final l        = AppLocalizations.of(context);
    final lang     = appLocale.value.languageCode;
    final canSell  = _p.listingType == 'sale' || _p.listingType == 'both';
    final canRent  = _p.listingType == 'rent' || _p.listingType == 'both';
    final vType    = _p.vehicleTypeName(lang);
    final vColor   = _p.vehicleColorName(lang);

    final specs = <_SpecItem>[
      if (_p.condition != null)
        _SpecItem(Icons.verified_outlined, l.condition, _conditionLabel(l, _p.condition)),
      if (_p.vehicleSizeLabel != null)
        _SpecItem(Icons.straighten_rounded, l.size, _p.vehicleSizeLabel!),
      _SpecItem(Icons.sell_outlined, l.type, _listingTypeLabel(l, _p.listingType)),
      _SpecItem(Icons.inventory_2_outlined, l.quantity, '${_p.quantity}'),
    ];

    return Scaffold(
      backgroundColor: context.appSurface,
      body: Column(children: [
        Expanded(
          child: CustomScrollView(slivers: [
            // ── Photo hero ──────────────────────────────────────
            SliverAppBar(
              expandedHeight: 330,
              pinned: true,
              backgroundColor: context.appSurface,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
              leadingWidth: 62,
              leading: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Center(child: _CircleBtn(
                  icon: Icons.arrow_back_ios_new_rounded, size: 17,
                  onTap: () => Navigator.pop(context),
                )),
              ),
              actions: [
                _CircleBtn(
                  icon: _saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: _saved ? Colors.redAccent : null,
                  onTap: () => setState(() => _saved = !_saved),
                ),
                const SizedBox(width: 10),
                _CircleBtn(key: _shareKey, icon: Icons.share_outlined, onTap: () => _share(l)),
                const SizedBox(width: 12),
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
                      child: CircularProgressIndicator(color: AppTheme.accent, strokeWidth: 2)),
                  if (_p.images.length > 1) ...[
                    Positioned(left: 16, bottom: 38,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('${_imgIdx + 1} / ${_p.images.length}',
                            style: const TextStyle(color: _white,
                                fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    Positioned(right: 16, bottom: 44,
                      child: Row(children: List.generate(_p.images.length, (i) =>
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: _imgIdx == i ? 18 : 6, height: 6,
                          margin: const EdgeInsets.only(left: 4),
                          decoration: BoxDecoration(
                            color: _imgIdx == i ? AppTheme.accent : _white.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        )),
                      ),
                    ),
                  ],
                ]),
              ),
            ),

            // ── Content sheet (overlaps the photo) ──────────────
            SliverToBoxAdapter(
              child: Transform.translate(
                offset: const Offset(0, -24),
                child: Container(
                  padding: responsivePadding(context, top: 20),
                  decoration: BoxDecoration(
                    color: context.appSurface,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // Badges
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      _SoftTag(
                        icon: canSell ? Icons.local_shipping_rounded : Icons.key_rounded,
                        label: _p.listingType == 'sale' ? l.forSaleLabel
                            : _p.listingType == 'rent' ? l.forRentLabel
                                : l.saleAndRentLabel,
                        color: _white,
                        bg: canSell ? AppTheme.accent : _purple,
                      ),
                      if (_p.condition != null)
                        _SoftTag(
                          label: _conditionLabel(l, _p.condition),
                          color: _condColor(_p.condition),
                          bg: _condColor(_p.condition).withValues(alpha: 0.12),
                        ),
                      _SoftTag(
                        icon: Icons.visibility_outlined,
                        label: '${_p.viewsCount} ${l.viewsCountSuffix}',
                        color: context.appTextSecondary,
                        bg: context.appCardBg,
                      ),
                    ]),
                    const SizedBox(height: 14),
                    Text(_p.title, style: TextStyle(color: context.appTextPrimary,
                        fontWeight: FontWeight.w800, fontSize: 22, height: 1.3)),
                    if (_p.categoryName != null) ...[
                      const SizedBox(height: 4),
                      Text(_p.categoryName!,
                          style: TextStyle(color: context.appTextSecondary, fontSize: 13)),
                    ],
                    if (vType != null || vColor != null) ...[
                      const SizedBox(height: 12),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        if (vType != null)
                          _SoftTag(icon: Icons.bolt_rounded, label: vType,
                              color: AppTheme.accent, bg: _mint(context)),
                        if (vColor != null)
                          _SoftTag(icon: Icons.circle, label: vColor,
                              iconColor: _swatchFor(_p.vehicleColorCode ?? ''),
                              color: AppTheme.confirmBlue,
                              bg: AppTheme.confirmBlue.withValues(alpha: 0.08)),
                      ]),
                    ],

                    // Price + verified seller
                    const SizedBox(height: 18),
                    Row(children: [
                      Expanded(child: _PriceBlock(product: _p, canSell: canSell, canRent: canRent)),
                      if (_p.sellerName != null) ...[
                        const SizedBox(width: 12),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 170),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: _mint(context),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.verified_user_rounded, color: AppTheme.accent, size: 26),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min, children: [
                                  Text(l.verifiedSeller, maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: AppTheme.accent,
                                          fontWeight: FontWeight.w800, fontSize: 12)),
                                  const SizedBox(height: 2),
                                  Text(_p.sellerName!, maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: context.appTextSecondary,
                                          fontSize: 11)),
                                ]),
                              ),
                            ]),
                          ),
                        ),
                      ],
                    ]),

                    if (_p.locationText != null) ...[
                      const SizedBox(height: 14),
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                              color: _mint(context), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.location_on_rounded, color: AppTheme.accent, size: 16),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(_p.locationText!,
                            style: TextStyle(color: context.appTextSecondary, fontSize: 13))),
                      ]),
                    ],

                    // Spec strip
                    const SizedBox(height: 18),
                    _SpecStrip(items: specs),

                    if (_p.description != null && _p.description!.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      _DetailHeading(l.description),
                      const SizedBox(height: 8),
                      Text(_p.description!, style: TextStyle(
                          color: context.appTextSecondary, fontSize: 14, height: 1.55)),
                    ],

                    if (_p.images.length > 1) ...[
                      const SizedBox(height: 22),
                      _DetailHeading(l.photos),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 72,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _p.images.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (_, i) => GestureDetector(
                            onTap: () => _pageCtrl.animateToPage(i,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: _imgIdx == i ? AppTheme.accent : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: _NetImage(url: _p.images[i], width: 92, height: 64),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ]),
                ),
              ),
            ),
          ]),
        ),

        // ── Bottom CTA ──────────────────────────────────────────
        Container(
          padding: responsivePadding(context, top: 12,
              bottom: 12 + MediaQuery.of(context).padding.bottom),
          decoration: BoxDecoration(
            color: context.appSurface,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16, offset: const Offset(0, -4))],
          ),
          child: _isOwner
              ? SizedBox(
                  width: double.infinity,
                  child: _OutlineCTA(
                    label: l.editListing,
                    icon: Icons.edit_outlined,
                    color: AppTheme.confirmBlue,
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => _PostProductScreen(existing: _p))),
                  ),
                )
              : Row(children: [
                  if (canSell && canRent) ...[
                    Expanded(child: _OutlineCTA(
                      label: l.rent, icon: Icons.key_rounded, color: AppTheme.confirmBlue,
                      onTap: () => _order('rent'),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _CTA(
                      label: l.buy, icon: Icons.shopping_cart_outlined, color: AppTheme.confirmBlue,
                      onTap: () => _order('purchase'),
                    )),
                  ] else if (canSell)
                    Expanded(child: _CTA(
                      label: l.buyNowLabel, icon: Icons.shopping_cart_outlined, color: AppTheme.confirmBlue,
                      onTap: () => _order('purchase'),
                    ))
                  else if (canRent)
                    Expanded(child: _CTA(
                      label: l.rentNowLabel, icon: Icons.key_rounded, color: AppTheme.confirmBlue,
                      onTap: () => _order('rent'),
                    )),
                ]),
        ),
      ]),
    );
  }
}

// Sale price (large) plus the per-day rent line; rent-only listings lead
// with the rent price instead.
class _PriceBlock extends StatelessWidget {
  final MarketplaceProductModel product;
  final bool canSell, canRent;
  const _PriceBlock({required this.product, required this.canSell, required this.canRent});

  @override
  Widget build(BuildContext context) {
    final l    = AppLocalizations.of(context);
    final rent = product.rentPricePerDay;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (canSell)
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(_usd(product.price), style: const TextStyle(color: AppTheme.accent,
              fontWeight: FontWeight.w900, fontSize: 32, height: 1.1)),
        )
      else if (rent != null)
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(_usd(rent), style: const TextStyle(color: _purple,
              fontWeight: FontWeight.w900, fontSize: 30, height: 1.1)),
          const SizedBox(width: 4),
          Flexible(
            child: Text('/ ${l.perDaySpecLabel}', maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
          ),
        ]),
      if (canSell && canRent && rent != null) ...[
        const SizedBox(height: 6),
        Row(children: [
          const Icon(Icons.calendar_month_rounded, color: _purple, size: 16),
          const SizedBox(width: 6),
          Flexible(
            child: Text.rich(
              TextSpan(children: [
                TextSpan(text: '${l.rentPerDay}  ',
                    style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
                TextSpan(text: _usd(rent), style: const TextStyle(color: _purple,
                    fontWeight: FontWeight.w800, fontSize: 14)),
              ]),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
          ),
        ]),
      ],
      if (product.quantity > 1) ...[
        const SizedBox(height: 4),
        Text('${l.qty}: ${product.quantity}',
            style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
      ],
    ]);
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  final double size;
  const _CircleBtn({super.key, required this.icon, required this.onTap,
      this.color, this.size = 20});

  @override
  Widget build(BuildContext context) => Material(
    color: context.appSurface,
    shape: const CircleBorder(),
    elevation: 3,
    shadowColor: Colors.black26,
    child: InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: SizedBox(width: 42, height: 42,
          child: Icon(icon, color: color ?? context.appTextPrimary, size: size)),
    ),
  );
}

class _SoftTag extends StatelessWidget {
  final String label;
  final Color color, bg;
  final IconData? icon;
  final Color? iconColor;
  const _SoftTag({required this.label, required this.color, required this.bg,
      this.icon, this.iconColor});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      if (icon != null) ...[
        Icon(icon, color: iconColor ?? color, size: 15),
        const SizedBox(width: 6),
      ],
      Flexible(
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
      ),
    ]),
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
    label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    style: AppTheme.confirmButtonStyle(background: color),
  );
}

class _OutlineCTA extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _OutlineCTA({required this.label, required this.icon,
      required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onTap,
    icon: Icon(icon, size: 18),
    label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    // Same size/shape as AppTheme.confirmButtonStyle, outlined.
    style: OutlinedButton.styleFrom(
      foregroundColor: color,
      side: BorderSide(color: color, width: 1.3),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      minimumSize: const Size(0, 44),
      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

class _DetailHeading extends StatelessWidget {
  final String text;
  const _DetailHeading(this.text);

  @override
  Widget build(BuildContext context) => Text(text, style: TextStyle(
      color: context.appTextPrimary, fontWeight: FontWeight.w800, fontSize: 17));
}

class _SpecItem {
  final IconData icon;
  final String label, value;
  const _SpecItem(this.icon, this.label, this.value);
}

// Mint strip of icon/label/value columns separated by thin dividers.
class _SpecStrip extends StatelessWidget {
  final List<_SpecItem> items;
  const _SpecStrip({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final divider = VerticalDivider(width: 1, thickness: 1,
        indent: 6, endIndent: 6, color: AppTheme.accent.withValues(alpha: 0.15));
    final cells = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) cells.add(divider);
      final it = items[i];
      cells.add(Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(it.icon, color: AppTheme.accent, size: 22),
            const SizedBox(height: 6),
            Text(it.label, maxLines: 1, overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(color: context.appTextSecondary, fontSize: 11)),
            const SizedBox(height: 3),
            Text(it.value, maxLines: 1, overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(color: context.appTextPrimary,
                    fontWeight: FontWeight.w800, fontSize: 13)),
          ]),
        ),
      ));
    }
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
      decoration: BoxDecoration(
        color: _mint(context),
        borderRadius: BorderRadius.circular(18),
      ),
      child: IntrinsicHeight(child: Row(children: cells)),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Order Screen
// ══════════════════════════════════════════════════════════════════════════════

// Rental duration presets — same "pick a duration, end date auto-computes"
// pattern as the Car Rental page (1M · 2M · 3M · 6M · 1Y · 2Y).
enum _RentDur { m1, m2, m3, m6, y1, y2 }

extension _RentDurX on _RentDur {
  String labelFor(AppLocalizations l) => switch (this) {
    _RentDur.m1 => l.durMonth1,
    _RentDur.m2 => l.durMonth2,
    _RentDur.m3 => l.durMonth3,
    _RentDur.m6 => l.durMonth6,
    _RentDur.y1 => l.durYear1,
    _RentDur.y2 => l.durYear2,
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
  String labelFor(AppLocalizations l) =>
      this == _LocType.pickup ? l.pickUpShortLabel : l.delivery;
  String subtitleFor(AppLocalizations l) => this == _LocType.pickup
      ? l.collectMyself
      : l.deliverCarToMyAddress;
  IconData get icon   => this == _LocType.pickup
      ? Icons.directions_walk_rounded
      : Icons.local_shipping_outlined;
  String mapTitleFor(AppLocalizations l) => this == _LocType.pickup
      ? l.pickupLocation
      : l.setDeliveryLocationTitle;
}

// Bottom-sheet picker for adding another product to the current order.
// Purchase-only (sale/both listings), excludes whatever's already in the order.
class _AddItemSheet extends StatefulWidget {
  final Set<int> excludeIds;
  // Set from the inline filter row on the main Buy Item page — the sheet
  // just shows results matching whatever was picked there, no filter UI of
  // its own.
  final int? vehicleTypeId;
  final int? vehicleColorId;
  final int? vehicleSizeId;
  const _AddItemSheet({
    required this.excludeIds,
    this.vehicleTypeId,
    this.vehicleColorId,
    this.vehicleSizeId,
  });

  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  final _search = TextEditingController();
  Timer? _debounce;
  bool _loading = true;
  String? _error;
  List<MarketplaceProductModel> _results = [];

  @override
  void initState() {
    super.initState();
    _load();
    _search.addListener(() {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 400), _load);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });
    try {
      final page = await ApiService.getMarketplaceProducts(
        search:         _search.text.trim().isEmpty ? null : _search.text.trim(),
        listingType:    'sale',
        vehicleTypeId:  widget.vehicleTypeId,
        vehicleColorId: widget.vehicleColorId,
        vehicleSizeId:  widget.vehicleSizeId,
      );
      if (!mounted) return;
      setState(() {
        _results = page.products.where((p) => !widget.excludeIds.contains(p.id)).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 40, height: 4,
              decoration: BoxDecoration(color: context.appCardBg, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(AppLocalizations.of(context).addItemTitle, style: TextStyle(
                color: context.appTextPrimary, fontWeight: FontWeight.w800, fontSize: 16)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _search,
              style: TextStyle(color: context.appTextPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context).searchListingsHint,
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey, size: 20),
                filled: true, fillColor: context.appCardBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _green, strokeWidth: 2))
                : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                    : _results.isEmpty
                        ? Center(child: Text(AppLocalizations.of(context).noOtherListingsFound,
                            style: TextStyle(color: context.appTextSecondary)))
                        : ListView.builder(
                            controller: scrollCtrl,
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: _results.length,
                            itemBuilder: (_, i) {
                              final p = _results[i];
                              return ListTile(
                                onTap: () => Navigator.pop(context, p),
                                contentPadding: EdgeInsets.zero,
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: p.images.isNotEmpty
                                      ? Image.network(p.images.first, width: 52, height: 52, fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(width: 52, height: 52, color: context.appCardBg))
                                      : Container(width: 52, height: 52, color: context.appCardBg,
                                          child: const Icon(Icons.image_outlined, color: Colors.grey)),
                                ),
                                title: Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                                subtitle: Text('\$${p.price.toStringAsFixed(p.price % 1 == 0 ? 0 : 2)}',
                                    style: const TextStyle(color: _green, fontWeight: FontWeight.w700, fontSize: 13)),
                                trailing: const Icon(Icons.add_circle_outline, color: _green),
                              );
                            },
                          ),
          ),
        ]),
      ),
    );
  }
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
  bool    _isGuest = false;
  final   _guestNameCtrl  = TextEditingController();
  final   _guestPhoneCtrl = TextEditingController();
  _LocType  _locType = _LocType.pickup;
  String    _deliveryAddress = '';
  LatLng?   _deliveryLatLng;
  // Manual pickup point, used only when the listing itself has no
  // coordinates — lets the buyer drag/search to set one instead of a
  // dead-end "not set" message.
  String    _manualPickupAddress = '';
  LatLng?   _manualPickupLatLng;

  // Extra items added to this same order beyond widget.product — purchase
  // orders only (a rental books exactly one vehicle through /rentals, which
  // has no concept of multiple items). Each entry keeps its own quantity;
  // the backend has no multi-item order endpoint, so submit fires one
  // POST /marketplace/{id}/order per line, sequentially.
  final List<MarketplaceProductModel> _extraItems = [];
  final Map<int, int> _extraQty = {};

  // Inline vehicle-type/size/color filter, shown right under the item card.
  // Selecting one both narrows "Add Another Item" AND swaps the main item
  // itself to the best match — so filtering is a way to change what you're
  // buying, not just a search-in-a-popup refinement.
  List<MarketplaceVehicleTypeModel>  _vTypes  = [];
  List<MarketplaceVehicleColorModel> _vColors = [];
  List<MarketplaceVehicleSizeModel>  _vSizes  = [];
  bool _refLoading = true;
  int? _filterVTypeId;
  int? _filterVColorId;
  int? _filterVSizeId;

  // Which type/color/size options currently have at least one active
  // listing — drives the grayed-out/unavailable chip state. Re-fetched
  // whenever a filter changes so it narrows as the buyer picks facets.
  MarketplaceAvailableOptions _availableOptions = const MarketplaceAvailableOptions();

  // Accessory ids selected for the current main item. Cleared whenever the
  // filter swaps _currentProduct to a different listing, since accessories
  // belong to one specific product, not the abstract type/size/color combo.
  final Set<int> _selectedAccessoryIds = {};

  // Sizes are only meaningful per vehicle type (e.g. Cargo has different
  // sizes than Passenger, via the marketplace_vehicle_type_size pivot) — the
  // vehicle-types endpoint already nests each type's valid sizes, so once a
  // type is picked, show only those instead of every size in the catalogue.
  List<MarketplaceVehicleSizeModel> get _sizesForFilter {
    if (_filterVTypeId == null) return _vSizes;
    for (final t in _vTypes) {
      if (t.id == _filterVTypeId) return t.sizes;
    }
    return _vSizes;
  }

  // Mutable "main item" — starts as whatever was tapped into from the
  // listings screen, but a filter selection can swap it to a matching
  // product. Everything pricing/order-related reads this, not widget.product.
  late MarketplaceProductModel _currentProduct = widget.product;
  bool _swappingProduct = false;
  String? _filterNoMatch;

  @override
  void initState() {
    super.initState();
    if (!_isVehicleRental) _loadFilterRefData();
    ApiService.isLoggedIn().then((v) {
      if (!mounted || v) return;
      setState(() {
        _isGuest = true;
        if (_pay == 'wallet') _pay = 'cash';
      });
    });
  }

  Future<void> _loadFilterRefData() async {
    try {
      final results = await Future.wait([
        ApiService.getMarketplaceVehicleTypes(),
        ApiService.getMarketplaceVehicleColors(),
        ApiService.getMarketplaceVehicleSizes(),
      ]);
      final options = await ApiService.getMarketplaceAvailableOptions(
        categoryId: _currentProduct.categoryId);
      if (!mounted) return;
      setState(() {
        _vTypes  = results[0] as List<MarketplaceVehicleTypeModel>;
        _vColors = results[1] as List<MarketplaceVehicleColorModel>;
        _vSizes  = results[2] as List<MarketplaceVehicleSizeModel>;
        _availableOptions = options;
        _refLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _refLoading = false);
    }
  }

  // Re-fetches which options are still available given the current filter
  // selection — narrows as facets get picked (e.g. once "Cargo" is chosen,
  // only sizes/colors that exist on an active Cargo listing stay enabled).
  Future<void> _refreshAvailableOptions() async {
    try {
      final options = await ApiService.getMarketplaceAvailableOptions(
        categoryId:     _currentProduct.categoryId,
        vehicleTypeId:  _filterVTypeId,
        vehicleColorId: _filterVColorId,
        vehicleSizeId:  _filterVSizeId,
      );
      if (mounted) setState(() => _availableOptions = options);
    } catch (_) {}
  }

  // Called whenever a filter chip is tapped — re-fetches with the new
  // filter combo and, if anything matches, swaps the displayed item to the
  // top result. Falls back to keeping the current item (with a small notice)
  // if nothing matches that combination.
  Future<void> _applyFilterToCurrentItem() async {
    setState(() { _swappingProduct = true; _filterNoMatch = null; });
    _refreshAvailableOptions();
    try {
      final page = await ApiService.getMarketplaceProducts(
        listingType:    'sale',
        vehicleTypeId:  _filterVTypeId,
        vehicleColorId: _filterVColorId,
        vehicleSizeId:  _filterVSizeId,
      );
      if (!mounted) return;
      final match = page.products.where((p) => p.id != _currentProduct.id).toList();
      setState(() {
        if (page.products.isNotEmpty) {
          _currentProduct = match.isNotEmpty ? match.first : page.products.first;
          // Accessories belong to one specific listing — carrying a
          // selection over to a swapped-in product could apply an add-on
          // that product doesn't even offer.
          _selectedAccessoryIds.clear();
        } else {
          _filterNoMatch = AppLocalizations.of(context).trNoListingMatchesFilter;
        }
        _swappingProduct = false;
      });
    } catch (_) {
      if (mounted) setState(() => _swappingProduct = false);
    }
  }

  bool get _isRent  => widget.orderType == 'rent';
  // Every "rent" listing in this marketplace is a vehicle, so rent orders
  // always book through the car-rental system (POST /rentals) instead of a
  // generic marketplace order — that's what makes them show up correctly for
  // the vehicle's driver/owner to accept.
  bool get _isVehicleRental => _isRent;
  bool get _showLocation => _isVehicleRental || _isGuest;
  String? get _orderDeliveryAddress =>
      _showLocation && _locType == _LocType.delivery ? _deliveryAddress : null;
  bool get _datesOk => !_isRent || _start != null;
  DateTime? get _end => _start?.add(Duration(days: _duration.days));
  int  get _days    => _isRent ? _duration.days : 0;
  // Flat add-on regardless of quantity — a canopy is one physical part
  // fitted to the vehicle being ordered, not multiplied per unit.
  double get _selectedAccessoriesTotal => _currentProduct.accessories
      .where((a) => a.id != null && _selectedAccessoryIds.contains(a.id))
      .fold(0.0, (sum, a) => sum + a.price);
  double get _mainItemTotal {
    final base = _isRent && _currentProduct.rentPricePerDay != null && _datesOk
        ? _currentProduct.rentPricePerDay! * _days * _qty
        : _currentProduct.price * _qty;
    return base + _selectedAccessoriesTotal;
  }
  double get _extraItemsTotal => _extraItems.fold(
      0.0, (sum, p) => sum + p.price * (_extraQty[p.id] ?? 1));
  double get _subtotal => _mainItemTotal + _extraItemsTotal;
  double get _discountUsd => _discountKhr / 4100.0;
  double get _total => (_subtotal - _discountUsd).clamp(0.0, _subtotal);
  Color get _color => AppTheme.accent;

  static String _fmt(DateTime d) => DateFormat('MMM d, yyyy').format(d);

  @override
  void dispose() {
    _notes.dispose();
    _couponCtrl.dispose();
    _guestNameCtrl.dispose();
    _guestPhoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _applyCoupon() async {
    final code = _couponCtrl.text.trim();
    if (code.isEmpty) return;
    setState(() { _applyingCoupon = true; _couponError = null; });
    try {
      final subtotalKhr = (_subtotal * 4100).round();
      final result = await ApiService.applyPromoCode(code, subtotalKhr,
          serviceType: _isRent ? 'product_rent' : 'product_purchase',
          guestPhone: _isGuest ? _guestPhoneCtrl.text : null);
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
      setState(() { _couponError = AppLocalizations.of(context).failedToApplyCoupon; _applyingCoupon = false; _discountKhr = 0; _appliedCode = null; });
    }
  }

  void _removeCoupon() => setState(() {
    _couponCtrl.clear();
    _discountKhr = 0;
    _appliedCode = null;
    _couponError = null;
  });

  Future<void> _openAddItemPicker() async {
    final picked = await showModalBottomSheet<MarketplaceProductModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddItemSheet(
        excludeIds: {_currentProduct.id, ..._extraItems.map((p) => p.id)},
        vehicleTypeId:  _filterVTypeId,
        vehicleColorId: _filterVColorId,
        vehicleSizeId:  _filterVSizeId,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _extraItems.add(picked);
      _extraQty[picked.id] = 1;
    });
  }

  void _bumpExtraQty(int productId, int delta) {
    final current = _extraQty[productId] ?? 1;
    final next = (current + delta).clamp(1, 99);
    setState(() => _extraQty[productId] = next);
  }

  void _removeExtraItem(int productId) {
    setState(() {
      _extraItems.removeWhere((p) => p.id == productId);
      _extraQty.remove(productId);
    });
  }

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
        title:    _locType.mapTitleFor(AppLocalizations.of(context)),
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
        title:    AppLocalizations.of(context).pickupLocation,
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
              child: Text(AppLocalizations.of(context).locationType, style: TextStyle(
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
                    Text(t.labelFor(AppLocalizations.of(ctx)), style: TextStyle(
                        color: ctx.appTextPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(t.subtitleFor(AppLocalizations.of(ctx)), style: TextStyle(color: ctx.appTextSecondary, fontSize: 12)),
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
              child: Text(AppLocalizations.of(context).rentalDuration, style: TextStyle(
                  color: ctx.appTextPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
          Divider(height: 1, color: ctx.appCardBg),
          ..._RentDur.values.map((d) {
            final isSel = d == _duration;
            final endsLabel = _start != null
                ? '${AppLocalizations.of(ctx).endsPrefix} ${_fmt(_start!.add(Duration(days: d.days)))}'
                : '${d.days} ${AppLocalizations.of(ctx).daysLabel}';
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
                    Text(d.labelFor(AppLocalizations.of(ctx)), style: TextStyle(
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
      setState(() => _err = AppLocalizations.of(context).selectRentalDatesError);
      return;
    }
    if (_showLocation && _locType == _LocType.delivery && _deliveryAddress.isEmpty) {
      setState(() => _err = AppLocalizations.of(context).setDeliveryLocationError);
      return;
    }
    final guestName  = _isGuest ? _guestNameCtrl.text.trim()  : null;
    final guestPhone = _isGuest ? _guestPhoneCtrl.text.trim() : null;
    if (_isGuest) {
      final invalid = GuestFields.validate(AppLocalizations.of(context), guestName!, guestPhone!);
      if (invalid != null) {
        setState(() => _err = invalid);
        return;
      }
    }
    // Guests confirm their phone by SMS code before ordering.
    if (_isGuest && !await ensureGuestPhoneVerified(context, guestPhone!)) return;
    if (!mounted) return;
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
          promoCode:      _appliedCode,
          guestName:      guestName,
          guestPhone:     guestPhone,
        );
      } else if (_extraItems.isEmpty) {
        await ApiService.placeMarketplaceOrder(_currentProduct.id,
          orderType:     widget.orderType,
          quantity:      _qty,
          paymentMethod: _pay,
          notes:         _notes.text.trim().isEmpty ? null : _notes.text.trim(),
          rentStartDate: _isRent ? DateFormat('yyyy-MM-dd').format(_start!) : null,
          rentEndDate:   _isRent ? DateFormat('yyyy-MM-dd').format(_end!)   : null,
          promoCode:     _appliedCode,
          accessoryIds:  _selectedAccessoryIds.toList(),
          guestName:     guestName,
          guestPhone:    guestPhone,
          deliveryAddress: _orderDeliveryAddress,
          deliveryLat:     _orderDeliveryAddress != null ? _deliveryLatLng?.latitude  : null,
          deliveryLng:     _orderDeliveryAddress != null ? _deliveryLatLng?.longitude : null,
        );
      } else {
        // Multiple items — atomic checkout: all orders succeed together or
        // none are created, instead of firing one request per item and
        // risking a half-placed cart if a later item fails.
        try {
          await ApiService.checkoutMarketplaceCart(
            items: [
              MarketplaceCheckoutItem(productId: _currentProduct.id, quantity: _qty,
                  accessoryIds: _selectedAccessoryIds.toList()),
              for (final item in _extraItems)
                MarketplaceCheckoutItem(productId: item.id, quantity: _extraQty[item.id] ?? 1),
            ],
            paymentMethod: _pay,
            notes:         _notes.text.trim().isEmpty ? null : _notes.text.trim(),
            promoCode:     _appliedCode,
            guestName:     guestName,
            guestPhone:    guestPhone,
            deliveryAddress: _orderDeliveryAddress,
            deliveryLat:     _orderDeliveryAddress != null ? _deliveryLatLng?.latitude  : null,
            deliveryLng:     _orderDeliveryAddress != null ? _deliveryLatLng?.longitude : null,
          );
        } on ApiException catch (e) {
          // TEMPORARY: /marketplace/checkout isn't deployed on the live
          // server yet (404/405 — route not registered there, though it
          // exists in the backend repo). Fall back to placing one order per
          // item so multi-item purchases still work until that ships.
          // Remove this catch once checkout is confirmed live in production.
          if (e.statusCode != 404 && e.statusCode != 405) rethrow;
          await ApiService.placeMarketplaceOrder(_currentProduct.id,
            orderType:     widget.orderType,
            quantity:      _qty,
            paymentMethod: _pay,
            notes:         _notes.text.trim().isEmpty ? null : _notes.text.trim(),
            promoCode:     _appliedCode,
            accessoryIds:  _selectedAccessoryIds.toList(),
            guestName:     guestName,
            guestPhone:    guestPhone,
            deliveryAddress: _orderDeliveryAddress,
            deliveryLat:     _orderDeliveryAddress != null ? _deliveryLatLng?.latitude  : null,
            deliveryLng:     _orderDeliveryAddress != null ? _deliveryLatLng?.longitude : null,
          );
          for (final item in _extraItems) {
            await ApiService.placeMarketplaceOrder(item.id,
              orderType:     'purchase',
              quantity:      _extraQty[item.id] ?? 1,
              paymentMethod: _pay,
              notes:         _notes.text.trim().isEmpty ? null : _notes.text.trim(),
              guestName:     guestName,
              guestPhone:    guestPhone,
              deliveryAddress: _orderDeliveryAddress,
              deliveryLat:     _orderDeliveryAddress != null ? _deliveryLatLng?.latitude  : null,
              deliveryLng:     _orderDeliveryAddress != null ? _deliveryLatLng?.longitude : null,
            );
          }
        }
      }
      if (!mounted) return;
      final goToHistory = await _showSuccessDialog();
      if (!mounted) return;
      if (goToHistory) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => _isVehicleRental && !_isGuest
                ? const MyRentalsScreen()
                : const MarketplaceScreen(initialTab: 1),
          ),
          (route) => route.isFirst,
        );
      } else {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on ApiException catch (e) {
      if (mounted) setState(() { _err = e.message; _busy = false; });
    } on SocketException {
      // Never reached the server (offline, DNS, connect timeout) — show a
      // readable message instead of the raw socket error.
      if (mounted) {
        setState(() {
          _err = AppLocalizations.of(context).connectionErrorRetry;
          _busy = false;
        });
      }
    } on TimeoutException {
      if (mounted) {
        setState(() {
          _err = AppLocalizations.of(context).connectionErrorRetry;
          _busy = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _err = e.toString(); _busy = false; });
    }
  }

  // Success popup after a purchase / rental goes through. Returns true when
  // the user wants to see their orders (or rentals), false for Home.
  Future<bool> _showSuccessDialog() async {
    final l = AppLocalizations.of(context);
    final p = _currentProduct;
    final showRentals = _isVehicleRental && !_isGuest;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: ctx.appSurface,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 28, 22, 18),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.4, end: 1),
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutBack,
              builder: (_, v, child) => Transform.scale(scale: v, child: child),
              child: Container(
                width: 92, height: 92,
                decoration: BoxDecoration(color: _mint(ctx), shape: BoxShape.circle),
                child: Center(
                  child: Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      color: AppTheme.accent,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: AppTheme.accent.withValues(alpha: 0.35),
                          blurRadius: 16, offset: const Offset(0, 6))],
                    ),
                    child: const Icon(Icons.check_rounded, color: _white, size: 38),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(_isRent ? l.rentalBookedSuccess : l.orderPlacedSuccess,
                textAlign: TextAlign.center,
                style: TextStyle(color: ctx.appTextPrimary,
                    fontWeight: FontWeight.w800, fontSize: 19, height: 1.3)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _mint(ctx),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _NetImage(
                      url: p.images.isNotEmpty ? p.images.first : null,
                      width: 52, height: 52),
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: ctx.appTextPrimary,
                          fontWeight: FontWeight.w700, fontSize: 13, height: 1.3)),
                  const SizedBox(height: 2),
                  Text('${l.total}: ${_usd(_total)}',
                      style: const TextStyle(color: AppTheme.accent,
                          fontWeight: FontWeight.w800, fontSize: 14)),
                ])),
              ]),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: AppTheme.confirmButtonStyle(),
                child: Text(showRentals ? l.myRentals : l.myOrdersTab),
              ),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.backToHome, style: TextStyle(
                  color: ctx.appTextSecondary, fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
      ),
    );
    return result ?? true;
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
              child: Text(AppLocalizations.of(context).paymentMethod, style: TextStyle(
                  color: ctx.appTextPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
          Divider(height: 1, color: ctx.appCardBg),
          ..._pays(AppLocalizations.of(ctx)).map((o) {
            final (id, label, icon, subtitle) = o;
            final isSel = id == _pay;
            return InkWell(
              onTap: () { setState(() => _pay = id); Navigator.pop(ctx); },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(children: [
                  PaymentLogo(method: id, size: 40),
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

  // Guests have no in-app wallet.
  List<(String, String, IconData, String)> _pays(AppLocalizations l) => [
    ('cash',         l.cash,          Icons.money_rounded,             l.payInCashOnPickup),
    ('aba',          'ABA',           Icons.account_balance_rounded,   l.abaMobileBanking),
    ('acleda',       'ACLEDA',        Icons.account_balance_rounded,   l.abaMobileBanking.replaceAll('ABA', 'ACLEDA')),
    if (!_isGuest)
      ('wallet',     l.walletLabel,   Icons.wallet_rounded,            l.inAppWalletBalance),
  ];

  @override
  Widget build(BuildContext context) {
    final p = _currentProduct;
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: Colors.black12,
        automaticallyImplyLeading: false,
        toolbarHeight: 64,
        centerTitle: true,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
          child: Material(
            color: _mint(context),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.pop(context),
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  color: context.appTextPrimary, size: 16),
            ),
          ),
        ),
        title: Text(_isRent ? l.rentItemTitle : l.buyItemTitle,
            style: TextStyle(color: context.appTextPrimary,
                fontWeight: FontWeight.w800, fontSize: 18)),
      ),
      body: Column(children: [
        Expanded(child: SingleChildScrollView(
          padding: responsivePadding(context, maxWidth: 720, top: 8, bottom: 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Product summary
            _FormCard(
              padding: const EdgeInsets.all(12),
              child: Column(children: [
                Row(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: _NetImage(
                        url: p.images.isNotEmpty ? p.images.first : null,
                        width: 92, height: 92),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: context.appTextPrimary,
                            fontWeight: FontWeight.w700, fontSize: 14, height: 1.3)),
                    const SizedBox(height: 6),
                    Text(
                      _isRent && p.rentPricePerDay != null
                          ? '${_usd(p.rentPricePerDay!)}${AppLocalizations.of(context).trPerDay}' : _usd(p.price),
                      style: TextStyle(color: _color,
                          fontWeight: FontWeight.w800, fontSize: 18)),
                    if (p.quantity > 0) ...[
                      const SizedBox(height: 6),
                      _SoftTag(icon: Icons.check_circle_rounded, label: l.available,
                          color: AppTheme.accent, bg: _mint(context)),
                    ],
                  ])),
                ]),
              ]),
            ),

            if (!_isVehicleRental && !_refLoading &&
                (_vTypes.isNotEmpty || _vColors.isNotEmpty || _vSizes.isNotEmpty)) ...[
              const SizedBox(height: 18),
              _OrderSectionHeader(icon: Icons.tune_rounded, text: AppLocalizations.of(context).options),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: context.appSurface,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 14, offset: const Offset(0, 4))],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (_vTypes.isNotEmpty) ...[
                    _OptionRowLabel(
                        icon: Icons.two_wheeler_outlined, text: AppLocalizations.of(context).type, color: _color),
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final vt in _vTypes)
                        _SelChip(vt.name(appLocale.value.languageCode), _filterVTypeId == vt.id, _color,
                            () {
                              setState(() {
                                final newTypeId = _filterVTypeId == vt.id ? null : vt.id;
                                _filterVTypeId = newTypeId;
                                // Drop the size pick if it doesn't belong to the
                                // newly-selected type's size list.
                                if (_filterVSizeId != null &&
                                    !_sizesForFilter.any((s) => s.id == _filterVSizeId)) {
                                  _filterVSizeId = null;
                                }
                              });
                              _applyFilterToCurrentItem();
                            },
                            // Never disable the option already selected —
                            // it clearly exists (we're looking at it) even
                            // if the availability probe hasn't caught up.
                            disabled: _filterVTypeId != vt.id &&
                                !_availableOptions.vehicleTypeIds.contains(vt.id)),
                    ]),
                  ],
                  if (_sizesForFilter.isNotEmpty) ...[
                    if (_vTypes.isNotEmpty) _OptionDivider(),
                    _OptionRowLabel(
                        icon: Icons.straighten_rounded, text: AppLocalizations.of(context).size, color: _color),
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final vs in _sizesForFilter)
                        _SelChip(vs.label, _filterVSizeId == vs.id, _color,
                            () { setState(() => _filterVSizeId = _filterVSizeId == vs.id ? null : vs.id); _applyFilterToCurrentItem(); },
                            disabled: _filterVSizeId != vs.id &&
                                !_availableOptions.vehicleSizeIds.contains(vs.id)),
                    ]),
                  ],
                  if (_vColors.isNotEmpty) ...[
                    if (_vTypes.isNotEmpty || _sizesForFilter.isNotEmpty) _OptionDivider(),
                    _OptionRowLabel(
                        icon: Icons.palette_outlined,
                        text: _filterVColorId == null
                            ? AppLocalizations.of(context).color
                            : '${AppLocalizations.of(context).color}: ${_vColors.firstWhere((c) => c.id == _filterVColorId).name(appLocale.value.languageCode)}',
                        color: _color),
                    const SizedBox(height: 8),
                    Wrap(spacing: 14, runSpacing: 10, children: [
                      for (final vc in _vColors)
                        Builder(builder: (_) {
                          final colorDisabled = _filterVColorId != vc.id &&
                              !_availableOptions.vehicleColorIds.contains(vc.id);
                          return GestureDetector(
                            onTap: colorDisabled ? null : () {
                              setState(() => _filterVColorId = _filterVColorId == vc.id ? null : vc.id);
                              _applyFilterToCurrentItem();
                            },
                            child: Opacity(
                              opacity: colorDisabled ? 0.5 : 1.0,
                              child: Column(mainAxisSize: MainAxisSize.min, children: [
                                Stack(alignment: Alignment.center, children: [
                                  Container(
                                    width: 32, height: 32,
                                    decoration: BoxDecoration(
                                      color: _swatchFor(vc.code),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: _filterVColorId == vc.id ? _color : const Color(0xFFE0E0E0),
                                          width: _filterVColorId == vc.id ? 2.5 : 1),
                                      boxShadow: _filterVColorId == vc.id
                                          ? [BoxShadow(color: _color.withValues(alpha: 0.35), blurRadius: 6)]
                                          : null,
                                    ),
                                    child: _filterVColorId == vc.id
                                        ? Icon(Icons.check, size: 16,
                                            color: _swatchFor(vc.code).computeLuminance() > 0.5 ? Colors.black : Colors.white)
                                        : null,
                                  ),
                                  if (colorDisabled)
                                    Icon(Icons.close_rounded, size: 18, color: Colors.grey.shade700),
                                ]),
                                const SizedBox(height: 5),
                                Text(vc.name(appLocale.value.languageCode),
                                    style: TextStyle(
                                        color: _filterVColorId == vc.id
                                            ? _color : context.appTextSecondary,
                                        fontSize: 10,
                                        fontWeight: _filterVColorId == vc.id ? FontWeight.w700 : FontWeight.w500)),
                              ]),
                            ),
                          );
                        }),
                    ]),
                  ],
                  if (_currentProduct.accessories.isNotEmpty) ...[
                    if (_vTypes.isNotEmpty || _sizesForFilter.isNotEmpty || _vColors.isNotEmpty)
                      _OptionDivider(),
                    _OptionRowLabel(
                        icon: Icons.build_circle_outlined, text: AppLocalizations.of(context).accessories, color: _color),
                    const SizedBox(height: 4),
                    for (final acc in _currentProduct.accessories)
                      if (acc.id != null)
                        CheckboxListTile(
                          value: _selectedAccessoryIds.contains(acc.id),
                          onChanged: (v) => setState(() {
                            if (v ?? false) {
                              _selectedAccessoryIds.add(acc.id!);
                            } else {
                              _selectedAccessoryIds.remove(acc.id);
                            }
                          }),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          activeColor: _color,
                          title: Text(acc.name(appLocale.value.languageCode),
                              style: TextStyle(
                                  color: context.appTextPrimary,
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                          secondary: Text('+${_usd(acc.price)}',
                              style: TextStyle(
                                  color: _color, fontSize: 13, fontWeight: FontWeight.w700)),
                        ),
                  ],
                  if (_swappingProduct) ...[
                    const SizedBox(height: 12),
                    Row(children: [
                      const SizedBox(width: 14, height: 14,
                          child: CircularProgressIndicator(color: _green, strokeWidth: 2)),
                      const SizedBox(width: 8),
                      Text(AppLocalizations.of(context).findingMatch, style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
                    ]),
                  ] else if (_filterNoMatch != null) ...[
                    const SizedBox(height: 12),
                    Row(children: [
                      const Icon(Icons.info_outline_rounded, color: Colors.orange, size: 14),
                      const SizedBox(width: 6),
                      Expanded(child: Text(_filterNoMatch!,
                          style: const TextStyle(color: Colors.orange, fontSize: 12))),
                    ]),
                  ],
                ]),
              ),
            ],
            const SizedBox(height: 18),

            // Other items in the same order (purchases only).
            if (!_isVehicleRental) ...[
              // Other items added to this same order.
              for (final item in _extraItems) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: context.appSurface, borderRadius: BorderRadius.circular(18),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 14, offset: const Offset(0, 4))]),
                  child: Row(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: item.images.isNotEmpty
                          ? Image.network(item.images.first, width: 44, height: 44, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(width: 44, height: 44, color: context.appCardBg))
                          : Container(width: 44, height: 44, color: context.appCardBg,
                              child: const Icon(Icons.image_outlined, color: Colors.grey, size: 18)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                      Text(_usd(item.price), style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w700, fontSize: 12)),
                    ])),
                    _QtyBtn(Icons.remove_rounded, (_extraQty[item.id] ?? 1) > 1, _color,
                        () => _bumpExtraQty(item.id, -1)),
                    SizedBox(width: 28, child: Center(child: Text('${_extraQty[item.id] ?? 1}',
                        style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w700, fontSize: 14)))),
                    _QtyBtn(Icons.add_rounded, (_extraQty[item.id] ?? 1) < 99, _color,
                        () => _bumpExtraQty(item.id, 1)),
                    IconButton(
                      onPressed: () => _removeExtraItem(item.id),
                      icon: const Icon(Icons.close_rounded, color: Colors.red, size: 18),
                      visualDensity: VisualDensity.compact,
                    ),
                  ]),
                ),
                const SizedBox(height: 10),
              ],
              GestureDetector(
                onTap: _openAddItemPicker,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _color.withValues(alpha: 0.4), width: 1.5),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.add_rounded, color: _color, size: 18),
                    const SizedBox(width: 6),
                    Text(AppLocalizations.of(context).addAnotherItem, style: TextStyle(color: _color, fontWeight: FontWeight.w700, fontSize: 13)),
                  ]),
                ),
              ),
              const SizedBox(height: 18),
            ],

            if (_isGuest) ...[
              GuestFields(nameCtrl: _guestNameCtrl, phoneCtrl: _guestPhoneCtrl),
              const SizedBox(height: 18),
            ],

            // Location — every rental, plus guest purchases (pick up from the
            // seller or deliver to an address), same Location Type + map UI.
            if (_showLocation) ...[
              _OrderSectionHeader(icon: Icons.location_on_rounded, text: l.location),
              _OrderDropdownTile(
                icon: _locType.icon,
                label: l.locationType,
                value: _locType.labelFor(l),
                subtitle: _locType.subtitleFor(l),
                color: _color,
                onTap: _openLocTypeSheet,
              ),
              const SizedBox(height: 10),
              if (_locType == _LocType.pickup)
                _FormCard(
                  padding: const EdgeInsets.all(10),
                  child: widget.product.locationLat != null && widget.product.locationLng != null
                      ? RotehLocationMap(
                          pin: LatLng(widget.product.locationLat!, widget.product.locationLng!),
                          // Never fall back to RotehLocationMap's own default label
                          // (the ROTEH HQ address) — this is the listing's own
                          // pickup point, not the company office.
                          addressLabel: widget.product.locationText ?? l.pickupLocation,
                        )
                      : _manualPickupLatLng != null
                          ? RotehLocationMap(
                              pin: _manualPickupLatLng,
                              addressLabel: _manualPickupAddress,
                            )
                          // No listing coordinates and nothing picked yet —
                          // default to the ROTEH CAMBODIA office (same as Car
                          // Rental's Pick Up default). Still tappable to
                          // override with a real pickup point.
                          : GestureDetector(
                              onTap: _pickManualPickupLocation,
                              child: const RotehLocationMap(),
                            ),
                )
              else
                _FormCard(
                  onTap: _pickDeliveryLocation,
                  border: _deliveryAddress.isEmpty
                      ? Colors.red.withValues(alpha: 0.4) : null,
                  child: Row(children: [
                    _IconBubble(icon: Icons.location_on_rounded, color: _color),
                    const SizedBox(width: 12),
                    Expanded(child: Text(
                        _deliveryAddress.isEmpty ? l.tapToSetDelivery : _deliveryAddress,
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: _deliveryAddress.isEmpty
                                ? context.appTextSecondary : context.appTextPrimary,
                            fontSize: 13,
                            fontWeight: _deliveryAddress.isEmpty ? FontWeight.w400 : FontWeight.w600))),
                    Icon(Icons.chevron_right_rounded, color: context.appTextSecondary, size: 22),
                  ]),
                ),
              const SizedBox(height: 18),
            ],

            // Rental period — start date, then duration + auto end date.
            if (_isRent) ...[
              _OrderSectionHeader(icon: Icons.calendar_month_rounded, text: l.rentalPeriodLabel),
              _FormCard(
                padding: const EdgeInsets.all(12),
                child: Column(children: [
                  _PickerTile(
                    icon: Icons.calendar_month_rounded,
                    label: l.startDate,
                    value: _start == null ? l.selectLabel : _fmt(_start!),
                    trailing: Icons.keyboard_arrow_down_rounded,
                    outlined: true,
                    error: _start == null,
                    onTap: _pickStartDate,
                  ),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: _PickerTile(
                      icon: _duration.icon,
                      label: l.durationLabel,
                      value: _duration.labelFor(l),
                      subtitle: '$_days ${l.daysLabel}',
                      trailing: Icons.chevron_right_rounded,
                      onTap: _openDurationSheet,
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: _PickerTile(
                      icon: Icons.event_available_rounded,
                      label: l.endDateAuto,
                      value: _end == null ? '—' : _fmt(_end!),
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
                      child: Text(l.selectStartDate,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red,
                              fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ],
                ]),
              ),
              const SizedBox(height: 18),
            ],

            // Payment
            _OrderSectionHeader(icon: Icons.credit_card_rounded, text: l.paymentMethod),
            Builder(builder: (context) {
              final selected = _pays(l).firstWhere((o) => o.$1 == _pay);
              return _OrderDropdownTile(
                icon: selected.$3,
                label: l.paymentMethod,
                value: selected.$2,
                subtitle: selected.$4,
                color: _color,
                onTap: _openPaymentSheet,
              );
            }),
            const SizedBox(height: 18),

            // Notes
            _OrderSectionHeader(icon: Icons.edit_note_rounded, text: l.notesOptional),
            TextField(
              controller: _notes, maxLines: 2,
              style: TextStyle(color: context.appTextPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: l.anySpecialInstructionsHint,
                hintStyle: TextStyle(color: context.appTextSecondary),
                filled: true, fillColor: context.appSurface,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: _color.withValues(alpha: 0.5))),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 18),

            // Coupon code (buy & rent, matching Car Rental)
            _OrderSectionHeader(icon: Icons.local_offer_rounded, text: l.couponCode),
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
                      Text('- ${_usd(_discountUsd)} ${AppLocalizations.of(context).discountApplied}',
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
                        hintText: AppLocalizations.of(context).enterCouponCodeOptional,
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
                          : Text(AppLocalizations.of(context).apply, style: const TextStyle(fontWeight: FontWeight.w700)),
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
            const SizedBox(height: 18),

            // Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: context.appSurface, borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 14, offset: const Offset(0, 4))]),
              child: Column(children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(_isRent ? AppLocalizations.of(context).bookingSummaryLabel : AppLocalizations.of(context).orderSummaryLabel,
                      style: TextStyle(color: context.appTextPrimary,
                          fontSize: 15, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 12),
                if (!_isRent) ...[
                  _SumRow(_qty > 1 ? '${p.title} × $_qty' : p.title, _usd(_mainItemTotal)),
                  for (final item in _extraItems)
                    _SumRow(
                        (_extraQty[item.id] ?? 1) > 1 ? '${item.title} × ${_extraQty[item.id]}' : item.title,
                        _usd(item.price * (_extraQty[item.id] ?? 1))),
                ] else ...[
                  // Matches the Car Rental page's summary rows exactly.
                  _SumRow(AppLocalizations.of(context).vehicleLabel, p.title),
                  _SumRow(AppLocalizations.of(context).durationLabel, _duration.labelFor(AppLocalizations.of(context))),
                  _SumRow(AppLocalizations.of(context).dailyRateLabel, p.rentPricePerDay != null ? _usd(p.rentPricePerDay!) : '—'),
                  _SumRow(AppLocalizations.of(context).daysCapLabel, _datesOk ? '$_days ${AppLocalizations.of(context).daysLabel}' : '—'),
                ],
                if (_isRent) ...[
                  const SizedBox(height: 8),
                  Row(children: [
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.local_offer_outlined, size: 14, color: _color),
                      const SizedBox(width: 4),
                      Text(
                        _appliedCode != null ? '${AppLocalizations.of(context).discountLabel} ($_appliedCode)' : AppLocalizations.of(context).discountLabel,
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
                  Text(AppLocalizations.of(context).total, style: TextStyle(
                      color: context.appTextPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                  Text(_usd(_total), style: TextStyle(
                      color: _color, fontSize: 22, fontWeight: FontWeight.w800)),
                ]),
              ]),
            ),
          ]),
        )),

        // Confirm — total, any submit error, then the action button.
        Container(
          padding: responsivePadding(context, maxWidth: 720, top: 14,
              bottom: 12 + MediaQuery.of(context).padding.bottom),
          decoration: BoxDecoration(
            color: context.appSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16, offset: const Offset(0, -4))],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (!_isRent || _datesOk) ...[
              Row(children: [
                Expanded(child: Text(l.totalSummaryLabel, style: TextStyle(
                    color: context.appTextSecondary, fontSize: 13, fontWeight: FontWeight.w600))),
                Text(_usd(_total), style: TextStyle(
                    color: _color, fontSize: 22, fontWeight: FontWeight.w900)),
              ]),
              const SizedBox(height: 12),
            ],
            if (_err != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                ),
                child: Row(children: [
                  const Icon(Icons.error_rounded, color: Colors.red, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_err!,
                      style: const TextStyle(color: Colors.red, fontSize: 13))),
                ]),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _busy ? null : _submit,
                style: AppTheme.confirmButtonStyle(),
                child: _busy
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(color: _white, strokeWidth: 2.5))
                    : Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.lock_rounded, size: 18),
                        const SizedBox(width: 10),
                        Flexible(child: Text(
                          _isRent
                              ? (_datesOk ? l.confirmRentalLabel : l.selectDatesToContinue)
                              : l.proceedToCheckout,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        )),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 18),
                      ]),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

// Icon-in-circle + bold title above each order-form section.
class _OrderSectionHeader extends StatelessWidget {
  final IconData icon;
  final String text;
  const _OrderSectionHeader({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Container(
        width: 36, height: 36,
        decoration: const BoxDecoration(color: AppTheme.accent, shape: BoxShape.circle),
        child: Icon(icon, color: _white, size: 19),
      ),
      const SizedBox(width: 10),
      Expanded(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: TextStyle(color: context.appTextPrimary,
              fontWeight: FontWeight.w800, fontSize: 17))),
    ]),
  );
}

class _FormCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? border;
  const _FormCard({required this.child,
      this.padding = const EdgeInsets.all(14), this.onTap, this.border});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: radius,
          border: border != null ? Border.all(color: border!) : null,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 14, offset: const Offset(0, 4))],
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class _IconBubble extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _IconBubble({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    width: 46, height: 46,
    decoration: BoxDecoration(color: _mint(context), shape: BoxShape.circle),
    child: Icon(icon, color: color, size: 22),
  );
}

// Date / duration tile in the rental-period card: mint fill, or outlined
// for the primary (start date) pick.
class _PickerTile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final String? subtitle;
  final IconData? trailing;
  final bool outlined, error;
  final VoidCallback? onTap;
  const _PickerTile({
    required this.icon, required this.label, required this.value,
    this.subtitle, this.trailing, this.outlined = false, this.error = false, this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14);
    return Material(
      color: outlined ? context.appSurface : _mint(context),
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: outlined
            ? BorderSide(color: error
                ? Colors.red.withValues(alpha: 0.4)
                : AppTheme.accent.withValues(alpha: 0.3), width: 1.2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(children: [
            Icon(icon, color: AppTheme.accent, size: 26),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: context.appTextSecondary, fontSize: 11)),
              const SizedBox(height: 2),
              Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: context.appTextPrimary,
                      fontWeight: FontWeight.w700, fontSize: 14)),
              if (subtitle != null)
                Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: context.appTextSecondary, fontSize: 11)),
            ])),
            if (trailing != null)
              Icon(trailing, color: context.appTextSecondary, size: 20),
          ]),
        ),
      ),
    );
  }
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
  Widget build(BuildContext context) => _FormCard(
    onTap: onTap,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    child: Row(children: [
      _IconBubble(icon: icon, color: color),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(color: context.appTextSecondary, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(
            color: context.appTextPrimary, fontWeight: FontWeight.w700, fontSize: 14),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        if (subtitle.isNotEmpty)
          Text(subtitle, style: TextStyle(
              color: context.appTextSecondary, fontSize: 11),
              maxLines: 1, overflow: TextOverflow.ellipsis),
      ])),
      Icon(Icons.chevron_right_rounded, color: context.appTextSecondary, size: 22),
    ]),
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
          shape: BoxShape.circle),
      child: Icon(icon, color: active ? color : Colors.grey, size: 20)),
  );
}

class _SumRow extends StatelessWidget {
  final String label, amount;
  const _SumRow(this.label, this.amount);
  // Either side can be long (a product title as the label for purchases,
  // or as the value for rentals): the label wraps in the remaining space and
  // the value keeps its natural width, capped at ~55% so neither side is
  // squeezed into a one-character column.
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: LayoutBuilder(builder: (context, c) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(label, maxLines: 3, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: context.appTextSecondary, fontSize: 13, height: 1.35)),
        ),
        const SizedBox(width: 12),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: c.maxWidth * 0.55),
          child: Text(amount, textAlign: TextAlign.right, maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: context.appTextPrimary,
                  fontWeight: FontWeight.w700, fontSize: 13, height: 1.35)),
        ),
      ],
    )),
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
        title: Text(AppLocalizations.of(context).deleteListing,
            style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w700)),
        content: Text('${p.title} ${AppLocalizations.of(context).willBePermanentlyRemoved}',
            style: const TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalizations.of(context).cancel, style: const TextStyle(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: Text(AppLocalizations.of(context).delete,
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
        Text(AppLocalizations.of(context).noListingsYetTitle,
            style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w700, fontSize: 17)),
        const SizedBox(height: 6),
        Text(AppLocalizations.of(context).postSomethingToStartSelling,
            style: TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const _PostProductScreen()))
              .then((_) => _load()),
          icon: const Icon(Icons.add_rounded),
          label: Text(AppLocalizations.of(context).postAListing,
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
                    Text(_productStatusLabel(AppLocalizations.of(context), p.status),
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
  bool _isGuest = false;
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
      if (!await ApiService.isLoggedIn()) {
        final guest = await ApiService.getGuestShopOrders();
        if (mounted) setState(() {
          _isGuest = true;
          _buying  = guest.orders;
          _selling = guest.rentals;
          _loading = false;
        });
        return;
      }
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
        case 'cancel':
          o.source == 'car_rental'
              ? await ApiService.cancelCarRental(o.id)
              : await ApiService.cancelMarketplaceOrder(o.id);
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
      if (_isGuest)
        Container(
          width: double.infinity,
          color: _green.withValues(alpha: 0.08),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(children: [
            const Icon(Icons.person_outline_rounded, color: _green, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(AppLocalizations.of(context).guestShoppingNotice,
                style: TextStyle(color: context.appTextSecondary, fontSize: 12))),
          ]),
        ),
      Padding(
        padding: responsivePadding(context, top: 14, bottom: 4),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: context.appSurface,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 14, offset: const Offset(0, 4))],
          ),
          child: TabBar(
            controller: _tc,
            indicator: BoxDecoration(
              color: AppTheme.accent,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: AppTheme.accent.withValues(alpha: 0.3),
                  blurRadius: 10, offset: const Offset(0, 3))],
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            splashBorderRadius: BorderRadius.circular(24),
            labelPadding: EdgeInsets.zero,
            labelColor: _white,
            unselectedLabelColor: context.appTextSecondary,
            labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            tabs: [
              _IconTab(icon: Icons.inventory_2_outlined, height: 46,
                  label: '${AppLocalizations.of(context).buyingTab} (${_buying.length})'),
              _IconTab(icon: Icons.key_outlined, height: 46,
                  label: '${AppLocalizations.of(context).rental} (${_selling.length})'),
            ],
          ),
        ),
      ),
      Expanded(child: TabBarView(controller: _tc, children: [
        _OrderList(orders: _buying,  isSeller: false, isGuest: _isGuest, onAction: _action, onRefresh: _load),
        _OrderList(orders: _selling, isSeller: false, isGuest: _isGuest, onAction: _action, onRefresh: _load),
      ])),
    ]);
  }
}

class _OrderList extends StatelessWidget {
  final List<MarketplaceOrderModel> orders;
  final bool isSeller;
  final bool isGuest;
  final void Function(MarketplaceOrderModel, String) onAction;
  final Future<void> Function() onRefresh;
  const _OrderList({required this.orders, required this.isSeller,
      this.isGuest = false, required this.onAction, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.receipt_long_outlined, color: Colors.grey, size: 48),
        const SizedBox(height: 12),
        Text(AppLocalizations.of(context).noOrdersYet, style: const TextStyle(color: Colors.grey, fontSize: 15)),
      ]),
    );
    return RefreshIndicator(
      onRefresh: onRefresh, color: AppTheme.accent,
      child: ListView.builder(
        padding: responsivePadding(context, top: 12, bottom: 24),
        itemCount: orders.length,
        itemBuilder: (_, i) =>
            _OrderCard(order: orders[i], isSeller: isSeller, isGuest: isGuest, onAction: onAction),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final MarketplaceOrderModel order;
  final bool isSeller;
  // Guests can only cancel — completing needs an account on the server.
  final bool isGuest;
  final void Function(MarketplaceOrderModel, String) onAction;
  const _OrderCard({required this.order, required this.isSeller,
      this.isGuest = false, required this.onAction});

  IconData _statusIcon(String status) => switch (status) {
    'confirmed' => Icons.check_circle_rounded,
    'completed' => Icons.task_alt_rounded,
    'cancelled' => Icons.schedule_rounded,
    _           => Icons.autorenew_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final l       = AppLocalizations.of(context);
    final o       = order;
    final sc      = _statusColor(o.status);
    final isRent  = o.orderType == 'rent';
    final typeClr = isRent ? _purple : AppTheme.accent;
    final canAct  = o.status == 'pending' || o.status == 'confirmed';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16, offset: const Offset(0, 5))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 104, height: 96,
              child: o.productImage != null && o.productImage!.isNotEmpty
                  ? Image.network(o.productImage!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imgFallback(typeClr, isRent))
                  : _imgFallback(typeClr, isRent),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Text(o.productTitle ?? '${l.order} #${o.id}',
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: context.appTextPrimary,
                        fontWeight: FontWeight.w800, fontSize: 14, height: 1.3))),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: sc.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(_statusIcon(o.status), color: sc, size: 12),
                    const SizedBox(width: 4),
                    Text(_orderStatusLabel(l, o.status),
                        style: TextStyle(color: sc, fontSize: 10, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: typeClr.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(isRent ? l.rental : l.purchaseLabel,
                      style: TextStyle(color: typeClr, fontSize: 11, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 8),
                Flexible(child: Text('${l.order} #${o.id}',
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: context.appTextSecondary, fontSize: 12))),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Icon(o.rentStartDate != null ? Icons.calendar_month_rounded : Icons.inventory_2_rounded,
                    color: context.appTextSecondary, size: 15),
                const SizedBox(width: 6),
                Flexible(child: Text(
                    o.rentStartDate != null
                        ? '${o.rentStartDate} → ${o.rentEndDate}'
                        : '${l.qty}: ${o.quantity}',
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: context.appTextSecondary, fontSize: 12))),
              ]),
            ]),
          )),
        ]),
        const SizedBox(height: 10),

        // ── Total + actions ─────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
          decoration: BoxDecoration(
            color: _mint(context),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.total, style: TextStyle(color: context.appTextSecondary, fontSize: 11)),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(_usd(o.totalPriceUsd), style: const TextStyle(
                    color: AppTheme.accent, fontWeight: FontWeight.w900, fontSize: 22, height: 1.2)),
              ),
            ])),
            if (canAct) ...[
              if (isSeller && o.status == 'pending') ...[
                _ActionPill(l.confirm, AppTheme.confirmBlue, Icons.check_circle_outline_rounded,
                    () => onAction(o, 'confirm')),
                const SizedBox(width: 8),
              ],
              if (!isGuest) ...[
                _ActionPill(l.done, AppTheme.confirmBlue, Icons.task_alt_rounded,
                    () => onAction(o, 'complete')),
                const SizedBox(width: 8),
              ],
              _ActionPill(l.cancel, Colors.red, Icons.cancel_outlined,
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
        color: color, size: 30)),
  );
}

class _ActionPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  const _ActionPill(this.label, this.color, this.icon, this.onTap);

  @override
  Widget build(BuildContext context) => Material(
    color: context.appSurface,
    shape: StadiumBorder(side: BorderSide(color: color.withValues(alpha: 0.4), width: 1.3)),
    child: InkWell(
      customBorder: const StadiumBorder(),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
        ]),
      ),
    ),
  );
}

// Tab with a leading icon — used by the main Browse / My Orders tabs and the
// Buying / Rental switch.
class _IconTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final double? height;
  const _IconTab({required this.icon, required this.label, this.height});

  @override
  Widget build(BuildContext context) => Tab(
    height: height,
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 19),
      const SizedBox(width: 8),
      Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)),
    ]),
  );
}


// One editable accessory row in the Post/Edit Listing form.
class _AccessoryDraft {
  final TextEditingController nameEnCtrl;
  final TextEditingController nameKmCtrl;
  final TextEditingController priceCtrl;

  _AccessoryDraft({String nameEn = '', String? nameKm, double? price})
      : nameEnCtrl = TextEditingController(text: nameEn),
        nameKmCtrl = TextEditingController(text: nameKm ?? ''),
        priceCtrl  = TextEditingController(text: price == null ? '' : '$price');

  void dispose() {
    nameEnCtrl.dispose();
    nameKmCtrl.dispose();
    priceCtrl.dispose();
  }
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
  final _qty      = TextEditingController(text: '99');

  String _type   = 'sale';
  String _cond   = 'used';
  String _status = 'active';
  final List<File> _imgs = [];
  final _picker = ImagePicker();
  bool _busy = false;
  String? _err;
  bool get _isEdit => widget.existing != null;

  List<MarketplaceCategoryModel>     _cats    = [];
  List<MarketplaceVehicleTypeModel>  _vTypes  = [];
  List<MarketplaceVehicleColorModel> _vColors = [];
  bool _refLoading = true;
  int? _categoryId;
  int? _vehicleTypeId;
  int? _vehicleColorId;
  int? _vehicleSizeId;
  // Category/vehicle-type/size are all vehicle body-style attributes — they
  // don't apply to a non-vehicle listing (helmet, spare part, accessory…).
  // Set correctly in initState() below once widget.existing is known.
  bool _isVehicleProduct = false;

  // Optional paid add-ons a buyer can tick on the Buy screen (e.g. a
  // removable canopy). Each row is its own set of controllers so the field
  // widgets stay uncontrolled-per-keystroke instead of rebuilding state on
  // every character.
  final List<_AccessoryDraft> _accessories = [];

  // Sizes are scoped to the selected vehicle type — the backend 422s on a
  // mismatched pairing (e.g. a cargo-only size picked under Passenger).
  List<MarketplaceVehicleSizeModel> get _sizesForSelectedType {
    if (_vehicleTypeId == null) return const [];
    return _vTypes.firstWhere((t) => t.id == _vehicleTypeId,
        orElse: () => const MarketplaceVehicleTypeModel(id: 0, nameEn: '', nameKm: '', slug: '')).sizes;
  }

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _title.text     = e.title;
      _desc.text      = e.description ?? '';
      _price.text     = '${e.price}';
      _rent.text      = e.rentPricePerDay != null ? '${e.rentPricePerDay}' : '';
      _location.text  = e.locationText ?? '';
      _qty.text       = '${e.quantity}';
      _type           = e.listingType;
      _cond           = e.condition ?? 'used';
      _status         = e.status;
      _categoryId     = e.categoryId;
      _vehicleTypeId  = e.vehicleTypeId;
      _vehicleColorId = e.vehicleColorId;
      _vehicleSizeId  = e.vehicleSizeId;
      _isVehicleProduct = e.categoryId != null || e.vehicleTypeId != null ||
          e.vehicleColorId != null || e.vehicleSizeId != null;
      for (final acc in e.accessories) {
        _accessories.add(_AccessoryDraft(nameEn: acc.nameEn, nameKm: acc.nameKm, price: acc.price));
      }
    }
    _loadRefData();
  }

  Future<void> _loadRefData() async {
    try {
      final results = await Future.wait([
        ApiService.getMarketplaceCategories(),
        ApiService.getMarketplaceVehicleTypes(),
        ApiService.getMarketplaceVehicleColors(),
      ]);
      if (!mounted) return;
      setState(() {
        _cats    = results[0] as List<MarketplaceCategoryModel>;
        _vTypes  = results[1] as List<MarketplaceVehicleTypeModel>;
        _vColors = results[2] as List<MarketplaceVehicleColorModel>;
        _refLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _refLoading = false);
    }
  }

  @override
  void dispose() {
    for (final c in [_title, _desc, _price, _rent, _location, _qty]) c.dispose();
    for (final a in _accessories) a.dispose();
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
    if (t.isEmpty) { setState(() => _err = AppLocalizations.of(context).titleIsRequiredError); return; }
    if (p == null) { setState(() => _err = AppLocalizations.of(context).priceMustBeNumberError); return; }
    final r = double.tryParse(_rent.text.trim());

    // Drop rows the seller started but never filled in — nothing to submit
    // for those. A row with a name but an invalid/blank price is rejected
    // rather than silently defaulting to free.
    final accessoryRows = _accessories.where((a) => a.nameEnCtrl.text.trim().isNotEmpty).toList();
    for (final a in accessoryRows) {
      if (double.tryParse(a.priceCtrl.text.trim()) == null) {
        setState(() => _err = '${AppLocalizations.of(context).enterValidPricePrefix} "${a.nameEnCtrl.text.trim()}".');
        return;
      }
    }
    final accessories = accessoryRows.map((a) => MarketplaceAccessoryInput(
      nameEn: a.nameEnCtrl.text.trim(),
      nameKm: a.nameKmCtrl.text.trim().isEmpty ? null : a.nameKmCtrl.text.trim(),
      price:  double.parse(a.priceCtrl.text.trim()),
    )).toList();

    setState(() { _busy = true; _err = null; });
    try {
      if (_isEdit) {
        await ApiService.updateMarketplaceProduct(widget.existing!.id,
            title: t, description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
            listingType: _type, condition: _cond, price: p, rentPricePerDay: r,
            quantity: int.tryParse(_qty.text.trim()) ?? 1, status: _status,
            locationText: _location.text.trim().isEmpty ? null : _location.text.trim(),
            categoryId: _categoryId, vehicleTypeId: _vehicleTypeId,
            vehicleColorId: _vehicleColorId, vehicleSizeId: _vehicleSizeId,
            accessories: accessories);
      } else {
        await ApiService.createMarketplaceProduct(
            title: t, price: p, condition: _cond, listingType: _type, status: _status,
            description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
            locationText: _location.text.trim().isEmpty ? null : _location.text.trim(),
            quantity: int.tryParse(_qty.text.trim()) ?? 1, rentPricePerDay: r, images: _imgs,
            categoryId: _categoryId, vehicleTypeId: _vehicleTypeId,
            vehicleColorId: _vehicleColorId, vehicleSizeId: _vehicleSizeId,
            accessories: accessories);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isEdit ? AppLocalizations.of(context).updatedExclaim : AppLocalizations.of(context).postedExclaim), backgroundColor: _green));
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) setState(() { _err = e.message; _busy = false; });
    } catch (e) {
      if (mounted) setState(() { _err = e.toString(); _busy = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface, elevation: 0,
        scrolledUnderElevation: 0.5, shadowColor: Colors.black12,
        leading: _BackBtn(),
        title: Text(_isEdit ? loc.editListing : loc.postAListing,
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
              _Card(title: loc.photos, subtitle: loc.upTo5,
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
                          Text('${5 - _imgs.length} ${loc.left}',
                              style: const TextStyle(color: _green, fontSize: 9,
                                  fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ),
                ]),
              ),

            _Card(title: loc.productInfo, child: Column(children: [
              _FF(ctrl: _title, label: loc.productTitle, hint: loc.egIphone14Pro),
              const SizedBox(height: 12),
              _FF(ctrl: _desc, label: loc.description,
                  hint: loc.describeProduct, maxLines: 3),
            ])),

            _Card(title: loc.whatAreYouListing, child: Row(children: [
              Expanded(child: _SelBtn(loc.vehicleOption, _isVehicleProduct, _green,
                  () => setState(() => _isVehicleProduct = true))),
              const SizedBox(width: 10),
              Expanded(child: _SelBtn(loc.accessoryOther, !_isVehicleProduct, _green,
                  () => setState(() {
                    _isVehicleProduct = false;
                    _categoryId = null; _vehicleTypeId = null;
                    _vehicleColorId = null; _vehicleSizeId = null;
                  }))),
            ])),

            if (_isVehicleProduct && !_refLoading && _cats.isNotEmpty)
              _Card(title: loc.category, subtitle: loc.optional,
                child: Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final cat in _cats)
                    _SelChip(cat.name, _categoryId == cat.id, _green,
                        () => setState(() => _categoryId = _categoryId == cat.id ? null : cat.id)),
                ]),
              ),

            if (_isVehicleProduct && !_refLoading && _vTypes.isNotEmpty)
              _Card(title: loc.vehicleType, subtitle: loc.optional,
                child: Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final vt in _vTypes)
                    _SelChip(vt.name(appLocale.value.languageCode), _vehicleTypeId == vt.id, _green,
                        () => setState(() {
                          _vehicleTypeId = _vehicleTypeId == vt.id ? null : vt.id;
                          // Selected size is only valid for the previous type.
                          _vehicleSizeId = null;
                        })),
                ]),
              ),

            if (_isVehicleProduct && !_refLoading && _sizesForSelectedType.isNotEmpty)
              _Card(title: loc.size, subtitle: loc.optional,
                child: Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final vs in _sizesForSelectedType)
                    _SelChip(vs.label, _vehicleSizeId == vs.id, _green,
                        () => setState(() => _vehicleSizeId = _vehicleSizeId == vs.id ? null : vs.id)),
                ]),
              ),

            if (_isVehicleProduct && !_refLoading && _vColors.isNotEmpty)
              _Card(title: loc.color, subtitle: loc.optional,
                child: Wrap(spacing: 14, runSpacing: 10, children: [
                  for (final vc in _vColors)
                    GestureDetector(
                      onTap: () => setState(() => _vehicleColorId = _vehicleColorId == vc.id ? null : vc.id),
                      child: Tooltip(
                        message: vc.name(appLocale.value.languageCode),
                        child: Container(
                          width: 30, height: 30,
                          decoration: BoxDecoration(
                            color: _swatchFor(vc.code),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: _vehicleColorId == vc.id ? _green : const Color(0xFFE0E0E0),
                                width: _vehicleColorId == vc.id ? 2.5 : 1),
                          ),
                          child: _vehicleColorId == vc.id
                              ? Icon(Icons.check, size: 16,
                                  color: _swatchFor(vc.code).computeLuminance() > 0.5 ? Colors.black : Colors.white)
                              : null,
                        ),
                      ),
                    ),
                ]),
              ),

            if (_isVehicleProduct)
              _Card(title: loc.accessories, subtitle: loc.optionalAddOns,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  for (int i = 0; i < _accessories.length; i++) ...[
                    if (i > 0) const SizedBox(height: 12),
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _FF(ctrl: _accessories[i].nameEnCtrl, label: loc.nameEn,
                              hint: loc.egRemovableCanopy),
                          const SizedBox(height: 8),
                          _FF(ctrl: _accessories[i].nameKmCtrl, label: loc.nameKm,
                              hint: 'e.g. ក្រណាត់ដំបូល'),
                          const SizedBox(height: 8),
                          _FF(ctrl: _accessories[i].priceCtrl, label: loc.priceUsd,
                              hint: '150', keyboardType: TextInputType.number),
                        ]),
                      ),
                      IconButton(
                        onPressed: () => setState(() {
                          _accessories[i].dispose();
                          _accessories.removeAt(i);
                        }),
                        icon: const Icon(Icons.close_rounded, color: Colors.red, size: 20),
                      ),
                    ]),
                  ],
                  if (_accessories.isNotEmpty) const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => setState(() => _accessories.add(_AccessoryDraft())),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _green.withValues(alpha: 0.4), width: 1.5),
                      ),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.add_rounded, color: _green, size: 18),
                        const SizedBox(width: 6),
                        Text(loc.addAccessory, style: const TextStyle(
                            color: _green, fontWeight: FontWeight.w700, fontSize: 13)),
                      ]),
                    ),
                  ),
                ]),
              ),

            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: _Card(title: loc.type,
                child: Column(children: [
                  for (final t in [('sale', loc.saleTypeLabel), ('rent', loc.rent), ('both', loc.bothTypeLabel)])
                    _SelBtn(t.$2, _type == t.$1, _green,
                        () => setState(() => _type = t.$1)),
                ]),
              )),
              const SizedBox(width: 12),
              Expanded(child: _Card(title: loc.condition,
                child: Column(children: [
                  for (final c in [('new', loc.conditionNewLabel), ('used', loc.conditionUsedLabel), ('refurbished', loc.conditionRefurbAbbrev)])
                    _SelBtn(c.$2, _cond == c.$1, _condColor(c.$1),
                        () => setState(() => _cond = c.$1)),
                ]),
              )),
            ]),

            _Card(title: loc.pricing, child: Column(children: [
              _FF(ctrl: _price, label: loc.priceUsd, hint: '100',
                  keyboardType: TextInputType.number),
              if (_type == 'rent' || _type == 'both') ...[
                const SizedBox(height: 12),
                _FF(ctrl: _rent, label: loc.rentPerDayUsd, hint: '10',
                    keyboardType: TextInputType.number),
              ],
              const SizedBox(height: 12),
              _FF(ctrl: _qty, label: loc.quantity, hint: '1',
                  keyboardType: TextInputType.number),
            ])),

            _Card(title: loc.location, child:
              _FF(ctrl: _location, label: loc.areaDistrictOptional,
                  hint: loc.egBkk1PhnomPenh)),

            if (_isEdit)
              _Card(title: loc.status, child: Wrap(spacing: 8, runSpacing: 8,
                children: ['draft', 'active', 'paused', 'sold'].map((s) =>
                  _SelBtn(_productStatusLabel(loc, s),
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
              style: AppTheme.confirmButtonStyle(background: _green),
              child: _busy
                  ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(color: _white, strokeWidth: 2.5))
                  : Text(_isEdit ? loc.saveChanges : loc.postListingBtn),
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

// Wrap-friendly chip variant of _SelBtn — for option groups with more than
// two or three choices (category, vehicle type, size) where a full-width
// stacked block would waste too much vertical space.
// Small icon + label header for one option group (Type/Size/Color) inside
// the "Options" card on the Buy/Rent Item screen.
class _OptionRowLabel extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _OptionRowLabel({required this.icon, required this.text, required this.color});
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 15, color: color),
    const SizedBox(width: 6),
    Text(text, style: TextStyle(
        color: context.appTextPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
  ]);
}

// Thin separator between option groups in the "Options" card.
class _OptionDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Divider(height: 1, color: context.appCardBg),
  );
}

class _SelChip extends StatelessWidget {
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;
  // No active listing exists for this option (given whatever else is
  // currently selected) — shown grayed out with a diagonal strike and not
  // tappable, instead of just disappearing or looking selectable but doing
  // nothing when tapped.
  final bool disabled;
  const _SelChip(this.label, this.active, this.color, this.onTap, {this.disabled = false});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: disabled ? null : onTap,
    child: Opacity(
      opacity: disabled ? 0.55 : 1.0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active && !disabled ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: active && !disabled ? color : const Color(0xFFE0E0E0), width: 1.5),
        ),
        child: Stack(alignment: Alignment.center, children: [
          Text(label, style: TextStyle(
              color: active && !disabled ? _white : Colors.grey.shade600,
              fontWeight: FontWeight.w600, fontSize: 12)),
          if (disabled)
            Positioned.fill(
              child: CustomPaint(painter: _StrikePainter(Colors.grey.shade500)),
            ),
        ]),
      ),
    ),
  );
}

// Draws the diagonal "unavailable" strike across a disabled _SelChip's label.
class _StrikePainter extends CustomPainter {
  final Color color;
  const _StrikePainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 1.2;
    canvas.drawLine(Offset(0, size.height), Offset(size.width, 0), paint);
  }

  @override
  bool shouldRepaint(covariant _StrikePainter oldDelegate) => oldDelegate.color != color;
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
