import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/location_picker_screen.dart';
import '../../l10n/app_localizations.dart';

const _green = Color(0xFF00C48C);

class SavedPlacesScreen extends StatefulWidget {
  const SavedPlacesScreen({super.key});

  @override
  State<SavedPlacesScreen> createState() => _SavedPlacesScreenState();
}

class _SavedPlacesScreenState extends State<SavedPlacesScreen> {
  List<SavedPlaceModel> _places = [];
  bool    _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await ApiService.getSavedPlaces();
      if (mounted) setState(() { _places = list; _loading = false; });
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _delete(SavedPlaceModel p) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppLocalizations.of(context).deletePlaceQuestion),
        content: Text('${AppLocalizations.of(context).removePlacePrefix} "${p.label}" ${AppLocalizations.of(context).fromSavedPlacesQuestionSuffix}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalizations.of(context).cancel)),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: Text(AppLocalizations.of(context).delete,
                  style: const TextStyle(color: AppTheme.danger))),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ApiService.deleteSavedPlace(p.id);
      setState(() => _places.removeWhere((x) => x.id == p.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('"${p.label}" ${AppLocalizations.of(context).removedSuffix}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _green,
        ));
      }
    } on ApiException catch (e) {
      if (mounted) _snack(e.message, AppTheme.danger);
    }
  }

  void _snack(String msg, Color c) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg),
          backgroundColor: c, behavior: SnackBarBehavior.floating));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        elevation: 0,
        leading: BackButton(color: context.appTextPrimary),
        title: Text(AppLocalizations.of(context).savedPlaces,
            style: TextStyle(
                color: context.appTextPrimary, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: _green),
            onPressed: () => _showAddEdit(null),
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: _green))
          : _error != null
              ? _ErrorView(error: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load, color: _green,
                  child: _places.isEmpty
                      ? _EmptyView(onAdd: () => _showAddEdit(null))
                      : ListView(
                          padding: EdgeInsets.all(16),
                          children: [
                            // Quick-add Home / Work if not present
                            if (!_places.any((p) =>
                                p.label.toLowerCase() == 'home')) ...[
                              _QuickAddTile(
                                icon: Icons.home_outlined,
                                label: AppLocalizations.of(context).addHomeLabel,
                                onTap: () => _showAddEdit(null,
                                    presetLabel: 'Home'),
                              ),
                              SizedBox(height: 8),
                            ],
                            if (!_places.any((p) =>
                                p.label.toLowerCase() == 'work')) ...[
                              _QuickAddTile(
                                icon: Icons.work_outline,
                                label: AppLocalizations.of(context).addWorkLabel,
                                onTap: () => _showAddEdit(null,
                                    presetLabel: 'Work'),
                              ),
                              SizedBox(height: 16),
                            ],
                            Padding(
                              padding: EdgeInsets.only(bottom: 10),
                              child: Text(AppLocalizations.of(context).yourPlacesLabel,
                                  style: TextStyle(
                                      color: context.appTextSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5)),
                            ),
                            ..._places.map((p) => _PlaceTile(
                              place: p,
                              onEdit: () => _showAddEdit(p),
                              onDelete: () => _delete(p),
                            )),
                          ],
                        ),
                ),
    );
  }

  void _showAddEdit(SavedPlaceModel? existing, {String? presetLabel}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddEditSheet(
        existing:    existing,
        presetLabel: presetLabel,
        onSaved: (p) {
          setState(() {
            if (existing != null) {
              final i = _places.indexWhere((x) => x.id == p.id);
              if (i >= 0) _places[i] = p;
            } else {
              _places.add(p);
            }
          });
        },
      ),
    );
  }
}

// ─── Tiles ────────────────────────────────────────────────────────────────────

class _PlaceTile extends StatelessWidget {
  final SavedPlaceModel place;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PlaceTile({required this.place,
      required this.onEdit, required this.onDelete});

  IconData get _icon {
    switch (place.label.toLowerCase()) {
      case 'home':   return Icons.home_rounded;
      case 'work':   return Icons.work_rounded;
      default:       return Icons.bookmark_rounded;
    }
  }

