import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

/// Shop-order alerts (new purchases, rentals, payments, cancellations) — the
/// same inbox as the web admin panel's bell, so reading here clears it there.
class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  static const _filters = [
    (null,       'All'),
    ('purchase', 'Purchases'),
    ('rental',   'Rentals'),
    ('system',   'Payments & Cancels'),
  ];

  String? _category;
  List<Map<String, dynamic>> _items = [];
  Map<String, dynamic> _counts = {};
  int _page = 1;
  int _lastPage = 1;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService.getAdminNotifications(category: _category);
      if (!mounted) return;
      setState(() {
        _items    = _list(data);
        _counts   = data['counts'] as Map<String, dynamic>? ?? {};
        _page     = (data['current_page'] as num?)?.toInt() ?? 1;
        _lastPage = (data['last_page'] as num?)?.toInt() ?? 1;
        _loading  = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _page >= _lastPage) return;
    setState(() => _loadingMore = true);
    try {
      final data = await ApiService.getAdminNotifications(category: _category, page: _page + 1);
      if (!mounted) return;
      setState(() {
        _items.addAll(_list(data));
        _page     = (data['current_page'] as num?)?.toInt() ?? _page + 1;
        _lastPage = (data['last_page'] as num?)?.toInt() ?? _lastPage;
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  static List<Map<String, dynamic>> _list(Map<String, dynamic> data) =>
      (data['notifications'] as List<dynamic>? ?? []).whereType<Map<String, dynamic>>().toList();

  Future<void> _open(Map<String, dynamic> n) async {
    final id = (n['id'] as num?)?.toInt();
    if (id != null && n['read'] != true) {
      setState(() {
        n['read'] = true;
        final all = (_counts['all'] as num? ?? 0).toInt();
        _counts['all'] = all > 0 ? all - 1 : 0;
      });
      ApiService.markAdminNotificationRead(id).catchError((_) {});
    }
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: context.appSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _DetailSheet(n: n),
    );
  }

  Future<void> _markAll() async {
    try {
      await ApiService.markAllAdminNotificationsRead();
      if (!mounted) return;
      setState(() {
        for (final n in _items) { n['read'] = true; }
        _counts['all'] = 0;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppTheme.danger, behavior: SnackBarBehavior.floating));
    }
  }

  @override
  Widget build(BuildContext context) {
    final unread = (_counts['all'] as num? ?? 0).toInt();
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: _markAll,
              child: const Text('Mark all read', style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      body: Column(children: [
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              for (final (value, label) in _filters)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_chipLabel(value, label)),
                    selected: _category == value,
                    selectedColor: AppTheme.accent.withValues(alpha: 0.18),
                    labelStyle: TextStyle(
                        color: _category == value ? AppTheme.accent : context.appTextSecondary,
                        fontWeight: FontWeight.w600, fontSize: 12),
                    onSelected: (_) {
                      if (_category == value) return;
                      setState(() => _category = value);
                      _load();
                    },
                  ),
                ),
            ],
          ),
        ),
        Expanded(child: _body()),
      ]),
    );
  }

  String _chipLabel(String? value, String label) {
    final n = (_counts[value ?? 'all'] as num? ?? 0).toInt();
    return n > 0 ? '$label ($n)' : label;
  }

  Widget _body() {
    if (_loading) return Center(child: CircularProgressIndicator(color: AppTheme.accent));
    if (_error != null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(_error!, style: TextStyle(color: context.appTextSecondary), textAlign: TextAlign.center),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: _load, child: const Text('Retry')),
      ]));
    }
    if (_items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(children: [
          const SizedBox(height: 120),
          Icon(Icons.notifications_none_rounded, size: 56, color: context.appTextSecondary),
          const SizedBox(height: 12),
          Center(child: Text('No notifications yet', style: TextStyle(color: context.appTextSecondary))),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AppTheme.accent,
      child: NotificationListener<ScrollNotification>(
        onNotification: (s) {
          if (s.metrics.pixels > s.metrics.maxScrollExtent - 200) _loadMore();
          return false;
        },
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
          itemCount: _items.length + (_loadingMore ? 1 : 0),
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            if (i >= _items.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }
            return _AlertTile(n: _items[i], onTap: () => _open(_items[i]));
          },
        ),
      ),
    );
  }
}

(IconData, Color) _style(String? type) => switch (type) {
  'PURCHASE_ORDER'  => (Icons.shopping_cart_rounded, AppTheme.success),
  'RENTAL_ORDER'    => (Icons.event_available_rounded, AppTheme.danger),
  'PAYMENT_SUCCESS' => (Icons.payments_rounded, AppTheme.accent),
  'ORDER_CANCELLED' => (Icons.block_rounded, AppTheme.warning),
  _                 => (Icons.notifications_rounded, AppTheme.accent),
};

String _when(String? iso) {
  final t = iso == null ? null : DateTime.tryParse(iso)?.toLocal();
  if (t == null) return '';
  final diff = DateTime.now().difference(t);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return DateFormat('MMM d, yyyy').format(t);
}

class _AlertTile extends StatelessWidget {
  final Map<String, dynamic> n;
  final VoidCallback onTap;
  const _AlertTile({required this.n, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _style(n['type'] as String?);
    final unread = n['read'] != true;
    return Material(
      color: unread ? color.withValues(alpha: 0.06) : context.appSurface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(n['title'] as String? ?? '',
                    style: TextStyle(color: context.appTextPrimary,
                        fontWeight: unread ? FontWeight.w800 : FontWeight.w600, fontSize: 14))),
                Text(_when(n['created_at'] as String?),
                    style: TextStyle(color: context.appTextSecondary, fontSize: 11)),
              ]),
              const SizedBox(height: 3),
              Text(n['message'] as String? ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: context.appTextPrimary, fontSize: 13)),
              if (n['detail'] != null) ...[
                const SizedBox(height: 2),
                Text(n['detail'] as String, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
              ],
            ])),
            if (unread) ...[
              const SizedBox(width: 8),
              Container(width: 8, height: 8, margin: const EdgeInsets.only(top: 6),
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            ],
          ]),
        ),
      ),
    );
  }
}

class _DetailSheet extends StatelessWidget {
  final Map<String, dynamic> n;
  const _DetailSheet({required this.n});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _style(n['type'] as String?);
    final kind = n['order_kind'] == 'car_rental' ? 'Car rental' : 'Marketplace order';
    Widget row(String label, String? value) => value == null || value.isEmpty
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(width: 90, child: Text(label, style: TextStyle(color: context.appTextSecondary, fontSize: 13))),
              Expanded(child: Text(value, style: TextStyle(color: context.appTextPrimary, fontSize: 13, fontWeight: FontWeight.w600))),
            ]),
          );

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: context.appCardBg, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Row(children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Expanded(child: Text(n['title'] as String? ?? '',
                style: TextStyle(color: context.appTextPrimary, fontSize: 17, fontWeight: FontWeight.w800))),
          ]),
          const SizedBox(height: 16),
          row('Order', n['message'] as String?),
          row('Details', n['detail'] as String?),
          row('Customer', n['customer'] as String?),
          row('Type', '$kind #${n['order_id'] ?? ''}'),
          row('Received', _when(n['created_at'] as String?)),
          const SizedBox(height: 4),
          Text('Confirm or manage this order from the web admin panel.',
              style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
        ]),
      ),
    );
  }
}
