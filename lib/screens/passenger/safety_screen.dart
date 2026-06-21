import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:autoride_superapp/theme/app_theme.dart';
import 'package:autoride_superapp/widgets/common_widgets.dart';
import '../../services/api_service.dart';

// ── Tokens ──────────────────────────────────────────────────────────────────
const _green  = Color(0xFF00C48C);
const _red    = AppTheme.danger;
const _white  = Colors.white;
const _bg     = AppTheme.primary;

// ══════════════════════════════════════════════════════════════════════════════
class SafetyScreen extends StatefulWidget {
  final int? activeRideId;
  const SafetyScreen({super.key, this.activeRideId});

  @override
  State<SafetyScreen> createState() => _SafetyScreenState();
}

class _SafetyScreenState extends State<SafetyScreen> {
  List<EmergencyContactModel> _contacts = [];
  bool    _contactsLoading = true;
  bool    _sosLoading      = false;
  bool    _fakeCallLoading = false;
  bool    _sharing         = false;
  String? _shareUrl;

  @override
  void initState() { super.initState(); _loadContacts(); }

  Future<void> _loadContacts() async {
    setState(() => _contactsLoading = true);
    try {
      final c = await ApiService.getEmergencyContacts();
      if (mounted) setState(() { _contacts = c; _contactsLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _contactsLoading = false);
    }
  }

  // ── SOS ──────────────────────────────────────────────────────────────────
  Future<void> _sendSos() async {
    final rideId = widget.activeRideId;
    setState(() => _sosLoading = true);
    try {
      if (rideId != null) {
        final r = await ApiService.sendSos(rideId);
        if (!mounted) return;
        _snack('🆘 SOS sent to ${r.contactsNotified} contact(s)', _red);
      } else {
        await ApiService.sendSosAlert(rideId: 0, message: 'Emergency SOS');
        if (!mounted) return;
        _snack('🆘 SOS alert sent', _red);
      }
    } on ApiException catch (e) {
      if (mounted) _snack(e.message, _red);
    } catch (e) {
      if (mounted) _snack(e.toString(), _red);
    }
    if (mounted) setState(() => _sosLoading = false);
  }

  // ── Fake call ─────────────────────────────────────────────────────────────
  Future<void> _triggerFakeCall(int delay) async {
    setState(() => _fakeCallLoading = true);
    try {
      final r = await ApiService.triggerFakeCall(delaySeconds: delay);
      if (!mounted) return;
      Navigator.pop(context); // close delay picker
      _showFakeCallDialog(r);
    } on ApiException catch (e) {
      if (mounted) _snack(e.message, _red);
    } catch (e) {
      if (mounted) _snack(e.toString(), _red);
    }
    if (mounted) setState(() => _fakeCallLoading = false);
  }

  // ── Share trip ────────────────────────────────────────────────────────────
  Future<void> _shareTrip() async {
    final rideId = widget.activeRideId;
    if (rideId == null) { _snack('No active ride to share', Colors.orange); return; }
    setState(() => _sharing = true);
    try {
      final r = await ApiService.shareTrip(rideId);
      if (!mounted) return;
      setState(() { _shareUrl = r.shareUrl; _sharing = false; });
      _showShareDialog(r.shareUrl);
    } on ApiException catch (e) {
      if (mounted) { setState(() => _sharing = false); _snack(e.message, _red); }
    } catch (e) {
      if (mounted) { setState(() => _sharing = false); _snack(e.toString(), _red); }
    }
  }

  Future<void> _stopSharing() async {
    final rideId = widget.activeRideId;
    if (rideId == null) return;
    try {
      await ApiService.stopSharingTrip(rideId);
      if (mounted) { setState(() => _shareUrl = null); _snack('Sharing stopped', _green); }
    } on ApiException catch (e) {
      if (mounted) _snack(e.message, _red);
    }
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────
  void _showFakeCallDialog(FakeCallResult r) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _FakeCallOverlay(result: r),
    );
  }

