import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wpcc_community/core/widgets/initials_avatar.dart';
import 'package:wpcc_community/core/widgets/member_photo_backdrop.dart';
import 'package:wpcc_community/core/theme/member_theme.dart';

void main() {
  testWidgets('media keeps its green fallback without artwork', (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: MemberPhotoBackdrop(
      imageUrl: '',
      route: '/media',
      child: Text('Message'),
    )));
    final fallback = tester.widget<MemberBackdrop>(find.byType(MemberBackdrop));
    expect(fallback.media, isTrue);
    expect(find.byType(Image), findsNothing);
    expect(find.text('Message'), findsOneWidget);
  });

  testWidgets('artwork fades only after decoding', (tester) async {
    Widget scene(bool ready, {bool reduced = false}) => MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduced),
            child: BackdropImageFade(
                ready: ready, child: const ColoredBox(color: Colors.red)),
          ),
        );
    await tester.pumpWidget(scene(false));
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 0);
    await tester.pumpWidget(scene(true));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity,
        inExclusiveRange(0, 1));
    await tester.pumpAndSettle();
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1);
    await tester.pumpWidget(scene(false, reduced: true));
    await tester.pumpWidget(scene(true, reduced: true));
    await tester.pump();
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1);
  });

  testWidgets('high contrast omits decorative image loading', (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: MediaQuery(
      data: MediaQueryData(highContrast: true),
      child: MemberPhotoBackdrop(
          imageUrl: 'https://example.test/cover.jpg', route: '/media'),
    )));
    expect(find.byType(InitialsAvatar), findsNothing);
    expect(find.byType(MemberBackdrop), findsOneWidget);
  });
}
