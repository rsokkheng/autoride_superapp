import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class AdminSupportScreen extends StatefulWidget {
  const AdminSupportScreen({super.key});

  @override
  State<AdminSupportScreen> createState() => _AdminSupportScreenState();
}

class _AdminSupportScreenState extends State<AdminSupportScreen> {
  List<Map<String, dynamic>> _tickets = [];
  bool _loading = true;
  String? _error;
  String? _statusFilter = 'open';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await ApiService.getAdminSupportTickets(status: _statusFilter == 'all' ? null : _statusFilter);
      if (!mounted) return;
      setState(() { _tickets = list; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      appBar: AppBar(
        title: const Text('Support Tickets'),
        actions: [
          PopupMenuButton<String>(
            color: AppTheme.surface,
            icon: Icon(Icons.filter_list_rounded, color: _statusFilter != 'all' ? AppTheme.accent : AppTheme.textSecondary),
            onSelected: (v) { setState(() => _statusFilter = v); _load(); },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'open',        child: Text('Open',        style: TextStyle(color: AppTheme.textPrimary))),
              PopupMenuItem(value: 'in_progress', child: Text('In Progress', style: TextStyle(color: AppTheme.textPrimary))),
              PopupMenuItem(value: 'resolved',    child: Text('Resolved',    style: TextStyle(color: AppTheme.textPrimary))),
              PopupMenuItem(value: 'closed',      child: Text('Closed',      style: TextStyle(color: AppTheme.textPrimary))),
              PopupMenuItem(value: 'all',         child: Text('All',         style: TextStyle(color: AppTheme.textPrimary))),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.error_outline, color: AppTheme.danger, size: 40), const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: AppTheme.textSecondary), textAlign: TextAlign.center), const SizedBox(height: 16),
                  ElevatedButton(onPressed: _load, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent), child: const Text('Retry')),
                ]))
              : _tickets.isEmpty
                  ? const Center(child: Text('No tickets found.', style: TextStyle(color: AppTheme.textSecondary)))
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppTheme.accent,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _tickets.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _TicketTile(ticket: _tickets[i], onUpdated: _load),
                      ),
                    ),
    );
  }
}

class _TicketTile extends StatelessWidget {
  final Map<String, dynamic> ticket;
  final VoidCallback onUpdated;
  const _TicketTile({required this.ticket, required this.onUpdated});

  Color _priorityColor(String? p) {
    switch (p) {
      case 'high':   return AppTheme.danger;
      case 'medium': return AppTheme.warning;
      default:       return AppTheme.textSecondary;
    }
  }

  Color _statusColor(String? s) {
    switch (s) {
      case 'resolved':
      case 'closed':      return AppTheme.success;
      case 'in_progress': return AppTheme.accent;
      default:            return AppTheme.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final id       = ticket['id']?.toString() ?? '—';
    final subject  = ticket['subject']  as String? ?? ticket['title'] as String? ?? 'No subject';
    final status   = ticket['status']   as String? ?? 'open';
    final priority = ticket['priority'] as String? ?? 'low';
    final user     = (ticket['user'] as Map?)?['name'] as String? ?? 'User';

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => AdminTicketDetailScreen(ticketId: int.tryParse(id) ?? 0, onUpdated: onUpdated),
      )),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: _priorityColor(priority).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.support_agent_rounded, color: _priorityColor(priority), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(subject, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Text('$user  •  #$id', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
            ]),
          ),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: _statusColor(status).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
              child: Text(status.replaceAll('_', ' ').toUpperCase(), style: TextStyle(color: _statusColor(status), fontSize: 9, fontWeight: FontWeight.w700))),
            const SizedBox(height: 4),
            Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: _priorityColor(priority).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
              child: Text(priority.toUpperCase(), style: TextStyle(color: _priorityColor(priority), fontSize: 9, fontWeight: FontWeight.w700))),
          ]),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: AppTheme.textSecondary, size: 18),
        ]),
      ),
    );
  }
}

class AdminTicketDetailScreen extends StatefulWidget {
  final int ticketId;
  final VoidCallback onUpdated;
  const AdminTicketDetailScreen({super.key, required this.ticketId, required this.onUpdated});

  @override
  State<AdminTicketDetailScreen> createState() => _AdminTicketDetailScreenState();
}

