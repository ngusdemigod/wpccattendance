import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wpcc_community/features/announcements/announcement_color_picker.dart';
import 'package:wpcc_community/features/announcements/announcement_palette.dart';

void main() {
  test('every palette colour has readable text contrast', () {
    for (final style in AnnouncementPalette.styles) {
      for (final bg in [style.from, style.to]) {
        expect(contrastRatio(style.foreground, bg), greaterThanOrEqualTo(4.5),
            reason: style.key);
      }
    }
  });

  test('keys are unique and unknown or empty keys fall back to default', () {
    final keys = AnnouncementPalette.styles.map((s) => s.key).toSet();
    expect(keys.length, AnnouncementPalette.styles.length);
    expect(AnnouncementPalette.byKey(null), isNull);
    expect(AnnouncementPalette.byKey(''), isNull);
    expect(AnnouncementPalette.byKey('linear-gradient(red,blue)'), isNull);
    expect(AnnouncementPalette.byKey('ocean')?.key, 'ocean');
  });

  test('status font shrinks for longer posts', () {
    expect(AnnouncementPalette.statusFontSize('Short'), 28);
    expect(AnnouncementPalette.statusFontSize('x' * 100), 22);
    expect(AnnouncementPalette.statusFontSize('x' * 300), 17);
  });

  testWidgets('picker selects swatches and preview follows', (tester) async {
    String? value;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => Column(children: [
            AnnouncementColorPicker(
                value: value, onChanged: (v) => setState(() => value = v)),
            AnnouncementStatusPreview(text: 'Hello church', styleKey: value),
          ]),
        ),
      ),
    ));
    expect(find.text('Hello church'), findsOneWidget);
    final swatch = find.bySemanticsLabel('Ocean blue');
    expect(tester.getSize(swatch).width, greaterThanOrEqualTo(48));
    await tester.tap(swatch);
    await tester.pumpAndSettle();
    expect(value, 'ocean');
    final text = tester.widget<Text>(find.text('Hello church'));
    expect(text.style, isNull);
    await tester.tap(find.bySemanticsLabel('Default background'));
    await tester.pumpAndSettle();
    expect(value, isNull);
  });
}
