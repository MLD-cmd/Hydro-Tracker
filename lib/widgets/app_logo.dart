import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// The HydroTracker logo presented inside a soft rounded badge.
///
/// Falls back to a water-drop icon if the asset is missing so the UI still
/// renders before the logo file is dropped into assets/images/logo.png.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.28;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowDark,
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
          const BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 16,
            offset: Offset(-6, -6),
          ),
        ],
      ),
      padding: EdgeInsets.all(size * 0.1),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius * 0.7),
        child: Image.asset(
          'assets/images/logo.png',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Icon(
            Icons.water_drop_rounded,
            size: size * 0.5,
            color: AppColors.turquoise,
          ),
        ),
      ),
    );
  }
}
