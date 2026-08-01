import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../screens/auth/login_screen.dart';

/// Force-logs-out the user after a period of no interaction, instead of the
/// old behaviour of forcing logout on every 401 (see [ApiService]'s
/// automatic refresh-token retry, which now handles expired-access-token
/// 401s silently). Idle time keeps counting while the app is backgrounded,
/// matching typical ride-hailing app session behaviour (e.g. Grab).
class IdleTimeoutWrapper extends StatefulWidget {
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  const IdleTimeoutWrapper({
    super.key,
    required this.child,
    required this.navigatorKey,
  });

  @override
  State<IdleTimeoutWrapper> createState() => _IdleTimeoutWrapperState();
}

class _IdleTimeoutWrapperState extends State<IdleTimeoutWrapper>
    with WidgetsBindingObserver {
  static const _idleTimeout = Duration(minutes: 20);

  DateTime _lastActivity = DateTime.now();
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) => _checkIdle());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkIdle();
  }

  void _resetActivity() => _lastActivity = DateTime.now();

  Future<void> _checkIdle() async {
    if (DateTime.now().difference(_lastActivity) < _idleTimeout) return;

    final token = await ApiService.getToken();
    if (token == null) {
      _resetActivity();
      return;
    }

    final nav = widget.navigatorKey.currentState;
    if (nav == null) return;

    await ApiService.clearSession();
    nav.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
    _resetActivity();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _resetActivity(),
      onPointerMove: (_) => _resetActivity(),
      onPointerUp: (_) => _resetActivity(),
      child: widget.child,
    );
  }
}
