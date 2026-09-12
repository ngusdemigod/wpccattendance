import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

class SpotifyEpisodePlayer extends StatefulWidget {
  const SpotifyEpisodePlayer({
    super.key,
    required this.embedUrl,
    required this.providerUrl,
  });

  final String embedUrl;
  final String providerUrl;

  @override
  State<SpotifyEpisodePlayer> createState() => _SpotifyEpisodePlayerState();
}

class _SpotifyEpisodePlayerState extends State<SpotifyEpisodePlayer> {
  static int _viewCount = 0;
  late final String viewType;

  @override
  void initState() {
    super.initState();
    viewType = 'spotify-episode-${_viewCount++}';
    ui_web.platformViewRegistry.registerViewFactory(viewType, (viewId) {
      final iframe = web.HTMLIFrameElement()
        ..src = widget.embedUrl
        ..title = 'Spotify episode player'
        ..allow =
            'autoplay; clipboard-write; encrypted-media; fullscreen; picture-in-picture'
        ..loading = 'lazy';
      iframe.style
        ..border = '0'
        ..width = '100%'
        ..height = '100%';
      return iframe;
    });
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 152,
        width: double.infinity,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: HtmlElementView(viewType: viewType),
        ),
      );
}
