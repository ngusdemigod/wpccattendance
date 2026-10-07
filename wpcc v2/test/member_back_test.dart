import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wpcc_community/app/app_shell.dart';
import 'package:wpcc_community/core/theme/app_theme.dart';
import 'package:wpcc_community/core/theme/member_theme.dart';
import 'package:wpcc_community/core/widgets/member_back.dart';
import 'package:wpcc_community/core/widgets/member_components.dart';
import 'package:wpcc_community/core/widgets/member_sheet.dart';

Widget _page(String path, {List<Widget> actions = const []}) => Scaffold(
        body: SafeArea(
            child: ListView(padding: const EdgeInsets.all(20), children: [
      MemberPageHeader(title: 'Detail', onBack: () {}, actions: actions),
      for (var i = 0; i < 40; i++) Text('Row $i'),
    ])));

GoRouter _router(String initial, {VoidCallback? onOverride}) => GoRouter(
        initialLocation: initial,
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const Text('home page')),
          GoRoute(path: '/events', builder: (_, __) => const Text('events page')),
          GoRoute(
              path: '/events/:id',
              pageBuilder: (_, state) => MaterialPage(
                  child: MemberTheme(
                      child: MemberBackHost(
                          path: state.uri.path,
                          child: MemberBackOverride(
                              onBack: onOverride,
                              child: _page(state.uri.path, actions: [
                                MemberIconButton(
                                    icon: Icons.ios_share,
                                    label: 'Share',
                                    onPressed: () {})
                              ])))))),
        ]);

Future<void> _pump(WidgetTester tester, GoRouter router,
    {Brightness brightness = Brightness.light, Size size = const Size(390, 844)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp.router(
      routerConfig: router, theme: buildWpccTheme(brightness: brightness)));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await (FontLoader('DM Sans')
          ..addFont(rootBundle.load('assets/DMSans-Regular.ttf')))
        .load();
  });

  testWidgets('one sticky Back sits top left and survives scrolling',
      (tester) async {
    final router = _router('/home');
    await _pump(tester, router);
    router.push('/events/1');
    await tester.pumpAndSettle();
    final back = find.byTooltip('Back');
    expect(back, findsOneWidget);
    final box = tester.getRect(back);
    expect(box.width, greaterThanOrEqualTo(48));
    expect(box.height, greaterThanOrEqualTo(48));
    expect(box.left, closeTo(20, .5));
    expect(box.top, closeTo(20, .5));
    // The in-page header draws no second back control: its title starts after
    // the sticky button and its Share action stays on the right.
    expect(tester.getRect(find.text('Detail')).left,
        greaterThanOrEqualTo(box.right));
    expect(tester.getRect(find.byTooltip('Share')).left,
        greaterThan(box.right));
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(tester.getRect(back), box);
    await tester.tap(back);
    await tester.pumpAndSettle();
    expect(find.text('home page'), findsOneWidget);
  });

  testWidgets('Back falls back to the parent route on a deep link',
      (tester) async {
    final router = _router('/events/1');
    await _pump(tester, router, brightness: Brightness.dark);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('events page'), findsOneWidget);
  });

  testWidgets('a page can take over Back and clear nothing else',
      (tester) async {
    var taken = 0;
    final router = _router('/events/1', onOverride: () => taken++);
    await _pump(tester, router);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(taken, 1);
    expect(find.text('Detail'), findsOneWidget);
  });

  testWidgets('without a host the header keeps one inline Back',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        theme: buildWpccTheme(),
        home: MemberTheme(child: _page('/events/1'))));
    expect(find.byTooltip('Back'), findsOneWidget);
    expect(tester.getRect(find.byTooltip('Back')).left, lessThan(60));
  });

  test('parent routes', () {
    expect(MemberBackRule.of('/media/albums/1').fallback, '/media');
    expect(MemberBackRule.of('/departments/9').fallback, '/departments');
    expect(MemberBackRule.of('/departments/9/requests').fallback,
        '/departments/9');
    expect(MemberBackRule.of('/give/result').forceGo, isTrue);
    expect(MemberBackRule.of('/give/payment').forceGo, isFalse);
    expect(MemberBackRule.of('/search').fallback, '/home');
  });

  testWidgets('dock indicator is a flat circle in both themes',
      (tester) async {
    for (final brightness in Brightness.values) {
      final router = GoRouter(initialLocation: '/home', routes: [
        ShellRoute(
            builder: (_, __, child) =>
                MemberTheme(child: AppShell(child: child)),
            routes: [
              GoRoute(path: '/home', builder: (_, __) => const SizedBox()),
            ]),
      ]);
      await tester.pumpWidget(MaterialApp.router(
          routerConfig: router, theme: buildWpccTheme(brightness: brightness)));
      await tester.pumpAndSettle();
      // The active marker is the flat selected colour of the member theme.
      final pill = tester.widget<Container>(
          find.byKey(const ValueKey('dock-selection')));
      expect((pill.decoration as BoxDecoration).gradient, isNull);
      expect((pill.decoration as BoxDecoration).color, isNotNull);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
    }
  });

  testWidgets('member sheets slide up and out, and are instant when reduced',
      (tester) async {
    for (final reduced in [false, true]) {
      await tester.pumpWidget(MaterialApp(
          theme: buildWpccTheme(),
          builder: (context, child) => MediaQuery(
              data:
                  MediaQuery.of(context).copyWith(disableAnimations: reduced),
              child: child!),
          home: MemberTheme(
              child: Builder(
                  builder: (context) => Scaffold(
                      body: TextButton(
                          onPressed: () => showMemberSheet<void>(
                              context: context,
                              title: 'Filters',
                              builder: (_) => const Text('content')),
                          child: const Text('open')))))));
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));
      final surface = find.byKey(const ValueKey('member-sheet-surface'));
      final early = tester.getTopLeft(surface).dy;
      await tester.pumpAndSettle();
      final rest = tester.getTopLeft(surface).dy;
      if (reduced) {
        expect(early, rest);
      } else {
        expect(early, greaterThan(rest + 20));
      }
      await tester.tap(find.byTooltip('Close'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      if (!reduced) {
        expect(tester.getTopLeft(surface).dy, greaterThan(rest));
      }
      await tester.pumpAndSettle();
      expect(surface, findsNothing);
      await tester.pumpWidget(const SizedBox());
    }
  });
}
