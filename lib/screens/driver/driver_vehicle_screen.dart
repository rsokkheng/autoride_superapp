import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import '../../models/vehicle_model.dart';
import '../../theme/app_theme.dart';

const _green = Color(0xFF00C48C);

class DriverVehicleScreen extends StatefulWidget {
  const DriverVehicleScreen({super.key});

  @override
  State<DriverVehicleScreen> createState() => _DriverVehicleScreenState();
}

class _DriverVehicleScreenState extends State<DriverVehicleScreen> {
  List<VehicleModel> _vehicles = [];
  bool    _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await ApiService.getVehicles();
      if (mounted) setState(() { _vehicles = list; _loading = false; });
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface, elevation: 0,
        leading: BackButton(color: context.appTextPrimary),
        title: Text('My Vehicles',
            style: TextStyle(
                color: context.appTextPrimary, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: _green),
            onPressed: _showRegister,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _green))
          : _error != null
              ? _ErrorView(error: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load, color: _green,
                  child: _vehicles.isEmpty
                      ? _EmptyView(onAdd: _showRegister)
                      : ListView(
                          padding: const EdgeInsets.all(16),
                          children: _vehicles
                              .map((v) => _VehicleCard(
                                    vehicle: v,
                                    onEdit:   () => _showEdit(v),
                                    onUpload: () => _uploadImages(v),
                                  ))
                              .toList(),
                        ),
                ),
    );
  }

  void _showRegister() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _VehicleFormSheet(
        onSaved: (v) => setState(() => _vehicles.add(v)),
      ),
    );
  }

  void _showEdit(VehicleModel v) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _VehicleFormSheet(
        existing: v,
        onSaved: (updated) => setState(() {
          final i = _vehicles.indexWhere((x) => x.id == updated.id);
          if (i >= 0) _vehicles[i] = updated;
        }),
      ),
    );
  }

  Future<void> _uploadImages(VehicleModel v) async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 80);
    if (picked.isEmpty || !mounted) return;
    final files = picked.map((x) => File(x.path)).toList();
    try {
      await ApiService.uploadVehicleImages(v.id, files);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Images uploaded'),
        backgroundColor: _green, behavior: SnackBarBehavior.floating,
      ));
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message),
        backgroundColor: AppTheme.danger, behavior: SnackBarBehavior.floating,
      ));
    }
  }
}

// ─── Vehicle card ─────────────────────────────────────────────────────────────

class _VehicleCard extends StatelessWidget {
  final VehicleModel vehicle;
  final VoidCallback onEdit;
  final VoidCallback onUpload;

  const _VehicleCard({
    required this.vehicle,
    required this.onEdit,
    required this.onUpload,
  });

  IconData get _typeIcon {
    switch (vehicle.type.toLowerCase()) {
      case 'motorbike':
      case 'motorcycle': return Icons.two_wheeler;
      case 'van':        return Icons.airport_shuttle_outlined;
      case 'truck':      return Icons.local_shipping_outlined;
      default:           return Icons.directions_car_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(16),
        border: vehicle.isActive
            ? Border.all(color: _green.withValues(alpha: 0.35)) : null,
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(children: [
          Row(children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_typeIcon, color: _green, size: 28),
            ),
            SizedBox(width: 14),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(vehicle.displayName,
                  style: TextStyle(
                      color: context.appTextPrimary,
                      fontWeight: FontWeight.w700, fontSize: 15)),
              SizedBox(height: 2),
              Text(vehicle.licensePlate,
                  style: TextStyle(
                      color: context.appTextSecondary, fontSize: 13)),
              SizedBox(height: 4),
              Row(children: [
                _Chip(
                  label: vehicle.type.isEmpty ? 'Vehicle' : vehicle.type,
                  color: AppTheme.accent,
                ),
                SizedBox(width: 6),
                _Chip(
                  label: vehicle.status.toUpperCase(),
                  color: vehicle.isActive ? _green : context.appTextSecondary,
                ),
              ]),
            ])),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.accent,
                  side: const BorderSide(color: AppTheme.accent),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onUpload,
                icon: const Icon(Icons.photo_camera_outlined, size: 16),
                label: const Text('Photos'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green, foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color  color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(label, style: TextStyle(
        color: color, fontSize: 11, fontWeight: FontWeight.w600)),
  );
}

// ─── Form sheet ───────────────────────────────────────────────────────────────

class _VehicleFormSheet extends StatefulWidget {
  final VehicleModel? existing;
  final ValueChanged<VehicleModel> onSaved;
  const _VehicleFormSheet({this.existing, required this.onSaved});

  @override
  State<_VehicleFormSheet> createState() => _VehicleFormSheetState();
}

class _VehicleFormSheetState extends State<_VehicleFormSheet> {
  final _makeCtrl  = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _yearCtrl  = TextEditingController();
  final _plateCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  String  _type   = 'motorbike';
  bool    _saving = false;
  String? _error;

