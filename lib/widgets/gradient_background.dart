import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Full-screen "shoreline" gradient used behind the auth screens.
///
/// The gradient fills the entire screen (edge to edge, including behind the
/// status bar and gesture area) so there is no cream seam at the bottom. The
/// [child] is wrapped in a [SafeArea] so content is never cut off by the
/// notch/status bar at the top or the gesture bar at the bottom.
class GradientBackground extends StatelessWidget {
  const GradientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.surface, // soft sand at the top
            AppColors.surfaceContainerLow,
            Color(0xFFD8EFEA), // turquoise shoreline at the bottom
          ],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: SafeArea(child: child),
    );
  }
}
