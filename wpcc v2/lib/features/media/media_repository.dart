import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/swr_cache.dart';

class MediaRepository {
  MediaRepository([SupabaseClient? client])
      : client = client ?? Supabase.instance.client;

  final SupabaseClient client;
  final cache = SwrCache.instance;

  Future<List<Map<String, dynamic>>> communityFeed() async {
    final rows = await client
        .from('community_media_feed')
        .select('id,caption,image_url,permalink,category,published_at')
        .eq('is_active', true)
        .order('published_at', ascending: false)
        .limit(100);
    return List<Map<String, dynamic>>.from(rows);
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