  static const _types = [
    ('motorbike', 'Motorbike', Icons.two_wheeler),
    ('car',       'Car',       Icons.directions_car_outlined),
    ('van',       'Van',       Icons.airport_shuttle_outlined),
    ('truck',     'Truck',     Icons.local_shipping_outlined),
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _makeCtrl.text  = e.make;
      _modelCtrl.text = e.model;
      _yearCtrl.text  = e.year.toString();
      _plateCtrl.text = e.licensePlate;
      _type           = e.type.isEmpty ? 'motorbike' : e.type;
    } else {
      _yearCtrl.text = DateTime.now().year.toString();
    }
  }

  @override
  void dispose() {
    _makeCtrl.dispose(); _modelCtrl.dispose(); _yearCtrl.dispose();
    _plateCtrl.dispose(); _colorCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_makeCtrl.text.trim().isEmpty || _modelCtrl.text.trim().isEmpty
        || _plateCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Make, model and plate are required');
      return;
    }
    setState(() { _saving = true; _error = null; });
    try {
      VehicleModel result;
      final year = int.tryParse(_yearCtrl.text.trim()) ?? DateTime.now().year;
      if (widget.existing != null) {
        result = await ApiService.updateDriverVehicle(widget.existing!.id,
          type:  _type,
          make:  _makeCtrl.text.trim(),
          model: _modelCtrl.text.trim(),
          year:  year,
          plate: _plateCtrl.text.trim(),
          color: _colorCtrl.text.trim().isEmpty ? null : _colorCtrl.text.trim(),
        );
      } else {
        result = await ApiService.registerDriverVehicle(
          type:  _type,
          make:  _makeCtrl.text.trim(),
          model: _modelCtrl.text.trim(),
          year:  year,
          plate: _plateCtrl.text.trim(),
          color: _colorCtrl.text.trim().isEmpty ? null : _colorCtrl.text.trim(),
        );
      }
      if (!mounted) return;
      widget.onSaved(result);
      Navigator.pop(context);
    } on ApiException catch (e) {
      setState(() { _error = e.message; _saving = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _saving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)))),
          SizedBox(height: 16),
          Text(isEdit ? 'Edit Vehicle' : 'Register Vehicle',
              style: TextStyle(fontSize: 17,
                  fontWeight: FontWeight.w700, color: context.appTextPrimary)),
          SizedBox(height: 16),

          // Vehicle type
          Text('Vehicle Type',
              style: TextStyle(color: context.appTextSecondary,
                  fontSize: 12, fontWeight: FontWeight.w600)),
          SizedBox(height: 8),
          Row(children: _types.map((t) => Expanded(child: Padding(
            padding: EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => setState(() => _type = t.$1),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 160),
                padding: EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _type == t.$1
                      ? _green.withValues(alpha: 0.1) : context.appCardBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _type == t.$1 ? _green : Colors.transparent,
                  ),
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(t.$3,
                    color: _type == t.$1 ? _green : context.appTextSecondary,
                    size: 20),
                  SizedBox(height: 3),
                  Text(t.$2, style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w600,
                    color: _type == t.$1 ? _green : context.appTextSecondary,
                  )),
                ]),
              ),
            ),
          ))).toList()),
          const SizedBox(height: 14),

          Row(children: [
            Expanded(child: _F(ctrl: _makeCtrl,  label: 'Make',  hint: 'Honda')),
            const SizedBox(width: 10),
            Expanded(child: _F(ctrl: _modelCtrl, label: 'Model', hint: 'Wave')),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _F(ctrl: _yearCtrl,  label: 'Year',  hint: '2022',
                keyboardType: TextInputType.number)),
            const SizedBox(width: 10),
            Expanded(child: _F(ctrl: _colorCtrl, label: 'Color (optional)',
                hint: 'Red')),
          ]),
          const SizedBox(height: 10),
          _F(ctrl: _plateCtrl, label: 'License Plate',
              hint: '1A-1234',
              keyboardType: TextInputType.text),

          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(
                color: AppTheme.danger, fontSize: 12)),
          ],
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: AppTheme.confirmButtonStyle(background: _green),
              child: _saving
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(isEdit ? 'Save Changes' : 'Register Vehicle'),
            ),
          ),
        ]),
      ),
    );
  }
}

class _F extends StatelessWidget {
  final TextEditingController ctrl;
  final String label, hint;
  final TextInputType? keyboardType;
  const _F({required this.ctrl, required this.label,
      required this.hint, this.keyboardType});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(
          color: context.appTextSecondary, fontSize: 12,
          fontWeight: FontWeight.w600)),
      SizedBox(height: 4),
      TextField(
        controller: ctrl, keyboardType: keyboardType,
        style: TextStyle(color: context.appTextPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          filled: true, fillColor: context.appCardBg,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _green)),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 12),
        ),
      ),
    ],
  );
}

// ─── Empty / Error ────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyView({required this.onAdd});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.directions_car_outlined,
          color: context.appTextSecondary, size: 60),
      SizedBox(height: 16),
      Text('No vehicles registered',
          style: TextStyle(color: context.appTextPrimary,
              fontSize: 16, fontWeight: FontWeight.w700)),
      SizedBox(height: 8),
      Text('Register your vehicle to start accepting rides.',
          textAlign: TextAlign.center,
          style: TextStyle(color: context.appTextSecondary, fontSize: 13)),
      const SizedBox(height: 20),
      ElevatedButton.icon(
        onPressed: onAdd,
        icon: const Icon(Icons.add),
        label: const Text('Register Vehicle'),
        style: ElevatedButton.styleFrom(
          backgroundColor: _green, foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      ),
    ]),
  );
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.error_outline, color: AppTheme.danger, size: 48),
      SizedBox(height: 12),
      Text(error, textAlign: TextAlign.center,
          style: TextStyle(color: context.appTextSecondary)),
      const SizedBox(height: 16),
      ElevatedButton(onPressed: onRetry,
          style: ElevatedButton.styleFrom(
              backgroundColor: _green, foregroundColor: Colors.white,
              elevation: 0),
          child: const Text('Retry')),
    ]),
  );
}
