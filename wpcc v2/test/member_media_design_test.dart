import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:wpcc_community/app/app_shell.dart';
import 'package:wpcc_community/core/theme/app_theme.dart';
import 'package:wpcc_community/core/theme/member_theme.dart';
import 'package:wpcc_community/features/media/media_episode_detail_page.dart';
import 'package:wpcc_community/features/media/media_page.dart';
import 'package:wpcc_community/features/media/media_album_detail_page.dart';
import 'package:wpcc_community/features/media/media_player_controller.dart';
import 'package:wpcc_community/features/media/media_shelves.dart';

const episode = <String, dynamic>{
  'id': 'message-1',
  'title': 'Sunday message for the church community',
  'description': 'A message for the church community.',
  'artwork_url': '',
  'duration_ms': 3600000,
  'source_published_at': '2026-09-07',
  'provider_url': 'https://open.spotify.com/episode/message-1',
};

final captureBoundary = GlobalKey();

Widget app(Widget child,
        {Brightness brightness = Brightness.light, double scale = 1}) =>
    MaterialApp(
      theme: buildMemberTheme(buildWpccTheme(brightness: brightness)),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: RepaintBoundary(
            key: captureBoundary,
            child: MemberBackdrop(media: true, child: child!)),
      ),
      home: child,
    );

