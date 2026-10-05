import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:wpcc_community/core/theme/app_theme.dart';
import 'package:wpcc_community/core/theme/member_theme.dart';
import 'package:wpcc_community/features/give/give_home_page.dart';
import 'package:wpcc_community/features/give/giving_history_page.dart';

const accounts = [
  {
    'account_number': '1234567890',
    'bank_name': 'Church bank',
    'purpose': 'General giving',
    'account_name': 'Wisdom Power Christian Centre'
  },
  {
    'account_number': '9876543210',
    'bank_name': 'Second bank',
    'purpose': 'Church account',
    'account_name': 'WPCC Community'
  },
];
const projects = [
  {
    'id': 'project-one',
    'title': 'Church building',
    'description': 'Support our church building.',
    'target_amount_kobo': 1000000
  },
  {
    'id': 'project-two',
    'title': 'Community outreach',
    'description': 'Serve together'
  },
];

GiveHomePage page({bool initialHistory = false}) => GiveHomePage(
    initialHistory: initialHistory,
    loadAccounts: () async => accounts,
    loadMandates: () async => [],
    loadProjects: () async => projects,
    loadHistory: ({required limit, required offset}) async => []);

void main() {
  testWidgets('scheduled cards and grouped history fit enlarged phone text',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      theme: buildMemberTheme(buildWpccTheme()),
      home: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: Scaffold(
            body: GiveHomePage(
          loadAccounts: () async => accounts,
          loadProjects: () async => projects,
          loadMandates: () async => [
            {
              'giving_type': 'prophet_offering',
              'amount_kobo': 25000,
              'status': 'active',
              'rule_keys': ['weekday:4']
            }
          ],
          loadHistory: ({required limit, required offset}) async => [
            {
              'giving_type': 'offering',
              'amount_kobo': 500000,
              'status': 'pending',
              'created_at': '2026-10-04T10:00:00Z'
            },
            {
              'giving_type': 'tithe',
              'amount_kobo': 25000,
              'status': 'successful',
              'created_at': '2026-09-24T10:00:00Z'
            },
          ],
        )),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Scheduled'));
    await tester.pumpAndSettle();
    expect(find.text('Thursday'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.text('October 2026'), findsOneWidget);
    expect(find.text('September 2026'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  for (final brightness in Brightness.values) {
    for (final size in [
      const Size(320, 844),
      const Size(390, 844),
      const Size(834, 1194)
    ]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('giving adapts at $size / $scale / $brightness',
            (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(MaterialApp(
              theme: buildMemberTheme(buildWpccTheme(brightness: brightness)),
              home: MediaQuery(
                  data: MediaQueryData(
                      size: size,
                      textScaler: TextScaler.linear(scale),
                      disableAnimations: true),
                  child: Scaffold(body: page()))));
          await tester.pumpAndSettle();
          expect(find.text('Give now'), findsOneWidget);
          expect(find.text('Giving'), findsOneWidget);
          await tester.tap(find.text('Scheduled'));
          await tester.pumpAndSettle();
          expect(find.text('No scheduled gifts'), findsOneWidget);
          expect(find.text('Give now'), findsNothing);
          expect(tester.takeException(), isNull);
          await tester.tap(find.text('Give'));
          await tester.pumpAndSettle();
          expect(find.text('1234567890'), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.scrollUntilVisible(find.text('Church building'), 250,
              scrollable: find
                  .descendant(
                      of: find.byType(ListView).first,
                      matching: find.byType(Scrollable))
                  .first);
          expect(tester.takeException(), isNull);
          await tester.tap(find.text('History'));
          await tester.pumpAndSettle();
          expect(find.text('No giving transactions yet'), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  testWidgets('purposes, projects, copying and schedules preserve contracts',
      (tester) async {
    Object? payment;
    String? copied;
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copied = (call.arguments as Map)['text'] as String;
      }
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));
    final router = GoRouter(initialLocation: '/give', routes: [
      GoRoute(path: '/give', builder: (_, __) => Scaffold(body: page())),
      GoRoute(
          path: '/give/payment',
          builder: (_, state) {
            payment = state.extra;
            return const Scaffold(body: Text('Payment'));
          }),
      GoRoute(
          path: '/give/auto',
          builder: (_, __) => const Scaffold(body: Text('Schedules'))),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Copy account number').first);
    await tester.pump();
    expect(copied, '1234567890');
    await tester.tap(find.text('Give now'));
    await tester.pumpAndSettle();
    expect(payment, {'giving_type': 'offering', 'title': 'Offering'});
    router.pop();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Church building'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Church building'));
    await tester.pumpAndSettle();
    expect(payment, {
      'giving_type': 'project',
      'project_id': 'project-one',
      'title': 'Church building'
    });
    router.pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Scheduled'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Manage scheduled givings'));
    await tester.tap(find.byTooltip('Manage scheduled givings'));
    await tester.pumpAndSettle();
    expect(find.text('Schedules'), findsOneWidget);
  });

  testWidgets('project error does not block giving; retry recovers',
      (tester) async {
    var attempts = 0;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: GiveHomePage(
                loadAccounts: () async => accounts,
                loadMandates: () async => [],
                loadProjects: () async {
                  if (++attempts == 1) throw StateError('offline');
                  return projects;
                }))));
    await tester.pumpAndSettle();
    expect(find.text('Give now'), findsOneWidget);
    await tester.scrollUntilVisible(
        find.text('Unable to load church projects'), 200,
        scrollable: find
            .descendant(
                of: find.byType(ListView).first,
                matching: find.byType(Scrollable))
            .first);
    await tester.ensureVisible(find.text('Retry'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Church building'), findsOneWidget);
  });

  testWidgets('accounts carousel remains swipeable', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: page())));
    await tester.pumpAndSettle();
    await tester.drag(find.byKey(const PageStorageKey('giving-accounts')),
        const Offset(-310, 0));
    await tester.pumpAndSettle();
    expect(find.text('9876543210').hitTestable(), findsOneWidget);
  });

  testWidgets('initial history loads lazily and preserves Give selection',
      (tester) async {
    var calls = 0;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: GiveHomePage(
                loadAccounts: () async => accounts,
                loadMandates: () async => [],
                loadProjects: () async => projects,
                loadHistory: ({required limit, required offset}) async {
                  calls++;
                  return [];
                }))));
    await tester.pumpAndSettle();
    expect(calls, 0);
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(calls, 1);
    await tester.tap(find.text('Give'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(calls, 1);
  });

  testWidgets('direct history entry selects History', (tester) async {
    await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: page(initialHistory: true))));
    await tester.pumpAndSettle();
    expect(find.text('No giving transactions yet'), findsOneWidget);
    expect(find.text('Give now'), findsNothing);
  });

  testWidgets('history keeps pagination and receipt actions', (tester) async {
    final offsets = <int>[];
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: GiveHomePage(
                initialHistory: true,
                loadAccounts: () async => accounts,
                loadMandates: () async => [],
                loadProjects: () async => projects,
                loadHistory: ({required limit, required offset}) async {
                  offsets.add(offset);
                  return List.generate(
                      offset == 0 ? 25 : 1,
                      (index) => {
                            'giving_type': 'offering',
                            'status': 'successful',
                            'amount_kobo': 100000,
                            'internal_reference': 'ref-${offset + index}',
                            'created_at': '2026-10-01T10:00:00Z',
                          });
                }))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Offering').first);
    await tester.pumpAndSettle();
    expect(find.text('Giving receipt'), findsOneWidget);
    expect(find.text('PDF'), findsOneWidget);
    expect(find.text('Image'), findsOneWidget);
    Navigator.of(tester.element(find.text('Giving receipt'))).pop();
    await tester.pumpAndSettle();
    await tester.drag(find.byKey(const PageStorageKey('giving-history-scroll')),
        const Offset(0, -2200));
    await tester.pumpAndSettle();
    expect(offsets, containsAllInOrder([0, 25]));
    expect(tester.takeException(), isNull);
  });

  testWidgets('overview retains projects without duplicate giving type choices',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: page())));
    await tester.pumpAndSettle();
    expect(find.text('Projects'), findsNothing);
    expect(find.text('Tithe'), findsNothing);
    expect(find.text('Prophet offering'), findsNothing);
    await tester.ensureVisible(find.text('Church building'));
    await tester.pumpAndSettle();
    expect(find.text('Church building').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('refresh discards an older in-flight history page',
      (tester) async {
    final pendingPage = Completer<List<Map<String, dynamic>>>();
    var firstPageCalls = 0;
    var moreCalls = 0;
    await tester.pumpWidget(MaterialApp(
        home: GivingHistoryPage(
            embedded: true,
            loadHistory: ({required limit, required offset}) async {
              if (offset != 0) {
                moreCalls++;
                return pendingPage.future;
              }
              if (++firstPageCalls > 1) {
                return [
                  {
                    'giving_type': 'tithe',
                    'status': 'successful',
                    'amount_kobo': 200000
                  }
                ];
              }
              return List.generate(
                  25,
                  (_) => {
                        'giving_type': 'offering',
                        'status': 'successful',
                        'amount_kobo': 100000
                      });
            })));
    await tester.pumpAndSettle();
    await tester.drag(find.byKey(const PageStorageKey('giving-history-scroll')),
        const Offset(0, -2200));
    await tester.pump();
    expect(moreCalls, 1);
    await tester
        .widget<RefreshIndicator>(find.byType(RefreshIndicator))
        .onRefresh();
    await tester.pump();
    pendingPage.complete([
      {
        'giving_type': 'stale_project',
        'status': 'successful',
        'amount_kobo': 900000
      }
    ]);
    await tester.pumpAndSettle();
    expect(find.text('Tithe'), findsOneWidget);
    expect(find.text('Stale Project'), findsNothing);
    expect(find.text('Offering'), findsNothing);
    expect(moreCalls, 1);
    expect(tester.takeException(), isNull);
  });
}
