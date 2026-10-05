import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/member_material.dart';
import 'router.dart';
import '../features/onboarding/pwa_launch_gate.dart';
import '../features/onboarding/profile_confirmation_gate.dart';
import '../features/auth/auth_repository.dart';

class WpccApp extends StatefulWidget {
  const WpccApp({super.key});
  @override
  State<WpccApp> createState() => _WpccAppState();
}

class _WpccAppState extends State<WpccApp> {
  late final router = buildRouter();
  @override
  void initState() {
    super.initState();
    ThemePreference.instance.load();
    TransparencyPreference.instance.load();
  }

  @override
  void dispose() {
    router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ThemeMode>(
        valueListenable: ThemePreference.instance,
        builder: (context, mode, _) => MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'WPCC Community',
          theme: buildWpccTheme(),
          darkTheme: buildWpccTheme(brightness: Brightness.dark),
          themeMode: mode,
          routerConfig: router,
          builder: (context, child) => MemberMaterialScope(
              child: WpccBackdrop(
            child: PwaLaunchGate(
              signedIn: AuthRepository().session != null,
              child: ProfileConfirmationGate(
                  child: child ?? const SizedBox.shrink()),
            ),
          )),
        ),
      );
}
