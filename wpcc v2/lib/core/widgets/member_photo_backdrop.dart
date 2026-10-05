import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/member_material.dart';
import '../theme/member_theme.dart';
import 'initials_avatar.dart';

/// Decorative artwork stays behind a stable, readable route fallback.
class MemberPhotoBackdrop extends StatelessWidget {
  const MemberPhotoBackdrop(
      {super.key,
      required this.imageUrl,
      required this.route,
      this.child = const SizedBox.expand()});
  final String? imageUrl;
  final String route;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final base = MemberVisuals.page(context);
    return Stack(fit: StackFit.expand, children: [
      Positioned.fill(
          child: IgnorePointer(
              child: ExcludeSemantics(
        child: MemberBackdrop(
          route: route,
          media: route.startsWith('/media'),
          child: AnimatedSwitcher(
            duration: MediaQuery.disableAnimationsOf(context) || MemberMaterials.solid(context)
                ? Duration.zero : const Duration(seconds: 2),
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeInOut,
            child: !MemberMaterials.solid(context) &&
                  (imageUrl?.trim().isNotEmpty ?? false)
              ? ClipRect(
                  key: ValueKey(imageUrl),
                  child: Stack(fit: StackFit.expand, children: [
                  RepaintBoundary(
                      child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 55, sigmaY: 55),
                    child: Transform.scale(
                        scale: 1.2,
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: InitialsAvatar(
                              key: ValueKey(imageUrl),
                              initials: '',
                              imageUrl: imageUrl,
                              size: 320,
                              memberStyle: true,
                              backdrop: true),
                        )),
                  )),
                  DecoratedBox(
                      decoration: BoxDecoration(
                          gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      base.withValues(alpha: .78),
                      base.withValues(alpha: .78),
                      base,
                      base
                    ],
                    stops: const [0, .3, .7, 1],
                  ))),
                ]))
              : const SizedBox.expand(key: ValueKey('fallback')),
          ),
        ),
      ))),
      child,
    ]);
  }
}
