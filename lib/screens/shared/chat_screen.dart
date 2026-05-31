import 'dart:async';
import 'package:flutter/material.dart';
import 'package:autoride_superapp/theme/app_theme.dart';
import 'package:autoride_superapp/services/api_service.dart';
import 'package:autoride_superapp/models/conversation_model.dart';
import 'package:autoride_superapp/models/chat_message_model.dart';

class ChatScreen extends StatefulWidget {
  final bool isDriver;
  const ChatScreen({super.key, required this.isDriver});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ConversationModel> _conversations = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadConversations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await ApiService.getConversations();
      if (!mounted) return;
      setState(() { _conversations = list; _loading = false; });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages & Support'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accent,
          labelColor: AppTheme.accent,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: const [Tab(text: 'Chats'), Tab(text: 'Support')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ConversationsTab(
            conversations: _conversations,
            loading: _loading,
            error: _error,
            isDriver: widget.isDriver,
            onRefresh: _loadConversations,
          ),
          const _SupportTab(),
        ],
      ),
    );
  }
}

// ── Conversations list tab ─────────────────────────────────────────────────────
class _ConversationsTab extends StatelessWidget {
  final List<ConversationModel> conversations;
  final bool loading;
  final String? error;
  final bool isDriver;
  final VoidCallback onRefresh;

  const _ConversationsTab({
    required this.conversations,
    required this.loading,
    required this.error,
    required this.isDriver,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.accent));
    }

    if (error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.wifi_off, color: AppTheme.textSecondary, size: 48),
          const SizedBox(height: 12),
          Text(error!, style: const TextStyle(color: AppTheme.textSecondary), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRefresh, child: const Text('Retry')),
        ]),
      );
    }

    if (conversations.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.chat_bubble_outline, color: AppTheme.textSecondary.withValues(alpha: 0.4), size: 64),
          const SizedBox(height: 16),
          const Text('No conversations yet', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('Messages with your driver will appear here',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13), textAlign: TextAlign.center),
        ]),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: AppTheme.accent,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: conversations.length,
        separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.cardBg, indent: 72),
        itemBuilder: (context, i) {
          final conv = conversations[i];
          final other = isDriver ? conv.passenger : conv.driver;
          final otherName = other?.name ?? conv.topic;
          final initial = otherName.isNotEmpty ? otherName[0].toUpperCase() : '?';
          final color = isDriver ? AppTheme.accent : AppTheme.accentOrange;

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: color.withValues(alpha: 0.2),
              child: Text(initial, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 18)),
            ),
            title: Text(otherName,
                style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
            subtitle: Text(conv.topic,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  conv.updatedAt.length >= 16 ? conv.updatedAt.substring(11, 16) : '',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: conv.status == 'active' ? AppTheme.success : AppTheme.textSecondary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ConversationDetailScreen(
                conversation: conv,
                isDriver: isDriver,
              )),
            ),
          );
        },
      ),
    );
  }
}

// ── Conversation detail (messages thread) ─────────────────────────────────────
class ConversationDetailScreen extends StatefulWidget {
  final ConversationModel conversation;
  final bool isDriver;

  const ConversationDetailScreen({super.key, required this.conversation, required this.isDriver});

  @override
  State<ConversationDetailScreen> createState() => _ConversationDetailScreenState();
}