  void _showFakeCallPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.appSurface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _FakeCallPicker(
        loading: _fakeCallLoading,
        onPick: (d) => _triggerFakeCall(d),
      ),
    );
  }

  void _showShareDialog(String url) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.appSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Trip Link Shared', style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(10)),
            child: Text(url, style: TextStyle(color: context.appTextPrimary, fontSize: 12)),
          ),
          SizedBox(height: 12),
          Text('Share this link so others can track your trip in real time.',
              style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: Text('Close', style: TextStyle(color: context.appTextSecondary))),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: url));
              Navigator.pop(ctx);
              _snack('Link copied!', _green);
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copy Link'),
            style: ElevatedButton.styleFrom(
                backgroundColor: _green, foregroundColor: _white, elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          ),
        ],
      ),
    );
  }

  void _showSosConfirm() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.appSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🆘 Send SOS?', style: TextStyle(color: _red, fontWeight: FontWeight.w800)),
        content: Text(
          _contacts.isEmpty
              ? 'An SOS alert will be sent immediately. No emergency contacts added yet.'
              : 'SOS will be sent to ${_contacts.length} emergency contact(s) immediately.',
          style: TextStyle(color: context.appTextSecondary, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: context.appTextSecondary))),
          ElevatedButton(
            onPressed: () { Navigator.pop(ctx); _sendSos(); },
            style: ElevatedButton.styleFrom(backgroundColor: _red,
                foregroundColor: _white, elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Send SOS', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _showReportIncident() {
    final descCtrl = TextEditingController();
    String type = 'harassment';
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: context.appSurface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setLocal) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20,
            MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Report Incident',
              style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w800, fontSize: 16)),
          SizedBox(height: 16),
          Wrap(spacing: 8, children: [
            for (final t in [
              ('harassment', 'Harassment'),
              ('unsafe_driving', 'Unsafe Driving'),
              ('overcharge', 'Overcharge'),
              ('other', 'Other'),
            ])
              GestureDetector(
                onTap: () => setLocal(() => type = t.$1),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 150),
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: type == t.$1 ? _red : context.appCardBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(t.$2, style: TextStyle(
                      color: type == t.$1 ? _white : context.appTextSecondary,
                      fontWeight: FontWeight.w600, fontSize: 12)),
                ),
              ),
          ]),
          SizedBox(height: 14),
          TextField(
            controller: descCtrl, maxLines: 3,
            style: TextStyle(color: context.appTextPrimary, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Describe what happened…',
              hintStyle: TextStyle(color: context.appTextSecondary),
              filled: true, fillColor: context.appCardBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final desc = descCtrl.text.trim();
                if (desc.isEmpty) return;
                Navigator.pop(ctx);
                try {
                  await ApiService.reportSafetyIncident(
                      type: type, description: desc,
                      rideId: widget.activeRideId);
                  if (mounted) _snack('Incident reported. Thank you.', _green);
                } on ApiException catch (e) {
                  if (mounted) _snack(e.message, _red);
                } catch (e) {
                  if (mounted) _snack(e.toString(), _red);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: _red,
                  foregroundColor: _white, elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Submit Report',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ]),
      )),
    );
  }

  void _showAddContact() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final relCtrl  = TextEditingController();
    bool sos = true, share = true;
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: context.appSurface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setLocal) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20,
            MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Add Emergency Contact',
              style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 16),
          _ModalField(ctrl: nameCtrl, hint: 'Full name', icon: Icons.person_outline),
          const SizedBox(height: 10),
          _ModalField(ctrl: phoneCtrl, hint: 'Phone number', icon: Icons.phone_outlined,
              type: TextInputType.phone),
          const SizedBox(height: 10),
          _ModalField(ctrl: relCtrl, hint: 'Relationship (e.g. Mom)', icon: Icons.people_outline),
          const SizedBox(height: 10),
          _NotifyRow('Notify on SOS', sos, (v) => setLocal(() => sos = v)),
          _NotifyRow('Notify on trip share', share, (v) => setLocal(() => share = v)),
          const SizedBox(height: 14),
          SizedBox(width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final n = nameCtrl.text.trim();
                final p = phoneCtrl.text.trim();
                if (n.isEmpty || p.isEmpty) return;
                Navigator.pop(ctx);
                try {
                  await ApiService.addEmergencyContact(
                    name: n, phone: p,
                    relationship: relCtrl.text.trim().isEmpty ? null : relCtrl.text.trim(),
                    notifyOnSos: sos, notifyOnTripShare: share,
                  );
                  _loadContacts();
                  if (mounted) _snack('Contact added!', _green);
                } on ApiException catch (e) {
                  if (mounted) _snack(e.message, _red);
                } catch (e) {
                  if (mounted) _snack(e.toString(), _red);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: _green,
                  foregroundColor: _white, elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Add Contact',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ]),
      )),
    );
  }

  void _showEditContact(EmergencyContactModel c) {
    final nameCtrl = TextEditingController(text: c.name);
    final phoneCtrl = TextEditingController(text: c.phone);
    bool sos = c.notifyOnSos, share = c.notifyOnTripShare;
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: context.appSurface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setLocal) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20,
            MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Edit Contact',
              style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 16),
          _ModalField(ctrl: nameCtrl, hint: 'Full name', icon: Icons.person_outline),
          const SizedBox(height: 10),
          _ModalField(ctrl: phoneCtrl, hint: 'Phone number', icon: Icons.phone_outlined,
              type: TextInputType.phone),
          const SizedBox(height: 10),
          _NotifyRow('Notify on SOS', sos, (v) => setLocal(() => sos = v)),
          _NotifyRow('Notify on trip share', share, (v) => setLocal(() => share = v)),
          const SizedBox(height: 14),
          SizedBox(width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await ApiService.updateEmergencyContact(c.id,
                    name: nameCtrl.text.trim(), phone: phoneCtrl.text.trim(),
                    notifyOnSos: sos, notifyOnTripShare: share,
                  );
                  _loadContacts();
                  if (mounted) _snack('Contact updated!', _green);
                } on ApiException catch (e) {
                  if (mounted) _snack(e.message, _red);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: _green,
                  foregroundColor: _white, elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Save Changes',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ]),
      )),
    );
  }

  Future<void> _deleteContact(EmergencyContactModel c) async {
    final ok = await showDialog<bool>(context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.appSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Remove contact?',
            style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w700)),
        content: Text('${c.name} will be removed from your emergency contacts.',
            style: TextStyle(color: context.appTextSecondary, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: TextStyle(color: context.appTextSecondary))),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove', style: TextStyle(color: _red, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ApiService.deleteEmergencyContact(c.id);
      _loadContacts();
      if (mounted) _snack('Contact removed', _green);
    } on ApiException catch (e) {
      if (mounted) _snack(e.message, _red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: Colors.black12,
        title: Text('Safety Center',
            style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w800, fontSize: 18)),
      ),
      body: RefreshIndicator(
        onRefresh: _loadContacts, color: _green,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── SOS button ─────────────────────────────────────────────────
            GestureDetector(
              onLongPress: _showSosConfirm,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28),
                decoration: BoxDecoration(
                  color: _red,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(
                      color: _red.withValues(alpha: 0.4),
                      blurRadius: 18, offset: Offset(0, 6))],
                ),
                child: Column(children: [
                  _sosLoading
                      ? SizedBox(width: 56, height: 56,
                          child: CircularProgressIndicator(color: _white, strokeWidth: 3))
                      : Container(
                          width: 72, height: 72,
                          decoration: BoxDecoration(
                              color: _white.withValues(alpha: 0.2),
                              shape: BoxShape.circle),
                          child: Icon(Icons.sos_rounded, color: _white, size: 40)),
                  SizedBox(height: 12),
                  Text('Emergency SOS',
                      style: TextStyle(color: _white, fontSize: 20, fontWeight: FontWeight.w800)),
                  SizedBox(height: 4),
                  Text('Hold for 1 second to activate',
                      style: TextStyle(color: _white.withValues(alpha: 0.8), fontSize: 13)),
                ]),
              ),
            ),
            SizedBox(height: 16),

            // ── Quick actions ───────────────────────────────────────────────
            Row(children: [
              Expanded(child: _ActionCard(
                icon: Icons.phone_callback_rounded,
                label: 'Fake Call',
                color: _green,
                loading: _fakeCallLoading,
                onTap: _showFakeCallPicker,
              )),
              SizedBox(width: 12),
              Expanded(child: _ActionCard(
                icon: _shareUrl != null
                    ? Icons.link_off_rounded : Icons.share_location_rounded,
                label: _shareUrl != null ? 'Stop Sharing' : 'Share Trip',
                color: _shareUrl != null ? Colors.orange : AppTheme.accent,
                loading: _sharing,
                onTap: _shareUrl != null ? _stopSharing : _shareTrip,
              )),
              SizedBox(width: 12),
              Expanded(child: _ActionCard(
                icon: Icons.report_outlined,
                label: 'Report',
                color: AppTheme.warning,
                onTap: _showReportIncident,
              )),
            ]),
            SizedBox(height: 24),

            // ── Emergency contacts ─────────────────────────────────────────
            Row(children: [
              Expanded(child: SectionHeader(title: 'Emergency Contacts')),
              TextButton.icon(
                onPressed: _showAddContact,
                icon: Icon(Icons.person_add_outlined, size: 16, color: _green),
                label: Text('Add', style: TextStyle(color: _green, fontWeight: FontWeight.w700)),
              ),
            ]),
            SizedBox(height: 10),
            if (_contactsLoading)
              Center(child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: _green, strokeWidth: 2),
              ))
            else if (_contacts.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: context.appSurface, borderRadius: BorderRadius.circular(16)),
                child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.people_outline, color: context.appTextSecondary, size: 36),
                    SizedBox(height: 8),
                    Text('No emergency contacts yet',
                        style: TextStyle(color: context.appTextSecondary, fontSize: 13)),
                  ]),
                ),
              )
            else
              ...(_contacts.map((c) => _ContactTile(
                contact: c,
                onEdit: () => _showEditContact(c),
                onDelete: () => _deleteContact(c),
              ))),
            SizedBox(height: 24),

            // ── Safety resources ───────────────────────────────────────────
            SectionHeader(title: 'Safety Resources'),
            SizedBox(height: 12),
            ...[
              ('Emergency: 117 / 119', Icons.phone_in_talk_outlined, _red),
              ('Report Incident',       Icons.report_outlined,         AppTheme.warning),
              ('Safety Guidelines',     Icons.menu_book_outlined,       AppTheme.accent),
            ].map((item) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: context.appSurface, borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                Container(padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: item.$3.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10)),
                    child: Icon(item.$2, color: item.$3, size: 18)),
                SizedBox(width: 12),
                Text(item.$1, style: TextStyle(
                    color: context.appTextPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                Spacer(),
                Icon(Icons.chevron_right, color: context.appTextSecondary, size: 18),
              ]),
            )),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ── Quick action card ──────────────────────────────────────────────────────

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool loading;
  final VoidCallback onTap;
  const _ActionCard({required this.icon, required this.label,
      required this.color, required this.onTap, this.loading = false});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: loading ? null : onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        loading
            ? SizedBox(width: 24, height: 24,
                child: CircularProgressIndicator(color: color, strokeWidth: 2))
            : Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 22)),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(
            color: color, fontWeight: FontWeight.w700, fontSize: 12),
            textAlign: TextAlign.center),
      ]),
    ),
  );
}

