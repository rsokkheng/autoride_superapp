import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../utils/app_log.dart';
import 'api_service.dart';

typedef RealtimeHandler = void Function(String event, Map<String, dynamic> data);

/// Push channel to the backend's Laravel Reverb server (Pusher protocol v7),
/// replacing the app's tight polling loops.
///
/// Events are "something changed" signals — handlers refetch through the
/// normal REST endpoint, which stays the source of truth. Screens keep a
/// slow fallback poll via [AdaptivePoller], so a dropped socket degrades
/// to the old polling behaviour instead of breaking anything.
///
/// Disabled (polling only) when REVERB_APP_KEY is missing from .env.
class RealtimeService with WidgetsBindingObserver {
  RealtimeService._() {
    WidgetsBinding.instance.addObserver(this);
  }
  static final RealtimeService instance = RealtimeService._();

  /// True while the socket is open and the handshake has completed.
  final ValueNotifier<bool> connected = ValueNotifier(false);

  final Map<String, Set<RealtimeHandler>> _handlers = {};
  final Set<String> _subscribed = {};

  WebSocketChannel? _ws;
  StreamSubscription? _wsSub;
  String? _socketId;
  Timer? _reconnectTimer;
  Timer? _activityTimer;
  Timer? _pongTimer;
  int _attempt = 0;
  bool _connecting = false;
  Duration _activityTimeout = const Duration(seconds: 30);

  static String? get _appKey {
    final k = dotenv.env['REVERB_APP_KEY'];
    return (k == null || k.isEmpty) ? null : k;
  }

  bool get isEnabled => _appKey != null;

  Uri? get _socketUri {
    final key = _appKey;
    if (key == null) return null;
    final api = Uri.tryParse(dotenv.env['BASE_URL'] ?? '');
    final scheme = dotenv.env['REVERB_SCHEME'] ?? api?.scheme ?? 'https';
    final secure = scheme == 'https' || scheme == 'wss';
    final host = dotenv.env['REVERB_HOST'] ?? api?.host;
    if (host == null || host.isEmpty) return null;
    final port = int.tryParse(dotenv.env['REVERB_PORT'] ?? '') ?? (secure ? 443 : 8080);
    return Uri(
      scheme: secure ? 'wss' : 'ws',
      host:   host,
      port:   port,
      path:   '/app/$key',
      queryParameters: const {'protocol': '7', 'client': 'dart', 'version': '1.0', 'flash': 'false'},
    );
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Listens on a private channel, e.g. `ride.42` (the `private-` prefix is
  /// added here). Connects on first use. Call [RealtimeSubscription.cancel]
  /// in dispose().
  RealtimeSubscription subscribe(String channel, RealtimeHandler handler) {
    final name = 'private-$channel';
    final set = _handlers.putIfAbsent(name, () => <RealtimeHandler>{});
    set.add(handler);

    if (isEnabled) {
      if (connected.value) {
        _subscribeOnServer(name);
      } else {
        _connect();
      }
    }
    return RealtimeSubscription._(() => _unsubscribe(name, handler));
  }

  /// Drops the socket and all listeners — call on logout.
  void disconnect() {
    _handlers.clear();
    _subscribed.clear();
    _close();
    _reconnectTimer?.cancel();
    _attempt = 0;
  }

  // ── Connection lifecycle ──────────────────────────────────────────────────

  Future<void> _connect() async {
    if (_connecting || _ws != null) return;
    final uri = _socketUri;
    if (uri == null) return;
    if (await ApiService.getToken() == null) return;

    _connecting = true;
    _reconnectTimer?.cancel();
    try {
      final ws = WebSocketChannel.connect(uri);
      _ws = ws;
      await ws.ready;
      _wsSub = ws.stream.listen(
        _onFrame,
        onError: (Object e) {
          AppLog.w('Realtime', 'socket error: $e');
          _onClosed();
        },
        onDone: _onClosed,
        cancelOnError: true,
      );
    } catch (e) {
      AppLog.w('Realtime', 'connect to $uri failed: $e');
      _onClosed();
    } finally {
      _connecting = false;
    }
  }

  void _onClosed() {
    _close();
    if (_handlers.isEmpty) return;
    // Exponential backoff with jitter (1s, 2s, 4s … capped at 30s) so a
    // Reverb restart doesn't get every app reconnecting in the same second.
    final base = min(30, 1 << min(_attempt, 5));
    final delay = Duration(milliseconds: base * 1000 + Random().nextInt(1000));
    _attempt++;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, _connect);
  }

  void _close() {
    _activityTimer?.cancel();
    _pongTimer?.cancel();
    _wsSub?.cancel();
    _wsSub = null;
    _ws?.sink.close();
    _ws = null;
    _socketId = null;
    _subscribed.clear();
    if (connected.value) connected.value = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The OS often kills sockets while backgrounded — reconnect right away
    // on resume instead of waiting out the backoff.
    if (state == AppLifecycleState.resumed && _handlers.isNotEmpty && _ws == null) {
      _attempt = 0;
      _connect();
    }
  }

  // ── Protocol ──────────────────────────────────────────────────────────────

  void _onFrame(dynamic raw) {
    _resetActivityTimer();
    final Map<String, dynamic> msg;
    try {
      msg = jsonDecode(raw as String) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    final event = msg['event'] as String? ?? '';
    final data = _decodeData(msg['data']);

    switch (event) {
      case 'pusher:connection_established':
        _socketId = data['socket_id'] as String?;
        final timeout = data['activity_timeout'];
        if (timeout is num && timeout > 0) {
          _activityTimeout = Duration(seconds: timeout.toInt());
        }
        _attempt = 0;
        connected.value = true;
        for (final name in _handlers.keys.toList()) {
          _subscribeOnServer(name);
        }
        _resetActivityTimer();
      case 'pusher:ping':
        _send({'event': 'pusher:pong', 'data': {}});
      case 'pusher:pong':
        _pongTimer?.cancel();
      case 'pusher:error':
        AppLog.w('Realtime', 'server error: $data');
        final code = data['code'];
        // 4000–4099: don't retry (bad app key, over quota, etc.)
        if (code is int && code >= 4000 && code < 4100) {
          _handlers.clear();
          _close();
        }
      case 'pusher_internal:subscription_succeeded':
        break;
      default:
        final channel = msg['channel'] as String?;
        final handlers = channel == null ? null : _handlers[channel];
        if (handlers == null) return;
        for (final h in handlers.toList()) {
          try {
            h(event, data);
          } catch (e, s) {
            AppLog.e('Realtime', 'handler for $event threw', e, s);
          }
        }
    }
  }

  Future<void> _subscribeOnServer(String name) async {
    final socketId = _socketId;
    if (socketId == null || _subscribed.contains(name)) return;
    _subscribed.add(name);
    try {
      final auth = await ApiService.authorizeChannel(socketId: socketId, channelName: name);
      // Socket may have been replaced, or the screen gone, while awaiting auth.
      if (socketId != _socketId || !_handlers.containsKey(name)) return;
      _send({
        'event': 'pusher:subscribe',
        'data': {'channel': name, 'auth': auth},
      });
    } catch (e) {
      _subscribed.remove(name);
      AppLog.w('Realtime', 'auth for $name failed: $e');
    }
  }

  void _unsubscribe(String name, RealtimeHandler handler) {
    final set = _handlers[name];
    if (set == null) return;
    set.remove(handler);
    if (set.isNotEmpty) return;
    _handlers.remove(name);
    if (_subscribed.remove(name)) {
      _send({'event': 'pusher:unsubscribe', 'data': {'channel': name}});
    }
    if (_handlers.isEmpty) {
      _close();
      _reconnectTimer?.cancel();
    }
  }

  void _send(Map<String, dynamic> msg) {
    try {
      _ws?.sink.add(jsonEncode(msg));
    } catch (_) {}
  }

  // Client-side keepalive: if the server goes quiet for activity_timeout,
  // ping it; no pong within 30s means the connection is dead.
  void _resetActivityTimer() {
    _activityTimer?.cancel();
    _activityTimer = Timer(_activityTimeout, () {
      _send({'event': 'pusher:ping', 'data': {}});
      _pongTimer?.cancel();
      _pongTimer = Timer(const Duration(seconds: 30), _onClosed);
    });
  }

  static Map<String, dynamic> _decodeData(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is String && data.isNotEmpty) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {}
    }
    return const {};
  }
}

