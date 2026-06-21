import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class FareManagementScreen extends StatefulWidget {
  const FareManagementScreen({super.key});

  @override
  State<FareManagementScreen> createState() => _FareManagementScreenState();
}

class _FareManagementScreenState extends State<FareManagementScreen> {
  List<Map<String, dynamic>> _rules = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService.getAdminFareRules();
      if (!mounted) return;
      setState(() { _rules = data; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _showEditSheet({Map<String, dynamic>? rule}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.appSurface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _FareEditSheet(
        rule: rule,
        onSaved: () {
          Navigator.pop(ctx);
          _load();
        },
      ),
    );
  }

  Future<void> _delete(Map<String, dynamic> rule) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.appSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Fare Rule',
            style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w700)),
        content: Text(
          'Delete fare rule for "${rule['vehicle_type'] ?? rule['name'] ?? 'this vehicle'}"?',
          style: TextStyle(color: context.appTextSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: TextStyle(color: context.appTextSecondary))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await ApiService.deleteAdminFareRule(rule['id'] as int);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString()),
        backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        title: Text('Fare Management'),
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditSheet(),
        backgroundColor: AppTheme.accent,
        icon: Icon(Icons.add, color: Colors.white),
        label: Text('Add Rule',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.error_outline, color: AppTheme.danger, size: 40),
                  SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: context.appTextSecondary),
                      textAlign: TextAlign.center),
                  SizedBox(height: 16),
                  ElevatedButton(onPressed: _load,
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
                      child: Text('Retry')),
                ]))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppTheme.accent,
                  child: _rules.isEmpty
                      ? Center(
                          child: Text('No fare rules configured.',
                              style: TextStyle(color: context.appTextSecondary)))
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                          itemCount: _rules.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) => _FareTile(
                            rule: _rules[i],
                            onEdit: () => _showEditSheet(rule: _rules[i]),
                            onDelete: () => _delete(_rules[i]),
                          ),
                        ),
                ),
    );
  }
}

class _FareTile extends StatelessWidget {
  final Map<String, dynamic> rule;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FareTile({required this.rule, required this.onEdit, required this.onDelete});

  String _vehicleLabel() {
    switch ((rule['vehicle_type'] as String? ?? '').toLowerCase()) {
      case 'car':     return 'Car';
      case 'bike':    return 'Bike';
      case 'tuk_tuk': return 'Tuk-Tuk';
      case 'van':     return 'Van';
      default:        return rule['vehicle_type'] as String? ?? rule['name'] as String? ?? 'Unknown';
    }
  }

  IconData _vehicleIcon() {
    switch ((rule['vehicle_type'] as String? ?? '').toLowerCase()) {
      case 'car':     return Icons.directions_car;
      case 'bike':    return Icons.two_wheeler;
      case 'tuk_tuk': return Icons.electric_rickshaw;
      case 'van':     return Icons.airport_shuttle;
      default:        return Icons.directions_car;
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseFare  = rule['base_fare']     ?? rule['base_fare_khr'] ?? 0;
    final perKm     = rule['per_km']        ?? rule['per_km_khr']    ?? 0;
    final minFare   = rule['minimum_fare']  ?? rule['min_fare']      ?? 0;
    final isActive  = rule['is_active'] as bool? ?? true;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(14),
        border: isActive
            ? Border.all(color: AppTheme.accent.withValues(alpha: 0.3))
            : null,
      ),
      child: Column(children: [
        Row(children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_vehicleIcon(), color: AppTheme.accent, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_vehicleLabel(),
                  style: TextStyle(color: context.appTextPrimary,
                      fontWeight: FontWeight.w700, fontSize: 15)),
              SizedBox(height: 2),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppTheme.success.withValues(alpha: 0.12)
                      : context.appTextSecondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: isActive ? AppTheme.success : context.appTextSecondary,
                      fontSize: 11, fontWeight: FontWeight.w600,
                    )),
              ),
            ]),
          ),
          IconButton(
            icon: Icon(Icons.edit_outlined, color: AppTheme.accent, size: 20),
            onPressed: onEdit,
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: AppTheme.danger, size: 20),
            onPressed: onDelete,
          ),
        ]),
        SizedBox(height: 12),
        Divider(height: 1, color: context.appCardBg),
        const SizedBox(height: 12),
        Row(children: [
          _FareStat(label: 'Base Fare', value: AppTheme.khr(baseFare is int ? baseFare : (baseFare as num).toInt())),
          _FareStat(label: 'Per KM', value: AppTheme.khr(perKm is int ? perKm : (perKm as num).toInt())),
          _FareStat(label: 'Minimum', value: AppTheme.khr(minFare is int ? minFare : (minFare as num).toInt())),
        ]),
      ]),
    );
  }
}

