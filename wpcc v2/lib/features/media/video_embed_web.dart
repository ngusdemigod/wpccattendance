import 'dart:convert';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import 'video_embed_controller.dart';

/// Inline YouTube / Facebook player. The iframe is created with the widget and
/// destroyed with it, which also stops playback, so mount only what is on
/// screen.
///
/// With [interactive] false the iframe lets every pointer event through to
/// Flutter (for swipe and tap handling on top of it); the optional
/// [controller] can then still play and pause a YouTube video.
class VideoEmbed extends StatefulWidget {
  const VideoEmbed(
      {super.key,
      required this.embedUrl,
      required this.title,
      this.aspectRatio = 16 / 9,
      this.interactive = true,
      this.radius = 20,
      this.controller});
  final String embedUrl, title;
  final double aspectRatio, radius;
  final bool interactive;
  final VideoEmbedController? controller;

  static const supported = true;

  @override
  State<VideoEmbed> createState() => _VideoEmbedState();
}

class _VideoEmbedState extends State<VideoEmbed> {
  static int _viewCount = 0;
  late final String viewType;
  web.HTMLIFrameElement? iframe;

  /// Safari and iPhones refuse to start a video with sound unless the tap
  /// happened inside the player itself, so there the video starts muted and
  /// shows the player's own unmute control. Elsewhere it starts with sound.
  static bool get _needsMutedStart {
    final agent = web.window.navigator.userAgent;
    final ios = RegExp('iPhone|iPad|iPod').hasMatch(agent) ||
        (agent.contains('Macintosh') && web.window.navigator.maxTouchPoints > 1);
    final safari = agent.contains('Safari') &&
        !RegExp('Chrome|Chromium|CriOS|FxiOS|Edg').hasMatch(agent);
    return ios || safari;
  }

  String get _source {
    final url = widget.embedUrl;
    if (!_needsMutedStart || !url.contains('youtube')) return url;
    return url.contains('?') ? '$url&mute=1' : '$url?mute=1';
  }

  @override
  void initState() {
    super.initState();
    viewType = 'media-video-embed-${_viewCount++}';
    ui_web.platformViewRegistry.registerViewFactory(viewType, (viewId) {
      final element = web.HTMLIFrameElement()
        ..src = _source
        ..title = widget.title
        ..allow =
            'autoplay; clipboard-write; encrypted-media; fullscreen; picture-in-picture'
        ..setAttribute('allowfullscreen', 'true')
        ..setAttribute('referrerpolicy', 'strict-origin-when-cross-origin');
      element.style
        ..border = '0'
        ..width = '100%'
        ..height = '100%'
        ..pointerEvents = widget.interactive ? 'auto' : 'none';
      iframe = element;
      element.addEventListener(
          'load',
          ((web.Event _) {
            // The player only listens a moment after it has loaded.
            if (!widget.embedUrl.contains('youtube')) return;
            for (final ms in const [400, 1200, 2400]) {
              Future<void>.delayed(Duration(milliseconds: ms), () {
                if (mounted) _send('playVideo');
              });
            }
          }).toJS);
      return element;
    });
    widget.controller?.attach(_send);
  }

  void _send(String command) {
    final message = jsonEncode({'event': 'command', 'func': command, 'args': ''});
    iframe?.contentWindow
        ?.postMessage(message.toJS, 'https://www.youtube-nocookie.com'.toJS);
  }

  @override
  void dispose() {
    widget.controller?.attach(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.radius),
          child: HtmlElementView(viewType: viewType),
        ),
      );
}
