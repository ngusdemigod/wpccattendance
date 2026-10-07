import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'receipt_save_outcome.dart';

/// Gets [bytes] to the member as a file, using the best route the browser has.
///
/// Phones and tablets (including installed PWAs, where anchor downloads often
/// do nothing) go to the Web Share sheet first so the member can Save to Photos
/// or Files. Desktop browsers ask where to save through the File System Access
/// picker. Anything else falls back to a normal blob download.
Future<ReceiptSaveOutcome> saveReceiptFile(Uint8List bytes,
    {required String filename, required String mime}) async {
  final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: mime));
  final file = web.File([blob].toJS, filename, web.FilePropertyBag(type: mime));

  final routes = <_Route>[
    if (_isTouchDevice()) ...[_share, _pick] else ...[_pick, _share],
    _anchor,
  ];
  Object? lastError;
  for (final route in routes) {
    try {
      final outcome = await route(blob, file, filename, mime);
      if (outcome != null) return outcome;
    } catch (e) {
      if (_isAbort(e)) return ReceiptSaveOutcome.cancelled;
      lastError = e;
    }
  }
  throw StateError(
      'The receipt could not be saved${lastError == null ? '' : ': $lastError'}');
}

typedef _Route = Future<ReceiptSaveOutcome?> Function(
    web.Blob blob, web.File file, String filename, String mime);

bool _isAbort(Object error) => error.toString().contains('AbortError');

bool _isTouchDevice() {
  final nav = web.window.navigator;
  final ua = nav.userAgent;
  if (RegExp(r'Android|iPhone|iPad|iPod|Mobile', caseSensitive: false)
      .hasMatch(ua)) {
    return true;
  }
  // iPadOS identifies as a Mac but has a touch screen.
  return nav.platform == 'MacIntel' && nav.maxTouchPoints > 1;
}

Future<ReceiptSaveOutcome?> _share(
    web.Blob blob, web.File file, String filename, String mime) async {
  final nav = web.window.navigator;
  if (!nav.has('share') || !nav.has('canShare')) {
    return null;
  }
  final data = web.ShareData(files: [file].toJS, title: 'WPCC giving receipt');
  if (!nav.canShare(data)) return null;
  try {
    await nav.share(data).toDart;
    return ReceiptSaveOutcome.shared;
  } catch (e) {
    // The browser refuses a share when the tap that started it has gone stale
    // (NotAllowedError). Let the next route handle it instead of failing.
    if (e.toString().contains('NotAllowedError')) return null;
    rethrow;
  }
}

Future<ReceiptSaveOutcome?> _pick(
    web.Blob blob, web.File file, String filename, String mime) async {
  final window = web.window;
  if (!window.has('showSaveFilePicker')) return null;
  final extension =
      filename.contains('.') ? '.${filename.split('.').last}' : '';
  final options = {
    'suggestedName': filename,
    'types': [
      {
        'description': mime == 'application/pdf' ? 'PDF document' : 'Image',
        'accept': {
          mime: [extension],
        },
      },
    ],
  }.jsify();
  try {
    final handle = await (window.callMethod<JSPromise<JSObject>>(
            'showSaveFilePicker'.toJS, options))
        .toDart;
    final writable =
        await (handle.callMethod<JSPromise<JSObject>>('createWritable'.toJS))
            .toDart;
    await (writable.callMethod<JSPromise<JSAny?>>('write'.toJS, blob)).toDart;
    await (writable.callMethod<JSPromise<JSAny?>>('close'.toJS)).toDart;
    return ReceiptSaveOutcome.saved;
  } catch (e) {
    // Not allowed in cross-origin frames or after a stale tap: fall through.
    final text = e.toString();
    if (text.contains('SecurityError') || text.contains('NotAllowedError')) {
      return null;
    }
    rethrow;
  }
}

Future<ReceiptSaveOutcome?> _anchor(
    web.Blob blob, web.File file, String filename, String mime) async {
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = filename;
  anchor.style.display = 'none';
  web.document.body!.append(anchor);
  anchor.click();
  anchor.remove();
  // Release the blob once the browser has had time to start the download.
  Future<void>.delayed(
      const Duration(minutes: 1), () => web.URL.revokeObjectURL(url));
  return ReceiptSaveOutcome.downloaded;
}
