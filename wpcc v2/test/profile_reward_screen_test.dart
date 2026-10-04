import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wpcc_community/features/onboarding/profile_reward_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  testWidgets(
      'v3 award badge, layout, inline interaction and close match at target heights',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final size in [
      const Size(390, 844),
      const Size(375, 667),
      const Size(768, 1024),
      const Size(375, 420)
    ]) {
      tester.view.physicalSize = size;
      var closed = false;
      await tester.pumpWidget(MaterialApp(
          home: MediaQuery(
              data: MediaQueryData(size: size, disableAnimations: true),
              child: RepaintBoundary(
                  key: const Key('capture-award'),
                  child: ProfileRewardScreen(
                      awarded: true, onClose: () => closed = true)))));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final badge = tester.widget<Image>(find.byKey(const Key('reward-badge')));
      expect((badge.image as AssetImage).assetName,
          'assets/images/profile_reward_badge.png');
      expect(badge.width, size.height <= 780 ? 176 : 212);
      expect(tester.getTopLeft(find.byKey(const Key('reward-title'))).dy,
          size.height <= 780 ? 308 : 392);
      expect(find.text('+15WP'), findsOneWidget);
      if (const bool.fromEnvironment('CAPTURE_AWARD')) {
        await tester.runAsync(() async {
          for (final row in [
            [
              GoogleFonts.manrope(fontWeight: FontWeight.w800).fontFamily!,
              'Manrope-ExtraBold.ttf'
            ],
            [GoogleFonts.dmSans().fontFamily!, 'DMSans-Regular.ttf'],
            [GoogleFonts.dmSans().fontFamily!, 'DMSans-Regular.ttf'],
            [
              GoogleFonts.dmSans(fontWeight: FontWeight.w700).fontFamily!,
              'DMSans-Bold.ttf'
            ],
          ]) {
            await (FontLoader(row[0])
                  ..addFont(rootBundle.load('assets/${row[1]}')))
                .load();
          }
          await (FontLoader('packages/phosphor_flutter/PhosphorRegular')
                ..addFont(rootBundle
                    .load('packages/phosphor_flutter/lib/fonts/Phosphor.ttf')))
              .load();
          await precacheImage(
              const AssetImage('assets/images/profile_reward_badge.png'),
              tester.element(find.byType(ProfileRewardScreen)));
        });
        await tester.pump();
        await tester.runAsync(() async {
          final image = await tester
              .renderObject<RenderRepaintBoundary>(
                  find.byKey(const Key('capture-award')))
              .toImage();
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(
                  '${Directory.systemTemp.path}/wpcc-award-${size.width.toInt()}x${size.height.toInt()}.png')
              .writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.ensureVisible(find.byKey(const Key('reward-footer')));
      final semantics = tester.widget<Semantics>(find
          .ancestor(
              of: find.byKey(const Key('reward-footer')),
              matching: find.byType(Semantics))
          .first);
      semantics.properties.onTap!();
      await tester.pump();
      expect(
          find.textContaining('More ways to earn WP coming soon',
              findRichText: true),
          findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1800));
      expect(
          find.textContaining('More ways to earn WP coming soon',
              findRichText: true),
          findsNothing);
      await tester.tap(find.byTooltip('Close reward'));
      await tester.pump();
      expect(closed, isTrue);
      await tester.pumpWidget(const SizedBox());
    }
  });
  testWidgets(
      'pending reward never claims points; entrance starts badge after 480ms',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        home: RepaintBoundary(
            key: const Key('animated-award-capture'),
            child: ProfileRewardScreen(awarded: false, onClose: () {}))));
    Opacity opacity() => tester.widget<Opacity>(find
        .ancestor(
            of: find.byKey(const Key('reward-badge')),
            matching: find.byType(Opacity))
        .first);
    expect(opacity().opacity, 0);
    await tester.pump(const Duration(milliseconds: 400));
    expect(opacity().opacity, 0);
    await tester.pump(const Duration(milliseconds: 400));
    expect(opacity().opacity, greaterThan(0));
    expect(find.text('+15WP'), findsNothing);
    expect(find.text('Reward on its way'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1700));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(MaterialApp(
        home: RepaintBoundary(
            key: const Key('animated-award-capture'),
            child: ProfileRewardScreen(awarded: true, onClose: () {}))));
    await tester.pump(const Duration(milliseconds: 2500));
    expect(find.text('+15WP'), findsOneWidget);
    if (const bool.fromEnvironment('CAPTURE_AWARD')) {
      await tester.runAsync(() async {
        final image = await tester
            .renderObject<RenderRepaintBoundary>(
                find.byKey(const Key('animated-award-capture')))
            .toImage();
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('${Directory.systemTemp.path}/wpcc-award-animated.png')
            .writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
    }

    await tester.pumpWidget(const SizedBox());
  });
}
