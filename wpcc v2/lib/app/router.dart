import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/auth/login_page.dart';
import '../features/departments/admin/department_announcement_page.dart';
import '../features/departments/admin/department_create_event_page.dart';
import '../features/departments/admin/department_manage_files_page.dart';
import '../features/departments/admin/department_profile_edit_page.dart';
import '../features/departments/admin/department_wallet_page.dart';
import '../features/departments/department_detail_page.dart';
import '../features/departments/admin/department_requests_page.dart';
import '../features/departments/departments_page.dart';
import '../features/departments/tools/department_tools_page.dart';
import '../features/devotional/devotional_page.dart';
import '../features/devotional/devotional_post_page.dart';
import '../features/events/event_detail_page.dart';
import '../features/events/events_page.dart';
import '../features/give/auto_give_page.dart';
import '../features/give/give_home_page.dart';
import '../features/give/give_payment_page.dart';
import '../features/give/give_result_page.dart';
import '../features/home/home_page.dart';
import '../features/reports/anonymous_reports_page.dart';
import '../features/media/media_page.dart';
import '../features/media/media_album_detail_page.dart';
import '../features/media/media_episode_detail_page.dart';
import '../features/media/media_video_page.dart';
import '../features/prayer/prayer_alert_edit_page.dart';
import '../features/prayer/prayer_alerts_page.dart';
import '../features/prayer/prayer_session_page.dart';
import '../features/profile/profile_page.dart';
import '../features/search/search_page.dart';
import '../features/search/search_filter_sheet.dart';
import '../features/souls/souls_page.dart';
import 'app_shell.dart';
import '../core/theme/member_theme.dart';
import '../core/theme/app_motion.dart';
import '../core/widgets/member_back.dart';

