import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'soft_card.dart';

/// "Splash" — a little water-drop buddy that reacts to how hydrated you are
/// today. It changes face, colour and message as you sip toward your goal,
/// and bobs gently while it waits. The personality piece of HydroTracker.
class HydrationBuddy extends StatefulWidget {
  const HydrationBuddy({
    super.key,
    required this.currentMl,
    required this.targetMl,
  });

  final int currentMl;
  final int targetMl;

  @override
  State<HydrationBuddy> createState() => _HydrationBuddyState();
}

enum BuddyMood { parched, thirsty, happy, overjoyed }

class _HydrationBuddyState extends State<HydrationBuddy>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bob = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  BuddyMood get _mood {
    final frac = widget.targetMl == 0
        ? 0.0
        : widget.currentMl / widget.targetMl;
    if (frac >= 1.0) return BuddyMood.overjoyed;
    if (frac >= 0.55) return BuddyMood.happy;
    if (frac >= 0.2) return BuddyMood.thirsty;
    return BuddyMood.parched;
  }

  ({String title, String line, Color color}) get _persona {
    switch (_mood) {
      case BuddyMood.overjoyed:
        return (
          title: 'Goal smashed! 🎉',
          line: "You're a Hydration Hero today. Splash is beaming!",
          color: AppColors.secondaryAccent,
        );
      case BuddyMood.happy:
        return (
          title: 'Feeling fresh!',
          line: 'Over halfway there — keep the tide rolling.',
          color: AppColors.secondaryAccent,
        );
      case BuddyMood.thirsty:
        return (
          title: 'Getting there…',
          line: 'A few more sips and Splash will be smiling.',
          color: AppColors.turquoise,
        );
      case BuddyMood.parched:
        return (
          title: "I'm parched!",
          line: 'Tap a quick log below to help Splash out.',
          color: const Color(0xFF9FD8D0),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final persona = _persona;
    return SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: AnimatedBuilder(
              animation: _bob,
              builder: (context, child) {
                final dy = (0.5 - _bob.value) * 8; // gentle ±4px bob
                return Transform.translate(
                  offset: Offset(0, dy),
                  child: child,
                );
              },
              child: CustomPaint(
                painter: _BuddyPainter(mood: _mood, color: persona.color),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  persona.title,
                  style: AppTheme.headlineLg.copyWith(fontSize: 17),
                ),
                const SizedBox(height: 4),
                Text(
                  persona.line,
                  style: AppTheme.bodyMd.copyWith(fontSize: 13, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BuddyPainter extends CustomPainter {
  _BuddyPainter({required this.mood, required this.color});

  final BuddyMood mood;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final cx = size.width / 2;
    final r = s * 0.34;
    final cy = s * 0.58;

    // --- Body: a classic teardrop shape. ---
    final body = Path()
      ..moveTo(cx, s * 0.08)
      ..quadraticBezierTo(cx + r * 1.25, cy - r, cx + r, cy)
      ..arcToPoint(
        Offset(cx - r, cy),
        radius: Radius.circular(r),
        clockwise: true,
      )
      ..quadraticBezierTo(cx - r * 1.25, cy - r, cx, s * 0.08)
      ..close();

    canvas.drawPath(body, Paint()..color = color);

    // Soft highlight on the upper-left for a glossy look.
    canvas.drawCircle(
      Offset(cx - r * 0.4, cy - r * 0.45),
      r * 0.22,
      Paint()..color = Colors.white.withValues(alpha: 0.30),
    );

    // --- Eyes ---
    final eyeDx = r * 0.42;
    final eyeY = cy - r * 0.10;
    final eyeR = s * 0.075;
    final white = Paint()..color = Colors.white;
    final pupil = Paint()..color = AppColors.primary;

    for (final sign in [-1.0, 1.0]) {
      final ex = cx + sign * eyeDx;
      if (mood == BuddyMood.parched) {
        // Half-closed, weary eyes (downward arcs).
        final lid = Paint()
          ..color = AppColors.primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.03
          ..strokeCap = StrokeCap.round;
        canvas.drawArc(
          Rect.fromCircle(center: Offset(ex, eyeY), radius: eyeR),
          0.15,
          3.14 - 0.3,
          false,
          lid,
        );
      } else {
        canvas.drawCircle(Offset(ex, eyeY), eyeR, white);
        canvas.drawCircle(Offset(ex, eyeY + eyeR * 0.2), eyeR * 0.55, pupil);
        // Catchlight.
        canvas.drawCircle(
          Offset(ex - eyeR * 0.25, eyeY - eyeR * 0.2),
          eyeR * 0.18,
          white,
        );
      }
    }

    // --- Cheeks (blush) for the happy moods ---
    if (mood == BuddyMood.happy || mood == BuddyMood.overjoyed) {
      final blush = Paint()..color = AppColors.hibiscus.withValues(alpha: 0.35);
      for (final sign in [-1.0, 1.0]) {
        canvas.drawCircle(
          Offset(cx + sign * r * 0.62, eyeY + eyeR * 1.4),
          s * 0.05,
          blush,
        );
      }
    }

    // --- Mouth ---
    final mouthPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.035
      ..strokeCap = StrokeCap.round;
    final mouthY = cy + r * 0.45;
    final mouthRect = Rect.fromCenter(
      center: Offset(cx, mouthY),
      width: r * 0.9,
      height: r * 0.7,
    );
    switch (mood) {
      case BuddyMood.overjoyed:
        // Big open smile.
        final smile = Paint()..color = AppColors.primary;
        final path = Path()
          ..addArc(
            Rect.fromCenter(
              center: Offset(cx, mouthY - r * 0.05),
              width: r * 0.95,
              height: r * 0.95,
            ),
            0.2,
            3.14 - 0.4,
          );
        canvas.drawPath(path, smile);
        break;
      case BuddyMood.happy:
        canvas.drawArc(mouthRect, 0.25, 3.14 - 0.5, false, mouthPaint);
        break;
      case BuddyMood.thirsty:
        // Small, hopeful smile.
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(cx, mouthY),
            width: r * 0.55,
            height: r * 0.4,
          ),
          0.4,
          3.14 - 0.8,
          false,
          mouthPaint,
        );
        break;
      case BuddyMood.parched:
        // Slight frown (flipped arc).
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(cx, mouthY + r * 0.2),
            width: r * 0.6,
            height: r * 0.45,
          ),
          3.14 + 0.4,
          3.14 - 0.8,
          false,
          mouthPaint,
        );
        break;
    }

    // --- Mood extras ---
    if (mood == BuddyMood.parched) {
      // A bead of sweat by the right eye.
      final sweat = Paint()..color = AppColors.turquoise;
      canvas.drawCircle(
        Offset(cx + eyeDx + eyeR * 1.2, eyeY - eyeR * 0.4),
        s * 0.035,
        sweat,
      );
    } else if (mood == BuddyMood.overjoyed) {
      // Little sparkles around the head.
      final spark = Paint()
        ..color = AppColors.hibiscus
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.025
        ..strokeCap = StrokeCap.round;
      void sparkle(double dx, double dy, double len) {
        final c = Offset(cx + dx, dy);
        canvas.drawLine(c.translate(-len, 0), c.translate(len, 0), spark);
        canvas.drawLine(c.translate(0, -len), c.translate(0, len), spark);
      }

      sparkle(-r * 1.25, s * 0.16, s * 0.05);
      sparkle(r * 1.2, s * 0.12, s * 0.06);
      sparkle(r * 0.95, s * 0.42, s * 0.04);
    }
  }

  @override
  bool shouldRepaint(_BuddyPainter old) =>
      old.mood != mood || old.color != color;
}
