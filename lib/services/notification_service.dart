import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../utils/app_log.dart';
import 'api_service.dart';

// Mirrors the backend's FcmService::TYPE_SOUNDS map — keep both in sync.
// channelId must match an AndroidNotificationChannel created in
// NotificationService.initialize(), and asset must match a file under
// assets/sounds/ (foreground playback) and android/.../res/raw +
// ios/Runner (channel/native sound, filename minus extension).
const Map<String, ({String channelId, String asset})> _typeSounds = {
  'ride_requested':      (channelId: 'booking_alerts', asset: 'booking'),
  'delivery_requested':  (channelId: 'booking_alerts', asset: 'booking'),
  'ride_accepted':       (channelId: 'ride_updates',   asset: 'accepted'),
  'delivery_accepted':   (channelId: 'ride_updates',   asset: 'accepted'),
};

// Must be a top-level (or static) function — FCM invokes this in a
// separate isolate when a message arrives while the app is fully
// terminated/backgrounded. Registered via
// FirebaseMessaging.onBackgroundMessage in main().
//
// A "notification"-type payload is shown by the OS automatically with no
// app code needing to run. But a data-only payload (no top-level
// "notification" key — which is what the backend's ride_requested push
// looks like, going by its apns.payload.aps having no "alert") shows
// NOTHING unless this handler explicitly displays a local notification.
// That silent gap is almost certainly why backgrounded/locked-screen
// drivers never see or hear a new-booking alert.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (message.notification != null) return; // OS already showed it
  final data = message.data;
  final title = data['title'] as String? ?? '🚗 New Ride Request';
  final body  = data['body']  as String? ??
      [data['pickup'], data['destination']].where((s) => s != null).join(' → ');
  if (body.isEmpty) return;

  final plugin = FlutterLocalNotificationsPlugin();
  await plugin.initialize(const InitializationSettings(
    android: AndroidInitializationSettings('@drawable/ic_notification'),
    iOS: DarwinInitializationSettings(),
  ));
  // Backend already sends data.channel_id matching the channel it targeted;
  // fall back to the type map only if that's missing.
  final channelId = data['channel_id'] as String? ??
      _typeSounds[data['type']]?.channelId ??
      'ride_channel';
  final isBooking = channelId == 'booking_alerts';
  await plugin.show(
    isBooking ? 1 : 2,
    title,
    body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        isBooking ? 'Booking Alerts' : 'Ride Notifications',
        channelDescription: isBooking
            ? 'New ride and delivery request alerts'
            : 'Ride notifications',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        sound: isBooking
            ? const RawResourceAndroidNotificationSound('booking')
            : null,
        enableVibration: true,
        visibility: NotificationVisibility.public,
        icon: '@drawable/ic_notification',
      ),
      iOS: const DarwinNotificationDetails(presentAlert: true, presentSound: true),
    ),
    payload: data['type'] as String?,
  );
}

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  static NotificationService get instance => _instance;
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  final _audioPlayer = AudioPlayer();
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

  // Matches the backend's intended channel for ride_requested /
  // delivery_requested pushes. Sound file must exist as
  // android/app/src/main/res/raw/booking.wav — Android channel sound can't
  // be changed after the channel is first created on-device.
  static const _bookingChannel = AndroidNotificationChannel(
    'booking_alerts',
    'Booking Alerts',
    description: 'New ride and delivery request alerts',
    importance: Importance.max,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('booking'),
  );

  // Matches the backend's channel for ride_accepted / delivery_accepted
  // pushes. Sound file must exist as
  // android/app/src/main/res/raw/accepted.wav.
  static const _rideUpdatesChannel = AndroidNotificationChannel(
    'ride_updates',
    'Ride Updates',
    description: 'Ride and delivery acceptance updates',
    importance: Importance.high,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('accepted'),
  );

  Future<void> initialize() async {
    if (_initialized) return;

    const androidInit = AndroidInitializationSettings('@drawable/ic_notification');
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
    await androidPlugin?.createNotificationChannel(_bookingChannel);
    await androidPlugin?.createNotificationChannel(_rideUpdatesChannel);
    await androidPlugin?.requestNotificationsPermission();

    _initialized = true;
  }

  // ── Push notifications (FCM) ────────────────────────────────────────────
  // This is what actually delivers alerts while the app is backgrounded or
  // the phone is locked — local notifications triggered from in-app Dart
  // code (timers, Firestore listeners, polling) can't fire once the OS
  // suspends the app. A real push, sent by the backend, wakes the device
  // and shows a system notification regardless of app state.

  bool _fcmInitialized = false;

  /// Requests notification permission, registers the device's FCM token
  /// with the backend, and wires up foreground message handling. Call once
  /// the user is authenticated (right after login, and again on app start
  /// if a session already exists) — registering a token requires an auth
  /// token, which is why this is separate from `initialize()`.
  ///
  /// Single backend call for every role — the backend auto-inserts into
  /// the driver_devices multi-device registry when the caller is a driver.
  bool _fcmInitializing = false;

  Future<void> initFcm() async {
    if (_fcmInitialized || _fcmInitializing) return;
    _fcmInitializing = true;

    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true, badge: true, sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        AppLog.w('FCM', 'Notification permission denied');
        _fcmInitialized = true; // no point retrying until the user re-grants it
        return;
      }

      // On iOS, getToken() internally needs the APNS token, which Apple
      // delivers to the app asynchronously — calling getToken() right
      // after requestPermission() can race ahead of it and throw
      // apns-token-not-set. Wait for it (briefly) first.
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        var apnsToken = await messaging.getAPNSToken();
        var attempts = 0;
        while (apnsToken == null && attempts < 10) {
          await Future.delayed(const Duration(milliseconds: 500));
          apnsToken = await messaging.getAPNSToken();
          attempts++;
        }
        if (apnsToken == null) {
          AppLog.w('FCM', 'APNS token never arrived — skipping FCM token fetch');
          return;
        }
      }

      await _sendTokenToBackend(await messaging.getToken());
      messaging.onTokenRefresh.listen(_sendTokenToBackend);

      // App in foreground: FCM doesn't show a system notification itself,
      // so surface it via the existing local-notification channel. Also
      // handles data-only payloads (message.notification == null), which
      // is what the backend's ride_requested/delivery_requested push
      // looks like — falling back to that silently was the actual cause
      // of drivers never seeing/hearing new-booking alerts.
      FirebaseMessaging.onMessage.listen((message) {
        final data = message.data;
        final type = data['type'] as String?;
        final title = message.notification?.title ?? data['title'] as String?;
        final body  = message.notification?.body  ?? data['body']  as String? ??
            [data['pickup'], data['destination']].where((s) => s != null).join(' → ');
        if ((title == null || title.isEmpty) && body.isEmpty) return;

        // Native push sound doesn't play while the app is foregrounded, so
        // play the matching local asset explicitly. data.sound is sent by
        // the backend; fall back to the type map if it's missing.
        final soundAsset = data['sound'] as String? ?? _typeSounds[type]?.asset;
        if (soundAsset != null) {
          _audioPlayer.play(AssetSource('sounds/$soundAsset.wav'));
        }

        if (type == 'ride_requested' || type == 'delivery_requested') {
          showRideRequest(
            passengerName: data['passenger_name'] as String? ?? 'New request',
            pickup:        data['pickup'] as String? ?? '',
            destination:   data['destination'] as String? ?? '',
            fare:          data['fare'] as String? ?? '',
          );
        } else if (type == 'ride_accepted' || type == 'delivery_accepted') {
          showRideAccepted(title: title ?? 'ROTEH', body: body);
        } else {
          showTripUpdate(title: title ?? 'ROTEH', body: body, payload: type);
        }
      });
      _fcmInitialized = true;
    } catch (e, s) {
      AppLog.e('FCM', 'initFcm failed', e, s);
      // Leave _fcmInitialized false so a later call (e.g. next screen,
      // next app launch) can retry.
    } finally {
      _fcmInitializing = false;
    }
  }

  Future<void> _sendTokenToBackend(String? fcmToken) async {
    if (fcmToken == null || fcmToken.isEmpty) return;
    await ApiService.saveFcmToken(
      fcmToken,
      platform: defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
    );
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
          _bookingChannel.id,
          _bookingChannel.name,
          channelDescription: _bookingChannel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@drawable/ic_notification',
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

  Future<void> showRideAccepted({
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      2,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _rideUpdatesChannel.id,
          _rideUpdatesChannel.name,
          channelDescription: _rideUpdatesChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/ic_notification',
          color: const Color(0xFF00D4AA),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'ride_accepted',
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
          icon: '@drawable/ic_notification',
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
          icon: '@drawable/ic_notification',
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
          icon: '@drawable/ic_notification',
          color: const Color(0xFF00D4AA),
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: 'payment_success',
    );
  }

  Future<void> cancelAll() async => _plugin.cancelAll();
}
