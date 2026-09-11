import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_config.dart';

class AuthRepository {
  AuthRepository([SupabaseClient? client]) : client = client ?? Supabase.instance.client;
  final SupabaseClient client;

  Stream<AuthState> get changes => client.auth.onAuthStateChange;
  Session? get session => client.auth.currentSession;

  Future<void> verifyMagicLink(String tokenHash, String? type) async {
    if (tokenHash.trim().isEmpty || type != 'email') {
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

  Future<String?> requestMemberMagicLink(String membershipCode) async {
    final body = <String, dynamic>{'membership_code': membershipCode.trim()};
    if (AppConfig.loginRedirect.isNotEmpty) body['redirect_to'] = AppConfig.loginRedirect;
    final response = await client.functions.invoke('send-otp', body: body);
    if (response.status >= 400) throw AuthException((response.data as Map?)?['error']?.toString() ?? 'Unable to send sign in link');
    return (response.data as Map?)?['email_masked']?.toString();
  }

  Future<void> signOut() => client.auth.signOut();
}
