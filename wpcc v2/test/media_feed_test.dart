import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:wpcc_community/core/theme/app_theme.dart';
import 'package:wpcc_community/core/theme/member_theme.dart';
import 'package:wpcc_community/core/widgets/member_components.dart';
import 'package:wpcc_community/features/media/gallery_viewer_page.dart';
import 'package:wpcc_community/features/media/media_feed.dart';
import 'package:wpcc_community/features/media/media_gallery_tab.dart';
import 'package:wpcc_community/features/media/media_page.dart';
import 'package:wpcc_community/features/media/media_shelves.dart';
import 'package:wpcc_community/features/media/media_shorts_page.dart';
import 'package:wpcc_community/features/media/media_video_page.dart';

Map<String, dynamic> audio(String id, String date) => {
      'id': id,
      'provider': 'spotify',
      'title': 'Message $id',
      'duration_ms': 1800000,
      'source_published_at': date,
      'provider_url': 'https://open.spotify.com/episode/$id',
    };

Map<String, dynamic> video(String id, String published,
        {String provider = 'youtube',
        String kind = 'video',
        String format = 'standard',
        bool liveNow = false}) =>
    {
      'format': format,
      'live_now': liveNow ? 1 : 0,
      'id': id,
      'provider': provider,
      'external_id': 'ext-$id',
      'title': 'Video $id',
      'kind': kind,
      'published_at': published,
      'duration_seconds': 754,
      'permalink_url': provider == 'youtube'
          ? 'https://www.youtube.com/watch?v=ext-$id'
          : 'https://www.facebook.com/wpcc/videos/$id',
      'thumbnail_url': '',
    };

Map<String, dynamic> photo(int n, {double ratio = 1}) => {
      'id': 'photo-$n',
      'caption': n.isEven ? 'Photo caption $n' : '',
      'permalink': 'https://www.facebook.com/photo/$n',
      'published_at':
          DateTime.utc(2026, 9, 1).subtract(Duration(hours: n)).toIso8601String(),
      'width': 1200,
      'height': (1200 / ratio).round(),
      'r2_key': 'fb/photo-$n',
    };

Widget host(Widget child,
        {Brightness brightness = Brightness.light, double scale = 1}) =>
    MaterialApp(
      theme: buildMemberTheme(buildWpccTheme(brightness: brightness)),
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: MemberBackdrop(media: true, child: child!)),
      home: child,
    );

MediaPage page({
  EpisodeLoader? episodes,
  EpisodeLoader? videos,
  GalleryLoader? photos,
  int seed = 1,
}) =>
    MediaPage(
        key: UniqueKey(),
        shelfSeed: seed,
        loadEpisodes: episodes ?? () async => [audio('a1', '2026-09-07')],
        loadAlbums: () async => [],
        loadVideos: videos ?? () async => [],
        loadGalleryPhotos: photos ?? ({after}) async => []);

