import 'dart:ui';

import 'package:flutter/material.dart';
import '../theme/member_material.dart';

/// A clipped member control surface; content and artwork remain unblurred.
class MemberGlass extends StatelessWidget {
  const MemberGlass(
      {super.key,
      required this.child,
      this.frosted = true,
      this.outlined = true,
      this.radius = 24,
      this.weight = MemberMaterialWeight.control});
  final MemberMaterialWeight weight;
  final Widget child;
  final double radius;
  final bool frosted;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final solid = MemberMaterials.solid(context);
    final surface = DecoratedBox(
      decoration: BoxDecoration(
        color: MemberMaterials.fill(context, weight),
        gradient: solid
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: frosted ? [
                    Colors.white.withValues(alpha: dark ? .13 : .72),
                    Colors.white.withValues(alpha: dark ? .10 : .62),
                  ] : [
                    Colors.white.withValues(alpha: dark ? .055 : .32),
                    Colors.white.withValues(alpha: 0)
                  ]),
        borderRadius: BorderRadius.circular(radius),
        border: outlined || MediaQuery.highContrastOf(context) ? Border.all(
          color: MemberMaterials.edge(context),
        ) : null,
      ),
      child: child,
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: solid
          ? surface
          : BackdropFilter(
              filter: ImageFilter.blur(
                  sigmaX: MemberMaterials.blur(weight),
                  sigmaY: MemberMaterials.blur(weight)),
              child: surface,
            ),
    );
  }
}
