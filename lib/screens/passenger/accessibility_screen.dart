import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class AccessibilityScreen extends StatefulWidget {
  const AccessibilityScreen({super.key});

  @override
  State<AccessibilityScreen> createState() => _AccessibilityScreenState();
}

class _AccessibilityScreenState extends State<AccessibilityScreen> {
  Map<String, dynamic> _settings = {};
  bool _loading = true;
  bool _saving  = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService.getAccessibilitySettings();
      if (!mounted) return;
      setState(() { _settings = Map<String, dynamic>.from(data); _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ApiService.updateAccessibilitySettings(_settings);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Accessibility settings saved.'),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
      ));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message),
        backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  bool _bool(String key) => _settings[key] == true || _settings[key] == 1;

  void _toggle(String key, bool val) => setState(() => _settings[key] = val);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      appBar: AppBar(
        title: const Text('Accessibility'),
        actions: [
          if (!_loading && _error == null)
            TextButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: AppTheme.accent, strokeWidth: 2))
                  : const Text('Save', style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.error_outline, color: AppTheme.danger, size: 40),
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: AppTheme.textSecondary), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _load, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent), child: const Text('Retry')),
                ]))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _Section(title: 'Visual', children: [
                      _Toggle(
                        icon: Icons.text_increase_rounded,
                        label: 'Large Text',
                        subtitle: 'Increase font size throughout the app',
                        value: _bool('large_text'),
                        onChanged: (v) => _toggle('large_text', v),
                      ),
                      _Toggle(
                        icon: Icons.contrast_rounded,
                        label: 'High Contrast',
                        subtitle: 'Improve visibility with stronger colours',
                        value: _bool('high_contrast'),
                        onChanged: (v) => _toggle('high_contrast', v),
                      ),
                      _Toggle(
                        icon: Icons.animation_rounded,
                        label: 'Reduce Motion',
                        subtitle: 'Minimise animations and transitions',
                        value: _bool('reduce_motion'),
                        onChanged: (v) => _toggle('reduce_motion', v),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    _Section(title: 'Audio & Speech', children: [
                      _Toggle(
                        icon: Icons.record_voice_over_rounded,
                        label: 'Screen Reader Support',
                        subtitle: 'Optimise labels for assistive technology',
                        value: _bool('screen_reader'),
                        onChanged: (v) => _toggle('screen_reader', v),
                      ),
                      _Toggle(
                        icon: Icons.vibration_rounded,
                        label: 'Haptic Feedback',
                        subtitle: 'Vibrate on key interactions',
                        value: _bool('haptic_feedback'),
                        onChanged: (v) => _toggle('haptic_feedback', v),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    _Section(title: 'Interaction', children: [
                      _Toggle(
                        icon: Icons.touch_app_outlined,
                        label: 'Large Touch Targets',
                        subtitle: 'Bigger buttons and tap areas',
                        value: _bool('large_touch_targets'),
                        onChanged: (v) => _toggle('large_touch_targets', v),
                      ),
                      _Toggle(
                        icon: Icons.accessible_forward_rounded,
                        label: 'Wheelchair Accessible Vehicles',
                        subtitle: 'Show only accessible vehicle options',
                        value: _bool('wheelchair_accessible'),
                        onChanged: (v) => _toggle('wheelchair_accessible', v),
                      ),
                    ]),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accent,
                          disabledBackgroundColor: AppTheme.accent.withValues(alpha: 0.4),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _saving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Save Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
      const SizedBox(height: 10),
      Container(
        decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(14)),
        child: Column(children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppTheme.cardBg, indent: 56),
            children[i],
          ],
        ]),
      ),
    ]);
  }
}

class _Toggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _Toggle({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.accent, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
            Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4)),
          ]),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppTheme.accent,
        ),
      ]),
    );
  }
}
