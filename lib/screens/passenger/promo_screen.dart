import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:share_plus/share_plus.dart';
import 'package:autoride_superapp/theme/app_theme.dart';
import 'package:autoride_superapp/widgets/common_widgets.dart';
import 'package:autoride_superapp/services/api_service.dart';
import '../../l10n/app_localizations.dart';
import 'voucher_screen.dart' show StoreTab, MyVouchersTab;

class PromoScreen extends StatefulWidget {
  const PromoScreen({super.key});

  @override
  State<PromoScreen> createState() => _PromoScreenState();
}

class _PromoScreenState extends State<PromoScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

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
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).promosVouchers),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: AppTheme.accent,
          labelColor: AppTheme.accent,
          unselectedLabelColor: context.appTextSecondary,
          tabs: [
            Tab(icon: const Icon(Icons.local_offer_outlined), text: AppLocalizations.of(context).promosTabLabel),
            Tab(icon: const Icon(Icons.store_outlined), text: AppLocalizations.of(context).storeTabLabel),
            Tab(icon: const Icon(Icons.wallet_giftcard_rounded), text: AppLocalizations.of(context).myVouchersTabLabel),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [_PromosTab(), StoreTab(), MyVouchersTab()],
      ),

    );
  }
}

class _PromosTab extends StatefulWidget {
  const _PromosTab();

  @override
  State<_PromosTab> createState() => _PromosTabState();
}

class _PromosTabState extends State<_PromosTab> {
  final _codeController = TextEditingController();
  String? _applyError;
  String? _applySuccess;
  String? _appliedShareUrl;
  String? _appliedCode;
  bool _applying = false;

  List<PromoModel> _promos = [];
  bool _loadingPromos = true;
  String? _promoError;

  @override
  void initState() {
    super.initState();
    _loadPromos();
  }

  Future<void> _loadPromos() async {
    setState(() { _loadingPromos = true; _promoError = null; });
    try {
      final list = await ApiService.getActivePromos();
      if (!mounted) return;
      setState(() { _promos = list; _loadingPromos = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _promoError = e.toString().replaceFirst('Exception: ', ''); _loadingPromos = false; });
    }
  }

