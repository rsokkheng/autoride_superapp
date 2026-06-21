import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  String? _error;
  String? _roleFilter;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await ApiService.getAdminUsers(
        role: _roleFilter,
        search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
      );
      if (!mounted) return;
      setState(() { _users = list; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  Future<void> _creditUser(Map<String, dynamic> user) async {
    final id   = (user['id'] as num?)?.toInt();
    final name = user['name'] as String? ?? 'User';
    if (id == null) return;

    final amtCtrl  = TextEditingController();
    final noteCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.appSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Credit $name', style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _DialogField(controller: amtCtrl, hint: 'Amount (KHR)', type: TextInputType.number),
          SizedBox(height: 12),
          _DialogField(controller: noteCtrl, hint: 'Note (optional)'),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: TextStyle(color: context.appTextSecondary))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
            child: const Text('Credit'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final amt = int.tryParse(amtCtrl.text.trim());
    if (amt == null || amt <= 0) return;
    try {
      await ApiService.creditAdminUser(id, amt, note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Credit applied.'), backgroundColor: AppTheme.success, behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: AppTheme.danger, behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final id   = (user['id'] as num?)?.toInt();
    final name = user['name'] as String? ?? 'User';
    if (id == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.appSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete User', style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w700)),
        content: Text('Permanently delete $name?', style: TextStyle(color: context.appTextSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: TextStyle(color: context.appTextSecondary))),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ApiService.deleteAdminUser(id);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: AppTheme.danger, behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(title: Text('Users')),
      body: Column(children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                style: TextStyle(color: context.appTextPrimary),
                decoration: InputDecoration(
                  hintText: 'Search by name / email…',
                  hintStyle: TextStyle(color: context.appTextSecondary),
                  prefixIcon: Icon(Icons.search, color: context.appTextSecondary, size: 20),
                  filled: true,
                  fillColor: context.appSurface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
                onSubmitted: (_) => _load(),
              ),
            ),
            SizedBox(width: 8),
            PopupMenuButton<String?>(
              color: context.appSurface,
              icon: Icon(Icons.filter_list_rounded, color: _roleFilter != null ? AppTheme.accent : context.appTextSecondary),
              onSelected: (v) { setState(() => _roleFilter = v); _load(); },
              itemBuilder: (_) => [
                PopupMenuItem(value: null,        child: Text('All Roles',  style: TextStyle(color: context.appTextPrimary))),
                PopupMenuItem(value: 'passenger', child: Text('Passenger',  style: TextStyle(color: context.appTextPrimary))),
                PopupMenuItem(value: 'driver',    child: Text('Driver',     style: TextStyle(color: context.appTextPrimary))),
                PopupMenuItem(value: 'admin',     child: Text('Admin',      style: TextStyle(color: context.appTextPrimary))),
              ],
            ),
          ]),
        ),
        const SizedBox(height: 8),
        Expanded(child: _buildBody()),
      ]),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppTheme.accent));
    if (_error != null) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.error_outline, color: AppTheme.danger, size: 40),
      SizedBox(height: 12),
      Text(_error!, style: TextStyle(color: context.appTextSecondary), textAlign: TextAlign.center),
      const SizedBox(height: 16),
      ElevatedButton(onPressed: _load, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent), child: const Text('Retry')),
    ]));
    if (_users.isEmpty) return Center(child: Text('No users found.', style: TextStyle(color: context.appTextSecondary)));
    return RefreshIndicator(
      onRefresh: _load,
      color: AppTheme.accent,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _users.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final u    = _users[i];
          final name = u['name']  as String? ?? '—';
          final email= u['email'] as String? ?? '';
          final role = u['role']  as String? ?? '';
          final roleColor = role == 'admin' ? AppTheme.danger : role == 'driver' ? AppTheme.accentOrange : AppTheme.accent;
          return Container(
            decoration: BoxDecoration(color: context.appSurface, borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              leading: CircleAvatar(
                backgroundColor: roleColor.withValues(alpha: 0.12),
                child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(color: roleColor, fontWeight: FontWeight.w800)),
              ),
              title: Text(name, style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(email, style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
                SizedBox(height: 2),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(color: roleColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                  child: Text(role.toUpperCase(), style: TextStyle(color: roleColor, fontSize: 9, fontWeight: FontWeight.w700)),
                ),
              ]),
              trailing: PopupMenuButton<String>(
                color: context.appSurface,
                icon: Icon(Icons.more_vert, color: context.appTextSecondary, size: 20),
                onSelected: (v) {
                  if (v == 'credit') _creditUser(u);
                  if (v == 'delete') _deleteUser(u);
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'credit', child: Text('Credit Wallet', style: TextStyle(color: context.appTextPrimary))),
                  PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppTheme.danger))),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DialogField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? type;
  const _DialogField({required this.controller, required this.hint, this.type});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: type,
      style: TextStyle(color: context.appTextPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: context.appTextSecondary),
        filled: true,
        fillColor: context.appCardBg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    );
  }
}
