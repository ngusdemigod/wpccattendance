import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wpcc_community/core/theme/app_theme.dart';
import 'package:wpcc_community/features/media/media_page.dart';

void main() {
  testWidgets('media page clearly exposes its empty Spotify state',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildWpccTheme(),
        home: MediaPage(loadEpisodes: () async => []),
      ),
    );

    expect(find.text('Messages & podcasts'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('No episodes yet'), findsOneWidget);
  });

  testWidgets('media page renders a synced episode and opens its player',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildWpccTheme(),
        home: MediaPage(
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
    expect(find.text('Play'), findsOneWidget);

    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();
    expect(find.text('Listen on Spotify'), findsOneWidget);
  });
}
