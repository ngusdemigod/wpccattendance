import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/config/app_config.dart';
import 'media_native_share_stub.dart'
    if (dart.library.html) 'media_native_share_web.dart';

/// Link to something in the app that shows a rich preview when pasted into a
/// chat. It points at the PWA (not at the media itself); the page behind it
/// carries the thumbnail, title and description for the preview and then opens
/// the app. [kind] is `v` (video), `p` (photo) or `a` (audio message).
///
/// Audio messages are not in the media catalog, so their [title] and artwork
/// [image] travel in the link for the preview.
String mediaShareLink(String kind, String id, {String? title, String? image}) {
  final query = {
    if (title != null && title.trim().isNotEmpty) 't': title.trim(),
    if (image != null && image.startsWith('https://')) 'i': image,
  };
  final base = '${AppConfig.publicAppUrl}/s/$kind/${Uri.encodeComponent(id)}';
  return query.isEmpty ? base : Uri.parse(base).replace(queryParameters: query).toString();
}

/// Opens the share dialog for [path] inside the PWA (empty for the app's home
/// page), or for [url] when given. Where the browser has no share dialog, the
/// link is copied instead and the user is told so.
Future<void> shareMedia(BuildContext context,
    {required String title,
    String? text,
    String path = '',
    String? url}) async {
  final link = url ?? '${AppConfig.publicAppUrl}/$path';
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (await nativeShare(title: title, text: text, url: link)) return;
  await Clipboard.setData(ClipboardData(text: link));
  messenger?.showSnackBar(const SnackBar(content: Text('Link copied')));
}