// ── Contact tile ───────────────────────────────────────────────────────────

class _ContactTile extends StatelessWidget {
  final EmergencyContactModel contact;
  final VoidCallback onEdit, onDelete;
  const _ContactTile({required this.contact, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final c = contact;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: context.appSurface, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6, offset: Offset(0, 2))]),
      child: Row(children: [
        CircleAvatar(
          backgroundColor: _green.withValues(alpha: 0.12), radius: 22,
          child: Text(c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
              style: TextStyle(color: _green, fontWeight: FontWeight.w800, fontSize: 16)),
        ),
        SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(c.name, style: TextStyle(
              color: context.appTextPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
          SizedBox(height: 2),
          Text(c.phone, style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
          if (c.relationship != null) ...[
            SizedBox(height: 2),
            Text(c.relationship!,
                style: TextStyle(color: context.appTextSecondary, fontSize: 11)),
          ],
          const SizedBox(height: 6),
          Wrap(spacing: 6, children: [
            if (c.notifyOnSos)
              _MiniTag('SOS', _red),
            if (c.notifyOnTripShare)
              _MiniTag('Trip Share', AppTheme.accent),
          ]),
        ])),
        IconButton(icon: const Icon(Icons.edit_outlined, color: _green, size: 18),
            onPressed: onEdit),
        IconButton(icon: const Icon(Icons.delete_outline, color: _red, size: 18),
            onPressed: onDelete),
      ]),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String label;
  final Color color;
  const _MiniTag(this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: TextStyle(
        color: color, fontSize: 10, fontWeight: FontWeight.w700)),
  );
}

