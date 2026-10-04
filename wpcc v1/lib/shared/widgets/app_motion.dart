import 'dart:async';

import 'package:flutter/material.dart';

abstract final class AppMotion {
  static const pageDuration = Duration(milliseconds: 240);
  static const pageReverseDuration = Duration(milliseconds: 180);
  static const entranceDuration = Duration(milliseconds: 260);
  static const easeOut = Cubic(0.23, 1, 0.32, 1);
}

class AppPageTransitionsBuilder extends PageTransitionsBuilder {
  const AppPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (route.isFirst) {
      return child;
    }

    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final curved = CurvedAnimation(
      parent: animation,
      curve: AppMotion.easeOut,
      reverseCurve: Curves.easeInCubic,
    );

    final faded = FadeTransition(opacity: curved, child: child);
    if (reduceMotion) {
      return faded;
    }

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.035, 0),
        end: Offset.zero,
      ).animate(curved),
      child: faded,
    );
  }
}

class EntranceMotion extends StatefulWidget {
  const EntranceMotion({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = const Offset(0, 8),
  });

  final Widget child;
  final Duration delay;
  final Offset offset;

  @override
  State<EntranceMotion> createState() => _EntranceMotionState();
}

class _EntranceMotionState extends State<EntranceMotion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _progress;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.entranceDuration,
    );
    _progress = CurvedAnimation(
      parent: _controller,
      curve: AppMotion.easeOut,
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(_progress);

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _delayTimer = Timer(widget.delay, _controller.forward);
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return AnimatedBuilder(
      animation: _progress,
      child: widget.child,
      builder: (context, child) {
        final translated = reduceMotion
            ? child!
            : Transform.translate(
                offset: Offset(
                  widget.offset.dx * (1 - _progress.value),
                  widget.offset.dy * (1 - _progress.value),
                ),
                child: child,
              );
        return Opacity(opacity: _opacity.value, child: translated);
      },
    );
  }
}
