import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:autoride_superapp/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../utils/phone_utils.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  String _originalPhone = '';
  String? _photoUrl;
  bool _loading = true;
  bool _saving  = false;
  bool _uploadingPhoto = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _changePhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: context.appSurface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: Icon(Icons.photo_camera_outlined, color: AppTheme.accent),
            title: Text('Take a photo', style: TextStyle(color: context.appTextPrimary)),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: Icon(Icons.photo_library_outlined, color: AppTheme.accent),
            title: Text('Choose from gallery', style: TextStyle(color: context.appTextPrimary)),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (source == null) return;

    final picked = await ImagePicker().pickImage(
        source: source, maxWidth: 1024, maxHeight: 1024, imageQuality: 85);
    if (picked == null || !mounted) return;

    setState(() => _uploadingPhoto = true);
    try {
      final url = await ApiService.uploadAvatar(File(picked.path));
      if (!mounted) return;
      setState(() => _photoUrl = url);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Could not update photo: ${e.message}'),
        backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Could not update photo. Try again.'),
        backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _loadProfile() async {
    setState(() { _loading = true; _error = null; });
    try {
      final user = await ApiService.getMe();
      if (!mounted) return;
      setState(() {
        _nameCtrl.text  = user.name;
        _emailCtrl.text = user.email;
        _phoneCtrl.text = user.phone;
        _originalPhone  = user.phone;
        _photoUrl       = user.photoUrl;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _save() async {
    final newPhone = _phoneCtrl.text.trim().isEmpty
        ? '' : normalizeLocalPhone(_phoneCtrl.text);
    if (newPhone.isNotEmpty) {
      final phoneError = validateLocalPhone(newPhone);
      if (phoneError != null) {
        setState(() => _error = phoneError);
        return;
      }
    }
    final phoneChanged = newPhone.isNotEmpty && newPhone != _originalPhone;

    if (phoneChanged) {
      // Require OTP verification before saving
      final verified = await _verifyPhoneWithOtp(newPhone);
      if (!verified || !mounted) return;
    }

    setState(() => _saving = true);
    try {
      await ApiService.updateProfile(
        name:  _nameCtrl.text.trim().isNotEmpty  ? _nameCtrl.text.trim()  : null,
        phone: newPhone.isNotEmpty               ? newPhone               : null,
        email: _emailCtrl.text.trim().isNotEmpty ? _emailCtrl.text.trim() : null,
      );
      if (!mounted) return;
      setState(() { _saving = false; _originalPhone = newPhone; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Profile updated successfully!'),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message),
        backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString()),
        backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  /// Shows the OTP bottom-sheet flow. Returns true if verified.
  Future<bool> _verifyPhoneWithOtp(String phone) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.appSurface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _OtpSheet(phone: phone),
    );
    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.error_outline, color: AppTheme.danger, size: 40),
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: AppTheme.danger), textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () { setState(() { _loading = true; _error = null; }); _loadProfile(); },
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
                        child: const Text('Retry', style: TextStyle(color: AppTheme.primary)),
                      ),
                    ]),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(children: [
                    const SizedBox(height: 8),

                    // Avatar
                    GestureDetector(
                      onTap: _uploadingPhoto ? null : _changePhoto,
                      child: Stack(children: [
                        CircleAvatar(
                          radius: 52,
                          backgroundColor: AppTheme.accent.withValues(alpha: 0.2),
                          backgroundImage: _photoUrl != null && _photoUrl!.isNotEmpty
                              ? NetworkImage(_photoUrl!)
                              : null,
                          child: _photoUrl == null || _photoUrl!.isEmpty
                              ? Icon(Icons.person, color: AppTheme.accent, size: 52)
                              : null,
                        ),
                        if (_uploadingPhoto)
                          const Positioned.fill(
                            child: CircleAvatar(
                              backgroundColor: Colors.black45,
                              child: SizedBox(
                                width: 24, height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              ),
                            ),
                          ),
                        Positioned(
                          bottom: 0, right: 0,
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(color: AppTheme.accent, shape: BoxShape.circle),
                            child: Icon(Icons.camera_alt, color: AppTheme.primary, size: 16),
                          ),
                        ),
                      ]),
                    ),
                    SizedBox(height: 8),
                    Text('Tap photo to change', style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
                    SizedBox(height: 28),

                    _Field(label: 'Full Name',    controller: _nameCtrl,  icon: Icons.person_outline),
                    SizedBox(height: 14),
                    _Field(label: 'Email',        controller: _emailCtrl, icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress),
                    SizedBox(height: 14),

                    // Phone field with OTP badge
                    Stack(alignment: Alignment.centerRight, children: [
                      _Field(label: 'Phone Number', controller: _phoneCtrl, icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                      if (_phoneCtrl.text.trim() != _originalPhone)
                        Positioned(
                          right: 14,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                color: AppTheme.warning.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.warning.withValues(alpha: 0.4))),
                            child: Text('OTP required', style: TextStyle(color: AppTheme.warning, fontSize: 10, fontWeight: FontWeight.w700)),
                          ),
                        ),
                    ]),
                    SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Changing your phone number requires OTP verification.',
                          style: TextStyle(color: context.appTextSecondary, fontSize: 11)),
                    ),
                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: AppTheme.confirmButtonStyle(
                          background: AppTheme.accent, foreground: AppTheme.primary),
                        child: _saving
                            ? const SizedBox(width: 22, height: 22,
                                child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2.5))
                            : const Text('Save Changes'),
                      ),
                    ),
                  ]),
                ),
    );
  }
}

// ── OTP bottom sheet ────────────────────────────────────────────────────────────
class _OtpSheet extends StatefulWidget {
  final String phone;
  const _OtpSheet({required this.phone});

