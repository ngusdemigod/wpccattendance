import 'package:flutter/material.dart';

/// Content placeholders only; mutation progress keeps its explicit indicator.
class MemberSkeleton extends StatefulWidget {
  const MemberSkeleton(
      {super.key,
      this.rows = 3,
      this.hero = false,
      this.label = 'Loading content'})
      : size = null,
        imageHeight = null,
        circular = false,
        radius = 12;
  const MemberSkeleton.image(
      {super.key,
      this.size = 64,
      this.imageHeight,
      this.circular = false,
      this.radius = 12,
      this.label = 'Loading image'})
      : rows = 0,
        hero = false;
  final int rows;
  final bool hero;
  final String label;
  final double? size;
  final double? imageHeight;
  final bool circular;
  final double radius;

  @override
  State<MemberSkeleton> createState() => _MemberSkeletonState();
}

class _MemberSkeletonState extends State<MemberSkeleton>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _animation = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1500));
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateMotion();
  }

  void _updateMotion() {
    final animate = _foreground &&
        TickerMode.valuesOf(context).enabled &&
        !MediaQuery.disableAnimationsOf(context) &&
        !MediaQuery.of(context).accessibleNavigation;
    if (animate && !_animation.isAnimating) _animation.repeat();
    if (!animate) _animation.stop();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _updateMotion();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animation.dispose();
    super.dispose();
  }

  Widget _block({double? width, required double height, double radius = 8}) =>
      Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(radius)));

  @override
  Widget build(BuildContext context) => Semantics(
        label: widget.label,
        child: ExcludeSemantics(
            child: RepaintBoundary(
                child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) => ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (bounds) => LinearGradient(
              begin: Alignment(-3 + _animation.value * 6, 0),
              end: Alignment(-1 + _animation.value * 6, 0),
              colors: [
                Colors.transparent,
                Colors.white.withValues(alpha: .12),
                Colors.transparent
              ],
            ).createShader(bounds),
            child: child,
          ),
          child: widget.size != null
              ? Container(
                  width: widget.size,
                  height: widget.circular
                      ? widget.size
                      : widget.imageHeight ?? widget.size,
                  decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      shape: widget.circular
                          ? BoxShape.circle
                          : BoxShape.rectangle,
                      borderRadius: widget.circular
                          ? null
                          : BorderRadius.circular(widget.radius)))
              : Column(mainAxisSize: MainAxisSize.min, children: [
                  if (widget.hero) ...[
                    AspectRatio(
                        aspectRatio: 1.6,
                        child: _block(height: 180, radius: 20)),
                    const SizedBox(height: 20),
                  ],
                  for (var index = 0; index < widget.rows; index++)
                    Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(children: [
                          _block(width: 48, height: 48, radius: 12),
                          const SizedBox(width: 14),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                FractionallySizedBox(
                                    widthFactor: .78,
                                    child: _block(height: 14)),
                                const SizedBox(height: 10),
                                FractionallySizedBox(
                                    widthFactor: .5, child: _block(height: 10)),
                              ])),
                        ])),
                ]),
        ))),
      );
}
