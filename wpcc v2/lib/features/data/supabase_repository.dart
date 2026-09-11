import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseRepository {
  SupabaseRepository([SupabaseClient? client]) : client = client ?? Supabase.instance.client;
  final SupabaseClient client;

  Future<Map<String, dynamic>?> currentProfile() async {
    final data = await client.rpc('current_my_profile');
    if (data is List && data.isNotEmpty) return Map<String, dynamic>.from(data.first as Map);
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }

  Future<List<Map<String, dynamic>>> departments({String filter = 'mine'}) async {
    final rows = await client.rpc('community_departments', params: {'p_filter': filter});
    return (rows as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> myDepartments() => departments(filter: 'mine');

  Future<List<Map<String, dynamic>>> upcomingEvents({int limit = 5}) async {
    final rows = await client.rpc('community_visible_events', params: {
      'p_mode': 'upcoming',
      'p_event_type': 'all',
      'p_limit': limit,
      'p_offset': 0,
    });
    return (rows as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> announcements({int limit = 10}) async {
    final rows = await client.from('my_announcements').select().order('created_at', ascending: false).limit(limit);
    return (rows as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
}
