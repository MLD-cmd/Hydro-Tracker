import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// "Pacific Pulse" design system tokens for HydroTracker.
///
/// A tropical-shoreline palette: deep ocean blues grounded on soft sand,
/// with turquoise water accents and a hibiscus highlight.
class AppColors {
  AppColors._();

  // Surfaces (soft sand)
  static const Color background = Color(0xFFFFF8F5);
  static const Color surface = Color(0xFFFFF8F5);
  static const Color surfaceContainerLow = Color(0xFFFFF1E7);
  static const Color surfaceContainer = Color(0xFFFEEADB);
  static const Color white = Color(0xFFFFFFFF);

  // Neomorphic shadow tints
  static const Color shadowLight = Color(0xFFFFFFFF);
  static const Color shadowDark = Color(0x33D1C0B1); // deep sand, ~20%

  // Text
  static const Color onSurface = Color(0xFF231A11);
  static const Color onSurfaceVariant = Color(0xFF7A6A5C);
  static const Color outlineVariant = Color(0xFFC2C7CF);

  // Brand
  static const Color primary = Color(0xFF002A48); // deep ocean blue
  static const Color primaryContainer = Color(0xFF00416A);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color turquoise = Color(0xFF40E0D0); // water / hydration
  static const Color secondaryAccent = Color(0xFF1AA589); // deep teal (active)
  static const Color hibiscus = Color(0xFFFF4F81); // accent
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        surface: AppColors.surface,
      ),
      scaffoldBackgroundColor: AppColors.background,
    );

    return base.copyWith(
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
        bodyColor: AppColors.onSurface,
        displayColor: AppColors.onSurface,
      ),
    );
  }

  // Convenience text styles mirroring the design spec.
  static TextStyle get headlineLg => GoogleFonts.plusJakartaSans(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    height: 1.2,
    letterSpacing: -0.5,
    color: AppColors.primary,
  );

  static TextStyle get bodyMd => GoogleFonts.plusJakartaSans(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.onSurfaceVariant,
  );

  static TextStyle get labelBold => GoogleFonts.plusJakartaSans(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
    color: AppColors.onSurface,
  );

  static TextStyle get button => GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.onPrimary,
  );

  static TextStyle get link => GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryContainer,
  );
}
