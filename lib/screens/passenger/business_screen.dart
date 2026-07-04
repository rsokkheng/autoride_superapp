import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class BusinessScreen extends StatefulWidget {
  const BusinessScreen({super.key});
  @override
  State<BusinessScreen> createState() => _BusinessScreenState();
}

class _BusinessScreenState extends State<BusinessScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  Map<String, dynamic>? _account;
  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _trips   = [];

  bool _loading      = true;
  bool _membersLoaded = false;
  bool _tripsLoaded   = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _tab.addListener(() {
      if (!_tab.indexIsChanging) {
        if (_tab.index == 1 && !_membersLoaded) _loadMembers();
        if (_tab.index == 2 && !_tripsLoaded)   _loadTrips();
      }
    });
    _loadAccount();
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  Future<void> _loadAccount() async {
    setState(() { _loading = true; _error = null; });
    try {
      _account = await ApiService.getBusinessAccount();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadMembers() async {
    try {
      final list = await ApiService.getBusinessMembers();
      if (mounted) setState(() { _members = list; _membersLoaded = true; });
    } catch (_) {}
  }

  Future<void> _loadTrips() async {
    try {
      final list = await ApiService.getBusinessTrips();
      if (mounted) setState(() { _trips = list; _tripsLoaded = true; });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        title: Text('Business Account'),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: AppTheme.accent,
          labelColor: AppTheme.accent,
          unselectedLabelColor: context.appTextSecondary,
          tabs: const [
            Tab(text: 'Account'),
            Tab(text: 'Members'),
            Tab(text: 'Trips'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : _error != null
              ? _ErrorState(message: _error!, onRetry: _loadAccount)
              : TabBarView(
                  controller: _tab,
                  children: [
                    _AccountTab(
                      account: _account,
                      onAccountChanged: (acc) => setState(() => _account = acc),
                    ),
                    _MembersTab(
                      members:  _members,
                      isAdmin:  _isAdmin,
                      onReload: _loadMembers,
                    ),
                    _TripsTab(
                      trips:    _trips,
                      onReload: _loadTrips,
                    ),
                  ],
                ),
    );
  }

  bool get _isAdmin {
    // The account response typically includes the current user's role
    final role = _account?['my_role'] as String? ?? _account?['role'] as String? ?? '';
    return role == 'admin' || role == 'owner';
  }
}

// ── Account Tab ───────────────────────────────────────────────────────────────

class _AccountTab extends StatefulWidget {
  final Map<String, dynamic>? account;
  final ValueChanged<Map<String, dynamic>> onAccountChanged;
  const _AccountTab({required this.account, required this.onAccountChanged});
  @override
  State<_AccountTab> createState() => _AccountTabState();
}

class _AccountTabState extends State<_AccountTab> {
  bool _showRegister = false;
  bool _showJoin     = false;

  @override
  Widget build(BuildContext context) {
    if (widget.account == null) {
      return _NoAccountView(
        onRegister: () => setState(() { _showRegister = true; _showJoin = false; }),
        onJoin:     () => setState(() { _showJoin = true; _showRegister = false; }),
        showRegister: _showRegister,
        showJoin:     _showJoin,
        onAccountCreated: (acc) {
          widget.onAccountChanged(acc);
          setState(() { _showRegister = false; _showJoin = false; });
        },
      );
    }
    return _AccountDetail(
      account: widget.account!,
      onUpdated: widget.onAccountChanged,
    );
  }
}

class _NoAccountView extends StatefulWidget {
  final VoidCallback onRegister;
  final VoidCallback onJoin;
  final bool         showRegister;
  final bool         showJoin;
  final ValueChanged<Map<String, dynamic>> onAccountCreated;
  const _NoAccountView({
    required this.onRegister, required this.onJoin,
    required this.showRegister, required this.showJoin,
    required this.onAccountCreated,
  });
  @override
  State<_NoAccountView> createState() => _NoAccountViewState();
}

class _NoAccountViewState extends State<_NoAccountView> {
  final _nameCtrl     = TextEditingController();
  final _taxCtrl      = TextEditingController();
  final _industryCtrl = TextEditingController();
  final _contactCtrl  = TextEditingController();
  final _phoneCtrl    = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _addressCtrl  = TextEditingController();
  String  _billingCycle = 'monthly';
  final _codeCtrl  = TextEditingController();
  bool    _busy    = false;
  String? _err;

  @override
  void dispose() {
    _nameCtrl.dispose(); _taxCtrl.dispose(); _industryCtrl.dispose();
    _contactCtrl.dispose(); _phoneCtrl.dispose(); _emailCtrl.dispose();
    _addressCtrl.dispose(); _codeCtrl.dispose();
    super.dispose();
  }

  void _fillSample() => setState(() {
    _nameCtrl.text     = 'Acme Corp';
    _taxCtrl.text      = 'K001234567';
    _industryCtrl.text = 'Technology';
    _contactCtrl.text  = 'Dara Sok';
    _phoneCtrl.text    = '0123456789';
    _emailCtrl.text    = 'finance@acme.com';
    _addressCtrl.text  = 'Phnom Penh, Cambodia';
    _billingCycle      = 'monthly';
  });

  Future<void> _register() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() { _busy = true; _err = null; });
    try {
      final acc = await ApiService.registerBusiness({
        'name':          _nameCtrl.text.trim(),
        'tax_id':        _taxCtrl.text.trim(),
        'industry':      _industryCtrl.text.trim(),
        'contact_name':  _contactCtrl.text.trim(),
        'contact_phone': _phoneCtrl.text.trim(),
        'billing_email': _emailCtrl.text.trim(),
        'billing_cycle': _billingCycle,
        'address':       _addressCtrl.text.trim(),
      });
      final inviteCode = acc['code'] as String?;
      if (mounted && inviteCode != null) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => _InviteCodeDialog(code: inviteCode),
        );
      }
      widget.onAccountCreated(acc);
    } on ApiException catch (e) {
      setState(() { _err = e.message; _busy = false; });
    } catch (e) {
      setState(() { _err = e.toString().replaceFirst('Exception: ', ''); _busy = false; });
    }
  }

  Future<void> _join() async {
    if (_codeCtrl.text.trim().isEmpty) return;
    setState(() { _busy = true; _err = null; });
    try {
      await ApiService.joinBusiness(_codeCtrl.text.trim().toUpperCase());
      // Reload account after joining
      final acc = await ApiService.getBusinessAccount();
      if (acc != null) widget.onAccountCreated(acc);
    } on ApiException catch (e) {
      setState(() { _err = e.message; _busy = false; });
    } catch (e) {
      setState(() { _err = e.toString().replaceFirst('Exception: ', ''); _busy = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showRegister && !widget.showJoin) {
      return Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: SizedBox(
                width: 80, height: 80,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                      color: Color(0x1A00B14F), shape: BoxShape.circle),
                  child: Icon(Icons.business_rounded,
                      color: AppTheme.accent, size: 40),
                ),
              ),
            ),
            SizedBox(height: 20),
            Text('No Business Account',
                textAlign: TextAlign.center,
                style: TextStyle(color: context.appTextPrimary, fontSize: 20,
                    fontWeight: FontWeight.w700)),
            SizedBox(height: 8),
            Text('Register your company or join an existing business account.',
                textAlign: TextAlign.center,
                style: TextStyle(color: context.appTextSecondary, height: 1.5)),
            const SizedBox(height: 32),
            _BigBtn(
              label: 'Register a Business',
              icon: Icons.add_business_rounded,
              onTap: widget.onRegister,
            ),
            const SizedBox(height: 12),
            _BigBtn(
              label: 'Join with Invite Code',
              icon: Icons.qr_code_rounded,
              outlined: true,
              onTap: widget.onJoin,
            ),
          ]),
      );
    }

    if (widget.showJoin) {
      return SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _SectionLabel('Join Business Account'),
          SizedBox(height: 4),
          Text('Enter the invite code your company admin shared with you.',
              style: TextStyle(color: context.appTextSecondary, fontSize: 13)),
          const SizedBox(height: 20),
          _Field(ctrl: _codeCtrl, hint: 'Invite code (e.g. ABC12345)',
              icon: Icons.key_rounded, inputFormatters: [_UpperCase()]),
          if (_err != null) ...[const SizedBox(height: 10), _ErrMsg(_err!)],
          const SizedBox(height: 20),
          _SubmitBtn(label: 'Join Business', busy: _busy, onTap: _join),
        ]),
      );
    }

    // Register form
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const _SectionLabel('Register Business'),
          const Spacer(),
          TextButton(
            onPressed: _fillSample,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              foregroundColor: AppTheme.accent,
            ),
            child: const Text('Fill sample data',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 12),
        _Field(ctrl: _nameCtrl,     hint: 'Company name *',       icon: Icons.business_rounded),
        const SizedBox(height: 10),
        _Field(ctrl: _taxCtrl,      hint: 'Tax ID / VAT number',  icon: Icons.receipt_long_outlined),
        const SizedBox(height: 10),
        _Field(ctrl: _industryCtrl, hint: 'Industry',             icon: Icons.category_outlined),
        const SizedBox(height: 16),
        const _SectionLabel('Contact Person'),
        const SizedBox(height: 10),
        _Field(ctrl: _contactCtrl, hint: 'Contact name *',  icon: Icons.person_outline_rounded),
        const SizedBox(height: 10),
        _Field(ctrl: _phoneCtrl,   hint: 'Contact phone',   icon: Icons.phone_outlined,
            keyboard: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
        const SizedBox(height: 10),
        _Field(ctrl: _emailCtrl,   hint: 'Billing email *', icon: Icons.email_outlined,
            keyboard: TextInputType.emailAddress),
        const SizedBox(height: 16),
        const _SectionLabel('Billing Cycle'),
        const SizedBox(height: 10),
        Row(children: ['weekly', 'monthly'].map((c) {
          final sel = _billingCycle == c;
          return Expanded(child: Padding(
            padding: EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _billingCycle = c),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 150),
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: sel ? AppTheme.accent.withValues(alpha: 0.12) : context.appSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: sel ? AppTheme.accent : context.appCardBg,
                      width: sel ? 1.5 : 1),
                ),
                child: Text(c[0].toUpperCase() + c.substring(1),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: sel ? AppTheme.accent : context.appTextSecondary,
                      fontWeight: FontWeight.w600,
                    )),
              ),
            ),
          ));
        }).toList()),
        const SizedBox(height: 10),
        _Field(ctrl: _addressCtrl, hint: 'Company address', icon: Icons.location_on_outlined),
        if (_err != null) ...[const SizedBox(height: 10), _ErrMsg(_err!)],
        const SizedBox(height: 20),
        _SubmitBtn(label: 'Register Business', busy: _busy, onTap: _register),
        const SizedBox(height: 8),
      ]),
    );
  }
}

