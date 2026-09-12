import 'package:flutter/foundation.dart';

class MediaPlayerEpisode {
  const MediaPlayerEpisode({
    required this.id,
    required this.title,
    required this.artworkUrl,
    required this.providerUrl,
    required this.embedUrl,
    required this.durationMs,
  });

  final String id;
  final String title;
  final String artworkUrl;
  final String providerUrl;
  final String embedUrl;
  final int durationMs;
}

class MediaPlayerState {
  const MediaPlayerState({this.episode, this.expanded = false});
  final MediaPlayerEpisode? episode;
  final bool expanded;
}

class MediaPlayerController extends ValueNotifier<MediaPlayerState> {
  MediaPlayerController._() : super(const MediaPlayerState());
  static final instance = MediaPlayerController._();

  void play(Map<String, dynamic> row) {
    value = MediaPlayerState(
      episode: MediaPlayerEpisode(
        id: row['id']?.toString() ?? '',
        title: row['title']?.toString() ?? 'Podcast episode',
        artworkUrl: row['artwork_url']?.toString() ?? '',
        providerUrl: row['provider_url']?.toString() ?? '',
        embedUrl: row['embed_url']?.toString() ?? '',
        durationMs: int.tryParse(row['duration_ms']?.toString() ?? '') ?? 0,
      ),
    );
  }

  void toggleExpanded() => value =
      MediaPlayerState(episode: value.episode, expanded: !value.expanded);
  void close() => value = const MediaPlayerState();
}
