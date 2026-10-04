import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '/auth/auth_manager.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/features/profile/profile_identity_resolver.dart';
import 'email_auth.dart';
import 'google_auth.dart';

import 'supabase_user_provider.dart';

export '/auth/base_auth_user_provider.dart';

class SupabaseAuthManager extends AuthManager
    with EmailSignInManager, GoogleSignInManager {
  @override
  Future signOut() {
    currentUser = null;
    ProfileIdentityResolver.clearCache();
    return SupaFlow.client.auth.signOut();
  }

  @override
  Future deleteUser(BuildContext context) async {
    try {
      if (!loggedIn) {
        debugPrint('Error: delete user attempted with no logged in user!');
        return;
      }
      await currentUser?.delete();
    } on AuthException catch (e) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.message}')),
      );
    }
  }

  @override
  Future updateEmail({
    required String email,
    required BuildContext context,
  }) async {
    try {
      if (!loggedIn) {
        debugPrint('Error: update email attempted with no logged in user!');
        return;
      }
      await currentUser?.updateEmail(email);
      if (!context.mounted) {
        return;
      }
    } on AuthException catch (e) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.message}')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Email change confirmation email sent')),
    );
  }

  Future updatePassword({
    required String newPassword,
    required BuildContext context,
  }) async {
    try {
      if (!loggedIn) {
        debugPrint('Error: update password attempted with no logged in user!');
        return;
      }
      await currentUser?.updatePassword(newPassword);
      if (!context.mounted) {
        return;
      }
    } on AuthException catch (e) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.message}')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password updated successfully')),
    );
  }

  @override
  Future resetPassword({
    required String email,
    required BuildContext context,
    String? redirectTo,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(supabaseFunctionUrl('Passwordreset_email')),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $kSupabaseAnonKey',
          'apikey': kSupabaseAnonKey,
        },
        body: jsonEncode(<String, String>{
          'email': email,
          if (redirectTo != null && redirectTo.trim().isNotEmpty)
            'redirectTo': redirectTo.trim(),
        }),
      );

      if (response.statusCode != 200) {
        throw FormatException(
          response.body.isNotEmpty
              ? response.body
              : 'Unable to send password reset email.',
        );
      }
    } on AuthException catch (e) {
      if (!context.mounted) {
        return null;
      }
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.message}')),
      );
      return null;
    } on FormatException catch (e) {
      if (!context.mounted) {
        return null;
      }
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
      return null;
    }
    if (!context.mounted) {
      return null;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password reset email sent')),
    );
  }

  @override
  Future<BaseAuthUser?> signInWithEmail(
    BuildContext context,
    String email,
    String password,
  ) =>
      _signInOrCreateAccount(
        context,
        () => emailSignInFunc(email, password),
      );

  @override
  Future<BaseAuthUser?> createAccountWithEmail(
    BuildContext context,
    String email,
    String password,
  ) =>
      _signInOrCreateAccount(
        context,
        () => emailCreateAccountFunc(email, password),
      );

  @override
  Future<BaseAuthUser?> signInWithGoogle(BuildContext context) =>
      _signInOrCreateAccount(context, googleSignInFunc);

  /// Tries to sign in or create an account using Supabase Auth.
  /// Returns the User object if sign in was successful.
  Future<BaseAuthUser?> _signInOrCreateAccount(
    BuildContext context,
    Future<User?> Function() signInFunc,
  ) async {
    try {
      final user = await signInFunc();
      final authUser = user == null ? null : AttendamceSupabaseUser(user);

      // Update currentUser here in case user info needs to be used immediately
      // after a user is signed in. This should be handled by the user stream,
      // but adding here too in case of a race condition where the user stream
      // doesn't assign the currentUser in time.
      if (authUser != null) {
        currentUser = authUser;
        AppStateNotifier.instance.update(authUser);
      }
      return authUser;
    } on AuthException catch (e) {
      final errorMsg = e.message.contains('User already registered')
          ? 'Error: The email is already in use by a different account'
          : 'Error: ${e.message}';
      if (!context.mounted) {
        return null;
      }
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg)),
      );
      return null;
    }
  }
}
