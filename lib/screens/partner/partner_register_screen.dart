import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../l10n/app_localizations.dart';
import '../../models/partner_package.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/phone_utils.dart';
import '../../widgets/location_picker_screen.dart';

/// Register this passenger account as a Partner (package sender). Also shows
/// the review state and lets a rejected registration be fixed and resent.
class PartnerRegisterScreen extends StatefulWidget {
  final PartnerStatus? status;
  const PartnerRegisterScreen({super.key, this.status});

  @override
  State<PartnerRegisterScreen> createState() => _PartnerRegisterScreenState();
}

class _PartnerRegisterScreenState extends State<PartnerRegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _contact = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  String _type = 'online_shop';
  LatLng? _latLng;
  bool _saving = false;
  String? _error;
  late PartnerStatus _status = widget.status ?? PartnerStatus.none;

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  Future<void> _prefill() async {
    final p = _status.profile;
    if (p != null) {
      _name.text = p['business_name']?.toString() ?? '';
      _contact.text = p['contact_name']?.toString() ?? '';
      _phone.text = p['phone']?.toString() ?? '';
      _address.text = p['address']?.toString() ?? '';
      _type = p['business_type']?.toString() ?? _type;
      final lat = double.tryParse(p['latitude']?.toString() ?? '');
      final lng = double.tryParse(p['longitude']?.toString() ?? '');
      if (lat != null && lng != null) _latLng = LatLng(lat, lng);
    } else {
      final me = await ApiService.getSavedUser();
      if (me != null && mounted && _phone.text.isEmpty) {
        _phone.text = me.phone;
        _contact.text = me.name;
      }
    }
    if (widget.status == null) {
      try {
        final s = await ApiService.getPartnerStatus();
        if (mounted) setState(() => _status = s);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _contact, _phone, _address]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickAddress() async {
    final r = await Navigator.push<LocationPickResult>(context, MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => LocationPickerScreen(title: AppLocalizations.of(context).pkPickupAddress, initial: _latLng),
    ));
    if (r != null && mounted) {
      setState(() { _address.text = r.address; _latLng = r.latLng; });
    }
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context);
    if (!_form.currentState!.validate()) return;
    setState(() { _saving = true; _error = null; });
    try {
      final s = await ApiService.registerPartner(
        businessName: _name.text.trim(),
        businessType: _type,
        contactName: _contact.text.trim(),
        phone: normalizeLocalPhone(_phone.text),
        address: _address.text.trim(),
        latitude: _latLng?.latitude,
        longitude: _latLng?.longitude,
      );
      if (!mounted) return;
      setState(() { _status = s; _saving = false; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l.pkPendingBody), behavior: SnackBarBehavior.floating, backgroundColor: AppTheme.success));
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _saving = false; });
    } catch (_) {
      if (mounted) setState(() { _error = l.connectionErrorRetry; _saving = false; });
    }
  }

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: context.appSurface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final pending = _status.status == 'pending';
    final approved = _status.isPartner;
    final types = {
      'online_shop': l.pkTypeOnlineShop,
      'retail': l.pkTypeRetail,
      'restaurant': l.pkTypeRestaurant,
      'other': l.pkTypeOther,
    };

    return Scaffold(
      appBar: AppBar(title: Text(approved ? l.pkPartnerAccount : l.pkRegisterTitle)),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              if (pending || approved || _status.status == 'rejected')
                _StatusBanner(status: _status)
              else
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.handshake_rounded, color: AppTheme.accent),
                    const SizedBox(width: 10),
                    Expanded(child: Text(l.pkRegisterIntro,
                        style: TextStyle(color: context.appTextPrimary, fontSize: 13, height: 1.45))),
                  ]),
                ),
              const SizedBox(height: 18),
              AbsorbPointer(
                absorbing: pending || approved,
                child: Opacity(
                  opacity: pending || approved ? 0.7 : 1,
                  child: Column(children: [
                    TextFormField(
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      decoration: _dec(l.pkBusinessName, Icons.storefront_outlined),
                      validator: (v) => (v ?? '').trim().isEmpty ? l.pkRequired : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: types.containsKey(_type) ? _type : 'other',
                      decoration: _dec(l.pkBusinessType, Icons.category_outlined),
                      items: [for (final e in types.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
                      onChanged: (v) => setState(() => _type = v ?? _type),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _contact,
                      decoration: _dec(l.pkContactName, Icons.person_outline),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                      decoration: _dec(l.pkBusinessPhone, Icons.phone_outlined),
                      validator: (v) => (v ?? '').trim().isEmpty
                          ? l.pkRequired
                          : validateLocalPhone(normalizeLocalPhone(v!)),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _address,
                      readOnly: true,
                      onTap: _pickAddress,
                      maxLines: 2,
                      minLines: 1,
                      decoration: _dec(l.pkPickupAddress, Icons.location_on_outlined).copyWith(
                        hintText: l.pkChooseOnMap,
                        suffixIcon: const Icon(Icons.map_outlined, color: AppTheme.accent),
                      ),
                      validator: (v) => (v ?? '').trim().isEmpty ? l.pkRequired : null,
                    ),
                  ]),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: AppTheme.danger, fontSize: 13)),
              ],
              const SizedBox(height: 22),
              if (!pending && !approved)
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _submit,
                    style: AppTheme.confirmButtonStyle(),
                    child: _saving
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(_status.status == 'rejected' ? l.pkResubmit : l.pkSubmit),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final PartnerStatus status;
  const _StatusBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final (Color c, IconData icon, String title, String body) = switch (status.status) {
      'approved'  => (AppTheme.success, Icons.verified_rounded, l.pkPartnerAccount, status.businessName ?? ''),
      'rejected'  => (AppTheme.danger, Icons.error_outline_rounded, l.pkRejectedTitle, status.rejectionReason ?? ''),
      'suspended' => (AppTheme.danger, Icons.block_rounded, l.pkSuspendedTitle, l.pkSuspendedBody),
      _           => (AppTheme.warning, Icons.hourglass_top_rounded, l.pkPendingTitle, l.pkPendingBody),
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(14)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: c),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
            if (body.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(body, style: TextStyle(color: context.appTextSecondary, fontSize: 12.5, height: 1.4)),
            ],
          ]),
        ),
      ]),
    );
  }
}