class AuthRefreshListenable extends ChangeNotifier {
  AuthRefreshListenable() {
    _subscription = Supabase.instance.client.auth.onAuthStateChange
        .listen((_) => notifyListeners());
  }
  late final StreamSubscription<AuthState> _subscription;
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

GoRouter buildRouter() {
  final authRefresh = AuthRefreshListenable();
  // Magic links can return either a token_hash query (custom template) or
  // access/refresh tokens in the URL fragment (Supabase implicit flow). The
  // fragment must never be treated as a GoRouter hash route.
  final callbackTokenHash = Uri.base.queryParameters['token_hash'] ??
      Uri.base.queryParameters['token'];
  // Self-hosted email templates may point at the configured Site URL (`/`)
  // instead of the requested `/login` redirect. A valid token query is the
  // authoritative callback signal regardless of the landing path.
  final emailCallback =
      callbackTokenHash != null && callbackTokenHash.isNotEmpty;
  final implicitAuthCallback = Uri.base.fragment.contains('access_token=') ||
      Uri.base.fragment.contains('refresh_token=');
  final authenticated = Supabase.instance.client.auth.currentSession != null;
  final initialLocation = emailCallback
      ? '/login?${Uri.base.query}'
      : authenticated
          ? '/home'
          : '/login';
  return GoRouter(
    initialLocation: initialLocation,
    // Flutter web uses the URL fragment for hash routing, while Supabase's
    // implicit flow uses it for credentials. Supabase restores the session
    // during initialize; always overriding prevents those credentials from
    // being parsed as an application route afterwards.
    overridePlatformDefaultLocation: emailCallback || implicitAuthCallback,
    refreshListenable: authRefresh,
    redirect: (context, state) {
      final authenticated =
          Supabase.instance.client.auth.currentSession != null;
      final atLogin = state.matchedLocation == '/login';
      if (state.matchedLocation == '/') {
        return authenticated ? '/home' : '/login';
      }
      if (!authenticated && !atLogin) return '/login';
      if (authenticated && atLogin) return '/home';
      return null;
    },
    routes: [
      GoRoute(
          path: '/login',
          builder: (_, state) => LoginPage(
                key: ValueKey(state.uri.toString()),
                tokenHash: state.uri.queryParameters['token_hash'] ??
                    state.uri.queryParameters['token'],
                linkType: state.uri.queryParameters['type'],
              )),
      ShellRoute(
        builder: (_, state, child) => MemberTheme(
            backdrop: false,
            route: state.uri.path,
            media: state.uri.path.startsWith('/media'),
            child: MemberSearchScope(child: AppShell(child: child))),
        routes: [
          GoRoute(
              path: '/home',
              pageBuilder: (context, state) =>
                  _memberPage(context, state, const HomePage())),
          GoRoute(
              path: '/media',
              pageBuilder: (context, state) =>
                  _memberPage(context, state, const MediaPage()),
              routes: [
                GoRoute(
                    path: 'albums/:id',
                    pageBuilder: (context, state) => _slide(
                        context,
                        state,
                        MediaAlbumDetailPage(
                            albumId: state.pathParameters['id']!,
                            seed: state.extra as Map<String, dynamic>?))),
                GoRoute(
                    path: 'video/:id',
                    pageBuilder: (context, state) => _slide(
                        context,
                        state,
                        MediaVideoPage(
                            videoId: state.pathParameters['id']!,
                            seed: state.extra as Map<String, dynamic>?))),
              ]),
          GoRoute(
              path: '/media/:id',
              pageBuilder: (context, state) => _memberPage(
                  context,
                  state,
                  MediaEpisodeDetailPage(
                      episodeId: state.pathParameters['id']!,
                      seed: state.extra as Map<String, dynamic>?))),
          GoRoute(
              path: '/departments',
              pageBuilder: (context, state) =>
                  _memberPage(context, state, const DepartmentsPage())),
          GoRoute(
              path: '/events',
              pageBuilder: (context, state) =>
                  _memberPage(context, state, const EventsPage())),
          GoRoute(
              path: '/give',
              pageBuilder: (context, state) => _memberPage(
                  context,
                  state,
                  GiveHomePage(
                      initialHistory:
                          state.uri.queryParameters['tab'] == 'history'))),
          GoRoute(
              path: '/profile',
              pageBuilder: (context, state) =>
                  _memberPage(context, state, const ProfilePage())),
          GoRoute(
              path: '/events/:id',
              pageBuilder: (context, state) => _memberPage(
                  context,
                  state,
                  EventDetailPage(
                      eventId: state.pathParameters['id']!,
                      seed: state.extra as Map<String, dynamic>?))),
          GoRoute(
              path: '/prayer-alerts',
              pageBuilder: (context, state) =>
                  _memberPage(context, state, const PrayerAlertsPage())),
          GoRoute(
              path: '/search',
              pageBuilder: (context, state) => _memberPage(
                  context,
                  state,
                  SearchPage(
                      initialFilter: state.uri.queryParameters['filter']))),
          GoRoute(
              path: '/devotional',
              pageBuilder: (context, state) =>
                  _memberPage(context, state, const DevotionalPage())),
          GoRoute(
              path: '/souls',
              pageBuilder: (context, state) =>
                  _memberPage(context, state, const SoulsPage())),
        ],
      ),
      GoRoute(
          path: '/departments/:id',
          pageBuilder: (context, state) => _slide(
              context,
              state,
              DepartmentDetailPage(
                  initialTab: state.uri.queryParameters['tab'] == 'files'
                      ? 3
                      : state.uri.queryParameters['tab'] == 'attendance'
                          ? 2
                          : 0,
                  departmentId: state.pathParameters['id']!,
                  seed: state.extra as Map<String, dynamic>?))),
      GoRoute(
          path: '/resources/department-tools',
          pageBuilder: (context, state) => _slide(
              context,
              state,
              DepartmentToolsPage(
                  departmentId: state.uri.queryParameters['department']))),
      GoRoute(
          path: '/resources/anonymous-reports',
          pageBuilder: (context, state) =>
              _slide(context, state, const AnonymousReportsPage())),
      GoRoute(
          path: '/resources/department-files',
          pageBuilder: (context, state) =>
              _slide(context, state, const DepartmentsPage(filesOnly: true))),
      GoRoute(
          path: '/departments/:id/requests',
          pageBuilder: (context, state) => _slide(
              context,
              state,
              DepartmentRequestsPage(
                  departmentId: state.pathParameters['id']!))),
      GoRoute(
          path: '/departments/:id/wallet/new',
          pageBuilder: (context, state) => _slide(context, state,
              DepartmentWalletPage(departmentId: state.pathParameters['id']!))),
      GoRoute(
          path: '/departments/:id/profile/edit',
          pageBuilder: (context, state) => _slide(
              context,
              state,
              DepartmentProfileEditPage(
                  departmentId: state.pathParameters['id']!))),
      GoRoute(
          path: '/departments/:id/event/new',
          pageBuilder: (context, state) => _slide(
              context,
              state,
              DepartmentCreateEventPage(
                  departmentId: state.pathParameters['id']!))),
      GoRoute(
          path: '/departments/:id/announcement',
          pageBuilder: (context, state) => _slide(
              context,
              state,
              DepartmentAnnouncementPage(
                  departmentId: state.pathParameters['id']!))),
      GoRoute(
          path: '/departments/:id/files/manage',
          pageBuilder: (context, state) => _slide(
              context,
              state,
              DepartmentManageFilesPage(
                  departmentId: state.pathParameters['id']!))),
      GoRoute(
          path: '/give/payment',
          pageBuilder: (context, state) => _slide(
              context,
              state,
              GivePaymentPage(
                  payload: Map<String, dynamic>.from((state.extra as Map?) ??
                      const {'giving_type': 'offering', 'title': 'Give'})))),
      GoRoute(
          path: '/give/auto',
          pageBuilder: (context, state) => _slide(
              context,
              state,
              AutoGivePage(
                  payload: Map<String, dynamic>.from(
                      (state.extra as Map?) ?? const {})))),
      GoRoute(path: '/give/history', redirect: (_, __) => '/give?tab=history'),
      GoRoute(
          path: '/give/result',
          pageBuilder: (context, state) => _fade(
              context,
              state,
              GiveResultPage(
                  reference: state.uri.queryParameters['reference'] ?? ''))),
      GoRoute(
          path: '/prayer-alerts/new',
          pageBuilder: (context, state) =>
              _slide(context, state, const PrayerAlertEditPage())),
      GoRoute(
          path: '/prayer-alerts/:id/edit',
          pageBuilder: (context, state) => _slide(
              context,
              state,
              PrayerAlertEditPage(
                  alertId: state.pathParameters['id']!,
                  alert: state.extra as Map<String, dynamic>?))),
      GoRoute(
          path: '/prayer-session',
          pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              fullscreenDialog: true,
              transitionDuration: AppMotion.duration(context, AppMotion.page),
              reverseTransitionDuration:
                  AppMotion.duration(context, AppMotion.exit),
              child: MemberTheme(
                  route: state.uri.path,
                  child: MemberBackHost(
                      path: state.uri.path,
                      child: PrayerSessionPage(
                          payload: Map<String, dynamic>.from(
                              (state.extra as Map?) ?? const {})))),
              transitionsBuilder: (context, animation, __, child) =>
                  AppRouteMotion(
                      animation: animation,
                      offset: const Offset(0, 16),
                      child: child))),
      GoRoute(
          path: '/devotional/:id',
          pageBuilder: (context, state) => _slide(
              context,
              state,
              DevotionalPostPage(
                  postId: state.pathParameters['id']!,
                  seed: state.extra as Map<String, dynamic>?))),
      GoRoute(
          path: '/souls/:id',
          pageBuilder: (context, state) => _slide(
              context,
              state,
              SoulDetailPage(
                  soulId: state.pathParameters['id']!,
                  seed: state.extra as Map<String, dynamic>?))),
    ],
  );
}