  @override
  State<_OtpSheet> createState() => _OtpSheetState();
}

class _OtpSheetState extends State<_OtpSheet> {
  final _codeCtrl = TextEditingController();
  bool _sending   = false;
  bool _verifying = false;
  bool _sent      = false;
  int? _devCode;   // shown in dev mode from API response
  String? _error;

  // 10-minute countdown
  int _secondsLeft = 600;
  Timer? _countdown;

  @override
  void initState() {
    super.initState();
    _sendOtp();
  }

  @override
  void dispose() {
    _countdown?.cancel();
    _codeCtrl.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _countdown?.cancel();
    _secondsLeft = 600;
    _countdown = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_secondsLeft <= 1) {
        t.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  String get _countdownLabel {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}';
  }

  Future<void> _sendOtp() async {
    setState(() { _sending = true; _error = null; });
    try {
      final result = await ApiService.sendOtp(widget.phone);
      if (!mounted) return;
      setState(() {
        _sending = false;
        _sent    = true;
        _devCode = result.code;
      });
      _startCountdown();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() { _sending = false; _error = e.message; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _sending = false; _error = e.toString(); });
    }
  }

  Future<void> _verify() async {
    final code = _codeCtrl.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Enter the 6-digit code.');
      return;
    }
    setState(() { _verifying = true; _error = null; });
    try {
      await ApiService.verifyOtp(widget.phone, code);
      if (!mounted) return;
      Navigator.pop(context, true); // verified
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() { _verifying = false; _error = e.message; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _verifying = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + keyboardHeight),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle
        Container(width: 40, height: 4,
            decoration: BoxDecoration(color: context.appCardBg, borderRadius: BorderRadius.circular(2))),
        SizedBox(height: 20),

        // Icon + title
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppTheme.accent.withValues(alpha: 0.12), shape: BoxShape.circle),
          child: Icon(Icons.phone_android, color: AppTheme.accent, size: 32),
        ),
        SizedBox(height: 14),
        Text('Verify Phone Number',
            style: TextStyle(color: context.appTextPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text('A 6-digit code was sent to\n${widget.phone}',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.appTextSecondary, fontSize: 13, height: 1.5)),

        // Dev mode code hint
        if (_devCode != null) ...[
          SizedBox(height: 10),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
                color: AppTheme.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.warning.withValues(alpha: 0.4))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.developer_mode, color: AppTheme.warning, size: 16),
              SizedBox(width: 6),
              Text('Dev code: $_devCode',
                  style: TextStyle(color: AppTheme.warning, fontWeight: FontWeight.w700, fontSize: 13)),
            ]),
          ),
        ],

        SizedBox(height: 24),

        if (_sending) ...[
          CircularProgressIndicator(color: AppTheme.accent),
          SizedBox(height: 12),
          Text('Sending OTP...', style: TextStyle(color: context.appTextSecondary)),
        ] else if (_sent) ...[
          // 6-digit input
          TextField(
            controller: _codeCtrl,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.appTextPrimary, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: 10),
            decoration: InputDecoration(
              counterText: '',
              hintText: '000000',
              hintStyle: TextStyle(color: context.appTextSecondary.withValues(alpha: 0.4), letterSpacing: 10),
              filled: true,
              fillColor: context.appCardBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppTheme.accent, width: 1.5)),
            ),
          ),
          SizedBox(height: 12),

          // Countdown
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.timer_outlined,
                color: _secondsLeft <= 60 ? AppTheme.danger : context.appTextSecondary, size: 15),
            SizedBox(width: 5),
            Text(
              _secondsLeft > 0 ? 'Expires in $_countdownLabel' : 'Code expired',
              style: TextStyle(
                  color: _secondsLeft <= 60 ? AppTheme.danger : context.appTextSecondary,
                  fontSize: 13),
            ),
          ]),
        ],

        // Error
        if (_error != null) ...[
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
                color: AppTheme.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.danger.withValues(alpha: 0.4))),
            child: Row(children: [
              Icon(Icons.error_outline, color: AppTheme.danger, size: 16),
              SizedBox(width: 8),
              Expanded(child: Text(_error!, style: TextStyle(color: AppTheme.danger, fontSize: 13))),
            ]),
          ),
        ],

        SizedBox(height: 20),

        // Actions
        if (_sent) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_verifying || _secondsLeft == 0) ? null : _verify,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: AppTheme.primary,
                padding: EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _verifying
                  ? SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2.5))
                  : Text('Verify', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            ),
          ),
          SizedBox(height: 10),
          TextButton(
            onPressed: (_sending || _secondsLeft > 0) ? null : _sendOtp,
            child: Text(
              _secondsLeft > 0 ? 'Resend in $_countdownLabel' : 'Resend OTP',
              style: TextStyle(
                color: _secondsLeft > 0 ? context.appTextSecondary : AppTheme.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ] else if (!_sending) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _sendOtp,
              style: AppTheme.confirmButtonStyle(
                background: AppTheme.accent, foreground: AppTheme.primary),
              child: const Text('Send OTP'),
            ),
          ),
        ],
      ]),
    );
  }
}

// ── Text field ─────────────────────────────────────────────────────────────────
class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _Field({required this.label, required this.controller, required this.icon,
    this.keyboardType = TextInputType.text, this.inputFormatters});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: TextStyle(color: context.appTextPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: context.appTextSecondary),
        prefixIcon: Icon(icon, color: context.appTextSecondary, size: 20),
        filled: true,
        fillColor: context.appSurface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.accent, width: 1.5),
        ),
      ),
    );
  }
}
