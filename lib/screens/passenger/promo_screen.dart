import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:autoride_superapp/theme/app_theme.dart';
import 'package:autoride_superapp/widgets/common_widgets.dart';
import 'package:autoride_superapp/services/api_service.dart';
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
        title: const Text('Promos & Vouchers'),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: AppTheme.accent,
          labelColor: AppTheme.accent,
          unselectedLabelColor: context.appTextSecondary,
          tabs: const [
            Tab(icon: Icon(Icons.local_offer_outlined), text: 'Promos'),
            Tab(icon: Icon(Icons.store_outlined), text: 'Store'),
            Tab(icon: Icon(Icons.wallet_giftcard_rounded), text: 'My Vouchers'),
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

  static const _promos = [
    _Promo(code: 'NEWUSER50', title: '50% Off First Ride', desc: 'Valid for new users only. Max discount \$5.', expiry: 'Expires Jun 30, 2026', discount: '50%', type: 'ride', color: Color(0xFF00D4AA), icon: Icons.directions_car),
    _Promo(code: 'ROTEH15', title: '15% Off Any Ride', desc: 'Use any time. Min fare \$3.00.', expiry: 'Expires May 31, 2026', discount: '15%', type: 'ride', color: Color(0xFF2196F3), icon: Icons.percent),
    _Promo(code: 'DELIVER10', title: '\$1 Off Delivery', desc: 'Valid on standard and same-day deliveries.', expiry: 'Expires Jun 15, 2026', discount: '\$1', type: 'delivery', color: Color(0xFFFF6B35), icon: Icons.delivery_dining),
    _Promo(code: 'EVCHARGE', title: 'Free EV Station Map', desc: 'Get premium station directions for free.', expiry: 'No expiry', discount: 'Free', type: 'ev', color: Color(0xFFFFB300), icon: Icons.ev_station),
    _Promo(code: 'WEEKEND20', title: '20% Off Weekends', desc: 'Valid Sat–Sun. Max discount \$8.', expiry: 'Expires Jun 30, 2026', discount: '20%', type: 'ride', color: Color(0xFF9C27B0), icon: Icons.weekend),
  ];

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
        final discount = result.discountPercent != null
            ? '${result.discountPercent!.toStringAsFixed(0)}% off'
            : result.discountAmount != null
                ? '${AppTheme.khr(result.discountAmount!)} off'
                : 'discount applied';
        setState(() => _applySuccess =
            'Promo "$code" applied — $discount${result.description != null ? '\n${result.description}' : ''}');
        _codeController.clear();
      } else {
        setState(() => _applyError = 'Invalid or expired promo code.');
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _applyError = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _applyError = 'Could not validate code. Try again.');
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
            Text('Enter Promo Code', style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
            SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _codeController,
                  style: TextStyle(color: context.appTextPrimary, letterSpacing: 1.5, fontWeight: FontWeight.w700),
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'e.g. ROTEH15',
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
                    : const Text('Apply', style: TextStyle(fontWeight: FontWeight.w800)),
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

        const SectionHeader(title: 'Available Vouchers'),
        const SizedBox(height: 12),

        ..._promos.map((p) => _PromoCard(
          promo: p,
          onCopy: () {
            Clipboard.setData(ClipboardData(text: p.code));
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Code "${p.code}" copied!'),
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
                Text('Copy', style: TextStyle(color: promo.color, fontWeight: FontWeight.w600, fontSize: 13)),
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
