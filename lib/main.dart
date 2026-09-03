import 'dart:async';

import 'package:provider/provider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app/theme/app_theme.dart';
import 'app/theme/theme_mode_controller.dart';
import 'auth/supabase_auth/supabase_user_provider.dart';
import 'features/profile/profile_identity_resolver.dart';

import '/backend/supabase/supabase.dart';
import 'flutter_flow/flutter_flow_util.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  GoRouter.optionURLReflectsImperativeAPIs = true;
  usePathUrlStrategy();

  GoogleFonts.config.allowRuntimeFetching = false;

  final appState = FFAppState(); // Initialize FFAppState
  await Future.wait([
    SupaFlow.initialize(),
    appState.initializePersistedState(),
  ]);

  runApp(ChangeNotifierProvider(
    create: (context) => appState,
    child: const MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  State<MyApp> createState() => MyAppState();

  static MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<MyAppState>()!;
}

class MyAppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}

class MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late AppStateNotifier _appStateNotifier;
  late GoRouter _router;
  String getRoute([RouteMatch? routeMatch]) {
    final RouteMatch lastMatch =
        routeMatch ?? _router.routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : _router.routerDelegate.currentConfiguration;
    return matchList.uri.toString();
  }

  List<String> getRouteStack() =>
      _router.routerDelegate.currentConfiguration.matches
          .map((e) => getRoute(e))
          .toList();
  late Stream<BaseAuthUser> userStream;
  final ProfileIdentityResolver _identityResolver = ProfileIdentityResolver();
  String? _lastRelinkedUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ThemeModeController.instance.addListener(_handleThemeChange);

    _appStateNotifier = AppStateNotifier.instance;
    _router = createRouter(_appStateNotifier);
    userStream = attendamceSupabaseUserStream()
      ..listen((user) {
        _appStateNotifier.update(user);
        _appStateNotifier.refreshProfileCompletionStatus();
        final userId = user.uid?.trim() ?? '';
        if (!user.loggedIn || userId.isEmpty) {
          _lastRelinkedUserId = null;
          return;
        }
        if (_lastRelinkedUserId == userId) {
          return;
        }
        _lastRelinkedUserId = userId;
        unawaited(
          _identityResolver.relinkCurrentAuthProfile().catchError((error) {
            debugPrint('Auth profile relink skipped: $error');
          }),
        );
      });
    _appStateNotifier.refreshProfileCompletionStatus();
    FFAppState().initializeDepartments();
    Future.delayed(
      const Duration(milliseconds: 1000),
      () => _appStateNotifier.stopShowingSplashImage(),
    );
  }

  @override
  void dispose() {
    ThemeModeController.instance.removeListener(_handleThemeChange);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      FFAppState().clearAllRequestCache();
      FFAppState().update(() {});
    }
  }

  void _handleThemeChange() => safeSetState(() {});

  void setThemeMode(ThemeMode mode) => ThemeModeController.instance.update(mode);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'attendamce',
      scrollBehavior: MyAppScrollBehavior(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', '')],
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeModeController.instance.themeMode,
      routerConfig: _router,
    );
  }
}
