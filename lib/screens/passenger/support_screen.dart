import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

const _green = Color(0xFF00C48C);

class SupportScreen extends StatefulWidget {
  final String? initialSubject;
  const SupportScreen({super.key, this.initialSubject});

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
    if (widget.initialSubject != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showNewTicket(subject: widget.initialSubject));
    }
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
        title: Text(AppLocalizations.of(context).helpSupport,
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
          tabs: [Tab(text: AppLocalizations.of(context).myTicketsTab), Tab(text: AppLocalizations.of(context).faqTab)],
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

  void _showNewTicket({String? subject}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NewTicketSheet(
        initialSubject: subject,
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
          child: Text(AppLocalizations.of(context).retry)),
    ]));
    if (tickets.isEmpty) return RefreshIndicator(
      onRefresh: onRefresh, color: _green,
      child: ListView(padding: EdgeInsets.all(32), children: [
        Icon(Icons.support_agent_outlined,
            color: context.appTextSecondary, size: 60),
        SizedBox(height: 16),
        Text(AppLocalizations.of(context).noSupportTickets, textAlign: TextAlign.center,
            style: TextStyle(color: context.appTextPrimary,
                fontSize: 16, fontWeight: FontWeight.w700)),
        SizedBox(height: 6),
        Text(AppLocalizations.of(context).tapPlusToCreateTicket,
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
          _SectionLabel('${AppLocalizations.of(context).openParenPrefix} (${open.length})'),
          ...open.map((t) => _TicketTile(ticket: t, onTap: () => onOpen(t))),
          const SizedBox(height: 8),
        ],
        if (closed.isNotEmpty) ...[
          _SectionLabel('${AppLocalizations.of(context).resolvedParenPrefix} (${closed.length})'),
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
            Text('${ticket.replies.length} ${AppLocalizations.of(context).repliesCountLabel}',
                style: TextStyle(
                    color: context.appTextSecondary, fontSize: 12)),
            if (ticket.createdAt != null) ...[
              Text(' · ',
                  style: TextStyle(color: context.appTextSecondary)),
              Text(_fmt(context, ticket.createdAt!),
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

  String _fmt(BuildContext context, DateTime dt) {
    final l = AppLocalizations.of(context);
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}${l.dAgoSuffix}';
    if (diff.inHours > 0) return '${diff.inHours}${l.hAgoSuffix}';
    return '${diff.inMinutes}${l.mAgoSuffix}';
  }
}

// ─── FAQ tab ──────────────────────────────────────────────────────────────────

class _FaqTab extends StatelessWidget {
  const _FaqTab();

  List<(String, String)> _faqs(BuildContext context) {
    final l = AppLocalizations.of(context);
    return [
      (l.faq1Q, l.faq1A),
      (l.faq2Q, l.faq2A),
      (l.faq3Q, l.faq3A),
      (l.faq4Q, l.faq4A),
      (l.faq5Q, l.faq5A),
      (l.faq6Q, l.faq6A),
      (l.faq7Q, l.faq7A),
    ];
  }

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
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(AppLocalizations.of(context).needHelpTitle, style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700,
                  fontSize: 15)),
              Text(AppLocalizations.of(context).cantFindAnswerDesc,
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ])),
          ]),
        ),
        ..._faqs(context).map((faq) => _FaqTile(q: faq.$1, a: faq.$2)),
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
  final String? initialSubject;
  const _NewTicketSheet({required this.onCreated, this.initialSubject});

  @override
  State<_NewTicketSheet> createState() => _NewTicketSheetState();
}

class _NewTicketSheetState extends State<_NewTicketSheet> {
  late final _subCtrl = TextEditingController(text: widget.initialSubject ?? '');
  final _msgCtrl  = TextEditingController();
  String  _priority = 'medium';
  bool    _saving   = false;
  String? _error;

  @override
  void dispose() { _subCtrl.dispose(); _msgCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (_subCtrl.text.trim().isEmpty || _msgCtrl.text.trim().isEmpty) {
      setState(() => _error = AppLocalizations.of(context).subjectAndMessageRequired);
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
      Text(AppLocalizations.of(context).newSupportTicketTitle,
          style: TextStyle(fontSize: 17,
              fontWeight: FontWeight.w700, color: context.appTextPrimary)),
      SizedBox(height: 16),

      // Priority
      Row(children: [
        Text(AppLocalizations.of(context).priorityColonLabel,
            style: TextStyle(color: context.appTextSecondary,
                fontWeight: FontWeight.w600, fontSize: 13)),
        ...[('medium', AppLocalizations.of(context).normal), ('high', AppLocalizations.of(context).highPriority), ('urgent', AppLocalizations.of(context).urgentPriority)]
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
          labelText: AppLocalizations.of(context).subjectLabel,
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
          labelText: AppLocalizations.of(context).describeYourIssueLabel,
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
          style: AppTheme.confirmButtonStyle(background: _green),
          child: _saving
              ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : Text(AppLocalizations.of(context).submitTicketBtn),
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
            Text('${AppLocalizations.of(context).priorityColonLabel} ${_ticket.priority}',
                style: TextStyle(
                    color: context.appTextSecondary, fontSize: 12)),
          ]),
          SizedBox(height: 16),

          if (_ticket.replies.isEmpty)
            Center(child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(AppLocalizations.of(context).noRepliesYetDesc,
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
                  hintText: AppLocalizations.of(context).writeAReplyHint,
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
            Text(AppLocalizations.of(context).supportTeamLabel,
                style: TextStyle(color: _green,
                    fontSize: 11, fontWeight: FontWeight.w700)),
          Text(reply.message,
              style: TextStyle(
                  color: isStaff
                      ? context.appTextPrimary : Colors.white,
                  fontSize: 13, height: 1.4)),
          SizedBox(height: 4),
          Text(reply.createdAt != null
              ? _fmt(context, reply.createdAt!) : '',
              style: TextStyle(
                  color: isStaff
                      ? context.appTextSecondary
                      : Colors.white.withValues(alpha: 0.7),
                  fontSize: 10)),
        ]),
      ),
    );
  }

  String _fmt(BuildContext context, DateTime dt) {
    final l = AppLocalizations.of(context);
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}${l.dAgoSuffix}';
    if (diff.inHours > 0) return '${diff.inHours}${l.hAgoSuffix}';
    return '${diff.inMinutes}${l.mAgoSuffix}';
  }
}

