import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wpcc_community/core/widgets/adaptive_layout.dart';
import 'package:wpcc_community/features/media/media_page.dart';
import 'package:wpcc_community/features/give/give_home_page.dart';

void main() {
  testWidgets('giving accounts adapt without overflow at all target widths',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final width in [375.0, 600.0, 768.0, 1024.0, 1366.0]) {
      tester.view.physicalSize = Size(width, 900);
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: GiveHomePage(
        loadMandates: () async => [],
        loadProjects: () async => [],
        loadAccounts: () async => [
          for (var i = 0; i < 3; i++)
            {
              'account_number': '123456789$i',
              'bank_name': 'Bank',
              'purpose': 'Purpose $i',
              'account_name': 'WPCC'
            }
        ],
      ))));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Purpose 0'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('sections preserve state through phone and tablet rotation',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body: AdaptiveSections(children: [
      _Counter(),
      SizedBox(key: Key('second'), height: 50)
    ]))));
    await tester.tap(find.text('Count 0'));
    for (final width in [375.0, 600.0, 768.0, 1024.0, 1366.0, 375.0]) {
      tester.view.physicalSize = Size(width, 900);
      await tester.pumpAndSettle();
      expect(find.text('Count 1'), findsOneWidget);
      final first = tester.getRect(find.byType(_Counter));
      final second = tester.getRect(find.byKey(const Key('second')));
      expect(second.top == first.top, width >= 900);
      expect(first.width, width >= 900 ? (width - 24) / 2 : width);
      expect(tester.takeException(), isNull);
    }
  });
  testWidgets('media remains readable at target widths in light and dark modes',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final brightness in Brightness.values) {
      for (final width in [375.0, 600.0, 768.0, 1024.0, 1366.0]) {
        tester.view.physicalSize = Size(width, 900);
        await tester.pumpWidget(MaterialApp(
            theme: ThemeData(brightness: brightness),
            home: MediaPage(
              loadAlbums: () async => [],
              loadEpisodes: () async => [
                {
                  'id': 'layout-fixture',
                  'title': 'Sunday message',
                  'description': 'Community teaching',
                  'duration_ms': 3600000,
                  'source_published_at': '2026-09-07',
                  'artwork_url': '',
                  'provider_url': '',
                  'embed_url': '',
                }
              ],
            )));
        await tester.pumpAndSettle();
        expect(find.text('Sunday message'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    }
  });
}

class _Counter extends StatefulWidget {
  const _Counter();
  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int count = 0;
  @override
  Widget build(BuildContext context) => TextButton(
      onPressed: () => setState(() => count++), child: Text('Count $count'));
}
