import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wpcc_community/features/onboarding/onboarding_style.dart';
import 'package:wpcc_community/features/onboarding/profile_confirmation_page.dart';
import 'package:wpcc_community/features/onboarding/prototype_auth_view.dart';
import 'package:wpcc_community/features/onboarding/pwa_onboarding.dart';
import 'package:wpcc_community/features/profile/profile_repository.dart';

class _Fixture extends ProfileRepository {
  _Fixture()
      : super(SupabaseClient('https://example.test', 'test-key',
            authOptions: const AuthClientOptions(autoRefreshToken: false),
            httpClient: MockClient((_) async => http.Response('true', 200,
                headers: {'content-type': 'application/json'}))));
  @override
  Future<Map<String, dynamic>?> profile() async => {
        'full_name': 'Fixture Member',
        'date_of_birth': '1990-01-01',
        'phone': '08012345678',
        'residential_address': 'Fixture address, Lagos',
        'occupation': 'Engineer',
        'emergency_contact': '{"name":"Contact","phone":"08012345679"}'
      };
  @override
  Future<Map<String, dynamic>> confirmationStatus() async => {
        'complete': false,
        'awarded': false,
        'pending': false,
        'departments': [
          {'id': 'a', 'name': 'Media', 'status': 'pending'}
        ]
      };
  @override
  Future<List<Map<String, dynamic>>> joinDirectory() async => [
        {'department_id': 'fixture', 'name': 'Choir'}
      ];
  @override
  Future<void> checkConfirmationReward() async {}
  @override
  Future<void> saveConfirmation(Map<String, String> values) async {}
}

