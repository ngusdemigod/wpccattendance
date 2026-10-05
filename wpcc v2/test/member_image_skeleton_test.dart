import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wpcc_community/core/widgets/member_skeleton.dart';

void main() {
  for (final circular in [false, true]) {
    testWidgets('image skeleton preserves bounds, circular=$circular',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
          home: Center(
              child: MemberSkeleton.image(size: 88, circular: circular))));
      expect(tester.getSize(find.byType(MemberSkeleton)), const Size(88, 88));
      final decoration = tester
          .widget<Container>(find.descendant(
              of: find.byType(MemberSkeleton),
              matching: find.byType(Container)))
          .decoration as BoxDecoration;
      expect(decoration.shape, circular ? BoxShape.circle : BoxShape.rectangle);
      expect(find.bySemanticsLabel('Loading image'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.binding.hasScheduledFrame, isTrue);
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('reduced motion shows a static image placeholder',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: MediaQuery(
      data: MediaQueryData(disableAnimations: true),
      child: Center(child: MemberSkeleton.image(size: 120, imageHeight: 160)),
    )));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(MemberSkeleton)), const Size(120, 160));
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
