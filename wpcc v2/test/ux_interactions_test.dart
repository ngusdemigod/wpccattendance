import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:wpcc_community/app/app_shell.dart';
import 'package:wpcc_community/core/widgets/animated_search_filter.dart';
import 'package:wpcc_community/features/auth/login_page.dart';
import 'package:wpcc_community/features/give/give_payment_page.dart';
import 'package:wpcc_community/features/prayer/prayer_alert_edit_page.dart';
import 'package:wpcc_community/features/profile/query_page.dart';

void main() {
  testWidgets('blank membership code shows inline validation', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    await tester.tap(find.text('Send sign in link'));
    await tester.pump();

    expect(find.text('Enter your membership code.'), findsOneWidget);
  });

  testWidgets('search and filter controls meet minimum target size',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AnimatedSearchFilter(
          hint: 'Search members',
          onSearch: (_) {},
          filterOptions: const ['All', 'Leaders'],
          selectedFilter: 'All',
          onFilter: (_) {},
        ),
      ),
    ));

    final searchButton = tester.getSize(find.byType(IconButton).first);
    final filterButton = tester.getSize(find.byType(PopupMenuButton<String>));
    expect(searchButton.width, greaterThanOrEqualTo(48));
    expect(searchButton.height, greaterThanOrEqualTo(48));
    expect(filterButton.width, greaterThanOrEqualTo(48));
    expect(filterButton.height, greaterThanOrEqualTo(48));
  });

  testWidgets(
      'bottom navigation exposes selected semantics and readable labels',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, __) => const AppShell(child: SizedBox()),
        ),
      ],
    );
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Home').first)
          .flagsCollection
          .isSelected,
      Tristate.isTrue,
    );
    final label = tester.widget<Text>(find.text('Home'));
    expect(label.style?.fontSize, greaterThanOrEqualTo(12));
    semantics.dispose();
  });

  testWidgets('give payment remains scrollable on a short viewport',
      (tester) async {
    tester.view.physicalSize = const Size(393, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(
      home: GivePaymentPage(payload: {'title': 'Give'}),
    ));

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('query validation identifies each invalid field', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: QueryPage()));

    await tester.tap(find.text('Submit query'));
    await tester.pump();

    expect(find.text('Enter a subject with at least 3 characters.'),
        findsOneWidget);
    expect(find.text('Add at least 10 characters of detail.'), findsOneWidget);
  });

  testWidgets('prayer time control exposes button name and value',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(const MaterialApp(home: PrayerAlertEditPage()));

    final node = tester.getSemantics(
      find.bySemanticsLabel('Prayer alert time').first,
    );
    expect(node.flagsCollection.isButton, isTrue);
    expect(node.value, isNotEmpty);
    semantics.dispose();
  });
}
