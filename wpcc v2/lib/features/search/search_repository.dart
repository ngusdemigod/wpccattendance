import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/swr_cache.dart';
import '../media/media_feed.dart';
import '../media/media_repository.dart';
import '../profile/profile_repository.dart';

typedef SearchRows = Future<List<Map<String, dynamic>>>;

/// Global search across the church app. The Supabase `global_search` RPC covers
/// events, departments and announcements, department people come from the
/// community RPCs, and the media catalogue (videos, livestreams, Spotify
/// messages), devotional posts and classes are searched here. Every section is
/// independent: one failing (for example classes before they are available)
/// never hides results from the others. Only when every section fails does
/// [search] throw, so the page can show its error and retry state.
class SearchRepository {
  SearchRepository({
    SupabaseClient? client,
    SearchRows Function(String query)? loadCore,
    SearchRows Function()? loadVideos,
    SearchRows Function()? loadEpisodes,
    SearchRows Function(String query)? loadDevotional,
    SearchRows Function()? loadClasses,
  })  : _client = client,
        _loadCore = loadCore,
        _loadVideos = loadVideos,
        _loadEpisodes = loadEpisodes,
        _loadDevotional = loadDevotional,
        _loadClasses = loadClasses;

  final SupabaseClient? _client;
  final SearchRows Function(String query)? _loadCore;
  final SearchRows Function()? _loadVideos;
  final SearchRows Function()? _loadEpisodes;
  final SearchRows Function(String query)? _loadDevotional;
  final SearchRows Function()? _loadClasses;
  SupabaseClient get client => _client ?? Supabase.instance.client;
  final cache = SwrCache.instance;
  MediaRepository? _media;
  ProfileRepository? _profile;

  /// Rows per section for the server-backed sections and for the sections
  /// filtered on the device.
  static const coreLimit = 8;
  static const sectionLimit = 20;
  static const episodeScanLimit = 200;

