import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wpcc_community/core/theme/app_theme.dart';
import 'package:wpcc_community/core/theme/member_theme.dart';
import 'package:wpcc_community/core/widgets/member_shimmer.dart';
import 'package:wpcc_community/features/prayer/prayer_alert_edit_page.dart';
import 'package:wpcc_community/features/prayer/prayer_alerts_content.dart';
import 'package:wpcc_community/features/prayer/prayer_alerts_view.dart';
import 'package:wpcc_community/features/prayer/prayer_schedule.dart';
import 'package:wpcc_community/features/prayer/prayer_session_page.dart';

// 2026-10-05 is a Monday.
final monday = DateTime.utc(2026, 10, 5);
DateTime at(int day, int hour, [int minute = 0]) =>
    DateTime.utc(2026, 10, 5 + day, hour, minute);

Map<String, dynamic> alert(String id, String time,
        {String scope = 'personal',
        bool active = true,
        List<int> days = const [1, 2, 3, 4, 5, 6, 7],
        String? timezone,
        String? title}) =>
    {
      'id': id,
      'scope': scope,
      'title': title ?? 'Alert $id',
      'local_time': time,
      'days_of_week': days,
      'is_active': active,
      'duration_seconds': 900,
      if (timezone != null) 'timezone': timezone,
    };

final global = alert('g', '06:00:00', scope: 'global', title: 'Church family');
final branch = alert('b', '12:00:00', scope: 'branch', title: 'Branch noon');
final mine = alert('m', '20:30:00', title: 'Evening prayer', days: [1, 3, 5]);
final mineOff =
    alert('o', '05:45:00', title: 'Early prayer', active: false, days: [6, 7]);

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
            padding: const EdgeInsets.only(bottom: 34),
            disableAnimations: reducedMotion),
        child: RepaintBoundary(
            key: boundary, child: MemberBackdrop(child: child!)),
      ),
      home: child,
    );

PrayerAlertsContent content(List<Map<String, dynamic>> alerts,
        {void Function(Map<String, dynamic>, bool)? onToggle,
        ValueChanged<Map<String, dynamic>>? onStart,
        VoidCallback? onAdd,
        VoidCallback? onEnablePush,
        Set<String> starting = const {},
        DateTime? now}) =>
    PrayerAlertsContent(
      alerts: alerts,
      now: now ?? at(0, 4),
      onRefresh: () async {},
      onTap: (_) {},
      onStart: onStart ?? (_) {},
      onCalendar: (_) {},
      onToggle: onToggle ?? (_, __) {},
      onAdd: onAdd ?? () {},
      onEnablePush: onEnablePush,
      starting: starting,
      onBack: () {},
    );

