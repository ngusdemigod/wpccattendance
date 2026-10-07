import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'onboarding_style.dart';

/// Award presentation from mobile onboarding prototype v3.
/// Entitlement is supplied by the parent after checking the server ledger.
class ProfileRewardScreen extends StatefulWidget {
  const ProfileRewardScreen(
      {super.key, required this.awarded, required this.onClose});
  final bool awarded;
  final VoidCallback onClose;
  @override
  State<ProfileRewardScreen> createState() => _ProfileRewardScreenState();
}

class _ProfileRewardScreenState extends State<ProfileRewardScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final entry = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2400));
  final clock = ValueNotifier<double>(0);
  late final Ticker ticker = createTicker(
      (elapsed) => clock.value = base + elapsed.inMicroseconds / 1000000);
  late final motion = Listenable.merge([entry, clock]);
  late final link = TapGestureRecognizer()..onTap = learnMore;
  Timer? linkReset;
  bool reduced = false, started = false, expandedLink = false, closing = false;
  double base = 0;
  static const reveal = Cubic(.16, 1, .3, 1);
  static const ease = Cubic(.22, .72, .18, 1);
  static const bounce = Cubic(.18, 1.32, .36, 1);
  static const floatEase = Cubic(.45, .05, .55, .95);
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    reduced = MediaQuery.disableAnimationsOf(context);
    if (reduced) {
      entry.value = 1;
      ticker.stop();
    } else {
      if (!started) entry.forward();
      if (!ticker.isActive) {
        base = clock.value;
        ticker.start();
      }
    }
    started = true;
  }

  @override
  void didUpdateWidget(ProfileRewardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.awarded && widget.awarded && !reduced) {
      entry.forward(from: 0);
      clock.value = 0;
      base = 0;
      ticker.stop();
      ticker.start();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !reduced && !ticker.isActive) {
      base = clock.value;
      ticker.start();
    } else if (state != AppLifecycleState.resumed) {
      ticker.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ticker.dispose();
    clock.dispose();
    entry.dispose();
    link.dispose();
    linkReset?.cancel();
    super.dispose();
  }

  void learnMore() {
    if (expandedLink) return;
    setState(() => expandedLink = true);
    linkReset = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => expandedLink = false);
    });
  }

  Future<void> close() async {
    if (closing) return;
    setState(() => closing = true);
    if (!reduced) await Future<void>.delayed(const Duration(milliseconds: 180));
    if (mounted) widget.onClose();
  }

  double phase(double delay, double duration) =>
      reduced ? 1 : ((entry.value * 2400 - delay) / duration).clamp(0, 1);
  TextStyle body(double size,
          {double alpha = 1, FontWeight weight = FontWeight.w400}) =>
      GoogleFonts.dmSans(
          fontSize: size,
          height: 1.5,
          fontWeight: weight,
          color: Colors.white.withValues(alpha: alpha),
          decoration: TextDecoration.none);
  Widget revealChild(Widget child, double delay, double duration,
          {double blur = 8, double rise = 18, double fromScale = 1}) =>
      AnimatedBuilder(
          animation: entry,
          child: child,
          builder: (context, child) {
            final t = reveal.transform(phase(delay, duration));
            return IgnorePointer(
                ignoring: t == 0,
                child: Opacity(
                    opacity: t,
                    child: Transform.translate(
                        offset: Offset(0, rise * (1 - t)),
                        child: ImageFiltered(
                            enabled: t < 1,
                            imageFilter: ui.ImageFilter.blur(
                                sigmaX: blur * (1 - t), sigmaY: blur * (1 - t)),
                            child: Transform.scale(
                                scale: fromScale + (1 - fromScale) * t,
                                child: child)))));
          });
  double keyframe(
      double t, List<double> stops, List<double> values, Curve curve) {
    var i = 0;
    while (i < stops.length - 2 && t > stops[i + 1]) {
      i++;
    }
    final p = curve
        .transform(((t - stops[i]) / (stops[i + 1] - stops[i])).clamp(0, 1));
    return values[i] + (values[i + 1] - values[i]) * p;
  }

  Widget badge(double size) => AnimatedBuilder(
      animation: motion,
      child: RepaintBoundary(
          child: SizedBox(
              width: size,
              height: size,
              child: Stack(clipBehavior: Clip.none, children: [
                if (!reduced) ...[
                  for (final shadow in [
                    const BoxShadow(
                        color: Color(0x660b0910),
                        offset: Offset(0, 24),
                        blurRadius: 36),
                    const BoxShadow(color: Color(0x338b6cf6), blurRadius: 28)
                  ])
                    Transform.translate(
                        offset: shadow.offset,
                        child: ImageFiltered(
                            imageFilter: ui.ImageFilter.blur(
                                sigmaX: shadow.blurRadius,
                                sigmaY: shadow.blurRadius),
                            child: ColorFiltered(
                                colorFilter: ColorFilter.mode(
                                    shadow.color, BlendMode.srcIn),
                                child: Image.asset(
                                    'assets/images/profile_reward_badge.png',
                                    width: size,
                                    height: size,
                                    fit: BoxFit.contain,
                                    excludeFromSemantics: true)))),
                ],
                Image.asset('assets/images/profile_reward_badge.png',
                    key: const Key('reward-badge'),
                    width: size,
                    height: size,
                    fit: BoxFit.contain,
                    excludeFromSemantics: true),
              ]))),
      builder: (context, child) {
        final t = phase(480, 1080);
        const stops = [0.0, .56, .76, 1.0];
        var y = keyframe(t, stops, [-28, 8, -5, 0], bounce);
        var scale = keyframe(t, stops, [.46, 1.08, .985, 1], bounce);
        var angle = keyframe(t, stops, [-8, 2, -1, 0], bounce);
        if (!reduced && clock.value >= 1.62) {
          final f = ((clock.value - 1.62) % 4.8) / 4.8;
          const fs = [0.0, .25, .5, .75, 1.0];
          y = keyframe(f, fs, [0, -6, -11, -5, 0], floatEase);
          scale = keyframe(f, fs, [1, 1.008, 1.012, 1.007, 1], floatEase);
          angle = keyframe(f, fs, [-1, .8, -.6, .7, -1], floatEase);
        }
        final opacity = bounce.transform((t / .56).clamp(0, 1)).clamp(0.0, 1.0);
        final blur =
            10 * (1 - bounce.transform((t / .56).clamp(0, 1)).clamp(0.0, 1.0));
        return Opacity(
            opacity: opacity,
            child: Transform.translate(
                offset: Offset(0, y),
                child: Transform.rotate(
                    angle: angle * math.pi / 180,
                    child: Transform.scale(
                        scale: scale,
                        child: ImageFiltered(
                            enabled: blur > 0,
                            imageFilter:
                                ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                            child: child)))));
      });
  Widget halo() => AnimatedBuilder(
      animation: motion,
      child: RepaintBoundary(
          child: ImageFiltered(
              enabled: !reduced,
              imageFilter: ui.ImageFilter.blur(sigmaX: 22, sigmaY: 22),
              child: const SizedBox(
                  width: 260,
                  height: 260,
                  child: DecoratedBox(
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(radius: .70710678, colors: [
                            Color(0x428b6cf6),
                            Color(0x188b6cf6),
                            Colors.transparent
                          ], stops: [
                            0,
                            .45,
                            .72
                          ])))))),
      builder: (context, child) {
        final t = Curves.ease.transform(phase(520, 1100));
        var opacity = .9 * t;
        var scale = .78 + .22 * t;
        if (!reduced && clock.value >= 1.62) {
          final f = ((clock.value - 1.62) % 4.4) / 4.4;
          final p = Curves.easeInOut.transform(f < .5 ? f * 2 : (1 - f) * 2);
          opacity = .72 + .28 * p;
          scale = .96 + .09 * p;
        }
        return Opacity(
            opacity: opacity,
            child: Transform.scale(scale: scale, child: child));
      });
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final short = MediaQuery.sizeOf(context).height <= 780;
        final safe = MediaQuery.paddingOf(context);
        final top = (short ? 62.0 : 68.0) + safe.top;
        final bottom = (short ? 26.0 : 34.0) + safe.bottom;
        final showcase = short ? 246.0 : 310.0;
        final badgeSize = short ? 176.0 : 212.0;
        final margin = short ? 0.0 : 14.0;
        return AnimatedOpacity(
            opacity: closing ? 0 : 1,
            duration: Duration(milliseconds: reduced ? 0 : 180),
            child: Material(
                color: Onb.canvas,
                child: Stack(fit: StackFit.expand, children: [
                  AnimatedBuilder(
                      animation: entry,
                      child: const RepaintBoundary(
                          child: CustomPaint(painter: _RewardBackground())),
                      builder: (context, child) {
                        final t = ease.transform(phase(0, 1050));
                        return Opacity(
                            opacity: t,
                            child: Transform.scale(
                                scale: 1 + .035 * (1 - t), child: child));
                      }),
                  if (!reduced)
                    IgnorePointer(
                        child: RepaintBoundary(
                            child: CustomPaint(
                                painter: _RewardStars(clock, entry)))),
                  SingleChildScrollView(
                      child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: box.maxHeight),
                          child: Padding(
                              padding: EdgeInsets.fromLTRB(short ? 24 : 28, top,
                                  short ? 24 : 28, bottom),
                              child: IntrinsicHeight(
                                  child: Column(children: [
                                SizedBox(height: margin),
                                SizedBox(
                                    height: showcase,
                                    width: double.infinity,
                                    child: Stack(
                                        alignment: Alignment.center,
                                        children: [halo(), badge(badgeSize)])),
                                revealChild(
                                    ConstrainedBox(
                                        constraints:
                                            const BoxConstraints(maxWidth: 350),
                                        child: Column(children: [
                                          Text(
                                              widget.awarded
                                                  ? '+15WP'
                                                  : 'Reward on its way',
                                              key: const Key('reward-title'),
                                              textAlign: TextAlign.center,
                                              style: Onb.heading(short ? 30 : 34,
                                                      height: 1.08)
                                                  .copyWith(
                                                      decoration:
                                                          TextDecoration.none)),
                                          const SizedBox(height: Onb.s12),
                                          ConstrainedBox(
                                              constraints: const BoxConstraints(
                                                  maxWidth: 320),
                                              child: Text(
                                                  widget.awarded
                                                      ? "You've been awarded 15WP for completing your profile."
                                                      : 'Your details are saved. Your one-time reward is being processed securely. You can continue using the app.',
                                                  textAlign: TextAlign.center,
                                                  style: Onb.body(15, alpha: .78)
                                                      .copyWith(
                                                          decoration:
                                                              TextDecoration
                                                                  .none))),
                                        ])),
                                    1020,
                                    760),
                                const Spacer(),
                                const SizedBox(height: Onb.s24),
                                revealChild(
                                    ConstrainedBox(
                                        constraints:
                                            const BoxConstraints(maxWidth: 420),
                                        child: OnbPrimaryButton(
                                            label: 'Continue',
                                            onPressed: close)),
                                    1300,
                                    740),
                                const SizedBox(height: Onb.s12),
                                revealChild(
                                    ConstrainedBox(
                                        constraints:
                                            const BoxConstraints(maxWidth: 340),
                                        child: FocusableActionDetector(
                                            actions: {
                                              ActivateIntent: CallbackAction<
                                                      ActivateIntent>(
                                                  onInvoke: (_) {
                                                learnMore();
                                                return null;
                                              })
                                            },
                                            child: Semantics(
                                                link: true,
                                                label:
                                                    'Learn more about points',
                                                onTap: learnMore,
                                                child: Text.rich(
                                                    TextSpan(children: [
                                                      const TextSpan(
                                                          text:
                                                              'Earn points by engaging and participating in activities on the app '),
                                                      TextSpan(
                                                          text: expandedLink
                                                              ? 'More ways to earn WP coming soon'
                                                              : 'Learn more',
                                                          recognizer: link,
                                                          style: body(12,
                                                                  alpha: .97,
                                                                  weight:
                                                                      FontWeight
                                                                          .w700)
                                                              .copyWith(
                                                                  decoration:
                                                                      TextDecoration
                                                                          .underline,
                                                                  decorationColor:
                                                                      Onb.ink)),
                                                      const TextSpan(
                                                          text:
                                                              ' on what those points are used for'),
                                                    ]),
                                                    key: const Key(
                                                        'reward-footer'),
                                                    textAlign: TextAlign.center,
                                                    style: body(12, alpha: .72)
                                                        .copyWith(height: 1.45))))),
                                    1300,
                                    740),
                              ]))))),
                  Positioned(
                      top: 20 + safe.top,
                      right: 20 + safe.right,
                      child: revealChild(
                          SizedBox(
                              width: Onb.minTarget,
                              height: Onb.minTarget,
                              child: IconButton(
                                  tooltip: 'Close reward',
                                  onPressed: close,
                                  padding: EdgeInsets.zero,
                                  style: IconButton.styleFrom(
                                      backgroundColor: Onb.inkAlpha(.08),
                                      foregroundColor: Onb.ink,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              Onb.radiusControl)),
                                      side: BorderSide(
                                          color: Onb.inkAlpha(.14))),
                                  icon: Icon(PhosphorIcons.x(), size: 20))),
                          720,
                          500,
                          blur: 4,
                          rise: 0,
                          fromScale: .82)),
                ])));
      });
}

