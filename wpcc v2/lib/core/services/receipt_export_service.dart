import 'dart:typed_data';

// Deferred: the PDF and barcode libraries are large and only needed once a
// member actually saves a receipt, so they stay out of the startup download.
import 'receipt_document.dart' deferred as receipt;
import 'receipt_save_outcome.dart';
import 'receipt_saver.dart';

export 'receipt_save_outcome.dart';

typedef ReceiptFileSaver = Future<ReceiptSaveOutcome> Function(Uint8List bytes,
    {required String filename, required String mime});

/// Creates a PDF or PNG receipt for a giving transaction and hands it to the
/// browser. Creation is platform neutral; delivery goes through [saver].
class ReceiptExportService {
  const ReceiptExportService({this.saver = saveReceiptFile});
  final ReceiptFileSaver saver;

  Future<ReceiptSaveOutcome> downloadPdf(Map<String, dynamic> tx) async {
    await receipt.loadLibrary();
    final bytes = await receipt.buildReceiptPdf(tx);
    return saver(bytes,
        filename: '${receipt.ReceiptData.fromTransaction(tx).fileStem}.pdf',
        mime: 'application/pdf');
  }

  Future<ReceiptSaveOutcome> downloadImage(Map<String, dynamic> tx) async {
    await receipt.loadLibrary();
    final bytes = await receipt.buildReceiptPng(tx);
    return saver(bytes,
        filename: '${receipt.ReceiptData.fromTransaction(tx).fileStem}.png',
        mime: 'image/png');
  }
}
