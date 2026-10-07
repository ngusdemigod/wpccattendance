import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wpcc_community/core/theme/app_theme.dart';
import 'package:wpcc_community/core/theme/member_theme.dart';
import 'package:wpcc_community/core/widgets/member_components.dart';
import 'package:wpcc_community/core/widgets/member_skeleton.dart';
import 'package:wpcc_community/features/search/search_page.dart';
import 'package:wpcc_community/features/search/search_repository.dart';

final _videos = <Map<String, dynamic>>[
  {
    'id': 'youtube:abc',
    'provider': 'youtube',
    'external_id': 'abc',
    'title': 'Grace for the journey',
    'description': 'Sunday message',
    'kind': 'video',
    'format': 'landscape',
    'published_at': '2026-01-04T10:00:00Z',
    'duration_seconds': 1800,
    'thumbnail_url': 'https://img.example/abc.jpg',
  },
  {
    'id': 'facebook:live1',
    'provider': 'facebook',
    'external_id': 'live1',
    'title': 'Midweek service',
    'description': 'Join us for grace and prayer',
    'kind': 'live',
    'published_at': '2026-02-01T18:00:00Z',
  },
  {
    'id': 'youtube:other',
    'provider': 'youtube',
    'external_id': 'other',
    'title': 'Youth rally',
    'published_at': '2026-02-02T18:00:00Z',
  },
];
final _episodes = <Map<String, dynamic>>[
  {
    'id': 'ep-1',
    'title': 'Walking in grace',
    'description': 'Audio message',
    'duration_ms': 1500000,
    'source_published_at': '2026-01-10T09:00:00Z',
    'artwork_url': 'https://img.example/ep1.jpg',
  },
  {'id': 'ep-2', 'title': 'Faith', 'description': 'No match here'},
];

