class AppConfig {
  const AppConfig._();

  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://pgpihzhvysbadrzjhvxw.supabase.co',
  );

  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_5YAfKwXF--agw-5Dil9uwA_4IAEarod',
  );

  static const appOrigin = String.fromEnvironment('APP_ORIGIN');
  static const vapidPublicKey = String.fromEnvironment('VAPID_PUBLIC_KEY');

  static String get loginRedirect {
    final configuredOrigin = appOrigin.trim().replaceFirst(RegExp(r'/+$'), '');
    if (configuredOrigin.isNotEmpty) return '$configuredOrigin/login';

    // Web builds can safely use their current origin when APP_ORIGIN was not
    // supplied. This keeps magic links on the same deployed app instead of
    // silently falling back to the Supabase project's Site URL.
    final current = Uri.base;
    if (current.scheme == 'http' || current.scheme == 'https') {
      return current
          .replace(path: '/login', query: null, fragment: null)
          .toString();
    }
    return '';
  }
}