  Color get _iconColor {
    switch (place.label.toLowerCase()) {
      case 'home':   return _green;
      case 'work':   return AppTheme.accent;
      default:       return AppTheme.accentOrange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Material(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
        contentPadding: EdgeInsets.symmetric(
            horizontal: 16, vertical: 4),
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: _iconColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(_icon, color: _iconColor, size: 22),
        ),
        title: Text(place.label,
            style: TextStyle(
                color: context.appTextPrimary,
                fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(place.address,
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: context.appTextSecondary, fontSize: 12)),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          if (place.isDefault)
            Container(
              margin: EdgeInsets.only(right: 8),
              padding: EdgeInsets.symmetric(
                  horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(AppLocalizations.of(context).defaultBadge,
                  style: TextStyle(
                      color: _green, fontSize: 10,
                      fontWeight: FontWeight.w600)),
            ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert,
                color: context.appTextSecondary, size: 20),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            itemBuilder: (_) => [
              PopupMenuItem(value: 'edit',
                  child: Row(children: [
                    const Icon(Icons.edit_outlined, size: 18),
                    const SizedBox(width: 10),
                    Text(AppLocalizations.of(context).edit),
                  ])),
              PopupMenuItem(value: 'delete',
                  child: Row(children: [
                    const Icon(Icons.delete_outline,
                        size: 18, color: AppTheme.danger),
                    const SizedBox(width: 10),
                    Text(AppLocalizations.of(context).delete,
                        style: const TextStyle(color: AppTheme.danger)),
                  ])),
            ],
            onSelected: (v) {
              if (v == 'edit') onEdit();
              if (v == 'delete') onDelete();
            },
          ),
        ]),
        ),
      ),
    );
  }
}

class _QuickAddTile extends StatelessWidget {
  final IconData icon;
  final String   label;
  final VoidCallback onTap;
  const _QuickAddTile({required this.icon,
      required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: _green.withValues(alpha: 0.3), style: BorderStyle.solid),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _green.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: _green, size: 20),
        ),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(
            color: _green, fontWeight: FontWeight.w600)),
        const Spacer(),
        const Icon(Icons.add, color: _green, size: 20),
      ]),
    ),
  );
}

class _EmptyView extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyView({required this.onAdd});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.bookmark_border_rounded,
          color: context.appTextSecondary, size: 60),
      SizedBox(height: 16),
      Text(AppLocalizations.of(context).noSavedPlacesYet,
          style: TextStyle(color: context.appTextPrimary,
              fontSize: 16, fontWeight: FontWeight.w700)),
      SizedBox(height: 6),
      Text(AppLocalizations.of(context).saveHomeWorkDesc,
          textAlign: TextAlign.center,
          style: TextStyle(color: context.appTextSecondary, fontSize: 13)),
      const SizedBox(height: 20),
      ElevatedButton.icon(
        onPressed: onAdd,
        icon: const Icon(Icons.add),
        label: Text(AppLocalizations.of(context).addAPlaceBtn),
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
      Icon(Icons.error_outline,
          color: AppTheme.danger, size: 48),
      SizedBox(height: 12),
      Text(error, textAlign: TextAlign.center,
          style: TextStyle(color: context.appTextSecondary)),
      const SizedBox(height: 16),
      ElevatedButton(onPressed: onRetry,
          style: ElevatedButton.styleFrom(
              backgroundColor: _green, foregroundColor: Colors.white,
              elevation: 0),
          child: Text(AppLocalizations.of(context).retry)),
    ]),
  );
}

// ─── Add / Edit bottom sheet ──────────────────────────────────────────────────

class _AddEditSheet extends StatefulWidget {
  final SavedPlaceModel? existing;
  final String? presetLabel;
  final ValueChanged<SavedPlaceModel> onSaved;

  const _AddEditSheet({this.existing, this.presetLabel, required this.onSaved});

  @override
  State<_AddEditSheet> createState() => _AddEditSheetState();
}

