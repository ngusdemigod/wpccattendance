import 'package:attendamce/shared/widgets/app_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('entrance motion fades content into place', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EntranceMotion(
            child: Text('Animated content'),
          ),
        ),
      ),
    );

    final opacity = tester.widget<Opacity>(
      find.ancestor(
        of: find.text('Animated content'),
        matching: find.byType(Opacity),
      ),
    );
    expect(opacity.opacity, 0);

    await tester.pumpAndSettle();

    final settledOpacity = tester.widget<Opacity>(
      find.ancestor(
        of: find.text('Animated content'),
        matching: find.byType(Opacity),
      ),
    );
    expect(settledOpacity.opacity, 1);
  });

  testWidgets('reduced motion removes the entrance translation',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: EntranceMotion(
              child: Text('Reduced motion content'),
            ),
          ),
        ),
      ),
    );

    expect(
      find.ancestor(
        of: find.text('Reduced motion content'),
        matching: find.byType(Transform),
      ),
      findsNothing,
    );
  });
}
