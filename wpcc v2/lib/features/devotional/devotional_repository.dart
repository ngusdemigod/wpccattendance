import 'package:supabase_flutter/supabase_flutter.dart';

class DevotionalRepository {
  DevotionalRepository([SupabaseClient? c])
      : client = c ?? Supabase.instance.client;
  final SupabaseClient client;
  Future<List<Map<String, dynamic>>> posts(
      {int offset = 0, int limit = 20}) async {
    final rows = await client
        .from('posts')
        .select('id,title,body,created_at,reaction_counts,comments_count,more')
        .eq('post_kind', 'devotional')
        .eq('is_archived', false)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return (rows as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<Map<String, dynamic>?> post(String id) async {
    final row = await client
        .from('posts')
        .select()
        .eq('id', id)
        .eq('post_kind', 'devotional')
        .maybeSingle();
    return row == null ? null : Map<String, dynamic>.from(row);
  }

  Future<List<Map<String, dynamic>>> comments(String id,
      {int offset = 0, int limit = 20}) async {
    final rows = await client
        .from('comments')
        .select('id,body,created_at,created_by,"commentor name"')
        .eq('post_id', id)
        .eq('is_deleted', false)
        .order('created_at')
        .range(offset, offset + limit - 1);
    return (rows as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<Set<String>> myReactions(String id) async {
    final uid = client.auth.currentUser?.id;
    if (uid == null) return {};
    final rows = await client
        .from('post_reactions')
        .select('reaction_type')
        .eq('post_id', id)
        .eq('user_id', uid);
    return (rows as List)
        .map((e) => (e as Map)['reaction_type'].toString())
        .toSet();
  }

  Future<void> toggleReaction(String postId, String type, bool active) async {
    final uid = client.auth.currentUser!.id;
    if (active) {
      await client
          .from('post_reactions')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', uid)
          .eq('reaction_type', type);
    } else {
      await client
          .from('post_reactions')
          .insert({'post_id': postId, 'user_id': uid, 'reaction_type': type});
    }
  }

  Future<void> addComment(String postId, String body) =>
      client.from('comments').insert({'post_id': postId, 'body': body});
}
