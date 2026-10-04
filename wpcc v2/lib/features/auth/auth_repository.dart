import 'package:supabase_flutter/supabase_flutter.dart';

String normalizeMembershipCode(String value) {
  final code = value.trim();
  return RegExp(r'^\d{3}$').hasMatch(code) ? '0$code' : code;
}

class AuthRepository {
  AuthRepository([SupabaseClient? client])
      : client = client ?? Supabase.instance.client;
  final SupabaseClient client;

  Stream<AuthState> get changes => client.auth.onAuthStateChange;
  Session? get session => client.auth.currentSession;

  Future<void> verifyMagicLink(String tokenHash, String? type) async {
    final normalizedType = type?.trim().toLowerCase();
    if (tokenHash.trim().isEmpty ||
        (normalizedType != null &&
            normalizedType != 'email' &&
            normalizedType != 'magiclink')) {
      throw const AuthException('Invalid sign in link');
    }
    final response = await client.auth.verifyOTP(
      tokenHash: tokenHash,
      type: OtpType.email,
    );
    if (response.session == null) {
      throw const AuthException('No session returned for sign in link');
    }
  }

  Future<void> requestMemberOtp(String membershipCode) async {
    final response = await client.functions.invoke('send-email-otp',
        body: {'membership_code': normalizeMembershipCode(membershipCode)});
    if (response.status >= 400) {
      throw const AuthException('Unable to send verification code');
    }
  }

  Future<void> verifyMemberOtp(String membershipCode, String code) async {
    final response = await client.functions.invoke('send-email-otp', body: {
      'action': 'verify',
      'membership_code': normalizeMembershipCode(membershipCode),
      'otp': code.trim(),
    });
    final token = (response.data as Map?)?['refresh_token'];
    if (response.status >= 400 || token is! String || token.isEmpty) {
      throw const AuthException('Invalid or expired code');
    }
    final auth = await client.auth.setSession(token);
    if (auth.session == null) {
      throw const AuthException('Unable to establish session');
    }
  }

  Future<void> requestEmailOtp(String email) async {
    final response = await client.functions.invoke(
      'send-email-otp',
      body: {'email': email.trim().toLowerCase()},
    );
    if (response.status >= 400) {
      throw AuthException((response.data as Map?)?['error']?.toString() ??
          'Unable to send verification code');
    }
  }

  Future<void> verifyEmailOtp(String email, String code) async {
    final response = await client.auth.verifyOTP(
      email: email.trim().toLowerCase(),
      token: code.trim(),
      type: OtpType.email,
    );
    if (response.session == null) {
      throw const AuthException('Invalid or expired code');
    }
  }

  Future<void> signInWithPassword(String email, String password) async {
    final response = await client.auth.signInWithPassword(
        email: email.trim().toLowerCase(), password: password);
    if (response.session == null) {
      throw const AuthException('Unable to sign in');
    }
  }

  Future<void> setPassword(String password) async {
    await client.auth.updateUser(UserAttributes(password: password));
  }

  Future<void> signOut() => client.auth.signOut();
}
