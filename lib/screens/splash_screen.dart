import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import 'auth/login_screen.dart';
import 'onboarding/onboarding_screen.dart';
import 'passenger/passenger_home.dart';
import 'driver/driver_home.dart';
import 'admin/admin_dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _logoScale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut)
        .drive(Tween(begin: 0.7, end: 1.0));
    _logoOpacity = CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.5))
        .drive(Tween(begin: 0.0, end: 1.0));
    _ctrl.forward();
    _timer = Timer(const Duration(milliseconds: 1800), _runSequence);
  }

  Future<void> _runSequence() async {
    if (!mounted) return;

    final role = await ApiService.getRole();
    if (!mounted) return;

    Widget destination;
    if (role == 'admin') {
      destination = const AdminDashboardScreen();
    } else if (role == 'driver') {
      destination = const DriverHomeScreen();
    } else if (role == 'passenger') {
      destination = const PassengerHomeScreen();
    } else {
      final seenOnboarding = await OnboardingScreen.hasSeenOnboarding();
      destination = seenOnboarding ? const LoginScreen() : const OnboardingScreen();
    }

    // Register this device for push notifications if a session already
    // exists — fire-and-forget, shouldn't block navigation.
    if (role == 'admin' || role == 'driver' || role == 'passenger') {
      NotificationService.instance.initFcm();
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => destination,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor:           Colors.transparent,
        statusBarIconBrightness:  Brightness.light,
        statusBarBrightness:      Brightness.dark,
        systemNavigationBarColor: AppTheme.accent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppTheme.white,
        extendBodyBehindAppBar: true,
        body: Center(
         child: Column(
          mainAxisSize: MainAxisSize.min, // Keeps the column wrapped tightly around its children
          children: [
            AnimatedBuilder(
              animation: _ctrl,
              builder: (_, child) => Opacity(
                opacity: _logoOpacity.value,
                child: Transform.scale(scale: _logoScale.value, child: child),
              ),
              child: Image.asset(
                'assets/library/icon_fa.png',
                width: 120,
                height: 120,
              ),
            ),
            
          const SizedBox(height: 8), // Adds spacing between the logo and the text
           const Text(
            'ROTEH APP',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.accent, // <-- Add your desired color here
            ),
          ),
          ],
        ),
        ),
      ),
    );
  }
}
