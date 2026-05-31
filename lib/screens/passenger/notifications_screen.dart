import 'package:flutter/material.dart';
import 'package:autoride_superapp/theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final Set<int> _read = {};

  static const _notifications = [
    _Notif(id: 0, title: 'Driver Found!', body: 'Chantha M. is on the way • ETA 8 min', time: 'Just now', type: _NotifType.ride, unread: true),
    _Notif(id: 1, title: 'Payment Successful', body: '\$3.50 paid via ABA Bank for your trip to Royal Palace', time: '2h ago', type: _NotifType.payment, unread: true),
    _Notif(id: 2, title: '🎉 Promo Unlocked', body: 'You earned 15% off your next ride! Valid for 24 hours.', time: '5h ago', type: _NotifType.promo, unread: true),
    _Notif(id: 3, title: 'Driver Arrived', body: 'Dara K. is waiting at BKK Market', time: 'Yesterday', type: _NotifType.ride, unread: false),
    _Notif(id: 4, title: 'Delivery Picked Up', body: 'Your package has been picked up and is on the way', time: 'Yesterday', type: _NotifType.delivery, unread: false),
    _Notif(id: 5, title: 'Top-up Successful', body: '\$20.00 added to your AutoRide Pay wallet via ABA', time: 'May 22', type: _NotifType.payment, unread: false),
    _Notif(id: 6, title: 'Rate Your Trip', body: 'How was your trip with Vanna S.? Share your experience!', time: 'May 22', type: _NotifType.rating, unread: false),
    _Notif(id: 7, title: 'Safety Alert', body: 'Your live location was shared with your emergency contact', time: 'May 20', type: _NotifType.safety, unread: false),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () => setState(() => _read.addAll(_notifications.map((n) => n.id))),
            child: const Text('Mark all read', style: TextStyle(color: AppTheme.accent, fontSize: 13)),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _notifications.length,
        itemBuilder: (_, i) {
          final n = _notifications[i];
          final isRead = _read.contains(n.id) || !n.unread;
          return GestureDetector(
            onTap: () => setState(() => _read.add(n.id)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              color: isRead ? Colors.transparent : AppTheme.accent.withValues(alpha: 0.05),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _typeColor(n.type).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_typeIcon(n.type), color: _typeColor(n.type), size: 20),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(
                      child: Text(n.title,
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: isRead ? FontWeight.w500 : FontWeight.w800,
                            fontSize: 14,
                          )),
                    ),
                    if (!isRead)
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.accent, shape: BoxShape.circle)),
                  ]),
                  const SizedBox(height: 4),
                  Text(n.body, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4)),
                  const SizedBox(height: 4),
                  Text(n.time, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                ])),
              ]),
            ),
          );
        },
      ),
    );
  }

  Color _typeColor(_NotifType type) {
    switch (type) {
      case _NotifType.ride:     return AppTheme.accent;
      case _NotifType.payment:  return AppTheme.success;
      case _NotifType.promo:    return AppTheme.warning;
      case _NotifType.delivery: return AppTheme.accentOrange;
      case _NotifType.rating:   return AppTheme.gold;
      case _NotifType.safety:   return AppTheme.danger;
    }
  }

  IconData _typeIcon(_NotifType type) {
    switch (type) {
      case _NotifType.ride:     return Icons.directions_car_outlined;
      case _NotifType.payment:  return Icons.payment_outlined;
      case _NotifType.promo:    return Icons.local_offer_outlined;
      case _NotifType.delivery: return Icons.delivery_dining_outlined;
      case _NotifType.rating:   return Icons.star_outline;
      case _NotifType.safety:   return Icons.shield_outlined;
    }
  }
}

enum _NotifType { ride, payment, promo, delivery, rating, safety }

class _Notif {
  final int id;
  final String title, body, time;
  final _NotifType type;
  final bool unread;
  const _Notif({required this.id, required this.title, required this.body, required this.time, required this.type, required this.unread});
}
