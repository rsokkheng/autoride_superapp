import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/partner_package.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'partner_create_package_screen.dart';
import 'partner_package_detail_screen.dart';
import 'partner_ui.dart';

/// My Packages — tabs: On the way (Track) · History · All.
class PartnerPackagesScreen extends StatefulWidget {
  /// 0 = on the way, 1 = history, 2 = all
  final int initialTab;
  const PartnerPackagesScreen({super.key, this.initialTab = 2});

  @override
  State<PartnerPackagesScreen> createState() => _PartnerPackagesScreenState();
}

class _PartnerPackagesScreenState extends State<PartnerPackagesScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this, initialIndex: widget.initialTab.clamp(0, 2));
  final _search = TextEditingController();
  final _keys = [GlobalKey<_PackageListState>(), GlobalKey<_PackageListState>(), GlobalKey<_PackageListState>()];
  Timer? _debounce;

  @override
  void dispose() {
    _tabs.dispose();
    _search.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearch(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      for (final k in _keys) {
        k.currentState?.reload();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.pkMyPackages),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(104),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: TextField(
                controller: _search,
                onChanged: _onSearch,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: l.pkSearchHint,
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  isDense: true,
                  filled: true,
                  fillColor: context.appSurface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ),
            TabBar(
              controller: _tabs,
              labelColor: AppTheme.accent,
              indicatorColor: AppTheme.accent,
              unselectedLabelColor: context.appTextSecondary,
              tabs: [Tab(text: l.pkTabActive), Tab(text: l.pkTabHistory), Tab(text: l.pkTabAll)],
            ),
          ]),
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _PackageList(key: _keys[0], group: 'active', search: _search, empty: l.pkEmptyActive),
          _PackageList(key: _keys[1], group: 'history', search: _search, empty: l.pkEmptyHistory),
          _PackageList(key: _keys[2], group: 'all', search: _search, empty: l.pkEmptyAll),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.accent,
        foregroundColor: Colors.white,
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const PartnerCreatePackageScreen()));
          for (final k in _keys) {
            k.currentState?.reload();
          }
        },
        icon: const Icon(Icons.add_rounded),
        label: Text(l.pkCreatePackage),
      ),
    );
  }
}

class _PackageList extends StatefulWidget {
  final String group;
  final TextEditingController search;
  final String empty;
  const _PackageList({super.key, required this.group, required this.search, required this.empty});

  @override
  State<_PackageList> createState() => _PackageListState();
}

class _PackageListState extends State<_PackageList> with AutomaticKeepAliveClientMixin {
  final _items = <PartnerPackage>[];
  final _scroll = ScrollController();
  int _page = 1;
  int _lastPage = 1;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 300) _more();
    });
    reload();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> reload() async {
    setState(() { _loading = _items.isEmpty; _error = null; });
    try {
      final r = await ApiService.getPartnerPackages(group: widget.group, search: widget.search.text, page: 1);
      if (!mounted) return;
      setState(() {
        _items..clear()..addAll(r.items);
        _page = 1;
        _lastPage = r.lastPage;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _error = AppLocalizations.of(context).connectionErrorRetry; _loading = false; });
    }
  }

  Future<void> _more() async {
    if (_loadingMore || _loading || _page >= _lastPage) return;
    setState(() => _loadingMore = true);
    try {
      final r = await ApiService.getPartnerPackages(group: widget.group, search: widget.search.text, page: _page + 1);
      if (!mounted) return;
      setState(() { _items.addAll(r.items); _page++; _lastPage = r.lastPage; _loadingMore = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppTheme.accent));

    return RefreshIndicator(
      color: AppTheme.accent,
      onRefresh: reload,
      child: _items.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 120),
                Icon(_error != null ? Icons.wifi_off_rounded : Icons.inventory_2_outlined,
                    size: 56, color: context.appTextSecondary.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                Text(_error ?? widget.empty, textAlign: TextAlign.center,
                    style: TextStyle(color: context.appTextSecondary)),
              ],
            )
          : ListView.separated(
              controller: _scroll,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              itemCount: _items.length + (_loadingMore ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                if (i >= _items.length) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accent)),
                  );
                }
                return _PackageCard(
                  pkg: _items[i],
                  onTap: () async {
                    await Navigator.push(context, MaterialPageRoute(
                        builder: (_) => PartnerPackageDetailScreen(packageId: _items[i].id)));
                    reload();
                  },
                );
              },
            ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  final PartnerPackage pkg;
  final VoidCallback onTap;
  const _PackageCard({required this.pkg, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Material(
      color: context.appSurface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(PackageUi.typeIcon(pkg.packageType), size: 18, color: context.appTextSecondary),
              const SizedBox(width: 6),
              Text(pkg.code, style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
              if (pkg.serviceOption == 'express') ...[
                const SizedBox(width: 6),
                const Icon(Icons.bolt_rounded, size: 16, color: AppTheme.danger),
              ],
              const SizedBox(width: 8),
              const Spacer(),
              Flexible(flex: 3, child: PackageStatusChip(pkg.status, reason: pkg.failureReason)),
            ]),
            const SizedBox(height: 10),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.location_on_rounded, size: 16, color: AppTheme.danger),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${pkg.recipientName} · ${pkg.recipientPhone}',
                      style: TextStyle(color: context.appTextPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(pkg.dropoffAddress, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
                ]),
              ),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Text(PackageUi.date(pkg.createdAt), style: TextStyle(color: context.appTextSecondary, fontSize: 11.5)),
              if (pkg.reference != null && pkg.reference!.isNotEmpty) ...[
                Text('  ·  #${pkg.reference}', style: TextStyle(color: context.appTextSecondary, fontSize: 11.5)),
              ],
              const Spacer(),
              if (pkg.codAmount > 0) ...[
                Text('${l.pkCod} ${AppTheme.khr(pkg.codAmount)}',
                    style: const TextStyle(color: AppTheme.accentOrange, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(width: 10),
              ],
              Text(AppTheme.khr(pkg.fee),
                  style: TextStyle(color: context.appTextPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
            ]),
          ]),
        ),
      ),
    );
  }
}
