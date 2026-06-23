import 'dart:math';
import 'package:flutter/material.dart';
import '../models/achievement.dart';
import '../theme/app_theme.dart';
import 'hydration_buddy.dart';

/// Shows the one-off "Goal Achieved!" celebration — a confetti burst behind a
/// bouncing card starring an overjoyed Splash. Call this the moment a logged
/// drink pushes the day's total across the goal.
Future<void> showGoalCelebration(
  BuildContext context, {
  required int streak,
  required int goalMl,
}) {
  return _showCelebration(
    context,
    label: 'Goal achieved',
    cardBuilder: (close) => _CelebrationCard(
      streak: streak,
      goalLabel: _formatGoal(goalMl),
      onClose: close,
    ),
  );
}

/// Shows the same confetti moment for a freshly-unlocked [achievement]. Chain
/// these after the goal celebration so a single log can announce both.
Future<void> showAchievementCelebration(
  BuildContext context, {
  required Achievement achievement,
}) {
  return _showCelebration(
    context,
    label: 'Achievement unlocked',
    cardBuilder: (close) =>
        _AchievementCard(achievement: achievement, onClose: close),
  );
}

/// Shared confetti-dialog plumbing. [cardBuilder] receives a close callback and
/// returns the card shown at the centre of the burst.
Future<void> _showCelebration(
  BuildContext context, {
  required String label,
  required Widget Function(VoidCallback close) cardBuilder,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: label,
    barrierColor: AppColors.primary.withValues(alpha: 0.45),
    transitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (_, _, _) => _CelebrationScaffold(cardBuilder: cardBuilder),
    transitionBuilder: (context, anim, _, child) =>
        FadeTransition(opacity: anim, child: child),
  );
}

String _formatGoal(int ml) {
  final litres = ml / 1000;
  return '${litres.toStringAsFixed(litres % 1 == 0 ? 0 : 1)}L';
}

class _CelebrationScaffold extends StatefulWidget {
  const _CelebrationScaffold({required this.cardBuilder});

  final Widget Function(VoidCallback close) cardBuilder;

  @override
  State<_CelebrationScaffold> createState() => _CelebrationScaffoldState();
}

class _CelebrationScaffoldState extends State<_CelebrationScaffold>
    with TickerProviderStateMixin {
  // Drives the falling confetti once, then settles.
  late final AnimationController _confetti = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..forward();

  // Bounces the card + Splash in.
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  )..forward();

  List<_Confetto>? _pieces;

  @override
  void dispose() {
    _confetti.dispose();
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        _pieces ??= _buildConfetti(size);
        // showGeneralDialog (unlike showDialog) inserts no Material, so without
        // this the card's Text widgets fall back to Flutter's "no style"
        // default and get painted with a yellow underline. A transparent
        // Material gives them a proper default text style while keeping the
        // confetti backdrop see-through.
        return Material(
          type: MaterialType.transparency,
          child: Stack(
          children: [
            // Confetti fills the whole screen, behind everything.
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _confetti,
                builder: (context, _) => CustomPaint(
                  painter: _ConfettiPainter(
                    pieces: _pieces!,
                    progress: _confetti.value,
                  ),
                ),
              ),
            ),
            Center(
              child: ScaleTransition(
                scale: CurvedAnimation(
                  parent: _pop,
                  curve: Curves.elasticOut,
                ),
                child: widget.cardBuilder(() => Navigator.of(context).pop()),
              ),
            ),
          ],
          ),
        );
      },
    );
  }

  List<_Confetto> _buildConfetti(Size size) {
    final rnd = Random();
    const colors = [
      AppColors.turquoise,
      AppColors.secondaryAccent,
      AppColors.hibiscus,
      AppColors.primaryContainer,
      Color(0xFFFFC857), // festive gold
      Colors.white,
    ];
    // Burst origin sits just behind the card.
    final origin = Offset(size.width / 2, size.height * 0.42);
    return List.generate(70, (_) {
      final angle = rnd.nextDouble() * 2 * pi;
      final speed = 180 + rnd.nextDouble() * 480;
      return _Confetto(
        origin: origin,
        // Slight upward bias so pieces arc up before gravity pulls them down.
        velocity: Offset(cos(angle) * speed, sin(angle) * speed - 140),
        color: colors[rnd.nextInt(colors.length)],
        size: 7 + rnd.nextDouble() * 9,
        rotation: rnd.nextDouble() * 2 * pi,
        rotationSpeed: (rnd.nextDouble() - 0.5) * 14,
        isRect: rnd.nextBool(),
      );
    });
  }
}

