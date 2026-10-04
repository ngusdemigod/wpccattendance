import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wpcc_community/core/widgets/member_glass.dart';

void main() {
  for (final solid in [false, true]) {
    testWidgets('glass respects high contrast: $solid', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(highContrast: solid),
          child: const MemberGlass(child: SizedBox(width: 48, height: 48)),
        ),
      ));
      expect(find.byType(BackdropFilter), solid ? findsNothing : findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
