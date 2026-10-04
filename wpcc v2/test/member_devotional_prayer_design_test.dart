import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:wpcc_community/core/theme/app_theme.dart';
import 'package:wpcc_community/core/theme/member_theme.dart';
import 'package:wpcc_community/core/widgets/member_components.dart';
import 'package:wpcc_community/features/devotional/devotional_page.dart';
import 'package:wpcc_community/features/prayer/prayer_alerts_content.dart';

const post = <String, dynamic>{
  'id': 'reading-1',
  'title': 'Faith for the days ahead',
  'body':
      'A real reading from our church community. Take a moment in the Word and carry it into the day.',
  'created_at': '2026-09-07T08:00:00Z',
  'more': {'author': 'WPCC', 'tag': 'Wisdom devotional'},
};
const church = <String, dynamic>{
  'id': 'church',
  'scope': 'global',
  'title': 'Church family prayer',
  'local_time': '06:00:00',
  'days_of_week': [1, 2, 3, 4, 5, 6, 7],
  'is_active': true,
  'duration_seconds': 900,
};
const personal = <String, dynamic>{
  'id': 'personal',
  'scope': 'personal',
  'title': 'Evening prayer',
  'local_time': '20:30:00',
  'days_of_week': [3],
  'is_active': false,
};
final boundary = GlobalKey();

Widget app(Widget child,
        {Brightness brightness = Brightness.light,
        double scale = 1,
        bool reducedMotion = true}) =>
    MaterialApp(
      theme: buildMemberTheme(buildWpccTheme(brightness: brightness)),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            disableAnimations: reducedMotion),
        child: RepaintBoundary(
            key: boundary, child: MemberBackdrop(child: child!)),
      ),
      home: child,
    );

PrayerAlertsContent content({
  List<Map<String, dynamic>> alerts = const [church, personal],
  ValueChanged<Map<String, dynamic>>? onTap,
  onStart,
  onCalendar,
  void Function(Map<String, dynamic>, bool)? onToggle,
  Set<String> starting = const {},
  Set<String> updating = const {},
  VoidCallback? onAdd,
  onBack,
  onEnablePush,
  String? error,
  Future<void> Function()? onRefresh,
}) =>
    PrayerAlertsContent(
      alerts: alerts,
      onRefresh: onRefresh ?? () async {},
      onTap: onTap ?? (_) {},
      onStart: onStart ?? (_) {},
      onCalendar: onCalendar ?? (_) {},
      onToggle: onToggle ?? (_, __) {},
      starting: starting,
      updating: updating,
      onAdd: onAdd,
      onBack: onBack,
      onEnablePush: onEnablePush,
      error: error,
    );

