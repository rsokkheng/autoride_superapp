import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class SurgePromoScreen extends StatefulWidget {
  const SurgePromoScreen({super.key});

  @override
  State<SurgePromoScreen> createState() => _SurgePromoScreenState();
}

class _SurgePromoScreenState extends State<SurgePromoScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      appBar: AppBar(
        title: const Text('Surge & Promo Control'),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: AppTheme.accent,
          labelColor: AppTheme.accent,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: const [
            Tab(icon: Icon(Icons.bolt_outlined), text: 'Surge'),
            Tab(icon: Icon(Icons.local_offer_outlined), text: 'Promos'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          _SurgeTab(),
          _PromoTab(),
        ],
      ),
    );
  }
}

// ── Surge zones tab ───────────────────────────────────────────────────────────

class _SurgeTab extends StatefulWidget {
  const _SurgeTab();

  @override
  State<_SurgeTab> createState() => _SurgeTabState();
}

class _SurgeTabState extends State<_SurgeTab> {
  List<Map<String, dynamic>> _zones = [];
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
      final list = await ApiService.getAdminSurgeZones();
      if (!mounted) return;
      setState(() { _zones = list; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  Future<void> _toggle(Map<String, dynamic> zone) async {
    final id = (zone['id'] as num?)?.toInt();
    if (id == null) return;
    try {
      final updated = await ApiService.toggleAdminSurgeZone(id);
      if (!mounted) return;
      setState(() {
        final idx = _zones.indexWhere((z) => z['id'] == zone['id']);
        if (idx >= 0) _zones[idx] = updated;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _delete(Map<String, dynamic> zone) async {
    final id = (zone['id'] as num?)?.toInt();
    if (id == null) return;
    final name = zone['name'] as String? ?? 'this zone';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Surge Zone',
            style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
        content: Text('Delete "$name"?',
            style: const TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary))),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ApiService.deleteAdminSurgeZone(id);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _showForm([Map<String, dynamic>? zone]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _SurgeZoneSheet(zone: zone, onSaved: () { Navigator.pop(context); _load(); }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        backgroundColor: AppTheme.warning,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Zone',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.error_outline, color: AppTheme.danger, size: 40),
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: AppTheme.textSecondary),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _load,
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
                      child: const Text('Retry')),
                ]))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppTheme.accent,
                  child: _zones.isEmpty
                      ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.bolt_outlined, color: AppTheme.textSecondary, size: 48),
                          SizedBox(height: 12),
                          Text('No surge zones configured.',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
                        ]))
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                          itemCount: _zones.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final z = _zones[i];
                            final name = z['name'] as String? ?? 'Zone ${z['id']}';
                            final mult = double.tryParse(z['multiplier']?.toString() ?? '1') ?? 1.0;
                            final active = z['is_active'] as bool? ?? z['active'] as bool? ?? false;
                            final desc = z['description'] as String? ?? '';

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: active
                                    ? Border.all(color: AppTheme.warning.withValues(alpha: 0.35))
                                    : null,
                              ),
                              child: Row(children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.warning.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.bolt_rounded, color: AppTheme.warning, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(name,
                                        style: const TextStyle(color: AppTheme.textPrimary,
                                            fontWeight: FontWeight.w700, fontSize: 14)),
                                    const SizedBox(height: 2),
                                    Row(children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppTheme.warning.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text('×${mult.toStringAsFixed(1)}',
                                            style: const TextStyle(color: AppTheme.warning,
                                                fontSize: 11, fontWeight: FontWeight.w700)),
                                      ),
                                      if (desc.isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(desc,
                                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                                            maxLines: 1, overflow: TextOverflow.ellipsis)),
                                      ],
                                    ]),
                                  ]),
                                ),
                                Switch(
                                  value: active,
                                  onChanged: (_) => _toggle(z),
                                  activeColor: AppTheme.warning,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, color: AppTheme.textSecondary, size: 20),
                                  onPressed: () => _showForm(z),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: AppTheme.danger, size: 20),
                                  onPressed: () => _delete(z),
                                ),
                              ]),
                            );
                          },
                        ),
                ),
    );
  }
}

class _SurgeZoneSheet extends StatefulWidget {
  final Map<String, dynamic>? zone;
  final VoidCallback onSaved;
  const _SurgeZoneSheet({this.zone, required this.onSaved});

  @override
  State<_SurgeZoneSheet> createState() => _SurgeZoneSheetState();
}

