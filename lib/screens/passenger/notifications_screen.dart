import 'package:flutter/material.dart';
import 'package:autoride_superapp/theme/app_theme.dart';
import '../../services/api_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  final Set<int> _locallyRead = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _loading = true);
    try {
      final list = await ApiService.getNotifications();
      if (!mounted) return;
      setState(() {
        _notifications = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _markRead(int id) async {
    setState(() => _locallyRead.add(id));
    try {
      await ApiService.markNotificationRead(id);
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    setState(() {
      for (final n in _notifications) {
        final id = n['id'];
        if (id is int) _locallyRead.add(id);
      }
    });
    try {
      await ApiService.markAllNotificationsRead();
    } catch (_) {}
  }

  bool _isRead(Map<String, dynamic> n) {
    final id = n['id'];
    if (id is int && _locallyRead.contains(id)) return true;
    final readAt = n['read_at'];
    return readAt != null && readAt.toString().isNotEmpty;
  }

  String _relativeTime(String? rawTime) {
    if (rawTime == null || rawTime.isEmpty) return '';
    final dt = DateTime.tryParse(rawTime);
    if (dt == null) return rawTime;
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24)   return '${diff.inHours} hrs ago';
    if (diff.inDays == 1)    return 'Yesterday';
    if (diff.inDays < 7)     return '${diff.inDays} days ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  IconData _typeIcon(String? type) {
    if (type == null) return Icons.notifications;
    final t = type.toLowerCase();
    if (t.contains('ride') || t.contains('booking') || t.contains('trip') || t.contains('accepted') || t.contains('driver_arrived') || t.contains('driver'))
      return Icons.directions_car;
    if (t.contains('payment') || t.contains('fare') || t.contains('wallet'))
      return Icons.account_balance_wallet;
    if (t.contains('promo') || t.contains('discount'))
      return Icons.local_offer;
    if (t.contains('rating') || t.contains('star'))
      return Icons.star;
    return Icons.notifications;
  }

  Color _typeColor(String? type) {
    if (type == null) return context.appTextSecondary;
    final t = type.toLowerCase();
    if (t.contains('ride') || t.contains('booking') || t.contains('trip') || t.contains('accepted') || t.contains('driver'))
      return AppTheme.accent;
    if (t.contains('payment') || t.contains('fare') || t.contains('wallet'))
      return AppTheme.success;
    if (t.contains('promo') || t.contains('discount'))
      return AppTheme.accentOrange;
    if (t.contains('rating') || t.contains('star'))
      return AppTheme.gold;
    return context.appTextSecondary;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
        actions: [
          TextButton(
            onPressed: _notifications.isEmpty ? null : _markAllRead,
            child: Text('Mark all read', style: TextStyle(color: AppTheme.accent, fontSize: 13)),
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : RefreshIndicator(
              color: AppTheme.accent,
              onRefresh: _loadNotifications,
              child: _notifications.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.65,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.notifications_none_outlined,
                                  color: context.appTextSecondary, size: 64),
                              SizedBox(height: 16),
                              Text('No notifications yet',
                                  style: TextStyle(
                                      color: context.appTextSecondary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      itemCount: _notifications.length,
                      itemBuilder: (_, i) {
                        final n      = _notifications[i];
                        final id     = n['id'];
                        final read   = _isRead(n);
                        final type   = n['type']?.toString();
                        final title  = n['title']?.toString() ?? n['data']?['title']?.toString() ?? 'Notification';
                        final body   = n['body']?.toString() ?? n['message']?.toString() ?? n['data']?['body']?.toString() ?? '';
                        final time   = _relativeTime(n['created_at']?.toString());
                        final color  = _typeColor(type);
                        final icon   = _typeIcon(type);

                        return GestureDetector(
                          onTap: () {
                            if (!read && id is int) _markRead(id);
                          },
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: read
                                  ? Colors.transparent
                                  : AppTheme.accent.withValues(alpha: 0.05),
                              border: Border(
                                left: BorderSide(
                                  color: read ? Colors.transparent : AppTheme.accent,
                                  width: 3,
                                ),
                              ),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Container(
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(icon, color: color, size: 20),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Row(children: [
                                    Expanded(
                                      child: Text(title,
                                          style: TextStyle(
                                            color: context.appTextPrimary,
                                            fontWeight: read ? FontWeight.w500 : FontWeight.w800,
                                            fontSize: 14,
                                          )),
                                    ),
                                    if (!read)
                                      Container(
                                          width: 8, height: 8,
                                          decoration: BoxDecoration(
                                              color: AppTheme.accent, shape: BoxShape.circle)),
                                  ]),
                                  if (body.isNotEmpty) ...[
                                    SizedBox(height: 4),
                                    Text(body,
                                        style: TextStyle(
                                            color: context.appTextSecondary, fontSize: 12, height: 1.4)),
                                  ],
                                  if (time.isNotEmpty) ...[
                                    SizedBox(height: 4),
                                    Text(time,
                                        style: TextStyle(
                                            color: context.appTextSecondary, fontSize: 11)),
                                  ],
                                ]),
                              ),
                            ]),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
