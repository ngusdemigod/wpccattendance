import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_config.dart';
import '../../core/services/swr_cache.dart';

class ProfileRepository {
  ProfileRepository([SupabaseClient? client])
      : client = client ?? Supabase.instance.client;
  final SupabaseClient client;
  final cache = SwrCache.instance;

  Future<Map<String, dynamic>?> profile() =>
      cache.get('profile:current', () async {
        final data = await client.rpc('current_my_profile');
        if (data is List && data.isNotEmpty) {
          return Map<String, dynamic>.from(data.first as Map);
        }
        if (data is Map) return Map<String, dynamic>.from(data);
        return null;
      });

  Future<void> checkConfirmationReward() async {
    await client.rpc('rewards_check_profile');
  }

  Future<void> saveConfirmation(Map<String, String> values) async {
    await client.rpc('community_save_profile_confirmation',
        params: {'p_details': values});
    cache.invalidate('profile:');
  }

  Future<Map<String, dynamic>> confirmationStatus() async =>
      Map<String, dynamic>.from(
          await client.rpc('community_profile_confirmation_status') as Map);

  Future<List<Map<String, dynamic>>> joinDirectory() async =>
      (await client.rpc('community_department_directory') as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

  Future<void> requestDepartment(String id) async {
    await client
        .rpc('community_request_department', params: {'p_department_id': id});
    cache.invalidate('departments:');
  }

  Future<List<Map<String, dynamic>>> classes() =>
      cache.get('profile:classes', () async {
        final data = await client.rpc('current_my_classes');
        return (data as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      });

  Future<void> updateAllowedDetails(
      {String? bio,
      String? occupation,
      String? address,
      String? phone,
      String? gender,
      String? maritalStatus,
      String? dateOfBirth}) async {
    final uid = client.auth.currentUser?.id;
    if (uid == null) throw StateError('Authentication required');
    final values = <String, dynamic>{
      if (bio != null) 'bio': bio,
      if (occupation != null) 'occupation': occupation,
      if (address != null) 'residential_address': address,
      if (phone != null) 'phone_number': phone,
      if (gender != null) 'gender': gender,
      if (maritalStatus != null) 'marital_status': maritalStatus,
      if (dateOfBirth != null)
        'date_of_birth': dateOfBirth.isEmpty ? null : dateOfBirth,
    };
    if (values.isNotEmpty) {
      // Returning the row detects missing records instead of reporting a false success.
      await client
          .from('profiles_priv_info')
          .update(values)
          .eq('id', uid)
          .select('id')
          .single();
    }
    cache.invalidate('profile:');
  }

  Future<String> uploadAvatar(PlatformFile file) async {
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      throw StateError('Selected image could not be read');
    }
    if (bytes.length > 5 * 1024 * 1024) {
      throw StateError('Choose an image smaller than 5 MB');
    }
    if (!{'jpg', 'jpeg', 'png', 'webp'}
        .contains(file.extension?.toLowerCase())) {
      throw StateError('Choose a JPG, PNG, or WebP image');
    }
    if (client.auth.currentSession?.isExpired == true) {
      await client.auth.refreshSession();
    }
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
    final response = await request.send().timeout(const Duration(seconds: 30));
    final body = await response.stream
        .bytesToString()
        .timeout(const Duration(seconds: 30));
    Map<String, dynamic> payload = {};
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) payload = Map<String, dynamic>.from(decoded);
    } catch (_) {
      throw StateError('Photo service is unavailable. Please try again.');
    }
    if (response.statusCode >= 400) {
      throw StateError(payload['error']?.toString() ?? 'Avatar upload failed');
    }
    final avatarUrl = payload['avatar_url']?.toString() ?? '';
    if (avatarUrl.isEmpty) throw StateError('Avatar URL was not returned');
    cache.invalidate('profile:');
    return avatarUrl;
  }
}
