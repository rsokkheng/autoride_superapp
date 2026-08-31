import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../utils/phone_utils.dart';
import '../../l10n/app_localizations.dart';
import 'ride_booking.dart';

class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key});
  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  FamilyGroup? _group;
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
      _group = await ApiService.getFamilyGroup();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).familyAccountTitle),
        actions: [
          if (_group != null)
            IconButton(
              icon: const Icon(Icons.person_add_rounded),
              tooltip: AppLocalizations.of(context).addMemberTooltip,
              onPressed: () => _showAddMember(context),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _load)
              : _group == null
                  ? _SetupView(onCreated: (g) => setState(() => _group = g))
                  : _GroupView(
                      group:    _group!,
                      onReload: _load,
                      onAddMember: () => _showAddMember(context),
                    ),
    );
  }

  Future<void> _showAddMember(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.appSurface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddMemberSheet(onAdded: (m) {
        setState(() => _group = FamilyGroup(
          id:      _group!.id,
          name:    _group!.name,
          members: [..._group!.members, m],
        ));
      }),
    );
  }
}

// ── Setup (no group yet) ──────────────────────────────────────────────────────

class _SetupView extends StatefulWidget {
  final ValueChanged<FamilyGroup> onCreated;
  const _SetupView({required this.onCreated});
  @override
  State<_SetupView> createState() => _SetupViewState();
}

class _SetupViewState extends State<_SetupView> {
  final _nameCtrl = TextEditingController();
  bool    _busy = false;
  String? _err;

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  Future<void> _create() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() { _busy = true; _err = null; });
    try {
      final g = await ApiService.setupFamilyGroup(_nameCtrl.text.trim());
      widget.onCreated(g);
    } on ApiException catch (e) {
      setState(() { _err = e.message; _busy = false; });
    } catch (e) {
      setState(() { _err = e.toString().replaceFirst('Exception: ', ''); _busy = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(Icons.family_restroom_rounded,
              color: AppTheme.accent, size: 40),
        ),
        SizedBox(height: 20),
        Text(AppLocalizations.of(context).createFamilyGroupTitle,
            style: TextStyle(color: context.appTextPrimary, fontSize: 20,
                fontWeight: FontWeight.w700)),
        SizedBox(height: 8),
        Text(
          AppLocalizations.of(context).familyGroupDescription,
          textAlign: TextAlign.center,
          style: TextStyle(color: context.appTextSecondary, height: 1.5),
        ),
        SizedBox(height: 32),
        TextField(
          controller: _nameCtrl,
          style: TextStyle(color: context.appTextPrimary),
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context).groupNameHint,
            hintStyle: TextStyle(color: context.appTextSecondary),
            prefixIcon: Icon(Icons.group_rounded,
                color: context.appTextSecondary, size: 20),
            filled: true,
            fillColor: context.appSurface,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.accent, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
        if (_err != null) ...[
          const SizedBox(height: 10),
          _ErrMsg(_err!),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _busy ? null : _create,
            icon: _busy
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.add_rounded),
            label: Text(AppLocalizations.of(context).createGroup,
                style: TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Group view ────────────────────────────────────────────────────────────────

class _GroupView extends StatelessWidget {
  final FamilyGroup  group;
  final VoidCallback onReload;
  final VoidCallback onAddMember;
  const _GroupView({required this.group, required this.onReload, required this.onAddMember});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Group header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF004D40), Color(0xFF00B14F)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(children: [
            const Icon(Icons.family_restroom_rounded, color: Colors.white, size: 32),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(group.name,
                  style: const TextStyle(color: Colors.white, fontSize: 17,
                      fontWeight: FontWeight.w800)),
              Text('${group.members.length} ${AppLocalizations.of(context).membersCountSuffix}',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13)),
            ])),
          ]),
        ),

        SizedBox(height: 20),

        // Members label + add button
        Row(children: [
          Text(AppLocalizations.of(context).membersLabel,
              style: TextStyle(color: context.appTextPrimary, fontSize: 14,
                  fontWeight: FontWeight.w700)),
          Spacer(),
          TextButton.icon(
            onPressed: onAddMember,
            icon: Icon(Icons.add_rounded, size: 16, color: AppTheme.accent),
            label: Text(AppLocalizations.of(context).add, style: TextStyle(color: AppTheme.accent,
                fontWeight: FontWeight.w600)),
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
          ),
        ]),
        SizedBox(height: 10),

        if (group.members.isEmpty)
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: context.appSurface, borderRadius: BorderRadius.circular(14)),
            child: Center(child: Text(AppLocalizations.of(context).noMembersYetMsg,
                textAlign: TextAlign.center,
                style: TextStyle(color: context.appTextSecondary, fontSize: 13))),
          )
        else
          ...group.members.map((m) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _MemberCard(
              member:   m,
              onBook:   () => _bookForMember(context, m),
              onEdit:   () => _editMember(context, m, onReload),
              onRemove: () => _removeMember(context, m, onReload),
            ),
          )),
      ],
    );
  }

  void _bookForMember(BuildContext context, FamilyMember m) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RideBookingScreen(
          forFamilyMember: m,
        ),
      ),
    );
  }

  Future<void> _editMember(
      BuildContext context, FamilyMember m, VoidCallback onReload) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.appSurface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _EditMemberSheet(member: m, onUpdated: onReload),
    );
  }

  Future<void> _removeMember(
      BuildContext context, FamilyMember m, VoidCallback onReload) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.appSurface,
        title: Text(AppLocalizations.of(context).removeMemberQuestion,
            style: TextStyle(color: context.appTextPrimary)),
        content: Text('${AppLocalizations.of(context).removeMemberPrefix} ${m.name} ${AppLocalizations.of(context).fromFamilyGroupQuestionSuffix}',
            style: TextStyle(color: context.appTextSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalizations.of(context).cancel,
                  style: TextStyle(color: context.appTextSecondary))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(AppLocalizations.of(context).remove,
                  style: const TextStyle(color: AppTheme.danger))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ApiService.removeFamilyMember(m.id);
      onReload();
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.message), backgroundColor: AppTheme.danger));
      }
    }
  }
}

