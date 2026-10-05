import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:wpcc_community/features/departments/tools/department_tool_card.dart';
import 'package:wpcc_community/features/departments/tools/department_tool_catalog.dart';
import 'package:wpcc_community/features/departments/tools/department_tools_page.dart';

void main() {
  test('all 20 ministries retain distinct definitions', () {
    expect(DepartmentToolDefinition.all.length, 20);
    expect(DepartmentToolDefinition.all.map((d) => d.name).toSet().length, 20);
    expect(DepartmentToolDefinition.forName('Wisdom Streams')!.icon,
        PhosphorIconsRegular.musicNotes);
    expect(DepartmentToolDefinition.forName('Power House')!.title,
        'Prayer-session plan');
  });

  for (final size in [const Size(390, 844), const Size(834, 1194)]) {
    for (final brightness in Brightness.values) {
      for (final scale in [1.0, 1.6]) {
        testWidgets('tools ${size.width} $brightness scale $scale', (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(MaterialApp(
            theme: ThemeData(brightness: brightness),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale), disableAnimations: true),
              child: child!),
            home: DepartmentToolsPage(loadDepartments: () async => [
              for (final d in DepartmentToolDefinition.all)
                {'department_id': d.name, 'name': d.name, 'is_member': true},
              {'department_id': 'pending', 'name': 'Pending team', 'status': 'pending'},
            ]),
          ));
          await tester.pumpAndSettle();
          expect(find.text('Pending team'), findsNothing);
          expect(find.text('Ushering & Protocol'), findsOneWidget);
          expect(tester.takeException(), isNull);
          final first = find.byType(DepartmentToolCard).first;
          final firstSize = tester.getSize(first);
          if (scale == 1) {
            expect(firstSize.width, closeTo(size.width == 390 ? 169 : 246, 1));
            expect(firstSize.height, greaterThanOrEqualTo(size.width == 390 ? 194 : 204));
          } else {
            expect(firstSize.width, size.width - (size.width == 390 ? 40 : 64));
          }
          await tester.tap(first);
          await tester.pumpAndSettle();
          expect(find.text('Attendance counter slip'), findsOneWidget);
          final unavailable = tester.widget<DepartmentToolCard>(
              find.widgetWithText(DepartmentToolCard, 'Attendance counter slip'));
          expect(unavailable.onTap, isNull);
          expect(find.text('Not available yet'), findsWidgets);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  testWidgets('direct department URL cannot show pending membership', (tester) async {
    await tester.pumpWidget(MaterialApp(home: DepartmentToolsPage(
      departmentId: 'pending', loadDepartments: () async => [
        {'department_id': 'pending', 'name': 'Accounts', 'status': 'pending'},
      ])));
    await tester.pumpAndSettle();
    expect(find.text('No active membership for these department tools'), findsOneWidget);
    expect(find.byType(DepartmentToolCard), findsNothing);
  });
}
