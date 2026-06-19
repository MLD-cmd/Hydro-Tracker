import 'package:flutter/material.dart';

/// The selectable "Environment Theme" — recolours the app's background
/// atmosphere. Kept as light tropical gradients so the dark text and white
/// cards stay readable across every screen.
class EnvironmentTheme {
  const EnvironmentTheme({
    required this.label,
    required this.gradient,
    required this.swatch,
    required this.accent,
    this.showMoon = false,
  });

  final String label;
  final List<Color> gradient; // top -> bottom, behind everything
  final List<Color> swatch; // the small preview tile in Settings
  final Color accent; // a representative accent for the theme
  final bool showMoon;
}

const List<EnvironmentTheme> kEnvironmentThemes = [
  EnvironmentTheme(
    label: 'Shoreline',
    gradient: [Color(0xFFFFF8F5), Color(0xFFFFF1E7), Color(0xFFD8EFEA)],
    swatch: [Color(0xFFD9F5EE), Color(0xFF8FE3D6)],
    accent: Color(0xFF1AA589),
  ),
  EnvironmentTheme(
    label: 'Lagoon',
    gradient: [Color(0xFFF3FAFF), Color(0xFFE4F1FB), Color(0xFFC4E4F5)],
    swatch: [Color(0xFF9AD6F0), Color(0xFF2C6E9B)],
    accent: Color(0xFF00416A),
    showMoon: true,
  ),
  EnvironmentTheme(
    label: 'Hibiscus',
    gradient: [Color(0xFFFFF6F8), Color(0xFFFFE9EF), Color(0xFFF9D2DE)],
    swatch: [Color(0xFFE0466F), Color(0xFF7E2038)],
    accent: Color(0xFFFF4F81),
  ),
];

/// App-wide current theme index. A small global notifier keeps the background
/// in sync across screens without a full state-management library. Persisted
/// via SettingsRepository; this just drives the live UI.
final ValueNotifier<int> environmentThemeIndex = ValueNotifier<int>(0);

EnvironmentTheme get activeEnvironmentTheme =>
    kEnvironmentThemes[environmentThemeIndex.value.clamp(
      0,
      kEnvironmentThemes.length - 1,
    )];
