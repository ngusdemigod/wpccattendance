import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/app_config.dart';
import '../../core/services/swr_cache.dart';

class MediaRepository {
  MediaRepository(
      [SupabaseClient? client, http.Client? httpClient, String? apiBase])
      : _client = client,
        _http = httpClient,
        _apiBase = (apiBase ?? AppConfig.mediaApiBase)
            .replaceFirst(RegExp(r'/+$'), '');

  final SupabaseClient? _client;
  final http.Client? _http;
  final String _apiBase;

  /// Resolved lazily so a repository used only for the media API works
  /// without Supabase being initialised.
  SupabaseClient get client => _client ?? Supabase.instance.client;
  final cache = SwrCache.instance;

  static const galleryPageSize = 40;
  static const videoPageSize = 50;

  /// Reads one page of the public media catalog (Cloudflare Worker + D1). The
  /// catalog is public content, so there is no login. In the browser the
  /// request carries the app's Origin, which the API requires.
  Future<List<Map<String, dynamic>>> _catalog(
      String path, Map<String, String> query) async {
    final uri = Uri.parse('$_apiBase$path').replace(queryParameters: query);
    const headers = {'Accept': 'application/json'};
    final response = await (_http != null
            ? _http.get(uri, headers: headers)
            : http.get(uri, headers: headers))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('Media service unavailable (${response.statusCode})');
    }
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    final items = body is Map ? body['items'] : null;
    if (items is! List) {
      throw Exception('Media service returned unexpected data');
    }
    return items.map((row) => Map<String, dynamic>.from(row as Map)).toList();
  }

  /// Mirrored Facebook photos, newest first. Pass the last row of the previous
  /// page as [after] for keyset pagination. Only the first page is cached.
  Future<List<Map<String, dynamic>>> galleryPhotos(
      {Map<String, dynamic>? after, int limit = galleryPageSize}) {
    final size = limit.clamp(1, 50);
    Future<List<Map<String, dynamic>>> load() => _catalog('/v1/gallery', {
          'limit': '$size',
          if (after?['published_at'] != null && after?['id'] != null)
            'before': '${after!['published_at']}|${after['id']}',
        });
    return after == null ? cache.get('media:gallery:$size', load) : load();
  }

  /// The stored copy of one gallery photo, for saving to the device. It comes
  /// from the media API (not the image host) because the image host does not
  /// allow the browser to read the bytes.
  Future<Uint8List> photoFile(String photoId) async {
    final uri = Uri.parse(
        '$_apiBase/v1/photos/${Uri.encodeComponent(photoId)}/file');
    final response = await (_http != null ? _http.get(uri) : http.get(uri))
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
      throw Exception('Photo unavailable (${response.statusCode})');
    }
    return response.bodyBytes;
  }

  /// YouTube and Facebook videos and livestreams, newest first.
  Future<List<Map<String, dynamic>>> videos({int limit = videoPageSize}) {
    final size = limit.clamp(1, 50);
    return cache.get('media:videos:$size',
        () => _catalog('/v1/videos', {'limit': '$size'}));
  }

  Future<List<Map<String, dynamic>>> episodes({int limit = 50}) =>
      cache.get('media:episodes:$limit', () async {
        final rows = await client
            .from('media_sermons')
            .select(
              'id,external_id,title,description,duration_ms,explicit,source_published_at,'
              'artwork_url,provider_url,embed_url',
            )
            .eq('provider', 'spotify')
            .eq('status', 'published')
            .order('source_published_at', ascending: false)
            .limit(limit);
        return (rows as List)
            .map((row) => Map<String, dynamic>.from(row as Map))
            .toList();
      });

  Future<Map<String, dynamic>?> episode(String id) =>
      cache.get('media:episode:$id', () async {
        final row = await client
            .from('media_sermons')
            .select(
                'id,external_id,title,description,duration_ms,explicit,source_published_at,artwork_url,provider_url,embed_url')
            .eq('id', id)
            .maybeSingle();
        return row == null ? null : Map<String, dynamic>.from(row);
      });

  Future<List<Map<String, dynamic>>> albums() =>
      cache.get('media:albums', () async {
        final rows = await client
            .from('media_albums')
            .select(
                'id,title,description,featured_image,media_album_tracks(count)')
            .eq('status', 'published')
            .order('created_at');
        return (rows as List)
            .map((row) => Map<String, dynamic>.from(row as Map))
            .toList();
      });

  Future<List<Map<String, dynamic>>> albumTracks(String albumId) =>
      cache.get('media:album:$albumId', () async {
        final rows = await client
            .from('media_album_tracks')
            .select(
                'track_number,episode:media_sermons(id,external_id,title,description,duration_ms,source_published_at,artwork_url,provider_url,embed_url)')
            .eq('album_id', albumId)
            .order('track_number');
        return (rows as List)
            .map((row) => Map<String, dynamic>.from(row as Map))
            .toList();
      });
}
