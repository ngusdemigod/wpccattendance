import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wpcc_community/core/theme/app_motion.dart';

void main() {
  testWidgets('component transition expands and returns to its origin',
      (tester) async {
    final animation = AnimationController(
        vsync: tester, duration: const Duration(milliseconds: 550));
    addTearDown(animation.dispose);
    await tester.pumpWidget(MaterialApp(
        home: ComponentRouteMotion(
      animation: animation,
      origin: const Rect.fromLTWH(20, 100, 160, 180),
      child: const SizedBox.expand(child: ColoredBox(color: Colors.green)),
    )));
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 0);
    animation.forward();
    await tester.pumpAndSettle();
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1);
    animation.reverse();
    await tester.pumpAndSettle();
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 0);
    expect(tester.takeException(), isNull);
  });
  testWidgets('covered page recedes and returns when the next page exits',
      (tester) async {
    final secondary =
        AnimationController(vsync: tester, duration: AppMotion.page);
    addTearDown(secondary.dispose);
    await tester.pumpWidget(MaterialApp(
        home: AppRouteMotion(
      animation: const AlwaysStoppedAnimation(1),
      secondaryAnimation: secondary,
      child: const Text('Underlying page'),
    )));
    secondary.forward();
    await tester.pumpAndSettle();
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity,
        closeTo(.82, .001));
    secondary.reverse();
    await tester.pumpAndSettle();
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'route travel is fixed and settles without moving the child layout',
      (tester) async {
    final animation =
        AnimationController(vsync: tester, duration: AppMotion.page);
    addTearDown(animation.dispose);
    await tester.pumpWidget(MaterialApp(
        home: AppRouteMotion(
            animation: animation,
            offset: const Offset(16, 0),
            child: const Text('Page'))));
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 0);
    animation.forward();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 110));
    final opacity = tester.widget<Opacity>(find.byType(Opacity)).opacity;
    expect(opacity, greaterThan(.5));
    await tester.pumpAndSettle();
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1);
    animation.reverse();
    await tester.pump();
    expect(
        tester
            .widget<IgnorePointer>(find
                .descendant(
                    of: find.byType(AppRouteMotion),
                    matching: find.byType(IgnorePointer))
                .first)
            .ignoring,
        isTrue);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion renders the final state even mid-transition',
      (tester) async {
    final animation =
        AnimationController(vsync: tester, duration: AppMotion.page, value: .3);
    addTearDown(animation.dispose);
    await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: AppRouteMotion(
                animation: animation, child: const Text('Ready')))));
    expect(find.byType(Opacity), findsNothing);
    expect(find.text('Ready'), findsOneWidget);
  });
}