class RealtimeSubscription {
  RealtimeSubscription._(this._cancel);
  final void Function() _cancel;
  bool _cancelled = false;

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    _cancel();
  }
}

/// Poll loop that runs at [fastInterval] when the realtime socket is down
/// (the old behaviour) and backs off to [slowInterval] as a safety net while
/// push events are flowing. Call [pokeNow] from a realtime handler.
class AdaptivePoller {
  AdaptivePoller({
    required this.onPoll,
    required this.fastInterval,
    this.slowInterval = const Duration(seconds: 30),
  });

  final Future<void> Function() onPoll;
  final Duration fastInterval;
  final Duration slowInterval;

  Timer? _timer;
  bool _running = false;
  bool _inFlight = false;

  bool get isRunning => _running;

  void start({bool immediately = false}) {
    if (_running) return;
    _running = true;
    RealtimeService.instance.connected.addListener(_reschedule);
    if (immediately) {
      pokeNow();
    } else {
      _schedule();
    }
  }

  void stop() {
    _running = false;
    _timer?.cancel();
    _timer = null;
    RealtimeService.instance.connected.removeListener(_reschedule);
  }

  /// Poll right now (e.g. a push event arrived), then resume the schedule.
  Future<void> pokeNow() async {
    if (!_running || _inFlight) return;
    _timer?.cancel();
    _inFlight = true;
    try {
      await onPoll();
    } finally {
      _inFlight = false;
      if (_running) _schedule();
    }
  }

  void _reschedule() {
    if (_running && !_inFlight) _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    final interval = RealtimeService.instance.connected.value ? slowInterval : fastInterval;
    _timer = Timer(interval, pokeNow);
  }
}
