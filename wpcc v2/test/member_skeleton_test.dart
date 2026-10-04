import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wpcc_community/core/widgets/member_skeleton.dart';

void main() {
  testWidgets('skeleton fits themes and widths and respects reduced motion',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final brightness in Brightness.values) {
      for (final width in [320.0, 390.0, 834.0]) {
        tester.view.physicalSize = Size(width, 1194);
        await tester.pumpWidget(MaterialApp(
            theme: ThemeData(brightness: brightness),
            home: MediaQuery(
                data: MediaQueryData(
                    size: Size(width, 1194), disableAnimations: true),
                child: const Scaffold(
                    body: Padding(
                        padding: EdgeInsets.all(20),
                        child: MemberSkeleton(hero: true))))));
        await tester.pumpAndSettle();
        expect(tester.binding.hasScheduledFrame, isFalse);
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('shimmer animates and disposes cleanly', (tester) async {
    await tester
        .pumpWidget(const MaterialApp(home: Scaffold(body: MemberSkeleton())));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