class _AccountDetail extends StatefulWidget {
  final Map<String, dynamic> account;
  final ValueChanged<Map<String, dynamic>> onUpdated;
  const _AccountDetail({required this.account, required this.onUpdated});
  @override
  State<_AccountDetail> createState() => _AccountDetailState();
}

class _AccountDetailState extends State<_AccountDetail> {
  bool    _editing = false;
  bool    _busy    = false;
  String? _err;

  late final _nameCtrl     = TextEditingController(text: widget.account['name']          as String? ?? '');
  late final _taxCtrl      = TextEditingController(text: widget.account['tax_id']         as String? ?? '');
  late final _emailCtrl    = TextEditingController(text: widget.account['billing_email']   as String? ?? '');
  late final _contactCtrl  = TextEditingController(text: widget.account['contact_name']   as String? ?? '');
  late final _phoneCtrl    = TextEditingController(text: widget.account['contact_phone']  as String? ?? '');
  late final _industryCtrl = TextEditingController(text: widget.account['industry']       as String? ?? '');
  late final _addressCtrl  = TextEditingController(text: widget.account['address']        as String? ?? '');
  late String _billingCycle = widget.account['billing_cycle'] as String? ?? 'monthly';

  @override
  void dispose() {
    _nameCtrl.dispose(); _taxCtrl.dispose(); _emailCtrl.dispose(); _contactCtrl.dispose();
    _phoneCtrl.dispose(); _industryCtrl.dispose(); _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() { _busy = true; _err = null; });
    try {
      final updated = await ApiService.updateBusinessAccount({
        'name':          _nameCtrl.text.trim(),
        'tax_id':        _taxCtrl.text.trim(),
        'industry':      _industryCtrl.text.trim(),
        'contact_name':  _contactCtrl.text.trim(),
        'contact_phone': _phoneCtrl.text.trim(),
        'billing_email': _emailCtrl.text.trim(),
        'billing_cycle': _billingCycle,
        'address':       _addressCtrl.text.trim(),
      });
      widget.onUpdated(updated);
      setState(() { _editing = false; _busy = false; });
    } on ApiException catch (e) {
      setState(() { _err = e.message; _busy = false; });
    } catch (e) {
      setState(() { _err = e.toString().replaceFirst('Exception: ', ''); _busy = false; });
    }
  }

  Future<void> _leave() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.appSurface,
        title: Text('Leave Business?', style: TextStyle(color: context.appTextPrimary)),
        content: Text('You will no longer have access to business features.',
            style: TextStyle(color: context.appTextSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: TextStyle(color: context.appTextSecondary))),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Leave', style: TextStyle(color: AppTheme.danger))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ApiService.leaveBusiness();
      if (mounted) Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.message), backgroundColor: AppTheme.danger));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final acc = widget.account;
    if (!_editing) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _InfoCard(
            title: acc['name'] as String? ?? '—',
            subtitle: acc['industry'] as String? ?? '',
            icon: Icons.business_rounded,
            color: AppTheme.accent,
          ),
          const SizedBox(height: 16),
          _DetailCard(children: [
            _DetailRow(label: 'Tax ID',        value: acc['tax_id']        as String? ?? '—'),
            _DetailRow(label: 'Billing Email', value: acc['billing_email'] as String? ?? '—'),
            _DetailRow(label: 'Billing Cycle', value: acc['billing_cycle'] as String? ?? '—'),
            _DetailRow(label: 'Contact',       value: acc['contact_name']  as String? ?? '—'),
            _DetailRow(label: 'Phone',         value: acc['contact_phone'] as String? ?? '—'),
            _DetailRow(label: 'Address',       value: acc['address']       as String? ?? '—'),
            if (acc['code'] != null)
              _DetailRow(label: 'Invite Code', value: acc['code'] as String, isBold: true),
          ]),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _BigBtn(
                label: 'Edit Account', icon: Icons.edit_rounded,
                onTap: () => setState(() => _editing = true))),
            const SizedBox(width: 10),
            Expanded(child: _BigBtn(
                label: 'Leave', icon: Icons.exit_to_app_rounded,
                outlined: true, danger: true, onTap: _leave)),
          ]),
        ]),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _SectionLabel('Edit Business Account'),
        const SizedBox(height: 16),
        _Field(ctrl: _nameCtrl,     hint: 'Company name',    icon: Icons.business_rounded),
        const SizedBox(height: 10),
        _Field(ctrl: _taxCtrl,      hint: 'Tax ID / VAT number', icon: Icons.receipt_long_outlined),
        const SizedBox(height: 10),
        _Field(ctrl: _emailCtrl,    hint: 'Billing email',   icon: Icons.email_outlined,
            keyboard: TextInputType.emailAddress),
        const SizedBox(height: 10),
        _Field(ctrl: _contactCtrl,  hint: 'Contact name',    icon: Icons.person_outline_rounded),
        const SizedBox(height: 10),
        _Field(ctrl: _phoneCtrl,    hint: 'Contact phone',   icon: Icons.phone_outlined,
            keyboard: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
        const SizedBox(height: 10),
        _Field(ctrl: _industryCtrl, hint: 'Industry',        icon: Icons.category_outlined),
        const SizedBox(height: 10),
        _Field(ctrl: _addressCtrl,  hint: 'Address',         icon: Icons.location_on_outlined),
        const SizedBox(height: 16),
        const _SectionLabel('Billing Cycle'),
        const SizedBox(height: 10),
        Row(children: ['weekly', 'monthly'].map((c) {
          final sel = _billingCycle == c;
          return Expanded(child: Padding(
            padding: EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _billingCycle = c),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 150),
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: sel ? AppTheme.accent.withValues(alpha: 0.12) : context.appSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: sel ? AppTheme.accent : context.appCardBg,
                      width: sel ? 1.5 : 1),
                ),
                child: Text(c[0].toUpperCase() + c.substring(1),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: sel ? AppTheme.accent : context.appTextSecondary,
                      fontWeight: FontWeight.w600,
                    )),
              ),
            ),
          ));
        }).toList()),
        if (_err != null) ...[SizedBox(height: 10), _ErrMsg(_err!)],
        SizedBox(height: 20),
        Row(children: [
          Expanded(child: OutlinedButton(
            onPressed: () => setState(() => _editing = false),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: context.appCardBg),
              padding: EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Cancel', style: TextStyle(color: context.appTextSecondary)),
          )),
          const SizedBox(width: 10),
          Expanded(child: _SubmitBtn(label: 'Save', busy: _busy, onTap: _save)),
        ]),
      ]),
    );
  }
}

