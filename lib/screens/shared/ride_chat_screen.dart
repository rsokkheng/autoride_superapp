import 'package:flutter/material.dart';
import '../../models/firestore_message.dart';
import '../../services/firestore_chat_service.dart';
import '../../theme/app_theme.dart';

class RideChatScreen extends StatefulWidget {
  final String rideId;
  final int    driverId;
  final int    passengerId;
  final int    myId;
  final String myName;
  final String otherName;
  final bool   isDriver;

  const RideChatScreen({
    super.key,
    required this.rideId,
    required this.driverId,
    required this.passengerId,
    required this.myId,
    required this.myName,
    required this.otherName,
    required this.isDriver,
  });

  @override
  State<RideChatScreen> createState() => _RideChatScreenState();
}

class _RideChatScreenState extends State<RideChatScreen> {
  final _msgCtrl    = TextEditingController();
  final _scrollCtrl = ScrollController();

  String? _chatId;
  bool    _loadingChat = true;
  String? _chatError;
  bool    _sending     = false;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _initChat() async {
    try {
      final id = await FirestoreChatService.getOrCreateChat(
        rideId:      widget.rideId,
        driverId:    widget.driverId,
        passengerId: widget.passengerId,
      );
      if (!mounted) return;
      setState(() { _chatId = id; _loadingChat = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _chatError = e.toString(); _loadingChat = false; });
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
    if (text.isEmpty || _sending || _chatId == null) return;
    setState(() => _sending = true);
    _msgCtrl.clear();
    try {
      await FirestoreChatService.sendMessage(
        chatId:     _chatId!,
        senderId:   widget.myId,
        senderName: widget.myName,
        message:    text,
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color   = widget.isDriver ? AppTheme.accent : AppTheme.accentOrange;
    final initial = widget.otherName.isNotEmpty
        ? widget.otherName[0].toUpperCase()
        : '?';

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.2),
            child: Text(initial,
                style: TextStyle(color: color, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.otherName,
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
            Text('Ride #${widget.rideId}',
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 11)),
          ]),
        ]),
      ),
      body: _loadingChat
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accent))
          : _chatError != null
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.wifi_off,
                        color: AppTheme.textSecondary, size: 48),
                    const SizedBox(height: 12),
                    Text(_chatError!,
                        style: const TextStyle(
                            color: AppTheme.textSecondary),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _loadingChat = true;
                          _chatError = null;
                        });
                        _initChat();
                      },
                      child: const Text('Retry'),
                    ),
                  ]),
                )
              : Column(children: [
                  Expanded(
                    child: StreamBuilder<List<FirestoreMessage>>(
                      stream:
                          FirestoreChatService.messagesStream(_chatId!),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator(
                                  color: AppTheme.accent));
                        }
                        final msgs = snapshot.data ?? [];
                        if (msgs.isNotEmpty) _scrollToBottom();
                        if (msgs.isEmpty) {
                          return Center(
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.chat_bubble_outline,
                                      color: AppTheme.textSecondary
                                          .withValues(alpha: 0.4),
                                      size: 56),
                                  const SizedBox(height: 12),
                                  const Text('No messages yet. Say hello!',
                                      style: TextStyle(
                                          color:
                                              AppTheme.textSecondary)),
                                ]),
                          );
                        }
                        return ListView.builder(
                          controller: _scrollCtrl,
                          padding: const EdgeInsets.all(16),
                          itemCount: msgs.length,
                          itemBuilder: (_, i) => _Bubble(
                            msg: msgs[i],
                            isMe: msgs[i].senderId == widget.myId,
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    color: AppTheme.surface,
                    child: SafeArea(
                      top: false,
                      child: Row(children: [
                        Expanded(
                          child: TextField(
                            controller: _msgCtrl,
                            style: const TextStyle(
                                color: AppTheme.textPrimary),
                            maxLines: 3,
                            minLines: 1,
                            textInputAction: TextInputAction.newline,
                            onSubmitted: (_) => _send(),
                            decoration: InputDecoration(
                              hintText: 'Type a message...',
                              hintStyle: const TextStyle(
                                  color: AppTheme.textSecondary),
                              filled: true,
                              fillColor: AppTheme.cardBg,
                              border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(24),
                                  borderSide: BorderSide.none),
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _send,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                                color: AppTheme.accent,
                                shape: BoxShape.circle),
                            child: _sending
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        color: AppTheme.primary,
                                        strokeWidth: 2))
                                : const Icon(Icons.send,
                                    color: AppTheme.primary, size: 18),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ]),
    );
  }
}

class _Bubble extends StatelessWidget {
  final FirestoreMessage msg;
  final bool isMe;
  const _Bubble({required this.msg, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.accent : AppTheme.surface,
          borderRadius: BorderRadius.only(
            topLeft:     const Radius.circular(16),
            topRight:    const Radius.circular(16),
            bottomLeft:  Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(msg.senderName,
                    style: const TextStyle(
                        color: AppTheme.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
            Text(msg.message,
                style: TextStyle(
                    color: isMe
                        ? AppTheme.primary
                        : AppTheme.textPrimary,
                    fontSize: 14)),
            const SizedBox(height: 4),
            Text(msg.timeLabel,
                style: TextStyle(
                    color: isMe
                        ? AppTheme.primary.withValues(alpha: 0.6)
                        : AppTheme.textSecondary,
                    fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
