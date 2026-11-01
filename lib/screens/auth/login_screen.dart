import 'dart:async';
import 'package:autoride_superapp/utils/sheet_insets.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/guest_shop_button.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';
import '../../utils/phone_utils.dart';
import '../../models/user_model.dart';
import '../../providers/biometric_provider.dart';
import '../passenger/passenger_home.dart';
import '../driver/driver_home.dart';
import '../driver/driver_approval_pending_screen.dart';
import 'role_selection.dart';
import 'register_screen.dart';
import 'account_switcher_screen.dart';
import '../admin/admin_dashboard_screen.dart';

/// Sign-in method to launch as soon as the screen opens (from WelcomeScreen).
enum LoginStart { phone, google }

class LoginScreen extends StatefulWidget {
  final LoginStart? start;
  const LoginScreen({super.key, this.start});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePass   = true;
  bool _loading       = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final start = widget.start;
    if (start != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        start == LoginStart.phone ? _phoneLogin() : _googleLogin();
      });
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _biometricLogin() async {
    final bio = context.read<BiometricProvider>();
    if (!bio.enabled || !bio.available) return;
    setState(() { _loading = true; _error = null; });
    try {
      final result = await bio.login();
      if (!mounted) return;
      await _navigate(result.user);
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  Future<void> _googleLogin() async {
    setState(() { _loading = true; _error = null; });
    try {
      final gsi     = GoogleSignIn(scopes: ['email', 'profile']);
      final account = await gsi.signIn();
      if (!mounted) return;
      if (account == null) {
        setState(() { _loading = false; _error = AppLocalizations.of(context).trGoogleCancelled; });
        return;
      }
      final auth    = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) throw Exception('Google authentication failed — no ID token returned.');
      final result  = await ApiService.socialLogin(provider: 'google', providerToken: idToken);
      if (!mounted) return;
      await _saveAndNavigate(result.user, result.token);
    } on Exception catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      setState(() {
        _error = msg.contains('network_error') || msg.contains('NETWORK_ERROR')
            ? AppLocalizations.of(context).connectionErrorRetry
            : msg.contains('sign_in_failed') || msg.contains('10:')
                ? AppLocalizations.of(context).trGoogleNotConfigured
                : msg;
        _loading = false;
      });
    }
  }

  Future<void> _phoneLogin() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.appSurface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _PhoneOtpSheet(onLoggedIn: _saveAndNavigate),
    );
  }

  Future<void> _saveAndNavigate(UserModel user, String token) async {
    await AccountManager.save(SavedAccount(
      email: user.email, name: user.name, role: user.role, token: token,
    ));
    await _navigate(user);
  }

  Future<void> _navigate(UserModel user) async {
    Widget destination;
    if (user.role == 'admin') {
      destination = const AdminDashboardScreen();
    } else if (user.isDriver) {
      try {
        final approval = await ApiService.getDriverApprovalStatus();
        destination = approval.isApproved ? const DriverHomeScreen() : const DriverApprovalPendingScreen();
      } catch (_) {
        destination = const DriverHomeScreen();
      }
    } else {
      destination = const PassengerHomeScreen();
    }
    if (!mounted) return;
    // Clear Welcome/Login underneath — the home screen must be the first
    // route, or "back to home" (popUntil isFirst) lands on Welcome.
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => destination), (_) => false);
  }

  Future<void> _login() async {
    final email    = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = AppLocalizations.of(context).trEnterEmailPassword);
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      final result = await ApiService.login(email, password);
      if (!mounted) return;

      // Auto-save account for multi-account switcher
      await AccountManager.save(SavedAccount(
        email: result.user.email,
        name:  result.user.name,
        role:  result.user.role,
        token: result.token,
      ));

      Widget destination;
      if (result.user.role == 'admin') {
        destination = const AdminDashboardScreen();
      } else if (result.user.isDriver) {
        // Check approval status — send pending/rejected drivers to the waiting screen
        try {
          final approval = await ApiService.getDriverApprovalStatus();
          destination = approval.isApproved
              ? const DriverHomeScreen()
              : const DriverApprovalPendingScreen();
        } catch (_) {
          // If status check fails, allow into home — server will gate access
          destination = const DriverHomeScreen();
        }
      } else {
        destination = const PassengerHomeScreen();
      }

      // Register this device for push notifications now that we're
      // authenticated — fire-and-forget, shouldn't block navigation.
      NotificationService.instance.initFcm();

      if (!mounted) return;
      // Home becomes the first route (see above).
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => destination),
        (_) => false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } on SocketException catch (e) {
      if (!mounted) return;
      setState(() => _error = '${AppLocalizations.of(context).trCannotReachServer}\n${e.message}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  static const _green = GuestShopButton.green;

  bool _showDemo = false;

  void _fillDemo(String email) => setState(() {
        _emailCtrl.text = email;
        _passwordCtrl.text = 'password';
        _showDemo = false;
      });

  InputDecoration _fieldDecoration(String hint, IconData icon, {Widget? suffix}) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: context.appTextSecondary.withValues(alpha: 0.7), fontSize: 14),
        prefixIcon: Icon(icon, color: context.appTextSecondary, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: context.appBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.appCardBg),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.appCardBg),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _green, width: 1.5),
        ),
      );

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: TextStyle(color: context.appTextPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
      );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: context.appBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            // ── Top bar ──────────────────────────────────────────────────
            Row(children: [
              if (canPop)
                Material(
                  color: context.appSurface,
                  shape: const CircleBorder(),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.appTextPrimary, size: 18),
                  ),
                ),
              const Spacer(),
              const LanguagePickerButton(),
            ]),

            const SizedBox(height: 24),

            // ── Brand + heading ──────────────────────────────────────────
            Center(
              child: Container(
                width: 76, height: 76,
                decoration: BoxDecoration(
                  color: _green.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(14),
                child: Image.asset('assets/library/icon_fa.png'),
              ),
            ),
            const SizedBox(height: 18),
            Text(l.welcomeBack,
                textAlign: TextAlign.center,
                style: TextStyle(color: context.appTextPrimary, fontSize: 26, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(l.signInSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(color: context.appTextSecondary, fontSize: 14, height: 1.4)),

            const SizedBox(height: 28),

            // ── Form card ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.appSurface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 24, offset: const Offset(0, 8)),
                ],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.danger.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.error_outline_rounded, color: AppTheme.danger, size: 18),
                      const SizedBox(width: 10),
                      Expanded(child: Text(_error!, style: const TextStyle(color: AppTheme.danger, fontSize: 13))),
                    ]),
                  ),
                  const SizedBox(height: 18),
                ],

                _label(l.email),
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  autofillHints: const [AutofillHints.email],
                  style: TextStyle(color: context.appTextPrimary, fontSize: 15),
                  decoration: _fieldDecoration(l.enterEmail, Icons.mail_outline_rounded),
                ),

                const SizedBox(height: 18),

                _label(l.password),
                TextField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePass,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  onSubmitted: (_) => _login(),
                  style: TextStyle(color: context.appTextPrimary, fontSize: 15),
                  decoration: _fieldDecoration(
                    l.enterPassword,
                    Icons.lock_outline_rounded,
                    suffix: IconButton(
                      onPressed: () => setState(() => _obscurePass = !_obscurePass),
                      icon: Icon(
                        _obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: context.appTextSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green,
                      disabledBackgroundColor: _green.withValues(alpha: 0.5),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : Text(l.signIn, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
                ),

                // ── Biometric sign-in ──────────────────────────────────────
                Consumer<BiometricProvider>(
                  builder: (context, bio, _) {
                    if (!bio.enabled || !bio.available) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: _loading ? null : _biometricLogin,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _green,
                            side: BorderSide(color: _green.withValues(alpha: 0.6), width: 1.2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.fingerprint_rounded, size: 22),
                          label: Text(
                            bio.savedEmail != null ? '${l.signInAs} ${bio.savedEmail}' : l.signInWithBiometrics,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ]),
            ),

            const SizedBox(height: 20),

            // ── Create account ───────────────────────────────────────────
            Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center, children: [
              Text(l.noAccountYet, style: TextStyle(color: context.appTextSecondary, fontSize: 14)),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RegisterScreen())),
                style: TextButton.styleFrom(
                  foregroundColor: _green,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(l.createAccount, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              ),
            ]),

            const SizedBox(height: 20),

            // ── Trust note ───────────────────────────────────────────────
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.lock_rounded, color: context.appTextSecondary, size: 14),
              const SizedBox(width: 6),
              Flexible(
                child: Text(l.secureSignInNote,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
              ),
            ]),

            const SizedBox(height: 12),

            // ── Demo accounts (collapsed) ────────────────────────────────
            Center(
              child: TextButton.icon(
                onPressed: () => setState(() => _showDemo = !_showDemo),
                style: TextButton.styleFrom(foregroundColor: context.appTextSecondary),
                icon: Icon(_showDemo ? Icons.expand_less_rounded : Icons.expand_more_rounded, size: 18),
                label: Text(l.demoAccounts, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ),
            if (_showDemo)
              Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [
                _DemoTile(label: AppLocalizations.of(context).passenger, icon: Icons.person_outline_rounded,
                    onTap: () => _fillDemo('sokkhnegry168@gmail.com')),
                _DemoTile(label: AppLocalizations.of(context).driver, icon: Icons.drive_eta_outlined,
                    onTap: () => _fillDemo('driver@example.com')),
                _DemoTile(label: AppLocalizations.of(context).trAdminRole, icon: Icons.admin_panel_settings_outlined,
                    onTap: () => _fillDemo('admin@example.com')),
              ]),
          ]),
        ),
      ),
    );
  }
}

