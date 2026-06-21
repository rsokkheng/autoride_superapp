import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

const _green = Color(0xFF00C48C);

class OtpScreen extends StatefulWidget {
  final String phone;
  final String? expectedCode;
  final VoidCallback? onVerified;

  const OtpScreen({
    super.key,
    required this.phone,
    this.expectedCode,
    this.onVerified,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _ctls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _nodes = List.generate(6, (_) => FocusNode());

  bool    _verifying  = false;
  bool    _resending  = false;
  String? _error;
  int     _resendSecs = 60;
  Timer?  _resendTimer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    for (final c in _ctls) c.dispose();
    for (final n in _nodes) n.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendSecs = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _resendSecs--);
      if (_resendSecs <= 0) t.cancel();
    });
  }

  String get _code => _ctls.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
    if (value.length > 1) {
      // Handle paste
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (int i = 0; i < 6 && i < digits.length; i++) {
        _ctls[i].text = digits[i];
      }
      _nodes[5].requestFocus();
      if (digits.length >= 6) _verify();
      return;
    }
    if (value.isNotEmpty && index < 5) {
      _nodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _nodes[index - 1].requestFocus();
    }
    if (_code.length == 6) _verify();
  }

  Future<void> _verify() async {
    if (_verifying || _code.length < 6) return;
    setState(() { _verifying = true; _error = null; });
    try {
      await ApiService.verifyOtp(widget.phone, _code);
      if (!mounted) return;
      if (widget.onVerified != null) {
        widget.onVerified!();
      } else {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
      }
    } on ApiException catch (e) {
      setState(() { _error = e.message; _verifying = false; });
      for (final c in _ctls) c.clear();
      _nodes[0].requestFocus();
    } catch (e) {
      setState(() { _error = e.toString(); _verifying = false; });
    }
  }

  Future<void> _resend() async {
    if (_resending || _resendSecs > 0) return;
    setState(() { _resending = true; _error = null; });
    try {
      await ApiService.sendOtp(widget.phone);
      if (!mounted) return;
      _startResendTimer();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('New code sent'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _green,
      ));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final maskedPhone = _maskPhone(widget.phone);
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        elevation: 0,
        leading: BackButton(color: context.appTextPrimary),
        title: Text('Verify Phone',
            style: TextStyle(
                color: context.appTextPrimary, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
            SizedBox(height: 20),

            // Icon
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: _green.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.sms_outlined, color: _green, size: 34),
            ),
            SizedBox(height: 20),

            Text('Enter verification code',
                style: TextStyle(fontSize: 20,
                    fontWeight: FontWeight.w800, color: context.appTextPrimary)),
            SizedBox(height: 8),
            Text(
              'A 6-digit code was sent to $maskedPhone',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: context.appTextSecondary, fontSize: 14),
            ),
            SizedBox(height: 36),

            // OTP boxes
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:
              List.generate(6, (i) => _OtpBox(
                controller: _ctls[i],
                focusNode:  _nodes[i],
                hasError:   _error != null,
                onChanged:  (v) => _onDigitChanged(i, v),
              )),
            ),
            SizedBox(height: 20),

            if (_error != null)
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  Icon(Icons.error_outline,
                      color: AppTheme.danger, size: 16),
                  SizedBox(width: 8),
                  Expanded(child: Text(_error!,
                      style: TextStyle(
                          color: AppTheme.danger, fontSize: 13))),
                ]),
              ),
            SizedBox(height: 28),

            // Verify button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: (_verifying || _code.length < 6) ? null : _verify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _verifying
                    ? SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white))
                    : Text('Verify',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            SizedBox(height: 20),

            // Resend
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text("Didn't receive the code? ",
                  style: TextStyle(color: context.appTextSecondary)),
              _resendSecs > 0
                  ? Text('Resend in ${_resendSecs}s',
                      style: TextStyle(color: context.appTextSecondary))
                  : GestureDetector(
                      onTap: _resending ? null : _resend,
                      child: _resending
                          ? const SizedBox(width: 14, height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: _green))
                          : const Text('Resend',
                              style: TextStyle(color: _green,
                                  fontWeight: FontWeight.w700)),
                    ),
            ]),
          ]),
        ),
      ),
    );
  }

  String _maskPhone(String phone) {
    if (phone.length <= 4) return phone;
    return '${phone.substring(0, phone.length - 4).replaceAll(RegExp(r'\d'), '•')}${phone.substring(phone.length - 4)}';
  }
}

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final ValueChanged<String> onChanged;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.hasError,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46, height: 56,
      child: TextFormField(
        controller:       controller,
        focusNode:        focusNode,
        textAlign:        TextAlign.center,
        keyboardType:     TextInputType.number,
        maxLength:        6,
        onChanged:        onChanged,
        inputFormatters:  [FilteringTextInputFormatter.digitsOnly],
        style: TextStyle(
            fontSize: 22, fontWeight: FontWeight.w700,
            color: context.appTextPrimary),
        decoration: InputDecoration(
          counterText:    '',
          filled:         true,
          fillColor:      context.appCardBg,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _green, width: 2)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: AppTheme.danger, width: 2)),
          enabledBorder: hasError ? OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: AppTheme.danger.withValues(alpha: 0.5))) : null,
        ),
      ),
    );
  }
}