class _AddEditSheetState extends State<_AddEditSheet> {
  final _labelCtrl   = TextEditingController();
  String  _address = '';
  LatLng? _latLng;
  bool  _isDefault = false;
  bool  _saving    = false;
  bool  _picking   = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _labelCtrl.text = e.label;
      _address        = e.address;
      _latLng         = LatLng(e.lat, e.lng);
      _isDefault      = e.isDefault;
    } else if (widget.presetLabel != null) {
      _labelCtrl.text = widget.presetLabel!;
    }
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    setState(() => _picking = true);
    final result = await Navigator.push<LocationPickResult>(
      context,
      MaterialPageRoute(builder: (_) => LocationPickerScreen(
        title:    AppLocalizations.of(context).setLocationTitle,
        pinColor: _green,
        initial:  _latLng,
      )),
    );
    if (!mounted) return;
    setState(() {
      _picking = false;
      if (result != null) {
        _address = result.address;
        _latLng  = result.latLng;
      }
    });
  }

  Future<void> _save() async {
    final label = _labelCtrl.text.trim();
    final lat   = _latLng?.latitude  ?? 0;
    final lng   = _latLng?.longitude ?? 0;
    if (label.isEmpty || _address.isEmpty || _latLng == null) {
      setState(() => _error = AppLocalizations.of(context).labelAndLocationRequired);
      return;
    }
    setState(() { _saving = true; _error = null; });
    try {
      SavedPlaceModel result;
      if (widget.existing != null) {
        result = await ApiService.updateSavedPlace(widget.existing!.id,
            label: label, address: _address, lat: lat, lng: lng,
            isDefault: _isDefault);
      } else {
        result = await ApiService.addSavedPlace(
            label: label, address: _address, lat: lat, lng: lng,
            isDefault: _isDefault);
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
      child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(
          width: 40, height: 4,
          decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2)),
        )),
        SizedBox(height: 18),
        Text(isEdit ? AppLocalizations.of(context).editPlaceTitle : AppLocalizations.of(context).addPlaceTitle,
            style: TextStyle(fontSize: 17,
                fontWeight: FontWeight.w700, color: context.appTextPrimary)),
        SizedBox(height: 18),

        _SheetField(ctrl: _labelCtrl, label: AppLocalizations.of(context).labelFieldTitle,
            hint: AppLocalizations.of(context).labelHintExample,
            icon: Icons.bookmark_outline),
        SizedBox(height: 12),
        Text(AppLocalizations.of(context).location, style: TextStyle(
            color: context.appTextSecondary, fontSize: 12,
            fontWeight: FontWeight.w600)),
        SizedBox(height: 4),
        InkWell(
          onTap: _picking ? null : _pickLocation,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: context.appCardBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              Icon(Icons.location_on_outlined,
                  color: _address.isEmpty ? context.appTextSecondary : _green, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: _picking
                    ? Text(AppLocalizations.of(context).openingMapEllipsis,
                        style: TextStyle(color: context.appTextSecondary, fontSize: 14))
                    : Text(
                        _address.isEmpty ? AppLocalizations.of(context).searchOrDragPinHint : _address,
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: _address.isEmpty
                                ? context.appTextSecondary
                                : context.appTextPrimary,
                            fontSize: 14),
                      ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: context.appTextSecondary, size: 18),
            ]),
          ),
        ),
        SizedBox(height: 12),

        Row(children: [
          Checkbox(
            value: _isDefault,
            onChanged: (v) => setState(() => _isDefault = v ?? false),
            activeColor: _green,
          ),
          Text(AppLocalizations.of(context).setAsDefaultCheckbox,
              style: TextStyle(color: context.appTextPrimary)),
        ]),

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
                : Text(isEdit ? AppLocalizations.of(context).saveChanges : AppLocalizations.of(context).addPlaceTitle),
          ),
        ),
      ]),
    );
  }
}

class _SheetField extends StatelessWidget {
  final TextEditingController ctrl;
  final String   label;
  final String   hint;
  final IconData icon;
  final TextInputType? keyboardType;
  const _SheetField({required this.ctrl, required this.label,
      required this.hint, required this.icon, this.keyboardType});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(
          color: context.appTextSecondary, fontSize: 12,
          fontWeight: FontWeight.w600)),
      SizedBox(height: 4),
      TextField(
        controller:   ctrl,
        keyboardType: keyboardType,
        style: TextStyle(
            color: context.appTextPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText:   hint,
          prefixIcon: Icon(icon,
              color: context.appTextSecondary, size: 18),
          filled:     true,
          fillColor:  context.appCardBg,
          border:     OutlineInputBorder(
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
