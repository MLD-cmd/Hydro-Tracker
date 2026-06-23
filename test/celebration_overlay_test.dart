import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydro_tracker/widgets/celebration_overlay.dart';

void main() {
  // Regression test for the yellow underline that showed under the celebration
  // text. showGeneralDialog inserts no Material, so without one the card's Text
  // widgets inherit Flutter's "no style" default — which paints a yellow
  // underline. The overlay now wraps its content in a transparent Material.
  testWidgets('goal celebration text has no yellow-underline fallback', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () =>
                  showGoalCelebration(context, streak: 1, goalMl: 2500),
              child: const Text('go'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    // The card actually rendered.
    expect(find.text('Goal Achieved! 🎉'), findsOneWidget);

    // The resolved style behind the title must not carry the underline that the
    // styleless default would have applied.
    final richText = tester.widget<RichText>(
      find.descendant(
        of: find.text('Goal Achieved! 🎉'),
        matching: find.byType(RichText),
      ),
    );
    final style = (richText.text as TextSpan).style;
    expect(style?.decoration, isNot(TextDecoration.underline));
  });
}
