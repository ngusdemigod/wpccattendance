import 'package:flutter/material.dart';

/// One shimmer for a whole skeleton. Wrap a tree of [MemberBone] shapes in it
/// and a soft highlight sweeps across all of them together, from a single
/// animation (many separate shimmering boxes would each run their own).
/// The sweep stops under reduced motion and when the screen is in the
/// background, and the skeleton is hidden from screen readers except for one
/// label.
class MemberShimmer extends StatefulWidget {
  const MemberShimmer(
      {super.key, required this.child, this.label = 'Loading content'});
  final Widget child;
  final String label;

  @override
  State<MemberShimmer> createState() => _MemberShimmerState();
}

class _MemberShimmerState extends State<MemberShimmer>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController sweep = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400));
  bool foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _update();
  }

  void _update() {
    final animate = foreground &&
        TickerMode.valuesOf(context).enabled &&
        !MediaQuery.disableAnimationsOf(context) &&
        !MediaQuery.of(context).accessibleNavigation;
    if (animate && !sweep.isAnimating) sweep.repeat();
    if (!animate) sweep.stop();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    foreground = state == AppLifecycleState.resumed;
    _update();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Semantics(
        label: widget.label,
        child: ExcludeSemantics(
            child: RepaintBoundary(
                child: AnimatedBuilder(
                    animation: sweep,
                    child: widget.child,
                    builder: (context, child) => ShaderMask(
                        blendMode: BlendMode.srcATop,
                        shaderCallback: (bounds) => LinearGradient(
                              begin: Alignment(-2.2 + sweep.value * 4.4, -.3),
                              end: Alignment(-.6 + sweep.value * 4.4, .3),
                              colors: [
                                Colors.transparent,
                                onSurface.withValues(alpha: .10),
                                Colors.transparent,
                              ],
                            ).createShader(bounds),
                        child: child)))));
  }
}

/// A placeholder shape: a rounded box, or a circle when [circle] is true.
/// Without a [width] it fills its parent's width.
class MemberBone extends StatelessWidget {
  const MemberBone(
      {super.key,
      this.width,
      required this.height,
      this.radius = 8,
      this.circle = false});
  final double? width;
  final double height;
  final double radius;
  final bool circle;

  @override
  Widget build(BuildContext context) => DecoratedBox(
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          shape: circle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: circle ? null : BorderRadius.circular(radius)),
      child: SizedBox(
          width: circle ? height : (width ?? double.infinity), height: height));
}
