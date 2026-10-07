import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wpcc_community/core/services/receipt_document.dart';
import 'package:wpcc_community/core/services/receipt_export_service.dart';
import 'package:wpcc_community/features/give/receipt_actions.dart';

const sample = <String, dynamic>{
  'amount_kobo': 1250000,
  'status': 'successful',
  'giving_type': 'first_fruit',
  'paystack_reference': 'WPCC-3F9A12BC7D',
  'paid_at': '2026-09-27T09:41:00Z',
  'source_summary': 'Visa •••• 4081',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReceiptData', () {
    test('uses only fields the transaction has', () {
      final data = ReceiptData.fromTransaction(sample);
      expect(data.amount, '12,500.00');
      expect(data.givingType, 'First Fruit');
      expect(data.reference, 'WPCC-3F9A12BC7D');
      expect(data.dateTime, '27 Sep 2026 · 10:41 AM');
      expect(data.kind, ReceiptKind.successful);
      expect(data.title, 'Thank you for giving!');
    });

    test('does not claim success for an unfinished or failed payment', () {
      expect(
          ReceiptData.fromTransaction({...sample, 'status': 'initialized'})
              .title,
          'Payment pending');
      expect(ReceiptData.fromTransaction({...sample, 'status': 'failed'}).title,
          'Payment not completed');
    });

    test('shows a dash instead of inventing missing values', () {
      final data = ReceiptData.fromTransaction(const {'status': 'successful'});
      expect(data.amount, '—');
      expect(data.reference, '—');
      expect(data.dateTime, '—');
      expect(data.barcodeData, 'WPCC-RECEIPT');
    });
  });

  group('receipt files', () {
    test('PDF is a valid document', () async {
      final bytes = await buildReceiptPdf(sample);
      expect(String.fromCharCodes(bytes.sublist(0, 5)), '%PDF-');
      expect(String.fromCharCodes(bytes.sublist(bytes.length - 8)),
          contains('%%EOF'));
      expect(bytes.length, greaterThan(5000));
    });

    test('PDF still builds with missing and unusual fields', () async {
      final bytes = await buildReceiptPdf(const {'status': 'failed'});
      expect(String.fromCharCodes(bytes.sublist(0, 5)), '%PDF-');
    });

    test('PNG is a real, non blank image', () async {
      final bytes = await buildReceiptPng(sample);
      expect(bytes.sublist(0, 8), [137, 80, 78, 71, 13, 10, 26, 10]);
      final codec = await ui.instantiateImageCodec(bytes);
      final image = (await codec.getNextFrame()).image;
      expect(image.width, receiptImageWidth);
      expect(image.height, greaterThan(1200));
      final pixels = (await image.toByteData())!.buffer.asUint8List();
      final colours = <int>{};
      for (var i = 0; i < pixels.length; i += 4 * 97) {
        colours.add(pixels[i] << 16 | pixels[i + 1] << 8 | pixels[i + 2]);
      }
      expect(colours.length, greaterThan(3));
      // The white card sits in the middle of the grey page.
      int px(int x, int y) {
        final o = (y * image.width + x) * 4;
        return pixels[o] << 16 | pixels[o + 1] << 8 | pixels[o + 2];
      }

      expect(px(10, 10), 0xF6F7FA);
      expect(px(200, 200), 0xFFFFFF);
    });

    test('service passes the right file name and type to the saver', () async {
      final saved = <(String, String, int)>[];
      final service = ReceiptExportService(
          saver: (bytes, {required filename, required mime}) async {
        saved.add((filename, mime, bytes.length));
        return ReceiptSaveOutcome.downloaded;
      });
      await service.downloadPdf(sample);
      await service.downloadImage(sample);
      expect(saved[0].$1, 'wpcc-receipt-WPCC-3F9A12BC7D.pdf');
      expect(saved[0].$2, 'application/pdf');
      expect(saved[1].$1, 'wpcc-receipt-WPCC-3F9A12BC7D.png');
      expect(saved[1].$2, 'image/png');
      expect(saved.every((e) => e.$3 > 1000), isTrue);
    });
  });

  Future<void> settle(WidgetTester tester, Finder until) async {
    for (var i = 0; i < 40 && until.evaluate().isEmpty; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pump(const Duration(milliseconds: 400));
  }

  group('ReceiptActions', () {
    Future<void> pump(WidgetTester tester, ReceiptFileSaver saver) =>
        tester.pumpWidget(MaterialApp(
            home: Scaffold(
                body: ReceiptActions(
                    transaction: sample,
                    exporter: ReceiptExportService(saver: saver)))));

    testWidgets('shows progress, then success', (tester) async {
      final gate = Completer<void>();
      await pump(tester, (Uint8List b,
          {required filename, required mime}) async {
        await gate.future;
        return ReceiptSaveOutcome.shared;
      });
      await tester.tap(find.text('PDF'));
      await tester.pump();
      expect(find.text('Preparing…'), findsOneWidget);
      // Both buttons are locked while one receipt is being prepared.
      expect(
          tester
              .widget<OutlinedButton>(
                  find.widgetWithText(OutlinedButton, 'Image'))
              .onPressed,
          isNull);
      gate.complete();
      await settle(tester, find.text('PDF receipt shared.'));
      expect(find.text('PDF receipt shared.'), findsOneWidget);
    });

    testWidgets('reports a failure and allows retrying', (tester) async {
      await pump(
          tester,
          (Uint8List b, {required filename, required mime}) =>
              Future.error(StateError('blocked')));
      await tester.tap(find.text('Image'));
      await settle(tester, find.textContaining('could not create'));
      expect(
          find.textContaining('could not create the receipt'), findsOneWidget);
      expect(
          tester
              .widget<OutlinedButton>(
                  find.widgetWithText(OutlinedButton, 'Image'))
              .onPressed,
          isNotNull);
    });
  });
}
