import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wpcc_community/core/theme/app_theme.dart';
import 'package:wpcc_community/features/media/media_page.dart';

void main() {
  testWidgets('media page clearly exposes its Spotify configuration state',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildWpccTheme(),
        home: const MediaPage(),
      ),
    );

    expect(find.text('Messages & podcasts'), findsOneWidget);
    expect(find.text('Spotify podcast not connected'), findsOneWidget);
  });
}
