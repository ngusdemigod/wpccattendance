import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wpcc_community/features/reports/anonymous_reports_page.dart';
import 'package:wpcc_community/core/theme/member_theme.dart';

void main() {
  Future<dynamic> rpc(String name, Map<String,dynamic> params) async => switch(name) {
    'community_anonymous_destinations' => [{'destination':'central'}],
    'community_report_access' => {'can_review':false, 'can_assign':false},
    _ => [],
  };
  for (final size in [const Size(390,844),const Size(834,1194)]) {
    for (final brightness in Brightness.values) {
      testWidgets('report form $size $brightness with keyboard and large text', (tester) async {
        tester.view.physicalSize=size;
        tester.view.devicePixelRatio=1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(MaterialApp(theme:buildMemberTheme(ThemeData(brightness:brightness)),
          home:MediaQuery(data:MediaQueryData(size:size,textScaler:const TextScaler.linear(1.6),
            viewInsets:const EdgeInsets.only(bottom:280)),child:AnonymousReportsPage(rpc:rpc))));
        await tester.pumpAndSettle();
        expect(find.text('Reviewer inbox'),findsNothing);
        expect(find.text('Reports are unavailable. Please retry.'),findsNothing);
        await tester.scrollUntilVisible(find.text('Submit report'),100,scrollable:find.byType(Scrollable).first);
        expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton,'Submit report')).onPressed,isNull);
        expect(tester.takeException(),isNull);
      });
    }
  }
  testWidgets('no assigned destination means no submission', (tester) async {
    await tester.pumpWidget(MaterialApp(home:AnonymousReportsPage(rpc:(name,params) async =>
      name=='community_report_access' ? {'can_review':false} : [])));
    await tester.pumpAndSettle();
    expect(find.text('No reviewer destinations are available yet.'),findsOneWidget);
    expect(find.text('Submit report'),findsNothing);
  });

  Widget app(Future<dynamic> Function(String, Map<String, dynamic>) handler,
          {double scale = 1, Size size = const Size(390, 844)}) =>
      MaterialApp(
          theme: buildMemberTheme(ThemeData()),
          home: MediaQuery(
              data: MediaQueryData(
                  size: size, textScaler: TextScaler.linear(scale)),
              child: AnonymousReportsPage(rpc: handler)));

  void phone(WidgetTester tester, [Size size = const Size(390, 844)]) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> choose(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Central reviewers'));
    await tester.pump();
    await tester.tap(find.text('Central reviewers'));
    await tester.pump();
  }

  Future<void> fill(WidgetTester tester, String text) async {
    await choose(tester);
    await tester.enterText(find.byType(TextField), text);
    await tester.pump();
    await tester.ensureVisible(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
  }

  testWidgets('sections, inline validation and progress guide the form',
      (tester) async {
    phone(tester, const Size(320, 640));
    await tester.pumpWidget(app(rpc, scale: 2, size: const Size(320, 640)));
    await tester.pumpAndSettle();
    expect(find.text('Who should receive it'), findsOneWidget);
    expect(find.text('What happened'), findsOneWidget);
    expect(find.text('Confirm privacy'), findsOneWidget);
    expect(find.textContaining('0 of 3 steps complete'), findsOneWidget);
    await choose(tester);
    await tester.enterText(find.byType(TextField), 'too short');
    await tester.pump();
    expect(find.textContaining('more characters needed'), findsOneWidget);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    expect(find.textContaining('Add at least 20 characters'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('successful submit shows the confirmation with the reference',
      (tester) async {
    phone(tester);
    final calls = <String>[];
    await tester.pumpWidget(app((name, params) async {
      calls.add(name);
      if (name == 'community_submit_anonymous') return 'ref-123';
      return rpc(name, params);
    }));
    await tester.pumpAndSettle();
    await fill(tester, 'This is a long enough report body.');
    expect(find.textContaining('3 of 3 steps complete'), findsOneWidget);
    await tester.tap(find.text('Submit report'));
    await tester.pumpAndSettle();
    expect(calls, contains('community_submit_anonymous'));
    expect(find.text('Report submitted'), findsOneWidget);
    expect(find.text('ref-123'), findsOneWidget);
    expect(find.text('Submit report'), findsNothing);
  });

  testWidgets('failed submit keeps the report and offers a retry',
      (tester) async {
    phone(tester);
    var attempts = 0;
    final keys = <Object?>[];
    await tester.pumpWidget(app((name, params) async {
      if (name == 'community_submit_anonymous') {
        keys.add(params['p_retry_key']);
        if (++attempts == 1) throw Exception('offline');
        return 'ref-9';
      }
      return rpc(name, params);
    }));
    await tester.pumpAndSettle();
    await fill(tester, 'This is a long enough report body.');
    await tester.tap(find.text('Submit report'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Connection interrupted'), findsOneWidget);
    expect(find.text('Retry submission'), findsOneWidget);
    await tester.tap(find.text('Retry submission'));
    await tester.pumpAndSettle();
    expect(find.text('Report submitted'), findsOneWidget);
    expect(keys.toSet().length, 1);
  });
}
