import 'package:flutter/material.dart';

class WpccShimmer extends StatefulWidget {
  const WpccShimmer({
    super.key,
    required this.child,
    this.baseColor = const Color(0xFFECEFF3),
    this.highlightColor = const Color(0xFFF7F8FA),
    this.duration = const Duration(milliseconds: 1350),
  });

  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final Duration duration;

  @override
  State<WpccShimmer> createState() => _WpccShimmerState();
}

class _WpccShimmerState extends State<WpccShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..repeat();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations;
    if (disableAnimations ?? false) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations;
    if (disableAnimations ?? false) {
      return ColoredBox(
        color: widget.baseColor,
        child: widget.child,
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      child: ColoredBox(
        color: widget.baseColor,
        child: widget.child,
      ),
      builder: (context, child) {
        final begin = -1.0 + (_controller.value * 2.0);
        final end = begin + 1.0;
        return ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment(begin, 0),
            end: Alignment(end, 0),
            colors: [
              widget.baseColor,
              widget.highlightColor,
              widget.baseColor,
            ],
            stops: const [0.1, 0.45, 0.9],
          ).createShader(bounds),
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
    );
  }
}

class WpccShimmerBlock extends StatelessWidget {
  const WpccShimmerBlock({
    super.key,
    required this.width,
    required this.height,
    this.radius = 999,
    this.baseColor = const Color(0xFFECEFF3),
    this.highlightColor = const Color(0xFFF7F8FA),
  });

  final double width;
  final double height;
  final double radius;
  final Color baseColor;
  final Color highlightColor;

  @override
  Widget build(BuildContext context) {
    return WpccShimmer(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class WpccShimmerCircle extends StatelessWidget {
  const WpccShimmerCircle({
    super.key,
    required this.size,
    this.baseColor = const Color(0xFFECEFF3),
    this.highlightColor = const Color(0xFFF7F8FA),
  });

  final double size;
  final Color baseColor;
  final Color highlightColor;

  @override
  Widget build(BuildContext context) {
    return WpccShimmer(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: baseColor,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class WpccShimmerCard extends StatelessWidget {
  const WpccShimmerCard({
    super.key,
    this.height,
    this.padding = const EdgeInsets.all(16),
    this.radius = 30,
    this.backgroundColor = const Color(0xFFFCFBF9),
    this.borderColor = const Color(0x14111827),
    required this.child,
  });

  final double? height;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color backgroundColor;
  final Color borderColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }
}

class WpccScreenShimmer extends StatelessWidget {
  const WpccScreenShimmer({
    super.key,
    this.includeBottomNavSpace = true,
  });

  final bool includeBottomNavSpace;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        20,
        18,
        20,
        includeBottomNavSpace ? 108 : 24,
      ),
      children: const [
        Row(
          children: [
            WpccShimmerBlock(width: 140, height: 14, radius: 8),
            Spacer(),
            WpccShimmerCircle(size: 38),
            SizedBox(width: 10),
            WpccShimmerCircle(size: 38),
          ],
        ),
        SizedBox(height: 14),
        WpccShimmerCard(
          height: 128,
          radius: 24,
          padding: EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WpccShimmerBlock(width: 74, height: 12, radius: 8),
              Spacer(),
              WpccShimmerBlock(width: 170, height: 20, radius: 10),
              SizedBox(height: 8),
              WpccShimmerBlock(width: 128, height: 16, radius: 8),
            ],
          ),
        ),
        SizedBox(height: 18),
        WpccShimmerBlock(width: 210, height: 16, radius: 8),
        SizedBox(height: 10),
        WpccShimmerCard(height: 138, radius: 26, child: SizedBox.expand()),
        SizedBox(height: 12),
        WpccShimmerCard(height: 138, radius: 26, child: SizedBox.expand()),
      ],
    );
  }
}
