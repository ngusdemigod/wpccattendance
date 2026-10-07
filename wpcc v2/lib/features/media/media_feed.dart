import 'dart:math';

import 'package:intl/intl.dart';

import '../../core/config/app_config.dart';

/// Builds URLs for media mirrored to our own storage by the media-sync worker.
/// Each photo has a key prefix with two compressed, immutable WebP copies
/// (w480.webp and w1600.webp), so the browser and Cloudflare edge can cache
/// them forever. The original is not stored; the Facebook link opens it.
class MediaCdn {
  const MediaCdn._();

  /// Compressed copy: 480px wide for grids and thumbnails, 1600px for viewing.
  static String thumb(String key, {required int width, String? base}) =>
      '${_base(base)}/${_key(key)}/${width <= 480 ? 'w480' : 'w1600'}.webp';

  static String _base(String? base) =>
      (base ?? AppConfig.mediaCdnBase).replaceFirst(RegExp(r'/+$'), '');
  static String _key(String key) => key.replaceFirst(RegExp(r'^/+'), '');
}

enum MediaType {
  audio('Audio'),
  video('Video'),
  livestream('Livestream');

  const MediaType(this.label);
  final String label;
}

/// One entry in the mixed Media feed (Spotify audio, YouTube and Facebook
/// videos, livestreams).
class MediaFeedItem {
  const MediaFeedItem(
      {required this.type,
      required this.id,
      required this.title,
      required this.publishedAt,
      required this.row});

  final MediaType type;
  final String id, title;
  final DateTime? publishedAt;
  final Map<String, dynamic> row;

  bool get isAudio => type == MediaType.audio;
  String get provider => row['provider']?.toString() ?? '';

  /// Short or portrait video (a Short or Reel), shown in the vertical shelf.
  /// Livestreams are always landscape, whatever the source says.
  bool get isVertical =>
      !isAudio &&
      type != MediaType.livestream &&
      const {'short', 'portrait'}.contains(row['format']?.toString());

  /// A livestream that is on air right now.
  bool get isLiveNow =>
      type == MediaType.livestream &&
      (row['live_now'] == 1 || row['live_now'] == true);

  /// Display name of the platform that hosts a video.
  String get providerLabel => switch (provider) {
        'youtube' => 'YouTube',
        'facebook' => 'Facebook',
        'spotify' => 'Spotify',
        _ => '',
      };

  factory MediaFeedItem.audio(Map<String, dynamic> row) => MediaFeedItem(
      type: MediaType.audio,
      id: row['id']?.toString() ?? '',
      title: row['title']?.toString() ?? 'Message',
      publishedAt: _parse(row['source_published_at']),
      row: row);

  factory MediaFeedItem.video(Map<String, dynamic> row) => MediaFeedItem(
      type: row['kind']?.toString() == 'live'
          ? MediaType.livestream
          : MediaType.video,
      id: row['id']?.toString() ?? '',
      title: row['title']?.toString().trim().isNotEmpty == true
          ? row['title'].toString()
          : 'Untitled video',
      publishedAt: _parse(row['published_at']),
      row: row);

  static DateTime? _parse(Object? value) =>
      value == null ? null : DateTime.tryParse(value.toString());
}

/// Merges audio episodes and videos into one newest-first list. Items without
/// a date sort last. The sort is stable for equal dates, so audio episodes
/// (which only carry a date) keep the order they were delivered in.
List<MediaFeedItem> mergeMediaFeed(
    List<Map<String, dynamic>> episodes, List<Map<String, dynamic>> videos) {
  final items = <MediaFeedItem>[
    for (final row in episodes) MediaFeedItem.audio(row),
    for (final row in videos) MediaFeedItem.video(row),
  ];
  final indexed = [for (var i = 0; i < items.length; i++) (i, items[i])];
  indexed.sort((a, b) {
    final first = a.$2.publishedAt, second = b.$2.publishedAt;
    if (first == null && second == null) return a.$1.compareTo(b.$1);
    if (first == null) return 1;
    if (second == null) return -1;
    final byDate = second.compareTo(first);
    return byDate != 0 ? byDate : a.$1.compareTo(b.$1);
  });
  return [for (final entry in indexed) entry.$2];
}

/// Thumbnail for a video row: our mirrored copy when available, otherwise the
/// provider URL (YouTube thumbnails are stable, Facebook's expire).
String videoThumbnailUrl(Map<String, dynamic> row, {int width = 640}) {
  final key = row['r2_key']?.toString() ?? '';
  if (key.isNotEmpty) return MediaCdn.thumb(key, width: width);
  if (row['provider']?.toString() == 'youtube') {
    return row['thumbnail_url']?.toString() ?? '';
  }
  return '';
}

