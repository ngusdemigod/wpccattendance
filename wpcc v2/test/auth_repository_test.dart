import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wpcc_community/features/auth/auth_repository.dart';

void main() {
  test('email token hash is exchanged for an authenticated session', () async {
    final client = SupabaseClient('https://example.supabase.co', 'test-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((request) async {
      expect(request.url.path, '/auth/v1/verify');
      expect(jsonDecode(request.body), containsPair('token_hash', 'test-email-hash'));
      expect(jsonDecode(request.body), containsPair('type', 'email'));
      return http.Response(jsonEncode({
        'access_token': 'test-access-token',
        'refresh_token': 'test-refresh-token',
        'token_type': 'bearer',
        'expires_in': 3600,
        'user': {
          'id': 'test-user',
          'app_metadata': {},
          'user_metadata': {},
          'aud': 'authenticated',
          'created_at': '2026-01-01T00:00:00Z',
        },
      }), 200);
    }));
    addTearDown(client.dispose);
    final repository = AuthRepository(client);
    await repository.verifyMagicLink('test-email-hash', 'email');
    expect(repository.session?.user.id, 'test-user');
  });

  test('invalid callbacks do not send a verification request', () async {
    final client = SupabaseClient('https://example.supabase.co', 'test-key',
        httpClient: MockClient((_) async {
      fail('Invalid callback must not reach the server');
    }));
    addTearDown(client.dispose);
    final repository = AuthRepository(client);
    await expectLater(repository.verifyMagicLink('', 'email'),
        throwsA(isA<AuthException>()));
    await expectLater(repository.verifyMagicLink('hash', 'recovery'),
        throwsA(isA<AuthException>()));
  });

  test('expired email links do not create a session', () async {
    final client = SupabaseClient('https://example.supabase.co', 'test-key',
        httpClient: MockClient((_) async => http.Response(
            '{"code":"otp_expired","msg":"Token has expired or is invalid"}',
            403)));
    addTearDown(client.dispose);
    final repository = AuthRepository(client);
    await expectLater(repository.verifyMagicLink('expired-hash', 'email'),
        throwsA(isA<AuthException>()));
    expect(repository.session, isNull);
  });
}

