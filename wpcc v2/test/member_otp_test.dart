import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wpcc_community/features/auth/auth_repository.dart';

void main() {
  test('three numeric digits are canonicalized without changing other codes',
      () {
    expect(normalizeMembershipCode(' 123 '), '0123');
    expect(normalizeMembershipCode('0123'), '0123');
    expect(normalizeMembershipCode('ABC'), 'ABC');
    expect(normalizeMembershipCode('12'), '12');
    expect(normalizeMembershipCode('12345'), '12345');
  });
  test('membership request and verification use the same prefixed identifier',
      () async {
    final client = SupabaseClient('https://example.test', 'test-key',
        httpClient: MockClient((request) async {
      expect(jsonDecode(request.body)['membership_code'], '0123');
      return http.Response('{}', 200,
          headers: {'content-type': 'application/json'});
    }));
    addTearDown(client.dispose);
    await AuthRepository(client).requestMemberOtp('123');
    await expectLater(AuthRepository(client).verifyMemberOtp('123', '123456'),
        throwsA(isA<AuthException>()));
  });

  test(
      'membership login requests an email code without redirect or email lookup in client',
      () async {
    final client = SupabaseClient('https://example.test', 'test-key',
        httpClient: MockClient((request) async {
      expect(request.url.path, '/functions/v1/send-email-otp');
      expect(jsonDecode(request.body), {'membership_code': 'WPCC-123'});
      return http.Response('{}', 200,
          headers: {'content-type': 'application/json'});
    }));
    addTearDown(client.dispose);
    await AuthRepository(client).requestMemberOtp(' WPCC-123 ');
  });
  test(
      'membership verification submits code and rejects an absent session token',
      () async {
    final client = SupabaseClient('https://example.test', 'test-key',
        httpClient: MockClient((request) async {
      expect(request.url.path, '/functions/v1/send-email-otp');
      expect(jsonDecode(request.body), {
        'action': 'verify',
        'membership_code': 'WPCC-123',
        'otp': '123456',
      });
      return http.Response('{}', 200,
          headers: {'content-type': 'application/json'});
    }));
    addTearDown(client.dispose);
    await expectLater(
        AuthRepository(client).verifyMemberOtp('WPCC-123', '123456'),
        throwsA(isA<AuthException>()));
    expect(client.auth.currentSession, isNull);
  });
}
