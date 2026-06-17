import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class HelmetCheckScreen extends StatefulWidget {
  const HelmetCheckScreen({super.key});

  @override
  State<HelmetCheckScreen> createState() => _HelmetCheckScreenState();
}

class _HelmetCheckScreenState extends State<HelmetCheckScreen> {
  XFile? _image;
  bool _checking  = false;
  Map<String, dynamic>? _result;
  String? _error;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80, maxWidth: 1280);
    if (picked == null) return;
    setState(() { _image = picked; _result = null; _error = null; });
  }

  Future<void> _check() async {
    if (_image == null) return;
    setState(() { _checking = true; _result = null; _error = null; });
    try {
      final bytes    = await _image!.readAsBytes();
      final filename = _image!.name.isNotEmpty ? _image!.name : 'helmet.jpg';
      final data     = await ApiService.checkHelmet(bytes, filename);
      if (!mounted) return;
      setState(() { _result = data; _checking = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _checking = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final detected  = _result?['helmet_detected'] == true || _result?['detected'] == true;
    final confident = (_result?['confidence'] as num?)?.toDouble() ?? 0.0;

    return Scaffold(
      backgroundColor: AppTheme.primary,
      appBar: AppBar(title: const Text('Helmet Check')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Upload a photo to verify that a helmet is being worn correctly.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.5)),

          const SizedBox(height: 24),

          // Image preview / placeholder
          GestureDetector(
            onTap: () => _showPicker(),
            child: Container(
              height: 240,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.cardBg, width: 2),
              ),
              child: _image == null
                  ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.add_a_photo_outlined, size: 52, color: AppTheme.accent.withValues(alpha: 0.6)),
                      const SizedBox(height: 12),
                      const Text('Tap to upload photo', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                    ])
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.network(
                        _image!.path,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.image_rounded, size: 52, color: AppTheme.accent.withValues(alpha: 0.5)),
                            const SizedBox(height: 8),
                            Text(_image!.name, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                          ]),
                        ),
                      ),
                    ),
            ),
          ),

          if (_image != null) ...[
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_outlined, size: 18),
                  label: const Text('Retake'),
                  style: OutlinedButton.styleFrom(foregroundColor: AppTheme.accent, side: const BorderSide(color: AppTheme.accent)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: const Text('Gallery'),
                  style: OutlinedButton.styleFrom(foregroundColor: AppTheme.accent, side: const BorderSide(color: AppTheme.accent)),
                ),
              ),
            ]),
          ],

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (_image == null || _checking) ? null : _check,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                disabledBackgroundColor: AppTheme.accent.withValues(alpha: 0.4),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: _checking
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.security_rounded, color: Colors.white),
              label: Text(_checking ? 'Checking…' : 'Check Helmet',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.error_outline, color: AppTheme.danger, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(_error!, style: const TextStyle(color: AppTheme.danger, fontSize: 13))),
              ]),
            ),
          ],

          if (_result != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: detected
                    ? AppTheme.success.withValues(alpha: 0.08)
                    : AppTheme.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: detected
                      ? AppTheme.success.withValues(alpha: 0.3)
                      : AppTheme.danger.withValues(alpha: 0.3),
                ),
              ),
              child: Column(children: [
                Icon(
                  detected ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: detected ? AppTheme.success : AppTheme.danger,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  detected ? 'Helmet Detected!' : 'No Helmet Detected',
                  style: TextStyle(
                    color: detected ? AppTheme.success : AppTheme.danger,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (confident > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Confidence: ${(confident * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                  ),
                ],
                if (!detected) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Please wear a helmet before starting your trip.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                ],
              ]),
            ),
          ],
        ]),
      ),
    );
  }

  void _showPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.camera_alt_rounded, color: AppTheme.accent),
            title: const Text('Take Photo', style: TextStyle(color: AppTheme.textPrimary)),
            onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_rounded, color: AppTheme.accent),
            title: const Text('Choose from Gallery', style: TextStyle(color: AppTheme.textPrimary)),
            onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}
