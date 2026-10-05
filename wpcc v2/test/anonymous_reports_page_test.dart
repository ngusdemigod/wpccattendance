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
}