// ── Member card ───────────────────────────────────────────────────────────────

class _MemberCard extends StatelessWidget {
  final FamilyMember member;
  final VoidCallback onBook;
  final VoidCallback onEdit;
  final VoidCallback onRemove;
  const _MemberCard({
    required this.member, required this.onBook,
    required this.onEdit, required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: context.appSurface, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: AppTheme.accentOrange.withValues(alpha: 0.12),
          backgroundImage: member.avatarUrl != null
              ? NetworkImage(member.avatarUrl!) : null,
          child: member.avatarUrl == null
              ? Text(member.name[0].toUpperCase(),
                  style: TextStyle(color: AppTheme.accentOrange,
                      fontWeight: FontWeight.w700, fontSize: 16))
              : null,
        ),
        SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(member.name,
              style: TextStyle(color: context.appTextPrimary,
                  fontWeight: FontWeight.w600, fontSize: 14)),
          Row(children: [
            Text(member.phone,
                style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
            const SizedBox(width: 6),
            Text('· ${member.relationship}',
                style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
          ]),
          if (member.hasAccount)
            Padding(
              padding: EdgeInsets.only(top: 2),
              child: Row(children: [
                Icon(Icons.check_circle_outline_rounded,
                    color: AppTheme.success, size: 12),
                SizedBox(width: 3),
                Text(AppLocalizations.of(context).hasAutorideAccountLabel,
                    style: TextStyle(color: AppTheme.success, fontSize: 11)),
              ]),
            ),
        ])),
        Column(children: [
          ElevatedButton(
            onPressed: onBook,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(AppLocalizations.of(context).bookLabel, style: TextStyle(
                fontWeight: FontWeight.w700, fontSize: 13)),
          ),
          SizedBox(height: 6),
          Row(mainAxisSize: MainAxisSize.min, children: [
            GestureDetector(
              onTap: onEdit,
              child: Icon(Icons.edit_rounded, size: 16,
                  color: context.appTextSecondary),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onRemove,
              child: const Icon(Icons.delete_outline_rounded, size: 16,
                  color: AppTheme.danger),
            ),
          ]),
        ]),
      ]),
    );
  }
}

