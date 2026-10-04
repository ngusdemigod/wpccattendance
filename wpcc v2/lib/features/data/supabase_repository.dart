import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/swr_cache.dart';

class SupabaseRepository {
  SupabaseRepository([SupabaseClient? client])
      : client = client ?? Supabase.instance.client;
  final SupabaseClient client;
  final cache = SwrCache.instance;

  Future<Map<String, dynamic>?> currentProfile() =>
      cache.get('profile:current', () async {
        final data = await client.rpc('current_my_profile');
        if (data is List && data.isNotEmpty)
          return Map<String, dynamic>.from(data.first as Map);
        if (data is Map) return Map<String, dynamic>.from(data);
        return null;
      });

  Future<List<Map<String, dynamic>>> departments({String filter = 'mine'}) =>
      cache.get('departments:$filter', () async {
        final rows = await client
            .rpc('community_departments', params: {'p_filter': filter});
        return (rows as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      });

  Future<List<Map<String, dynamic>>> myDepartments() async {
    final members = await departments(filter: 'mine');
    final uid = client.auth.currentUser?.id;
    if (uid == null) return members;
    final pending = await client
        .from('department_requests')
        .select('id,department_id,status,departments(name)')
        .eq('user_id', uid)
        .eq('status', 'pending');
    return [
      ...members,
      ...pending.map((row) => <String, dynamic>{
            'department_id': row['department_id'],
            'name': (row['departments'] as Map?)?['name'] ?? 'Department',
            'status': 'pending',
          })
    ];
  }

  Future<List<Map<String, dynamic>>> departmentDirectory() async {
    final rows = await client.rpc('community_department_directory');
    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  Future<void> requestDepartment(String departmentId) async {
    await client.rpc('community_request_department',
        params: {'p_department_id': departmentId});
    cache.invalidate('departments:');
  }

  Future<List<Map<String, dynamic>>> upcomingEvents({int limit = 5}) =>
      cache.get('events:upcoming:$limit', () async {
        final rows = await client.rpc('community_visible_events', params: {
          'p_mode': 'upcoming',
          'p_event_type': 'all',
          'p_limit': limit,
          'p_offset': 0,
        });
        return (rows as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      });

  Future<List<Map<String, dynamic>>> announcements({int limit = 10}) =>
      cache.get('announcements:$limit', () async {
        final rows = await client
            .from('my_announcements')
            .select()
            .order('created_at', ascending: false)
            .limit(limit);
        return (rows as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      });
}
