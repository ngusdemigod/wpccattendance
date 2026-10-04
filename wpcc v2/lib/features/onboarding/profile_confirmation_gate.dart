import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_confirmation_page.dart';

/// A restored session is not a fresh sign-in. Token refresh must not restart the flow.
class FreshLoginTracker {
  FreshLoginTracker(this.userId);
  String? userId;
  bool update(String? next) {
    final fresh = next != null && next != userId;
    userId = next;
    return fresh;
  }
}

class ProfileConfirmationGate extends StatefulWidget {
  const ProfileConfirmationGate({super.key, required this.child});
  final Widget child;
  @override
  State<ProfileConfirmationGate> createState() =>
      _ProfileConfirmationGateState();
}

class _ProfileConfirmationGateState extends State<ProfileConfirmationGate> {
  late final client = Supabase.instance.client;
  late final FreshLoginTracker tracker;
  StreamSubscription<AuthState>? subscription;
  String? confirming;
  @override
  void initState() {
    super.initState();
    tracker = FreshLoginTracker(client.auth.currentUser?.id);
    subscription = client.auth.onAuthStateChange.listen((state) {
      final id = state.session?.user.id;
      final fresh = tracker.update(id);
      if (!mounted) return;
      if (id == null || fresh) setState(() => confirming = fresh ? id : null);
    });
  }

  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => confirming == null
      ? widget.child
      : ProfileConfirmationFlow(
          key: ValueKey(confirming),
          builder: (_) => ProfileConfirmationPage(
              onFinish: () => setState(() => confirming = null)));
}

/// The confirmation gate is installed in MaterialApp.builder, above the router.
/// Give its fields, tooltips and modal dialogs their own Navigator/Overlay.
class ProfileConfirmationFlow extends StatelessWidget {
  const ProfileConfirmationFlow({super.key, required this.builder});
  final WidgetBuilder builder;
  @override
  Widget build(BuildContext context) => Navigator(
      onGenerateRoute: (_) => MaterialPageRoute<void>(builder: builder));
}