// ── Members Tab ───────────────────────────────────────────────────────────────

class _MembersTab extends StatefulWidget {
  final List<Map<String, dynamic>> members;
  final bool      isAdmin;
  final VoidCallback onReload;
  const _MembersTab({required this.members, required this.isAdmin, required this.onReload});
  @override
  State<_MembersTab> createState() => _MembersTabState();
}

class _MembersTabState extends State<_MembersTab> {
  Future<void> _editMember(Map<String, dynamic> m) async {
    final roleCtrl  = TextEditingController(text: m['role'] as String? ?? '');
    final deptCtrl  = TextEditingController(text: m['department'] as String? ?? '');
    final ccCtrl    = TextEditingController(text: m['cost_center'] as String? ?? '');
    final empCtrl   = TextEditingController(text: m['employee_id'] as String? ?? '');
    final limitCtrl = TextEditingController(
        text: m['monthly_limit_khr'] != null ? '${m['monthly_limit_khr']}' : '');
    bool   active = m['active'] as bool? ?? true;
    bool   busy   = false;
    String? err;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.appSurface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20,
              20 + MediaQuery.of(ctx).viewInsets.bottom),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Edit ${m['name'] ?? 'Member'}',
                style: TextStyle(color: context.appTextPrimary,
                    fontSize: 17, fontWeight: FontWeight.w700)),
            SizedBox(height: 16),
            _Field(ctrl: roleCtrl,  hint: 'Role (member / admin)', icon: Icons.shield_outlined),
            SizedBox(height: 10),
            _Field(ctrl: deptCtrl,  hint: 'Department',            icon: Icons.corporate_fare_rounded),
            SizedBox(height: 10),
            _Field(ctrl: ccCtrl,    hint: 'Cost center',           icon: Icons.account_tree_outlined),
            SizedBox(height: 10),
            _Field(ctrl: empCtrl,   hint: 'Employee ID',           icon: Icons.badge_outlined),
            SizedBox(height: 10),
            _Field(ctrl: limitCtrl, hint: 'Monthly limit (KHR)',   icon: Icons.wallet_outlined,
                keyboard: TextInputType.number),
            SizedBox(height: 12),
            Row(children: [
              Text('Active', style: TextStyle(color: context.appTextPrimary)),
              const Spacer(),
              Switch(
                value: active,
                onChanged: (v) => setS(() => active = v),
                activeColor: AppTheme.accent,
              ),
            ]),
            if (err != null) ...[const SizedBox(height: 8), _ErrMsg(err!)],
            const SizedBox(height: 16),
            _SubmitBtn(
              label: 'Save Changes',
              busy: busy,
              onTap: () async {
                setS(() { busy = true; err = null; });
                try {
                  await ApiService.updateBusinessMember(m['id'] as int, {
                    'role':               roleCtrl.text.trim(),
                    'department':         deptCtrl.text.trim(),
                    'cost_center':        ccCtrl.text.trim(),
                    'employee_id':        empCtrl.text.trim(),
                    if (limitCtrl.text.isNotEmpty)
                      'monthly_limit_khr': int.tryParse(limitCtrl.text) ?? 0,
                    'active': active,
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  widget.onReload();
                } on ApiException catch (e) {
                  setS(() { err = e.message; busy = false; });
                }
              },
            ),
          ]),
        );
      }),
    );
  }

  Future<void> _removeMember(Map<String, dynamic> m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.appSurface,
        title: Text('Remove Member?', style: TextStyle(color: context.appTextPrimary)),
        content: Text('Remove ${m['name'] ?? 'this member'} from the business account?',
            style: TextStyle(color: context.appTextSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: TextStyle(color: context.appTextSecondary))),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove', style: TextStyle(color: AppTheme.danger))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ApiService.removeBusinessMember(m['id'] as int);
      widget.onReload();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppTheme.danger));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.members.isEmpty) {
      return Center(child: Text('No members yet.',
          style: TextStyle(color: context.appTextSecondary)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: widget.members.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final m = widget.members[i];
        final role = m['role'] as String? ?? 'member';
        return Container(
          padding: EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: context.appSurface, borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            CircleAvatar(
              backgroundColor: AppTheme.accent.withValues(alpha: 0.12),
              child: Text((m['name'] as String? ?? '?')[0].toUpperCase(),
                  style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w700)),
            ),
            SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(m['name'] as String? ?? '—',
                  style: TextStyle(color: context.appTextPrimary,
                      fontWeight: FontWeight.w600, fontSize: 14)),
              Text(m['department'] as String? ?? role,
                  style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
            ])),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: role == 'admin'
                    ? AppTheme.accent.withValues(alpha: 0.12)
                    : context.appCardBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(role,
                  style: TextStyle(
                    color: role == 'admin' ? AppTheme.accent : context.appTextSecondary,
                    fontSize: 11, fontWeight: FontWeight.w600,
                  )),
            ),
            if (widget.isAdmin) ...[
              SizedBox(width: 6),
              IconButton(
                icon: Icon(Icons.edit_rounded, size: 18, color: context.appTextSecondary),
                onPressed: () => _editMember(m),
              ),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline_rounded,
                    size: 18, color: AppTheme.danger),
                onPressed: () => _removeMember(m),
              ),
            ],
          ]),
        );
      },
    );
  }
}

