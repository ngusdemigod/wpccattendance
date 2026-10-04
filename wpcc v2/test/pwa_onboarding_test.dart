import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wpcc_community/features/onboarding/pwa_onboarding.dart';
import 'package:wpcc_community/features/onboarding/prototype_auth_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  testWidgets('moving the photo strip does not rebuild the blurred backdrop',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
      data: const MediaQueryData(size: Size(390, 844), disableAnimations: true),
      child: PwaOnboarding(onContinue: (_) {}),
    )));
    await tester.pumpAndSettle();
    final gesture = await tester.startGesture(const Offset(200, 200));
    await gesture.moveBy(const Offset(-40, 0));
    await tester.pumpAndSettle();
    final backdrop =
        find.byWidgetPredicate((w) => w is Image && w.excludeFromSemantics);
    final before = tester.widget<Image>(backdrop);
    final card = find.byWidgetPredicate(
        (w) => w is Image && w.semanticLabel == 'WPCC community photo 2');
    final left = tester.getTopLeft(card).dx;
    await gesture.moveBy(const Offset(-3, 0));
    await tester.pump();
    expect(tester.getTopLeft(card).dx, lessThan(left));
    expect(identical(before, tester.widget<Image>(backdrop)), isTrue);
    await gesture.up();
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('reduced-motion onboarding continues and fits a compact display',
      (tester) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    int? selected;
    await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
            data: const MediaQueryData(
                size: Size(375, 667), disableAnimations: true),
            child: PwaOnboarding(onContinue: (index) => selected = index))));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Get Started'), findsOneWidget);
    await tester.tap(find.text('Get Started'));
    expect(selected, isNotNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
      'OTP supports six-digit paste and delegates verification to the existing callback',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final code = TextEditingController(),
        email = TextEditingController(text: 'test@example.org'),
        password = TextEditingController(),
        otp = TextEditingController();
    addTearDown(() {
      code.dispose();
      email.dispose();
      password.dispose();
      otp.dispose();
    });
    var calls = 0;
    await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
            data: const MediaQueryData(
                size: Size(390, 844), disableAnimations: true),
            child: PrototypeAuthView(
                scope: PrototypeAuthScope(
                    photo: 0, onBack: () {}, child: const SizedBox()),
                code: code,
                email: email,
                password: password,
                otp: otp,
                useEmail: true,
                usePassword: false,
                otpSent: true,
                linkSent: false,
                loading: false,
                verifying: false,
                resendSeconds: 20,
                onMode: (_, __) {},
                onSubmit: () {},
                onVerify: () {
                  calls++;
                },
                onResend: () {},
                onBack: () {}))));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '123456');
    await tester.pump();
    expect(otp.text, '123456');
    expect(find.text('Resend in 20s'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    expect(calls, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('switching sign-in modes keeps only one identity field',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controllers = List.generate(4, (_) => TextEditingController());
    addTearDown(() {
      for (final controller in controllers) {
        controller.dispose();
      }
    });
    var useEmail = false;
    var usePassword = false;
    var changes = 0;
    await tester.pumpWidget(MaterialApp(
      home: StatefulBuilder(
          builder: (context, update) => PrototypeAuthView(
                scope: PrototypeAuthScope(
                    photo: 0, onBack: () {}, child: const SizedBox()),
                code: controllers[0],
                email: controllers[1],
                password: controllers[2],
                otp: controllers[3],
                useEmail: useEmail,
                usePassword: usePassword,
                otpSent: false,
                linkSent: false,
                loading: false,
                verifying: false,
                resendSeconds: 0,
                onMode: (email, password) => update(() {
                  useEmail = email;
                  usePassword = password;
                  changes++;
                }),
                onSubmit: () {},
                onVerify: () {},
                onResend: () {},
                onBack: () {},
              )),
    ));
    await tester.pump(const Duration(milliseconds: 700));
    final authPhoto =
        find.byWidgetPredicate((w) => w is Image && w.excludeFromSemantics);
    final cachedPhoto = tester.widget<Image>(authPhoto);
    await tester.pump(const Duration(milliseconds: 100));
    expect(identical(cachedPhoto, tester.widget<Image>(authPhoto)), isTrue,
        reason: 'Background zoom must reuse the image/blur subtree');
    await tester.tap(find.text('Sign in with membership code'));
    await tester.pump();
    final field = find.byType(TextField);
    final modeOpacity =
        find.ancestor(of: field, matching: find.byType(Opacity));
    expect(modeOpacity, findsOneWidget,
        reason: 'The mode field must have only one entrance fade');
    expect(tester.widget<Opacity>(modeOpacity).opacity, 0);
    expect(
        (tester.widget<Opacity>(modeOpacity).child as Transform)
            .transform
            .storage[13],
        8);
    expect(find.ancestor(of: field, matching: find.byType(ImageFiltered)),
        findsNothing);
    expect(
        tester.widget<AnimatedSize>(find.byType(AnimatedSize).first).duration,
        const Duration(milliseconds: 180));
    await tester.pump(const Duration(milliseconds: 180));
    expect(tester.widget<Opacity>(modeOpacity).opacity, 1);
    await tester.tap(find.text('Use Email Address'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.byType(TextField), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller,
        controllers[1]);
    expect(changes, 2);
    await tester.pump(const Duration(milliseconds: 60));
    expect(find.byType(TextField), findsOneWidget);
    expect(tester.widget<Opacity>(modeOpacity).opacity, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