// ─── Hotline chat — type straight to support, no ticket form ─────────────────
//
// Reuses the same backend as the ticket system (createSupportTicket /
// getSupportTickets / replySupportTicket): the first message a passenger
// types opens a ticket behind the scenes, further messages reply to it, and
// once staff close it, sending again just starts a fresh one — all invisible
// to the passenger, who only ever sees a normal chat thread.
class SupportChatScreen extends StatefulWidget {
  const SupportChatScreen({super.key});

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final _msgCtrl    = TextEditingController();
  final _scrollCtrl = ScrollController();
  SupportTicketModel? _ticket;
  bool    _loading = true;
  bool    _sending = false;
  String? _error;
  Timer?  _pollTimer;
  // The message that opened the current ticket: the backend stores it as
  // the ticket's own subject/description, never as a reply row, so it would
  // never appear (and would vanish on the next poll if we faked a reply for
  // it) unless we pin it here and prepend it at render time instead.
  int?    _pinnedTicketId;
  String? _pinnedFirstMessage;

  List<SupportReplyModel> get _displayReplies => [
    if (_ticket != null && _pinnedTicketId == _ticket!.id)
      SupportReplyModel(id: -1, message: _pinnedFirstMessage!, isStaff: false, createdAt: _ticket!.createdAt),
    ...?_ticket?.replies,
  ];

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await _load();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _load(silent: true));
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() { _loading = true; _error = null; });
    try {
      final tickets = await ApiService.getSupportTickets();
      if (!mounted) return;
      final open = tickets.where((t) => t.isOpen).toList();
      setState(() {
        _ticket  = open.isNotEmpty ? open.first : (_ticket != null
            ? tickets.where((t) => t.id == _ticket!.id).firstOrNull ?? _ticket
            : null);
        _loading = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted || silent) return;
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _msgCtrl.clear();

    try {
      if (_ticket == null || _ticket!.isClosed) {
        final t = await ApiService.createSupportTicket(subject: 'Chat with Support', message: text);
        if (!mounted) return;
        setState(() {
          _ticket             = t;
          _pinnedTicketId     = t.id;
          _pinnedFirstMessage = text;
          _sending            = false;
        });
      } else {
        await ApiService.replySupportTicket(_ticket!.id, text);
        if (!mounted) return;
        setState(() {
          _sending = false;
          _ticket = SupportTicketModel(
            id: _ticket!.id, subject: _ticket!.subject,
            status: _ticket!.status, priority: _ticket!.priority,
            createdAt: _ticket!.createdAt,
            replies: [
              ..._ticket!.replies,
              SupportReplyModel(
                id: DateTime.now().millisecondsSinceEpoch,
                message: text, isStaff: false, createdAt: DateTime.now(),
              ),
            ],
          );
        });
      }
      _scrollToBottom();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message), backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (_) {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        elevation: 0,
        leading: BackButton(color: context.appTextPrimary),
        titleSpacing: 0,
        title: Row(children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: _green.withValues(alpha: 0.2),
            child: Icon(Icons.support_agent, color: _green, size: 20),
          ),
          SizedBox(width: 10),
          Text('ROTEH Support',
              style: TextStyle(color: context.appTextPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
        ]),
        actions: [
          IconButton(
            icon: Icon(Icons.list_alt_outlined, color: context.appTextSecondary),
            tooltip: AppLocalizations.of(context).myTicketsTab,
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen())),
          ),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: _loading
              ? Center(child: CircularProgressIndicator(color: _green))
              : _error != null
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.wifi_off, color: context.appTextSecondary, size: 48),
                      SizedBox(height: 12),
                      Text(_error!, style: TextStyle(color: context.appTextSecondary), textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: () => _load(),
                          style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white),
                          child: Text(l.retry)),
                    ]))
                  : _displayReplies.isEmpty
                      ? Center(child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.chat_bubble_outline, color: context.appTextSecondary.withValues(alpha: 0.4), size: 56),
                            SizedBox(height: 12),
                            Text('Say hello! Our team typically replies within a few minutes.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: context.appTextSecondary)),
                          ]),
                        ))
                      : ListView(
                          controller: _scrollCtrl,
                          padding: EdgeInsets.all(16),
                          children: _displayReplies.map((r) => _ReplyBubble(reply: r)).toList(),
                        ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(12, 8, 12, 12),
          color: context.appSurface,
          child: SafeArea(
            top: false,
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _msgCtrl,
                  style: TextStyle(color: context.appTextPrimary),
                  maxLines: 3,
                  minLines: 1,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(color: context.appTextSecondary),
                    filled: true,
                    fillColor: context.appCardBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _send,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: _green, shape: BoxShape.circle),
                  child: _sending
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send, color: Colors.white, size: 18),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