// ── Trips Tab ─────────────────────────────────────────────────────────────────

class _TripsTab extends StatefulWidget {
  final List<Map<String, dynamic>> trips;
  final VoidCallback onReload;
  const _TripsTab({required this.trips, required this.onReload});
  @override
  State<_TripsTab> createState() => _TripsTabState();
}

class _TripsTabState extends State<_TripsTab> {
  @override
  Widget build(BuildContext context) {
    if (widget.trips.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.receipt_long_outlined, color: context.appTextSecondary, size: 48),
        SizedBox(height: 12),
        Text('No business trips yet.',
            style: TextStyle(color: context.appTextSecondary)),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: widget.onReload,
          icon: const Icon(Icons.refresh_rounded, color: AppTheme.accent),
          label: const Text('Refresh', style: TextStyle(color: AppTheme.accent)),
        ),
      ]));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: widget.trips.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final t = widget.trips[i];
        final fare = t['fare_khr'] != null ? AppTheme.khr(t['fare_khr'] as int) : '—';
        return Container(
          padding: EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: context.appSurface, borderRadius: BorderRadius.circular(14)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.directions_car_outlined, color: AppTheme.accent, size: 16),
              SizedBox(width: 6),
              Expanded(child: Text(t['expense_category'] as String? ?? 'Business Trip',
                  style: TextStyle(color: context.appTextPrimary,
                      fontWeight: FontWeight.w600, fontSize: 14))),
              Text(fare, style: TextStyle(color: context.appTextPrimary,
                  fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 6),
            Text('${t['pickup_address'] ?? '—'} → ${t['dropoff_address'] ?? '—'}',
                style: TextStyle(color: context.appTextSecondary, fontSize: 12),
                overflow: TextOverflow.ellipsis),
            if (t['expense_ref'] != null) ...[
              const SizedBox(height: 4),
              Text('Ref: ${t['expense_ref']}',
                  style: TextStyle(color: context.appTextSecondary, fontSize: 11)),
            ],
          ]),
        );
      },
    );
  }
}

