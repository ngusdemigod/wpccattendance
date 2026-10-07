import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wpcc_community/app/app_shell.dart';
import 'package:wpcc_community/core/theme/app_theme.dart';
import 'package:wpcc_community/core/theme/member_theme.dart';
import 'package:wpcc_community/core/widgets/member_components.dart';
import 'package:wpcc_community/core/widgets/member_sheet.dart';
import 'package:wpcc_community/core/widgets/member_skeleton.dart';
import 'package:wpcc_community/features/departments/departments_page.dart';
import 'package:wpcc_community/features/data/providers.dart';
import 'package:wpcc_community/features/events/events_page.dart';
import 'package:wpcc_community/features/home/home_page.dart';
import 'package:wpcc_community/features/search/search_filter_sheet.dart';
import 'package:wpcc_community/features/search/search_page.dart';

Widget _app(
        Widget page, Brightness brightness, double scale, GlobalKey boundary) =>
    MaterialApp(
      theme: buildMemberTheme(buildWpccTheme(brightness: brightness)),
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!),
      home: RepaintBoundary(
          key: boundary, child: MemberBackdrop(child: Scaffold(body: page))),
    );

Future<void> _capture(WidgetTester tester, GlobalKey key, String name) async {
  if (Platform.environment['CAPTURE_MEMBER_UI'] != 'true') return;
  await tester.pumpAndSettle();
  final render =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final picture = await render.toImage(pixelRatio: 2);
    final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
    await File('${Directory.systemTemp.path}/wpcc-member-$name.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
    picture.dispose();
  });
}

final departments = <Map<String, dynamic>>[
  {
    'department_id': 'music',
    'name': 'Music ministry',
    'description': 'Worship and music',
    'is_member': true,
    'member_count': 18
  },
  {
    'department_id': 'welcome',
    'name': 'Welcome team',
    'description': 'A warm welcome for everyone',
    'status': 'pending'
  },
];
final results = <Map<String, dynamic>>[
  {
    'section': 'events',
    'id': 'church',
    'title': 'Sunday celebration',
    'subtitle': 'Wisdom Power Christian Centre'
  },
  {
    'section': 'departments',
    'id': 'music',
    'title': 'Music ministry',
    'subtitle': 'Worship and music'
  },
];

