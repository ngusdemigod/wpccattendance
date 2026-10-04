import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wpcc_community/core/theme/app_theme.dart';
import 'package:wpcc_community/core/theme/member_theme.dart';
import 'package:wpcc_community/core/widgets/member_components.dart';
import 'package:wpcc_community/core/widgets/member_sheet.dart';

Widget _harness(
    {Brightness brightness = Brightness.light,
    double scale = 1,
    bool solid = false,
    double keyboard = 0,
    bool nested = false}) {
  Widget launch(BuildContext context) => Scaffold(
          body: Center(
              child: TextButton(
        child: const Text('Open filters'),
        onPressed: () => showMemberSheet<void>(
            context: context,
            title: 'Search filters',
            builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
                  for (final label in [
                    'All',
                    'Events',
                    'Departments',
                    'Announcements',
                    'People'
                  ])
                    Padding(
                        padding:
                            EdgeInsets.only(bottom: label == 'People' ? 0 : 7),
                        child: MemberListRow(
                            title: label,
                            trailing: const SizedBox.shrink(),
                            onTap: () {})),
                ])),
      )));
  return MaterialApp(
    theme: buildWpccTheme(brightness: brightness),
    builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            highContrast: solid,
            disableAnimations: solid,
            viewInsets: EdgeInsets.only(bottom: keyboard)),
        child: child!),
    home: MemberTheme(
        child: nested
            ? Navigator(
                onGenerateRoute: (_) =>
                    MaterialPageRoute<void>(builder: launch))
            : Builder(builder: launch)),
  );
}

void main() {
  testWidgets('repeated close cannot pop the underlying page', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.tap(find.text('Open filters'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Close'));
    // The exiting surface is intentionally excluded from pointer hit testing.
    await tester.tap(find.byTooltip('Close'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('Open filters'), findsOneWidget);
    expect(find.byType(MemberSheet), findsNothing);
    expect(tester.takeException(), isNull);
  });

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await (FontLoader('DM Sans')
          ..addFont(rootBundle.load('assets/DMSans-Regular.ttf')))
        .load();
  });

  testWidgets(
      'reference sheets are inset on phones and centered on tablets in both themes',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final brightness in Brightness.values) {
      for (final size in [const Size(390, 844), const Size(834, 1194)]) {
        tester.view.physicalSize = size;
        await tester.pumpWidget(_harness(brightness: brightness));
        await tester.tap(find.text('Open filters'));
        await tester.pumpAndSettle();
        final rect =
            tester.getRect(find.byKey(const ValueKey('member-sheet-surface')));
        expect(rect.width, size.width == 390 ? 374 : 560);
        if (size.width == 390) {
          expect(rect.left, 8);
          expect(rect.bottom, 836);
          expect(rect.height, 515);
        } else {
          expect(rect.center, const Offset(417, 597));
          expect(rect.height, 519);
        }
        final title = tester.widget<Text>(find.text('Search filters'));
        expect(title.style!.fontSize, 26);
        expect(title.style!.height, 33 / 26);
        expect(
            title.style!.fontFamily,
            buildMemberTheme(buildWpccTheme())
                .textTheme
                .headlineSmall!
                .fontFamily);
        final surface = tester.widget<Container>(
            find.byKey(const ValueKey('member-sheet-surface')));
        expect((surface.decoration! as BoxDecoration).borderRadius,
            BorderRadius.circular(32));
        expect(tester.getSize(find.byTooltip('Close')), const Size(48, 48));
        expect(
            tester
                .getSize(find.byKey(const ValueKey('member-sheet-grip')))
                .height,
            48);
        for (final row in find.byType(MemberListRow).evaluate()) {
          expect(tester.getSize(find.byWidget(row.widget)).height, 76);
        }
        await tester.tap(find.byTooltip('Close'));
        await tester.pumpAndSettle();
        expect(find.byType(MemberSheet), findsNothing);
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets(
      'root modal captures member theme and dismisses by backdrop, Escape and Back',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(_harness(nested: true));
    for (final action in ['backdrop', 'escape', 'back', 'focused-close']) {
      await tester.tap(find.text('Open filters'));
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(MemberSheet));
      expect(Theme.of(context).textTheme.titleMedium!.fontSize, 15);
      expect(ModalRoute.of(context)!.navigator,
          Navigator.of(context, rootNavigator: true));
      if (action == 'backdrop') {
        await tester.tapAt(const Offset(20, 20));
      } else if (action == 'escape') {
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      } else if (action == 'back') {
        await tester.binding.handlePopRoute();
      } else {
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      }
      await tester.pumpAndSettle();
      expect(find.byType(MemberSheet), findsNothing);
      expect(find.text('Open filters'), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'grip tracks the drag and cancellation restores its current position',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(_harness());
    await tester.tap(find.text('Open filters'));
    await tester.pumpAndSettle();
    final surface = find.byKey(const ValueKey('member-sheet-surface'));
    final original = tester.getTopLeft(surface);
    final grip = find.byKey(const ValueKey('member-sheet-grip'));
    final gesture = await tester.startGesture(tester.getCenter(grip));
    await gesture.moveBy(const Offset(0, 30));
    await tester.pump();
    await gesture.moveBy(const Offset(0, 40));
    await tester.pump();
    expect(tester.getTopLeft(surface).dy, original.dy + 70);
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(surface), original);
    await tester.drag(grip, const Offset(0, 180));
    await tester.pumpAndSettle();
    expect(find.byType(MemberSheet), findsNothing);
  });

  testWidgets(
      'enlarged text, small viewports and keyboard keep sheet content scrollable',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final size in [const Size(320, 568), const Size(834, 1194)]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(_harness(
          scale: 2, solid: true, keyboard: size.width == 320 ? 240 : 0));
      await tester.tap(find.text('Open filters'));
      await tester.pumpAndSettle();
      final sheet = find.byType(MemberSheet);
      final scroll =
          find.descendant(of: sheet, matching: find.byType(Scrollable));
      await tester.scrollUntilVisible(find.text('People'), 100,
          scrollable: scroll);
      expect(find.text('People').hitTestable(), findsOneWidget);
      final context = tester.element(sheet);
      final decor = find
          .descendant(of: sheet, matching: find.byType(DecoratedBox))
          .evaluate()
          .map((e) => (e.widget as DecoratedBox).decoration)
          .whereType<BoxDecoration>()
          .where((d) => d.border != null)
          .single;
      expect(decor.color!.a, 1);
      expect((decor.border! as Border).top.color,
          Theme.of(context).colorScheme.onSurfaceVariant);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
    }
  });
}