// ── Shared small widgets ──────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});
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
          label: const Text('Retry'),
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
        ),
      ]),
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: TextStyle(color: context.appTextPrimary,
          fontSize: 14, fontWeight: FontWeight.w700));
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final IconData icon;
  final TextInputType? keyboard;
  final List<TextInputFormatter>? inputFormatters;
  const _Field({required this.ctrl, required this.hint, required this.icon,
      this.keyboard, this.inputFormatters});
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

class _SubmitBtn extends StatelessWidget {
  final String label;
  final bool   busy;
  final VoidCallback onTap;
  const _SubmitBtn({required this.label, required this.busy, required this.onTap});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: busy ? null : onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.accent,
        disabledBackgroundColor: AppTheme.accent.withValues(alpha: 0.4),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: busy
          ? const SizedBox(width: 20, height: 20,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
          : Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    ),
  );
}

class _BigBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool   outlined;
  final bool   danger;
  final VoidCallback onTap;
  const _BigBtn({required this.label, required this.icon, required this.onTap,
      this.outlined = false, this.danger = false});
  @override
  Widget build(BuildContext context) {
    final color = danger ? AppTheme.danger : AppTheme.accent;
    const size  = Size(double.infinity, 50);
    if (outlined) {
      return OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18, color: color),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          minimumSize: size,
          side: BorderSide(color: color.withValues(alpha: 0.4)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: size,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    );
  }
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

