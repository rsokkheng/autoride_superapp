import 'package:flutter/material.dart';
import '../utils/phone_utils.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// Name + phone inputs for buying/renting without an account. Both are
/// required, and the phone is then confirmed by SMS OTP
/// (see ensureGuestPhoneVerified) before the order is sent.
class GuestFields extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController phoneCtrl;
  const GuestFields({super.key, required this.nameCtrl, required this.phoneCtrl});

  /// Returns an error message, or null when the guest details are usable.
  /// The phone must be a real Cambodian mobile number (prefix table in
  /// phone_utils, same as the backend) — every OTP is a paid SMS.
  static String? validate(AppLocalizations l, String name, String phone) {
    final n = name.trim();
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (n.isEmpty && digits.isEmpty) return l.enterNamePhoneError;
    if (n.length < 2) return l.guestFullNameRequired;
    if (digits.isEmpty) return l.guestPhoneInvalid;
    return validateLocalPhone(normalizeLocalPhone(phone));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.person_outline_rounded, color: AppTheme.accent, size: 16),
          const SizedBox(width: 6),
          Text(l.yourInformationLabel,
              style: const TextStyle(
                  color: AppTheme.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 12),
        _GuestInput(
          ctrl: nameCtrl,
          hint: l.fullNameStarHint,
          icon: Icons.badge_outlined,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 10),
        _GuestInput(
          ctrl: phoneCtrl,
          hint: l.guestPhoneStarHint,
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(13), // +855 form at most
          ],
        ),
        const SizedBox(height: 8),
        Row(children: [
          Icon(Icons.sms_outlined, color: context.appTextSecondary, size: 14),
          const SizedBox(width: 6),
          Expanded(child: Text(l.guestOtpNote,
              style: TextStyle(color: context.appTextSecondary, fontSize: 11))),
        ]),
      ]),
    );
  }
}

class _GuestInput extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  const _GuestInput({
    required this.ctrl,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      style: TextStyle(color: context.appTextPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: context.appTextSecondary, fontSize: 13),
        prefixIcon: Icon(icon, color: context.appTextSecondary, size: 18),
        filled: true,
        fillColor: context.appSurface,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}
