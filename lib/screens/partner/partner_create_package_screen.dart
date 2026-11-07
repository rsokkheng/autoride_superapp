import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../../l10n/app_localizations.dart';
import '../../services/api_service.dart';
import '../../services/payway_pay.dart';
import '../../theme/app_theme.dart';
import '../../utils/phone_utils.dart';
import '../../widgets/location_picker_screen.dart';
import '../../widgets/payment_logo.dart';
import 'partner_package_detail_screen.dart';
import 'partner_ui.dart';

/// Partner creates a package for ROTEH to pick up and deliver.
/// The delivery fee always comes from the server (Partner contract price).
class PartnerCreatePackageScreen extends StatefulWidget {
  const PartnerCreatePackageScreen({super.key});

  @override
  State<PartnerCreatePackageScreen> createState() => _PartnerCreatePackageScreenState();
}

class _PartnerCreatePackageScreenState extends State<PartnerCreatePackageScreen> {
  final _form = GlobalKey<FormState>();
  final _senderName = TextEditingController();
  final _senderPhone = TextEditingController();
  final _receiverName = TextEditingController();
  final _receiverPhone = TextEditingController();
  final _pickup = TextEditingController();
  final _dropoff = TextEditingController();
  final _details = TextEditingController();
  final _weight = TextEditingController();
  final _cod = TextEditingController();
  final _reference = TextEditingController();
  final _notes = TextEditingController();

  LatLng? _pickupLatLng;
  LatLng? _dropoffLatLng;
  String _type = 'parcel';
  String _size = 'small';
  String _option = 'normal';
  String _paymentBy = 'recipient';
  String _method = 'cash';
  File? _photo;

