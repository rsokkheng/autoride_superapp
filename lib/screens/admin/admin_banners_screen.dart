import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class AdminBannersScreen extends StatefulWidget {
  const AdminBannersScreen({super.key});

  @override
  State<AdminBannersScreen> createState() => _AdminBannersScreenState();
}

class _AdminBannersScreenState extends State<AdminBannersScreen> {
  List<Map<String, dynamic>> _banners = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await ApiService.getAdminBanners();
      if (!mounted) return;
      setState(() { _banners = list; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  Future<void> _delete(Map<String, dynamic> banner) async {
    final id = (banner['id'] as num?)?.toInt();
    if (id == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.appSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Banner', style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w700)),
        content: Text('Remove this banner?', style: TextStyle(color: context.appTextSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: TextStyle(color: context.appTextSecondary))),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ApiService.deleteAdminBanner(id);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: AppTheme.danger, behavior: SnackBarBehavior.floating));
    }
  }

  void _showForm([Map<String, dynamic>? existing]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.appSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _BannerForm(existing: existing, onSaved: _load),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(title: Text('Banners')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.accent,
        child: Icon(Icons.add, color: Colors.white),
        onPressed: () => _showForm(),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.error_outline, color: AppTheme.danger, size: 40), SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: context.appTextSecondary), textAlign: TextAlign.center), SizedBox(height: 16),
                  ElevatedButton(onPressed: _load, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent), child: Text('Retry')),
                ]))
              : _banners.isEmpty
                  ? Center(child: Text('No banners yet.', style: TextStyle(color: context.appTextSecondary)))
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppTheme.accent,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: _banners.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final b     = _banners[i];
                          final title = b['title'] as String? ?? 'Untitled';
                          final img   = b['image_url'] as String? ?? b['image'] as String? ?? '';
                          final active = b['active'] == true || b['is_active'] == true;

                          return Container(
                            decoration: BoxDecoration(color: context.appSurface, borderRadius: BorderRadius.circular(14), border: Border.all(color: active ? AppTheme.accent.withValues(alpha: 0.3) : context.appCardBg)),
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              leading: img.isNotEmpty
                                  ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(img, width: 52, height: 52, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.image_outlined, color: context.appTextSecondary, size: 28)))
                                  : Container(width: 52, height: 52, decoration: BoxDecoration(color: context.appCardBg, borderRadius: BorderRadius.circular(8)), child: Icon(Icons.image_outlined, color: context.appTextSecondary, size: 24)),
                              title: Text(title, style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                              subtitle: active
                                  ? Text('Active', style: TextStyle(color: AppTheme.success, fontSize: 12, fontWeight: FontWeight.w600))
                                  : Text('Inactive', style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
                              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                IconButton(icon: Icon(Icons.edit_outlined, color: context.appTextSecondary, size: 20), onPressed: () => _showForm(b), tooltip: 'Edit'),
                                IconButton(icon: const Icon(Icons.delete_outline, color: AppTheme.danger, size: 20), onPressed: () => _delete(b), tooltip: 'Delete'),
                              ]),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

class _BannerForm extends StatefulWidget {
  final Map<String, dynamic>? existing;
  final VoidCallback onSaved;
  const _BannerForm({this.existing, required this.onSaved});

  @override
  State<_BannerForm> createState() => _BannerFormState();
}

class _BannerFormState extends State<_BannerForm> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _subtitleCtrl;
  late final TextEditingController _imgCtrl;
  bool _active  = true;
  bool _saving  = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl    = TextEditingController(text: e?['title']    as String? ?? '');
    _subtitleCtrl = TextEditingController(text: e?['subtitle'] as String? ?? e?['description'] as String? ?? '');
    _imgCtrl      = TextEditingController(text: e?['image_url'] as String? ?? e?['image'] as String? ?? '');
    _active       = e?['active'] == true || e?['is_active'] == true || e == null;
  }

  @override
  void dispose() {
    _titleCtrl.dispose(); _subtitleCtrl.dispose(); _imgCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) { setState(() => _error = 'Title is required.'); return; }
    setState(() { _saving = true; _error = null; });
    final data = {
      'title':     _titleCtrl.text.trim(),
      'subtitle':  _subtitleCtrl.text.trim(),
      'image_url': _imgCtrl.text.trim(),
      'active':    _active,
    };
    try {
      if (widget.existing == null) {
        await ApiService.createAdminBanner(data);
      } else {
        final id = (widget.existing!['id'] as num?)?.toInt() ?? 0;
        await ApiService.updateAdminBanner(id, data);
      }
      if (!mounted) return;
      Navigator.pop(context);
      widget.onSaved();
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _saving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(widget.existing == null ? 'New Banner' : 'Edit Banner', style: TextStyle(color: context.appTextPrimary, fontSize: 18, fontWeight: FontWeight.w800))),
          IconButton(icon: Icon(Icons.close, color: context.appTextSecondary), onPressed: () => Navigator.pop(context)),
        ]),
        if (_error != null) ...[
          SizedBox(height: 10),
          Text(_error!, style: TextStyle(color: AppTheme.danger, fontSize: 13)),
        ],
        SizedBox(height: 16),
        _FormField(controller: _titleCtrl,    hint: 'Title'),
        SizedBox(height: 10),
        _FormField(controller: _subtitleCtrl, hint: 'Subtitle / Description'),
        SizedBox(height: 10),
        _FormField(controller: _imgCtrl,      hint: 'Image URL (optional)'),
        SizedBox(height: 12),
        Row(children: [
          Text('Active', style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w600)),
          const Spacer(),
          Switch(value: _active, onChanged: (v) => setState(() => _active = v), activeColor: AppTheme.accent),
        ]),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent, disabledBackgroundColor: AppTheme.accent.withValues(alpha: 0.4), padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Save Banner', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
        )),
      ]),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  const _FormField({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: TextStyle(color: context.appTextPrimary),
      decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: context.appTextSecondary), filled: true, fillColor: context.appCardBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.accent, width: 1.5))),
    );
  }
}
