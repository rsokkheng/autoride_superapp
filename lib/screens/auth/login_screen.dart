import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/user_model.dart';
import '../../providers/biometric_provider.dart';
import '../passenger/passenger_home.dart';
import '../driver/driver_home.dart';
import '../driver/driver_approval_pending_screen.dart';
import 'role_selection.dart';
import 'register_screen.dart';
import 'account_switcher_screen.dart';
import '../admin/admin_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

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
        setState(() { _loading = false; _error = 'Google sign-in was cancelled.'; });
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
            ? 'Network error. Check your connection and try again.'
            : msg.contains('sign_in_failed') || msg.contains('10:')
                ? 'Google sign-in is not configured for this app. Contact support.'
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
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => destination));
  }

  Future<void> _login() async {
    final email    = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please enter your email and password.');
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

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => destination),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } on SocketException catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Cannot reach server.\n${e.message}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 32),

              // ── Logo ────────────────────────────────────────────────────
              Row(children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.accent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.electric_car, color: AppTheme.primary, size: 26),
                ),
                SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('ROTEH', style: TextStyle(color: context.appTextPrimary, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                  Text('ROTEH App', style: TextStyle(color: AppTheme.accent, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 3)),
                ]),
                Spacer(),
                LanguagePickerButton(),
              ]),

              SizedBox(height: 52),

              // ── Heading ─────────────────────────────────────────────────
              Text('Welcome back', style: TextStyle(color: context.appTextSecondary, fontSize: 15)),
              SizedBox(height: 4),
              Text('Sign in to continue', style: TextStyle(color: context.appTextPrimary, fontSize: 28, fontWeight: FontWeight.w800)),

              SizedBox(height: 36),

              // ── Error banner ────────────────────────────────────────────
              if (_error != null) ...[
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.danger.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.danger.withValues(alpha: 0.4)),
                  ),
                  child: Row(children: [
                    Icon(Icons.error_outline, color: AppTheme.danger, size: 18),
                    SizedBox(width: 10),
                    Expanded(child: Text(_error!, style: TextStyle(color: AppTheme.danger, fontSize: 13))),
                  ]),
                ),
                SizedBox(height: 20),
              ],

              // ── Email ───────────────────────────────────────────────────
              Text('Email', style: TextStyle(color: context.appTextSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                style: TextStyle(color: context.appTextPrimary),
                decoration: InputDecoration(
                  hintText: 'Enter your email',
                  prefixIcon: Icon(Icons.email_outlined, color: context.appTextSecondary, size: 20),
                  filled: true,
                  fillColor: context.appSurface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppTheme.accent, width: 1.5),
                  ),
                ),
              ),

              SizedBox(height: 18),

              // ── Password ────────────────────────────────────────────────
              Text('Password', style: TextStyle(color: context.appTextSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              TextField(
                controller: _passwordCtrl,
                obscureText: _obscurePass,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _login(),
                style: TextStyle(color: context.appTextPrimary),
                decoration: InputDecoration(
                  hintText: 'Enter your password',
                  prefixIcon: Icon(Icons.lock_outline, color: context.appTextSecondary, size: 20),
                  suffixIcon: GestureDetector(
                    onTap: () => setState(() => _obscurePass = !_obscurePass),
                    child: Icon(
                      _obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: context.appTextSecondary,
                      size: 20,
                    ),
                  ),
                  filled: true,
                  fillColor: context.appSurface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppTheme.accent, width: 1.5),
                  ),
                ),
              ),

              SizedBox(height: 32),

              // ── Login button ────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    disabledBackgroundColor: AppTheme.accent.withValues(alpha: 0.5),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _loading
                      ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2.5))
                      : Text('Sign In', style: TextStyle(color: AppTheme.primary, fontSize: 16, fontWeight: FontWeight.w800)),
                ),
              ),

              SizedBox(height: 20),

              // ── Divider ─────────────────────────────────────────────────
              Row(children: [
                Expanded(child: Divider(color: context.appCardBg)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('or continue with', style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
                ),
                Expanded(child: Divider(color: context.appCardBg)),
              ]),

              const SizedBox(height: 16),

              // ── Social / Phone login ────────────────────────────────────
              Row(children: [
                Expanded(
                  child: _SocialButton(
                    onTap: _loading ? null : _googleLogin,
                    icon: Icons.g_mobiledata_rounded,
                    label: 'Google',
                    iconColor: const Color(0xFFDB4437),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SocialButton(
                    onTap: _loading ? null : _phoneLogin,
                    icon: Icons.phone_rounded,
                    label: 'Phone',
                    iconColor: AppTheme.accent,
                  ),
                ),
              ]),

              const SizedBox(height: 16),

              // ── Biometric login ─────────────────────────────────────────
              Consumer<BiometricProvider>(
                builder: (context, bio, _) {
                  if (!bio.enabled || !bio.available) return const SizedBox.shrink();
                  return Column(children: [
                    Row(children: [
                      Expanded(child: Divider(color: context.appCardBg)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('or', style: TextStyle(color: context.appTextSecondary, fontSize: 13)),
                      ),
                      Expanded(child: Divider(color: context.appCardBg)),
                    ]),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _loading ? null : _biometricLogin,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.accent,
                          side: const BorderSide(color: AppTheme.accent, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.fingerprint, size: 22),
                        label: Text(
                          bio.savedEmail != null
                              ? 'Sign in as ${bio.savedEmail}'
                              : 'Sign in with Biometrics',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ]);
                },
              ),

              SizedBox(height: 4),

              // ── Create account link ──────────────────────────────────────
              Center(
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text("Don't have an account?",
                      style: TextStyle(
                          color: context.appTextSecondary, fontSize: 14)),
                  TextButton(
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => RegisterScreen())),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      minimumSize: Size.zero, tapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text('Create Account',
                        style: TextStyle(
                            color: AppTheme.accent,
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                  ),
                ]),
              ),

              SizedBox(height: 16),

              // ── Demo credentials hint ────────────────────────────────────
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.appSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.appCardBg),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Icon(Icons.info_outline, color: AppTheme.accent, size: 16),
                    const SizedBox(width: 8),
                    const Text('Demo Accounts', style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w700, fontSize: 13)),
                  ]),
                  const SizedBox(height: 12),
                  _DemoTile(
                    label: 'Passenger',
                    email: 'passenger@example.com',
                    onTap: () => setState(() {
                      _emailCtrl.text = 'passenger@example.com';
                      _passwordCtrl.text = 'password';
                    }),
                  ),
                  const SizedBox(height: 8),
                  _DemoTile(
                    label: 'Driver',
                    email: 'driver@example.com',
                    onTap: () => setState(() {
                      _emailCtrl.text = 'driver@example.com';
                      _passwordCtrl.text = 'password';
                    }),
                  ),
                  const SizedBox(height: 8),
                  _DemoTile(
                    label: 'Admin',
                    email: 'admin@example.com',
                    onTap: () => setState(() {
                      _emailCtrl.text = 'admin@example.com';
                      _passwordCtrl.text = 'password';
                    }),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final VoidCallback? onTap;
  final IconData icon;
  final String label;
  final Color iconColor;

  const _SocialButton({required this.onTap, required this.icon, required this.label, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.appCardBg),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: iconColor, size: 22),
          SizedBox(width: 8),
          Text(label, style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        ]),
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

  Future<void> _sendOtp() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) {
      setState(() => _error = 'Enter your phone number.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final result = await ApiService.sendOtp(phone);
      if (!mounted) return;
      setState(() {
        _codeSent  = true;
        _sentPhone = result.phone;
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
      setState(() => _error = 'Enter the 6-digit code.');
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
          24, 0, 24, MediaQuery.of(context).viewInsets.bottom + 32),
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
                  _codeSent = false; _error = null;
                  for (final c in _otpCtrls) c.clear();
                  _timer?.cancel();
                }),
              ),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_codeSent ? 'Enter OTP' : 'Phone Login',
                    style: TextStyle(color: context.appTextPrimary,
                        fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(
                  _codeSent
                      ? 'Code sent to ${_sentPhone ?? ''}'
                      : 'We\'ll send a one-time code via SMS',
                  style: TextStyle(color: context.appTextSecondary, fontSize: 13),
                ),
              ]),
            ),
          ]),
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
            Text('Phone Number',
                style: TextStyle(color: context.appTextSecondary,
                    fontSize: 13, fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _sendOtp(),
              style: TextStyle(color: context.appTextPrimary, fontSize: 16),
              decoration: InputDecoration(
                hintText: '+855 xx xxx xxx',
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
                    : const Text('Send OTP',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
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
                    : const Text('Verify & Sign In',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: _countdown > 0
                  ? Text('Resend code in ${_countdown}s',
                      style: TextStyle(color: context.appTextSecondary, fontSize: 13))
                  : TextButton(
                      onPressed: _loading ? null : _sendOtp,
                      child: const Text('Resend OTP',
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
  final String email;
  final VoidCallback onTap;

  const _DemoTile({required this.label, required this.email, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: context.appCardBg, borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          Icon(
            label == 'Driver' ? Icons.drive_eta_outlined : Icons.person_outline,
            color: label == 'Driver' ? AppTheme.accentOrange : AppTheme.accent,
            size: 16,
          ),
          SizedBox(width: 8),
          Text(label, style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
          SizedBox(width: 8),
          Expanded(child: Text(email, style: TextStyle(color: context.appTextSecondary, fontSize: 12))),
          Icon(Icons.touch_app_outlined, color: context.appTextSecondary, size: 14),
        ]),
      ),
    );
  }
}
