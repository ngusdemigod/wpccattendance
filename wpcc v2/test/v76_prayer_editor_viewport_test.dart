import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  for (final width in <double>[393, 360]) {
    testWidgets('prayer alert editor fits a $width pixel viewport',
        (tester) async {
      tester.view.physicalSize = Size(width, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: PrayerAlertEditPage()));
      await tester.pump();

      expect(find.text('New prayer alert'), findsOneWidget);
      expect(find.text('Test prayer alert'), findsOneWidget);
      expect(find.byType(ChoiceChip), findsNWidgets(7));
      for (final chip in find.byType(ChoiceChip).evaluate()) {
        final rect = tester.getRect(find.byWidget(chip.widget));
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(width));
      }
      expect(tester.takeException(), isNull);
    });
  }
}
