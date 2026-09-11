import 'package:supabase_flutter/supabase_flutter.dart';

class PrayerRepository {
  PrayerRepository([SupabaseClient? client]) : client = client ?? Supabase.instance.client;
  final SupabaseClient client;

  Future<List<Map<String, dynamic>>> alerts() async {
    final rows = await client.from('prayer_alerts').select().order('local_time');
    return (rows as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> save({
    String? id,
    String scope = 'personal',
    required String title,
    String? description,
    required String timezone,
    required String localTime,
    required List<int> days,
    int? durationSeconds,
    String? audioUrl,
    String? audioTitle,
    String? audioSource,
    bool active = true,
    bool vibrationEnabled = true,
    int? snoozeMinutes,
    String? branchId,
    String? departmentId,
  }) async {
    final result = await client.rpc('save_prayer_alert', params: {
      'p_id': id,
      'p_scope': scope,
      'p_title': title,
      'p_description': description,
      'p_timezone': timezone,
      'p_local_time': localTime,
      'p_days_of_week': days,
      'p_starts_on': null,
      'p_ends_on': null,
      'p_duration_seconds': durationSeconds,
      'p_audio_url': audioUrl,
      'p_audio_title': audioTitle,
      'p_audio_source': audioSource,
      'p_push_title': title,
      'p_push_body': 'Prayer time',
      'p_is_active': active,
      'p_branch_id': branchId,
      'p_department_id': departmentId,
      'p_vibration_enabled': vibrationEnabled,
      'p_snooze_minutes': snoozeMinutes,
    });
    return Map<String, dynamic>.from(result as Map);
  }

  Future<void> setActive(String id, bool active, Map<String, dynamic> current) async {
    await save(
      id: id,
      scope: current['scope']?.toString() ?? 'personal',
      title: current['title']?.toString() ?? 'Prayer',
      description: current['description']?.toString(),
      timezone: current['timezone']?.toString() ?? 'Africa/Lagos',
      localTime: current['local_time']?.toString() ?? '06:00:00',
      days: ((current['days_of_week'] as List?) ?? const [1,2,3,4,5,6,7]).map((e) => e as int).toList(),
      durationSeconds: current['duration_seconds'] as int?,
      audioUrl: current['audio_url']?.toString(),
      audioTitle: current['audio_title']?.toString(),
      audioSource: current['audio_source']?.toString(),
      active: active,
      vibrationEnabled: current['vibration_enabled'] != false,
      snoozeMinutes: int.tryParse(current['snooze_minutes']?.toString() ?? ''),
      branchId: current['branch_id']?.toString(),
      departmentId: current['department_id']?.toString(),
    );
  }

  Future<void> delete(String id) => client.from('prayer_alerts').delete().eq('id', id);

  Future<Map<String, dynamic>> snoozeOccurrence(String occurrenceId, int minutes) async {
    final result = await client.rpc('snooze_prayer_alert_occurrence', params: {
      'p_occurrence_id': occurrenceId,
      'p_minutes': minutes,
    });
    return Map<String, dynamic>.from(result as Map);
  }

  Future<Map<String, dynamic>> startSession({String? alertId, String? occurrenceId, String source = 'app'}) async {
    final result = await client.rpc('start_prayer_session', params: {'p_prayer_alert_id': alertId, 'p_occurrence_id': occurrenceId, 'p_started_from': source});
    return Map<String, dynamic>.from(result as Map);
  }

  Future<Map<String, dynamic>?> activeSession() async {
    final result = await client.rpc('get_active_prayer_session');
    if (result is List && result.isNotEmpty) return Map<String, dynamic>.from(result.first as Map);
    return null;
  }

  Future<Map<String, dynamic>> endSession(String sessionId, {String status = 'completed'}) async {
    final result = await client.rpc('end_prayer_session', params: {'p_session_id': sessionId, 'p_completion_status': status});
    return Map<String, dynamic>.from(result as Map);
  }
  Future<List<Map<String,dynamic>>> creationScopes() async {
    final options=<Map<String,dynamic>>[{'scope':'personal','label':'Personal','branch_id':null,'department_id':null}];
    final role=(await client.rpc('churchmetric_role'))?.toString().toLowerCase()??'';
    final branch=(await client.rpc('churchmetric_branch_id'))?.toString();
    if(role=='globaladmin') options.add({'scope':'global','label':'Global church','branch_id':null,'department_id':null});
    if(role=='admin' && branch!=null) options.add({'scope':'branch','label':'My branch','branch_id':branch,'department_id':null});
    final leading=await client.rpc('community_departments',params:{'p_filter':'leading'});
    for(final item in (leading as List)){final d=Map<String,dynamic>.from(item as Map);options.add({'scope':'department','label':d['name']?.toString()??'Department','branch_id':d['branch_id']?.toString(),'department_id':d['department_id']?.toString()});}
    return options;
  }

}
