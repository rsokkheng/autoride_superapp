import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

const _green = Color(0xFF00C48C);

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<SupportTicketModel> _tickets = [];
  bool    _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await ApiService.getSupportTickets();
      if (mounted) setState(() { _tickets = list; _loading = false; });
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
        backgroundColor: context.appSurface,
        elevation: 0,
        leading: BackButton(color: context.appTextPrimary),
        title: Text('Help & Support',
            style: TextStyle(
                color: context.appTextPrimary, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: _green),
            onPressed: _showNewTicket,
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: _green,
          labelColor: _green,
          unselectedLabelColor: context.appTextSecondary,
          tabs: const [Tab(text: 'My Tickets'), Tab(text: 'FAQ')],
        ),
      ),
      body: TabBarView(controller: _tabs, children: [
        _TicketsTab(
          loading: _loading,
          error: _error,
          tickets: _tickets,
          onRefresh: _load,
          onOpen: _openTicket,
        ),
        const _FaqTab(),
      ]),
    );
  }

  void _showNewTicket() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NewTicketSheet(
        onCreated: (t) => setState(() => _tickets.insert(0, t)),
      ),
    );
  }

  void _openTicket(SupportTicketModel t) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => _TicketDetailScreen(ticket: t),
    ));
  }
}

// ─── Tickets tab ──────────────────────────────────────────────────────────────

class _TicketsTab extends StatelessWidget {
  final bool loading;
  final String? error;
  final List<SupportTicketModel> tickets;
  final Future<void> Function() onRefresh;
  final ValueChanged<SupportTicketModel> onOpen;

  const _TicketsTab({
    required this.loading, required this.error,
    required this.tickets, required this.onRefresh, required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(
        child: CircularProgressIndicator(color: _green));
    if (error != null) return Center(child: Column(
        mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.error_outline, color: AppTheme.danger, size: 48),
      SizedBox(height: 12),
      Text(error!, style: TextStyle(color: context.appTextSecondary),
          textAlign: TextAlign.center),
      const SizedBox(height: 16),
      ElevatedButton(onPressed: onRefresh,
          style: ElevatedButton.styleFrom(
              backgroundColor: _green, foregroundColor: Colors.white,
              elevation: 0),
          child: const Text('Retry')),
    ]));
    if (tickets.isEmpty) return RefreshIndicator(
      onRefresh: onRefresh, color: _green,
      child: ListView(padding: EdgeInsets.all(32), children: [
        Icon(Icons.support_agent_outlined,
            color: context.appTextSecondary, size: 60),
        SizedBox(height: 16),
        Text('No support tickets', textAlign: TextAlign.center,
            style: TextStyle(color: context.appTextPrimary,
                fontSize: 16, fontWeight: FontWeight.w700)),
        SizedBox(height: 6),
        Text('Tap + to create a new support request.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.appTextSecondary, fontSize: 13)),
      ]),
    );

    final open   = tickets.where((t) => t.isOpen).toList();
    final closed = tickets.where((t) => t.isClosed).toList();

    return RefreshIndicator(
      onRefresh: onRefresh, color: _green,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        if (open.isNotEmpty) ...[
          _SectionLabel('Open (${open.length})'),
          ...open.map((t) => _TicketTile(ticket: t, onTap: () => onOpen(t))),
          const SizedBox(height: 8),
        ],
        if (closed.isNotEmpty) ...[
          _SectionLabel('Resolved (${closed.length})'),
          ...closed.map((t) => _TicketTile(ticket: t, onTap: () => onOpen(t))),
        ],
      ]),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: 8),
    child: Text(text, style: TextStyle(
        color: context.appTextSecondary, fontSize: 12,
        fontWeight: FontWeight.w700, letterSpacing: 0.5)),
  );
}

class _TicketTile extends StatelessWidget {
  final SupportTicketModel ticket;
  final VoidCallback onTap;
  const _TicketTile({required this.ticket, required this.onTap});

