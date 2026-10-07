import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'onboarding_style.dart';

/// Native Flutter rendering of the supplied visible-staggered-entrance prototype.
class PwaOnboarding extends StatefulWidget {
  const PwaOnboarding(
      {super.key,
      required this.onContinue,
      this.splashOnly = false,
      this.revealChild,
      this.skipSplash = false});
  final ValueChanged<int> onContinue;
  final bool splashOnly;
  final Widget? revealChild;
  final bool skipSplash;
  @override
  State<PwaOnboarding> createState() => _PwaOnboardingState();
}

class _PwaOnboardingState extends State<PwaOnboarding>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController entrance = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 3100));
  late final Ticker ticker = createTicker(_tick);
  Duration previous = Duration.zero;
  double offset = 0;
  final photoMotion = ValueNotifier<double>(0);
  double cardWidth = 176;
  double viewportWidth = 430;
  bool hovered = false;
  bool dragging = false;
  bool reduced = false;
  bool initialized = false;
  bool continued = false;
  int centre = 0;
  static const revealEase = Cubic(.16, 1, .3, 1);
  static const splashEase = Cubic(.77, 0, .175, 1);
  String photo(int i) => 'assets/images/onboarding_${i % 12}.jpg';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    entrance.addListener(() {
      if (widget.splashOnly && entrance.value * 3100 >= 2770 && !continued) {
        continued = true;
        widget.onContinue(centre);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    reduced = MediaQuery.disableAnimationsOf(context);
    if (initialized) return;
    initialized = true;
    if (widget.splashOnly) {
      // Continue the browser splash at its exit, without replaying the logo
      // entrance or waiting for photos that restored members never see.
      entrance.value = 1550 / 3100;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (reduced) {
          entrance.value = 1;
        } else {
          entrance.forward();
        }
      });
      return;
    }
    // Decode the first visible photos before beginning the reveal.
    Future.wait([
      for (final path in [
        'assets/images/onboarding_logo.png',
        photo(0),
        photo(1),
        photo(2)
      ])
        precacheImage(AssetImage(path), context),
    ]).then((_) {
      if (!mounted) return;
      if (reduced) {
        entrance.value = 1;
      } else {
        entrance.forward(from: widget.skipSplash ? 1 : 0);
        ticker.start();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (widget.splashOnly) return;
    if (state == AppLifecycleState.resumed && !reduced && !ticker.isActive) {
      previous = Duration.zero;
      ticker.start();
    } else if (state != AppLifecycleState.resumed) {
      ticker.stop();
    }
  }

  void _tick(Duration elapsed) {
    final dt = previous == Duration.zero
        ? 0.0
        : (elapsed - previous).inMicroseconds / 1000000;
    previous = elapsed;
    if (entrance.value * 3100 < 1790 || hovered || dragging || reduced) return;
    _move(-28 * dt.clamp(0, .1));
  }

  void _move(double delta) {
    final stride = cardWidth + 12;
    offset = (offset + delta) % (stride * 12);
    if (offset > 0) offset -= stride * 12;
    final nextCentre =
        ((viewportWidth / 2 - offset - cardWidth / 2) / stride).round() % 12;
    // Only the photo strip moves each frame. Static copy and the expensive
    // blurred backdrop update when the selected photograph actually changes.
    if (nextCentre != centre) setState(() => centre = nextCentre);
    photoMotion.value = offset;
  }

  double progress(double start, double duration, [Curve curve = revealEase]) {
    if (reduced) return 1;
    return curve
        .transform(((entrance.value * 3100 - start) / duration).clamp(0, 1));
  }

  Widget appear(Widget child, double start, double duration,
      {double rise = 20, double blur = 7, double scale = 1}) {
    final p = progress(start, duration);
    return IgnorePointer(
        ignoring: p < .95,
        child: Opacity(
            opacity: p,
            child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(
                    sigmaX: blur * (1 - p), sigmaY: blur * (1 - p)),
                child: Transform.translate(
                    offset: Offset(0, rise * (1 - p)),
                    child: Transform.scale(
                        scale: scale + (1 - scale) * p, child: child)))));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ticker.dispose();
    photoMotion.dispose();
    entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.splashOnly
      ? AnimatedBuilder(
          animation: entrance,
          child: widget.revealChild ?? const SizedBox.expand(),
          builder: (context, child) => Stack(fit: StackFit.expand, children: [
                child!,
                if (progress(1550, 1220, splashEase) < 1)
                  Positioned.fill(
                      child: ClipPath(
                          clipper:
                              _SplashClip(1 - progress(1550, 1220, splashEase)),
                          child: ColoredBox(
                              color: Colors.white,
                              child: Center(child: _logo())))),
              ]))
      : Material(
          color: Onb.canvas,
          child: LayoutBuilder(builder: (context, constraints) {
            final width = math.min(430.0, constraints.maxWidth);
            final height = constraints.maxHeight;
            viewportWidth = width;
            cardWidth = height <= 780
                ? 164
                : width <= 390
                    ? 160
                    : 176;
            // Preserve prototype coordinates; scale down only on very short displays.
            final canvasHeight = math.max(700.0, math.min(932.0, height));
            final copyTop = (canvasHeight <= 720
                    ? 386.0
                    : canvasHeight <= 780
                        ? 396.0
                        : width <= 390
                            ? 410.0
                            : 420.0) +
                75;
            final fontSize = canvasHeight <= 720
                ? 30.0
                : canvasHeight <= 780
                    ? 32.0
                    : 36.0;
            final small = canvasHeight <= 780;
            final gutter = width <= 390 ? Onb.s24 : Onb.s32;
            return Center(
                child: SizedBox(
                    width: width,
                    height: math.min(height, 932),
                    child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.topCenter,
                        child: SizedBox(
                            width: width,
                            height: canvasHeight,
                            child: AnimatedBuilder(
                                animation: entrance,
                                builder: (context, _) => ClipRect(
                                        child: Stack(
                                            fit: StackFit.expand,
                                            children: [
                                          ColoredBox(
                                              color: Onb.canvas),
                                          RepaintBoundary(
                                              child: Transform.scale(
                                                  scale: 1.55,
                                                  child: ImageFiltered(
                                                      imageFilter:
                                                          ui.ImageFilter.blur(
                                                              sigmaX: 56,
                                                              sigmaY: 56),
                                                      child: Image.asset(
                                                          photo(centre),
                                                          fit: BoxFit.cover,
                                                          excludeFromSemantics:
                                                              true)))),
                                          const DecoratedBox(
                                              decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                      begin:
                                                          Alignment.topCenter,
                                                      end: Alignment
                                                          .bottomCenter,
                                                      colors: [
                                                Color(0x990b0910),
                                                Color(0xb80b0910),
                                                Color(0xf00b0910)
                                              ],
                                                      stops: [
                                                0,
                                                .5,
                                                1
                                              ]))),
                                          const DecoratedBox(
                                              decoration: BoxDecoration(
                                                  gradient: RadialGradient(
                                                      center:
                                                          Alignment.bottomRight,
                                                      radius: 1.1,
                                                      colors: [
                                                Color(0x248b6cf6),
                                                Color(0x008b6cf6)
                                              ]))),
                                          Positioned(
                                              top: 18,
                                              left: 0,
                                              right: 0,
                                              height: canvasHeight <= 720
                                                  ? 338
                                                  : canvasHeight <= 780
                                                      ? 344
                                                      : width <= 390
                                                          ? 346
                                                          : 356,
                                              child: appear(
                                                  _photos(), 1790, 860,
                                                  rise: 28,
                                                  blur: 8,
                                                  scale: .965)),
                                          Positioned(
                                              top: copyTop,
                                              left: gutter,
                                              right: gutter,
                                              child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                appear(
                                                    Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                      Text(
                                                          'Welcome to\nWPCC Community',
                                                          style: Onb.heading(
                                                              fontSize,
                                                              height: 1.08)),
                                                      SizedBox(
                                                          height: small
                                                              ? Onb.s12
                                                              : Onb.s16),
                                                      ConstrainedBox(
                                                          constraints:
                                                              const BoxConstraints(
                                                                  maxWidth:
                                                                      340),
                                                          child: Text(
                                                              'Connect, grow and stay engaged with everything happening at Wisdom Power Christian Centre.',
                                                              style: Onb.body(
                                                                  small
                                                                      ? 14
                                                                      : 15,
                                                                  alpha: .8,
                                                                  height: small
                                                                      ? 1.42
                                                                      : 1.5))),
                                                    ]),
                                                    1950,
                                                    740),
                                                SizedBox(
                                                    height: canvasHeight <= 720
                                                        ? Onb.s16
                                                        : Onb.s24),
                                                appear(
                                                    _StartButton(
                                                        onPressed: () =>
                                                            widget.onContinue(
                                                                centre),
                                                        height: canvasHeight <=
                                                                720
                                                            ? 52
                                                            : Onb.buttonHeight),
                                                    2130,
                                                    720),
                                              ])),
                                          if (widget.splashOnly &&
                                              widget.revealChild != null)
                                            Positioned.fill(
                                                child: widget.revealChild!),
                                          if (progress(1550, 1220, splashEase) <
                                              1)
                                            Positioned.fill(
                                                child: ClipPath(
                                                    clipper: _SplashClip(1 -
                                                        progress(1550, 1220,
                                                            splashEase)),
                                                    child: ColoredBox(
                                                        color: Colors.white,
                                                        child: Center(
                                                            child: _logo())))),
                                        ])))))));
          }));

  Widget _logo() {
    final inside = progress(160, 1050, const Cubic(.22, .7, .18, 1));
    final outside = entrance.value * 3100 < 1550
        ? 0.0
        : progress(1550, 560, const Cubic(.22, .7, .18, 1));
    return Opacity(
        opacity: inside * (1 - outside),
        child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(
                sigmaX: 14 * (1 - inside) + 7 * outside,
                sigmaY: 14 * (1 - inside) + 7 * outside),
            child: Transform.translate(
                offset: Offset(-5 * outside, 4 * (1 - inside) - 5 * outside),
                child: Transform.scale(
                    scale: (.86 + .14 * inside) * (1 - .1 * outside),
                    child: Image.asset('assets/images/onboarding_logo.png',
                        width: 45, height: 45)))));
  }

  Widget _photos() => RepaintBoundary(
      child: ValueListenableBuilder<double>(
          valueListenable: photoMotion,
          builder: (context, position, _) => MouseRegion(
              onEnter: (_) => hovered = true,
              onExit: (_) => hovered = false,
              cursor: dragging
                  ? SystemMouseCursors.grabbing
                  : SystemMouseCursors.grab,
              child: Listener(
                  onPointerSignal: (event) {
                    if (event is PointerScrollEvent) {
                      _move(-(event.scrollDelta.dx != 0
                              ? event.scrollDelta.dx
                              : event.scrollDelta.dy) *
                          .55);
                    }
                  },
                  child: GestureDetector(
                      onHorizontalDragStart: (_) => dragging = true,
                      onHorizontalDragUpdate: (details) =>
                          _move(details.delta.dx),
                      onHorizontalDragEnd: (_) => dragging = false,
                      onHorizontalDragCancel: () => dragging = false,
                      child: ClipRect(
                          child: Stack(children: [
                        for (int i = 0; i < 24; i++)
                          if (offset + i * (cardWidth + 12) > -cardWidth - 20 &&
                              offset + i * (cardWidth + 12) <
                                  viewportWidth + 20)
                            Positioned(
                                left: offset + i * (cardWidth + 12),
                                top: [22.0, 0.0, 30.0][i % 3],
                                width: cardWidth,
                                height: 320,
                                child: AnimatedScale(
                                    duration: const Duration(milliseconds: 280),
                                    scale: i % 12 == centre ? 1.04 : 1,
                                    child: AnimatedSlide(
                                        duration:
                                            const Duration(milliseconds: 280),
                                        offset: i % 12 == centre
                                            ? const Offset(0, -.025)
                                            : Offset.zero,
                                        child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                                Onb.radiusCard),
                                            child: Stack(
                                                fit: StackFit.expand,
                                                children: [
                                                  Image.asset(photo(i),
                                                      fit: BoxFit.cover,
                                                      semanticLabel:
                                                          'WPCC community photo ${i % 12 + 1}'),
                                                  const DecoratedBox(
                                                      decoration: BoxDecoration(
                                                          gradient: LinearGradient(
                                                              begin: Alignment
                                                                  .topCenter,
                                                              end: Alignment
                                                                  .bottomCenter,
                                                              colors: [
                                                        Color(0x05ffffff),
                                                        Color(0x47000000)
                                                      ]))),
                                                  // Inner edge: keeps the
                                                  // photograph crisp on the
                                                  // blurred backdrop.
                                                  DecoratedBox(
                                                      decoration: BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(Onb
                                                                      .radiusCard),
                                                          border: Border.all(
                                                              color: Onb
                                                                  .inkAlpha(
                                                                      .14)))),
                                                ]))))),
                      ])))))));
}

class _SplashClip extends CustomClipper<Path> {
  const _SplashClip(this.remaining);
  final double remaining;
  @override
  Path getClip(Size size) => Path()
    ..addOval(Rect.fromCircle(
        center: Offset.zero,
        radius: 1.5 * math.max(size.width, size.height) * remaining));
  @override
  bool shouldReclip(_SplashClip oldClipper) =>
      oldClipper.remaining != remaining;
}

/// Full-width primary action, bounded by the copy column.
class _StartButton extends StatelessWidget {
  const _StartButton({required this.onPressed, required this.height});
  final VoidCallback onPressed;
  final double height;
  @override
  Widget build(BuildContext context) => ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: OnbPrimaryButton(
          label: 'Get Started', height: height, onPressed: onPressed));
}
