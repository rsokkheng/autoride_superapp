import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../passenger/passenger_home.dart';
import '../driver/driver_home.dart';
import '../driver/driver_approval_pending_screen.dart';
import 'login_screen.dart';

// Local session cache — used by login/social/biometric to remember who logged in.
class SavedAccount {
  final String email;
  final String name;
  final String role;
  final String token;
  final String? avatarUrl;

  const SavedAccount({
    required this.email,
    required this.name,
    required this.role,
    required this.token,
    this.avatarUrl,
  });

  Map<String, dynamic> toJson() => {
    'email': email, 'name': name, 'role': role, 'token': token,
    if (avatarUrl != null) 'avatarUrl': avatarUrl,
  };

  factory SavedAccount.fromJson(Map<String, dynamic> j) => SavedAccount(
    email:     j['email']     as String,
    name:      j['name']      as String,
    role:      j['role']      as String,
    token:     j['token']     as String,
    avatarUrl: j['avatarUrl'] as String?,
  );
}

class AccountManager {
  static const _key = 'saved_accounts';

  static Future<List<SavedAccount>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getStringList(_key) ?? [];
    return raw.map((s) {
      try { return SavedAccount.fromJson(jsonDecode(s) as Map<String, dynamic>); }
      catch (_) { return null; }
    }).whereType<SavedAccount>().toList();
  }

  static Future<void> save(SavedAccount account) async {
    final prefs    = await SharedPreferences.getInstance();
    final accounts = await load();
    final updated  = [account, ...accounts.where((a) => a.email != account.email)];
    await prefs.setStringList(_key, updated.map((a) => jsonEncode(a.toJson())).toList());
  }

  static Future<void> remove(String email) async {
    final prefs    = await SharedPreferences.getInstance();
    final accounts = await load();
    await prefs.setStringList(
      _key,
      accounts.where((a) => a.email != email).map((a) => jsonEncode(a.toJson())).toList(),
    );
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class AccountSwitcherScreen extends StatefulWidget {
  const AccountSwitcherScreen({super.key});

  @override
  State<AccountSwitcherScreen> createState() => _AccountSwitcherScreenState();
}

class _AccountSwitcherScreenState extends State<AccountSwitcherScreen> {
  List<Map<String, dynamic>> _linked = [];
  bool _loading    = true;
  int? _switchingId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await ApiService.getLinkedAccounts();
      if (!mounted) return;
      setState(() { _linked = list; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  Future<void> _switchTo(Map<String, dynamic> account) async {
    final id = account['id'] as int? ?? (account['id'] as num?)?.toInt();
    if (id == null) return;
    setState(() { _switchingId = id; });
    try {
      final result = await ApiService.switchLinkedAccount(id);
      if (!mounted) return;

      Widget destination;
      if (result.user.isDriver) {
        try {
          final approval = await ApiService.getDriverApprovalStatus();
          destination = approval.isApproved ? const DriverHomeScreen() : const DriverApprovalPendingScreen();
        } catch (_) {
          destination = const DriverHomeScreen();
        }
      } else {
        destination = const PassengerHomeScreen();
      }

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => destination),
        (route) => false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _switchingId = null);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message),
        backgroundColor: e.statusCode == 401 ? AppTheme.warning : AppTheme.danger,
        behavior: SnackBarBehavior.floating,
      ));
      if (e.statusCode == 401) await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _switchingId = null);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _removeAccount(Map<String, dynamic> account) async {
    final id   = (account['id'] as num?)?.toInt();
    final name = account['name'] as String? ?? account['email'] as String? ?? 'this account';
    if (id == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.appSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Remove Account', style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w700)),
        content: Text('Unlink $name from your account?', style: TextStyle(color: context.appTextSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: TextStyle(color: context.appTextSecondary))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await ApiService.deleteLinkedAccount(id);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _addAccount() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.appSurface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _LinkAccountSheet(onLinked: _load),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(title: const Text('Switch Account')),
      body: Column(children: [
        Expanded(child: _buildBody()),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _switchingId != null ? null : _addAccount,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.accent,
                side: const BorderSide(color: AppTheme.accent, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.link_rounded),
              label: const Text('Link Account', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppTheme.accent));
    if (_error != null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.error_outline, color: AppTheme.danger, size: 40),
        SizedBox(height: 12),
        Text(_error!, style: TextStyle(color: context.appTextSecondary), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: _load, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent), child: const Text('Retry')),
      ]));
    }
    if (_linked.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.manage_accounts_outlined, color: context.appTextSecondary, size: 56),
        SizedBox(height: 16),
        Text('No linked accounts', style: TextStyle(color: context.appTextSecondary, fontSize: 16)),
        SizedBox(height: 8),
        Text('Link another account to switch between them.',
            style: TextStyle(color: context.appTextSecondary, fontSize: 13), textAlign: TextAlign.center),
      ]));
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AppTheme.accent,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _linked.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final acc = _linked[i];
          final id  = (acc['id'] as num?)?.toInt();
          return _AccountTile(
            account:    acc,
            switching:  _switchingId == id,
            onSwitch:   _switchingId != null ? null : () => _switchTo(acc),
            onRemove:   _switchingId != null ? null : () => _removeAccount(acc),
          );
        },
      ),
    );
  }
}

