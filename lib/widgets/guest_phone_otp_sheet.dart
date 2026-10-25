import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

/// Verifies a guest shopper's [phone] by SMS OTP before each buy/rent
/// request — every guest order asks for a fresh code. Returns true once the
/// code is confirmed, false if the user closes the dialog.
Future<bool> ensureGuestPhoneVerified(BuildContext context, String phone) async {
  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _GuestOtpDialog(phone: phone.trim()),
  );
  return ok == true;
}

class _GuestOtpDialog extends StatefulWidget {
  final String phone;
  const _GuestOtpDialog({required this.phone});

  @override
  State<_GuestOtpDialog> createState() => _GuestOtpDialogState();
}

class _GuestOtpDialogState extends State<_GuestOtpDialog> {
  static const _codeLength    = 6;
  static const _validFor      = Duration(minutes: 3); // backend OTP lifetime
  static const _resendSeconds = 60;                   // backend resend cooldown

  final _codeCtrl  = TextEditingController();
  final _codeFocus = FocusNode();
  bool      _sending   = true;
  bool      _verifying = false;
  String?   _error;
  String?   _devCode;
  DateTime? _expiresAt;
  DateTime? _resendAt;
  Timer?    _ticker;

  @override
  void initState() {
    super.initState();
    _codeCtrl.addListener(() => setState(() {}));
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    _send();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _codeCtrl.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  Duration get _timeLeft {
    final left = _expiresAt?.difference(DateTime.now()) ?? Duration.zero;
    return left.isNegative ? Duration.zero : left;
  }

  int get _resendIn {
    final left = _resendAt?.difference(DateTime.now()).inSeconds ?? 0;
    return left < 0 ? 0 : left;
  }

  bool get _expired => !_sending && _expiresAt != null && _timeLeft == Duration.zero;

  Future<void> _send() async {
    setState(() { _sending = true; _error = null; });
    try {
      final res = await ApiService.sendOtp(ApiService.otpPhone(widget.phone));
      if (!mounted) return;
      final now = DateTime.now();
      setState(() {
        _sending   = false;
        _expiresAt = now.add(_validFor);
        _resendAt  = now.add(const Duration(seconds: _resendSeconds));
        _codeCtrl.clear();
        // The server only returns the code in debug builds of the backend.
        _devCode = kDebugMode ? res.code?.toString() : null;
      });
      _codeFocus.requestFocus();
    } on ApiException catch (e) {
      if (mounted) setState(() { _sending = false; _error = e.message; });
    } catch (_) {
      if (mounted) {
        setState(() {
          _sending = false;
          _error = AppLocalizations.of(context).connectionErrorRetry;
        });
      }
    }
  }

  Future<void> _verify() async {
    final code = _codeCtrl.text.trim();
    if (code.length != _codeLength || _verifying || _expired) return;
    setState(() { _verifying = true; _error = null; });
    try {
      await ApiService.verifyGuestPhone(widget.phone, code);
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) setState(() { _verifying = false; _error = e.message; });
    } catch (_) {
      if (mounted) {
        setState(() {
          _verifying = false;
          _error = AppLocalizations.of(context).connectionErrorRetry;
        });
      }
    }
  }

  // '012345678' / '+85512345678' → '+855 12 345 678'
  static String _displayPhone(String phone) {
    var d = phone.replaceAll(RegExp(r'\D'), '');
    if (d.startsWith('855')) d = d.substring(3);
    d = d.replaceFirst(RegExp(r'^0+'), '');
    if (d.length < 5) return phone;
    final rest = d.substring(2);
    final groups = <String>[];
    for (var i = 0; i < rest.length; i += 3) {
      groups.add(rest.substring(i, i + 3 > rest.length ? rest.length : i + 3));
    }
    return '+855 ${d.substring(0, 2)} ${groups.join(' ')}';
  }

