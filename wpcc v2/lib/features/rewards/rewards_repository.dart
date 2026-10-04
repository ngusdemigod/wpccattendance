import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class RewardsRepository {
  RewardsRepository([SupabaseClient? client])
      : client = client ?? Supabase.instance.client;
  final SupabaseClient client;
  String? _ticket;
  String? _session;
  Uri? _heartbeatUrl;
  int _expires = 0;
  bool _sending = false;

  Future<Map<String, dynamic>> summary() async =>
      Map<String, dynamic>.from(await client.rpc('rewards_my_summary') as Map);

  Future<int?> publicTotal(String userId) async {
    final rows = await client.rpc('rewards_public_totals', params: {
      'p_users': [userId]
    }) as List;
    return rows.isEmpty ? null : (rows.first['points_balance'] as num).toInt();
  }

  Future<void> checkSavedProfile() async {
    await client.rpc('rewards_check_profile');
  }

  // The server measures elapsed participation. No duration or points come from the app.
  Future<void> heartbeat(String sessionId) async {
    if (_sending || client.auth.currentUser == null) return;
    _sending = true;
    try {
      if (_session != sessionId ||
          _ticket == null ||
          DateTime.now().millisecondsSinceEpoch >= _expires - 30000) {
        final response = await client.functions.invoke('rewards-worker',
            body: {'action': 'prayer-ticket', 'session_id': sessionId});
        final data = Map<String, dynamic>.from(response.data as Map);
        if (data['eligible'] != true) return;
        final url = Uri.parse(data['heartbeat_url'] as String);
        if (url.scheme != 'https') {
          throw StateError('Invalid participation endpoint');
        }
        _heartbeatUrl = url;
        _ticket = data['ticket'] as String;
        _expires = (data['expires_at'] as num).toInt();
        _session = sessionId;
      }
      final response = await http
          .post(_heartbeatUrl!,
              headers: {
                'Authorization': 'Bearer $_ticket',
                'Content-Type': 'application/json',
              },
              body: jsonEncode({}))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 401) _ticket = null;
      if (response.statusCode != 200) {
        throw StateError('Participation update unavailable');
      }
    } finally {
      _sending = false;
    }
  }
}
