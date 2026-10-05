import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wpcc_community/core/widgets/member_glass.dart';
import 'package:wpcc_community/core/theme/member_material.dart';
import 'package:wpcc_community/core/widgets/member_components.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('selected chips use solid contrasting fills: $brightness',
        (tester) async {
      final theme = ThemeData(brightness: brightness);
      await tester.pumpWidget(MaterialApp(
        theme: theme,
        home: Scaffold(
            body: MemberFilterChip(
          label: 'Upcoming',
          icon: Icons.event,
          selected: true,
          featured: true,
          onPressed: () {},
        )),
      ));
      final decoration = tester
          .widget<AnimatedContainer>(find.descendant(
            of: find.byType(MemberFilterChip),
            matching: find.byType(AnimatedContainer),
          ))
          .decoration! as BoxDecoration;
      expect(decoration.gradient, isNull);
      expect(decoration.color, theme.colorScheme.onSurface);
      expect(tester.widget<Text>(find.text('Upcoming')).style!.color,
          brightness == Brightness.dark ? const Color(0xFF151517) : Colors.white);
    });
  }
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TransparencyPreference.instance.value = false;
  });
  tearDown(() => TransparencyPreference.instance.value = false);
  testWidgets('transparency preference updates glass and persists',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: MemberMaterialScope(
            child: const MemberGlass(child: SizedBox(width: 48, height: 48)))));
    expect(find.byType(BackdropFilter), findsOneWidget);
    await TransparencyPreference.instance.select(true);
    await tester.pump();
    expect(find.byType(BackdropFilter), findsNothing);
    expect(
        (await SharedPreferences.getInstance())
            .getBool('wpcc.reduceTransparency'),
        isTrue);
  });
  testWidgets('high contrast search has an opaque material', (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: MediaQuery(
            data: MediaQueryData(highContrast: true),
            child: Scaffold(body: MemberSearchBar()))));
    final searchMaterial = tester.widget<Material>(find
        .descendant(
            of: find.byType(MemberSearchBar), matching: find.byType(Material))
        .first);
    expect(searchMaterial.color!.a, 1);
  });
  for (final solid in [false, true]) {
    testWidgets('glass respects high contrast: $solid', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(highContrast: solid),
          child: const MemberGlass(child: SizedBox(width: 48, height: 48)),
        ),
      ));
      expect(
          find.byType(BackdropFilter), solid ? findsNothing : findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