  Future<List<Map<String, dynamic>>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];
    final outcomes = await Future.wait([
      _guard(() => _core(q)),
      _guard(() async => matchVideos(q, await _videos())),
      _guard(() async => matchEpisodes(q, await _episodes())),
      _guard(() => _devotional(q)),
      _guard(() async => matchClasses(q, await _classes())),
    ]);
    // Classes are "coming soon": a missing RPC there is expected, so it does
    // not count towards the all-sections-failed error.
    final primary = outcomes.take(4);
    if (primary.every((outcome) => outcome == null)) {
      throw Exception('Search unavailable');
    }
    return orderSearchResults([
      for (final outcome in outcomes) ...?outcome,
    ]);
  }

  Future<List<Map<String, dynamic>>?> _guard(
      Future<List<Map<String, dynamic>>> Function() load) async {
    try {
      return await load();
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _videos() =>
      (_loadVideos ?? (_media ??= MediaRepository()).videos)();

  Future<List<Map<String, dynamic>>> _episodes() =>
      (_loadEpisodes ??
          () => (_media ??= MediaRepository())
              .episodes(limit: episodeScanLimit))();

  Future<List<Map<String, dynamic>>> _classes() =>
      (_loadClasses ?? (_profile ??= ProfileRepository()).classes)();

  Future<List<Map<String, dynamic>>> _devotional(String q) async {
    if (_loadDevotional != null) return _loadDevotional(q);
    final term = _filterTerm(q);
    if (term.isEmpty) return [];
    final rows = await client
        .from('posts')
        .select('id,title,body,created_at')
        .eq('post_kind', 'devotional')
        .eq('is_archived', false)
        .or('title.ilike.*$term*,body.ilike.*$term*')
        .order('created_at', ascending: false)
        .limit(sectionLimit);
    return matchDevotional(q, [
      for (final row in rows as List) Map<String, dynamic>.from(row as Map)
    ]);
  }

  Future<List<Map<String, dynamic>>> _core(String q) {
    if (_loadCore != null) return _loadCore(q);
    return cache.get('search:${q.toLowerCase()}', () async {
      final aggregate = await client.rpc('global_search', params: {
        'search_query': q,
        'search_filter': 'all',
        'limit_per_section': coreLimit
      });
      final rows = (aggregate as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .where((e) => e['section'] != 'people')
          .toList();
      final myTeams = await client
          .rpc('community_departments', params: {'p_filter': 'mine'});
      final ids = (myTeams as List)
          .map((e) => (e as Map)['department_id']?.toString())
          .whereType<String>()
          .toSet();
      for (final id in ids) {
        final people = await client.rpc('community_department_members',
            params: {
              'p_department_id': id,
              'p_search': q,
              'p_limit': 8,
              'p_offset': 0
            });
        for (final p in (people as List)) {
          final m = Map<String, dynamic>.from(p as Map);
          if (rows.any((r) => r['id']?.toString() == m['user_id']?.toString())) {
            continue;
          }
          rows.add({
            'section': 'people',
            'id': m['user_id'],
            'title': m['full_name'],
            'subtitle': m['department_name'],
            'body': m['role_name'],
            'image_url': m['avatar'],
            'result_type': 'member',
            'route': '',
            'metadata': m
          });
        }
      }
      return rows;
    },
        freshFor: const Duration(minutes: 2),
        maxStale: const Duration(minutes: 10));
  }

  // ---- Matching helpers (pure, unit tested) --------------------------------

  /// YouTube and Facebook videos and livestreams whose title or description
  /// contains every word of [query]. Shorts open the same video route.
  static List<Map<String, dynamic>> matchVideos(
      String query, List<Map<String, dynamic>> videos) {
    final scored = <(int, DateTime?, Map<String, dynamic>)>[];
    for (final row in videos) {
      final title = row['title']?.toString() ?? '';
      final description = row['description']?.toString() ?? '';
      final rank = searchRank(query, title, description);
      if (rank == null) continue;
      final id = row['id']?.toString() ?? '';
      if (id.isEmpty) continue;
      final item = MediaFeedItem.video(row);
      final thumbnail = videoThumbnailUrl(row);
      scored.add((
        rank,
        item.publishedAt,
        {
          'section': 'media',
          'id': id,
          'title': item.title,
          'subtitle': _join([
            item.providerLabel,
            item.type.label,
            formatVideoDuration(row['duration_seconds']),
            _date(item.publishedAt),
          ]),
          'image_url': thumbnail.isEmpty ? null : thumbnail,
          'result_type': item.type.name,
          'row': row,
        }
      ));
    }
    return _top(scored);
  }

  /// Spotify messages (media_sermons) whose title or description match.
  static List<Map<String, dynamic>> matchEpisodes(
      String query, List<Map<String, dynamic>> episodes) {
    final scored = <(int, DateTime?, Map<String, dynamic>)>[];
    for (final row in episodes) {
      final title = row['title']?.toString() ?? '';
      final description = row['description']?.toString() ?? '';
      final rank = searchRank(query, title, description);
      if (rank == null) continue;
      final id = row['id']?.toString() ?? '';
      if (id.isEmpty) continue;
      final item = MediaFeedItem.audio(row);
      final artwork = row['artwork_url']?.toString() ?? '';
      scored.add((
        rank,
        item.publishedAt,
        {
          'section': 'audio',
          'id': id,
          'title': item.title,
          'subtitle': _join([
            'Spotify',
            'Message',
            _duration(row['duration_ms']),
            _date(item.publishedAt),
          ]),
          'image_url': artwork.isEmpty ? null : artwork,
          'result_type': 'audio',
          'row': row,
        }
      ));
    }
    return _top(scored);
  }

  /// Devotional posts. A post without a title is named after its first line.
  static List<Map<String, dynamic>> matchDevotional(
      String query, List<Map<String, dynamic>> posts) {
    final scored = <(int, DateTime?, Map<String, dynamic>)>[];
    for (final row in posts) {
      final body = _plain(row['body']?.toString() ?? '');
      final title = (row['title']?.toString() ?? '').trim().isNotEmpty
          ? row['title'].toString().trim()
          : _firstLine(body);
      final rank = searchRank(query, title, body);
      if (rank == null) continue;
      final id = row['id']?.toString() ?? '';
      if (id.isEmpty) continue;
      final date = DateTime.tryParse(row['created_at']?.toString() ?? '');
      scored.add((
        rank,
        date,
        {
          'section': 'devotional',
          'id': id,
          'title': title.isEmpty ? 'Devotional' : title,
          'subtitle': _snippet(body, query),
          'result_type': 'devotional',
        }
      ));
    }
    return _top(scored);
  }

  /// The member's classes. Class results are informational: the Classes area
  /// is not open yet, so the page does not navigate from them.
  static List<Map<String, dynamic>> matchClasses(
      String query, List<Map<String, dynamic>> classes) {
    final scored = <(int, DateTime?, Map<String, dynamic>)>[];
    for (final row in classes) {
      final title = row['title']?.toString() ??
          row['name']?.toString() ??
          row['class_name']?.toString() ??
          '';
      final description = row['description']?.toString() ?? '';
      final rank = searchRank(query, title, description);
      if (rank == null) continue;
      final id = (row['id'] ?? row['class_id'] ?? title).toString();
      final progress = row['progress_percent'];
      scored.add((
        rank,
        null,
        {
          'section': 'classes',
          'id': id,
          'title': title,
          'subtitle': progress is num
              ? '${progress.round()}% complete'
              : (description.isEmpty ? 'Class' : _snippet(description, query)),
          'result_type': 'class',
        }
      ));
    }
    return _top(scored);
  }

  static List<Map<String, dynamic>> _top(
      List<(int, DateTime?, Map<String, dynamic>)> scored) {
    final indexed = [for (var i = 0; i < scored.length; i++) (i, scored[i])];
    indexed.sort((a, b) {
      final byRank = a.$2.$1.compareTo(b.$2.$1);
      if (byRank != 0) return byRank;
      final first = a.$2.$2, second = b.$2.$2;
      if (first != null && second != null) {
        final byDate = second.compareTo(first);
        if (byDate != 0) return byDate;
      } else if (first != null) {
        return -1;
      } else if (second != null) {
        return 1;
      }
      return a.$1.compareTo(b.$1);
    });
    return [
      for (final entry in indexed.take(sectionLimit)) entry.$2.$3,
    ];
  }

  static String _join(List<String> parts) =>
      parts.where((part) => part.trim().isNotEmpty).join(' · ');

  static String _date(DateTime? value) =>
      value == null ? '' : DateFormat('d MMM yyyy').format(value.toLocal());

  static String _duration(Object? millis) {
    final ms = millis is num ? millis.toInt() : int.tryParse('$millis');
    return ms == null ? '' : formatVideoDuration(ms ~/ 1000);
  }

  static String _plain(String value) => value
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static String _firstLine(String body) {
    final end = body.indexOf(RegExp(r'[.!?]\s'));
    final line = end > 0 && end < 80 ? body.substring(0, end + 1) : body;
    return line.length > 80 ? '${line.substring(0, 80).trimRight()}...' : line;
  }

  /// A short excerpt of [text], centred on the first match when it sits deep
  /// in a long passage.
  static String _snippet(String text, String query, {int max = 120}) {
    final plain = _plain(text);
    if (plain.length <= max) return plain;
    final token = _tokens(query).firstWhere(
        (word) => plain.toLowerCase().contains(word),
        orElse: () => '');
    final at = token.isEmpty ? 0 : plain.toLowerCase().indexOf(token);
    final start = at <= 24 ? 0 : at - 24;
    final end = start + max > plain.length ? plain.length : start + max;
    return '${start > 0 ? '...' : ''}${plain.substring(start, end).trim()}'
        '${end < plain.length ? '...' : ''}';
  }

  static List<String> _tokens(String query) => query
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();

  /// Strips characters that have a meaning inside a PostgREST filter value.
  static String _filterTerm(String query) => query
      .replaceAll(RegExp(r'[,()"\\%*:]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  /// Relevance of a title/description pair for [query], lower is better, or
  /// null when it does not match. Every word of the query must appear in the
  /// title or the description.
  static int? searchRank(String query, String title, String description) {
    final words = _tokens(query);
    if (words.isEmpty) return null;
    final name = title.toLowerCase();
    final all = '$name ${description.toLowerCase()}';
    if (!words.every(all.contains)) return null;
    final phrase = words.join(' ');
    if (name == phrase) return 0;
    if (name.startsWith(phrase)) return 1;
    if (words.every(name.contains)) {
      return RegExp('(^|\\s)${RegExp.escape(words.first)}').hasMatch(name)
          ? 2
          : 3;
    }
    return 4;
  }
}

/// Orders rows by section (the order of [searchSectionKeys]) and keeps each
/// source's own relevance order inside a section. Unknown sections go last.
List<Map<String, dynamic>> orderSearchResults(List<Map<String, dynamic>> rows) {
  const order = [
    'events',
    'departments',
    'announcements',
    'media',
    'audio',
    'devotional',
    'classes',
    'people',
  ];
  int position(Map<String, dynamic> row) {
    final index = order.indexOf(row['section']?.toString() ?? '');
    return index < 0 ? order.length : index;
  }

  final indexed = [for (var i = 0; i < rows.length; i++) (i, rows[i])];
  indexed.sort((a, b) {
    final bySection = position(a.$2).compareTo(position(b.$2));
    return bySection != 0 ? bySection : a.$1.compareTo(b.$1);
  });
  return [for (final entry in indexed) entry.$2];
}
