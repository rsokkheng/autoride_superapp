import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/payment_logo.dart';

/// ABA PayWay KHQR checkout. Shows the KHQR (payable from ABA Mobile or any
/// KHQR bank app such as ACLEDA), opens ABA Mobile directly, and waits for
/// the server to confirm the payment with PayWay. Pops `true` once paid.
class PayWayCheckoutScreen extends StatefulWidget {
  /// Response of ApiService.createPayWayKhqr / createPayWayForOrder.
  final Map<String, dynamic> checkout;
  /// Guest checkouts (no account) poll with their guest token.
  final String? guestToken;
  const PayWayCheckoutScreen({super.key, required this.checkout, this.guestToken});

  @override
  State<PayWayCheckoutScreen> createState() => _PayWayCheckoutScreenState();
}

class _PayWayCheckoutScreenState extends State<PayWayCheckoutScreen> with WidgetsBindingObserver {
  Timer? _poll;
  Timer? _tick;
  String _status = 'pending';
  Duration _left = Duration.zero;
  bool _checking = false;

  String get _tranId => widget.checkout['tran_id'] as String;
  num get _amount => (widget.checkout['amount'] as num?) ?? 0;
  bool get _isUsd => widget.checkout['currency']?.toString().toUpperCase() == 'USD';
  bool get _isTopUp => (widget.checkout['purpose'] ?? 'topup') == 'topup';
  String get _amountText => _isUsd ? 'USD ${_amount.toStringAsFixed(2)}' : AppTheme.khr(_amount.round());
  DateTime? get _expiresAt => DateTime.tryParse(widget.checkout['expires_at']?.toString() ?? '')?.toLocal();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _poll = Timer.periodic(const Duration(seconds: 3), (_) => _check());
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => _updateLeft());
    _updateLeft();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _poll?.cancel();
    _tick?.cancel();
    super.dispose();
  }

  // Back from ABA Mobile — check straight away.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  void _updateLeft() {
    final exp = _expiresAt;
    if (exp == null || !mounted) return;
    final left = exp.difference(DateTime.now());
    setState(() => _left = left.isNegative ? Duration.zero : left);
  }

  Future<void> _check() async {
    if (_checking || _status != 'pending') return;
    _checking = true;
    try {
      final r = await ApiService.getPayWayStatus(_tranId, guestToken: widget.guestToken);
      if (!mounted) return;
      final status = r['status']?.toString() ?? 'pending';
      if (status != _status) setState(() => _status = status);
      if (status != 'pending') {
        _poll?.cancel();
        _tick?.cancel();
        if (status == 'paid') _onPaid();
      }
    } catch (_) {
      // Network blip — keep polling.
    } finally {
      _checking = false;
    }
  }

  Future<void> _onPaid() async {
    final l = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        icon: const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 52),
        title: Text(l.paywayPaidTitle, textAlign: TextAlign.center),
        content: Text(_isTopUp ? l.paywayPaidBody(_amountText) : l.paywayOrderPaidBody(_amountText),
            textAlign: TextAlign.center),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: AppTheme.confirmButtonStyle(),
              child: Text(l.ok),
            ),
          ),
        ],
      ),
    );
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _openAba() async {
    final link = widget.checkout['abapay_deeplink']?.toString();
    final store = Theme.of(context).platform == TargetPlatform.iOS
        ? widget.checkout['app_store']?.toString()
        : widget.checkout['play_store']?.toString();
    var opened = false;
    if (link != null && link.isNotEmpty) {
      try {
        opened = await launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication);
      } catch (_) {}
    }
    // ABA Mobile not installed — offer the store page.
    if (!opened && store != null && store.isNotEmpty) {
      try { await launchUrl(Uri.parse(store), mode: LaunchMode.externalApplication); } catch (_) {}
    }
  }

  Widget _qr() {
    final img = widget.checkout['qr_image']?.toString() ?? '';
    final comma = img.indexOf(',');
    if (img.startsWith('data:image') && comma > 0) {
      try {
        return Image.memory(base64Decode(img.substring(comma + 1)), width: 260, height: 260, fit: BoxFit.contain);
      } catch (_) {}
    }
    return SizedBox(
      width: 260, height: 260,
      child: Center(child: Icon(Icons.qr_code_2_rounded, size: 120, color: context.appTextSecondary)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final expired = _status == 'expired' || (_status == 'pending' && _expiresAt != null && _left == Duration.zero);
    final failed  = _status == 'failed' || _status == 'cancelled';
    final mm = _left.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = _left.inSeconds.remainder(60).toString().padLeft(2, '0');

    return Scaffold(
      appBar: AppBar(title: Text(l.paywayTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const PaymentLogo(method: 'aba', size: 34),
              const SizedBox(width: 8),
              const PaymentLogo(method: 'acleda', size: 34),
              const SizedBox(width: 10),
              Flexible(
                child: Text(l.paywayScanHint,
                    style: TextStyle(color: context.appTextSecondary, fontSize: 12.5, height: 1.35)),
              ),
            ]),
            const SizedBox(height: 18),
            Center(
              child: Text(_amountText,
                  style: TextStyle(color: context.appTextPrimary, fontSize: 30, fontWeight: FontWeight.w900)),
            ),
            const SizedBox(height: 16),
            Center(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, 6))],
                ),
                child: Opacity(opacity: (expired || failed) ? 0.25 : 1, child: _qr()),
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: expired
                  ? Text(l.paywayExpired, style: const TextStyle(color: AppTheme.danger, fontWeight: FontWeight.w700))
                  : failed
                      ? Text(l.paywayFailed, style: const TextStyle(color: AppTheme.danger, fontWeight: FontWeight.w700))
                      : Row(mainAxisSize: MainAxisSize.min, children: [
                          const SizedBox(width: 14, height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accent)),
                          const SizedBox(width: 8),
                          Text('${l.paywayWaiting}  $mm:$ss',
                              style: TextStyle(color: context.appTextSecondary, fontWeight: FontWeight.w600)),
                        ]),
            ),
            const SizedBox(height: 22),
            if (!expired && !failed)
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _openAba,
                  style: AppTheme.confirmButtonStyle(background: const Color(0xFF005D80)),
                  icon: const PaymentLogo(method: 'aba', size: 26),
                  label: Text(l.paywayOpenAba),
                ),
              )
            else
              SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l.trGoBack),
                ),
              ),
            const SizedBox(height: 10),
            if (!expired && !failed)
              TextButton(
                onPressed: _check,
                child: Text(l.paywayIPaid),
              ),
            const SizedBox(height: 6),
            Text('${l.paywayRef}: $_tranId',
                textAlign: TextAlign.center,
                style: TextStyle(color: context.appTextSecondary, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
