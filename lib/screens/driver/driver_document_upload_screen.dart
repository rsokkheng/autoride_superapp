import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'driver_approval_pending_screen.dart';

const _green = Color(0xFF00C48C);

// Document type definitions ordered by required first
const _kDocTypes = [
  _DocDef('id_card',              'National ID / Passport',   Icons.badge_outlined,             true),
  _DocDef('driver_license',       'Driver License',           Icons.credit_card_outlined,       true),
  _DocDef('vehicle_registration', 'Vehicle Registration',     Icons.directions_car_outlined,    true),
  _DocDef('selfie_with_id',       'Selfie with ID',           Icons.face_outlined,              true),
  _DocDef('vehicle_insurance',    'Vehicle Insurance',        Icons.shield_outlined,            false),
  _DocDef('other',                'Other Document',           Icons.insert_drive_file_outlined, false),
];

class DriverDocumentUploadScreen extends StatefulWidget {
  final int userId;
  const DriverDocumentUploadScreen({super.key, required this.userId});

  @override
  State<DriverDocumentUploadScreen> createState() => _DriverDocumentUploadScreenState();
}

class _DriverDocumentUploadScreenState extends State<DriverDocumentUploadScreen> {
  final _picker = ImagePicker();

  // type → upload state
  final Map<String, _UploadState> _states = {
    for (final d in _kDocTypes) d.type: _UploadState(),
  };

  bool get _requiredComplete => _kDocTypes
      .where((d) => d.required)
      .every((d) => _states[d.type]!.uploaded);

  bool get _anyUploading => _states.values.any((s) => s.loading);

