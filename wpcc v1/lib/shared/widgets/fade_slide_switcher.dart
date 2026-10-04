import 'package:flutter/material.dart';

class FadeSlideSwitcher extends StatelessWidget {
  const FadeSlideSwitcher({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 260),
    this.reverseDuration = const Duration(milliseconds: 180),
    this.offset = const Offset(0, 0.04),
    this.curve = Curves.easeOutCubic,
    this.reverseCurve = Curves.easeInCubic,
  });

  final Widget child;
  final Duration duration;
  final Duration reverseDuration;
  final Offset offset;
  final Curve curve;
  final Curve reverseCurve;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      reverseDuration: reverseDuration,
      switchInCurve: curve,
      switchOutCurve: reverseCurve,
      transitionBuilder: (child, animation) {
        final fadeAnimation = CurvedAnimation(
          parent: animation,
          curve: curve,
          reverseCurve: reverseCurve,
        );
        return FadeTransition(
          opacity: fadeAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: offset,
              end: Offset.zero,
            ).animate(fadeAnimation),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
