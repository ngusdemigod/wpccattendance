import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import 'media_player_controller.dart';
import 'media_repository.dart';

class MediaEpisodeDetailPage extends StatelessWidget {
  const MediaEpisodeDetailPage({super.key, required this.episodeId, this.seed});
  final String episodeId;
  final Map<String, dynamic>? seed;

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>?>(
        future: seed == null
            ? MediaRepository().episode(episodeId)
            : Future.value(seed),
        builder: (context, snapshot) {
          final episode = snapshot.data;
          return Scaffold(
            appBar: AppBar(title: const Text('Message'), centerTitle: true),
            body: episode == null
                ? Center(
                    child: snapshot.connectionState == ConnectionState.done
                        ? const Text('Message unavailable')
                        : const CircularProgressIndicator())
                : _EpisodeBody(episode: episode),
          );
        },
      );
}

class _EpisodeBody extends StatelessWidget {
  const _EpisodeBody({required this.episode});
  final Map<String, dynamic> episode;

  @override
  Widget build(BuildContext context) {
    final artwork = episode['artwork_url']?.toString() ?? '';
    final providerUrl = episode['provider_url']?.toString() ?? '';
    final published =
        DateTime.tryParse(episode['source_published_at']?.toString() ?? '');
    final durationMs =
        int.tryParse(episode['duration_ms']?.toString() ?? '') ?? 0;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 128),
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: artwork.isEmpty
                ? Container(
                    color: WpccColors.primarySoft,
                    child: Icon(PhosphorIcons.microphoneStage(),
                        size: 64, color: WpccColors.primaryDeep))
                : Image.network(artwork, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 24),
        const Text('WPCC MESSAGES',
            style: TextStyle(
                fontSize: 10,
                letterSpacing: 1.3,
                fontWeight: FontWeight.w600,
                color: WpccColors.primaryDeep)),
        const SizedBox(height: 9),
        Text(episode['title']?.toString() ?? 'Podcast episode',
            style: const TextStyle(
                fontSize: 26,
                height: 1.08,
                fontWeight: FontWeight.w600,
                letterSpacing: -.6)),
        const SizedBox(height: 10),
        Text(
            [
              if (published != null)
                DateFormat('d MMMM yyyy').format(published.toLocal()),
              if (durationMs > 0)
                '${Duration(milliseconds: durationMs).inMinutes} min'
            ].join(' · '),
            style: const TextStyle(fontSize: 12, color: WpccColors.muted)),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: () => MediaPlayerController.instance.play(episode),
          style: FilledButton.styleFrom(
              backgroundColor: WpccColors.ink,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52)),
          icon: Icon(PhosphorIcons.play(), size: 18),
          label: const Text('Play message'),
        ),
        const SizedBox(height: 24),
        Text(episode['description']?.toString() ?? '',
            style: const TextStyle(
                fontSize: 14, height: 1.65, color: WpccColors.inkSoft)),
        if (providerUrl.isNotEmpty) ...[
          const SizedBox(height: 18),
          TextButton.icon(
            onPressed: () => launchUrl(Uri.parse(providerUrl),
                mode: LaunchMode.externalApplication,
                webOnlyWindowName: '_blank'),
            icon: Icon(PhosphorIcons.spotifyLogo(), size: 18),
            label: const Text('Open in Spotify'),
          ),
        ],
      ],
    );
  }
}
