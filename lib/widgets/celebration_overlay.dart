import 'dart:math';
import 'package:flutter/material.dart';
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
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Goal achieved',
    barrierColor: AppColors.primary.withValues(alpha: 0.45),
    transitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (_, _, _) =>
        _CelebrationDialog(streak: streak, goalMl: goalMl),
    transitionBuilder: (context, anim, _, child) =>
        FadeTransition(opacity: anim, child: child),
  );
}

class _CelebrationDialog extends StatefulWidget {
  const _CelebrationDialog({required this.streak, required this.goalMl});

  final int streak;
  final int goalMl;

  @override
  State<_CelebrationDialog> createState() => _CelebrationDialogState();
}

class _CelebrationDialogState extends State<_CelebrationDialog>
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

  String _formatGoal(int ml) {
    final litres = ml / 1000;
    return '${litres.toStringAsFixed(litres % 1 == 0 ? 0 : 1)}L';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        _pieces ??= _buildConfetti(size);
        return Stack(
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
                child: _CelebrationCard(
                  streak: widget.streak,
                  goalLabel: _formatGoal(widget.goalMl),
                  onClose: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
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
          SizedBox(
            width: double.infinity,
            child: Material(
              color: AppColors.secondaryAccent,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onClose,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  child: Text(
                    'Awesome!',
                    textAlign: TextAlign.center,
                    style: AppTheme.button.copyWith(fontSize: 15),
                  ),
                ),
              ),
            ),
          ),
        ],
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