Future<void> capture(WidgetTester tester, String name) async {
  if (Platform.environment['CAPTURE_MEMBER_UI'] != 'true') return;
  final render =
      boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await render.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await File('${Directory.systemTemp.path}/wpcc-prayer-$name.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(const {});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-publishable-key',
    );
    for (final family in ['DMSans_regular', 'DM Sans']) {
      await (FontLoader(family)
            ..addFont(rootBundle.load('assets/DMSans-Regular.ttf'))
            ..addFont(rootBundle.load('assets/DMSans-Medium.ttf'))
            ..addFont(rootBundle.load('assets/DMSans-SemiBold.ttf'))
            ..addFont(rootBundle.load('assets/DMSans-Bold.ttf')))
          .load();
    }
    await (FontLoader('packages/phosphor_flutter/PhosphorRegular')
          ..addFont(rootBundle
              .load('packages/phosphor_flutter/lib/fonts/Phosphor.ttf')))
        .load();
    await (FontLoader('packages/phosphor_flutter/PhosphorBold')
          ..addFont(rootBundle
              .load('packages/phosphor_flutter/lib/fonts/Phosphor-Bold.ttf')))
        .load();
    await (FontLoader('packages/phosphor_flutter/PhosphorFill')
          ..addFont(rootBundle
              .load('packages/phosphor_flutter/lib/fonts/Phosphor-Fill.ttf')))
        .load();
  });

  tearDownAll(() async {
    await Supabase.instance.dispose();
  });

  group('PrayerSchedule', () {
    test('next occurrence and countdown from fixed times', () {
      final daily = alert('a', '06:00:00');
      var next = PrayerSchedule.nextOf(daily, at(0, 4))!;
      expect([next.minutesUntil, next.dayOffset, next.weekday], [120, 0, 1]);
      expect(PrayerSchedule.countdown(next), 'In 2 h');

      next = PrayerSchedule.nextOf(daily, at(0, 6, 30))!;
      expect([next.minutesUntil, next.dayOffset], [1410, 1]);
      expect(PrayerSchedule.countdown(next), 'In 23 h 30 min');

      next = PrayerSchedule.nextOf(alert('a', '08:00:00'), at(0, 8))!;
      expect(next.minutesUntil, 0);
      expect(PrayerSchedule.countdown(next), 'Now');

      next = PrayerSchedule.nextOf(alert('a', '09:15:00'), at(0, 8, 50))!;
      expect(PrayerSchedule.countdown(next), 'In 25 min');

      // Tomorrow, but more than 24 hours away.
      next = PrayerSchedule.nextOf(
          alert('a', '09:00:00', days: const [2]), at(0, 8))!;
      expect([next.minutesUntil, next.dayOffset], [25 * 60, 1]);
      expect(PrayerSchedule.countdown(next), 'Tomorrow');

      // Wednesday only, from Monday morning.
      next = PrayerSchedule.nextOf(
          alert('a', '20:30:00', days: const [3]), at(0, 10))!;
      expect([next.dayOffset, next.weekday], [2, 3]);
      expect(PrayerSchedule.countdown(next), 'Wednesday');

      // Monday only, already passed today: next week.
      next = PrayerSchedule.nextOf(
          alert('a', '06:00:00', days: const [1]), at(0, 7))!;
      expect([next.dayOffset, next.weekday], [7, 1]);
      expect(PrayerSchedule.countdown(next), 'Monday');
    });

    test('only active alerts count, the soonest wins, bad rows are ignored',
        () {
      final soon = alert('soon', '07:00:00');
      final later = alert('later', '09:00:00');
      final off = alert('off', '06:10:00', active: false);
      expect(PrayerSchedule.next([later, off, soon], at(0, 6))!.alert['id'],
          'soon');
      expect(PrayerSchedule.next([off], at(0, 6)), isNull);
      expect(PrayerSchedule.next(const [], at(0, 6)), isNull);
      expect(
          PrayerSchedule.nextOf(
              alert('x', '06:00:00', days: const []), at(0, 5)),
          isNull);
      expect(PrayerSchedule.nextOf(alert('x', '99:80'), at(0, 5)), isNull);
      expect(PrayerSchedule.nextOf({'id': 'x'}, at(0, 5)), isNull);
      // A row with no days_of_week repeats every day.
      expect(
          PrayerSchedule.nextOf(
                  {'local_time': '06:00:00', 'is_active': true}, at(0, 5))!
              .minutesUntil,
          60);
    });

    test('Africa/Lagos alerts are compared in Lagos time (UTC+1)', () {
      final lagos = alert('l', '06:00:00', timezone: 'Africa/Lagos');
      // 05:00 UTC is 06:00 in Lagos.
      expect(PrayerSchedule.nextOf(lagos, at(0, 5))!.minutesUntil, 0);
      expect(PrayerSchedule.nextOf(lagos, at(0, 4, 30))!.minutesUntil, 30);
      // 23:30 UTC Monday is 00:30 Tuesday in Lagos.
      final tuesday =
          alert('l', '06:00:00', timezone: 'Africa/Lagos', days: const [2]);
      final next = PrayerSchedule.nextOf(tuesday, at(0, 23, 30))!;
      expect([next.weekday, next.dayOffset, next.minutesUntil], [2, 0, 330]);
    });

    test('featured prefers the soonest active alert, otherwise the first', () {
      final a = alert('a', '09:00:00', scope: 'global');
      final b = alert('b', '07:00:00', scope: 'global');
      expect(PrayerSchedule.featured([a, b], at(0, 6))!['id'], 'b');
      final c = alert('c', '07:00:00', scope: 'global', active: false);
      final d = alert('d', '08:00:00', scope: 'global', active: false);
      expect(PrayerSchedule.featured([c, d], at(0, 6))!['id'], 'c');
      expect(PrayerSchedule.featured(const [], at(0, 6)), isNull);
    });

    test('day labels and time parts', () {
      expect(
          PrayerSchedule.daysLabel(const [1, 2, 3, 4, 5, 6, 7]), 'Every day');
      expect(PrayerSchedule.daysLabel(const [1, 2, 3, 4, 5]), 'Weekdays');
      expect(PrayerSchedule.daysLabel(const [1, 2, 3, 4, 5], long: true),
          'Monday to Friday');
      expect(PrayerSchedule.daysLabel(const [7, 6]), 'Weekends');
      expect(PrayerSchedule.daysLabel(const [1, 2, 3]), 'Mon to Wed');
      expect(PrayerSchedule.daysLabel(const [1, 3, 5]), 'Mon, Wed, Fri');
      expect(PrayerSchedule.daysLabel(const [1, 3, 5], long: true),
          'Monday, Wednesday and Friday');
      expect(PrayerSchedule.daysLabel(const []), '');
      String t(int h, int m, {bool use24 = false}) =>
          PrayerSchedule.timeText(h, m, use24: use24);
      expect(t(0, 0), '12:00 am');
      expect(t(6, 0), '6:00 am');
      expect(t(12, 30), '12:30 pm');
      expect(t(18, 5), '6:05 pm');
      expect(t(6, 0, use24: true), '06:00');
    });
  });

  group('alerts screen', () {
    testWidgets('the church card exists only when a global alert exists',
        (tester) async {
      await tester.pumpWidget(app(Scaffold(body: content([global, mine]))));
      await tester.pumpAndSettle();
      expect(find.byType(PrayerFeaturedCard), findsOneWidget);
      expect(find.text('Whole church'), findsOneWidget);
      expect(find.text('Pray now'), findsOneWidget);
      // The card comes before the member's own alerts.
      expect(tester.getTopLeft(find.byType(PrayerFeaturedCard)).dy,
          lessThan(tester.getTopLeft(find.byType(PrayerAlertRow)).dy));
      expect(find.text('From your church'), findsNothing);

      await tester.pumpWidget(app(Scaffold(body: content([mine, mineOff]))));
      await tester.pumpAndSettle();
      expect(find.byType(PrayerFeaturedCard), findsNothing);
      expect(find.text('Whole church'), findsNothing);
      expect(find.text('Pray now'), findsNothing);
      expect(find.text('From your church'), findsNothing);
      // With nothing church-wide the screen goes summary, then own alerts.
      expect(tester.getTopLeft(find.text('Next alert')).dy,
          lessThan(tester.getTopLeft(find.text('My alerts')).dy));
      expect(find.byType(PrayerAlertRow), findsNWidgets(2));
    });

    testWidgets(
        'branch alerts and extra global alerts sit under From your church',
        (tester) async {
      final other =
          alert('g2', '18:00:00', scope: 'global', title: 'Evening church');
      await tester.pumpWidget(
          app(Scaffold(body: content([global, other, branch, mine]))));
      await tester.pumpAndSettle();
      expect(find.byType(PrayerFeaturedCard), findsOneWidget);
      expect(find.text('From your church'), findsOneWidget);
      // Two read-only rows (no switch) plus one personal row with a switch.
      expect(find.byType(PrayerAlertRow), findsNWidgets(3));
      expect(find.byType(PrayerReminderSwitch), findsOneWidget);
      expect(
          tester.getTopLeft(find.text('From your church')).dy,
          greaterThan(
              tester.getBottomLeft(find.byType(PrayerFeaturedCard)).dy));
      expect(tester.getTopLeft(find.text('My alerts')).dy,
          greaterThan(tester.getTopLeft(find.text('From your church')).dy));
    });

    testWidgets('the summary shows the next active alert from the clock',
        (tester) async {
      await tester.pumpWidget(
          app(Scaffold(body: content([mine, mineOff], now: at(0, 18, 15)))));
      await tester.pumpAndSettle();
      // 18:15 Monday, next is the Monday 20:30 alert in 2 h 15 min.
      expect(find.text('In 2 h 15 min'), findsOneWidget);
      expect(find.text('Next alert'), findsOneWidget);

      await tester.pumpWidget(app(Scaffold(
          body: content([mineOff, alert('o2', '07:00:00', active: false)]))));
      await tester.pumpAndSettle();
      expect(find.text('No active alerts'), findsOneWidget);
      expect(find.text('In 2 h 15 min'), findsNothing);
    });

    testWidgets('the day strip emphasises only the repeat days',
        (tester) async {
      await tester.pumpWidget(app(Scaffold(body: content([mine]))));
      await tester.pumpAndSettle();
      final texts = tester
          .widgetList<Text>(find.descendant(
              of: find.byType(PrayerDayStrip), matching: find.byType(Text)))
          .toList();
      expect(texts.map((t) => t.data).join(), 'MTWTFSS');
      expect(texts.map((t) => t.style!.fontWeight == FontWeight.w700),
          [true, false, true, false, true, false, false]);
      // No dots or other decoration: letters only.
      expect(
          find.descendant(
              of: find.byType(PrayerDayStrip),
              matching: find.byType(DecoratedBox)),
          findsNothing);
    });

    testWidgets('a row is one semantic unit with a labelled switch',
        (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(app(Scaffold(
          body: content([
        alert('w', '06:00:00', title: 'Morning', days: const [1, 2, 3, 4, 5])
      ]))));
      await tester.pumpAndSettle();
      expect(
          find.bySemanticsLabel(
              'Prayer alert, 6:00 am, Morning, Monday to Friday, on'),
          findsOneWidget);
      expect(find.bySemanticsLabel('Enable Morning reminder'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('empty state offers one clear action', (tester) async {
      var added = 0;
      await tester.pumpWidget(app(Scaffold(
          body: PrayerAlertsContent(
              alerts: const [],
              onRefresh: () async {},
              onTap: (_) {},
              onStart: (_) {},
              onCalendar: (_) {},
              onToggle: (_, __) {},
              onAdd: () => added++,
              onBack: () {}))));
      await tester.pumpAndSettle();
      expect(find.text('No alerts yet'), findsOneWidget);
      expect(find.text('Next alert'), findsNothing);
      expect(find.text('New alert'), findsNothing);
      await tester.tap(find.text('Add your first alert'));
      expect(added, 1);
    });

    testWidgets('fits both themes at 320, 390 and 834 with 1x and 2x text',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final variants = {
        'full': [global, branch, mine, mineOff],
        'own': [mine, mineOff],
        'long': [
          {...global, 'title': 'Church family prayer and thanksgiving service'},
          {...mine, 'title': 'A very long label for my own morning prayer'},
        ],
      };
      for (final brightness in Brightness.values) {
        for (final width in [320.0, 390.0, 834.0]) {
          for (final scale in [1.0, 2.0]) {
            for (final entry in variants.entries) {
              tester.view.physicalSize = Size(width, width == 834 ? 1194 : 844);
              await tester.pumpWidget(app(
                  Scaffold(
                      body: content(entry.value,
                          onEnablePush: entry.key == 'full' ? () {} : null)),
                  brightness: brightness,
                  scale: scale));
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull,
                  reason: '${entry.key} $brightness $width x$scale');
              if (entry.key == 'full' && (scale == 1 || width == 320)) {
                await capture(tester,
                    'list-${brightness.name}-${width.toInt()}-x${scale.toInt()}');
              }
              // Switch and pill keep 48px targets.
              final pill = find.widgetWithText(FilledButton, 'New alert');
              expect(tester.getSize(pill).height, greaterThanOrEqualTo(48));
              expect(
                  tester
                      .getSize(find.byType(PrayerReminderSwitch).first)
                      .height,
                  greaterThanOrEqualTo(48));
              await tester.drag(
                  find.byType(ListView).first, const Offset(0, -2000));
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
              await tester.pumpWidget(const SizedBox());
            }
          }
        }
      }
    });
  });

  group('alerts view', () {
    Widget host(Widget page) => MaterialApp(
        theme: buildMemberTheme(buildWpccTheme()),
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: MemberBackdrop(child: child!)),
        home: Scaffold(body: page));

    PrayerAlertsView view(
            {required Future<List<Map<String, dynamic>>> Function() load,
            required Future<void> Function(String, bool, Map<String, dynamic>)
                save}) =>
        PrayerAlertsView(
          loadAlerts: load,
          setActive: save,
          onTap: (_) async {},
          onStart: (_) {},
          onCalendar: (_) {},
          onAdd: () async {},
          onBack: () {},
        );

    testWidgets('the switch changes at once and keeps the saved value',
        (tester) async {
      final save = Completer<void>();
      final calls = <String>[];
      var loads = 0;
      var saved = false;
      await tester.pumpWidget(host(view(
        load: () async {
          loads++;
          return [alert('o', '05:45:00', active: saved)];
        },
        save: (id, value, current) {
          calls.add('$id:$value');
          return save.future.then((_) => saved = value);
        },
      )));
      await tester.pumpAndSettle();
      PrayerReminderSwitch toggle() =>
          tester.widget(find.byType(PrayerReminderSwitch));
      expect(toggle().value, isFalse);
      await tester.tap(find.byType(PrayerReminderSwitch));
      await tester.pump();
      // Optimistic: on straight away while the save is pending, and locked.
      expect(calls, ['o:true']);
      expect(toggle().value, isTrue);
      expect(toggle().onChanged, isNull);
      expect(find.byType(MemberShimmer), findsNothing);
      save.complete();
      await tester.pumpAndSettle();
      expect(toggle().value, isTrue);
      expect(toggle().onChanged, isNotNull);
      expect(loads, 2);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a refresh that fails after a save keeps the saved value',
        (tester) async {
      var loads = 0;
      await tester.pumpWidget(host(view(
        load: () async {
          if (++loads > 1) throw StateError('offline');
          return [mineOff];
        },
        save: (id, value, current) async {},
      )));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(PrayerReminderSwitch));
      await tester.pumpAndSettle();
      expect(
          tester
              .widget<PrayerReminderSwitch>(find.byType(PrayerReminderSwitch))
              .value,
          isTrue);
      expect(find.text('Unable to load prayer alerts'), findsNothing);
    });

    testWidgets('a failed save puts the switch back and says so',
        (tester) async {
      await tester.pumpWidget(host(view(
        load: () async => [mineOff],
        save: (id, value, current) async => throw StateError('offline'),
      )));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(PrayerReminderSwitch));
      await tester.pumpAndSettle();
      expect(
          tester
              .widget<PrayerReminderSwitch>(find.byType(PrayerReminderSwitch))
              .value,
          isFalse);
      expect(find.text('Unable to update prayer alert. Please try again.'),
          findsOneWidget);
    });

    testWidgets('loading skeleton, then an error with working retry',
        (tester) async {
      final first = Completer<List<Map<String, dynamic>>>();
      var attempts = 0;
      await tester.pumpWidget(host(view(
          load: () {
            attempts++;
            if (attempts == 1) return first.future;
            return Future.value([mine]);
          },
          save: (_, __, ___) async {})));
      await tester.pump();
      expect(find.byType(MemberShimmer), findsOneWidget);
      expect(find.text('Prayer alerts'), findsOneWidget);
      first.completeError(StateError('offline'));
      await tester.pumpAndSettle();
      expect(find.byType(MemberShimmer), findsNothing);
      expect(find.text('Unable to load prayer alerts'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(attempts, 2);
      expect(find.text('Evening prayer'), findsWidgets);
    });
  });

  group('alert editor', () {
    Future<void> pumpEditor(WidgetTester tester,
        {double width = 393,
        double scale = 1,
        Brightness brightness = Brightness.light,
        Map<String, dynamic>? existing}) async {
      tester.view.physicalSize = Size(width, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
          theme: buildMemberTheme(buildWpccTheme(brightness: brightness)),
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(scale),
                  disableAnimations: true),
              child: RepaintBoundary(
                  key: boundary, child: MemberBackdrop(child: child!))),
          home: PrayerAlertEditPage(
              alertId: existing?['id'] as String?, alert: existing)));
      await tester.pumpAndSettle();
    }

    testWidgets('fits every width, both themes and 2x text', (tester) async {
      for (final brightness in Brightness.values) {
        for (final width in [320.0, 360.0, 393.0, 834.0]) {
          for (final scale in [1.0, 2.0]) {
            await pumpEditor(tester,
                width: width, scale: scale, brightness: brightness);
            expect(tester.takeException(), isNull,
                reason: '$brightness $width x$scale');
            expect(find.byType(PrayerDayToggle), findsNWidgets(7));
            for (final toggle in find.byType(PrayerDayToggle).evaluate()) {
              final rect = tester.getRect(find.byWidget(toggle.widget));
              expect(rect.left, greaterThanOrEqualTo(0));
              expect(rect.right, lessThanOrEqualTo(width));
              expect(rect.height, 48);
              expect(rect.width, greaterThanOrEqualTo(width <= 320 ? 42 : 48));
            }
            // Save is anchored below the scrolling form.
            final save =
                tester.getRect(find.widgetWithText(FilledButton, 'Save'));
            expect(save.height, greaterThanOrEqualTo(48));
            expect(save.bottom, lessThanOrEqualTo(852));
            if (scale == 1 && width == 393) {
              await capture(tester, 'editor-${brightness.name}');
            }
            await tester.drag(
                find.byType(ListView).first, const Offset(0, -2000));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox());
          }
        }
      }
    });

    testWidgets('an empty label cannot be saved', (tester) async {
      await pumpEditor(tester);
      await tester.enterText(find.byType(TextField), '   ');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pump();
      expect(find.text('Add a label for this prayer alert.'), findsOneWidget);
      expect(
          tester
              .widget<FilledButton>(find.widgetWithText(FilledButton, 'Save'))
              .onPressed,
          isNotNull);
    });

    testWidgets('clearing every repeat day is flagged and cannot be saved',
        (tester) async {
      await pumpEditor(tester);
      for (final day in [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday'
      ]) {
        await tester.tap(find.bySemanticsLabel(day).first, warnIfMissed: false);
        await tester.pump();
      }
      expect(find.text('Select at least one repeat day.'), findsOneWidget);
      expect(find.text('Choose at least one day'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pump();
      expect(find.text('Select at least one repeat day.'), findsNWidgets(2));
    });

    testWidgets('day toggles select, deselect and report their state',
        (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpEditor(tester, existing: mine);
      PrayerDayToggle toggle(int i) =>
          tester.widget(find.byType(PrayerDayToggle).at(i));
      expect([for (var i = 0; i < 7; i++) toggle(i).selected],
          [true, false, true, false, true, false, false]);
      await tester.tap(find.byType(PrayerDayToggle).at(1));
      await tester.pump();
      expect(toggle(1).selected, isTrue);
      expect(find.text('Mon to Fri'), findsNothing);
      expect(find.text('Mon to Wed, Fri'), findsNothing);
      expect(find.text('Mon, Tue, Wed, Fri'), findsOneWidget);
      await tester.tap(find.byType(PrayerDayToggle).at(1));
      await tester.pump();
      expect(toggle(1).selected, isFalse);
      expect(find.bySemanticsLabel('Monday'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('editing an existing alert keeps its time, label and days',
        (tester) async {
      await pumpEditor(tester, existing: mine);
      expect(find.text('Edit prayer alert'), findsOneWidget);
      expect(find.text('Evening prayer'), findsOneWidget);
      expect(find.textContaining('8:30'), findsOneWidget);
    });
  });

  group('prayer session', () {
    testWidgets('shows a calm countdown with a clear End session action',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      for (final width in [320.0, 390.0, 834.0]) {
        for (final scale in [1.0, 2.0]) {
          tester.view.physicalSize = Size(width, width == 834 ? 1194 : 700);
          await tester.pumpWidget(app(
              PrayerSessionPage(payload: {
                'alert': {...mine, 'title': 'Evening prayer'},
                'session': {'id': 's1', 'target_duration_seconds': 900},
              }),
              scale: scale));
          await tester.pump(const Duration(seconds: 2));
          expect(find.text('Evening prayer'), findsOneWidget);
          expect(find.textContaining('14:5'), findsOneWidget);
          expect(find.text('Countdown · 15 min'), findsOneWidget);
          expect(find.text('No prayer audio attached'), findsOneWidget);
          final end =
              tester.getRect(find.widgetWithText(FilledButton, 'End session'));
          expect(end.height, greaterThanOrEqualTo(48));
          expect(tester.takeException(), isNull,
              reason: 'session $width x$scale');
          if (scale == 1 && width == 390) await capture(tester, 'session');
          await tester.pumpWidget(const SizedBox());
        }
      }
    });
  });
}
