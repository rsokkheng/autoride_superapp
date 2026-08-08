import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  bool    _sendingImage = false;

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

  Future<void> _pickAndSendImage(ImageSource source) async {
    if (_chatId == null || _sendingImage) return;
    final picked = await ImagePicker().pickImage(
        source: source, maxWidth: 1600, maxHeight: 1600, imageQuality: 80);
    if (picked == null || !mounted) return;
    setState(() => _sendingImage = true);
    try {
      await FirestoreChatService.sendImageMessage(
        chatId:     _chatId!,
        senderId:   widget.myId,
        senderName: widget.myName,
        image:      File(picked.path),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Could not send photo: $e'),
        backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _sendingImage = false);
    }
  }

  void _showAttachmentSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.appSurface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: Icon(Icons.photo_camera_outlined, color: AppTheme.accent),
            title: Text('Take a photo', style: TextStyle(color: context.appTextPrimary)),
            onTap: () {
              Navigator.pop(context);
              _pickAndSendImage(ImageSource.camera);
            },
          ),
          ListTile(
            leading: Icon(Icons.photo_library_outlined, color: AppTheme.accent),
            title: Text('Upload from gallery', style: TextStyle(color: context.appTextPrimary)),
            onTap: () {
              Navigator.pop(context);
              _pickAndSendImage(ImageSource.gallery);
            },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
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
          SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.otherName,
                style: TextStyle(
                    color: context.appTextPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
            Text('Ride #${widget.rideId}',
                style: TextStyle(
                    color: context.appTextSecondary, fontSize: 11)),
          ]),
        ]),
      ),
      body: _loadingChat
          ? Center(
              child: CircularProgressIndicator(color: AppTheme.accent))
          : _chatError != null
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.wifi_off,
                        color: context.appTextSecondary, size: 48),
                    SizedBox(height: 12),
                    Text(_chatError!,
                        style: TextStyle(
                            color: context.appTextSecondary),
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
                                      color: context.appTextSecondary
                                          .withValues(alpha: 0.4),
                                      size: 56),
                                  SizedBox(height: 12),
                                  Text('No messages yet. Say hello!',
                                      style: TextStyle(
                                          color:
                                              context.appTextSecondary)),
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
                        EdgeInsets.fromLTRB(12, 8, 12, 12),
                    color: context.appSurface,
                    child: SafeArea(
                      top: false,
                      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        GestureDetector(
                          onTap: _sendingImage ? null : _showAttachmentSheet,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                color: context.appCardBg,
                                shape: BoxShape.circle),
                            child: _sendingImage
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        color: AppTheme.accent,
                                        strokeWidth: 2))
                                : Icon(Icons.attach_file,
                                    color: context.appTextSecondary, size: 18),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _msgCtrl,
                            style: TextStyle(
                                color: context.appTextPrimary),
                            maxLines: 3,
                            minLines: 1,
                            textAlignVertical: TextAlignVertical.center,
                            textInputAction: TextInputAction.newline,
                            onSubmitted: (_) => _send(),
                            decoration: InputDecoration(
                              hintText: 'Type a message...',
                              hintStyle: TextStyle(
                                  color: context.appTextSecondary),
                              filled: true,
                              fillColor: context.appCardBg,
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
        margin: EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72),
        padding:
            EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.accent : context.appSurface,
          borderRadius: BorderRadius.only(
            topLeft:     Radius.circular(16),
            topRight:    Radius.circular(16),
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
                padding: EdgeInsets.only(bottom: 4),
                child: Text(msg.senderName,
                    style: TextStyle(
                        color: AppTheme.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
            if (msg.isImage)
              GestureDetector(
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => Dialog(
                    backgroundColor: Colors.transparent,
                    insetPadding: const EdgeInsets.all(12),
                    child: InteractiveViewer(
                      child: Image.network(msg.attachmentUrl!),
                    ),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    msg.attachmentUrl!,
                    width: 200,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return SizedBox(
                        width: 200, height: 200,
                        child: Center(
                          child: CircularProgressIndicator(
                              color: isMe ? AppTheme.primary : AppTheme.accent, strokeWidth: 2),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stack) => SizedBox(
                      width: 200, height: 120,
                      child: Center(
                        child: Icon(Icons.broken_image_outlined,
                            color: isMe ? AppTheme.primary : context.appTextSecondary),
                      ),
                    ),
                  ),
                ),
              )
            else
              Text(msg.message,
                  style: TextStyle(
                      color: isMe
                          ? AppTheme.primary
                          : context.appTextPrimary,
                      fontSize: 14)),
            SizedBox(height: 4),
            Text(msg.timeLabel,
                style: TextStyle(
                    color: isMe
                        ? AppTheme.primary.withValues(alpha: 0.6)
                        : context.appTextSecondary,
                    fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
