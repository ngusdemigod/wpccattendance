import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/backend/schema/structs/index.dart';

import '/auth/base_auth_user_provider.dart';

import '/app/app_shell_widget.dart';
import '/features/profile_completion/profile_completion_service.dart';
import '/shared/widgets/wpcc_shimmer.dart';
import '/flutter_flow/flutter_flow_util.dart';

import '/index.dart';

export 'package:go_router/go_router.dart';
export 'serialization_util.dart';

class FocusReloader extends StatefulWidget {
  final Widget child;
  const FocusReloader({super.key, required this.child});

  @override
  State<FocusReloader> createState() => _FocusReloaderState();
}

class _FocusReloaderState extends State<FocusReloader> {
  @override
  Widget build(BuildContext context) => Focus(
        onFocusChange: (focused) {
          if (focused) {
            FFAppState().clearAllRequestCache();
            FFAppState().update(() {});
          }
        },
        child: widget.child,
      );
}

const kTransitionInfoKey = '__transition_info__';

GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class AppStateNotifier extends ChangeNotifier {
  AppStateNotifier._();

  static AppStateNotifier? _instance;
  static AppStateNotifier get instance => _instance ??= AppStateNotifier._();

  BaseAuthUser? initialUser;
  BaseAuthUser? user;
  ProfileCompletionStatus profileCompletionStatus =
      ProfileCompletionStatus.unknown;
  bool showSplashImage = true;
  String? _redirectLocation;
  int _profileCompletionRequestVersion = 0;

  /// Determines whether the app will refresh and build again when a sign
  /// in or sign out happens. This is useful when the app is launched or
  /// on an unexpected logout. However, this must be turned off when we
  /// intend to sign in/out and then navigate or perform any actions after.
  /// Otherwise, this will trigger a refresh and interrupt the action(s).
  bool notifyOnAuthChange = true;

  // Profile completion is resolved in the background by HomeScreen. It must
  // not block authenticated routes, because a slow secure-profile lookup
  // would otherwise leave the whole app on an indefinite shimmer.
  bool get loading => showSplashImage;
  bool get loggedIn => user?.loggedIn ?? false;
  bool get initiallyLoggedIn => initialUser?.loggedIn ?? false;
  bool get shouldRedirect => loggedIn && _redirectLocation != null;

  String getRedirectLocation() => _redirectLocation!;
  bool hasRedirect() => _redirectLocation != null;
  void setRedirectLocationIfUnset(String loc) => _redirectLocation ??= loc;
  void clearRedirectLocation() => _redirectLocation = null;

  /// Mark as not needing to notify on a sign in / out when we intend
  /// to perform subsequent actions (such as navigation) afterwards.
  void updateNotifyOnAuthChange(bool notify) => notifyOnAuthChange = notify;

  void update(BaseAuthUser newUser) {
    final shouldUpdate =
        user?.uid == null || newUser.uid == null || user?.uid != newUser.uid;
    initialUser ??= newUser;
    user = newUser;
    if (!newUser.loggedIn) {
      profileCompletionStatus = ProfileCompletionStatus.unauthenticated;
    } else if (shouldUpdate) {
      profileCompletionStatus = ProfileCompletionStatus.unknown;
    }
    // Refresh the app on auth change unless explicitly marked otherwise.
    // No need to update unless the user has changed.
    if (notifyOnAuthChange && shouldUpdate) {
      notifyListeners();
    }
    // Once again mark the notifier as needing to update on auth change
    // (in order to catch sign in / out events).
    updateNotifyOnAuthChange(true);
  }

  Future<void> refreshProfileCompletionStatus() async {
    if (!loggedIn) {
      if (profileCompletionStatus != ProfileCompletionStatus.unauthenticated) {
        profileCompletionStatus = ProfileCompletionStatus.unauthenticated;
        notifyListeners();
      }
      return;
    }

    final requestVersion = ++_profileCompletionRequestVersion;
    final status = await ProfileCompletionService()
        .fetchStatus()
        .onError((_, __) => ProfileCompletionStatus.incomplete);
    if (requestVersion != _profileCompletionRequestVersion) {
      return;
    }
    if (profileCompletionStatus != status) {
      profileCompletionStatus = status;
      notifyListeners();
    }
  }

  void setProfileCompletionStatus(ProfileCompletionStatus status) {
    if (profileCompletionStatus == status) {
      return;
    }
    profileCompletionStatus = status;
    notifyListeners();
  }

  void stopShowingSplashImage() {
    showSplashImage = false;
    notifyListeners();
  }
}