void main() {
  testWidgets('album circles sit right under the tabs, then the filter chips',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final brightness in Brightness.values) {
      for (final size in [const Size(390, 844), const Size(834, 1194)]) {
        for (final scale in [1.0, 1.6, 2.0]) {
          tester.view.physicalSize = size;
          await tester.pumpWidget(app(
              MediaPage(
                  key: UniqueKey(),
                  shelfSeed: 1,
                  loadVideos: () async => [],
                  loadEpisodes: () async => [episode],
                  loadAlbums: () async => [
                        {'id': 'featured', 'title': 'Featured album'},
                        {
                          'id': 'faith',
                          'title': 'Faith, Growth & Spiritual Alignment',
                        },
                        {'id': 'power', 'title': 'Power Touch 2025'},
                      ]),
              brightness: brightness,
              scale: scale));
          await tester.pumpAndSettle();
          // The removed introduction line stays gone.
          expect(find.textContaining('The Word for everyday life'), findsNothing);
          final rail = find.byType(MediaStoryRail);
          final circles = find.descendant(
              of: rail, matching: find.byType(MediaThumb));
          expect(circles, findsNWidgets(3));
          expect(tester.getSize(circles.first), const Size(76, 76));
          final label = tester.widget<Text>(
              find.text('Faith, Growth & Spiritual Alignment'));
          expect(label.maxLines, 2);
          // Order down the page: tabs, circles, filters, then the feed.
          final tabs = tester.getTopLeft(find.text('Gallery')).dy;
          final circle = tester.getTopLeft(rail).dy;
          final chips = tester.getTopLeft(find.byType(MediaFilterChips)).dy;
          final feed = tester.getTopLeft(find.text('Videos')).dy;
          expect(tabs < circle && circle < chips && chips < feed, isTrue,
              reason: '$brightness/$size/$scale');
          expect(tester.getSize(find.byType(MediaFilterChips)).height, 48);
          expect(find.text('All'), findsOneWidget);
          expect(find.text('Audio'), findsWidgets);
          expect(tester.takeException(), isNull,
              reason: '$brightness/$size/$scale');
          await tester.pumpWidget(const SizedBox());
        }
      }
    }
  });

  testWidgets('album opens a full page with description, playback and details',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final size in [const Size(390, 844), const Size(834, 1194)]) {
      tester.view.physicalSize = size;
      final router = GoRouter(initialLocation: '/media', routes: [
        ShellRoute(
            builder: (_, __, child) =>
                MemberTheme(child: AppShell(child: child)),
            routes: [
              GoRoute(
                  path: '/media',
                  builder: (_, __) => MediaPage(loadVideos: () async => [], 
                      loadEpisodes: () async => [episode],
                      loadAlbums: () async => [
                            {
                              'id': 'actual',
                              'title': 'Actual collection',
                              'description': 'Actual collection description',
                              'media_album_tracks': [
                                {'count': 4}
                              ]
                            }
                          ])),
              GoRoute(
                  path: '/media/albums/:id',
                  builder: (_, state) => MediaAlbumDetailPage(
                      albumId: state.pathParameters['id']!,
                      seed: state.extra as Map<String, dynamic>?,
                      loadAlbumTracks: (_) async => [
                            for (var index = 1; index <= 4; index++)
                              {
                                'track_number': index,
                                'episode': {
                                  ...episode,
                                  'id': 'track-$index',
                                  'title': 'Album message $index'
                                }
                              }
                          ])),
              GoRoute(
                  path: '/media/:id',
                  builder: (_, __) =>
                      const Center(child: Text('Message detail destination'))),
            ]),
      ]);
      await tester.pumpWidget(
          MaterialApp.router(theme: buildWpccTheme(), routerConfig: router));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Actual collection'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Actual collection'));
      await tester.pumpAndSettle();
      expect(find.byType(MediaAlbumDetailPage), findsOneWidget);
      expect(
          GoRouterState.of(tester.element(find.byType(MediaAlbumDetailPage)))
              .uri
              .path,
          '/media/albums/actual');
      final artwork = find.descendant(
          of: find.byType(MediaAlbumDetailPage),
          matching: find.byType(ShaderMask));
      expect(tester.getSize(artwork),
          Size(size.width, size.width < 600 ? 300 : 380));
      expect(find.text('4 messages · WPCC'), findsOneWidget);
      expect(find.text('Actual collection description'), findsOneWidget);
      await tester.ensureVisible(find.text('Album message 4'));
      await tester.pumpAndSettle();
      final play = find
          .descendant(
              of: find.byType(MediaAlbumDetailPage),
              matching: find.byTooltip('Play message'))
          .last;
      await tester.tap(play);
      await tester.pumpAndSettle();
      expect(MediaPlayerController.instance.value.episode?.id, 'track-4');
      final message = find.descendant(
          of: find.byType(MediaAlbumDetailPage),
          matching: find.text('Album message 4'));
      await tester.ensureVisible(message);
      await tester.pumpAndSettle();
      await tester.tap(message);
      await tester.pumpAndSettle();
      expect(find.text('Message detail destination'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      expect(find.byType(MediaAlbumDetailPage), findsOneWidget);
      await tester.ensureVisible(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/media');
      MediaPlayerController.instance.close();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
    }
  });

  testWidgets('album direct links load real metadata and retry track failures',
      (tester) async {
    var calls = 0;
    final router = GoRouter(initialLocation: '/media/albums/actual', routes: [
      GoRoute(
          path: '/media',
          builder: (_, __) => const Scaffold(body: Text('Media destination'))),
      GoRoute(
          path: '/media/albums/:id',
          builder: (_, state) => MediaAlbumDetailPage(
                albumId: state.pathParameters['id']!,
                loadAlbums: () async => [
                  {
                    'id': 'actual',
                    'title': 'Actual album',
                    'description': 'The complete album description.'
                  }
                ],
                loadAlbumTracks: (id) async {
                  expect(id, 'actual');
                  if (calls++ == 0) throw StateError('Offline');
                  return [
                    {'track_number': 1, 'episode': episode}
                  ];
                },
              )),
    ]);
    await tester.pumpWidget(MaterialApp.router(
        theme: buildMemberTheme(buildWpccTheme()), routerConfig: router));
    await tester.pumpAndSettle();
    expect(find.text('Actual album'), findsOneWidget);
    expect(find.text('The complete album description.'), findsOneWidget);
    await tester.ensureVisible(find.text('Retry'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('1 message · WPCC'), findsOneWidget);
    expect(find.text(episode['title'] as String), findsOneWidget);
    await tester.ensureVisible(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Media destination'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
  });

  testWidgets('album page accommodates large text and both themes',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final brightness in Brightness.values) {
      for (final size in [const Size(390, 844), const Size(834, 1194)]) {
        for (final scale in [1.0, 2.0]) {
          tester.view.physicalSize = size;
          await tester.pumpWidget(app(
              MediaAlbumDetailPage(
                key: UniqueKey(),
                albumId: 'actual',
                seed: const {
                  'id': 'actual',
                  'title': 'Marriage, Family & Relationships',
                  'description':
                      'Teachings about building healthy relationships and a strong family.'
                },
                loadAlbumTracks: (_) async => [],
              ),
              brightness: brightness,
              scale: scale));
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text('No messages in this album'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull,
              reason: '$brightness/$size/$scale');
          await tester.pumpWidget(const SizedBox());
        }
      }
    }
  });

  testWidgets('long album descriptions expand without hiding the track list',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final description =
        List.filled(12, 'Teachings for everyday life.').join(' ');
    await tester.pumpWidget(app(MediaAlbumDetailPage(
      albumId: 'actual',
      seed: {'id': 'actual', 'title': 'Faith', 'description': description},
      loadAlbumTracks: (_) async => [],
    )));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.text(description)).maxLines, 3);
    await tester.ensureVisible(find.text('Read more'));
    await tester.tap(find.text('Read more'));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.text(description)).maxLines, isNull);
    await tester.ensureVisible(find.text('Show less'));
    await tester.tap(find.text('Show less'));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.text(description)).maxLines, 3);
    expect(find.text('Messages'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('collection rows keep the approved message-detail interaction',
      (tester) async {
    MediaPlayerController.instance.close();
    final router = GoRouter(initialLocation: '/media', routes: [
      GoRoute(
          path: '/media',
          builder: (_, __) => Scaffold(
                  body: Column(children: [
                MediaCollectionTracks(album: const {
                  'id': 'actual'
                }, tracks: const [
                  {'track_number': 1, 'episode': episode}
                ]),
              ]))),
      GoRoute(
          path: '/media/:id',
          builder: (_, state) {
            final selected = state.extra! as Map<String, dynamic>;
            expect(selected['_collection'], {'id': 'actual'});
            expect(selected['_collection_tracks'], hasLength(1));
            return const Scaffold(body: Text('Message detail destination'));
          }),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(
        theme: buildMemberTheme(buildWpccTheme()), routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.text(episode['title'] as String));
    await tester.pumpAndSettle();
    expect(find.text('Message detail destination'), findsOneWidget);
    expect(MediaPlayerController.instance.value.episode, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('message detail matches reference reading and artwork bounds',
      (tester) async {
    addTearDown(MediaPlayerController.instance.close);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final brightness in Brightness.values) {
      for (final width in [390.0, 600.0, 834.0, 899.0, 900.0, 1024.0]) {
        tester.view.physicalSize = Size(width, 1194);
        await tester.pumpWidget(app(
            MediaEpisodeDetailPage(episodeId: 'message-1', seed: {
              ...episode,
              '_collection': {'id': 'actual', 'title': 'Actual collection'},
              '_collection_tracks': [
                {'track_number': 1, 'episode': episode}
              ],
            }),
            brightness: brightness));
        await tester.pumpAndSettle();
        final clip = find.byKey(const ValueKey('message-artwork'));
        final contentWidth =
            (width >= 900 ? 820.0 : width) - (width < 600 ? 40.0 : 64.0);
        final artWidth =
            width >= 600 && contentWidth > 680 ? 680.0 : contentWidth;
        final artHeight = (artWidth * .75).clamp(0.0, 430.0);
        expect(tester.getSize(clip), Size(artWidth, artHeight));
        final gutter = width < 600 ? 20.0 : 32.0;
        expect(tester.getTopLeft(clip),
            Offset((width >= 900 ? (width - 820) / 2 : 0) + gutter, 88));
        expect(tester.widget<ClipRRect>(clip).borderRadius,
            BorderRadius.circular(20));
        await tester.scrollUntilVisible(find.text('In this collection'), 100,
            scrollable: find.byType(Scrollable).first);
        final heading = tester.widget<Text>(find.text('In this collection'));
        expect(heading.style!.fontSize, 15);
        expect(heading.style!.height, 24 / 17);
        expect(heading.style!.fontWeight, FontWeight.w600);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      }
    }
  });

  testWidgets('provider pill and collection tracks preserve reference geometry',
      (tester) async {
    final tracks = [
      for (var index = 1; index <= 3; index++)
        {
          'track_number': index,
          'episode': {...episode, 'title': 'Track $index'}
        }
    ];
    await tester.pumpWidget(app(Scaffold(
        body: Column(children: [
      const MediaProviderLink(
          url: 'https://open.spotify.com/episode/message-1',
          label: 'Open in Spotify',
          showChevron: false),
      MediaCollectionTracks(album: const {}, tracks: tracks),
    ]))));
    await tester.pumpAndSettle();
    final provider = find.byType(MediaProviderLink);
    final target =
        find.descendant(of: provider, matching: find.byType(InkWell));
    expect(tester.getSize(target).height, 48);
    expect(find.descendant(of: provider, matching: find.byType(Icon)),
        findsOneWidget);
    expect(tester.getSize(find.byType(MediaCollectionTracks)).height, 210);
    final title = tester.widget<Text>(find.text('Track 1'));
    expect(title.style!.fontSize, 12);
    expect(title.style!.height, 18 / 12);
    expect(title.style!.fontFamily, 'DM Sans');
    expect(title.style!.fontWeight, FontWeight.w500);
    final play = find.byTooltip('Play message').first;
    expect(tester.getSize(play), const Size(48, 48));
    expect(
        tester
            .widget<Icon>(
                find.descendant(of: play, matching: find.byType(Icon)))
            .size,
        20);
    expect(tester.takeException(), isNull);
  });

  testWidgets('direct message detail Back returns to Media safely',
      (tester) async {
    final router = GoRouter(initialLocation: '/media/message-1', routes: [
      GoRoute(
          path: '/media',
          builder: (_, __) => const Scaffold(body: Text('Media destination'))),
      GoRoute(
          path: '/media/:id',
          builder: (_, __) => MediaEpisodeDetailPage(
              episodeId: 'message-1',
              seed: episode,
              loadAlbums: () async => [])),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(
        theme: buildMemberTheme(buildWpccTheme()), routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Media destination'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    for (final family in ['DMSans_regular', 'DM Sans']) {
      await (FontLoader(family)
            ..addFont(rootBundle.load('assets/DMSans-Regular.ttf')))
          .load();
    }
    await (FontLoader('packages/phosphor_flutter/PhosphorRegular')
          ..addFont(rootBundle
              .load('packages/phosphor_flutter/lib/fonts/Phosphor.ttf')))
        .load();
  });

  testWidgets('both themes and text scales fit member Media and detail',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final brightness in Brightness.values) {
      for (final width in [320.0, 390.0, 393.0, 600.0, 768.0, 834.0, 1024.0]) {
        for (final scale in [1.0, 1.6, 2.0]) {
          tester.view.physicalSize = Size(
              width,
              width == 390
                  ? 844
                  : width == 834
                      ? 1194
                      : 1000);
          await tester.pumpWidget(app(
              MediaPage(loadVideos: () async => [], 
                key: UniqueKey(),
                loadEpisodes: () async => [
                  episode,
                  {...episode, 'id': 'message-2'}
                ],
                loadAlbums: () async => [
                  {
                    'id': 'album-1',
                    'title': 'Messages for the church community',
                    'featured_image': '',
                    'media_album_tracks': [
                      {'count': 4}
                    ],
                  },
                  {
                    'id': 'album-2',
                    'title': 'Faith and growth',
                    'featured_image': '',
                    'media_album_tracks': [
                      {'count': 6}
                    ]
                  },
                  {
                    'id': 'album-3',
                    'title': 'Church teachings',
                    'featured_image': '',
                    'media_album_tracks': [
                      {'count': 7}
                    ]
                  },
                ],
              ),
              brightness: brightness,
              scale: scale));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull,
              reason: '$brightness/$width/$scale Messages');
          if (Platform.environment['CAPTURE_MEMBER_UI'] == 'true' &&
              (width == 393 || width == 390 || width == 834) &&
              scale == 1) {
            await capture(tester, 'media-${brightness.name}-$width');
          }
          await tester.pumpWidget(app(
              MediaEpisodeDetailPage(
                  episodeId: 'message-1',
                  seed: episode,
                  loadAlbums: () async => []),
              brightness: brightness,
              scale: scale));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull,
              reason: '$brightness/$width/$scale detail');
          if (Platform.environment['CAPTURE_MEMBER_UI'] == 'true' &&
              (width == 393 || width == 390 || width == 834) &&
              scale == 1) {
            await capture(tester, 'media-detail-${brightness.name}-$width');
          }
        }
      }
    }
  });

  testWidgets('the Audio filter lists every message and keeps playback working',
      (tester) async {
    await tester.pumpWidget(app(MediaPage(
      shelfSeed: 1,
      loadVideos: () async => [],
      loadEpisodes: () async => [
        for (var i = 0; i < 6; i++)
          {...episode, 'id': 'track-$i', 'title': 'Track ${i + 1}'}
      ],
      loadAlbums: () async => [],
    )));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(MediaFilterChips), matching: find.text('Audio')));
    await tester.pumpAndSettle();
    expect(find.text('Track 1'), findsOneWidget);
    await tester.ensureVisible(find.byTooltip('Play message').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Play message').first);
    await tester.pump();
    expect(MediaPlayerController.instance.value.episode?.id, 'track-0');
    expect(find.byTooltip('Pause message'), findsOneWidget);
    MediaPlayerController.instance.close();
    expect(tester.takeException(), isNull);
  });

  testWidgets('detail discovers only the actual matching collection',
      (tester) async {
    await tester.pumpWidget(app(MediaEpisodeDetailPage(
      episodeId: 'message-1',
      seed: episode,
      loadAlbums: () async => [
        {'id': 'unrelated', 'title': 'Other collection'},
        {'id': 'actual', 'title': 'Actual collection'}
      ],
      loadAlbumTracks: (id) async => [
        {
          'track_number': 1,
          'episode': id == 'actual' ? episode : {...episode, 'id': 'other'}
        }
      ],
    )));
    await tester.pumpAndSettle();
    expect(find.text('Actual collection'), findsOneWidget);
    expect(find.text('Other collection'), findsNothing);
    await tester.scrollUntilVisible(find.text('In this collection'), 140,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('In this collection'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('message failure and retry preserve the real detail navigation',
      (tester) async {
    var calls = 0;
    final router = GoRouter(routes: [
      GoRoute(
          path: '/',
          builder: (_, __) => MediaPage(loadVideos: () async => [], 
                loadAlbums: () async => [],
                loadEpisodes: () async {
                  calls++;
                  if (calls == 1) throw StateError('Messages unavailable');
                  return [episode];
                },
              )),
      GoRoute(
          path: '/media/:id',
          builder: (_, state) => MediaEpisodeDetailPage(
              episodeId: state.pathParameters['id']!,
              loadAlbums: () async => [],
              seed: state.extra as Map<String, dynamic>)),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(
        theme: buildMemberTheme(buildWpccTheme()), routerConfig: router));
    await tester.pumpAndSettle();
    expect(find.text('Unable to load Spotify'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(episode['title'] as String));
    await tester.pumpAndSettle();
    await tester.tap(find.text(episode['title'] as String));
    await tester.pumpAndSettle();
    // Opening a message from the list starts it playing.
    expect(MediaPlayerController.instance.value.episode?.id, 'message-1');
    await tester.scrollUntilVisible(find.byTooltip('Pause message'), 180,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Pause message'), findsNothing);
    expect(tester.getSize(find.byTooltip('Pause message')), const Size(56, 56));
    await tester.pumpAndSettle();
    MediaPlayerController.instance.close();
  });
}

Future<void> capture(WidgetTester tester, String name) async {
  final render = captureBoundary.currentContext!.findRenderObject()!
      as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await render.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await File('${Directory.systemTemp.path}/wpcc-member-$name.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}
