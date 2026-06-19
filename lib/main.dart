import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/sign_in_screen.dart';
import 'services/settings_repository.dart';
import 'state/environment_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Apply the saved environment theme before the first frame.
  final settings = SettingsRepository();
  await settings.load();
  environmentThemeIndex.value = settings.settings.themeIndex;
  runApp(const HydroTrackerApp());
}

class HydroTrackerApp extends StatelessWidget {
  const HydroTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hydro Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      scrollBehavior: const _NoStretchScrollBehavior(),
      home: const SignInScreen(),
    );
  }
}

/// Removes Android's Material 3 "stretch" overscroll. Scrolling past an edge
/// now stops cleanly instead of visually stretching the content.
class _NoStretchScrollBehavior extends MaterialScrollBehavior {
  const _NoStretchScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child; // no glow, no stretch
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }
}
