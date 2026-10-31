import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n.dart';

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

  // Getter so the labels follow the current language.
  static List<(String, String)> get _editableKeys => [
    (l10n.trBaseFareKhr,              'base_fare_khr'),
    (l10n.trPerKmRateKhr,            'per_km_khr'),
    (l10n.trPerMinuteRateKhr,        'per_minute_khr'),
    (l10n.trMinimumFareKhr,           'minimum_fare_khr'),
    (l10n.trCancelFeeAfterArrival,     'cancel_fee_after_arrival'),
    (l10n.trWaitingFreeMinutes,         'waiting_free_minutes'),
    (l10n.trWaitingFeePerMinuteKhr, 'waiting_fee_per_minute_khr'),
    (l10n.trNightSurchargePct,          'night_surcharge_pct'),
    (l10n.trPlatformCommissionPct,      'commission_pct'),
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).trPricingSaved), backgroundColor: AppTheme.success, behavior: SnackBarBehavior.floating));
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
      backgroundColor: context.appBackground,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).trPricingSettings),
        actions: [
          if (!_loading && _error == null)
            TextButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: AppTheme.accent, strokeWidth: 2))
                  : Text(AppLocalizations.of(context).trSave, style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.error_outline, color: AppTheme.danger, size: 40), SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: context.appTextSecondary), textAlign: TextAlign.center), SizedBox(height: 16),
                  ElevatedButton(onPressed: _load, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent), child: Text(AppLocalizations.of(context).retry)),
                ]))
              : ListView(
                  padding: EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(color: context.appSurface, borderRadius: BorderRadius.circular(16)),
                      child: Column(children: [
                        for (int i = 0; i < _editableKeys.length; i++) ...[
                          if (i > 0) Divider(height: 20, color: context.appCardBg),
                          Row(children: [
                            Expanded(child: Text(_editableKeys[i].$1, style: TextStyle(color: context.appTextSecondary, fontSize: 13))),
                            SizedBox(width: 12),
                            SizedBox(
                              width: 110,
                              child: TextField(
                                controller: _ctrls[_editableKeys[i].$2],
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.right,
                                style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w600),
                                decoration: InputDecoration(
                                  filled: true, fillColor: context.appCardBg,
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
                      style: AppTheme.confirmButtonStyle(background: AppTheme.accent),
                      child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(AppLocalizations.of(context).trSaveSettings),
                    )),
                    const SizedBox(height: 32),
                  ],
                ),
    );
  }
}
