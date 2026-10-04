import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wpcc_community/features/auth/auth_repository.dart';
import 'package:wpcc_community/features/auth/login_page.dart';
import 'package:wpcc_community/features/give/give_home_page.dart';
import 'package:wpcc_community/core/theme/app_theme.dart';

void main() {
  testWidgets('password mode offers one sign-in action and code fallback',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.tap(find.text('Sign in with password'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('Enter your password'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Use Membership Code'), findsOneWidget);
    expect(find.text('Use password'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  test('password login normalizes email and preserves password', () async {
    final client = SupabaseClient('https://example.supabase.co', 'test-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((request) async {
      expect(request.url.queryParameters['grant_type'], 'password');
      final body = jsonDecode(request.body) as Map;
      expect(body['email'], 'member@example.com');
      expect(body['password'], ' password with spaces ');
      return http.Response(
          jsonEncode({
            'access_token': 'test',
            'refresh_token': 'test',
            'token_type': 'bearer',
            'expires_in': 3600,
            'user': {
              'id': 'member',
              'aud': 'authenticated',
              'app_metadata': {},
              'user_metadata': {},
              'created_at': '2026-01-01T00:00:00Z'
            }
          }),
          200);
    }));
    addTearDown(client.dispose);
    await AuthRepository(client)
        .signInWithPassword(' Member@Example.com ', ' password with spaces ');
    expect(client.auth.currentUser?.id, 'member');
  });
  test('theme preference persists across reloads', () async {
    SharedPreferences.setMockInitialValues({});
    await ThemePreference.instance.select(ThemeMode.dark);
    ThemePreference.instance.value = ThemeMode.light;
    await ThemePreference.instance.load();
    expect(ThemePreference.instance.value, ThemeMode.dark);
  });
  testWidgets('all accounts are reachable by vertical scrolling on mobile',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: GiveHomePage(
      loadAccounts: () async => [
        for (var i = 0; i < 3; i++)
          {
            'account_number': '123456789$i',
            'bank_name': 'Bank',
            'wallet_name': 'Account $i',
            'purpose': 'Purpose $i',
            'account_name': 'WPCC'
          }
      ],
      loadMandates: () async => [],
      loadProjects: () async => [],
    ))));
    // Offscreen lazily laid-out loading indicators need not settle before scrolling.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Purpose 0'), findsOneWidget);
    final pageScroll = find
        .descendant(
            of: find.byType(ListView).first, matching: find.byType(Scrollable))
        .first;
    await tester.scrollUntilVisible(find.text('Purpose 2'), 200,
        scrollable: pageScroll);
    expect(find.text('Purpose 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