class _ConversationDetailScreenState extends State<ConversationDetailScreen> {
  final _msgCtrl    = TextEditingController();
  final _scrollCtrl = ScrollController();
  List<ChatMessageModel> _messages = [];
  bool _loading = true;
  bool _sending = false;
  int? _myId;
  Timer? _pollTimer;

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
    final saved = await ApiService.getSavedUser();
    _myId = saved?.id;
    await _loadMessages();
    // Poll every 5 seconds for new messages
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _loadMessages(silent: true));
  }

  Future<void> _loadMessages({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final msgs = await ApiService.getMessages(widget.conversation.id);
      if (!mounted) return;
      setState(() { _messages = msgs; _loading = false; });
      _scrollToBottom();
    } catch (_) {
      if (mounted && !silent) setState(() => _loading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() { _sending = true; });
    _msgCtrl.clear();

    try {
      final msg = await ApiService.sendMessage(widget.conversation.id, text);
      if (!mounted) return;
      setState(() { _messages.add(msg); _sending = false; });
      _scrollToBottom();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message),
        backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } catch (_) {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final other = widget.isDriver ? widget.conversation.passenger : widget.conversation.driver;
    final title = other?.name ?? widget.conversation.topic;
    final color = widget.isDriver ? AppTheme.accent : AppTheme.accentOrange;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.2),
            child: Text(
              title.isNotEmpty ? title[0].toUpperCase() : '?',
              style: TextStyle(color: color, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
            Text(widget.conversation.topic, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          ]),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: AppTheme.textSecondary),
              onPressed: () => _loadMessages()),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
                : _messages.isEmpty
                    ? const Center(child: Text('No messages yet. Say hello!',
                          style: TextStyle(color: AppTheme.textSecondary)))
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, i) {
                          final msg = _messages[i];
                          final isMe = msg.senderId == _myId;
                          return _MessageBubble(msg: msg, isMe: isMe);
                        },
                      ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            color: AppTheme.surface,
            child: SafeArea(
              top: false,
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    maxLines: 3,
                    minLines: 1,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: const TextStyle(color: AppTheme.textSecondary),
                      filled: true,
                      fillColor: AppTheme.cardBg,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _send,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(color: AppTheme.accent, shape: BoxShape.circle),
                    child: _sending
                        ? const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2))
                        : const Icon(Icons.send, color: AppTheme.primary, size: 18),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Message bubble ─────────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final ChatMessageModel msg;
  final bool isMe;

  const _MessageBubble({required this.msg, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.accent : AppTheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe && msg.sender != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(msg.sender!.name,
                    style: const TextStyle(color: AppTheme.accent, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            Text(msg.message,
                style: TextStyle(color: isMe ? AppTheme.primary : AppTheme.textPrimary, fontSize: 14)),
            const SizedBox(height: 4),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Text(msg.timeLabel,
                  style: TextStyle(
                      color: isMe ? AppTheme.primary.withValues(alpha: 0.6) : AppTheme.textSecondary,
                      fontSize: 11)),
              if (isMe) ...[
                const SizedBox(width: 4),
                Icon(
                  msg.isRead ? Icons.done_all : Icons.done,
                  size: 12,
                  color: msg.isRead ? AppTheme.success : AppTheme.primary.withValues(alpha: 0.6),
                ),
              ],
            ]),
          ],
        ),
      ),
    );
  }
}

// ── Support tab (static FAQ) ───────────────────────────────────────────────────
class _SupportTab extends StatelessWidget {
  const _SupportTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('How can we help?',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          TextField(
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search for help...',
              hintStyle: const TextStyle(color: AppTheme.textSecondary),
              prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
              filled: true,
              fillColor: AppTheme.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Quick Help',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ...[
            ('My driver is late',      Icons.schedule_outlined,    AppTheme.warning),
            ('I was overcharged',      Icons.receipt_outlined,     AppTheme.danger),
            ('Lost item in vehicle',   Icons.inventory_2_outlined, AppTheme.accent),
            ('Report a safety issue',  Icons.shield_outlined,      AppTheme.danger),
            ('Cancel my trip',         Icons.cancel_outlined,      AppTheme.textSecondary),
          ].map((item) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(14)),
            child: ListTile(
              leading: Icon(item.$2, color: item.$3, size: 20),
              title: Text(item.$1, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
              trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary, size: 18),
              onTap: () {},
            ),
          )),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.headset_mic_outlined, color: AppTheme.accent, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('24/7 Live Support',
                    style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                SizedBox(height: 4),
                Text('Average response: 2 minutes',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: AppTheme.accent, borderRadius: BorderRadius.circular(10)),
                child: const Text('Chat Now',
                    style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