class _FareStat extends StatelessWidget {
  final String label;
  final String value;
  const _FareStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(children: [
        Text(value,
            style: TextStyle(color: AppTheme.accent,
                fontWeight: FontWeight.w700, fontSize: 14)),
        SizedBox(height: 2),
        Text(label,
            style: TextStyle(color: context.appTextSecondary, fontSize: 11)),
      ]),
    );
  }
}

// ── Edit / Create sheet ───────────────────────────────────────────────────────

class _FareEditSheet extends StatefulWidget {
  final Map<String, dynamic>? rule;
  final VoidCallback onSaved;

  const _FareEditSheet({this.rule, required this.onSaved});

  @override
  State<_FareEditSheet> createState() => _FareEditSheetState();
}

class _FareEditSheetState extends State<_FareEditSheet> {
  final _baseCtrl = TextEditingController();
  final _perKmCtrl = TextEditingController();
  final _minCtrl = TextEditingController();
  String _vehicleType = 'car';
  bool _active = true;
  bool _submitting = false;

  static const _vehicleTypes = ['car', 'bike', 'tuk_tuk', 'van'];

  @override
  void initState() {
    super.initState();
    final r = widget.rule;
    if (r != null) {
      _vehicleType = r['vehicle_type'] as String? ?? 'car';
      _baseCtrl.text = (r['base_fare'] ?? r['base_fare_khr'] ?? '').toString();
      _perKmCtrl.text = (r['per_km'] ?? r['per_km_khr'] ?? '').toString();
      _minCtrl.text = (r['minimum_fare'] ?? r['min_fare'] ?? '').toString();
      _active = r['is_active'] as bool? ?? true;
    }
  }

  @override
  void dispose() {
    _baseCtrl.dispose();
    _perKmCtrl.dispose();
    _minCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final base  = int.tryParse(_baseCtrl.text.trim());
    final perKm = int.tryParse(_perKmCtrl.text.trim());
    final min   = int.tryParse(_minCtrl.text.trim());

    if (base == null || perKm == null || min == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please fill all fare fields with valid numbers.'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    setState(() => _submitting = true);
    final data = {
      'vehicle_type': _vehicleType,
      'base_fare': base,
      'per_km': perKm,
      'minimum_fare': min,
      'is_active': _active,
    };

    try {
      if (widget.rule != null) {
        await ApiService.updateAdminFareRule(widget.rule!['id'] as int, data);
      } else {
        await ApiService.createAdminFareRule(data);
      }
      if (!mounted) return;
      widget.onSaved();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message),
        backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString()),
        backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(height: 12),
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)))),
          SizedBox(height: 20),

          Text(widget.rule != null ? 'Edit Fare Rule' : 'New Fare Rule',
              style: TextStyle(color: context.appTextPrimary,
                  fontSize: 18, fontWeight: FontWeight.w800)),
          SizedBox(height: 20),

          // Vehicle type chips
          Text('Vehicle Type',
              style: TextStyle(color: context.appTextSecondary,
                  fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: _vehicleTypes.map((t) {
            final selected = _vehicleType == t;
            return ChoiceChip(
              label: Text(t.replaceAll('_', '-').toUpperCase()),
              selected: selected,
              onSelected: (_) => setState(() => _vehicleType = t),
              selectedColor: AppTheme.accent,
              backgroundColor: context.appCardBg,
              labelStyle: TextStyle(
                  color: selected ? Colors.white : context.appTextPrimary,
                  fontWeight: FontWeight.w600, fontSize: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              side: BorderSide.none,
            );
          }).toList()),

          SizedBox(height: 16),
          _Input(controller: _baseCtrl, label: 'Base Fare (KHR)', hint: 'e.g. 2000'),
          SizedBox(height: 12),
          _Input(controller: _perKmCtrl, label: 'Per KM Rate (KHR)', hint: 'e.g. 1500'),
          SizedBox(height: 12),
          _Input(controller: _minCtrl, label: 'Minimum Fare (KHR)', hint: 'e.g. 3000'),
          SizedBox(height: 16),

          Row(children: [
            Text('Active', style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w600)),
            const Spacer(),
            Switch(value: _active, onChanged: (v) => setState(() => _active = v),
                activeColor: AppTheme.accent),
          ]),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                disabledBackgroundColor: AppTheme.accent.withValues(alpha: 0.4),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _submitting
                  ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : Text(widget.rule != null ? 'Save Changes' : 'Create Rule',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            ),
          ),
        ]),
      ),
    );
  }
}

class _Input extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;

  const _Input({required this.controller, required this.label, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: context.appTextSecondary,
          fontSize: 12, fontWeight: FontWeight.w600)),
      SizedBox(height: 6),
      TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: TextStyle(color: context.appTextPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: context.appTextSecondary),
          filled: true,
          fillColor: context.appCardBg,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.accent, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    ]);
  }
}