GoRouter createRouter(AppStateNotifier appStateNotifier) => GoRouter(
      initialLocation: LoginWidget.routePath,
      debugLogDiagnostics: true,
      refreshListenable: appStateNotifier,
      navigatorKey: appNavigatorKey,
      errorBuilder: (context, state) => const AppShellWidget(),
      redirect: (context, state) {
        final location = state.uri.toString();
        final isAuthRoute =
            location == '/' || location.startsWith(LoginWidget.routePath);

        // Signed-in users always land on the app shell (home). Profile
        // completion is no longer a hard redirect gate; the home screen opens
        // it in the background when it is still needed.
        if (appStateNotifier.loggedIn && isAuthRoute) {
          return AppShellWidget.routePath;
        }

        return null;
      },
      routes: [
        FFRoute(
          name: '_initialize',
          path: '/',
          builder: (context, params) => LoginWidget(
            tokenHash: params.getParam(
                  'token_hash',
                  ParamType.String,
                ) ??
                '',
            authType: params.getParam(
                  'type',
                  ParamType.String,
                ) ??
                '',
            authErrorDescription: params.getParam(
                  'error_description',
                  ParamType.String,
                ) ??
                '',
          ),
        ),
        FFRoute(
          name: AppShellWidget.routeName,
          path: AppShellWidget.routePath,
          requireAuth: true,
          builder: (context, params) => const AppShellWidget(),
        ),
        FFRoute(
          name: AttendanceListWidget.routeName,
          path: AttendanceListWidget.routePath,
          requireAuth: true,
          builder: (context, params) => const AttendanceListWidget(),
        ),
        FFRoute(
          name: EventsListingWidget.routeName,
          path: EventsListingWidget.routePath,
          requireAuth: true,
          builder: (context, params) => const EventsListingWidget(),
        ),
        FFRoute(
          name: EventlistWidget.routeName,
          path: EventlistWidget.routePath,
          requireAuth: true,
          builder: (context, params) => const EventlistWidget(),
        ),
        FFRoute(
          name: LoginWidget.routeName,
          path: LoginWidget.routePath,
          requireAuth: false,
          builder: (context, params) => LoginWidget(
            tokenHash: params.getParam(
                  'token_hash',
                  ParamType.String,
                ) ??
                '',
            authType: params.getParam(
                  'type',
                  ParamType.String,
                ) ??
                '',
            authErrorDescription: params.getParam(
                  'error_description',
                  ParamType.String,
                ) ??
                '',
          ),
        ),
        FFRoute(
          name: EventDetailsScreen.routeName,
          path: EventDetailsScreen.routePath,
          requireAuth: true,
          builder: (context, params) => EventDetailsScreen(
            eventId: params.getParam(
                  'eventId',
                  ParamType.String,
                ) ??
                '',
          ),
        ),
        FFRoute(
          name: AnnouncementDetailScreen.routeName,
          path: AnnouncementDetailScreen.routePath,
          requireAuth: true,
          builder: (context, params) => AnnouncementDetailScreen(
            announcementId: params.getParam(
                  'announcementId',
                  ParamType.String,
                ) ??
                '',
          ),
        ),
        FFRoute(
          name: ClockInScreen.routeName,
          path: ClockInScreen.routePath,
          requireAuth: true,
          builder: (context, params) => ClockInScreen(
            eventId: params.getParam(
                  'eventId',
                  ParamType.String,
                ) ??
                '',
          ),
        ),
        FFRoute(
          name: CheckedInScreen.routeName,
          path: CheckedInScreen.routePath,
          requireAuth: true,
          builder: (context, params) => CheckedInScreen(
            eventId: params.getParam(
                  'eventId',
                  ParamType.String,
                ) ??
                '',
            action: params.getParam(
              'action',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: LocationNotFoundScreen.routeName,
          path: LocationNotFoundScreen.routePath,
          requireAuth: true,
          builder: (context, params) => LocationNotFoundScreen(
            eventId: params.getParam(
                  'eventId',
                  ParamType.String,
                ) ??
                '',
            reason: params.getParam(
              'reason',
              ParamType.String,
            ),
            message: params.getParam(
              'message',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: EventviewWidget.routeName,
          path: EventviewWidget.routePath,
          requireAuth: true,
          builder: (context, params) => EventviewWidget(
            evname: params.getParam(
              'evname',
              ParamType.String,
            ),
            evid: params.getParam(
              'evid',
              ParamType.String,
            ),
            desc: params.getParam(
              'desc',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: AttendanceActionWidget.routeName,
          path: AttendanceActionWidget.routePath,
          requireAuth: true,
          builder: (context, params) => AttendanceActionWidget(
            eventId: params.getParam(
              'eventId',
              ParamType.String,
            ),
            clockOut: params.getParam(
                  'clockOut',
                  ParamType.bool,
                ) ??
                false,
          ),
        ),
        FFRoute(
          name: ClockInSuccessWidget.routeName,
          path: ClockInSuccessWidget.routePath,
          requireAuth: true,
          builder: (context, params) => ClockInSuccessWidget(
            eventId: params.getParam(
              'eventId',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: EditProfileWidget.routeName,
          path: EditProfileWidget.routePath,
          requireAuth: true,
          builder: (context, params) => const EditProfileWidget(),
        ),
        FFRoute(
          name: SettingsWidget.routeName,
          path: SettingsWidget.routePath,
          requireAuth: true,
          builder: (context, params) => const SettingsWidget(),
        ),
        FFRoute(
          name: WelcomeWidget.routeName,
          path: WelcomeWidget.routePath,
          builder: (context, params) => const WelcomeWidget(),
        ),
        FFRoute(
          name: ProfileCompletionScreen.routeName,
          path: ProfileCompletionScreen.routePath,
          requireAuth: true,
          builder: (context, params) => const ProfileCompletionScreen(),
        ),
        FFRoute(
          name: GlobalSearchScreen.routeName,
          path: GlobalSearchScreen.routePath,
          requireAuth: true,
          builder: (context, params) => GlobalSearchScreen(
            initialQuery: params.getParam(
                  'q',
                  ParamType.String,
                ) ??
                '',
            initialFilter: params.getParam(
                  'filter',
                  ParamType.String,
                ) ??
                '',
          ),
        ),
      ].map((r) => r.toRoute(appStateNotifier)).toList(),
    );

extension NavParamExtensions on Map<String, String?> {
  Map<String, String> get withoutNulls => Map.fromEntries(
        entries
            .where((e) => e.value != null)
            .map((e) => MapEntry(e.key, e.value!)),
      );
}

extension NavigationExtensions on BuildContext {
  void goNamedAuth(
    String name,
    bool mounted, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, String> queryParameters = const <String, String>{},
    Object? extra,
    bool ignoreRedirect = false,
  }) =>
      !mounted || GoRouter.of(this).shouldRedirect(ignoreRedirect)
          ? null
          : goNamed(
              name,
              pathParameters: pathParameters,
              queryParameters: queryParameters,
              extra: extra,
            );

  void pushNamedAuth(
    String name,
    bool mounted, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, String> queryParameters = const <String, String>{},
    Object? extra,
    bool ignoreRedirect = false,
  }) =>
      !mounted || GoRouter.of(this).shouldRedirect(ignoreRedirect)
          ? null
          : pushNamed(
              name,
              pathParameters: pathParameters,
              queryParameters: queryParameters,
              extra: extra,
            );

  void safePop() {
    // If there is only one route on the stack, navigate to the initial
    // page instead of popping.
    if (canPop()) {
      pop();
    } else {
      go(LoginWidget.routePath);
    }
  }
}

extension GoRouterExtensions on GoRouter {
  AppStateNotifier get appState => AppStateNotifier.instance;
  void prepareAuthEvent([bool ignoreRedirect = false]) =>
      appState.hasRedirect() && !ignoreRedirect
          ? null
          : appState.updateNotifyOnAuthChange(false);
  bool shouldRedirect(bool ignoreRedirect) =>
      !ignoreRedirect && appState.hasRedirect();
  void clearRedirectLocation() => appState.clearRedirectLocation();
  void setRedirectLocationIfUnset(String location) =>
      appState.updateNotifyOnAuthChange(false);
}

extension _GoRouterStateExtensions on GoRouterState {
  Map<String, dynamic> get extraMap =>
      extra != null ? extra as Map<String, dynamic> : {};
  Map<String, dynamic> get allParams => <String, dynamic>{}
    ..addAll(pathParameters)
    ..addAll(uri.queryParameters)
    ..addAll(extraMap);
  TransitionInfo get transitionInfo => extraMap.containsKey(kTransitionInfoKey)
      ? extraMap[kTransitionInfoKey] as TransitionInfo
      : TransitionInfo.appDefault();
}

class FFParameters {
  FFParameters(this.state, [this.asyncParams = const {}]);

  final GoRouterState state;
  final Map<String, Future<dynamic> Function(String)> asyncParams;

  Map<String, dynamic> futureParamValues = {};

  // Parameters are empty if the params map is empty or if the only parameter
  // present is the special extra parameter reserved for the transition info.
  bool get isEmpty =>
      state.allParams.isEmpty ||
      (state.allParams.length == 1 &&
          state.extraMap.containsKey(kTransitionInfoKey));
  bool isAsyncParam(MapEntry<String, dynamic> param) =>
      asyncParams.containsKey(param.key) && param.value is String;
  bool get hasFutures => state.allParams.entries.any(isAsyncParam);
  Future<bool> completeFutures() => Future.wait(
        state.allParams.entries.where(isAsyncParam).map(
          (param) async {
            final doc = await asyncParams[param.key]!(param.value)
                .onError((_, __) => null);
            if (doc != null) {
              futureParamValues[param.key] = doc;
              return true;
            }
            return false;
          },
        ),
      ).onError((_, __) => [false]).then((v) => v.every((e) => e));

  dynamic getParam<T>(
    String paramName,
    ParamType type, {
    bool isList = false,
    StructBuilder<T>? structBuilder,
  }) {
    if (futureParamValues.containsKey(paramName)) {
      return futureParamValues[paramName];
    }
    if (!state.allParams.containsKey(paramName)) {
      return null;
    }
    final param = state.allParams[paramName];
    // Got parameter from `extras`, so just directly return it.
    if (param is! String) {
      return param;
    }
    // Return serialized value.
    return deserializeParam<T>(
      param,
      type,
      isList,
      structBuilder: structBuilder,
    );
  }
}

class FFRoute {
  const FFRoute({
    required this.name,
    required this.path,
    required this.builder,
    this.requireAuth = false,
    this.asyncParams = const {},
    this.routes = const [],
  });

  final String name;
  final String path;
  final bool requireAuth;
  final Map<String, Future<dynamic> Function(String)> asyncParams;
  final Widget Function(BuildContext, FFParameters) builder;
  final List<GoRoute> routes;

  GoRoute toRoute(AppStateNotifier appStateNotifier) => GoRoute(
        name: name,
        path: path,
        redirect: (context, state) {
          if (appStateNotifier.shouldRedirect) {
            final redirectLocation = appStateNotifier.getRedirectLocation();
            appStateNotifier.clearRedirectLocation();
            return redirectLocation;
          }

          if (requireAuth && !appStateNotifier.loggedIn) {
            appStateNotifier.setRedirectLocationIfUnset(state.uri.toString());
            return LoginWidget.routePath;
          }
          return null;
        },
        pageBuilder: (context, state) {
          fixStatusBarOniOS16AndBelow(context);
          final ffParams = FFParameters(state, asyncParams);
          final page = ffParams.hasFutures
              ? FutureBuilder(
                  future: ffParams.completeFutures(),
                  builder: (context, _) => builder(context, ffParams),
                )
              : builder(context, ffParams);
          final isSetupRoute = state.uri
              .toString()
              .startsWith(ProfileCompletionScreen.routePath);
          final shouldShowGlobalLoader =
              requireAuth && !isSetupRoute && appStateNotifier.loading;
          final child = shouldShowGlobalLoader
              ? const WpccScreenShimmer(includeBottomNavSpace: false)
              : FocusReloader(child: page);

          final transitionInfo = state.transitionInfo;
          return transitionInfo.hasTransition
              ? CustomTransitionPage(
                  key: state.pageKey,
                  name: state.name,
                  child: child,
                  transitionDuration: transitionInfo.duration,
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) =>
                          PageTransition(
                    type: transitionInfo.transitionType,
                    duration: transitionInfo.duration,
                    reverseDuration: transitionInfo.duration,
                    alignment: transitionInfo.alignment,
                    child: child,
                  ).buildTransitions(
                    context,
                    animation,
                    secondaryAnimation,
                    child,
                  ),
                )
              : MaterialPage(
                  key: state.pageKey, name: state.name, child: child);
        },
        routes: routes,
      );
}

class TransitionInfo {
  const TransitionInfo({
    required this.hasTransition,
    this.transitionType = PageTransitionType.fade,
    this.duration = const Duration(milliseconds: 300),
    this.alignment,
  });

  final bool hasTransition;
  final PageTransitionType transitionType;
  final Duration duration;
  final Alignment? alignment;

  static TransitionInfo appDefault() =>
      const TransitionInfo(hasTransition: false);
}

class RootPageContext {
  const RootPageContext(this.isRootPage, [this.errorRoute]);
  final bool isRootPage;
  final String? errorRoute;

  static bool isInactiveRootPage(BuildContext context) {
    final rootPageContext = context.read<RootPageContext?>();
    final isRootPage = rootPageContext?.isRootPage ?? false;
    final location = GoRouterState.of(context).uri.toString();
    return isRootPage &&
        location != '/' &&
        location != rootPageContext?.errorRoute;
  }

  static Widget wrap(Widget child, {String? errorRoute}) => Provider.value(
        value: RootPageContext(true, errorRoute),
        child: child,
      );
}

extension GoRouterLocationExtension on GoRouter {
  String getCurrentLocation() {
    final RouteMatch lastMatch = routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : routerDelegate.currentConfiguration;
    return matchList.uri.toString();
  }
}
