import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wpcc_community/core/theme/app_theme.dart';
import 'package:wpcc_community/core/widgets/member_shimmer.dart';
import 'package:wpcc_community/features/media/media_download_button.dart';
import 'package:wpcc_community/features/media/media_page.dart';
import 'package:wpcc_community/features/media/media_save_outcome.dart';
import 'package:wpcc_community/features/media/media_skeletons.dart';

Widget host(Widget child) => MaterialApp(
    theme: buildWpccTheme(), home: Scaffold(body: Center(child: child)));

void main() {
  group('download button', () {
    const photo = {'id': 'p1'};

    testWidgets('shows progress, then a check, then goes back to the icon',
        (tester) async {
      final gate = Completer<Uint8List>();
      String? savedAs;
      await tester.pumpWidget(host(MediaDownloadButton(
          photo: photo,
          loadFile: (_) => gate.future,
          save: (bytes, {required filename, required mime}) async {
            savedAs = '$filename $mime ${bytes.length}';
            return SaveOutcome.shared;
          })));
      await tester.tap(find.byType(MediaDownloadButton));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // A second tap while busy does nothing.
      await tester.tap(find.byType(MediaDownloadButton));
      gate.complete(Uint8List.fromList([1, 2, 3]));
      await tester.pump(const Duration(milliseconds: 300));
      expect(savedAs, 'wpcc-photo-p1.webp image/webp 3');
      expect(find.byIcon(Icons.check), findsNothing); // Phosphor icon, not Material
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Could not download this photo'), findsNothing);
    });

    testWidgets('closing the save dialog is not an error', (tester) async {
      await tester.pumpWidget(host(MediaDownloadButton(
          photo: photo,
          loadFile: (_) async => Uint8List(1),
          save: (bytes, {required filename, required mime}) async =>
              SaveOutcome.cancelled)));
      await tester.tap(find.byType(MediaDownloadButton));
      await tester.pumpAndSettle();
      expect(find.text('Could not download this photo'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('a failure says so and the button can be tried again',
        (tester) async {
      var calls = 0;
      await tester.pumpWidget(host(MediaDownloadButton(
          photo: photo,
          loadFile: (_) async {
            calls++;
            throw Exception('offline');
          })));
      await tester.tap(find.byType(MediaDownloadButton));
      await tester.pumpAndSettle();
      expect(find.text('Could not download this photo'), findsOneWidget);
      await tester.tap(find.byType(MediaDownloadButton));
      await tester.pumpAndSettle();
      expect(calls, 2);
    });
  });

  group('skeletons', () {
    testWidgets('each Media section has a shimmering placeholder while loading',
        (tester) async {
      final never = Completer<List<Map<String, dynamic>>>();
      await tester.pumpWidget(MaterialApp(
          theme: buildWpccTheme(),
          home: MediaPage(
              loadEpisodes: () => never.future,
              loadAlbums: () => never.future,
              loadVideos: () => never.future)));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(MediaStoriesSkeleton), findsOneWidget);
      expect(find.byType(MediaFeedSkeleton), findsOneWidget);
      expect(find.byType(MemberShimmer), findsNWidgets(2));
      expect(find.bySemanticsLabel('Loading media'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the gallery placeholder fits 2, 3 and 4 columns',
        (tester) async {
      for (final columns in [2, 3, 4]) {
        // Inside a scroll view, as on the real page.
        await tester.pumpWidget(host(SingleChildScrollView(
            child: SizedBox(
                width: 400, child: GallerySkeleton(columns: columns)))));
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.byType(MemberBone), findsNWidgets(columns * 3));
        expect(tester.takeException(), isNull, reason: '$columns columns');
      }
    });

    testWidgets('the shimmer stops when animations are off', (tester) async {
      await tester.pumpWidget(MaterialApp(
          theme: buildWpccTheme(),
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!),
          home: const Scaffold(
              body: MemberShimmer(child: MemberBone(height: 20)))));
      // Nothing is animating, so the test can settle.
      await tester.pumpAndSettle(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull);
    });
  });
}
