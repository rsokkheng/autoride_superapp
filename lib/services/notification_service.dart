import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  static NotificationService get instance => _instance;
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _rideChannel = AndroidNotificationChannel(
    'ride_channel',
    'Ride Notifications',
    description: 'Notifications for ride requests and trip updates',
    importance: Importance.high,
    playSound: true,
  );

  static const _deliveryChannel = AndroidNotificationChannel(
    'delivery_channel',
    'Delivery Notifications',
    description: 'Notifications for delivery status',
    importance: Importance.defaultImportance,
  );

  Future<void> initialize() async {
    if (_initialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_rideChannel);
    await androidPlugin?.createNotificationChannel(_deliveryChannel);
    await androidPlugin?.requestNotificationsPermission();

    _initialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    if (kDebugMode) print('Notification tapped: ${response.payload}');
  }

  Future<void> showRideRequest({
    required String passengerName,
    required String pickup,
    required String destination,
    required String fare,
  }) async {
    await _plugin.show(
      1,
      '🚗 New Ride Request',
      '$passengerName • $pickup → $destination • $fare',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _rideChannel.id,
          _rideChannel.name,
          channelDescription: _rideChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF00D4AA),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'ride_request',
    );
  }

  Future<void> showTripUpdate({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _plugin.show(
      2,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _rideChannel.id,
          _rideChannel.name,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: payload ?? 'trip_update',
    );
  }

  Future<void> showDeliveryUpdate({
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      3,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _deliveryChannel.id,
          _deliveryChannel.name,
          channelDescription: _deliveryChannel.description,
          importance: Importance.defaultImportance,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: 'delivery_update',
    );
  }

  Future<void> showPaymentSuccess({
    required String amount,
    required String method,
  }) async {
    await _plugin.show(
      4,
      '✅ Payment Successful',
      '$amount paid via $method',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _rideChannel.id,
          _rideChannel.name,
          importance: Importance.defaultImportance,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF00D4AA),
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: 'payment_success',
    );
  }

  Future<void> cancelAll() async => _plugin.cancelAll();
}
