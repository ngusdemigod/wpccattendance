import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wpcc_community/core/theme/app_theme.dart';
import 'package:wpcc_community/core/theme/member_theme.dart';
import 'package:wpcc_community/core/widgets/member_components.dart';
import 'package:wpcc_community/core/widgets/member_sheet.dart';
import 'package:wpcc_community/features/data/providers.dart';
import 'package:wpcc_community/features/home/home_page.dart';
import 'package:wpcc_community/features/search/search_page.dart';

void main() {
  testWidgets('Home preserves reference search and latest artwork geometry',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final width in [390.0, 600.0, 834.0, 899.0, 900.0, 1024.0]) {
      tester.view.physicalSize = Size(width, 1194);
      await tester.pumpWidget(ProviderScope(
          overrides: [
            currentProfileProvider
                .overrideWith((_) async => {'full_name': 'Member'}),
            upcomingEventsProvider.overrideWith((_) async => []),
            announcementsProvider.overrideWith((_) async => []),
          ],
          child: MaterialApp(
              theme: buildMemberTheme(buildWpccTheme()),
              home: Scaffold(
                  body: HomePage(
                      loadLatest: () async => [
                            {'id': 'latest', 'title': 'Latest teaching'}
                          ])))));
      await tester.pumpAndSettle();
      final search = find.byType(MemberSearchBar);
      final gutter = width < 600 ? 20.0 : 32.0;
      expect(tester.getSize(search),
          Size(width >= 900 ? 720 : width - gutter * 2, 48));
      expect(tester.getTopLeft(search), Offset(gutter, 80));
      await tester.scrollUntilVisible(find.text('Latest teaching'), 200,
          scrollable: find.byType(Scrollable).first);
      final artwork = find.byType(MemberArtwork);
      expect(tester.getSize(artwork), const Size(64, 66));
      expect(tester.widget<MemberArtwork>(artwork).radius, 12);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('Home filters open a sheet and carry the choice into real Search',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final size in [const Size(390, 844), const Size(834, 1194)]) {
      tester.view.physicalSize = size;
      final router = GoRouter(initialLocation: '/home', routes: [
        GoRoute(
            path: '/home',
            builder: (_, __) =>
                Scaffold(body: HomePage(loadLatest: () async => []))),
        GoRoute(
            path: '/search',
            builder: (_, state) => SearchPage(
                initialFilter: state.uri.queryParameters['filter'] ?? 'All',
                loadSearch: (_) async => [
                      {
                        'section': 'events',
                        'id': 'event',
                        'title': 'Church event'
                      },
                      {
                        'section': 'departments',
                        'id': 'team',
                        'title': 'Church team'
                      },
                    ])),
      ]);
      await tester.pumpWidget(ProviderScope(
          overrides: [
            currentProfileProvider
                .overrideWith((_) async => {'full_name': 'Member'}),
            upcomingEventsProvider.overrideWith((_) async => []),
            announcementsProvider.overrideWith((_) async => []),
          ],
          child: MaterialApp.router(
              routerConfig: router,
              theme: buildMemberTheme(buildWpccTheme()))));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Search filters'));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/home');
      expect(find.byType(MemberSheet), findsOneWidget);
      expect(
          find.descendant(
              of: find.byType(MemberSheet), matching: find.text('Messages')),
          findsNothing);
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/home');
      await tester.tap(find.byTooltip('Search filters'));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(
          of: find.byType(MemberSheet), matching: find.text('Departments')));
      await tester.pumpAndSettle();
      expect(find.byType(MemberSheet), findsNothing);
      expect(
          GoRouterState.of(tester.element(find.byType(SearchPage)))
              .uri
              .queryParameters['filter'],
          'Departments');
      final chip = tester.widget<MemberFilterChip>(
          find.widgetWithText(MemberFilterChip, 'Departments'));
      expect(chip.selected, isTrue);
      await tester.enterText(find.byType(TextField), 'church');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(find.text('Church team'), findsOneWidget);
      expect(find.text('Church event'), findsNothing);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/home');
      await tester.tap(find.byTooltip('Search filters'));
      await tester.pumpAndSettle();
      expect(
          tester
              .widget<MemberListRow>(find.descendant(
                  of: find.byType(MemberSheet),
                  matching: find.widgetWithText(MemberListRow, 'Departments')))
              .selected,
          isTrue);
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      expect(tester.takeException(), isNull);
    }
  });
  testWidgets(
      'appearance uses reference order and persists the real preference',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final original = ThemePreference.instance.value;
    addTearDown(() => ThemePreference.instance.value = original);
    await tester.pumpWidget(ProviderScope(
        overrides: [
          currentProfileProvider
              .overrideWith((_) async => {'full_name': 'Member'}),
          upcomingEventsProvider.overrideWith((_) async => []),
          announcementsProvider.overrideWith((_) async => []),
        ],
        child: MaterialApp(
            theme: buildMemberTheme(buildWpccTheme()),
            home: Scaffold(body: HomePage(loadLatest: () async => [])))));
    await tester.pumpAndSettle();
    for (final mode in [ThemeMode.dark, ThemeMode.light, ThemeMode.system]) {
      await tester.tap(find.byTooltip('Change appearance'));
      await tester.pumpAndSettle();
      final rows = find.descendant(
          of: find.byType(MemberSheet), matching: find.byType(MemberListRow));
      expect(tester.widgetList<MemberListRow>(rows).map((row) => row.title),
          ['Dark', 'Light', 'System']);
      final label = '${mode.name[0].toUpperCase()}${mode.name.substring(1)}';
      await tester.tap(find.widgetWithText(MemberListRow, label));
      await tester.pumpAndSettle();
      expect(find.byType(MemberSheet), findsNothing);
      expect(ThemePreference.instance.value, mode);
      expect((await SharedPreferences.getInstance()).getString('wpcc.theme'),
          mode.name);
    }
    expect(tester.takeException(), isNull);
  });
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await (FontLoader('DM Sans')
          ..addFont(rootBundle.load('assets/DMSans-Regular.ttf')))
        .load();
    await (FontLoader('packages/phosphor_flutter/PhosphorRegular')
          ..addFont(rootBundle
              .load('packages/phosphor_flutter/lib/fonts/Phosphor.ttf')))
        .load();
  });
  testWidgets('quick links use reference order and keep real destinations',
      (tester) async {
    expect(HomePage.actions.map((action) => action.$1), [
      'Departments',
      'Prayer',
      'Devotional',
      'Souls',
      'Give',
      'Classes',
      'Counselling'
    ]);
    expect(HomePage.actions.map((action) => action.$2), [
      '/departments',
      '/prayer-alerts',
      '/devotional',
      '/souls',
      '/give',
      '/profile/classes',
      '/counselling'
    ]);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final action in HomePage.actions.take(5)) {
      final router = GoRouter(initialLocation: '/home', routes: [
        GoRoute(
            path: '/home',
            builder: (_, __) => const Scaffold(body: HomeQuickLinks())),
        GoRoute(
            path: action.$2,
            builder: (_, __) =>
                Scaffold(body: Text('${action.$1} destination'))),
      ]);
      await tester.pumpWidget(MaterialApp.router(
          routerConfig: router,
          theme:
              buildMemberTheme(buildWpccTheme(brightness: Brightness.dark))));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text(action.$1), 80,
          scrollable: find.byType(Scrollable));
      await tester.pumpAndSettle();
      await tester.tap(find.text(action.$1));
      await tester.pumpAndSettle();
      expect(find.text('${action.$1} destination'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
    }
  });

  testWidgets('quick-link patterns stay circular at phone and tablet sizes',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final brightness in Brightness.values) {
      for (final size in [const Size(390, 844), const Size(834, 1194)]) {
        tester.view.physicalSize = size;
        await tester.pumpWidget(MaterialApp(
            theme: buildMemberTheme(buildWpccTheme(brightness: brightness)),
            home: const Scaffold(body: HomeQuickLinks())));
        await tester.pumpAndSettle();
        for (final action in HomePage.actions) {
          final art = find.byKey(ValueKey('quick-link-pattern:${action.$2}'));
          await tester.scrollUntilVisible(art, 80,
              scrollable: find.byType(Scrollable));
          await tester.pumpAndSettle();
          expect(tester.getSize(art), Size.square(size.width < 600 ? 70 : 78));
          expect(find.ancestor(of: art, matching: find.byType(ClipOval)),
              findsOneWidget);
          final painter = tester.widget<CustomPaint>(art).painter!;
          expect(painter.shouldRepaint(painter), isFalse);
          final icon = tester.widget<Icon>(
              find.descendant(of: art, matching: find.byType(Icon)));
          expect(icon.icon, action.$3);
          expect(icon.size, 30);
          expect(icon.color, Colors.white);

          final recorder = ui.PictureRecorder();
          painter.paint(Canvas(recorder), const Size(100, 100));
          final picture = recorder.endRecording();
          await tester.runAsync(() async {
            final image = await picture.toImage(100, 100);
            final bytes = await image.toByteData();
            int red(int x, int y) => bytes!.getUint8((y * 100 + x) * 4);
            int green(int x, int y) => bytes!.getUint8((y * 100 + x) * 4 + 1);
            int blue(int x, int y) => bytes!.getUint8((y * 100 + x) * 4 + 2);
            final upper = [red(20, 30), green(20, 30), blue(20, 30)];
            final lower = [red(20, 80), green(20, 80), blue(20, 80)];
            if (HomePage.actions.indexOf(action) < 5) {
              expect(lower, isNot(upper), reason: action.$1);
            } else {
              expect(lower, upper);
            }
            image.dispose();
          });
          picture.dispose();
          expect(tester.takeException(), isNull);
        }
        await tester.pumpWidget(const SizedBox());
      }
    }
  });

  testWidgets('home adapts to phone, tablet, dark mode and enlarged text',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final boundary = GlobalKey();
    for (final brightness in Brightness.values) {
      for (final width in [320.0, 390.0, 393.0, 600.0, 768.0, 834.0, 1024.0]) {
        for (final scale in [1.0, 1.6, 2.0]) {
          tester.view.physicalSize = Size(width, width == 834 ? 1194 : 844);
          await tester.pumpWidget(ProviderScope(
            overrides: [
              currentProfileProvider
                  .overrideWith((ref) async => {'full_name': 'WPCC Member'}),
              upcomingEventsProvider.overrideWith((ref) async => [
                    {
                      'event_id': 'fixture',
                      'title': 'Sunday celebration',
                      'event_start_at': '2026-10-04T09:00:00Z'
                    },
                  ]),
              announcementsProvider.overrideWith((ref) async => [
                    {
                      'title': 'Welcome to the community',
                      'body': 'Our latest community news.'
                    },
                  ]),
            ],
            child: MaterialApp(
              theme: buildMemberTheme(buildWpccTheme(brightness: brightness)),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: Scaffold(
                  body: RepaintBoundary(
                      key: boundary,
                      child: MemberBackdrop(
                          child: HomePage(loadLatest: () async => [])))),
            ),
          ));
          await tester.pumpAndSettle();
          expect(find.text('WPCC'), findsOneWidget);
          expect(find.text('Daily Tasks'), findsOneWidget);
          expect(find.text('Church life'), findsNothing);
          final seeAll = tester
              .widget<TextButton>(find.widgetWithText(TextButton, 'See all'));
          final seeAllStyle = seeAll.style!.textStyle!.resolve({})!;
          expect(seeAllStyle.fontWeight, FontWeight.w300);
          expect(seeAllStyle.fontFamily,
              GoogleFonts.dmSans(fontWeight: FontWeight.w300).fontFamily);
          expect(find.text('Sunday celebration'), findsWidgets);
          expect(tester.getTopLeft(find.byType(MemberPosterCard)).dy,
              lessThan(tester.getTopLeft(find.text('Quick links')).dy));
          expect(tester.takeException(), isNull);
          if (Platform.environment['CAPTURE_HOME'] == 'true' &&
              (width == 390 || width == 834) &&
              scale == 1) {
            await tester.runAsync(() => precacheImage(
                const AssetImage('assets/images/wpcc_logo.png'),
                boundary.currentContext!));
            await tester.pumpAndSettle();
            final render = boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
            await tester.runAsync(() async {
              final picture = await render.toImage(pixelRatio: 2);
              final bytes =
                  await picture.toByteData(format: ui.ImageByteFormat.png);
              await File(
                      '${Directory.systemTemp.path}/wpcc-home-${width.toInt()}-${brightness.name}.png')
                  .writeAsBytes(bytes!.buffer.asUint8List());
              picture.dispose();
            });
          }
          await tester.drag(find.byType(ListView).first, const Offset(0, -650));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        }
      }
    }
  });

  testWidgets('home errors can be retried without losing shortcuts',
      (tester) async {
    var attempts = 0;
    await tester.pumpWidget(ProviderScope(
        overrides: [
          currentProfileProvider
              .overrideWith((ref) async => {'full_name': 'Member'}),
          upcomingEventsProvider.overrideWith((ref) async {
            if (attempts++ == 0) throw StateError('Offline');
            return [
              {'event_id': 'retry', 'title': 'Restored event'}
            ];
          }),
          announcementsProvider.overrideWith((ref) async => []),
        ],
        child: MaterialApp(
            home: Scaffold(body: HomePage(loadLatest: () async => [])))));
    await tester.pumpAndSettle();
    expect(find.text('Events unavailable'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Restored event'), findsOneWidget);
    expect(find.text('Devotional'), findsOneWidget);
  });

  testWidgets('home shortcuts keep their destinations', (tester) async {
    final router = GoRouter(initialLocation: '/home', routes: [
      GoRoute(
          path: '/home',
          builder: (_, __) =>
              Scaffold(body: HomePage(loadLatest: () async => []))),
      GoRoute(
          path: '/devotional',
          builder: (_, __) =>
              const Scaffold(body: Text('Devotional destination'))),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(overrides: [
      currentProfileProvider
          .overrideWith((ref) async => {'full_name': 'Member'}),
      upcomingEventsProvider.overrideWith((ref) async => []),
      announcementsProvider.overrideWith((ref) async => []),
    ], child: MaterialApp.router(routerConfig: router)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.ensureVisible(find.text('Devotional'));
    await tester.tap(find.text('Devotional'));
    await tester.pumpAndSettle();
    expect(find.text('Devotional destination'), findsOneWidget);
  });

  testWidgets('unimplemented home shortcuts stay disabled', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(ProviderScope(
        overrides: [
          currentProfileProvider
              .overrideWith((ref) async => {'full_name': 'Member'}),
          upcomingEventsProvider.overrideWith((ref) async => []),
          announcementsProvider.overrideWith((ref) async => []),
        ],
        child: MaterialApp(
            home: Scaffold(body: HomePage(loadLatest: () async => [])))));
    await tester.pumpAndSettle();
    for (final label in ['Classes', 'Counselling']) {
      final ink = tester.widget<InkWell>(
          find.ancestor(of: find.text(label), matching: find.byType(InkWell)));
      expect(ink.onTap, isNull);
    }
    expect(
        tester
            .getSemantics(find.bySemanticsLabel('Devotional'))
            .getSemanticsData()
            .hasAction(ui.SemanticsAction.tap),
        isTrue);
    expect(
        tester
            .getSemantics(find.bySemanticsLabel('Classes, coming soon'))
            .getSemanticsData()
            .hasAction(ui.SemanticsAction.tap),
        isFalse);
    semantics.dispose();
  });

  testWidgets('home groups real events and opens announcement and message',
      (tester) async {
    tester.view.physicalSize = const Size(834, 1194);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(initialLocation: '/home', routes: [
      GoRoute(
          path: '/home',
          builder: (_, __) => Scaffold(
              body: HomePage(
                  loadLatest: () async => [
                        {
                          'id': 'latest',
                          'title': 'A faithful community',
                          'source_published_at': '2026-10-01T09:00:00Z',
                        }
                      ]))),
      GoRoute(
          path: '/media/:id',
          builder: (_, state) =>
              Scaffold(body: Text('Message ${state.pathParameters['id']}'))),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(overrides: [
      currentProfileProvider
          .overrideWith((ref) async => {'full_name': 'Member'}),
      upcomingEventsProvider.overrideWith((ref) async => [
            {'event_id': 'church', 'title': 'Church gathering'},
            {
              'event_id': 'department',
              'title': 'Team gathering',
              'department_id': 'music'
            },
          ]),
      announcementsProvider.overrideWith((ref) async => [
            {
              'title': 'Community update',
              'body': 'The full announcement remains available.'
            }
          ]),
    ], child: MaterialApp.router(routerConfig: router)));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(MemberFilterChip, 'Church'));
    await tester.pumpAndSettle();
    expect(find.text('Church gathering'), findsOneWidget);
    expect(find.text('Team gathering'), findsNothing);
    await tester.tap(find.widgetWithText(MemberFilterChip, 'Departments'));
    await tester.pumpAndSettle();
    expect(find.text('Church gathering'), findsNothing);
    expect(find.text('Team gathering'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Community update'), 350,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Community update'));
    await tester.pumpAndSettle();
    expect(
        find.text('The full announcement remains available.'), findsOneWidget);
    Navigator.of(tester
            .element(find.text('The full announcement remains available.')))
        .pop();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('A faithful community'), 350,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('A faithful community'));
    await tester.pumpAndSettle();
    expect(find.text('Message latest'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