// ── Phone OTP bottom sheet ────────────────────────────────────────────────────

class _PhoneOtpSheet extends StatefulWidget {
  final Future<void> Function(UserModel user, String token) onLoggedIn;
  const _PhoneOtpSheet({required this.onLoggedIn});

  @override
  State<_PhoneOtpSheet> createState() => _PhoneOtpSheetState();
}

class _PhoneOtpSheetState extends State<_PhoneOtpSheet> {
  final _phoneCtrl = TextEditingController();
  final List<TextEditingController> _otpCtrls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocus = List.generate(6, (_) => FocusNode());

  bool _codeSent  = false;
  bool _loading   = false;
  String? _error;
  String? _sentPhone;
  int? _devCode; // dev-mode backend returns the code directly (no real SMS)

  // Resend countdown
  int _countdown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    for (final c in _otpCtrls) c.dispose();
    for (final f in _otpFocus) f.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        if (_countdown > 0) { _countdown--; } else { t.cancel(); }
      });
    });
  }

  // Normalizes the user's digits-only input into E.164 for Cambodia
  // (+855...), which is what the backend's OTP endpoints expect.
  String _normalizePhone(String digits) {
    var d = digits.replaceAll(RegExp(r'[^0-9]'), '');
    if (d.startsWith('855')) d = d.substring(3);
    if (d.startsWith('0')) d = d.substring(1);
    return '+855$d';
  }

  Future<void> _sendOtp() async {
    final raw = _phoneCtrl.text.trim();
    if (raw.isEmpty) {
      setState(() => _error = AppLocalizations.of(context).trEnterYourPhone);
      return;
    }
    final phoneError = validateLocalPhone(normalizeLocalPhone(raw));
    if (phoneError != null) {
      setState(() => _error = phoneError);
      return;
    }
    final phone = _normalizePhone(raw);
    setState(() { _loading = true; _error = null; });
    try {
      final result = await ApiService.sendOtp(phone);
      if (!mounted) return;
      setState(() {
        _codeSent  = true;
        _sentPhone = result.phone;
        _devCode   = result.code;
        _loading   = false;
      });
      _startCountdown();
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _otpFocus[0].requestFocus();
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  Future<void> _verifyOtp() async {
    final code = _otpCtrls.map((c) => c.text).join();
    if (code.length < 6) {
      setState(() => _error = AppLocalizations.of(context).enterSixDigitCode);
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final result = await ApiService.loginWithOtp(_sentPhone!, code);
      if (!mounted) return;
      Navigator.pop(context);
      await widget.onLoggedIn(result.user, result.token);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() { _error = e.message; _loading = false; });
      for (final c in _otpCtrls) c.clear();
      _otpFocus[0].requestFocus();
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 0, 24, MediaQuery.of(context).sheetBottomInset + 32),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(height: 12),
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: context.appCardBg,
                  borderRadius: BorderRadius.circular(2)))),
          SizedBox(height: 24),

          Row(children: [
            if (_codeSent)
              IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded,
                    color: context.appTextSecondary, size: 18),
                onPressed: _loading ? null : () => setState(() {
                  _codeSent = false; _error = null; _devCode = null;
                  for (final c in _otpCtrls) c.clear();
                  _timer?.cancel();
                }),
              ),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_codeSent ? AppLocalizations.of(context).trEnterOtp : AppLocalizations.of(context).trPhoneLogin,
                    style: TextStyle(color: context.appTextPrimary,
                        fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(
                  _codeSent
                      ? AppLocalizations.of(context).trCodeSentTo(_sentPhone ?? '')
                      : AppLocalizations.of(context).trWeSendSmsCode,
                  style: TextStyle(color: context.appTextSecondary, fontSize: 13),
                ),
              ]),
            ),
          ]),
          if (_codeSent && _devCode != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.info_outline, color: AppTheme.accent, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).trDevModeCode(_devCode),
                    style: const TextStyle(color: AppTheme.accent, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ]),
            ),
          ],
          SizedBox(height: 24),

          // Error
          if (_error != null) ...[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                Icon(Icons.error_outline, color: AppTheme.danger, size: 16),
                SizedBox(width: 8),
                Expanded(child: Text(_error!,
                    style: TextStyle(color: AppTheme.danger, fontSize: 13))),
              ]),
            ),
            SizedBox(height: 16),
          ],

          if (!_codeSent) ...[
            // Phone number input
            Text(AppLocalizations.of(context).phoneNumber,
                style: TextStyle(color: context.appTextSecondary,
                    fontSize: 13, fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+]'))],
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _sendOtp(),
              style: TextStyle(color: context.appTextPrimary, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'xxx xxx xxx',
                hintStyle: TextStyle(color: context.appTextSecondary),
                prefixIcon: Icon(Icons.phone_outlined,
                    color: context.appTextSecondary, size: 20),
                filled: true,
                fillColor: context.appCardBg,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppTheme.accent, width: 1.5)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _sendOtp,
                style: AppTheme.confirmButtonStyle(background: AppTheme.accent),
                child: _loading
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : Text(AppLocalizations.of(context).sendOtp),
              ),
            ),
          ] else ...[
            // OTP boxes
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (i) => _OtpBox(
                  controller: _otpCtrls[i],
                  focusNode: _otpFocus[i],
                  onChanged: (v) {
                    if (v.isNotEmpty && i < 5) _otpFocus[i + 1].requestFocus();
                    if (v.isEmpty && i > 0) _otpFocus[i - 1].requestFocus();
                    if (i == 5 && v.isNotEmpty) {
                      final code = _otpCtrls.map((c) => c.text).join();
                      if (code.length == 6) _verifyOtp();
                    }
                  },
                ))),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  disabledBackgroundColor: AppTheme.accent.withValues(alpha: 0.4),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : Text(AppLocalizations.of(context).verifyAndSignIn,
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: _countdown > 0
                  ? Text(AppLocalizations.of(context).trResendCodeIn(_countdown),
                      style: TextStyle(color: context.appTextSecondary, fontSize: 13))
                  : TextButton(
                      onPressed: _loading ? null : _sendOtp,
                      child: Text(AppLocalizations.of(context).resendOtp,
                          style: TextStyle(color: AppTheme.accent,
                              fontWeight: FontWeight.w700, fontSize: 14)),
                    ),
            ),
          ],
        ]),
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 54,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        maxLength: 1,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: TextStyle(color: context.appTextPrimary,
            fontSize: 22, fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: context.appCardBg,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.accent, width: 2)),
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: onChanged,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _DemoTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _DemoTile({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: onTap,
      avatar: Icon(icon, size: 16, color: GuestShopButton.green),
      label: Text(label, style: TextStyle(color: context.appTextPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
      backgroundColor: context.appSurface,
      side: BorderSide(color: context.appCardBg),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
