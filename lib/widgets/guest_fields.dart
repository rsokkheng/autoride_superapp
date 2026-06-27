import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GuestFields extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController phoneCtrl;
  const GuestFields({super.key, required this.nameCtrl, required this.phoneCtrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.person_outline_rounded, color: AppTheme.accent, size: 16),
          const SizedBox(width: 6),
          Text('Guest Information',
              style: TextStyle(
                  color: AppTheme.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 12),
        _GuestInput(
          ctrl: nameCtrl,
          hint: 'Full name',
          icon: Icons.badge_outlined,
        ),
        const SizedBox(height: 10),
        _GuestInput(
          ctrl: phoneCtrl,
          hint: 'Phone number (e.g. 012 345 678)',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
      ]),
    );
  }
}

class _GuestInput extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  const _GuestInput({
    required this.ctrl,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
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
