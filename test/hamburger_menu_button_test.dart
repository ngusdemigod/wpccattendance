import 'package:attendamce/shared/widgets/hamburger_menu_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('opens the app shell drawer from every nested page',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          key: appShellScaffoldKey,
          drawer: const Drawer(
            child: Center(child: Text('Navigation drawer')),
          ),
          body: const IndexedStack(
            index: 2,
            children: [
              Scaffold(body: HamburgerMenuButton()),
              Scaffold(body: HamburgerMenuButton()),
              Scaffold(body: HamburgerMenuButton()),
              Scaffold(body: HamburgerMenuButton()),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.bySemanticsLabel('Open navigation menu'));
    await tester.pumpAndSettle();

    expect(find.text('Navigation drawer'), findsOneWidget);
  });

  testWidgets('becomes a back button on an inner page', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const Scaffold(
                    body: HamburgerMenuButton(),
                  ),
                ),
              );
            },
            child: const Text('Open inner page'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open inner page'));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Go back'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Go back'));
    await tester.pumpAndSettle();

    expect(find.text('Open inner page'), findsOneWidget);
  });
}
