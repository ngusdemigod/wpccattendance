import 'package:supabase_flutter/supabase_flutter.dart';

class SoulsRepository {
  SoulsRepository([SupabaseClient? client])
      : client = client ?? Supabase.instance.client;

  final SupabaseClient client;

  String get userId {
    final id = client.auth.currentUser?.id;
    if (id == null) throw StateError('Sign in to manage souls.');
    return id;
  }

  Future<List<Map<String, dynamic>>> mine() async {
    final rows = await client
        .from('souls')
        .select('id,branch_id,evangelism_event_id,full_name,email,phone,status,'
            'won_at,created_at,location,evangelist_name')
        .eq('recorded_by', userId)
        .order('won_at', ascending: false);
    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  Future<Map<String, dynamic>?> byId(String id) async {
    final row = await client
        .from('souls')
        .select('id,branch_id,evangelism_event_id,full_name,email,phone,status,'
            'won_at,created_at,location,evangelist_name')
        .eq('id', id)
        .eq('recorded_by', userId)
        .maybeSingle();
    return row == null ? null : Map<String, dynamic>.from(row);
  }

  Future<List<Map<String, dynamic>>> evangelismEvents() async {
    final profile = await client
        .from('profiles')
        .select('branch_id')
        .eq('id', userId)
        .maybeSingle();
    final branchId = profile?['branch_id']?.toString();
    if (branchId == null || branchId.isEmpty) return [];
    final rows = await client
        .from('evangelism_events')
        .select('id,branch_id,title,starts_at,status')
        .eq('branch_id', branchId)
        .order('starts_at', ascending: false);
    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  Future<void> add({
    required String eventId,
    required String fullName,
    String? email,
    String? phone,
    String? location,
  }) async {
    final event = await client
        .from('evangelism_events')
        .select('id,branch_id')
        .eq('id', eventId)
        .single();
    await client.from('souls').insert({
      'branch_id': event['branch_id'],
      'evangelism_event_id': eventId,
      'recorded_by': userId,
      'full_name': fullName.trim(),
      'email': _optional(email),
      'phone': _optional(phone),
      'location': _optional(location),
    });
  }

  String? _optional(String? value) {
    final clean = value?.trim() ?? '';
    return clean.isEmpty ? null : clean;
  }
}
