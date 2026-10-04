import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:wpcc_community/core/theme/app_motion.dart';
import 'package:wpcc_community/core/theme/app_theme.dart';
import 'package:wpcc_community/core/widgets/member_glass.dart';
import 'package:wpcc_community/features/give/give_payment_page.dart';
import 'package:wpcc_community/features/give/give_repository.dart';
import 'package:wpcc_community/features/give/giving_backdrop.dart';

const payload = <String, dynamic>{
  'title': 'Church building project',
  'giving_type': 'project',
  'project_id': 'project-1',
};
const eventRows = <String, List<Map<String, dynamic>>>{
  'recurring': [
    {
      'recurring_event_id': 'weekly',
      'title': 'Sunday celebration',
      'recurrence_type': 'weekly',
      'day_of_week': 7,
      'start_time': '09:00:00'
    },
    {
      'recurring_event_id': 'monthly',
      'title': 'Monthly prayer',
      'recurrence_type': 'monthly',
      'day_of_month': 15,
      'start_time': '18:00:00'
    },
    {
      'recurring_event_id': 'yearly',
      'title': 'Christmas service',
      'recurrence_type': 'yearly',
      'month': 12,
      'day_of_month': 25,
      'start_time': '09:00:00'
    },
  ],
  'upcoming': [
    {
      'event_id': 'upcoming',
      'title': 'Community service',
      'event_start_at': '2026-10-11T09:00:00Z'
    },
    {'event_id': 'undated', 'title': 'Undated service'},
  ],
};

class RecordingGivingRepository implements GiveRepository {
  final calls = <Map<String, dynamic>>[];
  Completer<Map<String, dynamic>>? pending;
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected repository use: ${invocation.memberName}');
  @override
  Future<Map<String, dynamic>> initialize({
    required int amountKobo,
    required String givingType,
    String? projectId,
    Map<String, dynamic>? autoGive,
    String? appOrigin,
  }) async {
    calls.add({
      'amount_kobo': amountKobo,
      'giving_type': givingType,
      'project_id': projectId,
      'auto_give': autoGive,
      'app_origin': appOrigin
    });
    if (pending != null) return pending!.future;
    throw StateError('Checkout intercepted by test');
  }
}

Widget app(
  RecordingGivingRepository repo, {
  Brightness brightness = Brightness.light,
  double scale = 1,
  bool reduced = true,
  Future<Map<String, List<Map<String, dynamic>>>> Function()? events,
}) =>
    MaterialApp(
      theme: buildWpccTheme(brightness: brightness),
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale), disableAnimations: reduced),
          child: child!),
      home: GivePaymentPage(
          key: UniqueKey(),
          payload: payload,
          repository: repo,
          eventLoader: events ?? () async => eventRows),
    );