class _SurgeZoneSheetState extends State<_SurgeZoneSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  double _multiplier = 1.5;
  bool _active = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final z = widget.zone;
    _nameCtrl   = TextEditingController(text: z?['name'] as String? ?? '');
    _descCtrl   = TextEditingController(text: z?['description'] as String? ?? '');
    _multiplier = double.tryParse(z?['multiplier']?.toString() ?? '1.5') ?? 1.5;
    _active     = z?['is_active'] as bool? ?? z?['active'] as bool? ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Zone name is required.');
      return;
    }
    setState(() { _saving = true; _error = null; });
    final data = <String, dynamic>{
      'name':        _nameCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'multiplier':  _multiplier,
      'active':      _active,
    };
    try {
      if (widget.zone == null) {
        await ApiService.createAdminSurgeZone(data);
      } else {
        await ApiService.updateAdminSurgeZone((widget.zone!['id'] as num).toInt(), data);
      }
      if (!mounted) return;
      widget.onSaved();
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _saving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 12),
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: Text(widget.zone == null ? 'New Surge Zone' : 'Edit Surge Zone',
                style: const TextStyle(color: AppTheme.textPrimary,
                    fontSize: 18, fontWeight: FontWeight.w800))),
            IconButton(icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                onPressed: () => Navigator.pop(context)),
          ]),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: AppTheme.danger, fontSize: 13)),
          ],
          const SizedBox(height: 16),
          _SurgeInput(controller: _nameCtrl, label: 'Zone Name', hint: 'e.g. City Centre'),
          const SizedBox(height: 12),
          _SurgeInput(controller: _descCtrl, label: 'Description (optional)', hint: 'e.g. High demand area'),
          const SizedBox(height: 16),
          Text('Multiplier: ×${_multiplier.toStringAsFixed(1)}',
              style: const TextStyle(color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600, fontSize: 14)),
          Slider(
            value: _multiplier,
            min: 1.0,
            max: 5.0,
            divisions: 40,
            label: '×${_multiplier.toStringAsFixed(1)}',
            activeColor: AppTheme.warning,
            onChanged: (v) => setState(() => _multiplier = v),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [
            Text('×1.0', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
            Text('×5.0', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            const Text('Active', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
            const Spacer(),
            Switch(value: _active, onChanged: (v) => setState(() => _active = v),
                activeColor: AppTheme.warning),
          ]),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.warning,
                disabledBackgroundColor: AppTheme.warning.withValues(alpha: 0.4),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _saving
                  ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : Text(widget.zone == null ? 'Create Zone' : 'Save Changes',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            ),
          ),
        ]),
      ),
    );
  }
}

class _SurgeInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;

  const _SurgeInput({required this.controller, required this.label, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: AppTheme.textSecondary,
          fontSize: 12, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: const TextStyle(color: AppTheme.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppTheme.textSecondary),
          filled: true,
          fillColor: AppTheme.cardBg,
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

// ── Promo codes tab ───────────────────────────────────────────────────────────

class _PromoTab extends StatefulWidget {
  const _PromoTab();

  @override
  State<_PromoTab> createState() => _PromoTabState();
}

class _PromoTabState extends State<_PromoTab> {
  List<Map<String, dynamic>> _promos = [];
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
      final data = await ApiService.getAdminPromos();
      if (!mounted) return;
      setState(() { _promos = data; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _showCreateSheet({Map<String, dynamic>? promo}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _PromoEditSheet(
        promo: promo,
        onSaved: () { Navigator.pop(ctx); _load(); },
      ),
    );
  }

  Future<void> _delete(Map<String, dynamic> promo) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Promo',
            style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
        content: Text('Delete promo code "${promo['code']}"?',
            style: const TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary))),
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
      await ApiService.deleteAdminPromo(promo['id'] as int);
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
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateSheet,
        backgroundColor: AppTheme.accent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Promo',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.error_outline, color: AppTheme.danger, size: 40),
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: AppTheme.textSecondary),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _load,
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
                      child: const Text('Retry')),
                ]))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppTheme.accent,
                  child: _promos.isEmpty
                      ? const Center(child: Text('No promo codes.',
                          style: TextStyle(color: AppTheme.textSecondary)))
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                          itemCount: _promos.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) => _PromoTile(
                            promo: _promos[i],
                            onEdit: () => _showCreateSheet(promo: _promos[i]),
                            onDelete: () => _delete(_promos[i]),
                          ),
                        ),
                ),
    );
  }
}

