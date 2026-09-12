import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wpcc_community/features/give/give_home_page.dart';

void main() {
  testWidgets('give home uses the requested list sections', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: GiveHomePage(
          loadAccounts: () async => const [],
          loadMandates: () async => const [],
        ),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Church accounts'), findsOneWidget);
    expect(find.text('Quick accounts'), findsOneWidget);
    expect(find.text('Offering'), findsOneWidget);
    expect(find.text('Tithe'), findsOneWidget);
    expect(find.text('Prophet offering'), findsOneWidget);
    expect(find.text('Scheduled givings'), findsOneWidget);
    expect(find.text('Auto give'), findsNothing);
    expect(find.text('Projects'), findsNothing);
    expect(find.byType(GridView), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
