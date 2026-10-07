import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/config/app_config.dart';
import 'core/services/cache_warmup.dart';
import 'core/services/swr_cache.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // DM Sans and Manrope ship in assets/, so google_fonts must resolve them from
  // the bundle. Without this, a variant that is not bundled would silently
  // download from fonts.gstatic.com while the screen is already showing.
  GoogleFonts.config.allowRuntimeFetching = false;
  // Local-only: reads the persisted session from storage (no network) and
  // wires auth listeners. Anything slower must not be awaited before runApp.
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
  SwrCache.instance.bind(Supabase.instance.client);
  runApp(const ProviderScope(child: WpccApp()));
  CacheWarmup.schedule();
}
