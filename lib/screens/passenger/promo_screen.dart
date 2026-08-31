import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _applying = false;

  List<_Promo> _promos(BuildContext context) {
    final l = AppLocalizations.of(context);
    return [
      _Promo(code: 'NEWUSER50', title: l.promo1Title, desc: l.promo1Desc, expiry: '${l.expiresPrefix} Jun 30, 2026', discount: '50%', type: 'ride', color: const Color(0xFF00D4AA), icon: Icons.directions_car),
      _Promo(code: 'ROTEH15', title: l.promo2Title, desc: l.promo2Desc, expiry: '${l.expiresPrefix} May 31, 2026', discount: '15%', type: 'ride', color: const Color(0xFF2196F3), icon: Icons.percent),
      _Promo(code: 'DELIVER10', title: l.promo3Title, desc: l.promo3Desc, expiry: '${l.expiresPrefix} Jun 15, 2026', discount: '\$1', type: 'delivery', color: const Color(0xFFFF6B35), icon: Icons.delivery_dining),
      _Promo(code: 'EVCHARGE', title: l.promo4Title, desc: l.promo4Desc, expiry: l.noExpiry, discount: l.freeLabel, type: 'ev', color: const Color(0xFFFFB300), icon: Icons.ev_station),
      _Promo(code: 'WEEKEND20', title: l.promo5Title, desc: l.promo5Desc, expiry: '${l.expiresPrefix} Jun 30, 2026', discount: '20%', type: 'ride', color: const Color(0xFF9C27B0), icon: Icons.weekend),
    ];
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
      _applyError   = null;
      _applySuccess = null;
      _applying     = true;
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
        setState(() => _applySuccess =
            '${l.promoAppliedDashPrefix} "$code" ${l.appliedDashSuffix} $discount${result.description != null ? '\n${result.description}' : ''}');
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
            ],
          ]),
        ),
        const SizedBox(height: 20),

        SectionHeader(title: AppLocalizations.of(context).availableVouchersTitle),
        const SizedBox(height: 12),

        ..._promos(context).map((p) => _PromoCard(
          promo: p,
          onCopy: () {
            Clipboard.setData(ClipboardData(text: p.code));
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('${AppLocalizations.of(context).codeCopiedPrefix} "${p.code}" ${AppLocalizations.of(context).copiedSuffix}'),
              backgroundColor: AppTheme.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              duration: const Duration(seconds: 2),
            ));
          },
        )),
      ],
    );
  }
}

class _PromoCard extends StatelessWidget {
  final _Promo promo;
  final VoidCallback onCopy;
  const _PromoCard({required this.promo, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: promo.color.withValues(alpha: 0.25)),
      ),
      child: Column(children: [
        // Top band
        Container(
          padding: EdgeInsets.all(16),
          child: Row(children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: promo.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(promo.icon, color: promo.color, size: 26),
            ),
            SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(promo.title,
                  style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w800, fontSize: 15)),
              SizedBox(height: 4),
              Text(promo.desc, style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
              const SizedBox(height: 4),
              Text(promo.expiry, style: TextStyle(color: promo.color, fontSize: 11, fontWeight: FontWeight.w600)),
            ])),
            // Discount badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: promo.color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(promo.discount, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
            ),
          ]),
        ),

        // Dashed divider
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: List.generate(28, (i) => Expanded(child: Container(
            height: 1,
            color: i.isEven ? promo.color.withValues(alpha: 0.3) : Colors.transparent,
          )))),
        ),

        // Code + copy
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: promo.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: promo.color.withValues(alpha: 0.3), style: BorderStyle.solid),
              ),
              child: Text(promo.code,
                  style: TextStyle(color: promo.color, fontWeight: FontWeight.w800, letterSpacing: 1.5, fontSize: 13)),
            ),
            const Spacer(),
            GestureDetector(
              onTap: onCopy,
              child: Row(children: [
                Icon(Icons.copy, color: promo.color, size: 16),
                const SizedBox(width: 4),
                Text(AppLocalizations.of(context).copy, style: TextStyle(color: promo.color, fontWeight: FontWeight.w600, fontSize: 13)),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _Promo {
  final String code, title, desc, expiry, discount, type;
  final Color color;
  final IconData icon;
  const _Promo({required this.code, required this.title, required this.desc, required this.expiry,
    required this.discount, required this.type, required this.color, required this.icon});
}
