import 'dart:io';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../passenger/passenger_home.dart';
import '../driver/driver_home.dart';
import 'role_selection.dart';

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

      final destination = result.user.isDriver
          ? const DriverHomeScreen()
          : const PassengerHomeScreen();

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
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),

              // ── Logo ────────────────────────────────────────────────────
              Row(children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.accent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.electric_car, color: AppTheme.primary, size: 26),
                ),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('ROTEH', style: TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                  Text('ROTEH App', style: TextStyle(color: AppTheme.accent, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 3)),
                ]),
                const Spacer(),
                const LanguagePickerButton(),
              ]),

              const SizedBox(height: 52),

              // ── Heading ─────────────────────────────────────────────────
              const Text('Welcome back', style: TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
              const SizedBox(height: 4),
              const Text('Sign in to continue', style: TextStyle(color: AppTheme.textPrimary, fontSize: 28, fontWeight: FontWeight.w800)),

              const SizedBox(height: 36),

              // ── Error banner ────────────────────────────────────────────
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.danger.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.danger.withValues(alpha: 0.4)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline, color: AppTheme.danger, size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_error!, style: const TextStyle(color: AppTheme.danger, fontSize: 13))),
                  ]),
                ),
                const SizedBox(height: 20),
              ],

              // ── Email ───────────────────────────────────────────────────
              const Text('Email', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Enter your email',
                  prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.textSecondary, size: 20),
                  filled: true,
                  fillColor: AppTheme.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppTheme.accent, width: 1.5),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // ── Password ────────────────────────────────────────────────
              const Text('Password', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordCtrl,
                obscureText: _obscurePass,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _login(),
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Enter your password',
                  prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.textSecondary, size: 20),
                  suffixIcon: GestureDetector(
                    onTap: () => setState(() => _obscurePass = !_obscurePass),
                    child: Icon(
                      _obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: AppTheme.textSecondary,
                      size: 20,
                    ),
                  ),
                  filled: true,
                  fillColor: AppTheme.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppTheme.accent, width: 1.5),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ── Login button ────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    disabledBackgroundColor: AppTheme.accent.withValues(alpha: 0.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _loading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2.5))
                      : const Text('Sign In', style: TextStyle(color: AppTheme.primary, fontSize: 16, fontWeight: FontWeight.w800)),
                ),
              ),

              const SizedBox(height: 36),

              // ── Demo credentials hint ────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.cardBg),
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
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          Icon(
            label == 'Driver' ? Icons.drive_eta_outlined : Icons.person_outline,
            color: label == 'Driver' ? AppTheme.accentOrange : AppTheme.accent,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(width: 8),
          Expanded(child: Text(email, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12))),
          const Icon(Icons.touch_app_outlined, color: AppTheme.textSecondary, size: 14),
        ]),
      ),
    );
  }
}