class _CelebrationCard extends StatelessWidget {
  const _CelebrationCard({
    required this.streak,
    required this.goalLabel,
    required this.onClose,
  });

  final int streak;
  final String goalLabel;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BuddyFace(mood: BuddyMood.overjoyed, size: 104),
          const SizedBox(height: 18),
          Text(
            'Goal Achieved! 🎉',
            textAlign: TextAlign.center,
            style: AppTheme.headlineLg.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 10),
          Text(
            "You hit your $goalLabel goal today.\nSplash is so proud of you!",
            textAlign: TextAlign.center,
            style: AppTheme.bodyMd.copyWith(fontSize: 14),
          ),
          if (streak > 1) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.hibiscus.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.local_fire_department_rounded,
                    size: 18,
                    color: AppColors.hibiscus,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$streak-day streak!',
                    style: AppTheme.labelBold.copyWith(
                      fontSize: 14,
                      color: AppColors.hibiscus,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          _CelebrationButton(label: 'Awesome!', onTap: onClose),
        ],
      ),
    );
  }
}

/// The "Achievement Unlocked!" variant — same confetti moment, but starring the
/// badge that was just earned instead of Splash.
class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.achievement, required this.onClose});

  final Achievement achievement;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  color: achievement.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(achievement.icon, size: 50, color: achievement.color),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.secondaryAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.white, width: 3),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Achievement Unlocked! 🏅',
            textAlign: TextAlign.center,
            style: AppTheme.headlineLg.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 10),
          Text(
            achievement.title,
            textAlign: TextAlign.center,
            style: AppTheme.headlineLg.copyWith(
              fontSize: 18,
              color: achievement.color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            achievement.description,
            textAlign: TextAlign.center,
            style: AppTheme.bodyMd.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 24),
          _CelebrationButton(label: 'Nice!', onTap: onClose),
        ],
      ),
    );
  }
}

/// The white rounded card the celebration content sits in.
class _CardShell extends StatelessWidget {
  const _CardShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CelebrationButton extends StatelessWidget {
  const _CelebrationButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: AppColors.secondaryAccent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: AppTheme.button.copyWith(fontSize: 15),
            ),
          ),
        ),
      ),
    );
  }
}

/// A single piece of confetti. Its position is computed analytically from the
/// elapsed time so the animation stays smooth and deterministic.
class _Confetto {
  const _Confetto({
    required this.origin,
    required this.velocity,
    required this.color,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
    required this.isRect,
  });

  final Offset origin;
  final Offset velocity; // px/s
  final Color color;
  final double size;
  final double rotation;
  final double rotationSpeed; // rad/s
  final bool isRect;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.pieces, required this.progress});

  final List<_Confetto> pieces;
  final double progress; // 0..1 over the controller's lifetime

  static const double _totalTime = 2.6; // seconds
  static const double _gravity = 950; // px/s²

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress * _totalTime;
    // Fade everything out over the final quarter of the run.
    final fade = progress < 0.75
        ? 1.0
        : (1 - (progress - 0.75) / 0.25).clamp(0.0, 1.0);

    for (final p in pieces) {
      final pos = Offset(
        p.origin.dx + p.velocity.dx * t,
        p.origin.dy + p.velocity.dy * t + 0.5 * _gravity * t * t,
      );
      if (pos.dy > size.height + 40) continue;

      final paint = Paint()..color = p.color.withValues(alpha: fade);
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(p.rotation + p.rotationSpeed * t);
      if (p.isRect) {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 0.5,
          ),
          paint,
        );
      } else {
        canvas.drawCircle(Offset.zero, p.size * 0.42, paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}