  void _useCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    setState(() => _codeController.text = code);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${AppLocalizations.of(context).codeCopiedPrefix} "$code" ${AppLocalizations.of(context).copiedSuffix}'),
      backgroundColor: AppTheme.success,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _applyCode() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() {
      _applyError      = null;
      _applySuccess    = null;
      _appliedShareUrl = null;
      _appliedCode     = null;
      _applying        = true;
    });

    try {
      final result = await ApiService.validatePromoCode(
        code: code,
        serviceType: 'ride',
        orderAmount: 0,
      );
      if (!mounted) return;
      if (result.valid) {
        final l = AppLocalizations.of(context);
        final discount = result.discountPercent != null
            ? '${result.discountPercent!.toStringAsFixed(0)}% ${l.offSuffix}'
            : result.discountAmount != null
                ? '${AppTheme.khr(result.discountAmount!)} ${l.offSuffix}'
                : l.discountAppliedFallback;
        setState(() {
          _applySuccess = '${l.promoAppliedDashPrefix} "$code" ${l.appliedDashSuffix} $discount${result.description != null ? '\n${result.description}' : ''}';
          _appliedShareUrl = result.shareUrl;
          _appliedCode = code;
        });
        _codeController.clear();
      } else {
        setState(() => _applyError = AppLocalizations.of(context).invalidExpiredPromoCode);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _applyError = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _applyError = AppLocalizations.of(context).couldNotValidateCode);
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        // Enter code
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(color: context.appSurface, borderRadius: BorderRadius.circular(16)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(AppLocalizations.of(context).enterPromoCodeTitle, style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
            SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _codeController,
                  style: TextStyle(color: context.appTextPrimary, letterSpacing: 1.5, fontWeight: FontWeight.w700),
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context).codeHintExample,
                    hintStyle: TextStyle(color: context.appTextSecondary, letterSpacing: 0, fontWeight: FontWeight.normal),
                    filled: true,
                    fillColor: context.appCardBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _applying ? null : _applyCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _applying
                    ? SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary))
                    : Text(AppLocalizations.of(context).apply, style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            ]),
            if (_applyError != null) ...[
              const SizedBox(height: 8),
              Text(_applyError!, style: const TextStyle(color: AppTheme.danger, fontSize: 12)),
            ],
            if (_applySuccess != null) ...[
              const SizedBox(height: 8),
              Text(_applySuccess!, style: const TextStyle(color: AppTheme.success, fontSize: 12, fontWeight: FontWeight.w600)),
              if (_appliedShareUrl != null) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => Share.share(
                    'Use my code $_appliedCode for a discount on ROTEH!\n$_appliedShareUrl',
                  ),
                  icon: const Icon(Icons.share_outlined, size: 16),
                  label: Text(AppLocalizations.of(context).shareWithFriends),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.accent,
                    side: const BorderSide(color: AppTheme.accent),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                ),
              ],
            ],
          ]),
        ),
        const SizedBox(height: 20),

        SectionHeader(title: AppLocalizations.of(context).availableVouchersTitle),
        const SizedBox(height: 12),

        if (_loadingPromos)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator(color: AppTheme.accent)),
          )
        else if (_promoError != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(children: [
              Text(_promoError!, style: TextStyle(color: context.appTextSecondary), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _loadPromos, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent), child: Text(AppLocalizations.of(context).retry)),
            ]),
          )
        else if (_promos.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text(AppLocalizations.of(context).noVouchersAvailable, style: TextStyle(color: context.appTextSecondary))),
          )
        else
          ..._promos.map((p) => _PromoCard(promo: p, onUseCode: () => _useCode(p.code))),
      ],
    );
  }
}

class _PromoCard extends StatelessWidget {
  final PromoModel promo;
  final VoidCallback onUseCode;
  const _PromoCard({required this.promo, required this.onUseCode});

  static const _color = Color(0xFF00D4AA);

  static const _serviceIcons = {
    'rides':      Icons.directions_car,
    'deliveries': Icons.delivery_dining_outlined,
    'moving':     Icons.local_shipping_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final discount = promo.type == 'percent'
        ? '${promo.value.toStringAsFixed(0)}%'
        : AppTheme.khr(promo.value);
    final minOrder = promo.minOrder;
    final desc = minOrder != null && minOrder > 0
        ? '${l.minOrderPrefix} ${AppTheme.khr(minOrder)}'
        : promo.description;
    final expiresAt = promo.expiresAt;
    final expiry = expiresAt != null && expiresAt.length >= 10
        ? '${l.expiresPrefix} ${expiresAt.substring(0, 10)}'
        : l.noExpiry;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _color.withValues(alpha: 0.25)),
      ),
      child: Column(children: [
        Container(
          padding: EdgeInsets.all(16),
          child: Row(children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(_serviceIcons[promo.serviceType] ?? Icons.local_offer_outlined, color: _color, size: 26),
            ),
            SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(promo.description,
                  style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w800, fontSize: 15)),
              SizedBox(height: 4),
              if (desc.isNotEmpty) Text(desc, style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
              const SizedBox(height: 4),
              Text(expiry, style: TextStyle(color: _color, fontSize: 11, fontWeight: FontWeight.w600)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(discount, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: Row(children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _color.withValues(alpha: 0.3)),
                ),
                child: Text(promo.code,
                    style: TextStyle(color: _color, fontWeight: FontWeight.w800, letterSpacing: 1.5, fontSize: 13)),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 36,
              child: ElevatedButton(
                onPressed: onUseCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _color.withValues(alpha: 0.12),
                  foregroundColor: _color,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(l.copy, style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