// ── Link account bottom sheet ─────────────────────────────────────────────────

class _LinkAccountSheet extends StatefulWidget {
  final VoidCallback onLinked;
  const _LinkAccountSheet({required this.onLinked});

  @override
  State<_LinkAccountSheet> createState() => _LinkAccountSheetState();
}

class _LinkAccountSheetState extends State<_LinkAccountSheet> {
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _labelCtrl = TextEditingController();
  bool _obscure  = true;
  bool _loading  = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _labelCtrl.dispose();
    super.dispose();
  }

  Future<void> _link() async {
    final email = _emailCtrl.text.trim();
    final pass  = _passCtrl.text;
    if (email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Enter email and password.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await ApiService.linkAccount(
        email:    email,
        password: pass,
        label:    _labelCtrl.text.trim().isEmpty ? null : _labelCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context);
      widget.onLinked();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('Link Account', style: TextStyle(color: context.appTextPrimary, fontSize: 18, fontWeight: FontWeight.w800))),
          IconButton(
            icon: Icon(Icons.close, color: context.appTextSecondary),
            onPressed: () => Navigator.pop(context),
          ),
        ]),
        SizedBox(height: 20),

        if (_error != null) ...[
          Container(
            padding: EdgeInsets.all(12),
            margin: EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppTheme.danger.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
            ),
            child: Text(_error!, style: TextStyle(color: AppTheme.danger, fontSize: 13)),
          ),
        ],

        _SheetField(controller: _emailCtrl, hint: 'Email', icon: Icons.email_outlined, type: TextInputType.emailAddress),
        SizedBox(height: 12),
        _SheetField(controller: _passCtrl, hint: 'Password', icon: Icons.lock_outline, obscure: _obscure,
          suffix: GestureDetector(
            onTap: () => setState(() => _obscure = !_obscure),
            child: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: context.appTextSecondary, size: 20),
          ),
        ),
        const SizedBox(height: 12),
        _SheetField(controller: _labelCtrl, hint: 'Label (optional, e.g. "Work")', icon: Icons.label_outline),
        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _link,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              disabledBackgroundColor: AppTheme.accent.withValues(alpha: 0.4),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Link Account', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
          ),
        ),
      ]),
    );
  }
}

class _SheetField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? type;
  final bool obscure;
  final Widget? suffix;

  const _SheetField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.type,
    this.obscure = false,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: type,
      obscureText: obscure,
      style: TextStyle(color: context.appTextPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: context.appTextSecondary),
        prefixIcon: Icon(icon, color: context.appTextSecondary, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: context.appCardBg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.accent, width: 1.5),
        ),
      ),
    );
  }
}

// ── Account tile ──────────────────────────────────────────────────────────────

class _AccountTile extends StatelessWidget {
  final Map<String, dynamic> account;
  final bool switching;
  final VoidCallback? onSwitch;
  final VoidCallback? onRemove;

  const _AccountTile({
    required this.account,
    required this.switching,
    this.onSwitch,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final name  = account['name']  as String? ?? account['email'] as String? ?? 'Account';
    final email = account['email'] as String? ?? '';
    final label = account['label'] as String?;
    final role  = account['role']  as String? ?? 'passenger';
    final isDriver = role == 'driver';

    return Container(
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: switching ? AppTheme.accent : context.appCardBg, width: switching ? 1.5 : 1),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: AppTheme.accent.withValues(alpha: 0.12),
          radius: 24,
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w800, fontSize: 18),
          ),
        ),
        title: Row(children: [
          Expanded(child: Text(label ?? name, style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w600, fontSize: 14))),
        ]),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (label != null) Text(name, style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
          Text(email, style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
          SizedBox(height: 4),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isDriver ? AppTheme.accentOrange.withValues(alpha: 0.12) : AppTheme.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isDriver ? 'Driver' : 'Passenger',
              style: TextStyle(color: isDriver ? AppTheme.accentOrange : AppTheme.accent, fontSize: 10, fontWeight: FontWeight.w700),
            ),
          ),
        ]),
        trailing: switching
            ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppTheme.accent, strokeWidth: 2))
            : Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                  icon: Icon(Icons.delete_outline, color: context.appTextSecondary, size: 20),
                  onPressed: onRemove,
                  tooltip: 'Remove',
                ),
                ElevatedButton(
                  onPressed: onSwitch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                    textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  child: const Text('Switch'),
                ),
              ]),
      ),
    );
  }
}