Future<void> tapVisible(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

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
      'open keypad and Auto give fit both themes responsive and accessible sizes',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final repo = RecordingGivingRepository();
    for (final brightness in Brightness.values) {
      for (final size in [
        const Size(320, 600),
        const Size(393, 480),
        const Size(390, 844),
        const Size(834, 1194)
      ]) {
        for (final scale in [1.0, 1.6, 2.0]) {
          tester.view.physicalSize = size;
          await tester
              .pumpWidget(app(repo, brightness: brightness, scale: scale));
          await tester.pumpAndSettle();
          expect(find.byType(GivingBackdrop), findsOneWidget);
          expect(find.byType(CustomScrollView), findsOneWidget);
          expect(find.byType(MemberGlass), findsNothing);
          expect(
              tester
                  .widget<Text>(find.byKey(const ValueKey('giving-amount')))
                  .style!
                  .fontSize,
              48);
          expect(tester.takeException(), isNull,
              reason: '$brightness/$size/$scale One-time');
          await tapVisible(tester, find.text('Auto give'));
          expect(find.byType(MemberGlass), findsOneWidget);
          expect(find.text('Mon'), findsOneWidget);
          expect(find.text('Sun'), findsOneWidget);
          expect(find.text('Service days'), findsOneWidget);
          expect(find.text('Charge time'), findsOneWidget);
          await tester.drag(
              find.byType(CustomScrollView), const Offset(0, -3000));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull,
              reason: '$brightness/$size/$scale Auto give');
        }
      }
    }
    expect(repo.calls, isEmpty);
  });

  testWidgets(
      'presets replace digits while keypad deletion and minimum stay unchanged',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final repo = RecordingGivingRepository();
    await tester.pumpWidget(app(repo));
    await tester.pumpAndSettle();
    final button = find.widgetWithText(FilledButton, 'Continue');
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
    await tester.tap(find.text('1'));
    await tester.tap(find.text('00'));
    await tester.pumpAndSettle();
    expect(find.text('₦100.00'), findsOneWidget);
    expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
    await tester.tap(find.bySemanticsLabel('Delete last digit'));
    await tester.pumpAndSettle();
    expect(find.text('₦10.00'), findsOneWidget);
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
    for (final value in ['1,000', '5,000', '10,000', '20,000']) {
      await tester.tap(find.text('₦$value'));
      await tester.pumpAndSettle();
      expect(find.text('₦$value.00'), findsOneWidget);
    }
    await tester.tap(find.text('2'));
    await tester.pumpAndSettle();
    expect(find.text('₦200,002.00'), findsOneWidget);
    expect(repo.calls, isEmpty);
  });

  testWidgets(
      'One-time checkout keeps purpose amount project and no recurring payload',
      (tester) async {
    final repo = RecordingGivingRepository();
    await tester.pumpWidget(app(repo));
    await tester.pumpAndSettle();
    await tester.tap(find.text('₦5,000'));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Continue'));
    expect(repo.calls, [
      {
        'amount_kobo': 500000,
        'giving_type': 'project',
        'project_id': 'project-1',
        'auto_give': null,
        'app_origin': null
      }
    ]);
    expect(find.text('Checkout intercepted by test'), findsOneWidget);
  });

  testWidgets(
      'Auto give validates and preserves every real service rule time and label',
      (tester) async {
    final repo = RecordingGivingRepository();
    await tester.pumpWidget(app(repo));
    await tester.pumpAndSettle();
    await tester.tap(find.text('₦1,000'));
    await tapVisible(tester, find.text('Auto give'));
    await tapVisible(tester, find.text('Continue'));
    expect(repo.calls, isEmpty);
    expect(find.text('Choose at least one day or service'), findsOneWidget);
    await tapVisible(tester, find.text('Mon'));
    await tapVisible(tester, find.text('Service days'));
    for (final title in [
      'Sunday celebration',
      'Monthly prayer',
      'Christmas service',
      'Community service'
    ]) {
      await tapVisible(tester, find.text(title));
    }
    expect(
        tester
            .widget<CheckboxListTile>(
                find.widgetWithText(CheckboxListTile, 'Undated service'))
            .onChanged,
        isNull);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('4 selected'), findsOneWidget);
    await tapVisible(tester, find.text('Charge time'));
    expect(
        tester
            .widget<TimePickerDialog>(find.byType(TimePickerDialog))
            .initialTime,
        const TimeOfDay(hour: 8, minute: 0));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('One-time'));
    await tapVisible(tester, find.text('Auto give'));
    expect(find.text('4 selected'), findsOneWidget);
    await tapVisible(tester, find.text('Continue'));
    expect(repo.calls.single['auto_give'], {
      'rule_keys': [
        'weekday:1',
        'weekday:7:weekly',
        'monthly:15:monthly',
        'yearly:12:25:yearly',
        'event:2026-10-11:upcoming'
      ],
      'local_charge_time': '08:00:00',
      'timezone': 'Africa/Lagos',
      'event_labels': {
        'weekday:7:weekly': 'Sunday celebration',
        'monthly:15:monthly': 'Monthly prayer',
        'yearly:12:25:yearly': 'Christmas service',
        'event:2026-10-11:upcoming': 'Community service'
      },
    });
    expect(repo.calls.single['amount_kobo'], 100000);
    expect(repo.calls.single['project_id'], 'project-1');
  });

  testWidgets(
      'service sheet keeps pending error and empty states without fabricated choices',
      (tester) async {
    final repo = RecordingGivingRepository();
    for (final fail in [false, true]) {
      final pending = Completer<Map<String, List<Map<String, dynamic>>>>();
      await tester.pumpWidget(app(repo, events: () => pending.future));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Auto give'));
      await tester.ensureVisible(find.text('Service days'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Service days'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      if (fail) {
        pending.completeError(StateError('offline'));
      } else {
        pending.complete({'upcoming': [], 'recurring': []});
      }
      await tester.pumpAndSettle();
      expect(
          find.text(
              fail ? 'Unable to load service days' : 'No upcoming services'),
          findsOneWidget);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
    }
    expect(repo.calls, isEmpty);
  });

  testWidgets(
      'early service loading failure remains available when picker opens',
      (tester) async {
    final repo = RecordingGivingRepository();
    await tester.pumpWidget(
        app(repo, events: () => Future.error(StateError('Services offline'))));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Service days'), findsNothing);
    await tapVisible(tester, find.text('Auto give'));
    await tapVisible(tester, find.text('Service days'));
    expect(find.text('Unable to load service days'), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(repo.calls, isEmpty);
  });

  testWidgets('synchronous duplicate submission initializes only once',
      (tester) async {
    final repo = RecordingGivingRepository()
      ..pending = Completer<Map<String, dynamic>>();
    await tester.pumpWidget(app(repo));
    await tester.pumpAndSettle();
    await tester.tap(find.text('₦1,000'));
    await tester.pumpAndSettle();
    final submit = tester
        .widget<FilledButton>(find.widgetWithText(FilledButton, 'Continue'))
        .onPressed!;
    submit();
    submit();
    expect(repo.calls, hasLength(1));
    await tester.pump();
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull);
    repo.pending!.completeError(StateError('Checkout intercepted by test'));
    await tester.pumpAndSettle();
    expect(find.text('Checkout intercepted by test'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('closing pending checkout prevents later authorization handoff',
      (tester) async {
    const launcher = MethodChannel('plugins.flutter.io/url_launcher');
    final handoffs = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(launcher,
        (call) async {
      handoffs.add(call);
      return true;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(launcher, null));
    final repo = RecordingGivingRepository()
      ..pending = Completer<Map<String, dynamic>>();
    await tester.pumpWidget(app(repo));
    await tester.pumpAndSettle();
    await tester.tap(find.text('₦1,000'));
    await tester.pumpAndSettle();
    tester
        .widget<FilledButton>(find.widgetWithText(FilledButton, 'Continue'))
        .onPressed!();
    repo.pending!
        .complete({'authorization_url': 'https://fixture.invalid/checkout'});
    await tester.pumpAndSettle();
    expect(handoffs.single.method, 'launch');
    handoffs.clear();
    repo.pending = Completer<Map<String, dynamic>>();
    await tester.pumpWidget(app(repo));
    await tester.pumpAndSettle();
    await tester.tap(find.text('₦1,000'));
    await tester.pumpAndSettle();
    tester
        .widget<FilledButton>(find.widgetWithText(FilledButton, 'Continue'))
        .onPressed!();
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    repo.pending!
        .complete({'authorization_url': 'https://fixture.invalid/checkout'});
    await tester.pumpAndSettle();
    expect(repo.calls, hasLength(2));
    expect(handoffs, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mode disclosure respects shared motion and reduced motion',
      (tester) async {
    final repo = RecordingGivingRepository();
    for (final reduced in [false, true]) {
      await tester.pumpWidget(app(repo, reduced: reduced));
      await tester.pumpAndSettle();
      if (reduced) {
        expect(find.byType(AnimatedSize), findsNothing);
      } else {
        final animation =
            tester.widget<AnimatedSize>(find.byType(AnimatedSize));
        expect(animation.duration, AppMotion.control);
        expect(animation.curve, AppMotion.curve);
      }
      await tapVisible(tester, find.text('Auto give'));
      expect(find.text('Repeat days'), findsOneWidget);
      await tapVisible(tester, find.text('One-time'));
      expect(find.text('Repeat days'), findsNothing);
    }
  });

  testWidgets('close amount screen goes back to Give', (tester) async {
    final repo = RecordingGivingRepository();
    final router = GoRouter(initialLocation: '/give/pay', routes: [
      GoRoute(
          path: '/give/pay',
          builder: (_, __) => GivePaymentPage(
              payload: payload,
              repository: repo,
              eventLoader: () async => eventRows)),
      GoRoute(
          path: '/give',
          builder: (_, __) => const Scaffold(body: Text('Giving hub'))),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(
        MaterialApp.router(theme: buildWpccTheme(), routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back to Give'));
    await tester.pumpAndSettle();
    expect(find.text('Giving hub'), findsOneWidget);
    expect(repo.calls, isEmpty);
  });
}
