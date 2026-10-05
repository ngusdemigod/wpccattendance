import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wpcc_community/core/services/swr_cache.dart';
import 'package:wpcc_community/core/theme/app_theme.dart';
import 'package:wpcc_community/core/theme/member_theme.dart';
import 'package:wpcc_community/core/widgets/member_components.dart';
import 'package:wpcc_community/core/widgets/member_sheet.dart';
import 'package:wpcc_community/features/profile/profile_page.dart';
import 'package:wpcc_community/features/profile/profile_repository.dart';

final captureBoundary = GlobalKey();

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    for (final family in ['DMSans_regular', 'DM Sans']) {
      await (FontLoader(family)
            ..addFont(rootBundle.load('assets/DMSans-Regular.ttf'))
            ..addFont(rootBundle.load('assets/DMSans-Medium.ttf'))
            ..addFont(rootBundle.load('assets/DMSans-SemiBold.ttf'))
            ..addFont(rootBundle.load('assets/DMSans-Bold.ttf')))
          .load();
    }
    await (FontLoader('packages/phosphor_flutter/PhosphorRegular')
          ..addFont(rootBundle
              .load('packages/phosphor_flutter/lib/fonts/Phosphor.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-key',
      httpClient: MockClient((request) async => http.Response(
          jsonEncode(request.url.path.endsWith('current_my_profile')
              ? [
                  {
                    'full_name': 'Grace Member',
                    'membership_code': '0123',
                    'department_name': 'Choir',
                    'leadership_title': 'Coordinator',
                    'email': 'member@example.com',
                    'phone': '08000000000'
                  }
                ]
              : {'balance': 15, 'pending': 0, 'history': []}),
          200,
          request: request,
          headers: {'content-type': 'application/json'})),
    );
  });
  tearDownAll(() => Supabase.instance.dispose());
  setUp(() {
    SwrCache.instance.clear();
    ThemePreference.instance.value = ThemeMode.system;
  });

  testWidgets('Profile appearance shares the reference member sheet',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final brightness in Brightness.values) {
      for (final size in [const Size(390, 844), const Size(834, 1194)]) {
        tester.view.physicalSize = size;
        ThemePreference.instance.value = ThemeMode.system;
        await tester.pumpWidget(MaterialApp(
            theme: buildMemberTheme(buildWpccTheme(brightness: brightness)),
            home: const Scaffold(body: ProfilePage())));
        await tester.runAsync(() => ProfileRepository().profile());
        await tester.pumpAndSettle();
        expect(find.text('Appearance'), findsNothing);
        await tester.tap(find.byTooltip('App settings'));
        await tester.pumpAndSettle();
        expect(find.text('App settings'), findsOneWidget);
        await tester.tap(find.text('Appearance'));
        await tester.pumpAndSettle();
        expect(find.byType(MemberSheet), findsOneWidget);
        final surface = find.byKey(const ValueKey('member-sheet-surface'));
        expect(tester.getSize(surface).width, size.width < 600 ? 374 : 560);
        expect(tester.getTopLeft(surface).dx, size.width < 600 ? 8 : 137);
        final rows = find.descendant(
            of: find.byType(MemberSheet), matching: find.byType(MemberListRow));
        expect(tester.widgetList<MemberListRow>(rows).map((row) => row.title),
            ['Dark', 'Light', 'System']);
        expect(
            tester
                .widget<MemberListRow>(
                    find.widgetWithText(MemberListRow, 'System'))
                .selected,
            isTrue);
        await tester.tap(find.widgetWithText(MemberListRow, 'Light'));
        await tester.pumpAndSettle();
        expect(find.byType(MemberSheet), findsNothing);
        expect(ThemePreference.instance.value, ThemeMode.light);
        expect((await SharedPreferences.getInstance()).getString('wpcc.theme'),
            'light');
        await tester.scrollUntilVisible(find.byTooltip('App settings'), -150,
            scrollable: find.byType(Scrollable).first);
        await tester.tap(find.byTooltip('App settings'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Appearance'));
        await tester.pumpAndSettle();
        expect(
            tester
                .widget<MemberListRow>(
                    find.widgetWithText(MemberListRow, 'Light'))
                .selected,
            isTrue);
        await tester.tap(find.descendant(
            of: find.byType(MemberSheet), matching: find.byTooltip('Close')));
        await tester.pumpAndSettle();
        expect(find.byType(MemberSheet), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      }
    }
  });

  testWidgets('profile editor remains scrollable with large text and keyboard',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      theme: buildMemberTheme(buildWpccTheme(brightness: Brightness.dark)),
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(2),
              viewInsets: const EdgeInsets.only(bottom: 240)),
          child: child!),
      home: const Scaffold(body: ProfilePage()),
    ));
    await tester.runAsync(() => ProfileRepository().profile());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Personal details'), 200,
        scrollable: find.byType(Scrollable).first);
    await Scrollable.ensureVisible(
        tester.element(find.text('Personal details')),
        alignment: .2);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Personal details'));
    await tester.pumpAndSettle();
    expect(find.byType(MemberSheet), findsOneWidget);
    expect(find.text('Church'), findsOneWidget);
    expect(find.text('Contact'), findsOneWidget);
    expect(find.text('About you'), findsOneWidget);
    await tester
        .ensureVisible(find.widgetWithText(FilledButton, 'Edit profile'));
    await tester.tap(find.widgetWithText(FilledButton, 'Edit profile'));
    await tester.pumpAndSettle();
    final save = find.widgetWithText(FilledButton, 'Save changes');
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    expect(save.hitTestable(), findsOneWidget);
    final saveStyle = tester.widget<FilledButton>(save).style!;
    expect(saveStyle.foregroundColor!.resolve({})!.a, 1);
    expect(saveStyle.foregroundColor!.resolve({}),
        isNot(saveStyle.backgroundColor!.resolve({})));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final brightness in Brightness.values) {
    for (final width in [320.0, 390.0, 393.0, 600.0, 768.0, 834.0, 1024.0]) {
      for (final scale in [1.0, 1.6, 2.0]) {
        testWidgets('profile adapts at $width/$scale/$brightness',
            (tester) async {
          final height = width == 390
              ? 844.0
              : width == 834
                  ? 1194.0
                  : 900.0;
          tester.view.physicalSize = Size(width, height);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(MaterialApp(
            theme: buildMemberTheme(buildWpccTheme(brightness: brightness)),
            builder: (context, child) => RepaintBoundary(
                key: captureBoundary, child: MemberBackdrop(child: child!)),
            home: MediaQuery(
                data: MediaQueryData(
                    size: Size(width, height),
                    textScaler: TextScaler.linear(scale)),
                child: const Scaffold(body: ProfilePage())),
          ));
          await tester.runAsync(() => ProfileRepository().profile());
          await tester.pumpAndSettle();
          if (scale == 1) {
            final gutter = width < 600 ? 20.0 : 32.0;
            final pageWidth = width > 680 ? 680.0 : width;
            final header = tester.getRect(find.byType(MemberPageHeader));
            expect(
                header.topLeft, Offset((width - pageWidth) / 2 + gutter, 20));
            expect(header.width, pageWidth - 2 * gutter);
          }
          if (Platform.environment['CAPTURE_MEMBER_UI'] == 'true' &&
              (width == 390 || width == 834) &&
              scale == 1) {
            await _capture(
                tester, 'profile-${brightness.name}-${width.toInt()}');
          }
          expect(find.text('Grace Member'), findsOneWidget);
          expect(find.text('My account'), findsOneWidget);
          if (scale == 1) expect(find.text('Account'), findsOneWidget);
          expect(find.text('Member ID: 0123'), findsOneWidget);
          expect(find.text('Active'), findsNothing);
          expect(tester.getSize(find.byTooltip('Change profile photo')).width,
              greaterThanOrEqualTo(48));
          await tester.scrollUntilVisible(find.text('Unavailable'), 200,
              scrollable: find.byType(Scrollable).first);
          expect(find.text('Unavailable'), findsOneWidget);
          expect(tester.takeException(), isNull);
          final scrollable = find
              .descendant(
                  of: find.byType(ListView).first,
                  matching: find.byType(Scrollable))
              .first;
          await tester.scrollUntilVisible(find.text('Personal details'), 250,
              scrollable: scrollable);
          await tester.pumpAndSettle();
          await tester.tap(find.text('Personal details'));
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text('Marital status'));
          await tester.pumpAndSettle();
          expect(find.text('Marital status'), findsOneWidget);
          expect(tester.takeException(), isNull);
          Navigator.of(tester.element(find.text('Marital status'))).pop();
          await tester.pumpAndSettle();
          await tester.scrollUntilVisible(find.byTooltip('App settings'), -250,
              scrollable: scrollable);
          await tester.pumpAndSettle();
          await tester.tap(find.byTooltip('App settings'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Appearance'));
          await tester.pumpAndSettle();
          expect(find.text('Light'), findsOneWidget);
          expect(find.text('Dark'), findsOneWidget);
          await tester.tap(find.text('Dark'));
          await tester.pumpAndSettle();
          expect(ThemePreference.instance.value, ThemeMode.dark);
          expect(find.byType(MemberSheet), findsNothing);
          await tester.scrollUntilVisible(
              find.text('Set or change password'), 250,
              scrollable: scrollable);
          await tester.pumpAndSettle();
          await tester.tap(find.text('Set or change password'));
          await tester.pumpAndSettle();
          expect(find.text('New password'), findsOneWidget);
          expect(find.text('Confirm password'), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        });
      }
    }
  }
}

Future<void> _capture(WidgetTester tester, String name) async {
  final render = captureBoundary.currentContext!.findRenderObject()!
      as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await render.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await File('${Directory.systemTemp.path}/wpcc-member-$name.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}
