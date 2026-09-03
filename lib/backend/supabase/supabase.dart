import 'package:supabase_flutter/supabase_flutter.dart';

export 'database/database.dart';
export 'storage/storage.dart';

const String _productionSupabaseUrl =
    'https://pgpihzhvysbadrzjhvxw.supabase.co';
const String _productionSupabasePublishableKey =
    'sb_publishable_5YAfKwXF--agw-5Dil9uwA_4IAEarod';

const String _configuredSupabaseUrl = String.fromEnvironment('SUPABASE_URL');
const String _configuredSupabasePublishableKey =
    String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

String _resolveSupabaseUrl() {
  if (_configuredSupabaseUrl.isNotEmpty) {
    return _configuredSupabaseUrl;
  }
  return _productionSupabaseUrl;
}

String _resolveSupabasePublishableKey() {
  if (_configuredSupabasePublishableKey.isNotEmpty) {
    return _configuredSupabasePublishableKey;
  }
  return _productionSupabasePublishableKey;
}

final String kSupabaseUrl = _resolveSupabaseUrl();
final String kSupabaseAnonKey = _resolveSupabasePublishableKey();

String supabaseFunctionUrl(String functionName) =>
    '$kSupabaseUrl/functions/v1/$functionName';

String appBaseRedirectUrl() => Uri.base.origin;

class SupaFlow {
  SupaFlow._();

  static SupaFlow? _instance;
  static SupaFlow get instance => _instance ??= SupaFlow._();

  final _supabase = Supabase.instance.client;
  static SupabaseClient get client => instance._supabase;

  static Future initialize() => Supabase.initialize(
        url: kSupabaseUrl,
        headers: {
          'X-Client-Info': 'flutterflow',
        },
        anonKey: kSupabaseAnonKey,
        debug: false,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
          autoRefreshToken: true,
          detectSessionInUri: true,
        ),
      );
}
