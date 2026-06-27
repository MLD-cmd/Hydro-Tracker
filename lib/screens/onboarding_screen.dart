import 'package:flutter/material.dart';
import '../repositories/settings_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_background.dart';
import '../widgets/hydration_buddy.dart';
import 'sign_in_screen.dart';

/// A one-time, three-slide intro shown on first launch. Finishing (or skipping)
/// records [AppSettings.onboarded] so it never shows again, then moves on to
/// sign in.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  static const _slides = <_SlideData>[
    _SlideData(
      icon: Icons.water_drop_rounded,
      color: AppColors.turquoise,
      title: 'Track every sip',
      body: 'Log water, coconut, juice, tea or coffee — and watch your day '
          'fill up toward your goal.',
    ),
    _SlideData(
      buddy: true,
      color: AppColors.secondaryAccent,
      title: 'Meet Splash',
      body: 'Your hydration buddy cheers you on, and gently nudges you back '
          'to water whenever you need it.',
    ),
    _SlideData(
      icon: Icons.emoji_events_rounded,
      color: AppColors.hibiscus,
      title: 'Badges, streaks & smart goals',
      body: 'Earn achievements, build daily streaks, and let your goal adapt '
          'to the island weather.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isLast => _page == _slides.length - 1;

  Future<void> _finish() async {
    final repo = SettingsRepository();
    await repo.load();
    await repo.save(repo.settings.copyWith(onboarded: true));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const SignInScreen()),
    );
  }

  void _next() {
    if (_isLast) {
      _finish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 12, 0),
                child: TextButton(
                  onPressed: _finish,
                  child: Text(
                    'Skip',
                    style: AppTheme.labelBold.copyWith(
                      fontSize: 14,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) => _Slide(data: _slides[i]),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _slides.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _page ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _page
                          ? AppColors.secondaryAccent
                          : AppColors.onSurfaceVariant.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
              child: SizedBox(
                width: double.infinity,
                child: Material(
                  color: AppColors.secondaryAccent,
                  borderRadius: BorderRadius.circular(16),
                  elevation: 6,
                  shadowColor: AppColors.secondaryAccent.withValues(alpha: 0.4),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _next,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        _isLast ? 'Get Started' : 'Next',
                        textAlign: TextAlign.center,
                        style: AppTheme.button.copyWith(fontSize: 15),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideData {
  const _SlideData({
    this.icon,
    this.buddy = false,
    required this.color,
    required this.title,
    required this.body,
  });

  final IconData? icon;
  final bool buddy; // show the Splash mascot instead of an icon
  final Color color;
  final String title;
  final String body;
}

class _Slide extends StatelessWidget {
  const _Slide({required this.data});

  final _SlideData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 168,
            height: 168,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: data.buddy
                ? const BuddyFace(mood: BuddyMood.happy, size: 120)
                : Icon(data.icon, size: 78, color: data.color),
          ),
          const SizedBox(height: 40),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: AppTheme.headlineLg.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 14),
          Text(
            data.body,
            textAlign: TextAlign.center,
            style: AppTheme.bodyMd.copyWith(fontSize: 15, height: 1.45),
          ),
        ],
      ),
    );
  }
}