void main() {
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
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
      'member search selection survives Back, dock navigation and rotation',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final brightness in Brightness.values) {
      for (final size in [const Size(390, 844), const Size(834, 1194)]) {
        tester.view.physicalSize = size;
        final router = GoRouter(initialLocation: '/home', routes: [
          ShellRoute(
              builder: (_, state, child) => MemberTheme(
                  child: MemberSearchScope(child: AppShell(child: child))),
              routes: [
                GoRoute(
                    path: '/home',
                    builder: (_, __) => HomePage(loadLatest: () async => [])),
                GoRoute(
                    path: '/events',
                    builder: (_, __) => EventsPage(
                        loadEvents: ({required limit, required offset}) async =>
                            [],
                        loadRecurring: () async => [])),
                GoRoute(
                    path: '/search',
                    builder: (_, state) => SearchPage(
                        initialFilter: state.uri.queryParameters['filter'],
                        loadSearch: (_) async => results)),
              ]),
          GoRoute(
              path: '/outside',
              builder: (_, __) =>
                  const Scaffold(body: Text('Outside member shell'))),
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
                theme: buildWpccTheme(brightness: brightness))));
        await tester.pumpAndSettle();

        Future<void> expectSheetChoice(String choice) async {
          await tester.tap(find.byTooltip('Search filters'));
          await tester.pumpAndSettle();
          final rows = find.descendant(
              of: find.byType(MemberSheet),
              matching: find.byType(MemberListRow));
          expect(
              tester
                  .widgetList<MemberListRow>(rows)
                  .where((row) => row.selected == true)
                  .map((row) => row.title),
              [choice]);
        }

        Future<void> expectChipChoice(String choice) async {
          final page = find.byType(SearchPage).evaluate().isNotEmpty
              ? find.byType(SearchPage)
              : find.byType(EventsPage);
          final body = find
              .descendant(of: page, matching: find.byType(Scrollable))
              .first;
          tester.state<ScrollableState>(body).position.jumpTo(0);
          await tester.pumpAndSettle();
          final chip = find.widgetWithText(MemberFilterChip, choice);
          final position = tester
              .element(find
                  .descendant(of: page, matching: find.byType(MemberFilterChip))
                  .first)
              .findAncestorStateOfType<ScrollableState>()!
              .position;
          position.jumpTo(0);
          await tester.pumpAndSettle();
          if (chip.evaluate().isEmpty) {
            position.jumpTo(position.maxScrollExtent);
            await tester.pumpAndSettle();
          }
          expect(tester.widget<MemberFilterChip>(chip).selected, isTrue);
        }

        // Home has no filter button; its search bar opens Search at All.
        expect(find.byTooltip('Search filters'), findsNothing);
        await tester.tap(find.byType(MemberSearchBar));
        await tester.pumpAndSettle();
        expect(find.byType(SearchPage), findsOneWidget);
        await expectChipChoice('All');
        await expectSheetChoice('All');
        await tester.tap(find.descendant(
            of: find.byType(MemberSheet), matching: find.text('Events')));
        await tester.pumpAndSettle();
        await expectChipChoice('Events');
        await tester.tap(find.widgetWithText(MemberFilterChip, 'Departments'));
        await tester.pumpAndSettle();
        await expectSheetChoice('Departments');
        await tester.tap(find.byTooltip('Close'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Back'));
        await tester.pumpAndSettle();
        expect(find.byType(SearchPage), findsNothing);
        expect(find.byTooltip('Search filters'), findsNothing);

        // The Events search bar has no filter button either and opens Search
        // at Events. The Events page keeps its own local chip meanwhile.
        await tester.tap(find.byTooltip('Events'));
        await tester.pumpAndSettle();
        expect(find.byTooltip('Search filters'), findsNothing);
        await tester.tap(find.widgetWithText(MemberFilterChip, 'Church'));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(MemberSearchBar));
        await tester.pumpAndSettle();
        await expectChipChoice('Events');
        await expectSheetChoice('Events');
        final people = find.descendant(
            of: find.byType(MemberSheet), matching: find.text('People'));
        await tester.ensureVisible(people);
        await tester.pumpAndSettle();
        await tester.tap(people);
        await tester.pumpAndSettle();
        await expectChipChoice('People');
        tester.view.physicalSize =
            size.width == 390 ? const Size(834, 1194) : const Size(390, 844);
        await tester.pumpAndSettle();
        await expectChipChoice('People');
        await tester.tap(find.byTooltip('Back'));
        await tester.pumpAndSettle();
        await expectChipChoice('Church');

        // A search opened without an explicit filter keeps the last section.
        router.push('/search');
        await tester.pumpAndSettle();
        await expectChipChoice('People');
        await expectSheetChoice('People');
        await tester.tap(find.byTooltip('Close'));
        await tester.pumpAndSettle();
        router.pop();
        await tester.pumpAndSettle();
        router.push('/search?filter=Announcements');
        await tester.pumpAndSettle();
        await expectChipChoice('Announcements');
        router.pop();
        await tester.pumpAndSettle();
        router.push('/search');
        await tester.pumpAndSettle();
        await expectChipChoice('Announcements');
        await expectSheetChoice('Announcements');
        await tester.tap(find.byTooltip('Close'));
        await tester.pumpAndSettle();
        router.pop();
        await tester.pumpAndSettle();
        router.push('/search?filter=Messages');
        await tester.pumpAndSettle();
        await expectChipChoice('All');
        expect(find.text('Messages'), findsNothing);
        await tester.tap(find.widgetWithText(MemberFilterChip, 'Events'));
        await tester.pumpAndSettle();

        // Leaving the member shell discards the selection.
        router.go('/outside');
        await tester.pumpAndSettle();
        expect(find.byType(MemberSearchScope), findsNothing);
        router.go('/home');
        await tester.pumpAndSettle();
        router.push('/search');
        await tester.pumpAndSettle();
        await expectChipChoice('All');
        await expectSheetChoice('All');
        await tester.tap(find.byTooltip('Close'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        router.dispose();
      }
    }
  });

  testWidgets(
      'unsupported initial filters fall back to the existing All section',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: SearchPage(
            initialFilter: 'Messages', loadSearch: (_) async => results)));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<MemberFilterChip>(
                find.widgetWithText(MemberFilterChip, 'All'))
            .selected,
        isTrue);
    expect(find.text('Messages'), findsNothing);
    await tester.enterText(find.byType(TextField), 'church');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(find.text('Sunday celebration'), findsOneWidget);
    expect(find.text('Music ministry'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reference filter sheet selects existing search sections only',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        theme: buildMemberTheme(buildWpccTheme()),
        home: SearchPage(loadSearch: (_) async => results)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'church');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Search filters'));
    await tester.pumpAndSettle();
    final rows = find.descendant(
        of: find.byType(MemberSheet), matching: find.byType(MemberListRow));
    expect(tester.widgetList<MemberListRow>(rows).map((row) => row.title),
        [
          'All',
          'Events',
          'Departments',
          'Announcements',
          'Media',
          'Audio',
          'Devotional',
          'Classes',
          'People'
        ]);
    expect(tester.widgetList<MemberListRow>(rows).first.selected, isTrue);
    expect(find.text('Messages'), findsNothing);
    await tester.tap(find.descendant(
        of: find.byType(MemberSheet), matching: find.text('Departments')));
    await tester.pumpAndSettle();
    expect(find.byType(MemberSheet), findsNothing);
    expect(find.text('Music ministry'), findsOneWidget);
    expect(find.text('Sunday celebration'), findsNothing);
    await tester.tap(find.byTooltip('Search filters'));
    await tester.pumpAndSettle();
    expect(
        tester
            .widgetList<MemberListRow>(rows)
            .singleWhere((row) => row.title == 'Departments')
            .selected,
        isTrue);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('department and search rows match reference thumbnail geometry',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final brightness in Brightness.values) {
      for (final width in [390.0, 834.0, 1024.0]) {
        tester.view.physicalSize = Size(width, width == 834 ? 1194 : 844);
        final boundary = GlobalKey();
        await tester.pumpWidget(_app(
            DepartmentsPage(loadDepartments: () async => departments),
            brightness,
            1,
            boundary));
        await tester.pumpAndSettle();
        expect(find.text('Your departments'), findsOneWidget);
        expect(find.text('Pending requests'), findsOneWidget);
        for (final art in find.byType(MemberArtwork).evaluate()) {
          expect(tester.getSize(find.byWidget(art.widget)), const Size(48, 48));
        }
        await tester.pumpWidget(_app(
            SearchPage(loadSearch: (_) async => results),
            brightness,
            1,
            boundary));
        await tester.pumpAndSettle();
        final search = find.byType(MemberSearchBar);
        expect(tester.getSize(search),
            Size(width >= 900 ? 720 : width - (width < 600 ? 40 : 64), 48));
        expect(tester.getTopLeft(search), Offset(width < 600 ? 20 : 32, 88));
        await tester.enterText(find.byType(TextField), 'church');
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle();
        for (final art in find.byType(MemberArtwork).evaluate()) {
          expect(tester.getSize(find.byWidget(art.widget)), const Size(64, 66));
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      }
    }
  });

  testWidgets('departments and search adapt in both themes with enlarged text',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final boundary = GlobalKey();
    for (final brightness in Brightness.values) {
      for (final width in [320.0, 390.0, 393.0, 600.0, 768.0, 834.0, 1024.0]) {
        for (final scale in [1.0, 1.6, 2.0]) {
          tester.view.physicalSize = Size(width, width == 834 ? 1194 : 844);
          await tester.pumpWidget(_app(
              DepartmentsPage(loadDepartments: () async => departments),
              brightness,
              scale,
              boundary));
          await tester.pumpAndSettle();
          expect(find.text('Music ministry'), findsOneWidget);
          final pending = tester.widget<MemberListRow>(find.ancestor(
              of: find.text('Welcome team'),
              matching: find.byType(MemberListRow)));
          expect(pending.onTap, isNull);
          if ((width == 390 || width == 834) && scale == 1) {
            await _capture(tester, boundary,
                'departments-${width.toInt()}-${brightness.name}');
          }
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(_app(
              SearchPage(loadSearch: (_) async => results),
              brightness,
              scale,
              boundary));
          await tester.pumpAndSettle();
          expect(find.text('Explore'), findsOneWidget);
          if ((width == 390 || width == 834) && scale == 1) {
            await _capture(tester, boundary,
                'search-empty-${width.toInt()}-${brightness.name}');
          }
          await tester.enterText(find.byType(TextField), 'church');
          await tester.pump(const Duration(milliseconds: 350));
          await tester.pumpAndSettle();
          expect(find.text('Sunday celebration'), findsOneWidget);
          if ((width == 390 || width == 834) && scale == 1) {
            await _capture(
                tester, boundary, 'search-${width.toInt()}-${brightness.name}');
          }
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        }
      }
    }
  });

  testWidgets('departments recover from errors and retain detail route data',
      (tester) async {
    var attempts = 0;
    final router = GoRouter(initialLocation: '/departments', routes: [
      GoRoute(
          path: '/departments',
          builder: (_, __) =>
              Scaffold(body: DepartmentsPage(loadDepartments: () async {
                if (attempts++ == 0) throw StateError('offline');
                return departments;
              }))),
      GoRoute(
          path: '/departments/:id',
          builder: (_, state) => Scaffold(
              body: Text(
                  '${state.pathParameters['id']}: ${(state.extra as Map)['name']}'))),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Music ministry'));
    await tester.pumpAndSettle();
    expect(find.text('music: Music ministry'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'search ignores stale responses, filters results and clears input',
      (tester) async {
    final first = Completer<List<Map<String, dynamic>>>();
    final second = Completer<List<Map<String, dynamic>>>();
    await tester.pumpWidget(MaterialApp(
        home: SearchPage(
            loadSearch: (query) =>
                query == 'first' ? first.future : second.future)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'first');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.enterText(find.byType(TextField), 'second');
    await tester.pump(const Duration(milliseconds: 350));
    second.complete(results);
    await tester.pumpAndSettle();
    first.complete([
      {'title': 'Stale event', 'section': 'events', 'id': 'stale'}
    ]);
    await tester.pumpAndSettle();
    expect(find.text('Stale event'), findsNothing);
    await tester.tap(find.widgetWithText(MemberFilterChip, 'Events'));
    await tester.pumpAndSettle();
    expect(find.text('Sunday celebration'), findsOneWidget);
    expect(find.text('Music ministry'), findsNothing);
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();
    expect(find.text('Explore'), findsOneWidget);
    expect(find.text('Sunday celebration'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('search submission saves history and history can be removed',
      (tester) async {
    await tester.pumpWidget(
        MaterialApp(home: SearchPage(loadSearch: (_) async => results)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'church');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(
        (await SharedPreferences.getInstance())
            .getStringList('wpcc_recent_searches'),
        ['church']);
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();
    expect(find.text('Recent searches'), findsOneWidget);
    await tester.tap(find.byTooltip('Remove church from recent searches'));
    await tester.pumpAndSettle();
    expect(find.text('Recent searches'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'editing a query shows pending feedback before debounce completes',
      (tester) async {
    final first = Completer<List<Map<String, dynamic>>>();
    await tester.pumpWidget(MaterialApp(
        home: SearchPage(
            loadSearch: (query) =>
                query == 'first' ? first.future : Future.value(results))));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'first');
    await tester.pump();
    expect(find.text('No results'), findsNothing);
    expect(find.byType(MemberSkeleton), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 350));
    await tester.enterText(find.byType(TextField), 'second');
    first.complete([
      {'title': 'Stale event', 'section': 'events', 'id': 'stale'}
    ]);
    await tester.pump();
    expect(find.text('Stale event'), findsNothing);
    expect(find.byType(MemberSkeleton), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(find.text('Sunday celebration'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('clearing input immediately invalidates an in-flight search',
      (tester) async {
    final pending = Completer<List<Map<String, dynamic>>>();
    await tester.pumpWidget(
        MaterialApp(home: SearchPage(loadSearch: (_) => pending.future)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'church');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.byTooltip('Clear search'));
    pending.complete(results);
    await tester.pump();
    expect(find.text('Explore'), findsOneWidget);
    expect(find.text('Sunday celebration'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
