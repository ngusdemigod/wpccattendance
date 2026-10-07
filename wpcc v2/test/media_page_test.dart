import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wpcc_community/core/theme/app_theme.dart';
import 'package:wpcc_community/features/media/media_page.dart';
import 'package:wpcc_community/features/media/media_player_controller.dart';
import 'package:wpcc_community/features/media/media_shelves.dart';

void main() {
  testWidgets('media page clearly exposes its empty Spotify state',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildWpccTheme(),
        home:
            MediaPage(loadVideos: () async => [], loadAlbums: () async => [], loadEpisodes: () async => []),
      ),
    );

    // The page title and the Media tab chip.
    expect(find.text('Media'), findsNWidgets(2));
    await tester.pumpAndSettle();
    expect(find.text('No media yet'), findsOneWidget);
  });

  testWidgets('media page renders a synced episode and opens its player',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildWpccTheme(),
        home: MediaPage(loadVideos: () async => [], 
          loadAlbums: () async => [],
          loadEpisodes: () async => [
            {
              'id': 'episode-1',
              'title': 'Sunday message',
              'description': 'A message for the church community.',
              'duration_ms': 3600000,
              'source_published_at': '2026-09-07',
              'artwork_url': '',
              'provider_url': 'https://open.spotify.com/episode/episode-1',
              'embed_url': 'https://open.spotify.com/embed/episode/episode-1',
            },
          ],
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Sunday message'), findsOneWidget);
    expect(find.text('Videos'), findsOneWidget);

    // The Audio filter lists messages as rows with a play button.
    await tester.tap(find.descendant(of: find.byType(MediaFilterChips), matching: find.text('Audio')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Play message'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Play message'));
    await tester.pump();
    expect(
        MediaPlayerController.instance.value.episode?.title, 'Sunday message');
    MediaPlayerController.instance.close();
  });
}
