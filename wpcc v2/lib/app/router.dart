import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/widgets/feature_gap_page.dart';
import '../features/auth/login_page.dart';
import '../features/departments/admin/department_announcement_page.dart';
import '../features/departments/admin/department_create_event_page.dart';
import '../features/departments/admin/department_manage_files_page.dart';
import '../features/departments/admin/department_profile_edit_page.dart';
import '../features/departments/admin/department_wallet_page.dart';
import '../features/departments/department_detail_page.dart';
import '../features/departments/departments_page.dart';
import '../features/devotional/devotional_page.dart';
import '../features/devotional/devotional_post_page.dart';
import '../features/events/event_detail_page.dart';
import '../features/events/events_page.dart';
import '../features/give/auto_give_page.dart';
import '../features/give/give_home_page.dart';
import '../features/give/give_payment_page.dart';
import '../features/give/give_result_page.dart';
import '../features/give/giving_history_page.dart';
import '../features/home/home_page.dart';
import '../features/media/media_page.dart';
import '../features/prayer/prayer_alert_edit_page.dart';
import '../features/prayer/prayer_alerts_page.dart';
import '../features/prayer/prayer_session_page.dart';
import '../features/profile/classes_page.dart';
import '../features/profile/profile_page.dart';
import '../features/profile/query_page.dart';
import '../features/search/search_page.dart';
import 'app_shell.dart';

class AuthRefreshListenable extends ChangeNotifier {
  AuthRefreshListenable() {
    _subscription = Supabase.instance.client.auth.onAuthStateChange.listen((_) => notifyListeners());
  }
  late final StreamSubscription<AuthState> _subscription;
  @override void dispose() { _subscription.cancel(); super.dispose(); }
}

