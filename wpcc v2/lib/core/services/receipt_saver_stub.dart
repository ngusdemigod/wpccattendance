import 'dart:typed_data';

import 'receipt_save_outcome.dart';

/// Saving a file is only implemented for the browser build.
Future<ReceiptSaveOutcome> saveReceiptFile(Uint8List bytes,
        {required String filename, required String mime}) =>
    Future.error(UnsupportedError(
        'Receipt downloads are only available in the app in a browser.'));