class _InfoCard extends StatelessWidget {
  final String  title;
  final String  subtitle;
  final IconData icon;
  final Color   color;
  const _InfoCard({required this.title, required this.subtitle,
      required this.icon, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [color.withValues(alpha: 0.8), color],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(children: [
      Icon(icon, color: Colors.white, size: 36),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: Colors.white,
            fontSize: 18, fontWeight: FontWeight.w800)),
        if (subtitle.isNotEmpty)
          Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13)),
      ])),
    ]),
  );
}

class _DetailCard extends StatelessWidget {
  final List<Widget> children;
  const _DetailCard({required this.children});
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(color: context.appSurface,
        borderRadius: BorderRadius.circular(14)),
    child: Column(children: children),
  );
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool   isBold;
  const _DetailRow({required this.label, required this.value, this.isBold = false});
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      SizedBox(width: 110,
          child: Text(label, style: TextStyle(
              color: context.appTextSecondary, fontSize: 13))),
      Expanded(child: Text(value, style: TextStyle(
          color: context.appTextPrimary, fontSize: 13,
          fontWeight: isBold ? FontWeight.w700 : FontWeight.w400))),
    ]),
  );
}

class _InviteCodeDialog extends StatelessWidget {
  final String code;
  const _InviteCodeDialog({required this.code});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.appSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: EdgeInsets.fromLTRB(24, 24, 24, 16),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.12),
              shape: BoxShape.circle),
          child: Icon(Icons.check_rounded, color: AppTheme.accent, size: 36),
        ),
        SizedBox(height: 16),
        Text('Business Registered!',
            style: TextStyle(color: context.appTextPrimary, fontSize: 18,
                fontWeight: FontWeight.w800)),
        SizedBox(height: 8),
        Text('Share this invite code with your employees so they can join.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.appTextSecondary, fontSize: 13, height: 1.4)),
        const SizedBox(height: 20),
        // Invite code box
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppTheme.accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
          ),
          child: Text(code,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.accent,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 6,
              )),
        ),
        const SizedBox(height: 12),
        // Copy button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Invite code copied!'),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: Icon(Icons.copy_rounded, size: 16),
            label: Text('Copy Code'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.accent,
              side: BorderSide(color: AppTheme.accent.withValues(alpha: 0.4)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Done', style: TextStyle(color: context.appTextSecondary)),
        ),
      ]),
    );
  }
}

class _UpperCase extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue o, TextEditingValue v) =>
      v.copyWith(text: v.text.toUpperCase(), selection: v.selection);
}
