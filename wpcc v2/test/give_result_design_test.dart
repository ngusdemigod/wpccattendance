import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wpcc_community/core/theme/app_theme.dart';
import 'package:wpcc_community/core/theme/member_theme.dart';
import 'package:wpcc_community/features/give/give_repository.dart';
import 'package:wpcc_community/features/give/give_result_page.dart';
import 'package:wpcc_community/features/give/giving_backdrop.dart';

class ResultRepository implements GiveRepository {
  ResultRepository(this.status, {this.unavailable = false});
  final String status;
  final bool unavailable;
  @override
  Future<Map<String, dynamic>> verify(String reference) async {
    if (unavailable) throw StateError('offline');
    return {
      'status': status,
      'amount_kobo': 500000,
      'giving_type': 'offering',
      'paystack_reference': reference,
      'source_summary': 'Test bank',
    };
  }

  @override
  Future<Map<String, dynamic>?> transactionByReference(
          String reference) async =>
      throw StateError('offline');
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  testWidgets(
      'receipt states fit phone, tablet and enlarged text in both themes',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final brightness in Brightness.values) {
      for (final size in [const Size(390, 844), const Size(834, 1194)]) {
        for (final scale in [1.0, 2.0]) {
          for (final status in [
            'successful',
            'pending',
            'processing',
            'failed'
          ]) {
            tester.view.physicalSize = size;
            await tester.pumpWidget(MaterialApp(
              theme: buildMemberTheme(buildWpccTheme(brightness: brightness)),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: GiveResultPage(
                key: UniqueKey(),
                reference: 'WPCC-00000000-0000-0000-0000-000000000000',
                repository: ResultRepository(status),
              ),
            ));
            await tester.pumpAndSettle();
            final backdrop =
                tester.widget<GivingBackdrop>(find.byType(GivingBackdrop));
            expect(backdrop.status, status);
            final decoration = tester
                .widget<DecoratedBox>(find
                    .descendant(
                        of: find.byType(GivingBackdrop),
                        matching: find.byType(DecoratedBox))
                    .first)
                .decoration as BoxDecoration;
            final color = (decoration.gradient! as LinearGradient).colors.first;
            if (status == 'failed') {
              expect(color.r, greaterThan(color.g));
            } else if (status == 'pending' || status == 'processing') {
              expect(color.r, greaterThan(color.b));
              expect(color.g, greaterThan(color.b));
            }
            await tester.scrollUntilVisible(
                find.widgetWithText(FilledButton, 'Back to Give'), 200,
                scrollable: find.byType(Scrollable).first);
            await tester.pumpAndSettle();
            expect(find.text('Download receipt'),
                status == 'successful' ? findsOneWidget : findsNothing);
            expect(
                find.text('Check payment status'),
                status == 'pending' || status == 'processing'
                    ? findsOneWidget
                    : findsNothing);
            expect(find.byTooltip('Copy reference'), findsOneWidget);
            await tester.ensureVisible(
                find.widgetWithText(FilledButton, 'Back to Give'));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull,
                reason: '$brightness/$size/$scale/$status');
            await tester.pumpWidget(const SizedBox());
          }
        }
      }
    }
  });
  testWidgets('verification failure never presents a successful receipt',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildMemberTheme(buildWpccTheme()),
      home: GiveResultPage(
          reference: 'ref',
          repository: ResultRepository('successful', unavailable: true)),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Unable to check payment status'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Download receipt'), findsNothing);
  });
}
