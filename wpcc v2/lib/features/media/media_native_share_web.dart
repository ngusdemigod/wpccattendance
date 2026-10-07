import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Opens the browser's share sheet (Web Share API) with a link. Returns false
/// when the browser has none, so the caller can fall back to copying the link.
/// Closing the sheet without sharing counts as handled.
Future<bool> nativeShare(
    {required String title, String? text, required String url}) async {
  final data = web.ShareData(title: title, text: text ?? '', url: url);
  try {
    if (!web.window.navigator.canShare(data)) return false;
    await web.window.navigator.share(data).toDart;
    return true;
  } catch (error) {
    // AbortError: the user dismissed the share sheet.
    return error.toString().contains('AbortError');
  }
}