class _PromoTile extends StatelessWidget {
  final Map<String, dynamic> promo;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PromoTile({required this.promo, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final code      = promo['code']        as String? ?? '—';
    final discount  = promo['discount']    ?? promo['discount_khr'] ?? 0;
    final usesLeft  = promo['uses_remaining'] ?? promo['max_uses'] ?? '∞';
    final expiresAt = promo['expires_at']  as String? ?? '';
    final isActive  = promo['is_active']   as bool? ?? true;
    final short     = expiresAt.length >= 10 ? expiresAt.substring(0, 10) : expiresAt;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: isActive
            ? Border.all(color: AppTheme.accent.withValues(alpha: 0.3))
            : null,
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.local_offer_outlined,
              color: AppTheme.accent, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(code,
                style: const TextStyle(color: AppTheme.accent,
                    fontWeight: FontWeight.w800, fontSize: 15,
                    fontFamily: 'monospace', letterSpacing: 2)),
            const SizedBox(height: 4),
            Row(children: [
              Text('${AppTheme.khr(discount is int ? discount : (discount as num).toInt())} off',
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12)),
              const Text(' · ', style: TextStyle(color: AppTheme.textSecondary)),
              Text('$usesLeft uses left',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              if (short.isNotEmpty) ...[
                const Text(' · ', style: TextStyle(color: AppTheme.textSecondary)),
                Text('Exp $short',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ]),
          ]),
        ),
        IconButton(
          icon: const Icon(Icons.edit_outlined, color: AppTheme.accent, size: 20),
          onPressed: onEdit,
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: AppTheme.danger, size: 20),
          onPressed: onDelete,
        ),
      ]),
    );
  }
}

class _PromoEditSheet extends StatefulWidget {
  final Map<String, dynamic>? promo;
  final VoidCallback onSaved;

  const _PromoEditSheet({this.promo, required this.onSaved});

  @override
  State<_PromoEditSheet> createState() => _PromoEditSheetState();
}

class _PromoEditSheetState extends State<_PromoEditSheet> {
  final _codeCtrl      = TextEditingController();
  final _discountCtrl  = TextEditingController();
  final _usesCtrl      = TextEditingController();
  final _expiresCtrl   = TextEditingController();
  bool _active = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final p = widget.promo;
    if (p != null) {
      _codeCtrl.text     = p['code']        as String? ?? '';
      _discountCtrl.text = (p['discount']   ?? p['discount_khr'] ?? '').toString();
      _usesCtrl.text     = (p['max_uses']   ?? '').toString();
      final exp = p['expires_at'] as String? ?? '';
      _expiresCtrl.text = exp.length >= 10 ? exp.substring(0, 10) : exp;
      _active = p['is_active'] as bool? ?? true;
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _discountCtrl.dispose();
    _usesCtrl.dispose();
    _expiresCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code     = _codeCtrl.text.trim().toUpperCase();
    final discount = int.tryParse(_discountCtrl.text.trim());
    if (code.isEmpty || discount == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Code and discount amount are required.'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    setState(() => _submitting = true);
    final data = <String, dynamic>{
      'code': code,
      'discount': discount,
      'is_active': _active,
      if (_usesCtrl.text.trim().isNotEmpty)
        'max_uses': int.tryParse(_usesCtrl.text.trim()),
      if (_expiresCtrl.text.trim().isNotEmpty)
        'expires_at': _expiresCtrl.text.trim(),
    };

    try {
      if (widget.promo != null) {
        await ApiService.updateAdminPromo(widget.promo!['id'] as int, data);
      } else {
        await ApiService.createAdminPromo(data);
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
          const SizedBox(height: 12),
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),

          Text(widget.promo != null ? 'Edit Promo Code' : 'New Promo Code',
              style: const TextStyle(color: AppTheme.textPrimary,
                  fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),

          _SurgeInput(controller: _codeCtrl, label: 'Promo Code', hint: 'e.g. ROTEH2026'),
          const SizedBox(height: 12),
          _SurgeInput(controller: _discountCtrl, label: 'Discount (KHR)', hint: 'e.g. 10000'),
          const SizedBox(height: 12),
          _SurgeInput(controller: _usesCtrl, label: 'Max Uses (leave blank = unlimited)', hint: 'e.g. 100'),
          const SizedBox(height: 12),
          _SurgeInput(controller: _expiresCtrl, label: 'Expires At (YYYY-MM-DD)', hint: 'e.g. 2026-12-31'),
          const SizedBox(height: 16),

          Row(children: [
            const Text('Active', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
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
                  : Text(widget.promo != null ? 'Save Changes' : 'Create Promo',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            ),
          ),
        ]),
      ),
    );
  }
}