Widget _host(Widget child, {Size size = const Size(390, 844), double text = 1}) =>
    MaterialApp(
        home: MediaQuery(
            data: MediaQueryData(
                size: size,
                disableAnimations: true,
                textScaler: TextScaler.linear(text)),
            child: Scaffold(
                backgroundColor: Onb.canvas,
                body: Padding(
                    padding: const EdgeInsets.all(Onb.s24),
                    child: SingleChildScrollView(child: child)))));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  test('step labels use plain words', () {
    expect(Onb.stepLabel(1, 8), 'Step 1 of 8');
    expect(Onb.stepLabel(8, 8), 'Step 8 of 8');
  });

  test('the palette avoids pure black and pure white', () {
    for (final color in [Onb.canvas, Onb.ink, Onb.onInk]) {
      expect(color.toARGB32() & 0xffffff, isNot(0x000000));
      expect(color.toARGB32() & 0xffffff, isNot(0xffffff));
    }
  });

  testWidgets('shared controls follow the radius and target system',
      (tester) async {
    var pressed = 0;
    await tester.pumpWidget(_host(Column(children: [
      OnbBackButton(tooltip: 'Back', onPressed: () => pressed++),
      OnbPrimaryButton(label: 'Continue', onPressed: () => pressed++),
      OnbSecondaryButton(label: 'Resend code', onPressed: () => pressed++),
      OnbTextAction(label: 'Skip', onPressed: () => pressed++),
      OnbChip(label: 'Engineer', onTap: () => pressed++),
    ])));
    // Back is a 48 square with the 12 control radius.
    final back = tester.getSize(find.byTooltip('Back'));
    expect(back, const Size(48, 48));
    final backShape = tester
        .widget<IconButton>(find.byType(IconButton))
        .style!
        .shape!
        .resolve({}) as RoundedRectangleBorder;
    expect(backShape.borderRadius, BorderRadius.circular(12));
    // The one primary action is a full pill, at least 56 high.
    final primary = tester.getSize(find.byType(FilledButton));
    expect(primary.height, greaterThanOrEqualTo(56));
    expect(
        tester
            .widget<FilledButton>(find.byType(FilledButton))
            .style!
            .shape!
            .resolve({}),
        isA<StadiumBorder>());
    // Secondary actions never use the pill radius.
    final secondary = tester
        .widget<OutlinedButton>(find.byType(OutlinedButton))
        .style!
        .shape!
        .resolve({}) as RoundedRectangleBorder;
    expect(secondary.borderRadius, BorderRadius.circular(12));
    for (final finder in [
      find.byType(OutlinedButton),
      find.byType(TextButton),
      find.byType(OnbChip)
    ]) {
      expect(tester.getSize(finder).height, greaterThanOrEqualTo(48));
    }
    for (final finder in [
      find.byType(IconButton),
      find.byType(FilledButton),
      find.byType(OutlinedButton),
      find.byType(TextButton),
      find.byType(InkWell)
    ]) {
      await tester.tap(finder.first);
    }
    expect(pressed, 5);
  });

  testWidgets('fields put the label above and the error below the input',
      (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_host(OnbField(
        label: 'Full name',
        controller: controller,
        hint: 'Enter your full name',
        helper: 'As on your record.')));
    final label = tester.getTopLeft(find.text('Full name')).dy;
    final input = tester.getTopLeft(find.byType(TextField)).dy;
    final helper = tester.getTopLeft(find.text('As on your record.')).dy;
    expect(label, lessThan(input));
    expect(helper, greaterThan(input));
    expect(tester.getSize(find.byType(TextField)).height, greaterThanOrEqualTo(56));
    final border = tester
        .widget<TextField>(find.byType(TextField))
        .decoration!
        .enabledBorder as OutlineInputBorder;
    expect(border.borderRadius, BorderRadius.circular(12));
    await tester.pumpWidget(_host(OnbField(
        label: 'Full name',
        controller: controller,
        error: 'Enter at least two characters.')));
    expect(find.text('Enter at least two characters.'), findsOneWidget);
    expect(find.text('As on your record.'), findsNothing);
  });

  testWidgets('confirmation shows step counts and filled segments',
      (tester) async {
    final repo = _Fixture();
    addTearDown(() {
      repo.client.dispose();
    });
    await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
            data: const MediaQueryData(
                size: Size(390, 844), disableAnimations: true),
            child:
                ProfileConfirmationPage(repository: repo, onFinish: () {}))));
    await tester.pumpAndSettle();
    expect(find.text('Step 1 of 8'), findsOneWidget);
    expect(find.byType(OnbStepSegments), findsOneWidget);
    // The member sticky back button must never appear in onboarding.
    expect(find.byTooltip('Back to sign in'), findsOneWidget);
    for (var step = 2; step <= 8; step++) {
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();
      expect(find.text('Step $step of 8'), findsOneWidget);
    }
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.text('Details Verified'), findsOneWidget);
    expect(find.textContaining('Step '), findsNothing);
    expect(find.byType(OnbStepSegments), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'confirmation steps and sign-in stay usable at 2x text on a compact phone',
      (tester) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = _Fixture();
    addTearDown(() {
      repo.client.dispose();
    });
    await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
            data: const MediaQueryData(
                size: Size(375, 667),
                disableAnimations: true,
                textScaler: TextScaler.linear(2)),
            child:
                ProfileConfirmationPage(repository: repo, onFinish: () {}))));
    await tester.pumpAndSettle();
    for (var i = 0; i < 8; i++) {
      expect(tester.takeException(), isNull, reason: 'step ${i + 1}');
      // Primary action stays reachable above the safe area.
      expect(tester.getBottomLeft(find.byType(FilledButton)).dy,
          lessThanOrEqualTo(667));
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
    final controllers = List.generate(4, (_) => TextEditingController());
    addTearDown(() {
      for (final c in controllers) {
        c.dispose();
      }
    });
    await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
            data: const MediaQueryData(
                size: Size(375, 667),
                disableAnimations: true,
                textScaler: TextScaler.linear(2)),
            child: PrototypeAuthView(
              scope: PrototypeAuthScope(
                  photo: 0, onBack: () {}, child: const SizedBox()),
              code: controllers[0],
              email: controllers[1],
              password: controllers[2],
              otp: controllers[3],
              useEmail: false,
              usePassword: false,
              otpSent: false,
              linkSent: false,
              loading: false,
              verifying: false,
              resendSeconds: 0,
              onMode: (_, __) {},
              onSubmit: () {},
              onVerify: () {},
              onResend: () {},
              onBack: () {},
            ))));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.text('Sign in with membership code'), findsOneWidget);
    await tester.tap(find.text('Sign in with membership code'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
            data: const MediaQueryData(
                size: Size(375, 667),
                disableAnimations: true,
                textScaler: TextScaler.linear(2)),
            child: PrototypeAuthView(
              scope: PrototypeAuthScope(
                  photo: 0, onBack: () {}, child: const SizedBox()),
              code: controllers[0],
              email: controllers[1],
              password: controllers[2],
              otp: controllers[3],
              useEmail: true,
              usePassword: false,
              otpSent: true,
              linkSent: false,
              loading: false,
              verifying: false,
              resendSeconds: 0,
              onMode: (_, __) {},
              onSubmit: () {},
              onVerify: () {},
              onResend: () {},
              onBack: () {},
            ))));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNWidgets(6));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('welcome keeps one full-width primary action on tablet widths',
      (tester) async {
    tester.view.physicalSize = const Size(834, 1194);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
            data: const MediaQueryData(
                size: Size(834, 1194), disableAnimations: true),
            child: PwaOnboarding(onContinue: (_) {}))));
    await tester.pumpAndSettle();
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
    expect(tester.getSize(find.byType(FilledButton)).height,
        greaterThanOrEqualTo(52));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
