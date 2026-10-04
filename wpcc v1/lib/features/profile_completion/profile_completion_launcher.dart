import 'package:flutter/material.dart';

import 'profile_completion_screen.dart';

/// Opens the profile completion flow as a full-screen overlay above the
/// current app shell. The screen fades in while sliding up, and on dismissal
/// fades out while sliding down (the enter animation played in reverse).
Future<void> openProfileCompletionFlow(BuildContext context) {
  return Navigator.of(context, rootNavigator: true).push<void>(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: const Color(0x14111827),
      transitionDuration: const Duration(milliseconds: 420),
      reverseTransitionDuration: const Duration(milliseconds: 360),
      pageBuilder: (_, __, ___) => const ProfileCompletionScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        final slide = Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(curved);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(position: slide, child: child),
        );
      },
    ),
  );
}
