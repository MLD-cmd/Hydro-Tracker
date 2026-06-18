import 'package:flutter_test/flutter_test.dart';
import 'package:hydro_tracker/main.dart';
import 'package:hydro_tracker/screens/sign_in_screen.dart';

void main() {
  testWidgets('App renders the sign in screen', (WidgetTester tester) async {
    await tester.pumpWidget(const HydroTrackerApp());
    expect(find.byType(SignInScreen), findsOneWidget);
    expect(find.text('HydroTracker'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
