import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hydro_tracker/config/supabase_config.dart';
import 'package:hydro_tracker/main.dart';
import 'package:hydro_tracker/screens/splash_screen.dart';
import 'package:hydro_tracker/screens/onboarding_screen.dart';

void main() {
  setUpAll(() async {
    // The app normally inits Supabase in main(); the test pumps the widget
    // directly, so init it here. This is local-only (no network) — with an
    // empty store there's no session to restore, so the splash treats the run
    // as signed-out.
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: SupabaseConfig.url,
      // ignore: deprecated_member_use
      anonKey: SupabaseConfig.anonKey,
    );
  });

  testWidgets('App opens on the splash screen, then routes onward', (
    WidgetTester tester,
  ) async {
    // The splash loads persisted settings; give it an empty store so the run is
    // deterministic (no saved profile → treated as a first run).
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const HydroTrackerApp());

    // Launch lands on the bouncing splash, not straight on a content screen.
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('HydroTracker'), findsOneWidget);

    // The splash holds for ~2s, then hands off. Flush that delay and let the
    // route transition settle so no timers linger past the test.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    // First run (empty settings) routes into onboarding.
    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(OnboardingScreen), findsOneWidget);
  });
}
