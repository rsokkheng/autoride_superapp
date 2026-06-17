import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class AdminPricingScreen extends StatefulWidget {
  const AdminPricingScreen({super.key});

  @override
  State<AdminPricingScreen> createState() => _AdminPricingScreenState();
}

class _AdminPricingScreenState extends State<AdminPricingScreen> {
  Map<String, dynamic> _data = {};
  final Map<String, TextEditingController> _ctrls = {};
  bool _loading = true;
  bool _saving  = false;
  String? _error;

  static const _editableKeys = [
    ('Base Fare (KHR)',              'base_fare_khr'),
    ('Per KM Rate (KHR)',            'per_km_khr'),
    ('Per Minute Rate (KHR)',        'per_minute_khr'),
    ('Minimum Fare (KHR)',           'minimum_fare_khr'),
    ('Cancel Fee After Arrival',     'cancel_fee_after_arrival'),
    ('Waiting Free Minutes',         'waiting_free_minutes'),
    ('Waiting Fee Per Minute (KHR)', 'waiting_fee_per_minute_khr'),
    ('Night Surcharge (%)',          'night_surcharge_pct'),
    ('Platform Commission (%)',      'commission_pct'),
  ];

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() {
    for (final c in _ctrls.values) c.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService.getAdminPricing();
      if (!mounted) return;
      final settings = (data['settings'] as Map<String, dynamic>?) ?? data;
      setState(() { _data = settings; _loading = false; });
      for (final k in _editableKeys) {
        _ctrls[k.$2] = TextEditingController(text: settings[k.$2]?.toString() ?? '');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final settings = <String, dynamic>{};
    for (final k in _editableKeys) {
      final v = _ctrls[k.$2]?.text.trim();
      if (v != null && v.isNotEmpty) settings[k.$2] = v;
    }
    try {
      await ApiService.updateAdminPricingSettings(settings);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pricing settings saved.'), backgroundColor: AppTheme.success, behavior: SnackBarBehavior.floating));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: AppTheme.danger, behavior: SnackBarBehavior.floating));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: AppTheme.danger, behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      appBar: AppBar(
        title: const Text('Pricing Settings'),
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
                  const Icon(Icons.error_outline, color: AppTheme.danger, size: 40), const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: AppTheme.textSecondary), textAlign: TextAlign.center), const SizedBox(height: 16),
                  ElevatedButton(onPressed: _load, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent), child: const Text('Retry')),
                ]))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16)),
                      child: Column(children: [
                        for (int i = 0; i < _editableKeys.length; i++) ...[
                          if (i > 0) const Divider(height: 20, color: AppTheme.cardBg),
                          Row(children: [
                            Expanded(child: Text(_editableKeys[i].$1, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 110,
                              child: TextField(
                                controller: _ctrls[_editableKeys[i].$2],
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.right,
                                style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                                decoration: InputDecoration(
                                  filled: true, fillColor: AppTheme.cardBg,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                ),
                              ),
                            ),
                          ]),
                        ],
                      ]),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(width: double.infinity, child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent, disabledBackgroundColor: AppTheme.accent.withValues(alpha: 0.4), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Save Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                    )),
                    const SizedBox(height: 32),
                  ],
                ),
    );
  }
}