class _AdminTicketDetailScreenState extends State<AdminTicketDetailScreen> {
  Map<String, dynamic> _ticket = {};
  bool _loading = true;
  String? _error;
  bool _replying = false;
  final _replyCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _replyCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService.getAdminSupportTicket(widget.ticketId);
      if (!mounted) return;
      setState(() { _ticket = data; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  Future<void> _reply() async {
    final msg = _replyCtrl.text.trim();
    if (msg.isEmpty) return;
    setState(() => _replying = true);
    try {
      await ApiService.replyAdminSupportTicket(widget.ticketId, msg);
      if (!mounted) return;
      _replyCtrl.clear();
      await _load();
      widget.onUpdated();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: AppTheme.danger, behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _replying = false);
    }
  }

  Future<void> _updateStatus(String status) async {
    try {
      await ApiService.updateAdminSupportTicketStatus(widget.ticketId, status);
      if (!mounted) return;
      await _load();
      widget.onUpdated();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: AppTheme.danger, behavior: SnackBarBehavior.floating));
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = (_ticket['messages'] as List<dynamic>?) ?? [];
    final status   = _ticket['status'] as String? ?? 'open';

    return Scaffold(
      backgroundColor: AppTheme.primary,
      appBar: AppBar(
        title: Text(_ticket['subject'] as String? ?? 'Ticket #${widget.ticketId}'),
        actions: [
          PopupMenuButton<String>(
            color: AppTheme.surface,
            icon: const Icon(Icons.more_vert),
            onSelected: _updateStatus,
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'open',        child: Text('Mark Open',        style: TextStyle(color: AppTheme.textPrimary))),
              PopupMenuItem(value: 'in_progress', child: Text('Mark In Progress', style: TextStyle(color: AppTheme.textPrimary))),
              PopupMenuItem(value: 'resolved',    child: Text('Mark Resolved',    style: TextStyle(color: AppTheme.textPrimary))),
              PopupMenuItem(value: 'closed',      child: Text('Mark Closed',      style: TextStyle(color: AppTheme.textPrimary))),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.error_outline, color: AppTheme.danger, size: 40), const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: AppTheme.textSecondary)), const SizedBox(height: 16),
                  ElevatedButton(onPressed: _load, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent), child: const Text('Retry')),
                ]))
              : Column(children: [
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final m       = messages[i] as Map;
                        final isAdmin = m['sender_type'] == 'admin' || m['is_admin'] == true;
                        final text    = m['message'] as String? ?? m['body'] as String? ?? '';
                        final name    = m['sender_name'] as String? ?? (isAdmin ? 'Admin' : 'User');
                        return Row(
                          mainAxisAlignment: isAdmin ? MainAxisAlignment.end : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (!isAdmin) ...[
                              CircleAvatar(radius: 14, backgroundColor: AppTheme.accent.withValues(alpha: 0.12),
                                child: Text(name[0].toUpperCase(), style: const TextStyle(color: AppTheme.accent, fontSize: 11))),
                              const SizedBox(width: 8),
                            ],
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isAdmin ? AppTheme.accent : AppTheme.surface,
                                  borderRadius: BorderRadius.only(
                                    topLeft:     const Radius.circular(14),
                                    topRight:    const Radius.circular(14),
                                    bottomLeft:  Radius.circular(isAdmin ? 14 : 4),
                                    bottomRight: Radius.circular(isAdmin ? 4 : 14),
                                  ),
                                ),
                                child: Text(text, style: TextStyle(color: isAdmin ? Colors.white : AppTheme.textPrimary, fontSize: 13)),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  if (status != 'closed' && status != 'resolved')
                    Container(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 16),
                      color: AppTheme.surface,
                      child: Row(children: [
                        Expanded(
                          child: TextField(
                            controller: _replyCtrl,
                            style: const TextStyle(color: AppTheme.textPrimary),
                            decoration: InputDecoration(
                              hintText: 'Type a reply…',
                              hintStyle: const TextStyle(color: AppTheme.textSecondary),
                              filled: true, fillColor: AppTheme.cardBg,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _replying ? null : _reply,
                          child: Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(color: AppTheme.accent, shape: BoxShape.circle),
                            child: _replying
                                ? const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                          ),
                        ),
                      ]),
                    ),
                ]),
    );
  }
}
