import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wpcc_community/features/onboarding/profile_confirmation_gate.dart';
import 'package:wpcc_community/features/onboarding/profile_confirmation_page.dart';
import 'package:wpcc_community/features/profile/profile_repository.dart';

class FixtureProfile extends ProfileRepository {
  FixtureProfile()
      : super(SupabaseClient('https://example.test', 'test-key',
            authOptions: const AuthClientOptions(autoRefreshToken: false),
            httpClient: MockClient((_) async => http.Response('true', 200,
                headers: {'content-type': 'application/json'}))));
  final saves = <Map<String, String>>[];
  @override
  Future<Map<String, dynamic>?> profile() async => {
        'full_name': 'Fixture Member',
        'date_of_birth': '1990-01-01',
        'phone': '08012345678',
        'residential_address': 'Fixture address',
        'occupation': 'Engineer',
        'emergency_contact': '{"name":"Contact","phone":"08012345679"}'
      };
  @override
  Future<Map<String, dynamic>> confirmationStatus() async => {
        'complete': false,
        'awarded': false,
        'pending': false,
        'departments': []
      };
  @override
  Future<List<Map<String, dynamic>>> joinDirectory() async => [
        {'department_id': 'fixture', 'name': 'Choir'}
      ];
  @override
  Future<void> checkConfirmationReward() async {}
  @override
  Future<void> saveConfirmation(Map<String, String> values) async {
    saves.add(values);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  testWidgets('birthday dialog opens from confirmation above the app router',
      (tester) async {
    final repo = FixtureProfile();
    addTearDown(() {
      repo.client.dispose();
    });
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => MediaQuery(
          data: const MediaQueryData(
              size: Size(390, 844), disableAnimations: true),
          child: ProfileConfirmationFlow(
              builder: (_) =>
                  ProfileConfirmationPage(repository: repo, onFinish: () {}))),
      home: const SizedBox(),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(DatePickerDialog), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsNothing);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '1990-01-01');
    expect(repo.saves, isEmpty);
    await tester.pumpWidget(const SizedBox());
  });
  test('fresh login only: restored sessions and refreshes do not replay', () {
    final tracker = FreshLoginTracker('existing');
    expect(tracker.update('existing'), false);
    expect(tracker.update(null), false);
    expect(tracker.update('existing'), true);
    expect(tracker.update('existing'), false);
    expect(tracker.update('another'), true);
  });
  testWidgets(
      'compact confirmation can skip all steps without saving or fabricating an award',
      (tester) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = FixtureProfile();
    addTearDown(() {
      repo.client.dispose();
    });
    var finished = false;
    await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
            data: const MediaQueryData(
                size: Size(375, 667), disableAnimations: true),
            child: ProfileConfirmationPage(
                repository: repo, onFinish: () => finished = true))));
    await tester.pumpAndSettle();
    expect(find.text('Confirm your profile photo'), findsOneWidget);
    for (var i = 0; i < 8; i++) {
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    expect(find.text('Details Verified'), findsOneWidget);
    expect(repo.saves, isEmpty);
    await tester.tap(find.text('Continue to WPCC Community'));
    await tester.pumpAndSettle();
    expect(finished, true);
    expect(find.text('+15WP'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('continue persists the visible field and back preserves draft',
      (tester) async {
    final repo = FixtureProfile();
    addTearDown(() {
      repo.client.dispose();
    });
    await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child:
                ProfileConfirmationPage(repository: repo, onFinish: () {}))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Updated Member');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(repo.saves, [
      {'full_name': 'Updated Member'}
    ]);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Updated Member'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('confirmation steps use short directional motion without blur',
      (tester) async {
    final repo = FixtureProfile();
    addTearDown(() {
      repo.client.dispose();
    });
    for (final reduced in [false, true]) {
      await tester.pumpWidget(MaterialApp(
          home: MediaQuery(
              data: MediaQueryData(disableAnimations: reduced),
              child:
                  ProfileConfirmationPage(repository: repo, onFinish: () {}))));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skip'));
      await tester.pump();
      final heading = find.text('Confirm your full name');
      final opacity =
          find.ancestor(of: heading, matching: find.byType(Opacity));
      expect(opacity, findsOneWidget);
      expect(find.ancestor(of: heading, matching: find.byType(ImageFiltered)),
          findsNothing);
      expect(
          (tester.widget<Opacity>(opacity).child as Transform)
              .transform
              .storage[12],
          reduced ? 0 : 16);
      expect(tester.widget<Opacity>(opacity).opacity, reduced ? 1 : 0);
      await tester.pump(const Duration(milliseconds: 220));
      expect(tester.widget<Opacity>(opacity).opacity, 1);
      expect(
          (tester.widget<Opacity>(opacity).child as Transform)
              .transform
              .storage[12],
          0);
      await tester.tap(find.byTooltip('Back'));
      await tester.pump();
      final previous = find.text('Confirm your profile photo');
      final backOpacity =
          find.ancestor(of: previous, matching: find.byType(Opacity));
      expect(
          (tester.widget<Opacity>(backOpacity).child as Transform)
              .transform
              .storage[12],
          reduced ? 0 : -16);
      await tester.pump(const Duration(milliseconds: 220));
      expect(
          (tester.widget<Opacity>(backOpacity).child as Transform)
              .transform
              .storage[12],
          0);
      expect(repo.saves, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    }
  });
}
