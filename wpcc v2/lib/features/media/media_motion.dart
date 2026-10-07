import 'package:flutter/material.dart';

import '../../core/theme/app_motion.dart';

/// Fades a child in and lifts it a few pixels into place, once, when it first
/// appears. It uses the app's standard ease-out curve (AppMotion.curve) and
/// never starts from nothing: the child begins slightly offset and fully
/// laid out, so nothing around it shifts. With animations disabled it simply
/// shows the child.
///
/// [delay] staggers siblings; keep it under about 50 ms per item.
class MediaReveal extends StatefulWidget {
  const MediaReveal(
      {super.key,
      required this.child,
      this.delay = Duration.zero,
      this.duration = const Duration(milliseconds: 260),
      this.offset = const Offset(0, 12),
      this.enabled = true});
  final Widget child;
  final Duration delay, duration;
  final Offset offset;
  final bool enabled;

  @override
  State<MediaReveal> createState() => _MediaRevealState();
}

class _MediaRevealState extends State<MediaReveal>
    with SingleTickerProviderStateMixin {
  AnimationController? controller;
  late Animation<double> progress;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (controller != null) return;
    if (!widget.enabled || MediaQuery.disableAnimationsOf(context)) return;
    final total = widget.delay + widget.duration;
    controller = AnimationController(vsync: this, duration: total)..forward();
    progress = CurvedAnimation(
        parent: controller!,
        curve: Interval(
            widget.delay.inMicroseconds / total.inMicroseconds, 1,
            curve: AppMotion.curve));
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = this.controller;
    if (controller == null) return widget.child;
    return AnimatedBuilder(
        animation: progress,
        child: widget.child,
        builder: (context, child) => Opacity(
            opacity: progress.value.clamp(0.0, 1.0),
            child: Transform.translate(
                offset: widget.offset * (1 - progress.value),
                child: child)));
  }
}

/// Cross-fades between children with the app's enter and exit timing: the new
/// content eases in on [AppMotion.curve] while the old content leaves faster on
/// the flipped curve.
class MediaSwap extends StatelessWidget {
  const MediaSwap({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
      duration: AppMotion.duration(context, AppMotion.control),
      reverseDuration: AppMotion.duration(context, AppMotion.exit),
      switchInCurve: AppMotion.curve,
      switchOutCurve: AppMotion.curve.flipped,
      layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.topCenter,
          children: [...previous, if (current != null) current]),
      child: child);
}
