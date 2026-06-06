import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import 'auth/login_screen.dart';
import 'passenger/passenger_home.dart';
import 'driver/driver_home.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── controllers ─────────────────────────────────────────
  late final AnimationController _bgCtrl;     // particle drift
  late final AnimationController _rippleCtrl; // logo rings
  late final AnimationController _logoCtrl;   // logo pop-in
  late final AnimationController _textCtrl;   // name + tagline
  late final AnimationController _chipsCtrl;  // service chips
  late final AnimationController _barCtrl;    // progress bar
  late final AnimationController _exitCtrl;   // fade out

  // ── animations ──────────────────────────────────────────
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _nameOpacity;
  late final Animation<Offset>  _nameSlide;
  late final Animation<double> _taglineOpacity;
  late final Animation<double> _barProgress;
  late final Animation<double> _exitOpacity;

  // Staggered chip animations (4 services)
  late final List<Animation<double>> _chipScales;
  late final List<Animation<double>> _chipOpacities;

  @override
  void initState() {
    super.initState();
    _buildControllers();
    _buildAnimations();
    _runSequence();
  }

  void _buildControllers() {
    _bgCtrl     = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
    _rippleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();
    _logoCtrl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _textCtrl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _chipsCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _barCtrl    = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));
    _exitCtrl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  }

  void _buildAnimations() {
    // Logo
    _logoScale   = CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut)
        .drive(Tween(begin: 0.0, end: 1.0));
    _logoOpacity = CurvedAnimation(parent: _logoCtrl, curve: const Interval(0, 0.4))
        .drive(Tween(begin: 0.0, end: 1.0));

    // Name
    _nameSlide   = CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut)
        .drive(Tween(begin: const Offset(0, 0.35), end: Offset.zero));
    _nameOpacity = _textCtrl.drive(Tween(begin: 0.0, end: 1.0));

    // Tagline lags behind name a bit
    _taglineOpacity = CurvedAnimation(parent: _textCtrl, curve: const Interval(0.3, 1))
        .drive(Tween(begin: 0.0, end: 1.0));

    // Chips — staggered per chip
    _chipScales   = List.generate(4, (i) {
      final start = i * 0.18;
      return CurvedAnimation(
        parent: _chipsCtrl,
        curve: Interval(start, (start + 0.45).clamp(0.0, 1.0), curve: Curves.elasticOut),
      ).drive(Tween(begin: 0.0, end: 1.0));
    });
    _chipOpacities = List.generate(4, (i) {
      final start = i * 0.18;
      return CurvedAnimation(
        parent: _chipsCtrl,
        curve: Interval(start, (start + 0.3).clamp(0.0, 1.0)),
      ).drive(Tween(begin: 0.0, end: 1.0));
    });

    // Progress bar
    _barProgress = CurvedAnimation(parent: _barCtrl, curve: Curves.easeInOut)
        .drive(Tween(begin: 0.0, end: 1.0));

    // Exit fade
    _exitOpacity = _exitCtrl.drive(Tween(begin: 1.0, end: 0.0));
  }

  Future<void> _runSequence() async {
    // Step 1 — logo pops in
    await Future.delayed(const Duration(milliseconds: 300));
    _logoCtrl.forward();

    // Step 2 — name slides up
    await Future.delayed(const Duration(milliseconds: 500));
    _textCtrl.forward();

    // Step 3 — chips + bar start together
    await Future.delayed(const Duration(milliseconds: 350));
    _chipsCtrl.forward();
    _barCtrl.forward();

    // Step 4 — check session then fade out and push
    await Future.delayed(const Duration(milliseconds: 2400));
    if (!mounted) return;

    final role = await ApiService.getRole();
    if (!mounted) return;

    await _exitCtrl.forward();
    if (!mounted) return;

    Widget destination;
    if (role == 'driver') {
      destination = const DriverHomeScreen();
    } else if (role == 'passenger') {
      destination = const PassengerHomeScreen();
    } else {
      destination = const LoginScreen();
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) => destination,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _rippleCtrl.dispose();
    _logoCtrl.dispose();
    _textCtrl.dispose();
    _chipsCtrl.dispose();
    _barCtrl.dispose();
    _exitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final size = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: _exitOpacity,
      builder: (_, child) => Opacity(opacity: _exitOpacity.value, child: child),
      child: Scaffold(
        backgroundColor: AppTheme.primary,
        body: Stack(
          children: [
            // ── Layer 1: animated particle background ──────────
            AnimatedBuilder(
              animation: _bgCtrl,
              builder: (_, __) => CustomPaint(
                painter: _ParticlePainter(_bgCtrl.value, size),
                size: Size.infinite,
              ),
            ),

            // ── Layer 2: decorative arcs (top-right + bottom-left) ──
            CustomPaint(
              painter: _ArcPainter(),
              size: Size.infinite,
            ),

            // ── Layer 3: content ───────────────────────────────
            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 3),

                  // ── Logo cluster ─────────────────────────────
                  AnimatedBuilder(
                    animation: Listenable.merge([_logoCtrl, _rippleCtrl]),
                    builder: (_, __) => Opacity(
                      opacity: _logoOpacity.value,
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: _LogoCluster(ripple: _rippleCtrl.value),
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),

                  // ── App name ──────────────────────────────────
                  SlideTransition(
                    position: _nameSlide,
                    child: FadeTransition(
                      opacity: _nameOpacity,
                      child: Column(children: [
                        // "AutoRide" letterpress
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFFFFFFFF), Color(0xFFB0E6DD)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds),
                          child: const Text(
                            'ROTEH', // Updated app name
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 44,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                              height: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Tagline
                        FadeTransition(
                          opacity: _taglineOpacity,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 5),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: AppTheme.accent.withValues(alpha: 0.4),
                                  width: 1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              l.tagline.toUpperCase(),
                              style: const TextStyle(
                                color: AppTheme.accent,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 4,
                              ),
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ),

                  const SizedBox(height: 52),

                  // ── Service chips (staggered) ─────────────────
                  AnimatedBuilder(
                    animation: _chipsCtrl,
                    builder: (_, __) => Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _ServiceChip(
                          icon: Icons.directions_car_outlined,
                          label: l.bookRide,
                          color: AppTheme.accent,
                          scale: _chipScales[0].value,
                          opacity: _chipOpacities[0].value,
                        ),
                        const SizedBox(width: 12),
                        _ServiceChip(
                          icon: Icons.delivery_dining_outlined,
                          label: l.delivery,
                          color: AppTheme.accentOrange,
                          scale: _chipScales[1].value,
                          opacity: _chipOpacities[1].value,
                        ),
                        const SizedBox(width: 12),
                        _ServiceChip(
                          icon: Icons.store_outlined,
                          label: l.marketplace,
                          color: const Color(0xFF9C27B0),
                          scale: _chipScales[2].value,
                          opacity: _chipOpacities[2].value,
                        ),
                        const SizedBox(width: 12),
                        _ServiceChip(
                          icon: Icons.ev_station_outlined,
                          label: l.evStations,
                          color: AppTheme.warning,
                          scale: _chipScales[3].value,
                          opacity: _chipOpacities[3].value,
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 3),

                  // ── Progress bar ──────────────────────────────
                  AnimatedBuilder(
                    animation: _barProgress,
                    builder: (_, __) => _ProgressBar(
                      progress: _barProgress.value,
                      size: size,
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Logo cluster — glowing rings + icon
// ─────────────────────────────────────────────────────────────
class _LogoCluster extends StatelessWidget {
  final double ripple;

  const _LogoCluster({required this.ripple});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ripple ring 1
          _Ring(
            size: 170 + 20 * math.sin(ripple * math.pi * 2),
            color: AppTheme.accent,
            opacity: (1 - ripple) * 0.25,
            width: 1.5,
          ),
          // Outer ripple ring 2 (offset phase)
          _Ring(
            size: 150 + 16 * math.sin((ripple + 0.4) * math.pi * 2),
            color: AppTheme.accent,
            opacity: 0.15,
            width: 1,
          ),
          // Static decorative ring
          _Ring(size: 130, color: AppTheme.accent, opacity: 0.12, width: 1),

          // Glowing background blob
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.accent.withValues(alpha: 0.25),
                  AppTheme.cardBg.withValues(alpha: 0.9),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accent.withValues(alpha: 0.35),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
              ],
            ),
          ),

          // Inner solid circle
          Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF0F4040), Color(0xFF00D4AA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // App icon
          const Icon(
            Icons.electric_car_rounded,
            color: Colors.white,
            size: 48,
          ),

          // Small delivery bike badge (bottom-right)
          Positioned(
            right: 20,
            bottom: 18,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppTheme.accentOrange,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primary, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentOrange.withValues(alpha: 0.5),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Icon(Icons.delivery_dining,
                  color: Colors.white, size: 18),
            ),
          ),

          // Small EV badge (top-right)
          Positioned(
            right: 18,
            top: 18,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppTheme.warning,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primary, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.warning.withValues(alpha: 0.5),
                    blurRadius: 10,
                  ),
                ],
              ),
              child:
                  const Icon(Icons.bolt_rounded, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  final double size, opacity, width;
  final Color color;

  const _Ring(
      {required this.size,
      required this.color,
      required this.opacity,
      required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: opacity), width: width),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Service chip
// ─────────────────────────────────────────────────────────────
class _ServiceChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final double scale, opacity;

  const _ServiceChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.scale,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Transform.scale(
        scale: scale.clamp(0.0, 1.0),
        child: Column(children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Progress bar
// ─────────────────────────────────────────────────────────────
class _ProgressBar extends StatelessWidget {
  final double progress;
  final Size size;

  const _ProgressBar({required this.progress, required this.size});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppTheme.surface,
            valueColor: AlwaysStoppedAnimation(
              Color.lerp(AppTheme.accent, AppTheme.accentOrange, progress)!,
            ),
            minHeight: 3,
          ),
        ),
      ),
      const SizedBox(height: 14),
      Text(
        progress < 0.5 ? 'Initializing services...' : 'Almost ready...',
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 12,
          letterSpacing: 0.5,
        ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────
// Particle painter — floating dots drift upward
// ─────────────────────────────────────────────────────────────
class _ParticlePainter extends CustomPainter {
  final double t;
  final Size canvasSize;

  _ParticlePainter(this.t, this.canvasSize);

  static final List<_Particle> _particles = List.generate(30, (i) {
    final rng = math.Random(i * 31 + 7);
    return _Particle(
      x: rng.nextDouble(),
      baseY: rng.nextDouble(),
      radius: 1.5 + rng.nextDouble() * 3,
      speed: 0.04 + rng.nextDouble() * 0.08,
      opacity: 0.05 + rng.nextDouble() * 0.12,
      color: i % 4 == 0
          ? AppTheme.accentOrange
          : i % 4 == 1
              ? AppTheme.warning
              : AppTheme.accent,
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final y = ((p.baseY - t * p.speed) % 1.0 + 1.0) % 1.0;
      final paint = Paint()
        ..color = p.color.withValues(alpha: p.opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(p.x * size.width, y * size.height),
        p.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.t != t;
}

class _Particle {
  final double x, baseY, radius, speed, opacity;
  final Color color;

  const _Particle({
    required this.x,
    required this.baseY,
    required this.radius,
    required this.speed,
    required this.opacity,
    required this.color,
  });
}

// ─────────────────────────────────────────────────────────────
// Arc painter — decorative curved arcs in corners
// ─────────────────────────────────────────────────────────────
class _ArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintTeal = Paint()
      ..color = AppTheme.accent.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 60;

    final paintOrange = Paint()
      ..color = AppTheme.accentOrange.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 50;

    // Top-right arc
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.width, 0),
        width: size.width * 0.9,
        height: size.width * 0.9,
      ),
      math.pi * 0.5,
      math.pi * 0.5,
      false,
      paintTeal,
    );

    // Bottom-left arc
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(0, size.height),
        width: size.width * 0.8,
        height: size.width * 0.8,
      ),
      math.pi * 1.5,
      math.pi * 0.5,
      false,
      paintOrange,
    );

    // Center subtle glow ring
    canvas.drawCircle(
      Offset(size.width / 2, size.height * 0.42),
      size.width * 0.38,
      Paint()
        ..color = AppTheme.accent.withValues(alpha: 0.04)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) => false;
}
