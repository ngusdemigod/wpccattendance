import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_config.dart';

class ProfileRepository {
  ProfileRepository([SupabaseClient? client])
      : client = client ?? Supabase.instance.client;
  final SupabaseClient client;

  Future<Map<String, dynamic>?> profile() async {
    final data = await client.rpc('current_my_profile');
    if (data is List && data.isNotEmpty) {
      return Map<String, dynamic>.from(data.first as Map);
    }
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }

  Future<List<Map<String, dynamic>>> classes() async {
    final data = await client.rpc('current_my_classes');
    return (data as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<void> updateAllowedDetails(
      {String? bio, String? occupation, String? address}) async {
    final uid = client.auth.currentUser?.id;
    if (uid == null) throw StateError('Authentication required');
    if (bio != null) {
      await client.from('profiles').update({'bio': bio}).eq('id', uid);
    }
    final values = <String, dynamic>{};
    if (occupation != null) values['occupation'] = occupation;
    if (address != null) values['residential_address'] = address;
    if (values.isNotEmpty) {
      await client.from('profiles_priv_info').update(values).eq('id', uid);
    }
  }

  Future<String> uploadAvatar(PlatformFile file) async {
    final bytes = file.bytes;
    if (bytes == null) throw StateError('Selected image could not be read');
    final token = client.auth.currentSession?.accessToken;
    if (token == null) throw StateError('Authentication required');
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${AppConfig.supabaseUrl}/functions/v1/profile-avatar'),
    )
      ..headers['Authorization'] = 'Bearer $token'
      ..headers['apikey'] = AppConfig.supabasePublishableKey
      ..files.add(
          http.MultipartFile.fromBytes('file', bytes, filename: file.name));
    final response = await request.send();
    final body = await response.stream.bytesToString();
    final payload = body.isEmpty
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(jsonDecode(body) as Map);
    if (response.statusCode >= 400) {
      throw StateError(payload['error']?.toString() ?? 'Avatar upload failed');
    }
    final avatarUrl = payload['avatar_url']?.toString() ?? '';
    if (avatarUrl.isEmpty) throw StateError('Avatar URL was not returned');
    return avatarUrl;
  }
}