void main() {
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

  testWidgets(
      'prayer reminder toggle matches geometry and supports keyboard, drag and disabled semantics',
      (tester) async {
    final semantics = tester.ensureSemantics();
    bool value = false, enabled = true;
    final changes = <bool>[];
    late StateSetter rebuild;
    await tester.pumpWidget(
        app(Scaffold(body: StatefulBuilder(builder: (context, setState) {
      rebuild = setState;
      return Center(
          child: PrayerReminderSwitch(
              label: 'Morning reminder',
              value: value,
              onChanged: enabled
                  ? (next) => setState(() {
                        value = next;
                        changes.add(next);
                      })
                  : null));
    }))));
    await tester.pumpAndSettle();
    final toggle = find.byType(PrayerReminderSwitch);
    final track = find.descendant(
        of: toggle,
        matching: find.byWidgetPredicate((widget) =>
            widget is Container &&
            widget.constraints?.maxWidth == 44 &&
            widget.constraints?.maxHeight == 26));
    final thumb = find.descendant(
        of: toggle,
        matching: find.byWidgetPredicate((widget) =>
            widget is SizedBox && widget.width == 20 && widget.height == 20));
    expect(tester.getSize(toggle), const Size(51, 56));
    expect(tester.getSize(track), const Size(44, 26));
    expect(tester.getSize(thumb), const Size(20, 20));
    final off = tester.getTopLeft(thumb);
    expect(
        tester
            .getSemantics(toggle)
            .getSemanticsData()
            .flagsCollection
            .isToggled,
        ui.Tristate.isFalse);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(changes, [true]);
    expect(tester.getTopLeft(thumb), off + const Offset(18, 0));
    expect(
        tester
            .getSemantics(toggle)
            .getSemanticsData()
            .flagsCollection
            .isToggled,
        ui.Tristate.isTrue);
    expect((tester.widget<Container>(track).decoration as BoxDecoration).color,
        const Color(0xFF29996C));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(changes, [true, false]);

    final gesture = await tester.startGesture(tester.getCenter(toggle));
    await gesture.moveBy(const Offset(20, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(9, 0));
    await tester.pump();
    expect(tester.getTopLeft(thumb).dx, greaterThan(off.dx));
    await gesture.moveBy(const Offset(9, 0));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(value, isTrue);
    expect(changes, [true, false, true]);
    rebuild(() => enabled = false);
    await tester.pumpAndSettle();
    final disabled = tester.getSemantics(toggle).getSemanticsData();
    expect(disabled.flagsCollection.isToggled, ui.Tristate.isTrue);
    expect(disabled.flagsCollection.isEnabled, ui.Tristate.isFalse);
    expect(disabled.hasAction(ui.SemanticsAction.tap), isFalse);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(changes, [true, false, true]);
    semantics.dispose();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'prayer reminder movement is interruptible, cancelable and respects reduced motion and RTL',
      (tester) async {
    bool value = false;
    late StateSetter rebuild;
    final child = Scaffold(body: StatefulBuilder(builder: (context, setState) {
      rebuild = setState;
      return Center(
          child: PrayerReminderSwitch(
              label: 'Morning reminder',
              value: value,
              onChanged: (next) => setState(() => value = next)));
    }));
    final toggle = find.byType(PrayerReminderSwitch);
    final thumb = find.descendant(
        of: toggle,
        matching: find.byWidgetPredicate((widget) =>
            widget is SizedBox && widget.width == 20 && widget.height == 20));
    await tester.pumpWidget(app(child, reducedMotion: false));
    await tester.pumpAndSettle();
    final off = tester.getTopLeft(thumb);
    await tester.tap(toggle);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    final intermediate = tester.getTopLeft(thumb).dx;
    expect(intermediate, greaterThan(off.dx));
    expect(intermediate, lessThan(off.dx + 18));
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(value, isFalse);
    expect(tester.getTopLeft(thumb), off);
    final gesture = await tester.startGesture(tester.getCenter(toggle));
    await gesture.moveBy(const Offset(20, 0));
    await gesture.moveBy(const Offset(9, 0));
    await tester.pump();
    expect(tester.getTopLeft(thumb).dx, greaterThan(off.dx));
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(value, isFalse);
    expect(tester.getTopLeft(thumb), off);
    rebuild(() => value = true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    await tester.pumpWidget(app(child));
    expect(tester.getTopLeft(thumb), off + const Offset(18, 0));
    await tester.pumpWidget(
        app(Directionality(textDirection: TextDirection.rtl, child: child)));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(thumb), off);
    await tester.tap(toggle);
    await tester.pump();
    expect(tester.getTopLeft(thumb), off + const Offset(18, 0));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'single personal reminder aligns with the reference without empty group sections',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final brightness in Brightness.values) {
      for (final size in [const Size(390, 844), const Size(834, 1194)]) {
        tester.view.physicalSize = size;
        await tester.pumpWidget(app(
            Scaffold(body: content(alerts: const [personal], onBack: () {})),
            brightness: brightness));
        await tester.pumpAndSettle();
        final row = tester.getRect(find.byType(PrayerAlertRow));
        final bio = tester.getRect(find.text('A quiet moment, every day.'));
        expect(row.top - bio.bottom, 25);
        expect(row.height, 78);
        final start = tester.getRect(find
            .descendant(
                of: find.widgetWithText(FilledButton, 'Start prayer'),
                matching: find.byType(Material))
            .first);
        final calendar = tester.getRect(find
            .descendant(
                of: find.widgetWithText(TextButton, 'Calendar'),
                matching: find.byType(Material))
            .first);
        expect(start.top - row.bottom, 22);
        expect(calendar.top - start.bottom, 10);
        expect(find.text('No church prayer alerts'), findsNothing);
        expect(find.text('My prayer alerts'), findsNothing);
        expect(find.text('Church prayer alerts'), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      }
    }
  });

  testWidgets(
      'reading and prayer hubs fit both themes and accessible text sizes',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final brightness in Brightness.values) {
      for (final width in [320.0, 390.0, 600.0, 834.0, 1024.0]) {
        for (final scale in [1.0, 1.6, 2.0]) {
          tester.view.physicalSize = Size(
              width,
              width == 390
                  ? 844
                  : width == 834
                      ? 1194
                      : 1000);
          await tester.pumpWidget(app(
              DevotionalPage(
                  key: UniqueKey(),
                  loadPosts: ({int offset = 0, int limit = 20}) async => [
                        post,
                        {
                          ...post,
                          'id': 'reading-2',
                          'title': 'A second reading'
                        }
                      ]),
              brightness: brightness,
              scale: scale));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull,
              reason: 'Devotional $brightness/$width/$scale');
          if (Platform.environment['CAPTURE_MEMBER_UI'] == 'true' &&
              (width == 390 || width == 834) &&
              scale == 1) {
            await capture(tester, 'devotional-${brightness.name}-$width');
          }
          await tester.drag(
              find.byType(ListView).first, const Offset(0, -2000));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(app(Scaffold(body: content()),
              brightness: brightness, scale: scale));
          await tester.pumpAndSettle();
          expect(find.byType(PrayerReminderSwitch), findsOneWidget);
          expect(find.text('06:00'), findsOneWidget);
          expect(find.text('20:30'), findsOneWidget);
          expect(tester.takeException(), isNull,
              reason: 'Prayer $brightness/$width/$scale');
          if (Platform.environment['CAPTURE_MEMBER_UI'] == 'true' &&
              (width == 390 || width == 834) &&
              scale == 1) {
            await capture(tester, 'prayer-${brightness.name}-$width');
          }
          await tester.drag(
              find.byType(ListView).first, const Offset(0, -2000));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      }
    }
  });

  testWidgets(
      'prayer permissions and every alert action survive the compact layout',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 1194);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final tapped = <String>[];
    final started = <String>[];
    final exported = <String>[];
    final toggled = <String>[];
    await tester.pumpWidget(app(Scaffold(
        body: content(
      onTap: (a) => tapped.add(a['id'] as String),
      onStart: (a) => started.add(a['id'] as String),
      onCalendar: (a) => exported.add(a['id'] as String),
      onToggle: (a, value) => toggled.add('${a['id']}:$value'),
    ))));
    await tester.pumpAndSettle();
    expect(find.byType(PrayerReminderSwitch), findsOneWidget);
    await tester.tap(find.byType(PrayerReminderSwitch));
    await tester.tap(find.byTooltip('Edit Evening prayer'));
    await tester.tap(find.text('Church family prayer'));
    expect(toggled, ['personal:true']);
    expect(tapped, ['personal', 'church']);
    await tester.tap(find.text('Start prayer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Evening prayer').last);
    await tester.pumpAndSettle();
    expect(started, ['personal']);
    await tester.tap(find.text('Calendar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Church family prayer').last);
    await tester.pumpAndSettle();
    expect(exported, ['church']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('prayer busy actions disable without granting editing rights',
      (tester) async {
    await tester.pumpWidget(app(Scaffold(
        body: content(
            starting: const {'church', 'personal'},
            updating: const {'personal'}))));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<PrayerReminderSwitch>(find.byType(PrayerReminderSwitch))
            .onChanged,
        isNull);
    expect(
        tester
            .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Start prayer'))
            .onPressed,
        isNull);
    expect(find.byTooltip('Edit Church family prayer'), findsNothing);
    expect(
        tester
            .widget<IconButton>(find.byWidgetPredicate((widget) =>
                widget is IconButton &&
                widget.tooltip == 'Start Church family prayer'))
            .onPressed,
        isNull);
  });

  testWidgets('prayer matches reference gutters and full-width actions',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var backs = 0;
    for (final brightness in Brightness.values) {
      for (final width in [390.0, 834.0, 1024.0]) {
        tester.view.physicalSize = Size(width, 1194);
        await tester.pumpWidget(app(
            Scaffold(
                body: content(alerts: const [personal], onBack: () => backs++)),
            brightness: brightness));
        await tester.pumpAndSettle();
        final gutter = width < 600 ? 20.0 : 32.0;
        final pageWidth = width >= 900 ? 820.0 : width;
        final left = (width - pageWidth) / 2 + gutter;
        final header = tester.getRect(find.byType(MemberPageHeader));
        expect(header.topLeft, Offset(left, 20));
        expect(header.width, pageWidth - 2 * gutter);
        for (final button in [
          find.widgetWithText(FilledButton, 'Start prayer'),
          find.widgetWithText(TextButton, 'Calendar'),
        ]) {
          final surface = find
              .descendant(of: button, matching: find.byType(Material))
              .first;
          expect(tester.getSize(surface), Size(header.width, 48));
        }
        expect(tester.getSize(find.byType(PrayerAlertRow)).height,
            greaterThanOrEqualTo(76));
        expect(tester.getSize(find.byType(PrayerReminderSwitch)),
            const Size(51, 56));
        expect(find.text('My prayer alerts'), findsNothing);
        expect(find.text('Church prayer alerts'), findsNothing);
        await tester.tap(find.byTooltip('Back'));
        expect(tester.takeException(), isNull);
      }
    }
    expect(backs, 6);
  });

  testWidgets(
      'single prayer starts and exports directly and utilities remain live',
      (tester) async {
    final actions = <String>[];
    await tester.pumpWidget(app(Scaffold(
        body: content(
      alerts: const [personal],
      onStart: (a) => actions.add('start:${a['id']}'),
      onCalendar: (a) => actions.add('calendar:${a['id']}'),
      onAdd: () => actions.add('add'),
      onEnablePush: () => actions.add('push'),
    ))));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add prayer alert'));
    await tester.scrollUntilVisible(find.text('Start prayer'), 200);
    await tester.tap(find.text('Start prayer'));
    await tester.scrollUntilVisible(find.text('Calendar'), 100);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Calendar'));
    await tester.scrollUntilVisible(find.text('Enable push reminders'), 200);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enable push reminders'));
    expect(actions, ['add', 'start:personal', 'calendar:personal', 'push']);
  });

  testWidgets('devotional routes retain actual post and prayer destinations',
      (tester) async {
    Map<String, dynamic>? opened;
    final router = GoRouter(initialLocation: '/devotional', routes: [
      GoRoute(
          path: '/home',
          builder: (_, __) => const Scaffold(body: Text('Home destination'))),
      GoRoute(
          path: '/devotional',
          builder: (_, __) => DevotionalPage(
              loadPosts: ({int offset = 0, int limit = 20}) async => [post])),
      GoRoute(
          path: '/devotional/:id',
          builder: (_, state) {
            opened = state.extra as Map<String, dynamic>;
            return const Scaffold(body: Text('Post detail'));
          }),
      GoRoute(
          path: '/prayer-alerts',
          builder: (_, __) => const Scaffold(body: Text('Prayer hub'))),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(
        routerConfig: router, theme: buildMemberTheme(buildWpccTheme())));
    await tester.pumpAndSettle();
    expect(find.textContaining('3 min read'), findsNothing);
    expect(find.text('Today'), findsNothing);
    await tester.scrollUntilVisible(find.text('Read devotional'), 200);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Read devotional'));
    await tester.pumpAndSettle();
    expect(opened, post);
    router.pop();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Prayer'), 200);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Prayer'));
    await tester.pumpAndSettle();
    expect(find.text('Prayer hub'), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byTooltip('Back'), -200);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Home destination'), findsOneWidget);
  });

  testWidgets('devotional pagination retries at the same actual offset',
      (tester) async {
    final offsets = <int>[];
    var failed = false;
    await tester.pumpWidget(
        app(DevotionalPage(loadPosts: ({int offset = 0, int limit = 20}) async {
      offsets.add(offset);
      if (offset == 0) return List.generate(20, (i) => {...post, 'id': '$i'});
      if (!failed) {
        failed = true;
        throw StateError('offline');
      }
      return [];
    })));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Load more'), 700,
        maxScrolls: 40);
    await tester.tap(find.text('Load more'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Retry'), 150);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(offsets, [0, 20, 20]);
    expect(find.text('Load more'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('devotional artwork uses reference phone and tablet bounds',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final width in [390.0, 834.0]) {
      tester.view.physicalSize = Size(width, 1194);
      await tester.pumpWidget(app(DevotionalPage(
          key: UniqueKey(),
          loadPosts: ({int offset = 0, int limit = 20}) async => [post])));
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byType(MemberPageHeader)).topLeft,
          Offset(width < 600 ? 20 : 32, 20));
      expect(tester.getSize(find.byType(MemberArtwork)),
          width < 600 ? const Size(350, 262.5) : const Size(680, 430));
      expect(find.byTooltip('Back'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('real loaders keep loading error empty and retry states',
      (tester) async {
    final pending = Completer<List<Map<String, dynamic>>>();
    await tester.pumpWidget(app(DevotionalPage(
        loadPosts: ({int offset = 0, int limit = 20}) => pending.future)));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pending.complete([]);
    await tester.pumpAndSettle();
    expect(find.text('No devotional posts yet'), findsOneWidget);
    var attempts = 0;
    await tester.pumpWidget(app(DevotionalPage(
        key: UniqueKey(),
        loadPosts: ({int offset = 0, int limit = 20}) async {
          attempts++;
          if (attempts == 1) throw StateError('offline');
          return [post];
        })));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.text(post['title'] as String), findsOneWidget);
    await tester.pumpWidget(app(Scaffold(
        body: PrayerAlertsContent(
      alerts: const [],
      loading: true,
      onRefresh: () async {},
      onTap: (_) {},
      onStart: (_) {},
      onCalendar: (_) {},
      onToggle: (_, __) {},
    ))));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Prayer alerts'), findsOneWidget);
    var retries = 0;
    await tester.pumpWidget(app(Scaffold(
        body: content(
            alerts: const [],
            error: 'Unable to load prayer alerts',
            onRefresh: () async {
              retries++;
            }))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(retries, 1);
    await tester.pumpWidget(app(Scaffold(body: content(alerts: const []))));
    await tester.pumpAndSettle();
    expect(find.text('No prayer alerts'), findsOneWidget);
    expect(find.text('Start prayer'), findsNothing);
    expect(PrayerAlertRow.time(const {}), '--:--');
    expect(PrayerAlertRow.time(const {'local_time': '99:80'}), '--:--');
    expect(tester.takeException(), isNull);
  });
}

Future<void> capture(WidgetTester tester, String name) async {
  final render =
      boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await render.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await File('${Directory.systemTemp.path}/wpcc-member-$name.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}
