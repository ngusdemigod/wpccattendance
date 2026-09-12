import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/swr_cache.dart';

class GiveRepository {
  GiveRepository([SupabaseClient? client])
      : client = client ?? Supabase.instance.client;
  final SupabaseClient client;
  final cache = SwrCache.instance;

  Future<List<Map<String, dynamic>>> accounts() =>
      cache.get('give:accounts', () async {
        final rows = await client
            .from('church_bank_accounts')
            .select(
                'id,scope,branch_id,department_id,wallet_name,bank_name,account_name,account_number,purpose,display_order,style_variant,bank_logo_url,bank_logo_object_key')
            .eq('is_active', true)
            .order('display_order');
        return (rows as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      });

  Future<List<Map<String, dynamic>>> projects() =>
      cache.get('give:projects', () async {
        final rows = await client
            .from('giving_projects')
            .select(
                'id,title,description,image_url,target_amount_kobo,scope,branch_id,department_id,starts_at,ends_at')
            .eq('status', 'active')
            .order('created_at', ascending: false);
        return (rows as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      });

  Future<List<Map<String, dynamic>>> history(
          {int limit = 50, int offset = 0}) =>
      cache.get('give:history:$limit:$offset', () async {
        final uid = client.auth.currentUser?.id;
        if (uid == null) return [];
        final rows = await client
            .from('giving_transactions')
            .select(
                'id,giving_type,project_id,amount_kobo,currency,internal_reference,paystack_reference,status,payment_channel,source_summary,receipt_type,initiated_at,paid_at,failed_at,created_at')
            .eq('profile_id', uid)
            .order('created_at', ascending: false)
            .range(offset, offset + limit - 1);
        return (rows as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }, freshFor: const Duration(minutes: 2));

  Future<Map<String, dynamic>?> transactionByReference(String reference) =>
      cache.get('give:transaction:$reference', () async {
        final uid = client.auth.currentUser?.id;
        if (uid == null) return null;
        final row = await client
            .from('giving_transactions')
            .select(
                'id,giving_type,project_id,amount_kobo,currency,internal_reference,paystack_reference,status,payment_channel,source_summary,receipt_type,initiated_at,paid_at,failed_at,created_at')
            .eq('profile_id', uid)
            .or('paystack_reference.eq.$reference,internal_reference.eq.$reference')
            .maybeSingle();
        return row == null ? null : Map<String, dynamic>.from(row);
      }, freshFor: const Duration(seconds: 30));

  Future<Map<String, dynamic>> initialize({
    required int amountKobo,
    required String givingType,
    String? projectId,
    Map<String, dynamic>? autoGive,
    String? appOrigin,
  }) async {
    final response = await client.functions.invoke('initialize-giving', body: {
      'amount_kobo': amountKobo,
      'giving_type': givingType,
      'project_id': projectId,
      if (appOrigin != null) 'app_origin': appOrigin,
      if (autoGive != null) 'auto_give': autoGive,
    });
    if (response.status >= 400) {
      throw StateError((response.data as Map?)?['error']?.toString() ??
          'Unable to start payment');
    }
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, List<Map<String, dynamic>>>> schedulableEvents() =>
      cache.get('give:schedulable-events', () async {
        final upcoming = await client.rpc('community_visible_events', params: {
          'p_mode': 'upcoming',
          'p_event_type': 'all',
          'p_limit': 60,
          'p_offset': 0,
        });
        final recurring = await client
            .from('my_recurring_events')
            .select(
                'recurring_event_id,title,recurrence_type,day_of_week,day_of_month,month,start_time')
            .eq('is_active', true)
            .order('created_at', ascending: false)
            .limit(40);
        List<Map<String, dynamic>> maps(Object? rows) => (rows as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        return {'upcoming': maps(upcoming), 'recurring': maps(recurring)};
      });

  Future<Map<String, dynamic>> verify(String reference) async {
    final response = await client.functions
        .invoke('verify-giving', body: {'reference': reference});
    if (response.status >= 400) {
      throw StateError((response.data as Map?)?['error']?.toString() ??
          'Unable to verify payment');
    }
    final payload = Map<String, dynamic>.from(response.data as Map);
    final tx = payload['transaction'];
    cache.invalidate('give:');
    if (tx is Map) return Map<String, dynamic>.from(tx);
    return payload;
  }

  Future<List<Map<String, dynamic>>> savedPaymentMethods() =>
      cache.get('give:payment-methods', () async {
        final rows = await client.rpc('my_saved_payment_methods');
        return (rows as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      });

  Future<Map<String, dynamic>> createMandate({
    required int amountKobo,
    required String givingType,
    String? projectId,
    required List<String> ruleKeys,
    required String authorizationId,
  }) async {
    final result = await client.rpc('create_auto_give_mandate', params: {
      'p_amount_kobo': amountKobo,
      'p_giving_type': givingType,
      'p_project_id': projectId,
      'p_rule_keys': ruleKeys,
      'p_authorization_id': authorizationId,
      'p_timezone': 'Africa/Lagos',
      'p_local_charge_time': '08:00:00',
    });
    cache.invalidate('give:');
    return Map<String, dynamic>.from(result as Map);
  }

  Future<List<Map<String, dynamic>>> mandates() =>
      cache.get('give:mandates', () async {
        final uid = client.auth.currentUser?.id;
        if (uid == null) return [];
        final rows = await client
            .from('recurring_giving_mandates')
            .select(
                'id,giving_type,project_id,amount_kobo,rule_keys,timezone,local_charge_time,status,next_charge_at,last_charge_at,consent_at,cancelled_at')
            .eq('profile_id', uid)
            .order('created_at', ascending: false);
        return (rows as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }, freshFor: const Duration(minutes: 2));

  Future<void> cancelMandate(String id) async {
    await client.rpc('cancel_auto_give_mandate', params: {'p_mandate_id': id});
    cache.invalidate('give:');
  }
}
