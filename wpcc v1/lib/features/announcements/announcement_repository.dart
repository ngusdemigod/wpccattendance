import '../../auth/supabase_auth/auth_util.dart';
import '../../backend/supabase/supabase.dart';
import '../../backend/supabase/database/database.dart';
import '../home/home_feed_models.dart';

class AnnouncementRepository {
  Future<List<HomeAnnouncement>> fetchHomeAnnouncements({
    int limit = 4,
  }) async {
    final rows = await SupaFlow.client
        .from('my_announcements')
        .select()
        .order('scope_priority', ascending: true)
        .order('created_at', ascending: false)
        .limit(limit);
    return (rows as List)
        .map((row) => HomeAnnouncement.fromMap(Map<String, dynamic>.from(row)))
        .where((item) => item.id.isNotEmpty)
        .toList(growable: false);
  }

  Future<HomeAnnouncement?> fetchAnnouncementById(String announcementId) async {
    final rows = await SupaFlow.client
        .from('my_announcements')
        .select()
        .eq('id', announcementId)
        .limit(1);
    if ((rows as List).isEmpty) {
      return null;
    }
    return HomeAnnouncement.fromMap(Map<String, dynamic>.from(rows.first));
  }

  Future<void> acknowledgeAnnouncement(String announcementId) async {
    if (currentUserUid.isEmpty) {
      return;
    }
    try {
      await SupaFlow.client.from('announcement_acknowledgements').insert({
        'announcement_id': announcementId,
        'user_id': currentUserUid,
      });
    } catch (error) {
      final message = error.toString().toLowerCase();
      if (message.contains('duplicate') || message.contains('unique')) {
        return;
      }
      rethrow;
    }
  }

  Future<List<AnnouncementComment>> fetchComments(String announcementId) async {
    final rows = await SupaFlow.client
        .from('announcement_comments')
        .select('id, user_id, body, created_at')
        .eq('announcement_id', announcementId)
        .eq('is_deleted', false)
        .order('created_at', ascending: true);
    final commentRows = (rows as List)
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);
    final userIds = commentRows
        .map((row) => row['user_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    final namesById = <String, String>{};
    if (userIds.isNotEmpty) {
      final profiles = await ProfilesTable().queryRows(
        queryFn: (q) => q.inFilter('id', userIds),
      );
      for (final profile in profiles) {
        final id = profile.id?.trim() ?? '';
        if (id.isEmpty) {
          continue;
        }
        namesById[id] = profile.fullName;
      }
    }
    return commentRows
        .map((row) => _commentFromMap(row, namesById))
        .toList(growable: false);
  }

  Future<void> createComment({
    required String announcementId,
    required String body,
  }) async {
    final trimmed = body.trim();
    if (trimmed.isEmpty || currentUserUid.isEmpty) {
      return;
    }
    await SupaFlow.client.from('announcement_comments').insert({
      'announcement_id': announcementId,
      'user_id': currentUserUid,
      'body': trimmed,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  AnnouncementComment _commentFromMap(
    Map<String, dynamic> row,
    Map<String, String> namesById,
  ) {
    final userId = row['user_id']?.toString() ?? '';
    final fullName = namesById[userId] ?? 'Member';
    return AnnouncementComment(
      id: row['id']?.toString() ?? '',
      userId: userId,
      fullName: fullName,
      body: row['body']?.toString() ?? '',
      createdAt: DateTime.tryParse(row['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
