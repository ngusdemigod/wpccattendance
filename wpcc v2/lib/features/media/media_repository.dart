import 'package:supabase_flutter/supabase_flutter.dart';

class MediaRepository {
  MediaRepository([SupabaseClient? client])
      : client = client ?? Supabase.instance.client;

  final SupabaseClient client;

  Future<List<Map<String, dynamic>>> episodes({int limit = 50}) async {
    final rows = await client
        .from('media_sermons')
        .select(
          'id,title,description,duration_ms,explicit,source_published_at,'
          'artwork_url,provider_url,embed_url',
        )
        .eq('provider', 'spotify')
        .eq('status', 'published')
        .order('source_published_at', ascending: false)
        .limit(limit);
    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  Future<Map<String, dynamic>?> episode(String id) async {
    final row = await client
        .from('media_sermons')
        .select('id,title,description,duration_ms,explicit,source_published_at,artwork_url,provider_url,embed_url')
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : Map<String, dynamic>.from(row);
  }
}
