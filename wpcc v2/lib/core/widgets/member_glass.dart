import 'dart:ui';

import 'package:flutter/material.dart';

/// A clipped member control surface; content and artwork remain unblurred.
class MemberGlass extends StatelessWidget {
  const MemberGlass({super.key, required this.child, this.radius = 24});
  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final solid = MediaQuery.highContrastOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    final surface = DecoratedBox(
      decoration: BoxDecoration(
        color: solid
            ? (dark ? const Color(0xFF29292D) : const Color(0xFFF0F0F3))
            : Colors.white.withValues(alpha: dark ? .075 : .62),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: (dark ? Colors.white : Colors.black)
              .withValues(alpha: solid ? .22 : .10),
        ),
      ),
      child: child,
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: solid
          ? surface
          : BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: surface,
            ),
    );
  }
}
