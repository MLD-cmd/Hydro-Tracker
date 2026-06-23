import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/settings_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import '../widgets/gradient_background.dart';
import 'dashboard_screen.dart';
import 'onboarding_screen.dart';
import 'sign_in_screen.dart';

/// The first screen on launch: the HydroTracker logo bouncing while settings
/// load. After a short beat it hands off to onboarding (first run) or sign in.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounce = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final repo = SettingsRepository();
    // Load settings, but keep the splash up for at least a beat so the logo
    // gets to bounce before we move on.
    await Future.wait([
      repo.load(),
      Future.delayed(const Duration(milliseconds: 2000)),
    ]);
    if (!mounted) return;
    // A restored Supabase session means the user is still signed in — skip
    // straight to the app. Otherwise route by whether they've onboarded.
    final Widget next;
    if (AuthService.instance.isSignedIn) {
      next = const DashboardScreen();
    } else {
      next = repo.settings.onboarded
          ? const SignInScreen()
          : const OnboardingScreen();
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => next),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _bounce,
                builder: (context, child) {
                  final t = Curves.easeInOut.transform(_bounce.value);
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.translate(
                        offset: Offset(0, -30 * t),
                        child: child,
                      ),
                      const SizedBox(height: 16),
                      // A soft shadow that spreads and darkens as the logo nears
                      // the ground — the classic bouncing-ball cue.
                      Transform.scale(
                        scaleX: 0.65 + 0.35 * (1 - t),
                        child: Container(
                          width: 80,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppColors.primary
                                .withValues(alpha: 0.05 + 0.12 * (1 - t)),
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                      ),
                    ],
                  );
                },
                child: const AppLogo(size: 116),
              ),
              const SizedBox(height: 36),
              Text(
                'HydroTracker',
                style: AppTheme.headlineLg.copyWith(fontSize: 28),
              ),
              const SizedBox(height: 8),
              Text(
                'Stay refreshed, island style 🌴',
                style: AppTheme.bodyMd,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
