import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../driver/driver_document_upload_screen.dart';

const _green = Color(0xFF00C48C);

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _namCtrl     = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _confCtrl    = TextEditingController();
  final _cityCtrl    = TextEditingController();
  final _referCtrl   = TextEditingController();

  String  _role        = 'passenger';
  String  _driverType  = 'owner';
  bool    _obscureP   = true;
  bool    _obscureC   = true;
  bool    _loading    = false;
  String? _error;

  static const _driverTypes = [
    ('owner',    'Owner',    Icons.person_outlined),
    ('employee', 'Employee', Icons.badge_outlined),
    ('rental',   'Rental',   Icons.car_rental_outlined),
  ];

  static const _cities = [
    'Phnom Penh', 'Siem Reap', 'Sihanoukville', 'Battambang',
    'Kampong Cham', 'Kampot', 'Kep', 'Poipet',
  ];

  @override
  void dispose() {
    _namCtrl.dispose(); _emailCtrl.dispose(); _phoneCtrl.dispose();
    _passCtrl.dispose(); _confCtrl.dispose();
    _cityCtrl.dispose(); _referCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      final result = await ApiService.register(
        name:                 _namCtrl.text.trim(),
        email:                _emailCtrl.text.trim(),
        password:             _passCtrl.text,
        passwordConfirmation: _confCtrl.text,
        phone:                _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        role:                 _role,
        driverType:           _role == 'driver' ? _driverType : null,
        city:                 _role == 'driver' && _cityCtrl.text.trim().isNotEmpty
                                  ? _cityCtrl.text.trim() : null,
        referredByCode:       _referCtrl.text.trim().isEmpty ? null : _referCtrl.text.trim(),
      );
      if (!mounted) return;

      if (_role == 'driver') {
        // Drivers must upload documents before going online
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => DriverDocumentUploadScreen(userId: result.user.id)),
        );
      } else {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
      }
    } on ApiException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        elevation: 0,
        leading: BackButton(color: context.appTextPrimary),
        title: Text('Create Account',
            style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(
                child: Column(children: [
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      color: _green.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset('assets/library/icon_fa.png', width: 40, height: 40),
                  ),
                  SizedBox(height: 12),
                  Text('Join ROTEH',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: context.appTextPrimary)),
                  SizedBox(height: 4),
                  Text('Fast, safe rides in Cambodia',
                      style: TextStyle(color: context.appTextSecondary, fontSize: 13)),
                ]),
              ),
              SizedBox(height: 28),

              // ── Role ──────────────────────────────────────────────────────
              Text('I want to',
                  style: TextStyle(color: context.appTextSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Row(children: [
                _RoleChip(
                  label: 'Ride as Passenger',
                  icon:  Icons.person_outline,
                  selected: _role == 'passenger',
                  onTap: () => setState(() => _role = 'passenger'),
                ),
                SizedBox(width: 10),
                _RoleChip(
                  label: 'Drive & Earn',
                  icon:  Icons.electric_rickshaw,
                  selected: _role == 'driver',
                  onTap: () => setState(() => _role = 'driver'),
                ),
              ]),
              SizedBox(height: 20),

              // ── Driver-only fields ────────────────────────────────────────
              if (_role == 'driver') ...[
                Text('Driver Type',
                    style: TextStyle(color: context.appTextSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(children: _driverTypes.map((t) {
                  final selected = _driverType == t.$1;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _driverType = t.$1),
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 150),
                        margin: EdgeInsets.only(right: t.$1 == 'rental' ? 0 : 8),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: selected ? _green.withValues(alpha: 0.1) : context.appSurface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: selected ? _green : Colors.transparent, width: 1.5),
                        ),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(t.$3, color: selected ? _green : context.appTextSecondary, size: 20),
                          SizedBox(height: 4),
                          Text(t.$2,
                              style: TextStyle(
                                  color: selected ? _green : context.appTextSecondary,
                                  fontSize: 11, fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ),
                  );
                }).toList()),
                SizedBox(height: 14),

                // City
                _Label('City'),
                SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _cityCtrl.text.isEmpty ? null : _cityCtrl.text,
                  dropdownColor: context.appSurface,
                  style: TextStyle(color: context.appTextPrimary, fontSize: 14),
                  decoration: _inputDecoration('Select your city', Icons.location_city_outlined),
                  items: _cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => _cityCtrl.text = v ?? '',
                  validator: (v) => (v == null || v.isEmpty) ? 'City is required' : null,
                ),
                const SizedBox(height: 14),
              ],

              // ── Common fields ─────────────────────────────────────────────
              _Field(
                controller: _namCtrl,
                label: 'Full Name', hint: 'Sokha Chan',
                icon:  Icons.person_outline,
                validator: (v) => (v?.trim().isEmpty ?? true) ? 'Name is required' : null,
              ),
              const SizedBox(height: 14),
              _Field(
                controller: _emailCtrl,
                label: 'Email', hint: 'you@example.com',
                icon:  Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email is required';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              SizedBox(height: 14),
              _Field(
                controller: _phoneCtrl,
                label: 'Phone (optional)', hint: '+855 963430534',
                icon:  Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              SizedBox(height: 14),
              _Field(
                controller: _passCtrl,
                label: 'Password', hint: '••••••••',
                icon:  Icons.lock_outline,
                obscureText: _obscureP,
                suffixIcon: IconButton(
                  icon: Icon(_obscureP ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: context.appTextSecondary, size: 20),
                  onPressed: () => setState(() => _obscureP = !_obscureP),
                ),
                validator: (v) => (v?.length ?? 0) < 8 ? 'At least 8 characters' : null,
              ),
              SizedBox(height: 14),
              _Field(
                controller: _confCtrl,
                label: 'Confirm Password', hint: '••••••••',
                icon:  Icons.lock_outline,
                obscureText: _obscureC,
                suffixIcon: IconButton(
                  icon: Icon(_obscureC ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: context.appTextSecondary, size: 20),
                  onPressed: () => setState(() => _obscureC = !_obscureC),
                ),
                validator: (v) => v != _passCtrl.text ? 'Passwords do not match' : null,
              ),
              SizedBox(height: 14),
              _Field(
                controller: _referCtrl,
                label: 'Referral Code (optional)', hint: 'ROTEH2026',
                icon:  Icons.card_giftcard_outlined,
              ),
              SizedBox(height: 20),

              if (_error != null) ...[
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.danger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
                  ),
                  child: Row(children: [
                    Icon(Icons.error_outline, color: AppTheme.danger, size: 18),
                    SizedBox(width: 8),
                    Expanded(child: Text(_error!,
                        style: TextStyle(color: AppTheme.danger, fontSize: 13))),
                  ]),
                ),
                SizedBox(height: 16),
              ],

              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _loading
                      ? SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : Text(_role == 'driver' ? 'Register & Upload Documents' : 'Create Account',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              SizedBox(height: 16),

              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('Already have an account? ',
                    style: TextStyle(color: context.appTextSecondary)),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text('Sign In',
                      style: TextStyle(color: _green, fontWeight: FontWeight.w700)),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _Label(String text) => Text(text,
      style: TextStyle(color: context.appTextSecondary, fontSize: 13, fontWeight: FontWeight.w600));

  InputDecoration _inputDecoration(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: context.appTextSecondary),
    prefixIcon: Icon(icon, color: context.appTextSecondary, size: 20),
    filled: true,
    fillColor: context.appSurface,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}

// ── Shared input widget ───────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String        label;
  final String        hint;
  final IconData      icon;
  final bool          obscureText;
  final Widget?       suffixIcon;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText  = false,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: TextStyle(color: context.appTextSecondary,
              fontSize: 13, fontWeight: FontWeight.w600)),
      SizedBox(height: 6),
      TextFormField(
        controller:   controller,
        obscureText:  obscureText,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: TextStyle(color: context.appTextPrimary),
        decoration: InputDecoration(
          hintText:    hint,
          hintStyle:   TextStyle(color: context.appTextSecondary),
          prefixIcon:  Icon(icon, color: context.appTextSecondary, size: 20),
          suffixIcon:  suffixIcon,
          filled:      true,
          fillColor:   context.appSurface,
          border:      OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        validator: validator,
      ),
    ]);
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
        duration: Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? _green.withValues(alpha: 0.1) : context.appSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? _green : Colors.transparent, width: 1.5),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: selected ? _green : context.appTextSecondary, size: 18),
          SizedBox(width: 6),
          Text(label, style: TextStyle(
              color: selected ? _green : context.appTextSecondary,
              fontWeight: FontWeight.w600, fontSize: 13)),
        ]),
      ),
    ),
  );
}
