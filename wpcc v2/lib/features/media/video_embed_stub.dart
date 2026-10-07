import 'package:flutter/material.dart';

import 'video_embed_controller.dart';

/// Non-web fallback: embedding is unavailable, so the parent shows the
/// "Open in ..." button instead. [VideoEmbed.supported] lets callers skip the
/// player area entirely.
class VideoEmbed extends StatelessWidget {
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

  static const supported = false;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
