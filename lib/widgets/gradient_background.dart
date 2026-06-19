import 'package:flutter/material.dart';
import '../state/environment_theme.dart';

/// Full-screen environment gradient used behind every screen.
///
/// The gradient fills the entire screen (edge to edge, including behind the
/// status bar and gesture area) so there is no cream seam at the bottom. The
/// [child] is wrapped in a [SafeArea] so content is never cut off by the
/// notch/status bar at the top or the gesture bar at the bottom. The colours
/// follow the user's selected [EnvironmentTheme] and animate when it changes.
class GradientBackground extends StatelessWidget {
  const GradientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: environmentThemeIndex,
      builder: (context, _, child) {
        final theme = activeEnvironmentTheme;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: theme.gradient,
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
          child: child,
        );
      },
      child: SafeArea(child: child),
    );
  }
}
