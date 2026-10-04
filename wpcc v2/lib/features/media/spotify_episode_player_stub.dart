import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SpotifyEpisodePlayer extends StatelessWidget {
  const SpotifyEpisodePlayer({
    super.key,
    required this.embedUrl,
    required this.providerUrl,
  });

  final String embedUrl;
  final String providerUrl;

  @override
  Widget build(BuildContext context) => Container(
        height: 88,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18),
        ),
        child: TextButton.icon(
          onPressed: () => launchUrl(
            Uri.parse(providerUrl),
            mode: LaunchMode.externalApplication,
          ),
          icon: const Icon(Icons.open_in_new_rounded, size: 18),
          label: const Text('Listen on Spotify'),
        ),
      );
}