void main() {
  group('feed helpers', () {
    test('merges audio and video newest first, undated items last', () {
      final items = mergeMediaFeed([
        audio('old', '2026-08-01'),
        {'id': 'undated', 'title': 'No date'},
        audio('new', '2026-09-20'),
      ], [
        video('mid', '2026-09-10T08:00:00Z'),
        video('live', '2026-09-20T18:00:00Z', kind: 'live'),
      ]);
      expect(items.map((item) => item.id), ['live', 'new', 'mid', 'old', 'undated']);
      expect(items.first.type, MediaType.livestream);
      expect(items[1].type, MediaType.audio);
      expect(items[2].type, MediaType.video);
    });

    test('equal dates keep delivery order', () {
      final items = mergeMediaFeed(
          [audio('b', '2026-09-07'), audio('a', '2026-09-07')], []);
      expect(items.map((item) => item.id), ['b', 'a']);
    });

    test('builds embeds only from safe provider data', () {
      expect(videoEmbedUrl(video('1', '2026-09-01T00:00:00Z')),
          'https://www.youtube-nocookie.com/embed/ext-1?rel=0&playsinline=1&autoplay=1&enablejsapi=1');
      expect(
          videoEmbedUrl(video('1', '2026-09-01T00:00:00Z'), bare: true),
          allOf(contains('controls=0'), contains('loop=1'), contains('playlist=ext-1')));
      final facebook = videoEmbedUrl(
          video('2', '2026-09-01T00:00:00Z', provider: 'facebook'));
      expect(facebook, startsWith('https://www.facebook.com/plugins/video.php?href='));
      expect(facebook, contains(Uri.encodeComponent('https://www.facebook.com/wpcc/videos/2')));
      expect(
          videoEmbedUrl({
            'provider': 'facebook',
            'permalink_url': 'http://insecure.example/video'
          }),
          '');
      expect(videoEmbedUrl({'provider': 'vimeo', 'external_id': '9'}), '');
    });

    test('formats durations', () {
      expect(formatVideoDuration(754), '12:34');
      expect(formatVideoDuration(3909), '1:05:09');
      expect(formatVideoDuration(0), '');
      expect(formatVideoDuration(null), '');
    });

    test('prefers the mirrored copy and never hotlinks Facebook thumbnails', () {
      expect(videoThumbnailUrl({'provider': 'facebook', 'r2_key': 'fb/x'}, width: 320),
          'https://storage.wisdompowercc.org/fb/x/w480.webp');
      expect(
          videoThumbnailUrl(
              {'provider': 'youtube', 'thumbnail_url': 'https://i.ytimg.com/a.jpg'}),
          'https://i.ytimg.com/a.jpg');
      expect(
          videoThumbnailUrl({
            'provider': 'facebook',
            'thumbnail_url': 'https://scontent.fbcdn.net/expiring.jpg'
          }),
          '');
    });

    test('gallery column counts follow width', () {
      expect(galleryColumns(390), 2);
      expect(galleryColumns(600), 3);
      expect(galleryColumns(899), 3);
      expect(galleryColumns(900), 4);
    });
  });

  group('shelves', () {
    List<MediaFeedItem> feed() => mergeMediaFeed([
          for (var i = 0; i < 12; i++) audio('a$i', '2026-08-${10 + i}'),
        ], [
          for (var i = 0; i < 12; i++)
            video('v$i', '2026-09-${10 + i}T10:00:00Z'),
          for (var i = 0; i < 9; i++)
            video('s$i', '2026-09-${10 + i}T12:00:00Z', format: 'short'),
          video('live', '2026-09-25T10:00:00Z',
              kind: 'live', liveNow: true, format: 'short'),
        ]);

    test('every item appears once, shorts only in the shorts shelf', () {
      final items = feed();
      for (var seed = 0; seed < 20; seed++) {
        final shelves = buildMediaShelves(items, random: Random(seed));
        final seen = [
          for (final shelf in shelves) ...shelf.items.map((i) => i.id)
        ];
        expect(seen.toSet().length, seen.length, reason: 'seed $seed');
        // The on-air livestream has its own place at the top of the page.
        expect(seen, isNot(contains('live')));
        expect(seen.length, items.length - 1);
        for (final shelf in shelves) {
          expect(shelf.items.length, lessThanOrEqualTo(shelf.kind.size));
          if (shelf.kind == MediaShelfKind.shorts) {
            expect(shelf.items.every((i) => i.isVertical), isTrue);
          } else {
            expect(shelf.items.any((i) => i.isVertical), isFalse);
          }
          if (shelf.kind == MediaShelfKind.wide) {
            expect(shelf.items.single.isAudio, isFalse);
          }
        }
      }
    });

    test('the page does not always open the same way', () {
      final items = feed();
      final firsts = {
        for (var seed = 0; seed < 30; seed++)
          buildMediaShelves(items, random: Random(seed)).first.kind
      };
      expect(firsts.length, greaterThan(1));
      final tops = {
        for (var seed = 0; seed < 30; seed++)
          buildMediaShelves(items, random: Random(seed))
              .first
              .items
              .first
              .isAudio
      };
      expect(tops, {true, false});
    });

    test('each kind of shelf has the size the design asks for', () {
      expect(MediaShelfKind.shorts.size, 4);
      expect(MediaShelfKind.wide.size, 1);
      expect(MediaShelfKind.grid.size, 6);
      expect(MediaShelfKind.list.size, lessThanOrEqualTo(4));
    });

    test('works with only audio, only shorts, or nothing', () {
      expect(buildMediaShelves([], random: Random(1)), isEmpty);
      final audioOnly = mergeMediaFeed([audio('a', '2026-09-01')], []);
      expect(
          buildMediaShelves(audioOnly, random: Random(1)).single.items.single.id,
          'a');
      final shortsOnly = mergeMediaFeed(
          [], [video('s', '2026-09-01T00:00:00Z', format: 'short')]);
      expect(buildMediaShelves(shortsOnly, random: Random(1)).single.kind,
          MediaShelfKind.shorts);
    });

    test('vertical means short or portrait video, never a livestream or audio',
        () {
      MediaFeedItem make(String id, {String format = 'standard', String kind = 'video'}) =>
          MediaFeedItem.video(
              video(id, '2026-09-01T00:00:00Z', format: format, kind: kind));
      expect(make('a', format: 'short').isVertical, isTrue);
      expect(make('b', format: 'portrait').isVertical, isTrue);
      expect(make('c').isVertical, isFalse);
      expect(make('d', format: 'short', kind: 'live').isVertical, isFalse);
      expect(MediaFeedItem.audio(audio('e', '2026-09-01')).isVertical, isFalse);
      // Rows from before the format column existed count as ordinary videos.
      final old = video('f', '2026-09-01T00:00:00Z')..remove('format');
      expect(MediaFeedItem.video(old).isVertical, isFalse);
    });

    test('finds the live stream, or the latest one that ended', () {
      final onAir = mergeMediaFeed([], [
        video('old', '2026-09-01T00:00:00Z', kind: 'live'),
        video('now', '2026-09-20T00:00:00Z', kind: 'live', liveNow: true),
      ]);
      expect(liveNowItem(onAir)?.id, 'now');
      expect(latestLivestreamItem(onAir)?.id, 'old');
      final ended = mergeMediaFeed([], [
        video('old', '2026-09-01T00:00:00Z', kind: 'live'),
        video('new', '2026-09-10T00:00:00Z', kind: 'live'),
        video('plain', '2026-09-20T00:00:00Z'),
      ]);
      expect(liveNowItem(ended), isNull);
      expect(latestLivestreamItem(ended)?.id, 'new');
    });
  });

  group('Media tab', () {
    List<Map<String, dynamic>> sample() => [
          video('v1', '2026-09-20T10:00:00Z'),
          video('v2', '2026-09-18T10:00:00Z', provider: 'facebook'),
          video('live1', '2026-09-03T10:00:00Z',
              provider: 'facebook', kind: 'live'),
          video('s1', '2026-09-19T10:00:00Z', format: 'short'),
          video('s2', '2026-09-17T10:00:00Z', format: 'short'),
        ];

    void tall(WidgetTester tester, [Size size = const Size(390, 4000)]) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
    }

    Finder chip(String label) => find.descendant(
        of: find.byType(MediaFilterChips), matching: find.text(label));

    testWidgets('lays the feed out in shelves under a Videos heading',
        (tester) async {
      tall(tester);
      await tester.pumpWidget(host(page(videos: () async => sample())));
      await tester.pumpAndSettle();
      expect(find.text('Videos'), findsOneWidget);
      expect(find.text('All media'), findsNothing);
      expect(find.text('Latest'), findsNothing);
      expect(find.text('Shorts'), findsOneWidget);
      expect(find.text('Video s1'), findsOneWidget);
      expect(find.text('Video s2'), findsOneWidget);
      expect(find.byType(MediaShelfView), findsWidgets);
      for (final title in ['Video v1', 'Video v2', 'Message a1']) {
        expect(find.text(title), findsOneWidget, reason: title);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('the shelf order depends on the seed, the content does not',
        (tester) async {
      tall(tester);
      final orders = <String>{};
      for (final seed in [1, 2, 3, 4, 5, 6]) {
        await tester
            .pumpWidget(host(page(seed: seed, videos: () async => sample())));
        await tester.pumpAndSettle();
        orders.add([
          for (final view
              in tester.widgetList<MediaShelfView>(find.byType(MediaShelfView)))
            view.shelf.kind.name
        ].join(','));
      }
      expect(orders.length, greaterThan(1));
    });

    testWidgets('a livestream on air gets a LIVE circle and no latest circle',
        (tester) async {
      tall(tester);
      await tester.pumpWidget(host(page(
          videos: () async => [
                video('past', '2026-09-03T10:00:00Z', kind: 'live'),
                video('now', '2026-09-20T10:00:00Z',
                    kind: 'live', liveNow: true),
                video('v1', '2026-09-19T10:00:00Z'),
              ])));
      await tester.pumpAndSettle();
      expect(find.text('Live now'), findsOneWidget);
      expect(find.text('LIVE'), findsOneWidget);
      expect(find.text('Latest livestream'), findsNothing);
      // It is in the circles, not repeated in the feed.
      expect(find.text('Video now'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('with nothing on air the latest livestream gets a circle',
        (tester) async {
      tall(tester);
      await tester.pumpWidget(host(page(videos: () async => sample())));
      await tester.pumpAndSettle();
      expect(find.text('Latest livestream'), findsOneWidget);
      expect(find.text('Live now'), findsNothing);
      expect(find.text('LIVE'), findsNothing);
    });

    testWidgets('albums become circles with their title underneath',
        (tester) async {
      await tester.pumpWidget(host(MediaPage(
          key: UniqueKey(),
          shelfSeed: 1,
          loadEpisodes: () async => [audio('a1', '2026-09-07')],
          loadVideos: () async => [],
          loadAlbums: () async => [
                {'id': 'one', 'title': 'Faith and growth'},
                {'id': 'two', 'title': 'Power touch'},
              ],
          loadGalleryPhotos: ({after}) async => [])));
      await tester.pumpAndSettle();
      expect(find.text('Faith and growth'), findsOneWidget);
      expect(find.text('Power touch'), findsOneWidget);
      expect(find.byType(MediaStoryRail), findsOneWidget);
    });

    testWidgets('the Audio filter shows only audio and All brings the rest back',
        (tester) async {
      tall(tester);
      await tester.pumpWidget(host(page(videos: () async => sample())));
      await tester.pumpAndSettle();
      await tester.tap(chip('Audio'));
      await tester.pumpAndSettle();
      expect(find.text('Message a1'), findsOneWidget);
      expect(find.text('Video v1'), findsNothing);
      expect(find.text('Shorts'), findsNothing);
      await tester.tap(chip('All'));
      await tester.pumpAndSettle();
      expect(find.text('Video v1'), findsOneWidget);
      expect(find.text('Shorts'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a video opens on its own page', (tester) async {
      tall(tester);
      final router = GoRouter(initialLocation: '/media', routes: [
        GoRoute(
            path: '/media',
            builder: (_, __) => page(videos: () async => sample()),
            routes: [
              GoRoute(
                  path: 'video/:id',
                  builder: (_, state) => MediaVideoPage(
                      videoId: state.pathParameters['id']!,
                      seed: state.extra as Map<String, dynamic>?)),
            ]),
      ]);
      addTearDown(router.dispose);
      await tester.pumpWidget(MaterialApp.router(
          theme: buildMemberTheme(buildWpccTheme()), routerConfig: router));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Video v1'));
      await tester.pumpAndSettle();
      expect(find.byType(MediaVideoPage), findsOneWidget);
      expect(find.text('Open in YouTube'), findsOneWidget);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.byType(MediaVideoPage), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a short opens the vertical viewer and can move between shorts',
        (tester) async {
      tall(tester);
      await tester.pumpWidget(host(page(videos: () async => sample())));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Video s1'));
      await tester.pumpAndSettle();
      expect(find.byType(MediaShortsPage), findsOneWidget);
      expect(find.text('Open in YouTube'), findsOneWidget);
      await tester.tap(find.byTooltip('Next short'));
      await tester.pumpAndSettle();
      expect(find.text('Open in YouTube'), findsOneWidget);
      await tester.tap(find.byTooltip('Previous short'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Close shorts'));
      await tester.pumpAndSettle();
      expect(find.byType(MediaShortsPage), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('sources fail independently', (tester) async {
      tall(tester);
      await tester.pumpWidget(
          host(page(videos: () async => throw Exception('videos down'))));
      await tester.pumpAndSettle();
      expect(find.text('Message a1'), findsOneWidget);
      expect(find.text('Videos are unavailable'), findsOneWidget);

      await tester.pumpWidget(host(page(
          episodes: () async => throw Exception('spotify down'),
          videos: () async => [video('v1', '2026-09-20T10:00:00Z')])));
      await tester.pumpAndSettle();
      expect(find.text('Video v1'), findsOneWidget);
      expect(find.text('Spotify messages are unavailable'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('empty and fully failed states are explicit', (tester) async {
      await tester.pumpWidget(host(page(episodes: () async => [])));
      await tester.pumpAndSettle();
      expect(find.text('No media yet'), findsOneWidget);

      await tester.pumpWidget(host(page(
          episodes: () async => throw Exception('a'),
          videos: () async => throw Exception('b'))));
      await tester.pumpAndSettle();
      expect(find.text('Unable to load media'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });

  group('video page', () {
    testWidgets('autoplays and eases the open button in', (tester) async {
      await tester.pumpWidget(host(MediaVideoPage(
          videoId: 'v1', seed: video('v1', '2026-09-20T10:00:00Z'))));
      await tester.pump();
      double opacity() => tester
          .widget<Opacity>(find
              .ancestor(
                  of: find.text('Open in YouTube'),
                  matching: find.byType(Opacity))
              .first)
          .opacity;
      expect(opacity(), 0);
      await tester.pump(const Duration(milliseconds: 200));
      expect(opacity(), lessThan(1));
      await tester.pump(const Duration(milliseconds: 600));
      expect(opacity(), 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('looks the video up when opened without it', (tester) async {
      await tester.pumpWidget(host(MediaVideoPage(
          videoId: 'v2',
          loadVideos: () async => [
                video('v1', '2026-09-20T10:00:00Z'),
                video('v2', '2026-09-19T10:00:00Z', provider: 'facebook')
              ])));
      await tester.pumpAndSettle();
      expect(find.text('Video v2'), findsOneWidget);
      expect(find.text('Open in Facebook'), findsOneWidget);
    });

    testWidgets('says so when the video is gone', (tester) async {
      await tester.pumpWidget(host(
          MediaVideoPage(videoId: 'missing', loadVideos: () async => [])));
      await tester.pumpAndSettle();
      expect(find.text('This video is no longer available'), findsOneWidget);
    });
  });

  group('Gallery tab', () {
    Future<void> openGallery(WidgetTester tester) async {
      await tester.tap(find.text('Gallery'));
      await tester.pumpAndSettle();
    }

    testWidgets('lays photos out in 2, 3 and 4 masonry columns', (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      const ratios = [1.0, 0.75, 1.5, 0.8, 1.2, 1.0, 0.9, 1.3];
      for (final entry in {390.0: 2, 834.0: 3, 1024.0: 4}.entries) {
        tester.view.physicalSize = Size(entry.key, 1400);
        await tester.pumpWidget(host(page(
            photos: ({after}) async =>
                [for (var i = 0; i < 12; i++) photo(i, ratio: ratios[i % 8])])));
        await tester.pumpAndSettle();
        await openGallery(tester);
        final lefts = tester
            .widgetList<GalleryTile>(find.byType(GalleryTile))
            .map((tile) => tester.getTopLeft(find.byWidget(tile)).dx.round())
            .toSet();
        expect(lefts.length, entry.value, reason: 'width ${entry.key}');
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('empty, error and retry states', (tester) async {
      await tester.pumpWidget(host(page(photos: ({after}) async => [])));
      await tester.pumpAndSettle();
      await openGallery(tester);
      expect(find.text('No photos yet'), findsOneWidget);

      var calls = 0;
      await tester.pumpWidget(host(page(photos: ({after}) async {
        if (calls++ == 0) throw Exception('offline');
        return [photo(1), photo(2)];
      })));
      await tester.pumpAndSettle();
      await openGallery(tester);
      expect(find.text('Photos are unavailable'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.byType(GalleryTile), findsNWidgets(2));
    });

    testWidgets('loads the next page near the end of the list', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final requested = <String?>[];
      await tester.pumpWidget(host(page(photos: ({after}) async {
        requested.add(after?['id']?.toString());
        return after == null
            ? [for (var i = 0; i < 40; i++) photo(i)]
            : [photo(100), photo(101)];
      })));
      await tester.pumpAndSettle();
      await openGallery(tester);
      expect(requested, [null]);
      for (var i = 0; i < 6; i++) {
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -1500));
        await tester.pumpAndSettle();
      }
      expect(requested, [null, 'photo-39']);
      expect(tester.takeException(), isNull);
    });

    testWidgets('opens the viewer with a Facebook link and closes it',
        (tester) async {
      await tester.pumpWidget(host(page(
          photos: ({after}) async => [photo(2), photo(3)])));
      await tester.pumpAndSettle();
      await openGallery(tester);
      await tester.tap(find.byType(GalleryTile).first);
      await tester.pumpAndSettle();
      expect(find.byType(GalleryViewerPage), findsOneWidget);
      expect(find.text('View on Facebook'), findsOneWidget);
      expect(find.text('Photo caption 2'), findsWidgets);
      await tester.tap(find.byTooltip('Close photo'));
      await tester.pumpAndSettle();
      expect(find.byType(GalleryViewerPage), findsNothing);
    });

    testWidgets('switching tabs keeps the media feed available', (tester) async {
      await tester.pumpWidget(host(page(
          photos: ({after}) async => [photo(1)],
          videos: () async => [video('v1', '2026-09-20T10:00:00Z')])));
      await tester.pumpAndSettle();
      await openGallery(tester);
      expect(find.byType(GalleryTile), findsOneWidget);
      await tester.tap(find.descendant(
          of: find.byType(MemberFilterChip), matching: find.text('Media')));
      await tester.pumpAndSettle();
      expect(find.text('Video v1'), findsOneWidget);
    });
  });

  group('fit', () {
    testWidgets('both tabs fit phone and tablet in both themes at large text',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      for (final brightness in Brightness.values) {
        for (final size in [
          const Size(320, 700),
          const Size(390, 844),
          const Size(834, 1194)
        ]) {
          for (final scale in [1.0, 2.0]) {
            tester.view.physicalSize = size;
            await tester.pumpWidget(host(
                page(
                    videos: () async => [
                          video('v1', '2026-09-20T10:00:00Z'),
                          video('live1', '2026-09-03T10:00:00Z',
                              provider: 'facebook', kind: 'live'),
                          for (var i = 0; i < 6; i++)
                            video('s$i', '2026-09-1${i}T10:00:00Z',
                                format: 'short'),
                        ],
                    photos: ({after}) async =>
                        [for (var i = 0; i < 6; i++) photo(i, ratio: 0.8 + i / 5)]),
                brightness: brightness,
                scale: scale));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull,
                reason: 'media $brightness $size $scale');
            await tester.tap(find.text('Gallery'));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull,
                reason: 'gallery $brightness $size $scale');
          }
        }
      }
    });
  });
}
