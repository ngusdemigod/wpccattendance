import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wpcc_community/app/app_shell.dart';
import 'package:wpcc_community/core/widgets/animated_search_filter.dart';
import 'package:wpcc_community/features/auth/login_page.dart';
import 'package:wpcc_community/features/give/give_payment_page.dart';
import 'package:wpcc_community/features/prayer/prayer_alert_edit_page.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues(const {});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-publishable-key',
    );
  });

  tearDownAll(() async {
    await Supabase.instance.dispose();
  });

  testWidgets('blank membership code cannot be submitted', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    await tester.pump(const Duration(milliseconds: 700));

    await tester.tap(find.text('Sign in with membership code'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    final continueButton = find.widgetWithText(FilledButton, 'Continue');
    expect(tester.widget<FilledButton>(continueButton).onPressed, isNull);
    await tester.pumpWidget(const SizedBox());
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

  testWidgets('navigation exposes labels, selected semantics and tooltips',
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
    expect(find.text('Home'),
        findsNothing); // Icon-only dock retains its semantic label.
    expect(find.byTooltip('Home'), findsOneWidget);
    expect(find.bySemanticsLabel('Media'), findsOneWidget);
    expect(find.bySemanticsLabel('Department'), findsNothing);
    semantics.dispose();
  });

  testWidgets('all tabs remain reachable with large text on a small phone',
      (tester) async {
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const paths = ['/home', '/media', '/events', '/give', '/profile'];
    const labels = ['Home', 'Media', 'Events', 'Give', 'Profile'];
    final router = GoRouter(initialLocation: '/home', routes: [
      for (final path in paths)
        GoRoute(
            path: path,
            builder: (_, __) =>
                AppShell(child: Center(child: Text('Screen $path')))),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(
      routerConfig: router,
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!),
    ));
    for (var i = 0; i < paths.length; i++) {
      await tester.tap(find.byTooltip(labels[i]));
      await tester.pumpAndSettle();
      expect(find.text('Screen ${paths[i]}'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('give payment remains scrollable on a short viewport',
      (tester) async {
    tester.view.physicalSize = const Size(393, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      home: GivePaymentPage(
        payload: {'title': 'Give'},
        eventLoader: () async => {'upcoming': [], 'recurring': []},
      ),
    ));

    expect(find.byType(CustomScrollView), findsOneWidget);
    expect(find.text('Auto give'), findsOneWidget);
    expect(find.text('Set up Auto Give'), findsNothing);
    await tester.tap(find.text('Auto give'));
    await tester.pump(const Duration(milliseconds: 220));
    expect(find.text('Mon'), findsOneWidget);
    expect(find.text('Sun'), findsOneWidget);
    expect(find.text('Service days'), findsOneWidget);
    expect(find.text('Charge time'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final size in [const Size(390, 844), const Size(834, 1194)]) {
    testWidgets('giving keypad and schedule at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
        home: GivePaymentPage(
          payload: {'title': 'Offering'},
          eventLoader: () async => {'upcoming': [], 'recurring': []},
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNull);
      await tester.tap(find.text('1'));
      await tester.tap(find.text('00'));
      await tester.pump();
      expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNotNull);
      await tester.tap(find.bySemanticsLabel('Delete last digit'));
      await tester.pump();
      expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNull);
      await tester.tap(find.text('Auto give'));
      await tester.pumpAndSettle();
      expect(find.text('Service days'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

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