// ── Add member bottom sheet ───────────────────────────────────────────────────

class _AddMemberSheet extends StatefulWidget {
  final ValueChanged<FamilyMember> onAdded;
  const _AddMemberSheet({required this.onAdded});
  @override
  State<_AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends State<_AddMemberSheet> {
  final _nameCtrl         = TextEditingController();
  final _phoneCtrl        = TextEditingController();
  final _relationshipCtrl = TextEditingController();
  bool    _busy = false;
  String? _err;

  List<String> _suggestions(BuildContext context) {
    final l = AppLocalizations.of(context);
    return [l.mother, l.father, l.spouse, l.son, l.daughter, l.sibling, l.friend];
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _phoneCtrl.dispose(); _relationshipCtrl.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    if (_nameCtrl.text.trim().isEmpty || _phoneCtrl.text.trim().isEmpty) return;
    final phoneError = validateLocalPhone(normalizeLocalPhone(_phoneCtrl.text));
    if (phoneError != null) {
      setState(() => _err = phoneError);
      return;
    }
    setState(() { _busy = true; _err = null; });
    try {
      final m = await ApiService.addFamilyMember(
        name:         _nameCtrl.text.trim(),
        phone:        normalizeLocalPhone(_phoneCtrl.text),
        relationship: _relationshipCtrl.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onAdded(m);
      }
    } on ApiException catch (e) {
      setState(() { _err = e.message; _busy = false; });
    } catch (e) {
      setState(() { _err = e.toString().replaceFirst('Exception: ', ''); _busy = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20,
          20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(AppLocalizations.of(context).addFamilyMemberTitle,
            style: TextStyle(color: context.appTextPrimary, fontSize: 17,
                fontWeight: FontWeight.w700)),
        SizedBox(height: 16),
        _FieldWidget(ctrl: _nameCtrl, hint: AppLocalizations.of(context).fullNameStarHint,
            icon: Icons.person_outline_rounded),
        SizedBox(height: 10),
        _FieldWidget(ctrl: _phoneCtrl, hint: AppLocalizations.of(context).phoneNumberStarHint,
            icon: Icons.phone_outlined, keyboard: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
        SizedBox(height: 10),
        _FieldWidget(ctrl: _relationshipCtrl,
            hint: AppLocalizations.of(context).relationshipHint,
            icon: Icons.people_outline_rounded),
        SizedBox(height: 8),
        // Quick-tap suggestions (free text — tapping fills the field)
        Wrap(
          spacing: 8, runSpacing: 6,
          children: _suggestions(context).map((s) => GestureDetector(
            onTap: () => setState(() => _relationshipCtrl.text = s),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _relationshipCtrl.text == s
                    ? AppTheme.accent.withValues(alpha: 0.12)
                    : context.appCardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: _relationshipCtrl.text == s
                        ? AppTheme.accent : context.appCardBg),
              ),
              child: Text(s, style: TextStyle(
                color: _relationshipCtrl.text == s
                    ? AppTheme.accent : context.appTextSecondary,
                fontSize: 12,
              )),
            ),
          )).toList(),
        ),
        if (_err != null) ...[const SizedBox(height: 10), _ErrMsg(_err!)],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _busy ? null : _add,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              disabledBackgroundColor: AppTheme.accent.withValues(alpha: 0.4),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: _busy
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : Text(AppLocalizations.of(context).addMemberBtn,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }
}

// ── Edit member bottom sheet ──────────────────────────────────────────────────

class _EditMemberSheet extends StatefulWidget {
  final FamilyMember member;
  final VoidCallback onUpdated;
  const _EditMemberSheet({required this.member, required this.onUpdated});
  @override
  State<_EditMemberSheet> createState() => _EditMemberSheetState();
}

class _EditMemberSheetState extends State<_EditMemberSheet> {
  late final _nameCtrl         = TextEditingController(text: widget.member.name);
  late final _phoneCtrl        = TextEditingController(text: widget.member.phone);
  late final _relationshipCtrl = TextEditingController(text: widget.member.relationship);
  bool    _busy = false;
  String? _err;

  List<String> _suggestions(BuildContext context) {
    final l = AppLocalizations.of(context);
    return [l.mother, l.father, l.spouse, l.son, l.daughter, l.sibling, l.friend];
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _phoneCtrl.dispose(); _relationshipCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final phoneError = validateLocalPhone(normalizeLocalPhone(_phoneCtrl.text));
    if (phoneError != null) {
      setState(() => _err = phoneError);
      return;
    }
    setState(() { _busy = true; _err = null; });
    try {
      await ApiService.updateFamilyMember(
        widget.member.id,
        name:         _nameCtrl.text.trim(),
        phone:        normalizeLocalPhone(_phoneCtrl.text),
        relationship: _relationshipCtrl.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onUpdated();
      }
    } on ApiException catch (e) {
      setState(() { _err = e.message; _busy = false; });
    } catch (e) {
      setState(() { _err = e.toString().replaceFirst('Exception: ', ''); _busy = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20,
          20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${AppLocalizations.of(context).edit} ${widget.member.name}',
            style: TextStyle(color: context.appTextPrimary, fontSize: 17,
                fontWeight: FontWeight.w700)),
        SizedBox(height: 16),
        _FieldWidget(ctrl: _nameCtrl, hint: AppLocalizations.of(context).fullNameHint,
            icon: Icons.person_outline_rounded),
        SizedBox(height: 10),
        _FieldWidget(ctrl: _phoneCtrl, hint: AppLocalizations.of(context).phoneNumberHint2,
            icon: Icons.phone_outlined, keyboard: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
        SizedBox(height: 10),
        _FieldWidget(ctrl: _relationshipCtrl,
            hint: AppLocalizations.of(context).relationshipHint,
            icon: Icons.people_outline_rounded),
        SizedBox(height: 8),
        Wrap(
          spacing: 8, runSpacing: 6,
          children: _suggestions(context).map((s) => GestureDetector(
            onTap: () => setState(() => _relationshipCtrl.text = s),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _relationshipCtrl.text == s
                    ? AppTheme.accent.withValues(alpha: 0.12)
                    : context.appCardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: _relationshipCtrl.text == s
                        ? AppTheme.accent : context.appCardBg),
              ),
              child: Text(s, style: TextStyle(
                color: _relationshipCtrl.text == s
                    ? AppTheme.accent : context.appTextSecondary,
                fontSize: 12,
              )),
            ),
          )).toList(),
        ),
        if (_err != null) ...[const SizedBox(height: 10), _ErrMsg(_err!)],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _busy ? null : _save,
            style: AppTheme.confirmButtonStyle(background: AppTheme.accent),
            child: _busy
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : Text(AppLocalizations.of(context).saveChanges),
          ),
        ),
      ]),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

class _FieldWidget extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final IconData icon;
  final TextInputType? keyboard;
  final List<TextInputFormatter>? inputFormatters;
  const _FieldWidget({required this.ctrl, required this.hint,
      required this.icon, this.keyboard, this.inputFormatters});
  @override
  Widget build(BuildContext context) => TextField(
    controller: ctrl,
    keyboardType: keyboard,
    inputFormatters: inputFormatters,
    style: TextStyle(color: context.appTextPrimary),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: context.appTextSecondary, fontSize: 14),
      prefixIcon: Icon(icon, color: context.appTextSecondary, size: 18),
      filled: true,
      fillColor: context.appCardBg,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.accent, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
  );
}

class _ErrMsg extends StatelessWidget {
  final String msg;
  const _ErrMsg(this.msg);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
        color: AppTheme.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8)),
    child: Row(children: [
      const Icon(Icons.error_outline, color: AppTheme.danger, size: 14),
      const SizedBox(width: 6),
      Expanded(child: Text(msg,
          style: const TextStyle(color: AppTheme.danger, fontSize: 12))),
    ]),
  );
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.error_outline, color: AppTheme.danger, size: 48),
        SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center,
            style: TextStyle(color: context.appTextSecondary)),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(AppLocalizations.of(context).retry),
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent,
              foregroundColor: Colors.white),
        ),
      ]),
    ),
  );
}