  Color get _statusColor {
    switch (ticket.status) {
      case 'open':     return _green;
      case 'pending':  return AppTheme.warning;
      case 'resolved':
      case 'closed':   return AppTheme.textSecondary;
      default:         return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(14),
        border: ticket.isOpen
            ? Border.all(color: _green.withValues(alpha: 0.3)) : null,
      ),
      child: Row(children: [
        Container(
          padding: EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: _statusColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.support_agent_outlined,
              color: _statusColor, size: 20),
        ),
        SizedBox(width: 12),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(ticket.subject, style: TextStyle(
              color: context.appTextPrimary,
              fontWeight: FontWeight.w600, fontSize: 14),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 3),
          Row(children: [
            Text('${ticket.replies.length} repl${ticket.replies.length == 1 ? 'y' : 'ies'}',
                style: TextStyle(
                    color: context.appTextSecondary, fontSize: 12)),
            if (ticket.createdAt != null) ...[
              Text(' · ',
                  style: TextStyle(color: context.appTextSecondary)),
              Text(_fmt(ticket.createdAt!),
                  style: TextStyle(
                      color: context.appTextSecondary, fontSize: 12)),
            ],
          ]),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: _statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(ticket.status.toUpperCase(),
              style: TextStyle(color: _statusColor,
                  fontSize: 10, fontWeight: FontWeight.w700)),
        ),
      ]),
    ),
  );

  String _fmt(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }
}

// ─── FAQ tab ──────────────────────────────────────────────────────────────────

class _FaqTab extends StatelessWidget {
  const _FaqTab();

  static const _faqs = [
    ('How do I book a ride?', 'Open the app, tap Book Ride, set your pickup and destination, then confirm.'),
    ('How do I cancel a ride?', 'During a booking you can tap Cancel on the tracking screen. Cancellation fees may apply after the driver is on the way.'),
    ('How does payment work?', 'We accept cash and wallet. Choose your method before confirming the booking.'),
    ('How do I report a problem?', 'Create a support ticket by tapping the + button above. Our team responds within 24 hours.'),
    ('Where does AutoRide operate?', 'Currently available across Phnom Penh, Cambodia.'),
    ('How do I become a driver?', 'Register with role "Driver", complete verification, then register your vehicle.'),
    ('What if the driver doesn\'t show up?', 'Use the SOS or contact button on the tracking screen, or cancel and rebook.'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [_green, Color(0xFF00A37A)]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(children: [
            const Icon(Icons.support_agent, color: Colors.white, size: 32),
            const SizedBox(width: 12),
            const Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Need help?', style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700,
                  fontSize: 15)),
              Text('Can\'t find your answer? Open a ticket.',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
            ])),
          ]),
        ),
        ..._faqs.map((faq) => _FaqTile(q: faq.$1, a: faq.$2)),
      ],
    );
  }
}

class _FaqTile extends StatefulWidget {
  final String q;
  final String a;
  const _FaqTile({required this.q, required this.a});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => setState(() => _open = !_open),
    child: Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: [
        Padding(
          padding: EdgeInsets.all(14),
          child: Row(children: [
            Expanded(child: Text(widget.q, style: TextStyle(
                color: context.appTextPrimary,
                fontWeight: FontWeight.w600, fontSize: 14))),
            Icon(_open ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded,
                color: context.appTextSecondary),
          ]),
        ),
        if (_open)
          Padding(
            padding: EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Text(widget.a, style: TextStyle(
                color: context.appTextSecondary, fontSize: 13, height: 1.5)),
          ),
      ]),
    ),
  );
}

// ─── New ticket sheet ─────────────────────────────────────────────────────────

class _NewTicketSheet extends StatefulWidget {
  final ValueChanged<SupportTicketModel> onCreated;
  const _NewTicketSheet({required this.onCreated});

  @override
  State<_NewTicketSheet> createState() => _NewTicketSheetState();
}

class _NewTicketSheetState extends State<_NewTicketSheet> {
  final _subCtrl  = TextEditingController();
  final _msgCtrl  = TextEditingController();
  String  _priority = 'normal';
  bool    _saving   = false;
  String? _error;

