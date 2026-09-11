import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wpcc_community/core/widgets/initials_avatar.dart';

void main() {
  testWidgets('initials avatar renders initials', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: InitialsAvatar(initials: 'IA')));
    expect(find.text('IA'), findsOneWidget);
  });
}
