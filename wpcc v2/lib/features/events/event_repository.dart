import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/swr_cache.dart';

class EventRepository {
  EventRepository([SupabaseClient? client])
      : client = client ?? Supabase.instance.client;
  final SupabaseClient client;
  final cache = SwrCache.instance;

  Future<List<Map<String, dynamic>>> events(
          {String mode = 'upcoming',
          String type = 'all',
          int limit = 50,
          int offset = 0}) =>
      cache.get('events:list:$mode:$type:$limit:$offset', () async {
        final rows = await client.rpc('community_visible_events', params: {
          'p_mode': mode,
          'p_event_type': type,
          'p_limit': limit,
          'p_offset': offset,
        });
        return (rows as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      });

  Future<List<Map<String, dynamic>>> recurringEvents({int limit = 20}) =>
      cache.get('events:recurring:$limit', () async {
        final rows = await client
            .from('my_recurring_events')
            .select(
              'recurring_event_id,title,description,event_scope,source_table,'
              'branch_id,department_id,recurrence_type,day_of_week,'
              'week_of_month,day_of_month,month,start_time,end_time,'
              'featured_image,is_active,created_at',
            )
            .eq('is_active', true)
            .order('created_at', ascending: false)
            .limit(limit);
        return (rows as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      });

  Future<Map<String, dynamic>?> event(String id) =>
      cache.get('events:detail:$id', () async {
        final rows = await client
            .rpc('community_event_by_id', params: {'p_event_id': id});
        if (rows is List && rows.isNotEmpty) {
          return Map<String, dynamic>.from(rows.first as Map);
        }
        return null;
      });

  Future<Map<String, dynamic>?> meta(String eventId) =>
      cache.get('events:meta:$eventId', () async {
        final data = await client
            .rpc('community_event_meta', params: {'p_event_id': eventId});
        if (data is List && data.isNotEmpty) {
          return Map<String, dynamic>.from(data.first as Map);
        }
        if (data is Map) return Map<String, dynamic>.from(data);
        return null;
      });

  Future<List<Map<String, dynamic>>> attendance(String eventId) =>
      cache.get('events:attendance:$eventId', () async {
        final rows = await client
            .rpc('community_event_attendance', params: {'p_event_id': eventId});
        return (rows as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }, freshFor: const Duration(minutes: 1));

  Future<Map<String, dynamic>?> myAttendance(String eventId) =>
      cache.get('events:my-attendance:$eventId', () async {
        final uid = client.auth.currentUser?.id;
        if (uid == null) return null;
        final row = await client
            .from('attendance')
            .select('id,status,created_at,clockout')
            .eq('event_id', eventId)
            .eq('user_id', uid)
            .maybeSingle();
        return row == null ? null : Map<String, dynamic>.from(row);
      }, freshFor: const Duration(seconds: 30));

  Future<Map<String, dynamic>> checkInOrOut(String eventId) async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw StateError('Location permission is required for attendance.');
    }
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    final response =
        await client.functions.invoke('attendance-geofence', body: {
      'event_id': eventId,
      'latitude': position.latitude,
      'longitude': position.longitude,
    });
    if (response.status >= 400) {
      final data = response.data;
      throw StateError(data is Map
          ? data['message']?.toString() ?? 'Attendance failed.'
          : 'Attendance failed.');
    }
    cache.invalidate('events:');
    return Map<String, dynamic>.from(response.data as Map);
  }
}
