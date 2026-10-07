import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'media_save_outcome.dart';

bool _isPhoneOrTablet() {
  final navigator = web.window.navigator;
  final agent = navigator.userAgent;
  return RegExp('Android|iPhone|iPad|iPod', caseSensitive: false)
          .hasMatch(agent) ||
      (agent.contains('Macintosh') && navigator.maxTouchPoints > 1);
}

bool _dismissed(Object error) => error.toString().contains('AbortError');

/// Phones and photo apps handle JPEG everywhere, so images are converted from
/// WebP first. If anything goes wrong the original file is used unchanged.
Future<({web.Blob blob, String name, String mime})> _prepare(
    Uint8List bytes, String filename, String mime) async {
  final source = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: mime));
  if (mime != 'image/webp') return (blob: source, name: filename, mime: mime);
  try {
    final bitmap = await web.window.createImageBitmap(source).toDart;
    final canvas = web.HTMLCanvasElement()
      ..width = bitmap.width
      ..height = bitmap.height;
    final context = canvas.getContext('2d') as web.CanvasRenderingContext2D;
    context.fillStyle = '#ffffff'.toJS;
    context.fillRect(0, 0, bitmap.width, bitmap.height);
    context.drawImage(bitmap, 0, 0);
    final done = Completer<web.Blob?>();
    canvas.toBlob(
        ((web.Blob? blob) => done.complete(blob)).toJS, 'image/jpeg', 0.92.toJS);
    final jpeg = await done.future;
    if (jpeg == null) throw StateError('no image');
    return (
      blob: jpeg,
      name: filename.replaceFirst(RegExp(r'\.webp$'), '.jpg'),
      mime: 'image/jpeg'
    );
  } catch (_) {
    return (blob: source, name: filename, mime: mime);
  }
}

/// Saves a file the way the device expects:
///
/// - On a phone or tablet it opens the share sheet with the file, which offers
///   Save to Photos / Save to Gallery / Files.
/// - On a computer it asks where to save (the browser's save dialog).
/// - Anywhere else it starts an ordinary download.
Future<SaveOutcome> saveMediaBytes(Uint8List bytes,
    {required String filename, required String mime}) async {
  final file = await _prepare(bytes, filename, mime);

  if (_isPhoneOrTablet()) {
    final shared = web.File(
        [file.blob].toJS, file.name, web.FilePropertyBag(type: file.mime));
    final data = web.ShareData(files: [shared].toJS);
    try {
      if (web.window.navigator.canShare(data)) {
        await web.window.navigator.share(data).toDart;
        return SaveOutcome.shared;
      }
    } catch (error) {
      if (_dismissed(error)) return SaveOutcome.cancelled;
    }
  } else if (web.window.has('showSaveFilePicker')) {
    try {
      final extension =
          file.name.contains('.') ? '.${file.name.split('.').last}' : '.jpg';
      final options = {
        'suggestedName': file.name,
        'types': [
          {
            'description': 'Image',
            'accept': {
              file.mime: [extension]
            }
          }
        ],
      }.jsify();
      final handle = await web.window
          .callMethod<JSPromise<JSObject>>('showSaveFilePicker'.toJS, options)
          .toDart;
      final writable = await handle
          .callMethod<JSPromise<JSObject>>('createWritable'.toJS)
          .toDart;
      await writable.callMethod<JSPromise>('write'.toJS, file.blob).toDart;
      await writable.callMethod<JSPromise>('close'.toJS).toDart;
      return SaveOutcome.saved;
    } catch (error) {
      if (_dismissed(error)) return SaveOutcome.cancelled;
    }
  }

  // Ordinary download.
  final url = web.URL.createObjectURL(file.blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = file.name;
  anchor.style.display = 'none';
  web.document.body!.append(anchor);
  anchor.click();
  anchor.remove();
  Future<void>.delayed(
      const Duration(seconds: 5), () => web.URL.revokeObjectURL(url));
  return SaveOutcome.saved;
}
