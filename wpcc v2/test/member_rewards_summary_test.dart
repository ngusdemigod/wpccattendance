import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wpcc_community/core/theme/app_theme.dart';
import 'package:wpcc_community/core/theme/member_theme.dart';
import 'package:wpcc_community/core/widgets/member_components.dart';
import 'package:wpcc_community/features/rewards/rewards_card.dart';

Map<String, dynamic> summary(
        {int balance = 0,
        int pending = 0,
        List<Map<String, dynamic>> history = const []}) =>
    {'balance': balance, 'pending': pending, 'history': history};

Widget app(Widget child, {Brightness brightness = Brightness.dark}) =>
    MaterialApp(
      theme: buildWpccTheme(brightness: brightness),
      home: MemberTheme(
          child: Scaffold(
              body: SingleChildScrollView(
                  padding: const EdgeInsets.all(20), child: child))),
    );

void main() {
  testWidgets('compact balance waits for the actual private summary',
      (tester) async {
    final result = Completer<Map<String, dynamic>>();
    await tester.pumpWidget(
        app(RewardsCard(compact: true, loadSummary: () => result.future)));
    await tester.pump();
    expect(find.text('Loading points'), findsOneWidget);
    expect(find.textContaining('15 WP'), findsNothing);
    expect(
        tester.widget<MemberListRow>(find.byType(MemberListRow)).onTap, isNull);
    result.complete(summary(balance: 37));
    await tester.pumpAndSettle();
    expect(find.text('37 WP'), findsOneWidget);
    expect(find.textContaining('confirmed'), findsNothing);
    expect(tester.widget<MemberListRow>(find.byType(MemberListRow)).onTap,
        isNotNull);
  });

  testWidgets('unavailable summary retries without a fabricated balance',
      (tester) async {
    var calls = 0;
    await tester.pumpWidget(app(RewardsCard(
        compact: true,
        loadSummary: () async {
          if (calls++ == 0) throw StateError('offline');
          return summary(balance: 0);
        })));
    await tester.pumpAndSettle();
    expect(find.text('Temporarily unavailable'), findsOneWidget);
    expect(find.text('0 WP'), findsNothing);
    expect(tester.getSize(find.byTooltip('Retry points')), const Size(48, 48));
    await tester.tap(find.byTooltip('Retry points'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('0 WP'), findsOneWidget);
  });

  testWidgets('history shares one ledger summary and refresh owner',
      (tester) async {
    var calls = 0;
    await tester.pumpWidget(app(RewardsCard(
        compact: true,
        loadSummary: () async {
          calls++;
          return summary(balance: calls == 1 ? 15 : 20, history: const [
            {
              'kind': 'profile',
              'delta': 15,
              'created_at': '2026-10-01T08:00:00Z'
            },
          ]);
        })));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Wisdom Points'));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(find.byType(RewardsCard), findsOneWidget);
    await tester.tap(find.text('Your points history'));
    await tester.pumpAndSettle();
    expect(find.text('Profile completion'), findsOneWidget);
    expect(find.text('+15 WP'), findsOneWidget);
    await tester.tap(find.byTooltip('Refresh points'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('+5 WP confirmed'), findsOneWidget);
    expect(find.text('20 WP'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('pending confirmation remains truthful across responsive themes',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final brightness in Brightness.values) {
      for (final size in [
        const Size(390, 844),
        const Size(834, 1194),
        const Size(320, 640)
      ]) {
        tester.view.physicalSize = size;
        await tester.pumpWidget(app(
            RewardsCard(
                key: UniqueKey(),
                compact: true,
                loadSummary: () async => summary(balance: 0, pending: 1)),
            brightness: brightness));
        await tester.pumpAndSettle();
        expect(find.text('Awaiting confirmation'), findsOneWidget);
        expect(find.text('0 WP'), findsOneWidget);
        expect(find.textContaining('+15'), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      }
    }
  });

  testWidgets('default presentation keeps expanded history and refresh',
      (tester) async {
    await tester
        .pumpWidget(app(RewardsCard(loadSummary: () async => summary())));
    await tester.pumpAndSettle();
    expect(find.byType(MemberListRow), findsNothing);
    expect(find.text('Your points history'), findsOneWidget);
    expect(find.byTooltip('Refresh points'), findsOneWidget);
    await tester.tap(find.text('Your points history'));
    await tester.pumpAndSettle();
    expect(find.text('No points awarded yet'), findsOneWidget);
  });
}