GoRouter buildRouter() {
  final authRefresh = AuthRefreshListenable();
  // Email links use a path/query URL even when Flutter uses hash routing.
  final emailCallback = Uri.base.path == '/login' &&
      Uri.base.queryParameters.containsKey('token_hash');
  return GoRouter(
    initialLocation: emailCallback ? '/login?${Uri.base.query}' : '/home',
    overridePlatformDefaultLocation: emailCallback,
    refreshListenable: authRefresh,
    redirect: (context, state) {
      final authenticated = Supabase.instance.client.auth.currentSession != null;
      final atLogin = state.matchedLocation == '/login';
      if (!authenticated && !atLogin) return '/login';
      if (authenticated && atLogin) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, state) => LoginPage(
        key: ValueKey(state.uri.toString()),
        tokenHash: state.uri.queryParameters['token_hash'],
        linkType: state.uri.queryParameters['type'],
      )),
      ShellRoute(
        builder: (_, __, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/home', pageBuilder: (_, state) => _fade(state, const HomePage())),
          GoRoute(path: '/media', pageBuilder: (_, state) => _fade(state, const MediaPage())),
          GoRoute(path: '/departments', pageBuilder: (_, state) => _fade(state, const DepartmentsPage())),
          GoRoute(path: '/events', pageBuilder: (_, state) => _fade(state, const EventsPage())),
          GoRoute(path: '/give', pageBuilder: (_, state) => _fade(state, const GiveHomePage())),
          GoRoute(path: '/profile', pageBuilder: (_, state) => _fade(state, const ProfilePage())),
        ],
      ),
      GoRoute(path: '/departments/:id', pageBuilder: (_, state) => _slide(state, DepartmentDetailPage(departmentId: state.pathParameters['id']!, seed: state.extra as Map<String, dynamic>?))),
      GoRoute(path: '/departments/:id/wallet/new', pageBuilder: (_, state) => _slide(state, DepartmentWalletPage(departmentId: state.pathParameters['id']!))),
      GoRoute(path: '/departments/:id/profile/edit', pageBuilder: (_, state) => _slide(state, DepartmentProfileEditPage(departmentId: state.pathParameters['id']!))),
      GoRoute(path: '/departments/:id/event/new', pageBuilder: (_, state) => _slide(state, DepartmentCreateEventPage(departmentId: state.pathParameters['id']!))),
      GoRoute(path: '/departments/:id/announcement', pageBuilder: (_, state) => _slide(state, DepartmentAnnouncementPage(departmentId: state.pathParameters['id']!))),
      GoRoute(path: '/departments/:id/files/manage', pageBuilder: (_, state) => _slide(state, DepartmentManageFilesPage(departmentId: state.pathParameters['id']!))),
      GoRoute(path: '/events/:id', pageBuilder: (_, state) => _slide(state, EventDetailPage(eventId: state.pathParameters['id']!, seed: state.extra as Map<String,dynamic>?))),
      GoRoute(path: '/give/payment', pageBuilder: (_, state) => _slide(state, GivePaymentPage(payload: Map<String,dynamic>.from((state.extra as Map?) ?? const {'giving_type':'offering','title':'Give'})))),
      GoRoute(path: '/give/auto', pageBuilder: (_, state) => _slide(state, const AutoGivePage())),
      GoRoute(path: '/give/history', pageBuilder: (_, state) => _slide(state, const GivingHistoryPage())),
      GoRoute(path: '/give/result', pageBuilder: (_, state) => _fade(state, GiveResultPage(reference: state.uri.queryParameters['reference'] ?? ''))),
      GoRoute(path: '/prayer-alerts', pageBuilder: (_, state) => _slide(state, const PrayerAlertsPage())),
      GoRoute(path: '/prayer-alerts/new', pageBuilder: (_, state) => _slide(state, const PrayerAlertEditPage())),
      GoRoute(path: '/prayer-alerts/:id/edit', pageBuilder: (_, state) => _slide(state, PrayerAlertEditPage(alertId: state.pathParameters['id']!, alert: state.extra as Map<String, dynamic>?))),
      GoRoute(path: '/prayer-session', pageBuilder: (_, state) => CustomTransitionPage(key: state.pageKey, fullscreenDialog: true, transitionDuration: const Duration(milliseconds: 260), child: PrayerSessionPage(payload: Map<String, dynamic>.from((state.extra as Map?) ?? const {})), transitionsBuilder: (context, animation, __, child) => MediaQuery.disableAnimationsOf(context) ? child : FadeTransition(opacity: animation, child: child))),
      GoRoute(path: '/search', pageBuilder: (_, state) => _slide(state, const SearchPage())),
      GoRoute(path: '/devotional', pageBuilder: (_, state) => _slide(state, const DevotionalPage())),
      GoRoute(path: '/devotional/:id', pageBuilder: (_, state) => _slide(state, DevotionalPostPage(postId: state.pathParameters['id']!, seed: state.extra as Map<String,dynamic>?))),
      GoRoute(path: '/profile/classes', pageBuilder: (_, state) => _slide(state, const ClassesPage())),
      GoRoute(path: '/profile/query', pageBuilder: (_, state) => _slide(state, const QueryPage())),
      GoRoute(path: '/souls', pageBuilder: (_, state) => _slide(state, const FeatureGapPage(title: 'Souls', message: 'The v76 package defines the Souls entry point but no approved member-facing target-page design. The existing souls and follow-up backend is preserved for a separate approved screen.'))),
      GoRoute(path: '/counselling', pageBuilder: (_, state) => _slide(state, const FeatureGapPage(title: 'Counselling', message: 'The v76 package defines the Counselling entry point but no approved target-page design. Existing enquiry data remains untouched until that screen is approved.'))),
    ],
  );
}

CustomTransitionPage<void> _fade(GoRouterState state, Widget child) => CustomTransitionPage(
  key: state.pageKey,
  transitionDuration: const Duration(milliseconds: 210),
  reverseTransitionDuration: const Duration(milliseconds: 190),
  child: child,
  transitionsBuilder: (context, animation, __, child) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return FadeTransition(opacity: animation, child: SlideTransition(position: Tween(begin: const Offset(0,.018), end: Offset.zero).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)), child: child));
  },
);

CustomTransitionPage<void> _slide(GoRouterState state, Widget child) => CustomTransitionPage(
  key: state.pageKey,
  transitionDuration: const Duration(milliseconds: 210),
  reverseTransitionDuration: const Duration(milliseconds: 190),
  child: child,
  transitionsBuilder: (context, animation, __, child) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return FadeTransition(opacity: animation, child: SlideTransition(position: Tween(begin: const Offset(.025,0), end: Offset.zero).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)), child: child));
  },
);
