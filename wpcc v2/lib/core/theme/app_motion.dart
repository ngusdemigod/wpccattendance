import 'package:flutter/material.dart';

abstract final class AppMotion {
  static const curve = Cubic(.23, 1, .32, 1);
  static const drawer = Cubic(.32, .72, 0, 1);
  static const tab = Duration(milliseconds: 140);
  static const control = Duration(milliseconds: 180);
  static const page = Duration(milliseconds: 220);
  static const exit = Duration(milliseconds: 180);
  static const sheet = Duration(milliseconds: 260);
  static const sheetExit = Duration(milliseconds: 200);
  static AnimationStyle sheetStyle(BuildContext context) => AnimationStyle(
      duration: duration(context, sheet),
      reverseDuration: duration(context, sheetExit),
      curve: drawer,
      reverseCurve: drawer.flipped);
  static AnimationStyle dialogStyle(BuildContext context) => AnimationStyle(
      duration: duration(context, control),
      reverseDuration: duration(context, tab),
      curve: curve,
      reverseCurve: curve.flipped);
  static Duration duration(BuildContext context, Duration normal) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : normal;
}

class AppPressMotion extends StatefulWidget {
  const AppPressMotion({super.key, required this.child});
  final Widget child;
  @override
  State<AppPressMotion> createState() => _AppPressMotionState();
}

class _AppPressMotionState extends State<AppPressMotion> {
  bool pressed = false;
  void _set(bool value) {
    if (pressed != value) setState(() => pressed = value);
  }

  @override
  Widget build(BuildContext context) => Listener(
      onPointerDown: (event) {
        if (event.buttons == 1) _set(true);
      },
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
          scale: pressed && !MediaQuery.disableAnimationsOf(context) ? .97 : 1,
          duration: AppMotion.duration(
              context, Duration(milliseconds: pressed ? 100 : 140)),
          curve: AppMotion.curve,
          child: widget.child));
}

/// A route-owned transition: direction-aware easing, fixed logical travel.
class AppRouteMotion extends StatefulWidget {
  const AppRouteMotion(
      {super.key,
      required this.animation,
      required this.child,
      this.offset = Offset.zero,
      this.beginScale = 1,
      this.curve = AppMotion.curve});
  final Animation<double> animation;
  final Widget child;
  final Offset offset;
  final double beginScale;
  final Curve curve;

  @override
  State<AppRouteMotion> createState() => _AppRouteMotionState();
}

class _AppRouteMotionState extends State<AppRouteMotion> {
  late CurvedAnimation progress;
  void _bind() => progress = CurvedAnimation(
      parent: widget.animation,
      curve: widget.curve,
      reverseCurve: widget.curve.flipped);
  @override
  void initState() {
    super.initState();
    _bind();
  }

  @override
  void didUpdateWidget(AppRouteMotion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation != widget.animation ||
        oldWidget.curve != widget.curve) {
      progress.dispose();
      _bind();
    }
  }

  @override
  void dispose() {
    progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return AnimatedBuilder(
        animation: progress,
        child: widget.child,
        builder: (context, child) {
          final reverse = widget.animation.status == AnimationStatus.reverse;
          final value = progress.value;
          return ExcludeSemantics(
              excluding: reverse,
              child: IgnorePointer(
                  ignoring: reverse,
                  child: Opacity(
                      opacity: value.clamp(0, 1),
                      child: Transform.translate(
                          offset: widget.offset * (1 - value),
                          child: Transform.scale(
                              scale: widget.beginScale +
                                  (1 - widget.beginScale) * value,
                              child: child)))));
        });
  }
}

Future<T?> showMotionDialog<T>(
    {required BuildContext context,
    required WidgetBuilder builder,
    AnimationStyle? animationStyle,
    bool barrierDismissible = true,
    Color? barrierColor = Colors.black54}) {
  final navigator = Navigator.of(context, rootNavigator: true);
  final themes = InheritedTheme.capture(from: context, to: navigator.context);
  return navigator.push<T>(_MotionDialogRoute<T>(
    pageBuilder: (context, _, __) => themes.wrap(Builder(builder: builder)),
    barrierDismissible: barrierDismissible,
    barrierColor: barrierColor,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    transitionDuration: AppMotion.duration(context, AppMotion.control),
    transitionBuilder: (_, animation, __, child) => AppRouteMotion(
        animation: animation, beginScale: .98, child: SafeArea(child: child)),
  ));
}

class _MotionDialogRoute<T> extends RawDialogRoute<T> {
  _MotionDialogRoute(
      {required super.pageBuilder,
      required super.barrierDismissible,
      required super.barrierColor,
      required super.barrierLabel,
      required super.transitionDuration,
      required super.transitionBuilder})
      : super(traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop);
  @override
  Duration get reverseTransitionDuration =>
      transitionDuration == Duration.zero ? Duration.zero : AppMotion.tab;
}