  Future<void> _pickAndUpload(_DocDef doc) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: context.appSurface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 40, height: 4,
            margin: EdgeInsets.only(top: 12, bottom: 16),
            decoration: BoxDecoration(color: context.appCardBg, borderRadius: BorderRadius.circular(2)),
          ),
          ListTile(
            leading: Icon(Icons.camera_alt_outlined, color: _green),
            title: Text('Take Photo', style: TextStyle(color: context.appTextPrimary)),
            onTap: () => Navigator.pop(context, 'camera'),
          ),
          ListTile(
            leading: Icon(Icons.photo_library_outlined, color: _green),
            title: Text('Choose from Gallery', style: TextStyle(color: context.appTextPrimary)),
            onTap: () => Navigator.pop(context, 'gallery'),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (action == null || !mounted) return;

    final XFile? picked = await (action == 'camera'
        ? _picker.pickImage(source: ImageSource.camera,  imageQuality: 85)
        : _picker.pickImage(source: ImageSource.gallery, imageQuality: 85));
    if (picked == null || !mounted) return;

    setState(() => _states[doc.type]!
      ..loading = true
      ..error   = null
      ..file    = File(picked.path));

    try {
      await ApiService.uploadDriverDocument(
        type: doc.type,
        file: File(picked.path),
      );
      if (!mounted) return;
      setState(() => _states[doc.type]!
        ..loading  = false
        ..uploaded = true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _states[doc.type]!
        ..loading = false
        ..error   = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _states[doc.type]!
        ..loading = false
        ..error   = e.toString());
    }
  }

  void _continue() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const DriverApprovalPendingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text('Upload Documents',
            style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w700)),
      ),
      body: Column(children: [
        // Progress banner
        Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          color: context.appSurface,
          child: Column(children: [
            Row(children: [
              Expanded(child: Text(
                '${_kDocTypes.where((d) => d.required && _states[d.type]!.uploaded).length} / 4 required documents uploaded',
                style: TextStyle(color: context.appTextSecondary, fontSize: 13),
              )),
              Text(
                _requiredComplete ? 'Ready!' : 'Required',
                style: TextStyle(
                  color: _requiredComplete ? _green : AppTheme.warning,
                  fontWeight: FontWeight.w700, fontSize: 13,
                ),
              ),
            ]),
            SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _kDocTypes.where((d) => d.required && _states[d.type]!.uploaded).length / 4,
                backgroundColor: context.appCardBg,
                valueColor: AlwaysStoppedAnimation<Color>(_requiredComplete ? _green : AppTheme.accent),
                minHeight: 6,
              ),
            ),
          ]),
        ),

        Expanded(
          child: ListView(
            padding: EdgeInsets.all(16),
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text('Required Documents',
                    style: TextStyle(color: context.appTextPrimary,
                        fontSize: 15, fontWeight: FontWeight.w700)),
              ),
              ..._kDocTypes.where((d) => d.required).map((d) => _DocTile(
                    doc:   d,
                    state: _states[d.type]!,
                    onTap: _anyUploading ? null : () => _pickAndUpload(d),
                  )),

              Padding(
                padding: EdgeInsets.only(top: 20, bottom: 12),
                child: Text('Optional Documents',
                    style: TextStyle(color: context.appTextSecondary,
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ),
              ..._kDocTypes.where((d) => !d.required).map((d) => _DocTile(
                    doc:   d,
                    state: _states[d.type]!,
                    onTap: _anyUploading ? null : () => _pickAndUpload(d),
                  )),

              SizedBox(height: 24),
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: _requiredComplete && !_anyUploading ? _continue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _green.withValues(alpha: 0.4),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Submit for Review',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              SizedBox(height: 12),
              Center(
                child: Text(
                  'Your documents will be reviewed within 1–2 business days.',
                  style: TextStyle(color: context.appTextSecondary, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ]),
    );
  }
}

// ── Doc tile ──────────────────────────────────────────────────────────────────

class _DocTile extends StatelessWidget {
  final _DocDef      doc;
  final _UploadState state;
  final VoidCallback? onTap;

  const _DocTile({required this.doc, required this.state, this.onTap});

  @override
  Widget build(BuildContext context) {
    final uploaded = state.uploaded;
    final loading  = state.loading;
    final error    = state.error;
    final hasFile  = state.file != null;

    Color borderColor = context.appCardBg;
    if (uploaded) borderColor = _green;
    if (error != null) borderColor = AppTheme.danger;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 10),
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: uploaded ? 1.5 : 1),
        ),
        child: Row(children: [
          // Thumbnail or icon
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 52, height: 52,
              child: hasFile && !loading
                  ? Image.file(state.file!, fit: BoxFit.cover)
                  : Container(
                      color: uploaded
                          ? _green.withValues(alpha: 0.1)
                          : context.appCardBg,
                      child: Icon(
                        uploaded ? Icons.check_circle_rounded : doc.icon,
                        color: uploaded ? _green : context.appTextSecondary,
                        size: 28,
                      ),
                    ),
            ),
          ),
          SizedBox(width: 14),

          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(doc.label,
                  style: TextStyle(color: context.appTextPrimary,
                      fontWeight: FontWeight.w600, fontSize: 13)),
              if (doc.required) ...[
                SizedBox(width: 6),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppTheme.danger.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('Required',
                      style: TextStyle(color: AppTheme.danger, fontSize: 9, fontWeight: FontWeight.w700)),
                ),
              ],
            ]),
            SizedBox(height: 3),
            if (error != null)
              Text(error, style: TextStyle(color: AppTheme.danger, fontSize: 11))
            else if (uploaded)
              Text('Uploaded', style: TextStyle(color: _green, fontSize: 11))
            else
              Text(doc.required ? 'Tap to upload' : 'Optional — tap to upload',
                  style: TextStyle(color: context.appTextSecondary, fontSize: 11)),
          ])),

          SizedBox(width: 8),
          if (loading)
            SizedBox(width: 22, height: 22,
                child: CircularProgressIndicator(color: _green, strokeWidth: 2.5))
          else if (uploaded)
            Icon(Icons.check_circle_rounded, color: _green, size: 24)
          else
            Icon(Icons.upload_rounded, color: context.appTextSecondary, size: 22),
        ]),
      ),
    );
  }
}

// ── Data classes ─────────────────────────────────────────────────────────────

class _DocDef {
  final String   type;
  final String   label;
  final IconData icon;
  final bool     required;
  const _DocDef(this.type, this.label, this.icon, this.required);
}

class _UploadState {
  bool    loading  = false;
  bool    uploaded = false;
  File?   file;
  String? error;
}
