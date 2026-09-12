import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wpcc_community/features/profile/classes_page.dart';

void main() {
  testWidgets('classes empty state matches the prototype structure',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ClassesPage(loadClasses: () async => const []),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Classes'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('In progress'), findsOneWidget);
    expect(find.text('Due soon'), findsOneWidget);
    expect(find.text('No classes assigned'), findsOneWidget);
    expect(find.text('My classes'), findsNothing);
    expect(
        find.byKey(const ValueKey('class-metric-Completed')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('class-metric-In progress')), findsOneWidget);
    expect(find.byKey(const ValueKey('class-metric-Due soon')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