class _RewardBackground extends CustomPainter {
  const _RewardBackground();
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
        rect,
        Paint()
          ..shader = const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xff161338), Color(0xff0d0b1f), Color(0xff0b0910)],
              stops: [0, .5, 1]).createShader(rect));
    void radial(double y, List<Color> colors, List<double> stops) {
      final center = Offset(size.width * .5, size.height * y);
      final far = math.sqrt(math.pow(size.width / 2, 2) +
          math.pow(math.max(y.abs(), (1 - y).abs()) * size.height, 2));
      canvas.drawRect(rect,
          Paint()..shader = ui.Gradient.radial(center, far, colors, stops));
    }

    radial(.34, [const Color(0x2e8b6cf6), const Color(0x008b6cf6)], [0, .4]);
    radial(-.08, [const Color(0x293f4fd6), const Color(0x003f4fd6)], [0, .38]);
  }

  @override
  bool shouldRepaint(_RewardBackground old) => false;
}

class _RewardStars extends CustomPainter {
  _RewardStars(this.clock, this.entry)
      : super(repaint: Listenable.merge([clock, entry]));
  final ValueNotifier<double> clock;
  final Animation<double> entry;
  @override
  void paint(Canvas canvas, Size size) {
    final fade =
        Curves.ease.transform(((entry.value * 2400 - 180) / 750).clamp(0, 1));
    for (var n = 1; n <= 20; n++) {
      final duration = 7.5 + (n % 6) * 1.15;
      final delay = (n * 1.37) % 9.5;
      final t = ((clock.value + delay) % duration) / duration;
      final op = .28 + (n % 5) * .12;
      final opacity = (t < .1
              ? t / .1
              : t < .82
                  ? 1 - .1 * (t - .1) / .72
                  : .9 * (1 - t) / .18) *
          op *
          fade;
      final point = Offset(((n * 37 + 3) % 94) / 100 * size.width,
          size.height + 18 - 1.12 * size.height * t);
      final radius = (2 + n % 4) / 2 * (.7 + .45 * t);
      final color = n % 3 == 0 ? Onb.ink : Onb.accentLight;
      canvas.drawCircle(
          point,
          radius + 3,
          Paint()
            ..color = color.withValues(alpha: opacity * .15)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
      canvas.drawCircle(
          point, radius, Paint()..color = color.withValues(alpha: opacity));
    }
  }

  @override
  bool shouldRepaint(_RewardStars old) =>
      old.clock != clock || old.entry != entry;
}