SearchRepository _repo({
  Future<List<Map<String, dynamic>>> Function(String)? core,
  Future<List<Map<String, dynamic>>> Function()? videos,
  Future<List<Map<String, dynamic>>> Function()? episodes,
  Future<List<Map<String, dynamic>>> Function(String)? devotional,
  Future<List<Map<String, dynamic>>> Function()? classes,
}) =>
    SearchRepository(
      loadCore: core ??
          (_) async => [
                {
                  'section': 'events',
                  'id': 'e1',
                  'title': 'Grace conference',
                },
              ],
      loadVideos: videos ?? () async => _videos,
      loadEpisodes: episodes ?? () async => _episodes,
      loadDevotional: devotional ??
          (q) async => SearchRepository.matchDevotional(q, [
                {
                  'id': 'd1',
                  'title': 'Daily grace',
                  'body': '<p>Grace is enough</p>',
                  'created_at': '2026-03-01T06:00:00Z',
                },
              ]),
      loadClasses: classes ?? () async => throw Exception('missing rpc'),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('SearchRepository', () {
    test('returns every section grouped in a stable order', () async {
      final rows = await _repo().search('grace');
      expect(rows.map((row) => row['section']).toList(), [
        'events',
        'media',
        'media',
        'audio',
        'devotional',
      ]);
      final media = rows.where((row) => row['section'] == 'media').toList();
      // A title match ranks above a description-only match.
      expect(media.first['id'], 'youtube:abc');
      expect(media.last['id'], 'facebook:live1');
      expect(media.last['result_type'], 'livestream');
      expect(media.first['row'], isA<Map<String, dynamic>>());
      final audio = rows.singleWhere((row) => row['section'] == 'audio');
      expect(audio['id'], 'ep-1');
      expect(audio['subtitle'], contains('Spotify'));
      final devotional =
          rows.singleWhere((row) => row['section'] == 'devotional');
      expect(devotional['title'], 'Daily grace');
      expect(devotional['subtitle'], isNot(contains('<p>')));
    });

    test('a failing section does not hide the others', () async {
      final rows = await _repo(
        core: (_) async => throw Exception('rpc down'),
        videos: () async => throw Exception('media api down'),
      ).search('grace');
      expect(
          rows.map((row) => row['section']).toSet(), {'audio', 'devotional'});
    });

    test('throws only when every section fails', () async {
      final repo = _repo(
        core: (_) async => throw Exception('a'),
        videos: () async => throw Exception('b'),
        episodes: () async => throw Exception('c'),
        devotional: (_) async => throw Exception('d'),
      );
      await expectLater(repo.search('grace'), throwsException);
    });

    test('classes match when available and are skipped when missing',
        () async {
      final withClasses = await _repo(classes: () async => [
            {
              'id': 'c1',
              'title': 'Foundations of grace',
              'progress_percent': 40
            },
          ]).search('grace');
      expect(withClasses.where((row) => row['section'] == 'classes'),
          hasLength(1));
      expect(await _repo(core: (_) async => []).search('zzz-nothing'), isEmpty);
    });

    test('blank queries return nothing and every word must match', () async {
      expect(await _repo().search('   '), isEmpty);
      final rows = await _repo().search('grace journey');
      expect(
          rows
              .where((row) => row['section'] == 'media')
              .map((row) => row['id']),
          ['youtube:abc']);
    });

    test('searchRank prefers exact and prefix title matches', () {
      expect(SearchRepository.searchRank('grace', 'Grace', ''), 0);
      expect(SearchRepository.searchRank('gra', 'Grace for all', ''), 1);
      expect(SearchRepository.searchRank('all', 'Grace for all', ''), 2);
      expect(SearchRepository.searchRank('ace', 'Grace for all', ''), 3);
      expect(
          SearchRepository.searchRank('mercy', 'Grace', 'full of mercy'), 4);
      expect(SearchRepository.searchRank('mercy', 'Grace', ''), isNull);
    });
  });

  group('SearchPage', () {
    Future<GoRouter> pump(WidgetTester tester, SearchRepository repo,
        {List<String>? pushed}) async {
      final router = GoRouter(initialLocation: '/search', routes: [
        GoRoute(
            path: '/search',
            builder: (_, __) => SearchPage(loadSearch: repo.search)),
        for (final path in [
          '/media/:id',
          '/media/video/:id',
          '/devotional/:id',
          '/events/:id'
        ])
          GoRoute(
              path: path,
              builder: (_, state) {
                pushed?.add(state.uri.toString());
                return Scaffold(body: Text('opened ${state.uri}'));
              }),
      ]);
      await tester.pumpWidget(MaterialApp.router(
          routerConfig: router, theme: buildMemberTheme(buildWpccTheme())));
      await tester.pumpAndSettle();
      return router;
    }

    Future<void> type(WidgetTester tester, String text) async {
      await tester.enterText(find.byType(TextField), text);
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
    }

    void phone(WidgetTester tester) {
      tester.view.physicalSize = const Size(390, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    testWidgets('shows grouped sections and section filter chips',
        (tester) async {
      phone(tester);
      await pump(tester, _repo());
      await type(tester, 'grace');
      expect(find.text('Walking in grace'), findsOneWidget);
      expect(find.text('Grace for the journey'), findsOneWidget);
      Future<void> chip(String label) async {
        final finder = find.widgetWithText(MemberFilterChip, label);
        await tester.scrollUntilVisible(finder, 120,
            scrollable: find.descendant(
                of: find.byWidgetPredicate((widget) =>
                    widget is ListView &&
                    widget.scrollDirection == Axis.horizontal),
                matching: find.byType(Scrollable)));
        await tester.ensureVisible(finder);
        await tester.pumpAndSettle();
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }

      await chip('Audio');
      expect(find.text('Walking in grace'), findsOneWidget);
      expect(find.text('Grace for the journey'), findsNothing);
      await chip('Classes');
      expect(find.text('No results in Classes'), findsOneWidget);
    });

    testWidgets('results open the right destination', (tester) async {
      phone(tester);
      final pushed = <String>[];
      final router = await pump(tester, _repo(), pushed: pushed);
      await type(tester, 'grace');
      await tester.tap(find.text('Walking in grace'));
      await tester.pumpAndSettle();
      expect(pushed.last, '/media/ep-1');
      router.pop();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Grace for the journey'));
      await tester.pumpAndSettle();
      expect(pushed.last, '/media/video/youtube%3Aabc');
      router.pop();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Daily grace'));
      await tester.pumpAndSettle();
      expect(pushed.last, '/devotional/d1');
    });

    testWidgets('shows a skeleton, then an error with retry', (tester) async {
      phone(tester);
      var calls = 0;
      final repo = _repo(
        core: (_) async => throw Exception('a'),
        videos: () async => throw Exception('b'),
        episodes: () async => throw Exception('c'),
        devotional: (_) async {
          calls++;
          if (calls == 1) throw Exception('d');
          return [
            {'section': 'devotional', 'id': 'd9', 'title': 'Recovered'}
          ];
        },
      );
      await pump(tester, repo);
      await tester.enterText(find.byType(TextField), 'grace');
      await tester.pump();
      expect(find.byType(MemberSkeleton), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(find.text('Unable to search right now.'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('Recovered'), findsOneWidget);
    });
  });
}