/// Embed URL for the inline player, or an empty string when the video cannot
/// be embedded and should fall back to the "Open in ..." button.
///
/// The video starts on its own. With [bare] the player drops its own controls
/// and loops, for the full-screen Shorts viewer that supplies its own.
String videoEmbedUrl(Map<String, dynamic> row, {bool bare = false}) {
  final provider = row['provider']?.toString();
  final externalId = row['external_id']?.toString() ?? '';
  if (provider == 'youtube' && externalId.isNotEmpty) {
    final id = Uri.encodeComponent(externalId);
    return 'https://www.youtube-nocookie.com/embed/$id'
        '?rel=0&playsinline=1&autoplay=1&enablejsapi=1'
        '${bare ? '&controls=0&loop=1&playlist=$id&modestbranding=1&fs=0&disablekb=1' : ''}';
  }
  if (provider == 'facebook') {
    final permalink = row['permalink_url']?.toString() ?? '';
    final uri = Uri.tryParse(permalink);
    if (uri == null || uri.scheme != 'https') return '';
    return 'https://www.facebook.com/plugins/video.php'
        '?href=${Uri.encodeComponent(permalink)}&show_text=false&autoplay=true';
  }
  return '';
}

/// Short, human readable duration such as 1:05:09 or 12:30.
String formatVideoDuration(Object? seconds) {
  final total = seconds is num ? seconds.toInt() : int.tryParse('$seconds');
  if (total == null || total <= 0) return '';
  final h = total ~/ 3600, m = (total % 3600) ~/ 60, s = total % 60;
  String two(int n) => n.toString().padLeft(2, '0');
  return h > 0 ? '$h:${two(m)}:${two(s)}' : '$m:${two(s)}';
}

/// Artwork or thumbnail for any feed item.
String mediaThumbnailUrl(MediaFeedItem item, {int width = 640}) => item.isAudio
    ? item.row['artwork_url']?.toString() ?? ''
    : videoThumbnailUrl(item.row, width: width);

/// Plain-text details shown next to a feed item's badge: platform, date and
/// length.
List<String> mediaDetails(MediaFeedItem item) {
  final date = item.publishedAt;
  final formatted =
      date == null ? '' : DateFormat('d MMM yyyy').format(date.toLocal());
  if (item.isAudio) {
    final ms = int.tryParse(item.row['duration_ms']?.toString() ?? '') ?? 0;
    final min = Duration(milliseconds: ms).inMinutes;
    return [
      formatted,
      if (ms > 0) min >= 60 ? '${min ~/ 60}h ${min % 60}m' : '$min min',
    ];
  }
  return [
    item.providerLabel,
    formatted,
    formatVideoDuration(item.row['duration_seconds']),
  ];
}

/// The livestream that is on air right now, if there is one.
MediaFeedItem? liveNowItem(List<MediaFeedItem> items) {
  for (final item in items) {
    if (item.isLiveNow) return item;
  }
  return null;
}

/// The newest livestream that has ended. Newest first, as delivered.
MediaFeedItem? latestLivestreamItem(List<MediaFeedItem> items) {
  for (final item in items) {
    if (item.type == MediaType.livestream && !item.isLiveNow) return item;
  }
  return null;
}

/// The four ways the Media page lays out a run of items.
enum MediaShelfKind {
  /// A few rows, Spotify style.
  list(4),

  /// A horizontal scroll of portrait cards, like Shorts or TikTok.
  shorts(4),

  /// One large 16:9 video.
  wide(1),

  /// Small square tiles, three across.
  grid(6);

  const MediaShelfKind(this.size);
  final int size;
}

class MediaShelf {
  const MediaShelf(this.kind, this.items);
  final MediaShelfKind kind;
  final List<MediaFeedItem> items;
}

/// Lays the feed out as a run of shelves in a random order, so the page does
/// not open with the same kind of content every time. [items] must be newest
/// first. Each item appears once; each pool (shorts, videos, audio) stays
/// newest first. Shelves mix audio and video by chance weighted by how many of
/// each are left. The on-air livestream is left out: it has its own place at
/// the top of the page.
List<MediaShelf> buildMediaShelves(List<MediaFeedItem> items, {Random? random}) {
  final rng = random ?? Random();
  final shorts = [for (final item in items) if (item.isVertical && !item.isLiveNow) item];
  final audio = [for (final item in items) if (item.isAudio) item];
  final videos = [
    for (final item in items)
      if (!item.isAudio && !item.isVertical && !item.isLiveNow) item
  ];

  MediaFeedItem? takeAny() {
    final total = audio.length + videos.length;
    if (total == 0) return null;
    final video = videos.isNotEmpty && (audio.isEmpty || rng.nextInt(total) < videos.length);
    return (video ? videos : audio).removeAt(0);
  }

  List<MediaFeedItem> take(List<MediaFeedItem>? pool, int count) {
    final out = <MediaFeedItem>[];
    while (out.length < count) {
      final MediaFeedItem? next;
      if (pool == null) {
        next = takeAny();
      } else {
        next = pool.isEmpty ? null : pool.removeAt(0);
      }
      if (next == null) break;
      out.add(next);
    }
    return out;
  }

  final order = [...MediaShelfKind.values]..shuffle(rng);
  final shelves = <MediaShelf>[];
  while (shorts.isNotEmpty || audio.isNotEmpty || videos.isNotEmpty) {
    for (final kind in order) {
      final picked = switch (kind) {
        MediaShelfKind.shorts => take(shorts, kind.size),
        MediaShelfKind.wide => take(videos, kind.size),
        MediaShelfKind.list || MediaShelfKind.grid => take(null, kind.size),
      };
      if (picked.isNotEmpty) shelves.add(MediaShelf(kind, picked));
    }
  }
  return shelves;
}