  @override
  void dispose() { _subCtrl.dispose(); _msgCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (_subCtrl.text.trim().isEmpty || _msgCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Subject and message are required');
      return;
    }
    setState(() { _saving = true; _error = null; });
    try {
      final t = await ApiService.createSupportTicket(
        subject:  _subCtrl.text.trim(),
        message:  _msgCtrl.text.trim(),
        priority: _priority,
      );
      if (!mounted) return;
      widget.onCreated(t);
      Navigator.pop(context);
    } on ApiException catch (e) {
      setState(() { _error = e.message; _saving = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _saving = false; });
    }
  }

  @override
  Widget build(BuildContext context) => Container(
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
      Center(child: Container(width: 40, height: 4,
          decoration: BoxDecoration(color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2)))),
      SizedBox(height: 16),
      Text('New Support Ticket',
          style: TextStyle(fontSize: 17,
              fontWeight: FontWeight.w700, color: context.appTextPrimary)),
      SizedBox(height: 16),

      // Priority
      Row(children: [
        Text('Priority: ',
            style: TextStyle(color: context.appTextSecondary,
                fontWeight: FontWeight.w600, fontSize: 13)),
        ...[('normal', 'Normal'), ('high', 'High'), ('urgent', 'Urgent')]
            .map((p) => Padding(
          padding: EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(p.$2),
            selected: _priority == p.$1,
            selectedColor: _green.withValues(alpha: 0.15),
            labelStyle: TextStyle(
              color: _priority == p.$1 ? _green : context.appTextSecondary,
              fontWeight: FontWeight.w600, fontSize: 12,
            ),
            onSelected: (_) => setState(() => _priority = p.$1),
          ),
        )),
      ]),
      SizedBox(height: 12),

      TextField(
        controller: _subCtrl,
        style: TextStyle(color: context.appTextPrimary),
        decoration: InputDecoration(
          labelText: 'Subject',
          labelStyle: TextStyle(color: context.appTextSecondary),
          filled: true, fillColor: context.appCardBg,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: _green)),
        ),
      ),
      SizedBox(height: 10),

      TextField(
        controller: _msgCtrl,
        maxLines: 4,
        style: TextStyle(color: context.appTextPrimary),
        decoration: InputDecoration(
          labelText: 'Describe your issue',
          labelStyle: TextStyle(color: context.appTextSecondary),
          alignLabelWithHint: true,
          filled: true, fillColor: context.appCardBg,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _green)),
        ),
      ),

      if (_error != null) ...[
        const SizedBox(height: 8),
        Text(_error!, style: const TextStyle(
            color: AppTheme.danger, fontSize: 12)),
      ],
      const SizedBox(height: 16),

      SizedBox(
        width: double.infinity, height: 50,
        child: ElevatedButton(
          onPressed: _saving ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: _green, foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: _saving
              ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Submit Ticket',
                  style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ),
    ]),
  );
}

// ─── Ticket detail screen ─────────────────────────────────────────────────────

class _TicketDetailScreen extends StatefulWidget {
  final SupportTicketModel ticket;
  const _TicketDetailScreen({required this.ticket});

