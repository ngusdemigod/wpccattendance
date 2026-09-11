import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'router.dart';

class WpccApp extends StatefulWidget {
  const WpccApp({super.key});
  @override
  State<WpccApp> createState() => _WpccAppState();
}

class _WpccAppState extends State<WpccApp> {
  late final router = buildRouter();
  @override
  void dispose() {
    router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'WPCC Community',
        theme: buildWpccTheme(),
        routerConfig: router,
        builder: (context, child) => WpccBackdrop(
          child: child ?? const SizedBox.shrink(),
        ),
      );
}