// ── Fake call delay picker ─────────────────────────────────────────────────

class _FakeCallPicker extends StatelessWidget {
  final bool loading;
  final void Function(int) onPick;
  const _FakeCallPicker({required this.loading, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final options = [
      (5,  'Now (5 sec)'),
      (10, 'In 10 sec'),
      (30, 'In 30 sec'),
      (60, 'In 1 min'),
    ];
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 30),
      child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Fake Call — Choose Delay',
            style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w800, fontSize: 16)),
        SizedBox(height: 6),
        Text('Your phone will ring after the selected delay.',
            style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
        SizedBox(height: 16),
        if (loading)
          Center(child: CircularProgressIndicator(color: _green))
        else
          ...options.map((o) => GestureDetector(
            onTap: () => onPick(o.$1),
            child: Container(
              width: double.infinity,
              margin: EdgeInsets.only(bottom: 10),
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: context.appCardBg, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Container(padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: _green.withValues(alpha: 0.12), shape: BoxShape.circle),
                    child: Icon(Icons.phone_callback_rounded, color: _green, size: 18)),
                SizedBox(width: 12),
                Text(o.$2, style: TextStyle(
                    color: context.appTextPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                Spacer(),
                Icon(Icons.chevron_right, color: context.appTextSecondary, size: 18),
              ]),
            ),
          )),
      ]),
    );
  }
}

