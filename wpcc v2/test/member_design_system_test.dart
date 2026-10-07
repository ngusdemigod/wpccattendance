import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wpcc_community/app/app_shell.dart';
import 'package:wpcc_community/core/theme/app_theme.dart';
import 'package:wpcc_community/core/theme/member_theme.dart';
import 'package:wpcc_community/core/widgets/member_components.dart';
import 'package:wpcc_community/features/departments/departments_page.dart';
import 'package:wpcc_community/features/devotional/devotional_page.dart';
import 'package:wpcc_community/features/media/media_player_controller.dart';
import 'package:wpcc_community/features/media/media_episode_detail_page.dart';
import 'package:wpcc_community/features/media/media_page.dart';
import 'package:wpcc_community/features/prayer/prayer_alerts_content.dart';
import 'package:wpcc_community/features/search/search_page.dart';
import 'package:wpcc_community/features/souls/souls_page.dart';

const widths = [320.0, 390.0, 393.0, 600.0, 768.0, 834.0, 1024.0];
const scales = [1.0, 1.6, 2.0];
const department = {
  'department_id': 'team',
  'name': 'Creative Arts and Worship Department',
  'status': 'pending',
  'member_count': 12,
  'is_primary': false,
};
const prayer = {
  'id': 'personal',
  'title': 'Morning prayer and thanksgiving',
  'scope': 'personal',
  'local_time': '06:30:00',
  'days_of_week': [1, 2, 3, 4, 5, 6, 7],
  'is_active': true,
  'audio_title': 'Praying with the church',
  'duration_seconds': 900,
};
const post = {
  'id': 'post',
  'title': 'A life rooted in wisdom and kindness',
  'body':
      'A thoughtful reflection for our community. Read and reflect together.',
  'created_at': '2026-10-02T08:00:00Z',
  'more': {'author': 'WPCC', 'tag': 'Faith'},
};
const soul = {
  'id': 'soul',
  'full_name': 'A member with a long display name',
  'status': 'awaiting_contact',
};