  int? _fee;
  bool _quoting = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _prefill();
    _quote();
  }

  Future<void> _prefill() async {
    try {
      final s = await ApiService.getPartnerStatus();
      final p = s.profile;
      if (!mounted || p == null) return;
      setState(() {
        _senderName.text = p['business_name']?.toString() ?? '';
        _senderPhone.text = p['phone']?.toString() ?? '';
        _pickup.text = p['address']?.toString() ?? '';
        final lat = double.tryParse(p['latitude']?.toString() ?? '');
        final lng = double.tryParse(p['longitude']?.toString() ?? '');
        if (lat != null && lng != null) _pickupLatLng = LatLng(lat, lng);
      });
    } catch (_) {}
  }

  Future<void> _quote() async {
    setState(() => _quoting = true);
    try {
      final fee = await ApiService.quotePartnerPackage(size: _size, serviceOption: _option);
      if (mounted) setState(() { _fee = fee; _quoting = false; });
    } catch (_) {
      if (mounted) setState(() => _quoting = false);
    }
  }

  @override
  void dispose() {
    for (final c in [_senderName, _senderPhone, _receiverName, _receiverPhone, _pickup, _dropoff,
        _details, _weight, _cod, _reference, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickLocation(bool pickup) async {
    final l = AppLocalizations.of(context);
    final r = await Navigator.push<LocationPickResult>(context, MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => LocationPickerScreen(
        title: pickup ? l.pkPickupLocation : l.pkDeliveryLocation,
        pinColor: pickup ? AppTheme.accent : AppTheme.danger,
        initial: pickup ? _pickupLatLng : (_dropoffLatLng ?? _pickupLatLng),
      ),
    ));
    if (r == null || !mounted) return;
    setState(() {
      if (pickup) {
        _pickup.text = r.address;
        _pickupLatLng = r.latLng;
      } else {
        _dropoff.text = r.address;
        _dropoffLatLng = r.latLng;
      }
    });
  }

  Future<void> _pickPhoto() async {
    final l = AppLocalizations.of(context);
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(leading: const Icon(Icons.photo_camera_outlined), title: Text(l.pkCamera),
              onTap: () => Navigator.pop(ctx, ImageSource.camera)),
          ListTile(leading: const Icon(Icons.photo_library_outlined), title: Text(l.pkGallery),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery)),
        ]),
      ),
    );
    if (source == null) return;
    try {
      final x = await ImagePicker().pickImage(source: source, maxWidth: 1600, imageQuality: 80);
      if (x != null && mounted) setState(() => _photo = File(x.path));
    } catch (_) {}
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context);
    setState(() => _error = null);
    if (!_form.currentState!.validate()) return;
    if (_pickupLatLng == null || _dropoffLatLng == null) {
      setState(() => _error = l.pkChooseLocations);
      return;
    }
    final method = _paymentBy == 'recipient' ? 'cash' : _method;
    final fields = <String, String>{
      'sender_name': _senderName.text.trim(),
      'sender_phone': normalizeLocalPhone(_senderPhone.text),
      'recipient_name': _receiverName.text.trim(),
      'recipient_phone': normalizeLocalPhone(_receiverPhone.text),
      'pickup_address': _pickup.text.trim(),
      'pickup_lat': _pickupLatLng!.latitude.toString(),
      'pickup_lng': _pickupLatLng!.longitude.toString(),
      'dropoff_address': _dropoff.text.trim(),
      'dropoff_lat': _dropoffLatLng!.latitude.toString(),
      'dropoff_lng': _dropoffLatLng!.longitude.toString(),
      'package_type': _type,
      'package_details': _details.text.trim(),
      if (_weight.text.trim().isNotEmpty) 'package_weight': _weight.text.trim(),
      'package_size': _size,
      'service_option': _option,
      if (_cod.text.trim().isNotEmpty) 'package_amount': _cod.text.trim(),
      'payment_by': _paymentBy,
      'payment_method': method,
      if (_reference.text.trim().isNotEmpty) 'partner_reference': _reference.text.trim(),
      if (_notes.text.trim().isNotEmpty) 'notes': _notes.text.trim(),
    };

    setState(() => _saving = true);
    try {
      final pkg = await ApiService.createPartnerPackage(fields, photo: _photo);
      if (!mounted) return;
      if (isPayWayMethod(method)) {
        await payOrderWithAba(context, type: 'delivery', id: pkg.id);
        if (!mounted) return;
      }
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          icon: const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 52),
          title: Text(l.pkCreatedTitle, textAlign: TextAlign.center),
          content: Text(l.pkCreatedBody(pkg.code), textAlign: TextAlign.center),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: AppTheme.confirmButtonStyle(),
                child: Text(l.ok),
              ),
            ),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => PartnerPackageDetailScreen(packageId: pkg.id)));
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _saving = false; });
    } catch (_) {
      if (mounted) setState(() { _error = l.connectionErrorRetry; _saving = false; });
    }
  }

  // ── UI helpers ───────────────────────────────────────────────────────────

  InputDecoration _dec(String label, IconData icon, {String? hint, Widget? suffix}) => InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: context.appSurface,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      );

  Widget _section(String title, IconData icon, List<Widget> children) => Padding(
        padding: const EdgeInsets.only(top: 18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Icon(icon, size: 18, color: AppTheme.accent),
            const SizedBox(width: 6),
            Text(title, style: TextStyle(color: context.appTextPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 10),
          ...children,
        ]),
      );

  Widget _gap() => const SizedBox(height: 10);

  String? _required(String? v) => (v ?? '').trim().isEmpty ? AppLocalizations.of(context).pkRequired : null;

  String? _phoneValidator(String? v) =>
      (v ?? '').trim().isEmpty ? AppLocalizations.of(context).pkRequired : validateLocalPhone(normalizeLocalPhone(v!));

  Widget _phoneField(TextEditingController c, String label) => TextFormField(
        controller: c,
        keyboardType: TextInputType.phone,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
        decoration: _dec(label, Icons.phone_outlined),
        validator: _phoneValidator,
      );

  Widget _locationField(TextEditingController c, String label, bool pickup) => TextFormField(
        controller: c,
        readOnly: true,
        onTap: () => _pickLocation(pickup),
        minLines: 1,
        maxLines: 2,
        decoration: _dec(label, pickup ? Icons.trip_origin_rounded : Icons.location_on_rounded,
            hint: AppLocalizations.of(context).pkChooseOnMap,
            suffix: const Icon(Icons.map_outlined, color: AppTheme.accent)),
        validator: _required,
      );

  Widget _choice<T>(List<(T, String)> items, T value, ValueChanged<T> onPick) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final it in items)
            ChoiceChip(
              label: Text(it.$2),
              selected: value == it.$1,
              onSelected: (_) => onPick(it.$1),
              selectedColor: AppTheme.accent.withValues(alpha: 0.15),
              labelStyle: TextStyle(
                color: value == it.$1 ? AppTheme.accent : context.appTextPrimary,
                fontWeight: value == it.$1 ? FontWeight.w600 : FontWeight.w400,
                fontSize: 13,
              ),
              side: BorderSide(color: value == it.$1 ? AppTheme.accent : Colors.transparent),
              backgroundColor: context.appSurface,
            ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.pkCreatePackage)),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              _section(l.pkSender, Icons.storefront_outlined, [
                TextFormField(controller: _senderName, decoration: _dec(l.pkName, Icons.person_outline), validator: _required),
                _gap(),
                _phoneField(_senderPhone, l.pkPhone),
                _gap(),
                _locationField(_pickup, l.pkPickupLocation, true),
              ]),
              _section(l.pkReceiver, Icons.person_pin_circle_outlined, [
                TextFormField(controller: _receiverName, textCapitalization: TextCapitalization.words,
                    decoration: _dec(l.pkName, Icons.person_outline), validator: _required),
                _gap(),
                _phoneField(_receiverPhone, l.pkPhone),
                _gap(),
                _locationField(_dropoff, l.pkDeliveryLocation, false),
              ]),
              _section(l.pkPackage, Icons.inventory_2_outlined, [
                Text(l.pkPackageType, style: TextStyle(color: context.appTextSecondary, fontSize: 12.5)),
                const SizedBox(height: 6),
                _choice([for (final t in PackageUi.types) (t, PackageUi.type(l, t))], _type, (v) => setState(() => _type = v)),
                const SizedBox(height: 12),
                TextFormField(controller: _details, maxLines: 2, minLines: 1, maxLength: 500,
                    decoration: _dec(l.pkDescription, Icons.notes_rounded), validator: _required),
                TextFormField(
                  controller: _weight,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}(\.\d{0,2})?'))],
                  decoration: _dec(l.pkWeight, Icons.scale_outlined),
                ),
                const SizedBox(height: 12),
                Text(l.pkSize, style: TextStyle(color: context.appTextSecondary, fontSize: 12.5)),
                const SizedBox(height: 6),
                _choice([
                  ('small', l.pkSizeSmall), ('medium', l.pkSizeMedium),
                  ('large', l.pkSizeLarge), ('extra_large', l.pkSizeXL),
                ], _size, (v) { setState(() => _size = v); _quote(); }),
                const SizedBox(height: 12),
                Text(l.pkPhoto, style: TextStyle(color: context.appTextSecondary, fontSize: 12.5)),
                const SizedBox(height: 6),
                Row(children: [
                  InkWell(
                    onTap: _pickPhoto,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 84, height: 84,
                      decoration: BoxDecoration(color: context.appSurface, borderRadius: BorderRadius.circular(12)),
                      clipBehavior: Clip.antiAlias,
                      child: _photo != null
                          ? Image.file(_photo!, fit: BoxFit.cover)
                          : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              const Icon(Icons.add_a_photo_outlined, color: AppTheme.accent),
                              const SizedBox(height: 4),
                              Text(l.pkAddPhoto, style: TextStyle(color: context.appTextSecondary, fontSize: 11)),
                            ]),
                    ),
                  ),
                  if (_photo != null)
                    IconButton(onPressed: () => setState(() => _photo = null),
                        icon: const Icon(Icons.close_rounded, color: AppTheme.danger)),
                ]),
              ]),
              _section(l.pkService, Icons.speed_rounded, [
                _choice([('normal', l.pkNormal), ('express', l.pkExpress)], _option,
                    (v) { setState(() => _option = v); _quote(); }),
              ]),
              _section(l.pkPayment, Icons.payments_outlined, [
                Text(l.pkWhoPays, style: TextStyle(color: context.appTextSecondary, fontSize: 12.5)),
                const SizedBox(height: 6),
                _choice([('recipient', l.pkReceiverPays), ('sender', l.pkPartnerPays)], _paymentBy,
                    (v) => setState(() => _paymentBy = v)),
                if (_paymentBy == 'sender') ...[
                  const SizedBox(height: 12),
                  Text(l.pkPayMethod, style: TextStyle(color: context.appTextSecondary, fontSize: 12.5)),
                  const SizedBox(height: 6),
                  for (final m in [('cash', l.pkPayCash, 'cash'), ('wallet', l.pkPayWallet, 'wallet'), ('aba', l.pkPayAba, 'aba')])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Material(
                        color: context.appSurface,
                        borderRadius: BorderRadius.circular(12),
                        child: RadioListTile<String>(
                          value: m.$1,
                          groupValue: _method,
                          onChanged: (v) => setState(() => _method = v ?? _method),
                          activeColor: AppTheme.accent,
                          dense: true,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          title: Row(children: [
                            PaymentLogo(method: m.$3, size: 26),
                            const SizedBox(width: 10),
                            Text(m.$2, style: TextStyle(color: context.appTextPrimary, fontSize: 13.5)),
                          ]),
                        ),
                      ),
                    ),
                ],
                const SizedBox(height: 12),
                TextFormField(
                  controller: _cod,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(9)],
                  decoration: _dec(l.pkCodAmount, Icons.request_quote_outlined, hint: l.pkCodHint),
                ),
                _gap(),
                TextFormField(controller: _reference, maxLength: 100,
                    decoration: _dec(l.pkReference, Icons.tag_rounded)),
                TextFormField(controller: _notes, maxLines: 2, minLines: 1, maxLength: 500,
                    decoration: _dec(l.pkNotes, Icons.sticky_note_2_outlined)),
              ]),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: AppTheme.danger, fontSize: 13)),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(children: [
          Expanded(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.pkDeliveryFee, style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
              _quoting && _fee == null
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_fee == null ? '—' : AppTheme.khr(_fee!),
                      style: TextStyle(color: context.appTextPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
            ]),
          ),
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _submit,
              style: AppTheme.confirmButtonStyle(),
              icon: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send_rounded, size: 18),
              label: Text(l.pkSubmitPackage),
            ),
          ),
        ]),
      ),
    );
  }
}