// ── Fake call overlay ──────────────────────────────────────────────────────

class _FakeCallOverlay extends StatefulWidget {
  final FakeCallResult result;
  const _FakeCallOverlay({required this.result});
  @override
  State<_FakeCallOverlay> createState() => _FakeCallOverlayState();
}

class _FakeCallOverlayState extends State<_FakeCallOverlay> {
  late int _remaining;
  Timer? _timer;
  bool _ringing = false;

  @override
  void initState() {
    super.initState();
    _remaining = widget.result.delaySeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remaining <= 1) {
        t.cancel();
        if (mounted) setState(() { _remaining = 0; _ringing = true; });
      } else {
        if (mounted) setState(() => _remaining--);
      }
    });
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _ringing ? _green : context.appTextPrimary,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 64, height: 64,
              decoration: BoxDecoration(
                  color: _white.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: Icon(_ringing ? Icons.phone_in_talk_rounded : Icons.phone_callback_rounded,
                  color: _white, size: 32)),
          const SizedBox(height: 16),
          Text(
            _ringing ? 'Incoming Call…' : 'Fake call in $_remaining s…',
            style: const TextStyle(color: _white, fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(widget.result.callerName,
              style: TextStyle(color: _white.withValues(alpha: 0.9),
                  fontSize: 15, fontWeight: FontWeight.w600)),
          Text(widget.result.callerNumber,
              style: TextStyle(color: _white.withValues(alpha: 0.7), fontSize: 13)),
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(width: 56, height: 56,
                  decoration: const BoxDecoration(color: _red, shape: BoxShape.circle),
                  child: const Icon(Icons.call_end_rounded, color: _white, size: 28)),
            ),
            if (_ringing) ...[
              const SizedBox(width: 40),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(width: 56, height: 56,
                    decoration: BoxDecoration(
                        color: _white.withValues(alpha: 0.2), shape: BoxShape.circle),
                    child: const Icon(Icons.call_rounded, color: _white, size: 28)),
              ),
            ],
          ]),
        ]),
      ),
    );
  }
}

// ── Helper widgets ─────────────────────────────────────────────────────────

class _ModalField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final IconData icon;
  final TextInputType? type;
  const _ModalField({required this.ctrl, required this.hint,
      required this.icon, this.type});
  @override
  Widget build(BuildContext context) => TextField(
    controller: ctrl, keyboardType: type,
    style: TextStyle(color: context.appTextPrimary, fontSize: 14),
    decoration: InputDecoration(
      hintText: hint, hintStyle: TextStyle(color: context.appTextSecondary),
      prefixIcon: Icon(icon, color: context.appTextSecondary, size: 18),
      filled: true, fillColor: context.appCardBg,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
  );
}

class _NotifyRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _NotifyRow(this.label, this.value, this.onChanged);
  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Text(label, style: TextStyle(color: context.appTextPrimary, fontSize: 13))),
    Switch(value: value, onChanged: onChanged,
        activeColor: _green, activeTrackColor: _green.withValues(alpha: 0.4)),
  ]);
}