void main() {
  testWidgets('dock glides, redirects mid-flight and respects reduced motion',
      (tester) async {
    for (final reduced in [false, true]) {
      final router = GoRouter(initialLocation: '/home', routes: [
        ShellRoute(
            builder: (_, __, child) =>
                MemberTheme(child: AppShell(child: child)),
            routes: [
              for (final path in [
                '/home',
                '/events',
                '/media',
                '/give',
                '/profile'
              ])
                GoRoute(path: path, builder: (_, __) => const SizedBox()),
            ]),
      ]);
      await tester.pumpWidget(MaterialApp.router(
        routerConfig: router,
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
            child: child!),
      ));
      await tester.pumpAndSettle();
      final marker = find.byKey(const ValueKey('dock-selection'));
      final start = tester.getCenter(marker).dx;
      await tester.tap(find.byTooltip('Profile'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      final mid = tester.getCenter(marker).dx;
      expect(mid, greaterThan(start));
      final target = tester.getCenter(find.byTooltip('Profile')).dx;
      if (reduced) {
        expect(mid, closeTo(target, .1));
      } else {
        expect(mid, lessThan(target));
      }
      await tester.tap(find.byTooltip('Events'));
      await tester.pump();
      if (!reduced) expect(tester.getCenter(marker).dx, closeTo(mid, .1));
      await tester.pumpAndSettle();
      expect(tester.getCenter(marker).dx,
          closeTo(tester.getCenter(find.byTooltip('Events')).dx, .1));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
    }
  });
  test('dock selects only corresponding primary views', () {
    const shell = AppShell(child: SizedBox());
    for (final entry in {
      '/home': 0,
      '/events': 1,
      '/events/event': 1,
      '/media': 2,
      '/media/message': 2,
      '/give': 3,
      '/profile': 4,
      '/departments': -1,
      '/search': -1,
      '/prayer-alerts': -1,
      '/devotional': -1,
      '/souls': -1,
    }.entries) {
      expect(shell.indexFor(entry.key), entry.value);
    }
  });
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await (FontLoader(buildWpccTheme().textTheme.bodyMedium!.fontFamily!)
          ..addFont(rootBundle.load('assets/DMSans-Regular.ttf'))
          ..addFont(rootBundle.load('assets/DMSans-Medium.ttf'))
          ..addFont(rootBundle.load('assets/DMSans-SemiBold.ttf'))
          ..addFont(rootBundle.load('assets/DMSans-Bold.ttf')))
        .load();
    await (FontLoader('packages/phosphor_flutter/PhosphorRegular')
          ..addFont(rootBundle
              .load('packages/phosphor_flutter/lib/fonts/Phosphor.ttf')))
        .load();
    await (FontLoader('packages/phosphor_flutter/PhosphorFill')
          ..addFont(rootBundle
              .load('packages/phosphor_flutter/lib/fonts/Phosphor-Fill.ttf')))
        .load();
  });

  test('member styling does not mutate the protected global theme', () {
    for (final brightness in Brightness.values) {
      final base = buildWpccTheme(brightness: brightness);
      final member = buildMemberTheme(base);
      expect(base.textTheme.headlineSmall!.fontSize, 23);
      expect(member.textTheme.headlineSmall!.fontSize, 24);
      expect(base.scaffoldBackgroundColor, Colors.transparent);
      expect(member.scaffoldBackgroundColor, Colors.transparent);
      for (final style in [
        member.textTheme.headlineSmall,
        member.textTheme.titleLarge,
        member.textTheme.bodyMedium,
        member.textTheme.bodySmall,
        member.textTheme.labelSmall
      ]) {
        expect(style!.letterSpacing, 0);
        expect(style.fontFamily, 'DM Sans');
      }
      final colors = member.colorScheme;
      final backdrops = brightness == Brightness.dark
          ? const [
              Color(0xFF3A1E25),
              Color(0xFF271D21),
              Color(0xFF151517),
              Color(0xFF182411),
              Color(0xFF202317),
              Color(0xFF110D0B),
              Color(0xFF090A08)
            ]
          : const [
              Color(0xFFF1E4E9),
              Color(0xFFF4EDF0),
              Color(0xFFF7F7F8),
              Color(0xFFE4EADF),
              Color(0xFFF0F0E8)
            ];
      for (final background in backdrops) {
        for (final surface in [
          colors.surface,
          colors.surfaceContainerLow,
          colors.primaryContainer
        ]) {
          final composited = Color.alphaBlend(surface, background);
          expect(_contrast(colors.onSurface, composited),
              greaterThanOrEqualTo(4.5));
          expect(_contrast(colors.onSurfaceVariant, composited),
              greaterThanOrEqualTo(4.5));
        }
      }
      expect(_contrast(colors.onPrimary, colors.primary),
          greaterThanOrEqualTo(4.5));
    }
  });

  testWidgets('utility buttons retain semantic labels and 48px targets',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(MaterialApp(
        theme: buildMemberTheme(buildWpccTheme()),
        home: Scaffold(
            body: MemberIconButton(
                icon: PhosphorIconsRegular.magnifyingGlass,
                label: 'Search',
                onPressed: () {}))));
    expect(find.byTooltip('Search'), findsOneWidget);
    final size = tester.getSize(find.byType(IconButton));
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
    semantics.dispose();
  });

  testWidgets('search matches reference insets, icons and bounded material',
      (tester) async {
    var filters = 0;
    for (final solid in [false, true]) {
      await tester.pumpWidget(MaterialApp(
          theme: buildMemberTheme(buildWpccTheme()),
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(highContrast: solid),
              child: child!),
          home: Scaffold(
              body: Padding(
                  padding: const EdgeInsets.all(20),
                  child: MemberSearchBar(onFilter: () => filters++)))));
      await tester.pumpAndSettle();
      final search = find.byType(MemberSearchBar);
      final filter = find.byTooltip('Search filters');
      expect(tester.getSize(search).height, 48);
      expect(tester.getSize(filter), const Size(48, 48));
      expect(tester.getTopRight(search).dx - tester.getTopRight(filter).dx, 14);
      final icon = tester.widget<Icon>(
          find.descendant(of: filter, matching: find.byType(Icon)));
      expect(icon.size, 21);
      final clip = tester.widget<ClipRRect>(
          find.descendant(of: search, matching: find.byType(ClipRRect)));
      expect(clip.borderRadius, BorderRadius.circular(26));
      final backdrop = find.descendant(
          of: search, matching: find.byType(BackdropFilter));
      if (solid) {
        expect(backdrop, findsNothing);
      } else {
        expect(tester.widget<BackdropFilter>(backdrop).filter,
            ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24));
      }
      await tester.tap(filter);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    expect(filters, 2);
  });

  test('poster text remains legible over a white church flyer', () {
    final background =
        Color.alphaBlend(MemberPosterCard.textScrim, Colors.white);
    expect(_contrast(Colors.white, background), greaterThanOrEqualTo(4.5));
    expect(_contrast(const Color(0xFFE5E5E5), background),
        greaterThanOrEqualTo(4.5));
  });

  testWidgets('poster exposes a working screen-reader tap action',
      (tester) async {
    var taps = 0;
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(MaterialApp(
        theme: buildMemberTheme(buildWpccTheme()),
        home: Scaffold(
            body: MemberPosterCard(
                title: 'Sunday service',
                metadata: '4 October',
                imageUrl: '',
                onTap: () => taps++))));
    final node =
        tester.getSemantics(find.bySemanticsLabel('Sunday service, 4 October'));
    expect(node.getSemanticsData().hasAction(ui.SemanticsAction.tap), isTrue);
    tester.binding.rootPipelineOwner.visitChildren((owner) {
      owner.semanticsOwner?.performAction(node.id, ui.SemanticsAction.tap);
    });
    expect(taps, 1);
    handle.dispose();
  });

  final pages = <String, Widget Function()>{
    'departments': () =>
        DepartmentsPage(loadDepartments: () async => [department]),
    'prayer': () => Scaffold(
        body: PrayerAlertsContent(
            onBack: () {},
            alerts: [
              {...prayer, 'id': 'church', 'scope': 'global'},
              prayer
            ],
            onRefresh: () async {},
            onTap: (_) {},
            onStart: (_) {},
            onCalendar: (_) {},
            onToggle: (_, __) {})),
    'devotional': () => DevotionalPage(
        loadPosts: ({int offset = 0, int limit = 20}) async => [
              post,
              {...post, 'id': 'older', 'title': 'Walking together in faith'}
            ]),
    'souls': () => SoulsPage(loadSouls: () async => [soul]),
    'search': () => SearchPage(
        loadSearch: (_) async => [
              {
                'id': 'event',
                'section': 'events',
                'title': 'Sunday celebration',
                'subtitle': '4 October'
              },
              {
                'id': 'department',
                'section': 'departments',
                'title': 'Worship team',
                'subtitle': 'Members'
              },
            ]),
  };
  for (final entry in pages.entries) {
    testWidgets('${entry.key} supports both themes, all widths and large text',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      for (final brightness in Brightness.values) {
        for (final width in widths) {
          for (final scale in scales) {
            tester.view.physicalSize = Size(width, width == 834 ? 1194 : 844);
            final boundary = GlobalKey();
            await tester.pumpWidget(MaterialApp(
              theme: buildMemberTheme(buildWpccTheme(brightness: brightness)),
              builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                      textScaler: TextScaler.linear(scale),
                      padding: const EdgeInsets.only(bottom: 34),
                      disableAnimations: true),
                  child: child!),
              home: RepaintBoundary(
                  key: boundary, child: MemberBackdrop(child: entry.value())),
            ));
            await tester.pumpAndSettle();
            if (entry.key == 'search') {
              await tester.enterText(find.byType(TextField), 'church');
              await tester.pump(const Duration(milliseconds: 400));
              await tester.pumpAndSettle();
              expect(find.text('Sunday celebration'), findsOneWidget);
            }
            expect(tester.takeException(), isNull,
                reason: '${entry.key} $brightness $width scale $scale');
            if (Platform.environment['CAPTURE_MEMBER_UI'] == 'true' &&
                (width == 390 || width == 834) &&
                scale == 1) {
              await _capture(tester, boundary,
                  '${entry.key}-${width.toInt()}-${brightness.name}');
            }
            if (find.byType(ListView).evaluate().isNotEmpty) {
              await tester.drag(
                  find.byType(ListView).first, const Offset(0, -450));
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
            }
            await tester.pumpWidget(const SizedBox());
          }
        }
      }
    });
  }

  testWidgets('hub error states provide functional retry', (tester) async {
    var attempts = 0;
    await tester.pumpWidget(MaterialApp(
        theme: buildMemberTheme(buildWpccTheme()),
        home: DepartmentsPage(loadDepartments: () async {
          if (attempts++ == 0) throw StateError('offline');
          return [department];
        })));
    await tester.pumpAndSettle();
    expect(find.text('Unable to load departments'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Awaiting approval'), findsOneWidget);
    expect(attempts, 2);
  });

  testWidgets('souls retry settles when the connection stays unavailable',
      (tester) async {
    var attempts = 0;
    await tester.pumpWidget(MaterialApp(
        theme: buildMemberTheme(buildWpccTheme()),
        home: SoulsPage(loadSouls: () async {
          attempts++;
          throw StateError('offline');
        })));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Unable to load your souls'), findsOneWidget);
    expect(attempts, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('message provider action scrolls clear of the floating dock',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final width in [320.0, 393.0]) {
      for (final scale in [1.0, 2.0]) {
        tester.view.physicalSize = Size(width, 700);
        final router = GoRouter(initialLocation: '/media/message', routes: [
          GoRoute(
              path: '/media/message',
              builder: (_, __) => const MemberTheme(
                      child: AppShell(
                          child: MediaEpisodeDetailPage(
                              episodeId: 'message',
                              seed: {
                        'id': 'message',
                        'title': 'A message for our community',
                        'description':
                            'A thoughtful teaching for the week. A thoughtful teaching for the week. '
                                'A thoughtful teaching for the week. A thoughtful teaching for the week.',
                        'provider_url':
                            'https://open.spotify.com/episode/fixture',
                      })))),
        ]);
        await tester.pumpWidget(MaterialApp.router(
            routerConfig: router,
            theme: buildWpccTheme(),
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(scale),
                    padding: const EdgeInsets.only(bottom: 34),
                    disableAnimations: true),
                child: child!)));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
            find.widgetWithText(MediaProviderLink, 'Open in Spotify'), 100);
        await tester.pumpAndSettle();
        final actionBottom = tester
            .getBottomLeft(
                find.widgetWithText(MediaProviderLink, 'Open in Spotify'))
            .dy;
        final dockTop = tester.getTopLeft(find.byTooltip('Home')).dy;
        expect(actionBottom, lessThan(dockTop - 4),
            reason: '$width scale $scale');
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        router.dispose();
      }
    }
  });

  testWidgets('department pending cards cannot navigate', (tester) async {
    await tester.pumpWidget(MaterialApp(
        theme: buildMemberTheme(buildWpccTheme()),
        home: DepartmentsPage(loadDepartments: () async => [department])));
    await tester.pumpAndSettle();
    final cardInk = find.ancestor(
        of: find.text(department['name'] as String),
        matching: find.byType(InkWell));
    expect(tester.widget<InkWell>(cardInk.first).onTap, isNull);
  });

  testWidgets('search filters change real results and clearing resets them',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        theme: buildMemberTheme(buildWpccTheme()), home: pages['search']!()));
    await tester.enterText(find.byType(TextField), 'church');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('Worship team'), findsOneWidget);
    await tester.tap(find.widgetWithText(MemberFilterChip, 'Events'));
    await tester.pumpAndSettle();
    expect(find.text('Sunday celebration'), findsOneWidget);
    expect(find.text('Worship team'), findsNothing);
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('Sunday celebration'), findsNothing);
  });

  testWidgets(
      'devotional metadata is not fabricated and pagination is preserved',
      (tester) async {
    final offsets = <int>[];
    await tester.pumpWidget(MaterialApp(
        theme: buildMemberTheme(buildWpccTheme()),
        home:
            DevotionalPage(loadPosts: ({int offset = 0, int limit = 20}) async {
          offsets.add(offset);
          return offset == 0
              ? List.generate(20, (i) => {...post, 'id': '$i'})
              : [];
        })));
    await tester.pumpAndSettle();
    expect(find.textContaining('3 min read'), findsNothing);
    expect(find.text('Today'), findsNothing);
    await tester.scrollUntilVisible(find.text('Load more'), 700,
        maxScrolls: 30);
    await tester.tap(find.text('Load more'));
    await tester.pumpAndSettle();
    expect(offsets, [0, 20]);
  });

  testWidgets('nested routes retain accessible top player actions',
      (tester) async {
    final handle = tester.ensureSemantics();
    try {
      final player = MediaPlayerController.instance;
      addTearDown(() => player.value = const MediaPlayerState());
      final router = GoRouter(initialLocation: '/home', routes: [
        ShellRoute(
          builder: (_, __, child) => MemberTheme(child: AppShell(child: child)),
          routes: [
            GoRoute(
                path: '/home',
                builder: (context, __) => Center(
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                      Semantics(
                          container: true, child: const Text('Nested route')),
                      TextButton(
                          onPressed: () => showModalBottomSheet<void>(
                              context: context,
                              builder: (sheetContext) => SizedBox(
                                  height: 240,
                                  child: Align(
                                      alignment: Alignment.topCenter,
                                      child: TextButton(
                                          onPressed: () =>
                                              Navigator.pop(sheetContext),
                                          child: const Text('Close sheet'))))),
                          child: const Text('Open sheet')),
                      TextButton(
                          onPressed: () => showDialog<void>(
                              context: context,
                              builder: (dialogContext) => AlertDialog(actions: [
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.pop(dialogContext),
                                        child: const Text('Close dialog')),
                                  ])),
                          child: const Text('Open dialog')),
                    ]))),
          ],
        ),
      ]);
      addTearDown(router.dispose);
      for (final reduced in [false, true]) {
        player.value = const MediaPlayerState(
            episode: MediaPlayerEpisode(
                id: 'fixture',
                externalId: '',
                title: 'A real message',
                artworkUrl: '',
                providerUrl: '',
                embedUrl: '',
                durationMs: 900000,
                description: '',
                publishedAt: ''),
            durationMs: 900000);
        await tester.pumpWidget(MaterialApp.router(
            routerConfig: router,
            theme: buildWpccTheme(),
            builder: (context, child) => MediaQuery(
                data:
                    MediaQuery.of(context).copyWith(disableAnimations: reduced),
                child: child!)));
        await tester.pumpAndSettle();
        expect(
            _semanticsNodes(tester)
                .where((node) => node.getSemanticsData().tooltip == 'Play'),
            hasLength(1));
        expect(
            _semanticsNodes(tester).where(
                (node) => node.getSemanticsData().label == 'Playback progress'),
            hasLength(1));
        await tester.tap(find.text('Open sheet'));
        await tester.pumpAndSettle();
        expect(
            _semanticsNodes(tester).where(
                (node) => node.getSemanticsData().label == 'Nested route'),
            isEmpty);
        expect(
            _semanticsNodes(tester).where(
                (node) => node.getSemanticsData().label == 'Close sheet'),
            hasLength(1));
        expect(
            _semanticsNodes(tester).where(
                (node) => node.getSemanticsData().tooltip == 'Close player'),
            hasLength(1));
        await tester.tap(find.text('Close sheet'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Open dialog'));
        await tester.pumpAndSettle();
        expect(
            _semanticsNodes(tester).where(
                (node) => node.getSemanticsData().tooltip == 'Close player'),
            isEmpty);
        expect(
            _semanticsNodes(tester)
                .where((node) => node.getSemanticsData().label == 'Home'),
            isEmpty);
        expect(
            _semanticsNodes(tester).where(
                (node) => node.getSemanticsData().label == 'Close dialog'),
            hasLength(1));
        await tester.tap(find.text('Close dialog'));
        await tester.pumpAndSettle();
        final close = _semanticsNodes(tester).singleWhere(
            (node) => node.getSemanticsData().tooltip == 'Close player');
        expect(
            close.getSemanticsData().hasAction(ui.SemanticsAction.tap), isTrue);
        tester.binding.rootPipelineOwner.visitChildren((owner) {
          owner.semanticsOwner?.performAction(close.id, ui.SemanticsAction.tap);
        });
        await tester.pumpAndSettle();
        expect(player.value.episode, isNull);
        expect(tester.takeException(), isNull);
      }
    } finally {
      handle.dispose();
    }
  });

  testWidgets('shell preserves reference dock and top artwork geometry',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final router = GoRouter(initialLocation: '/home', routes: [
      ShellRoute(
        builder: (_, __, child) => MemberTheme(child: AppShell(child: child)),
        routes: [GoRoute(path: '/home', builder: (_, __) => const SizedBox())],
      ),
    ]);
    addTearDown(router.dispose);
    final player = MediaPlayerController.instance;
    addTearDown(() => player.value = const MediaPlayerState());
    player.value = MediaPlayerState(
        episode: MediaPlayerEpisode.fromRow(const {
          'id': 'fixture',
          'title': 'Actual message',
          'duration_ms': 900000,
        }),
        durationMs: 900000);
    for (final brightness in Brightness.values) {
      for (final size in [const Size(390, 844), const Size(834, 1194)]) {
        tester.view.physicalSize = size;
        final key = GlobalKey();
        await tester.pumpWidget(MaterialApp.router(
          routerConfig: router,
          theme: buildWpccTheme(brightness: brightness),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(padding: EdgeInsets.zero),
            child: RepaintBoundary(key: key, child: child!),
          ),
        ));
        await tester.pumpAndSettle();
        final home = find.byTooltip('Home');
        final dockBounds =
            tester.getRect(find.byKey(const ValueKey('floating-navigation')));
        final playerBounds =
            tester.getRect(find.byKey(const ValueKey('floating-player')));
        expect(playerBounds.width, dockBounds.width);
        expect(dockBounds.top - playerBounds.bottom, closeTo(4, .01));
        expect(tester.getSize(home), const Size(50, 50));
        expect(tester.getTopLeft(home).dx, (size.width - 292) / 2 + 5);
        final bottom = size.width < 600 ? 22 : 24;
        expect(tester.getTopLeft(home).dy, size.height - bottom - 60 + 5);
        final artwork = find.byType(MemberArtwork);
        expect(tester.getSize(artwork), const Size(34, 34));
        expect(tester.widget<MemberArtwork>(artwork).radius, 8);
        expect(tester.getTopLeft(artwork).dx,
            closeTo((size.width - 292) / 2 + 14, 1));
        expect(tester.getBottomLeft(artwork).dy,
            lessThan(tester.getTopLeft(home).dy));
        expect(tester.getSize(find.byType(LinearProgressIndicator)).width,
            lessThanOrEqualTo(292));
        expect(find.byTooltip('Play'), findsOneWidget);
        expect(find.byTooltip('Close player'), findsOneWidget);
        expect(tester.takeException(), isNull);
        if (Platform.environment['CAPTURE_MEMBER_UI'] == 'true') {
          await _capture(
              tester, key, 'shell-${size.width.toInt()}-${brightness.name}');
        }
      }
    }
  });

  testWidgets('shell keeps top player and five accessible tabs with large text',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final router = GoRouter(initialLocation: '/home', routes: [
      for (final path in ['/home', '/media', '/events', '/give', '/profile'])
        GoRoute(
            path: path,
            builder: (_, __) => MemberTheme(
                child: AppShell(child: Center(child: Text('Screen $path'))))),
    ]);
    addTearDown(router.dispose);
    final player = MediaPlayerController.instance;
    player.value = const MediaPlayerState(
        episode: MediaPlayerEpisode(
            id: 'fixture',
            externalId: '',
            title: 'A real message with a long title',
            artworkUrl: '',
            providerUrl: '',
            embedUrl: '',
            durationMs: 900000,
            description: '',
            publishedAt: ''),
        durationMs: 900000);
    addTearDown(() => player.value = const MediaPlayerState());
    for (final brightness in Brightness.values) {
      for (final width in widths) {
        for (final scale in scales) {
          tester.view.physicalSize = Size(width, 900);
          await tester.pumpWidget(MaterialApp.router(
            routerConfig: router,
            theme: buildWpccTheme(brightness: brightness),
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(scale),
                    padding: const EdgeInsets.only(bottom: 34),
                    disableAnimations: true,
                    highContrast: true),
                child: child!),
          ));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.byTooltip('Close player'), findsOneWidget);
          expect(
              tester
                  .getTopLeft(find.text('A real message with a long title'))
                  .dy,
              lessThan(tester.getTopLeft(find.byTooltip('Home')).dy));
        }
      }
    }
    for (final label in ['Home', 'Media', 'Events', 'Give', 'Profile']) {
      await tester.tap(find.byTooltip(label));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}

List<SemanticsNode> _semanticsNodes(WidgetTester tester) {
  final nodes = <SemanticsNode>[];
  void collect(SemanticsNode node) {
    nodes.add(node);
    node.visitChildren((child) {
      collect(child);
      return true;
    });
  }

  tester.binding.rootPipelineOwner.visitChildren((owner) {
    final root = owner.semanticsOwner?.rootSemanticsNode;
    if (root != null) collect(root);
  });
  return nodes;
}

double _contrast(Color a, Color b) {
  final first = a.computeLuminance(), second = b.computeLuminance();
  return first > second
      ? (first + .05) / (second + .05)
      : (second + .05) / (first + .05);
}

Future<void> _capture(WidgetTester tester, GlobalKey key, String name) async {
  final render =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await render.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await File('${Directory.systemTemp.path}/wpcc-member-$name.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}
