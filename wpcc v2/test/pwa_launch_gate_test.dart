import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wpcc_community/features/onboarding/pwa_launch_gate.dart';
import 'package:wpcc_community/features/onboarding/pwa_onboarding.dart';
import 'package:wpcc_community/features/onboarding/prototype_auth_view.dart';

void main() {
  testWidgets('reduced motion skips the restored splash exit', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: PwaLaunchGate(signedIn: true, child: Text('Member content')),
      ),
    ));
    await tester.pump();
    expect(find.byType(PwaOnboarding), findsNothing);
    expect(find.text('Member content'), findsOneWidget);
  });
  testWidgets('restored members play only the splash exit then enter',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: PwaLaunchGate(signedIn: true, child: Text('Member content')),
    ));
    expect(find.text('Member content'), findsOneWidget);
    expect(find.byType(PwaOnboarding), findsOneWidget);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1250));
    expect(find.byType(PwaOnboarding), findsNothing);
    expect(find.byType(PrototypeAuthScope), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('signed-out launches retain the original onboarding flow',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: PwaLaunchGate(signedIn: false, child: Text('Sign in')),
    ));
    expect(find.byType(PwaOnboarding), findsOneWidget);
    expect(tester.widget<PwaOnboarding>(find.byType(PwaOnboarding)).splashOnly,
        isFalse);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
