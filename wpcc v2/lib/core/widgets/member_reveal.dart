import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

/// Fades a child in and lifts it a few pixels into place, once, when it first
/// appears. It uses the app's standard ease-out curve ([AppMotion.curve]) and
/// the child is always fully laid out, so nothing around it shifts. With
/// animations disabled it shows the child immediately.
///
/// Use [index] to stagger a list: each step adds 40 ms and anything past
/// [staggerLimit] (roughly the first screenful) appears without animating, so
/// long or lazily built lists never replay motion while scrolling.
class MemberReveal extends StatefulWidget {
  const MemberReveal(
      {super.key,
      required this.child,
      this.index = 0,
      this.delay,
      this.duration = const Duration(milliseconds: 260),
      this.offset = const Offset(0, 12),
      this.enabled = true});

  static const stagger = Duration(milliseconds: 40);
  static const staggerLimit = 8;

  final Widget child;
  final int index;

  /// Overrides the delay derived from [index].
  final Duration? delay;
  final Duration duration;
  final Offset offset;
  final bool enabled;

  @override
  State<MemberReveal> createState() => _MemberRevealState();
}

class _MemberRevealState extends State<MemberReveal>
    with SingleTickerProviderStateMixin {
  AnimationController? controller;
  late Animation<double> progress;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (controller != null) return;
    if (!widget.enabled ||
        widget.index > MemberReveal.staggerLimit ||
        MediaQuery.disableAnimationsOf(context)) {
      return;
    }
    final delay = widget.delay ?? MemberReveal.stagger * widget.index;
    final total = delay + widget.duration;
    controller = AnimationController(vsync: this, duration: total)..forward();
    progress = CurvedAnimation(
        parent: controller!,
        curve: Interval(delay.inMicroseconds / total.inMicroseconds, 1,
            curve: AppMotion.curve));
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null) return widget.child;
    return FadeTransition(
        opacity: progress,
        child: AnimatedBuilder(
            animation: progress,
            child: widget.child,
            builder: (context, child) => Transform.translate(
                offset: widget.offset * (1 - progress.value), child: child)));
  }
}

/// Cross-fades between children: new content eases in on [AppMotion.curve]
/// while the old content leaves faster on the flipped curve. Give each state a
/// distinct key. The box animates to the new size.
class MemberSwap extends StatelessWidget {
  const MemberSwap(
      {super.key,
      required this.child,
      this.alignment = Alignment.topCenter,
      this.animateSize = true});
  final Widget child;
  final AlignmentGeometry alignment;
  final bool animateSize;

  @override
  Widget build(BuildContext context) {
    final switcher = AnimatedSwitcher(
        duration: AppMotion.duration(context, AppMotion.control),
        reverseDuration: AppMotion.duration(context, AppMotion.exit),
        switchInCurve: AppMotion.curve,
        switchOutCurve: AppMotion.curve.flipped,
        layoutBuilder: (current, previous) => Stack(
            alignment: alignment,
            children: [...previous, if (current != null) current]),
        child: child);
    // AnimatedSize with a zero duration re-dirties its own layout, so reduced
    // motion skips it.
    if (!animateSize || MediaQuery.disableAnimationsOf(context)) {
      return switcher;
    }
    return AnimatedSize(
        duration: AppMotion.duration(context, AppMotion.control),
        curve: AppMotion.curve,
        alignment: Alignment.topCenter,
        child: switcher);
  }
}

/// Animates its own height when content appears, disappears or changes.
class MemberExpand extends StatelessWidget {
  const MemberExpand({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => MediaQuery.disableAnimationsOf(context)
      ? child
      : AnimatedSize(
          duration: AppMotion.duration(context, AppMotion.control),
          reverseDuration: AppMotion.duration(context, AppMotion.exit),
          curve: AppMotion.curve,
          alignment: Alignment.topCenter,
          child: child);
}

/// Press feedback (the app's 0.97 scale) for any tappable card or row.
/// Thin wrapper so pages depend on one import for motion helpers.
class MemberPress extends StatelessWidget {
  const MemberPress({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => AppPressMotion(child: child);
}