  static String _mmss(Duration d) =>
      '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Dialog(
      backgroundColor: context.appSurface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Close
          Align(
            alignment: Alignment.centerRight,
            child: Material(
              color: context.appCardBg,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Navigator.pop(context, false),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(Icons.close_rounded, color: context.appTextPrimary, size: 22),
                ),
              ),
            ),
          ),
          const _OtpIllustration(),
          const SizedBox(height: 16),

          Text(l.confirmOtpTitle, textAlign: TextAlign.center, style: TextStyle(
              color: context.appTextPrimary, fontWeight: FontWeight.w800, fontSize: 22)),
          const SizedBox(height: 8),
          Text(l.otpSentToYourPhone, textAlign: TextAlign.center,
              style: TextStyle(color: context.appTextSecondary, fontSize: 14)),
          const SizedBox(height: 4),
          Text(_displayPhone(widget.phone), textAlign: TextAlign.center, style: TextStyle(
              color: context.appTextPrimary, fontWeight: FontWeight.w700, fontSize: 18)),
          if (_devCode != null) ...[
            const SizedBox(height: 4),
            Text('${l.devCodePrefix} $_devCode',
                style: const TextStyle(color: AppTheme.warning, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
          const SizedBox(height: 20),

          _CodeBoxes(
            controller: _codeCtrl,
            focusNode: _codeFocus,
            length: _codeLength,
            enabled: !_sending && !_verifying,
            onCompleted: _verify,
          ),
          const SizedBox(height: 16),

          // Expiry countdown
          if (_sending)
            Text(l.sendingOtpEllipsis,
                style: TextStyle(color: context.appTextSecondary, fontSize: 13))
          else if (_expiresAt != null)
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.schedule_rounded,
                  color: _expired ? AppTheme.danger : AppTheme.accent, size: 20),
              const SizedBox(width: 8),
              if (_expired)
                Text(l.codeExpired, style: const TextStyle(
                    color: AppTheme.danger, fontWeight: FontWeight.w700, fontSize: 14))
              else ...[
                Text(l.expiresInPrefix,
                    style: TextStyle(color: context.appTextSecondary, fontSize: 14)),
                const SizedBox(width: 6),
                Text(_mmss(_timeLeft), style: const TextStyle(
                    color: AppTheme.accent, fontWeight: FontWeight.w800, fontSize: 16)),
              ],
            ]),

          if (_error != null) ...[
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.error_outline, color: AppTheme.danger, size: 16),
              const SizedBox(width: 6),
              Flexible(child: Text(_error!, textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.danger, fontSize: 12))),
            ]),
          ],
          const SizedBox(height: 18),

          // Confirm
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _sending || _verifying || _expired ||
                      _codeCtrl.text.length != _codeLength
                  ? null
                  : _verify,
              style: AppTheme.confirmButtonStyle(background: AppTheme.accent),
              child: _verifying
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.check_circle_outline_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text(l.confirm),
                    ]),
            ),
          ),
          const SizedBox(height: 10),

          // Resend
          Material(
            color: context.appCardBg,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _sending || _resendIn > 0 ? null : _send,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: [
                    Text(l.didntReceiveCode,
                        style: TextStyle(color: context.appTextSecondary, fontSize: 13)),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.refresh_rounded, size: 18,
                          color: _resendIn > 0 || _sending
                              ? context.appTextSecondary : AppTheme.accent),
                      const SizedBox(width: 4),
                      Text(
                        _resendIn > 0 ? '${l.resendShort} (${_resendIn}s)' : l.resendShort,
                        style: TextStyle(
                            color: _resendIn > 0 || _sending
                                ? context.appTextSecondary : AppTheme.accent,
                            fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Six digit boxes over one hidden TextField (keeps paste / SMS autofill).
class _CodeBoxes extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final int length;
  final bool enabled;
  final VoidCallback onCompleted;
  const _CodeBoxes({
    required this.controller,
    required this.focusNode,
    required this.length,
    required this.enabled,
    required this.onCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final code = controller.text;
    return GestureDetector(
      onTap: () => focusNode.requestFocus(),
      child: Stack(children: [
        // Invisible input that actually receives the keystrokes.
        Positioned.fill(
          child: Opacity(
            opacity: 0,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: enabled,
              autofocus: true,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              maxLength: length,
              showCursor: false,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(counterText: '', border: InputBorder.none),
              onChanged: (v) { if (v.length == length) onCompleted(); },
            ),
          ),
        ),
        IgnorePointer(
          child: Row(children: [
            for (var i = 0; i < length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(child: _box(context, i, code)),
            ],
          ]),
        ),
      ]),
    );
  }

  Widget _box(BuildContext context, int i, String code) {
    final filled = i < code.length;
    final active = focusNode.hasFocus &&
        (i == code.length || (code.length == length && i == length - 1));
    return AspectRatio(
      aspectRatio: 0.9,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppTheme.accent.withValues(alpha: 0.06) : context.appSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? AppTheme.accent : context.appCardBg,
            width: active ? 2 : 1.5,
          ),
        ),
        child: Text(filled ? code[i] : '', style: TextStyle(
            color: context.appTextPrimary, fontWeight: FontWeight.w700, fontSize: 24)),
      ),
    );
  }
}

/// Shield + phone with an SMS bubble, drawn from icons (no image asset).
class _OtpIllustration extends StatelessWidget {
  const _OtpIllustration();

  @override
  Widget build(BuildContext context) {
    final mint = AppTheme.accent.withValues(alpha: 0.12);
    return SizedBox(
      width: 200, height: 140,
      child: Stack(alignment: Alignment.center, children: [
        Container(width: 130, height: 130,
            decoration: BoxDecoration(color: mint, shape: BoxShape.circle)),
        Positioned(left: 14, top: 34,
            child: Transform.rotate(angle: -0.5,
                child: Icon(Icons.eco_rounded, color: AppTheme.accent.withValues(alpha: 0.35), size: 34))),
        Positioned(right: 12, bottom: 22,
            child: Transform.rotate(angle: 0.4,
                child: Icon(Icons.eco_rounded, color: AppTheme.accent.withValues(alpha: 0.35), size: 30))),
        // Phone
        Positioned(right: 48, top: 4,
          child: Container(
            width: 64, height: 116,
            decoration: BoxDecoration(
              color: context.appSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.accent, width: 3),
            ),
            alignment: Alignment.topCenter,
            child: Container(
              margin: const EdgeInsets.only(top: 6),
              width: 22, height: 4,
              decoration: BoxDecoration(color: AppTheme.accent, borderRadius: BorderRadius.circular(2)),
            ),
          ),
        ),
        // SMS bubble
        Positioned(right: 30, top: 34,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: context.appSurface,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8)],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: List.generate(4, (_) =>
              Container(
                width: 6, height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(color: context.appTextPrimary, shape: BoxShape.circle),
              ))),
          ),
        ),
        // Shield with lock
        Positioned(left: 50, bottom: 10,
          child: SizedBox(
            width: 70, height: 80,
            child: Stack(alignment: Alignment.center, children: [
              const Icon(Icons.shield_rounded, color: AppTheme.accent, size: 78),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Icon(Icons.lock_rounded, color: Colors.white.withValues(alpha: 0.95), size: 30),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}
