import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Large circular hydration gauge with an animated wave that fills from the
/// bottom according to [currentMl] / [targetMl].
class WaterCircle extends StatefulWidget {
  const WaterCircle({
    super.key,
    required this.currentMl,
    required this.targetMl,
    this.size = 300,
  });

  final int currentMl;
  final int targetMl;
  final double size;

  @override
  State<WaterCircle> createState() => _WaterCircleState();
}

class _WaterCircleState extends State<WaterCircle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _waveController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  // Animated fill level so adding water rises smoothly.
  late double _displayedProgress = _targetProgress;

  double get _targetProgress =>
      (widget.currentMl / widget.targetMl).clamp(0.0, 1.0);

  @override
  void didUpdateWidget(WaterCircle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentMl != widget.currentMl ||
        oldWidget.targetMl != widget.targetMl) {
      setState(() {}); // TweenAnimationBuilder picks up the new target.
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: AppColors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowDark,
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: AppColors.turquoise.withValues(alpha: 0.18),
            blurRadius: 36,
            spreadRadius: -8,
          ),
        ],
      ),
      child: ClipOval(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: _displayedProgress, end: _targetProgress),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          onEnd: () => _displayedProgress = _targetProgress,
          builder: (context, progress, _) {
            return Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _waveController,
                  builder: (context, _) => CustomPaint(
                    size: Size.square(widget.size),
                    painter: _WavePainter(
                      progress: progress,
                      phase: _waveController.value * 2 * math.pi,
                    ),
                  ),
                ),
                _CenterReadout(
                  currentMl: widget.currentMl,
                  targetMl: widget.targetMl,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CenterReadout extends StatelessWidget {
  const _CenterReadout({required this.currentMl, required this.targetMl});

  final int currentMl;
  final int targetMl;

  String _formatMl(int ml) {
    final s = ml.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'CURRENT',
          style: AppTheme.labelBold.copyWith(
            fontSize: 13,
            letterSpacing: 2,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _formatMl(currentMl),
          style: AppTheme.headlineLg.copyWith(
            fontSize: 56,
            fontWeight: FontWeight.w800,
            height: 1.0,
          ),
        ),
        Text(
          'ml',
          style: AppTheme.bodyMd.copyWith(
            color: AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Target: ${_formatMl(targetMl)}ml',
            style: AppTheme.labelBold.copyWith(
              color: AppColors.onSurface,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter({required this.progress, required this.phase});

  final double progress; // 0..1 fill amount
  final double phase; // animation phase in radians

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final baseLevel = size.height * (1 - progress);
    final waveHeight = 8.0;

    // Two overlapping waves for a layered, watery feel.
    _drawWave(
      canvas,
      size,
      baseLevel: baseLevel + 4,
      amplitude: waveHeight,
      phase: phase,
      color: AppColors.turquoise.withValues(alpha: 0.28),
    );
    _drawWave(
      canvas,
      size,
      baseLevel: baseLevel,
      amplitude: waveHeight * 0.7,
      phase: phase + math.pi / 2,
      color: AppColors.turquoise.withValues(alpha: 0.45),
    );
  }

  void _drawWave(
    Canvas canvas,
    Size size, {
    required double baseLevel,
    required double amplitude,
    required double phase,
    required Color color,
  }) {
    final path = Path()..moveTo(0, baseLevel);
    for (double x = 0; x <= size.width; x++) {
      final y =
          baseLevel +
          amplitude * math.sin((x / size.width * 2 * math.pi) + phase);
      path.lineTo(x, y);
    }
    path
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_WavePainter old) =>
      old.progress != progress || old.phase != phase;
}