CustomTransitionPage<void> _memberPage(
        BuildContext context, GoRouterState state, Widget child) =>
    !const ['/home', '/media', '/events', '/give', '/profile']
            .contains(state.uri.path)
        ? _slide(context, state, child)
        : CustomTransitionPage<void>(
            key: state.pageKey,
            child: MemberBackdrop(
                route: state.uri.path,
                media: state.uri.path.startsWith('/media'),
                child: child),
            transitionDuration: AppMotion.duration(context, AppMotion.page),
            reverseTransitionDuration:
                AppMotion.duration(context, AppMotion.exit),
            transitionsBuilder: (context, animation, secondary, child) =>
                AppRouteMotion(
                    animation: animation, offset: Offset.zero, child: child));

CustomTransitionPage<void> _fade(
        BuildContext context, GoRouterState state, Widget child) =>
    CustomTransitionPage(
      key: state.pageKey,
      transitionDuration: AppMotion.duration(context, AppMotion.page),
      reverseTransitionDuration: AppMotion.duration(context, AppMotion.exit),
      child: MemberTheme(
          route: state.uri.path,
          child: MemberBackHost(path: state.uri.path, child: child)),
      transitionsBuilder: (context, animation, secondary, child) {
        if (MediaQuery.disableAnimationsOf(context)) return child;
        return AppRouteMotion(
            animation: animation,
            secondaryAnimation: secondary,
            offset: const Offset(0, 28),
            beginScale: .975,
            child: child);
      },
    );

CustomTransitionPage<void> _slide(
    BuildContext context, GoRouterState state, Widget child) {
  final origin = ComponentOrigin.take();
  return CustomTransitionPage(
    key: state.pageKey,
    transitionDuration:
        AppMotion.duration(context, const Duration(milliseconds: 280)),
    reverseTransitionDuration:
        AppMotion.duration(context, const Duration(milliseconds: 200)),
    // Every non-tab member page gets the shared sticky top-left back button.
    child: MemberTheme(
        route: state.uri.path,
        child: MemberBackHost(path: state.uri.path, child: child)),
    transitionsBuilder: (context, animation, secondary, child) {
      if (MediaQuery.disableAnimationsOf(context)) return child;
      if (origin != null) {
        return ComponentRouteMotion(
            animation: animation, origin: origin, child: child);
      }
      return AppRouteMotion(
          animation: animation,
          secondaryAnimation: secondary,
          beginScale: .98,
          offset: state.uri.path == '/give/payment'
              ? const Offset(0, 32)
              : const Offset(36, 0),
          child: child);
    },
  );
}
