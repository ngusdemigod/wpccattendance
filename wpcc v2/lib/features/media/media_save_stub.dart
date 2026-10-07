import 'dart:typed_data';

import 'media_save_outcome.dart';

/// Saving a file is only implemented for the browser build.
Future<SaveOutcome> saveMediaBytes(Uint8List bytes,
        {required String filename, required String mime}) async =>
    throw UnsupportedError('Saving files is only available in the browser');
