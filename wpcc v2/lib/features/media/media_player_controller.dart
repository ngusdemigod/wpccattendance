import 'package:flutter/foundation.dart';

import 'spotify_playback_bridge.dart';

class MediaPlayerEpisode {
  const MediaPlayerEpisode(
      {required this.id,
      required this.externalId,
      required this.title,
      required this.artworkUrl,
      required this.providerUrl,
      required this.embedUrl,
      required this.durationMs,
      required this.description,
      required this.publishedAt});
  factory MediaPlayerEpisode.fromRow(Map<String, dynamic> row) =>
      MediaPlayerEpisode(
          id: row['id']?.toString() ?? '',
          externalId: row['external_id']?.toString() ?? '',
          title: row['title']?.toString() ?? 'Podcast episode',
          artworkUrl: row['artwork_url']?.toString() ?? '',
          providerUrl: row['provider_url']?.toString() ?? '',
          embedUrl: row['embed_url']?.toString() ?? '',
          durationMs: int.tryParse(row['duration_ms']?.toString() ?? '') ?? 0,
          description: row['description']?.toString() ?? '',
          publishedAt: row['source_published_at']?.toString() ?? '');
  final String id,
      externalId,
      title,
      artworkUrl,
      providerUrl,
      embedUrl,
      description,
      publishedAt;
  final int durationMs;
  Map<String, dynamic> toRow() => {
        'id': id,
        'external_id': externalId,
        'title': title,
        'artwork_url': artworkUrl,
        'provider_url': providerUrl,
        'embed_url': embedUrl,
        'duration_ms': durationMs,
        'description': description,
        'source_published_at': publishedAt
      };
}

class MediaPlayerState {
  const MediaPlayerState(
      {this.episode,
      this.isPlaying = false,
      this.positionMs = 0,
      this.durationMs = 0});
  final MediaPlayerEpisode? episode;
  final bool isPlaying;
  final int positionMs, durationMs;
}

class MediaPlayerController extends ValueNotifier<MediaPlayerState> {
  MediaPlayerController._() : super(const MediaPlayerState()) {
    SpotifyPlaybackBridge.instance.addListener(_syncPlayback);
  }
  static final instance = MediaPlayerController._();

  void _syncPlayback() {
    final episode = value.episode;
    if (episode == null) return;
    final playback = SpotifyPlaybackBridge.instance.value;
    value = MediaPlayerState(
        episode: episode,
        isPlaying: !playback.isPaused,
        positionMs: playback.positionMs,
        durationMs:
            playback.durationMs > 0 ? playback.durationMs : episode.durationMs);
  }

  void play(Map<String, dynamic> row) {
    final episode = MediaPlayerEpisode.fromRow(row);
    value = MediaPlayerState(
        episode: episode, isPlaying: true, durationMs: episode.durationMs);
    final entity = episode.externalId.isNotEmpty
        ? 'spotify:episode:${episode.externalId}'
        : episode.providerUrl.isNotEmpty
            ? episode.providerUrl
            : episode.embedUrl.replaceFirst('/embed/', '/');
    SpotifyPlaybackBridge.instance.loadAndPlay(entity);
  }

  void togglePlayback() => SpotifyPlaybackBridge.instance.togglePlay();
  void seek(int positionMs) {
    SpotifyPlaybackBridge.instance.seek(positionMs);
    value = MediaPlayerState(
        episode: value.episode,
        isPlaying: value.isPlaying,
        positionMs: positionMs,
        durationMs: value.durationMs);
  }

  void close() {
    SpotifyPlaybackBridge.instance.pause();
    value = const MediaPlayerState();
  }
}
