import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  static const _seenKey = 'seen_onboarding';

  static Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_seenKey) ?? false) return true;
    // Also check server progress if user is already logged in
    try {
      final progress = await ApiService.getOnboardingProgress();
      final completed = progress['completed'] == true ||
                        progress['status'] == 'completed' ||
                        progress['status'] == 'skipped';
      if (completed) {
        await prefs.setBool(_seenKey, true);
        return true;
      }
    } catch (_) {}
    return false;
  }

  static Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seenKey, true);
  }

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _stepKeys = ['welcome', 'booking', 'wallet', 'rewards'];

  static const _pages = [
    _OnboardPage(
      icon: Icons.electric_car_outlined,
      color: Color(0xFF00B14F),
      title: 'Welcome to ROTEH',
      subtitle:
          'Your smart ride companion in Cambodia.\nFast, safe, and affordable rides at your fingertips.',
    ),
    _OnboardPage(
      icon: Icons.route_outlined,
      color: Color(0xFF2196F3),
      title: 'Book in Seconds',
      subtitle:
          'Choose your vehicle type — Car, Bike, or Tuk-Tuk.\nGet a fare estimate before you confirm.',
    ),
    _OnboardPage(
      icon: Icons.account_balance_wallet_outlined,
      color: Color(0xFFFF6B2B),
      title: 'ROTEH Pay',
      subtitle:
          'Pay by cash or use ROTEH Pay wallet.\nSend money to friends with QR code.',
    ),
    _OnboardPage(
      icon: Icons.star_rounded,
      color: Color(0xFFFFD700),
      title: 'Earn Rewards',
      subtitle:
          'Collect ROTEH Points on every trip.\nClimb from Bronze to Platinum and unlock exclusive benefits.',
    ),
  ];

  void _next() {
    // Report step completion to server (fire-and-forget)
    if (_page < _stepKeys.length) {
      ApiService.completeOnboardingStep(_stepKeys[_page]).catchError((_) {});
    }
    if (_page < _pages.length - 1) {
      _controller.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
    } else {
      _done(skip: false);
    }
  }

  Future<void> _done({bool skip = true}) async {
    if (skip) {
      ApiService.skipOnboarding().catchError((_) {});
    }
    await OnboardingScreen.markSeen();
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _done(skip: true),
                child: const Text('Skip',
                    style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600)),
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _pages.length,
                itemBuilder: (context, i) => _PageView(page: _pages[i]),
              ),
            ),

            // Dots + button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(children: [
                // Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pages.length, (i) {
                    final active = i == _page;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: active ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: active ? AppTheme.accent : AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 28),

                // CTA button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _next,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: Text(
                      _page < _pages.length - 1 ? 'Next' : 'Get Started',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageView extends StatelessWidget {
  final _OnboardPage page;
  const _PageView({required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: page.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(page.icon, color: page.color, size: 72),
          ),
          const SizedBox(height: 40),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            page.subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 15,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardPage {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  const _OnboardPage({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });
}