  @override
  State<_TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<_TicketDetailScreen> {
  final _replyCtrl = TextEditingController();
  bool _sending = false;
  late SupportTicketModel _ticket;

  @override
  void initState() { super.initState(); _ticket = widget.ticket; }

  @override
  void dispose() { _replyCtrl.dispose(); super.dispose(); }

  Future<void> _reply() async {
    final msg = _replyCtrl.text.trim();
    if (msg.isEmpty) return;
    setState(() => _sending = true);
    try {
      await ApiService.replySupportTicket(_ticket.id, msg);
      if (!mounted) return;
      _replyCtrl.clear();
      setState(() {
        _sending = false;
        // Optimistically add reply
        _ticket = SupportTicketModel(
          id: _ticket.id, subject: _ticket.subject,
          status: _ticket.status, priority: _ticket.priority,
          createdAt: _ticket.createdAt,
          replies: [
            ..._ticket.replies,
            SupportReplyModel(
              id: DateTime.now().millisecondsSinceEpoch,
              message: msg,
              isStaff: false,
              createdAt: DateTime.now(),
            ),
          ],
        );
      });
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _sending = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.message), backgroundColor: AppTheme.danger,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (_) {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.appBackground,
    appBar: AppBar(
      backgroundColor: context.appSurface, elevation: 0,
      leading: BackButton(color: context.appTextPrimary),
      title: Text(_ticket.subject,
          style: TextStyle(
              color: context.appTextPrimary, fontWeight: FontWeight.w700,
              fontSize: 15),
          maxLines: 1, overflow: TextOverflow.ellipsis),
    ),
    body: Column(children: [
      Expanded(child: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Status badge
          Row(children: [
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _ticket.isOpen
                    ? _green.withValues(alpha: 0.1)
                    : context.appCardBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_ticket.status.toUpperCase(),
                  style: TextStyle(
                    color: _ticket.isOpen ? _green
                        : context.appTextSecondary,
                    fontSize: 11, fontWeight: FontWeight.w700,
                  )),
            ),
            const SizedBox(width: 8),
            Text('Priority: ${_ticket.priority}',
                style: TextStyle(
                    color: context.appTextSecondary, fontSize: 12)),
          ]),
          SizedBox(height: 16),

          if (_ticket.replies.isEmpty)
            Center(child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('No replies yet. We\'ll respond within 24 hours.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: context.appTextSecondary, fontSize: 13)),
            )),

          ..._ticket.replies.map((r) => _ReplyBubble(reply: r)),
        ],
      )),

      // Reply box
      if (_ticket.isOpen)
        Container(
          padding: EdgeInsets.only(
            left: 16, right: 8, top: 10,
            bottom: MediaQuery.of(context).viewInsets.bottom + 10,
          ),
          decoration: BoxDecoration(
            color: context.appSurface,
            border: Border(top: BorderSide(color: context.appCardBg)),
          ),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _replyCtrl,
                maxLines: 3, minLines: 1,
                style: TextStyle(
                    color: context.appTextPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Write a reply…',
                  hintStyle: TextStyle(
                      color: context.appTextSecondary),
                  filled: true, fillColor: context.appCardBg,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 44, height: 44,
              child: ElevatedButton(
                onPressed: _sending ? null : _reply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green, foregroundColor: Colors.white,
                  elevation: 0, padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _sending
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded, size: 18),
              ),
            ),
          ]),
        ),
    ]),
  );
}

class _ReplyBubble extends StatelessWidget {
  final SupportReplyModel reply;
  const _ReplyBubble({required this.reply});

  @override
  Widget build(BuildContext context) {
    final isStaff = reply.isStaff;
    return Align(
      alignment: isStaff
          ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: EdgeInsets.only(bottom: 10),
        padding: EdgeInsets.symmetric(
            horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isStaff ? context.appSurface : _green,
          borderRadius: BorderRadius.only(
            topLeft:     Radius.circular(14),
            topRight:    Radius.circular(14),
            bottomLeft:  Radius.circular(isStaff ? 0 : 14),
            bottomRight: Radius.circular(isStaff ? 14 : 0),
          ),
          boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 4, offset: Offset(0, 2),
          )],
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (isStaff)
            Text('Support Team',
                style: TextStyle(color: _green,
                    fontSize: 11, fontWeight: FontWeight.w700)),
          Text(reply.message,
              style: TextStyle(
                  color: isStaff
                      ? context.appTextPrimary : Colors.white,
                  fontSize: 13, height: 1.4)),
          SizedBox(height: 4),
          Text(reply.createdAt != null
              ? _fmt(reply.createdAt!) : '',
              style: TextStyle(
                  color: isStaff
                      ? context.appTextSecondary
                      : Colors.white.withValues(alpha: 0.7),
                  fontSize: 10)),
        ]),
      ),
    );
  }

  String _fmt(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }
}
