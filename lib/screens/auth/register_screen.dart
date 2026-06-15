import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

const _green = Color(0xFF00C48C);

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey  = GlobalKey<FormState>();
  final _namCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _confCtrl  = TextEditingController();

  String  _role       = 'passenger';
  String  _driverType = 'motorcycle';
  bool    _obscureP  = true;
  bool    _obscureC  = true;
  bool    _loading   = false;
  String? _error;

  @override
  void dispose() {
    _namCtrl.dispose(); _emailCtrl.dispose(); _phoneCtrl.dispose();
    _passCtrl.dispose(); _confCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await ApiService.register(
        name:                 _namCtrl.text.trim(),
        email:                _emailCtrl.text.trim(),
        password:             _passCtrl.text,
        passwordConfirmation: _confCtrl.text,
        phone:                _phoneCtrl.text.trim().isEmpty
            ? null : _phoneCtrl.text.trim(),
        role:       _role,
        driverType: _role == 'driver' ? _driverType : null,
      );
      if (!mounted) return;
      // Replace entire stack so back doesn't go to register
      Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
    } on ApiException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: const BackButton(color: AppTheme.textPrimary),
        title: const Text('Create Account',
            style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Logo / header
              Center(
                child: Column(children: [
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      color: _green.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.directions_car_rounded,
                        color: _green, size: 36),
                  ),
                  const SizedBox(height: 12),
                  const Text('Join AutoRide',
                      style: TextStyle(fontSize: 22,
                          fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                  const SizedBox(height: 4),
                  const Text('Fast, safe rides in Phnom Penh',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                ]),
              ),
              const SizedBox(height: 28),

              // Role selector
              const Text('I want to',
                  style: TextStyle(color: AppTheme.textSecondary,
                      fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(children: [
                _RoleChip(
                  label: 'Ride as Passenger',
                  icon: Icons.person_outline,
                  selected: _role == 'passenger',
                  onTap: () => setState(() => _role = 'passenger'),
                ),
                const SizedBox(width: 10),
                _RoleChip(
                  label: 'Drive & Earn',
                  icon: Icons.local_taxi_outlined,
                  selected: _role == 'driver',
                  onTap: () => setState(() => _role = 'driver'),
                ),
              ]),
              if (_role == 'driver') ...[
                const SizedBox(height: 12),
                const Text('Vehicle Type',
                    style: TextStyle(color: AppTheme.textSecondary,
                        fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final t in ['motorcycle', 'tuk_tuk', 'car', 'van', 'truck'])
                    GestureDetector(
                      onTap: () => setState(() => _driverType = t),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _driverType == t
                              ? _green.withValues(alpha: 0.15)
                              : AppTheme.surface,
                          border: Border.all(
                            color: _driverType == t
                                ? _green : AppTheme.cardBg,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          t.replaceAll('_', ' ').toUpperCase(),
                          style: TextStyle(
                            color: _driverType == t
                                ? _green : AppTheme.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ]),
              ],
              const SizedBox(height: 20),

              _Field(
                controller: _namCtrl,
                label: 'Full Name',
                hint: 'Sokha Chan',
                icon: Icons.person_outline,
                validator: (v) => (v?.trim().isEmpty ?? true) ? 'Name is required' : null,
              ),
              const SizedBox(height: 14),
              _Field(
                controller: _emailCtrl,
                label: 'Email',
                hint: 'you@example.com',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email is required';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              _Field(
                controller: _phoneCtrl,
                label: 'Phone (optional)',
                hint: '+855 12 345 678',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 14),
              _Field(
                controller: _passCtrl,
                label: 'Password',
                hint: '••••••••',
                icon: Icons.lock_outline,
                obscureText: _obscureP,
                suffixIcon: IconButton(
                  icon: Icon(_obscureP ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                      color: AppTheme.textSecondary, size: 20),
                  onPressed: () => setState(() => _obscureP = !_obscureP),
                ),
                validator: (v) => (v?.length ?? 0) < 8
                    ? 'At least 8 characters' : null,
              ),
              const SizedBox(height: 14),
              _Field(
                controller: _confCtrl,
                label: 'Confirm Password',
                hint: '••••••••',
                icon: Icons.lock_outline,
                obscureText: _obscureC,
                suffixIcon: IconButton(
                  icon: Icon(_obscureC ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                      color: AppTheme.textSecondary, size: 20),
                  onPressed: () => setState(() => _obscureC = !_obscureC),
                ),
                validator: (v) => v != _passCtrl.text
                    ? 'Passwords do not match' : null,
              ),
              const SizedBox(height: 20),

              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.danger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppTheme.danger.withValues(alpha: 0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline,
                        color: AppTheme.danger, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!,
                        style: const TextStyle(
                            color: AppTheme.danger, fontSize: 13))),
                  ]),
                ),
                const SizedBox(height: 16),
              ],

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _loading
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white))
                      : const Text('Create Account',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 16),

              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('Already have an account? ',
                    style: TextStyle(color: AppTheme.textSecondary)),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text('Sign In',
                      style: TextStyle(color: _green,
                          fontWeight: FontWeight.w700)),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String    label;
  final IconData  icon;
  final bool      selected;
  final VoidCallback onTap;
  const _RoleChip({required this.label, required this.icon,
      required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? _green.withValues(alpha: 0.1) : AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? _green : AppTheme.cardBg, width: 1.5),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon,
              color: selected ? _green : AppTheme.textSecondary, size: 22),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: selected ? _green : AppTheme.textSecondary,
              )),
        ]),
      ),
    ),
  );
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String  label;
  final String  hint;
  final IconData icon;
  final bool    obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(
          color: AppTheme.textPrimary, fontSize: 13,
          fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      TextFormField(
        controller:   controller,
        obscureText:  obscureText,
        keyboardType: keyboardType,
        validator:    validator,
        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
        decoration: InputDecoration(
          hintText:     hint,
          prefixIcon:   Icon(icon, color: AppTheme.textSecondary, size: 20),
          suffixIcon:   suffixIcon,
          filled:       true,
          fillColor:    AppTheme.cardBg,
          border:       OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _green, width: 1.5)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: AppTheme.danger, width: 1.5)),
          focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: AppTheme.danger, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
        ),
      ),
    ]);
  }
}
