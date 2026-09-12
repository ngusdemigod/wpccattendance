import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import 'media_repository.dart';
import 'spotify_episode_player.dart';

typedef EpisodeLoader = Future<List<Map<String, dynamic>>> Function();

class MediaPage extends StatefulWidget {
  const MediaPage({super.key, this.loadEpisodes});

  final EpisodeLoader? loadEpisodes;

  @override
  State<MediaPage> createState() => _MediaPageState();
}

class _MediaPageState extends State<MediaPage> {
  late Future<List<Map<String, dynamic>>> episodes;

  @override
  void initState() {
    super.initState();
    episodes = _load();
  }

  Future<List<Map<String, dynamic>>> _load() =>
      (widget.loadEpisodes ?? MediaRepository().episodes)();

  Future<void> _refresh() async {
    final next = _load();
    setState(() => episodes = next);
    await next;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(19, 22, 19, 110),
              children: [
                const Text(
                  'Messages & podcasts',
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Listen to recent WPCC podcast episodes and messages.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: WpccColors.inkSoft,
                  ),
                ),
                const SizedBox(height: 24),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: episodes,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const SizedBox(
                        height: 260,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (snapshot.hasError) {
                      return _MediaStatus(
                        icon: PhosphorIcons.warningCircle(),
                        title: 'Unable to load Spotify',
                        message:
                            'Pull down to retry loading the latest podcast episodes.',
                      );
                    }
                    final rows = snapshot.data ?? const [];
                    if (rows.isEmpty) {
                      return _MediaStatus(
                        icon: PhosphorIcons.microphoneStage(),
                        title: 'No episodes yet',
                        message:
                            'New Spotify episodes will appear here automatically.',
                      );
                    }
                    return Column(
                      children: [
                        for (final episode in rows) ...[
                          _EpisodeCard(episode: episode),
                          const SizedBox(height: 14),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
}

class _EpisodeCard extends StatefulWidget {
  const _EpisodeCard({required this.episode});

  final Map<String, dynamic> episode;

  @override
  State<_EpisodeCard> createState() => _EpisodeCardState();
}

class _EpisodeCardState extends State<_EpisodeCard> {
  bool playerVisible = false;

  @override
  Widget build(BuildContext context) {
    final episode = widget.episode;
    final artwork = episode['artwork_url']?.toString() ?? '';
    final embedUrl = episode['embed_url']?.toString() ?? '';
    final providerUrl = episode['provider_url']?.toString() ?? '';
    final description = episode['description']?.toString().trim() ?? '';
    final published = DateTime.tryParse(
      episode['source_published_at']?.toString() ?? '',
    );
    final durationMs = int.tryParse(episode['duration_ms']?.toString() ?? '');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: WpccColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(17),
                child: artwork.isEmpty
                    ? _ArtworkPlaceholder()
                    : Image.network(
                        artwork,
                        width: 92,
                        height: 92,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _ArtworkPlaceholder(),
                      ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: SizedBox(
                  height: 92,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        episode['title']?.toString() ?? 'Podcast episode',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontSize: 15,
                              height: 1.2,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const Spacer(),
                      Text(
                        [
                          if (published != null)
                            DateFormat('d MMM yyyy')
                                .format(published.toLocal()),
                          if (durationMs != null) _duration(durationMs),
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontSize: 11,
                              color: WpccColors.muted,
                            ),
                      ),
                      const SizedBox(height: 7),
                      SizedBox(
                        height: 30,
                        child: FilledButton.icon(
                          onPressed: embedUrl.isEmpty
                              ? null
                              : () => setState(
                                    () => playerVisible = !playerVisible,
                                  ),
                          style: FilledButton.styleFrom(
                            backgroundColor: WpccColors.ink,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          icon: Icon(
                            playerVisible
                                ? PhosphorIcons.pause()
                                : PhosphorIcons.play(),
                            size: 14,
                          ),
                          label: Text(playerVisible ? 'Hide player' : 'Play'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              description,
              maxLines: playerVisible ? 4 : 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    height: 1.45,
                    color: WpccColors.inkSoft,
                  ),
            ),
          ],
          if (playerVisible && embedUrl.isNotEmpty) ...[
            const SizedBox(height: 14),
            SpotifyEpisodePlayer(
              embedUrl: embedUrl,
              providerUrl: providerUrl,
            ),
          ],
          if (providerUrl.isNotEmpty) ...[
            const SizedBox(height: 7),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => launchUrl(
                  Uri.parse(providerUrl),
                  mode: LaunchMode.externalApplication,
                  webOnlyWindowName: '_blank',
                ),
                icon: const Icon(Icons.open_in_new_rounded, size: 15),
                label: const Text('Open in Spotify'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _duration(int milliseconds) {
    final totalMinutes = Duration(milliseconds: milliseconds).inMinutes;
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return hours > 0 ? '${hours}h ${minutes}m' : '$minutes min';
  }
}

class _ArtworkPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 92,
        height: 92,
        color: WpccColors.primarySoft,
        alignment: Alignment.center,
        child: Icon(
          PhosphorIcons.microphoneStage(),
          color: WpccColors.primaryDeep,
          size: 28,
        ),
      );
}

class _MediaStatus extends StatelessWidget {
  const _MediaStatus({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(20, 30, 20, 30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: WpccColors.line),
        ),
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: WpccColors.primarySoft,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, size: 26, color: WpccColors.primaryDeep),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                height: 1.5,
                color: WpccColors.muted,
              ),
            ),
          ],
        ),
      );
}
