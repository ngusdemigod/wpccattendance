import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/config/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabasePublishableKey,
    // The send-otp Edge Function creates the magic link server-side, so this
    // client does not own a PKCE verifier. Supabase returns access/refresh
    // tokens in the callback URL and supabase_flutter restores that session.
    // Custom token_hash email links are verified by LoginPage instead.
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.implicit,
    ),
  );
  runApp(const ProviderScope(child: WpccApp()));
}
