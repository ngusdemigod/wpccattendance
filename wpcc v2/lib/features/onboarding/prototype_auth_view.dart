import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_motion.dart';

class PrototypeAuthScope extends InheritedWidget {
  const PrototypeAuthScope(
      {super.key,
      required this.photo,
      required this.onBack,
      required super.child});
  final int photo;
  final VoidCallback onBack;
  static PrototypeAuthScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PrototypeAuthScope>();
  @override
  bool updateShouldNotify(PrototypeAuthScope oldWidget) =>
      oldWidget.photo != photo;
}

/// Presentation only: all submission/verification remains in LoginPage.
class PrototypeAuthView extends StatefulWidget {
  const PrototypeAuthView(
      {super.key,
      required this.scope,
      required this.code,
      required this.email,
      required this.password,
      required this.otp,
      required this.useEmail,
      required this.usePassword,
      required this.otpSent,
      required this.linkSent,
      required this.loading,
      required this.verifying,
      required this.resendSeconds,
      required this.onMode,
      required this.onSubmit,
      required this.onVerify,
      required this.onResend,
      required this.onBack,
      this.error,
      this.maskedEmail});
  final PrototypeAuthScope scope;
  final TextEditingController code, email, password, otp;
  final bool useEmail, usePassword, otpSent, linkSent, loading, verifying;
  final int resendSeconds;
  final String? error, maskedEmail;
  final void Function(bool email, bool password) onMode;
  final VoidCallback onSubmit, onVerify, onResend, onBack;
  @override
  State<PrototypeAuthView> createState() => _PrototypeAuthViewState();
}

class _PrototypeAuthViewState extends State<PrototypeAuthView>
    with TickerProviderStateMixin {
  late final AnimationController entrance = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 680));
  late final AnimationController kenBurns =
      AnimationController(vsync: this, duration: const Duration(seconds: 14));
  bool selected = false;
  bool obscure = true;
  late final AnimationController fieldEntrance =
      AnimationController(vsync: this, duration: AppMotion.control, value: 1);
  static const ease = Cubic(.22, .72, .18, 1);
  bool get verification => widget.otpSent || widget.linkSent;
  TextStyle body(double size,
          {Color color = Colors.white, FontWeight weight = FontWeight.w400}) =>
      GoogleFonts.dmSans(
          fontSize: size, color: color, fontWeight: weight, height: 1.42);
  TextStyle heading(double size) => GoogleFonts.manrope(
      fontSize: size,
      height: .98,
      letterSpacing: -size * .055,
      fontWeight: FontWeight.w800,
      color: Colors.white);
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      entrance.value = 1;
      fieldEntrance.value = 1;
      kenBurns.stop();
    } else {
      if (entrance.value == 0) entrance.forward();
      if (!kenBurns.isAnimating) kenBurns.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    entrance.dispose();
    kenBurns.dispose();
    fieldEntrance.dispose();
    super.dispose();
  }

  void choose(bool email, bool password) {
    setState(() => selected = true);
    widget.onMode(email, password);
    if (MediaQuery.disableAnimationsOf(context)) {
      fieldEntrance.value = 1;
    } else {
      fieldEntrance.forward(from: 0);
    }
  }

  Widget button(String label, VoidCallback? action,
          {Color fill = Colors.white}) =>
      SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton(
              onPressed: action,
              style: FilledButton.styleFrom(
                  backgroundColor: fill,
                  foregroundColor: fill == Colors.white
                      ? const Color(0xff151515)
                      : Colors.white,
                  disabledBackgroundColor: Colors.white.withValues(alpha: .18),
                  disabledForegroundColor: Colors.white38,
                  shape: const StadiumBorder(),
                  textStyle: body(14, weight: FontWeight.w600)),
              child: Text(label)));
  Widget field(String label, TextEditingController controller,
          {bool email = false, bool secret = false}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: body(12, color: Colors.white70, weight: FontWeight.w600)),
        const SizedBox(height: 9),
        TextField(
            controller: controller,
            enabled: !widget.loading,
            obscureText: secret && obscure,
            autofillHints: secret
                ? const [AutofillHints.password]
                : email
                    ? const [AutofillHints.email]
                    : null,
            keyboardType:
                email ? TextInputType.emailAddress : TextInputType.text,
            style: body(15, weight: FontWeight.w500),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => widget.onSubmit(),
            decoration: InputDecoration(
                hintText: secret
                    ? 'Enter your password'
                    : email
                        ? 'Enter your email address'
                        : 'Enter your member code',
                hintStyle: body(15, color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withValues(alpha: .12),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: Colors.white24)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: Colors.white24)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: Colors.white60)),
                suffixIcon: secret
                    ? IconButton(
                        tooltip: obscure ? 'Show password' : 'Hide password',
                        onPressed: () => setState(() => obscure = !obscure),
                        icon: Icon(
                            obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: Colors.white70))
                    : null)),
      ]);
  @override
  Widget build(BuildContext context) {
    final short = MediaQuery.sizeOf(context).height <= 780;
    final canSubmit = (widget.useEmail || widget.usePassword
            ? widget.email.text.trim().isNotEmpty
            : widget.code.text.trim().isNotEmpty) &&
        (!widget.usePassword || widget.password.text.isNotEmpty) &&
        !widget.loading;
    final transition = CurvedAnimation(parent: entrance, curve: ease);
    return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
            child: ConstrainedBox(
                constraints: const BoxConstraints.expand(),
                child: FadeTransition(
                    opacity: transition,
                    child: SlideTransition(
                        position: Tween(
                                begin: const Offset(0, .035), end: Offset.zero)
                            .animate(transition),
                        child: Stack(fit: StackFit.expand, children: [
                          AnimatedBuilder(
                              animation: kenBurns,
                              builder: (context, background) => Transform.scale(
                                  scale: 1.015 + .04 * kenBurns.value,
                                  child: background),
                              child: RepaintBoundary(
                                  child: ImageFiltered(
                                      imageFilter: ui.ImageFilter.blur(
                                          sigmaX: verification
                                              ? 10
                                              : selected
                                                  ? 2
                                                  : 0,
                                          sigmaY: verification
                                              ? 10
                                              : selected
                                                  ? 2
                                                  : 0),
                                      child: Image.asset(
                                          'assets/images/onboarding_${widget.scope.photo}.jpg',
                                          fit: BoxFit.cover,
                                          color: Colors.black.withValues(
                                              alpha: verification ? .38 : .24),
                                          colorBlendMode: BlendMode.darken,
                                          excludeFromSemantics: true)))),
                          const DecoratedBox(
                              decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                Color(0x1f070608),
                                Color(0x2b070608),
                                Color(0x5c070608),
                                Color(0xa8070608)
                              ],
                                      stops: [
                                0,
                                .34,
                                .68,
                                1
                              ]))),
                          const DecoratedBox(
                              decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                      center: Alignment(0, 1.24),
                                      radius: 1.15,
                                      colors: [
                                Color(0x4d843fff),
                                Color(0x26843fff),
                                Color(0x00843fff)
                              ],
                                      stops: [
                                0,
                                .42,
                                1
                              ]))),
                          SafeArea(
                              child: Column(children: [
                            Align(
                                alignment: Alignment.topLeft,
                                child: Padding(
                                    padding: const EdgeInsets.only(
                                        left: 20, top: 17, bottom: 7),
                                    child: IconButton.filledTonal(
                                        tooltip: 'Go back',
                                        onPressed: widget.loading
                                            ? null
                                            : () {
                                                if (verification) {
                                                  widget.onBack();
                                                  return;
                                                }
                                                if (selected) {
                                                  setState(
                                                      () => selected = false);
                                                  return;
                                                }
                                                widget.scope.onBack();
                                              },
                                        style: IconButton.styleFrom(
                                            backgroundColor: Colors.white
                                                .withValues(alpha: .08),
                                            foregroundColor: Colors.white,
                                            side: const BorderSide(
                                                color: Colors.white12)),
                                        icon: const Icon(Icons.chevron_left,
                                            size: 30)))),
                            Expanded(
                                child: LayoutBuilder(
                                    builder: (context, c) =>
                                        SingleChildScrollView(
                                            padding: EdgeInsets.fromLTRB(
                                                short ? 24 : 28,
                                                0,
                                                short ? 24 : 28,
                                                short ? 26 : 34),
                                            child: Center(
                                                child: ConstrainedBox(
                                                    constraints: BoxConstraints(
                                                        maxWidth: 520,
                                                        minHeight: (c
                                                                    .maxHeight -
                                                                (short
                                                                    ? 26
                                                                    : 34))
                                                            .clamp(
                                                                0,
                                                                double
                                                                    .infinity)),
                                                    child: verification
                                                        ? _verification(short)
                                                        : Column(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .end,
                                                            children: [
                                                                Image.asset(
                                                                    'assets/images/onboarding_logo.png',
                                                                    width: short
                                                                        ? 46
                                                                        : 50,
                                                                    height: short
                                                                        ? 46
                                                                        : 50),
                                                                SizedBox(
                                                                    height: short
                                                                        ? 16
                                                                        : 22),
                                                                Text(
                                                                    'Welcome back',
                                                                    style: body(
                                                                        12,
                                                                        color: Colors
                                                                            .white60,
                                                                        weight:
                                                                            FontWeight.w600)),
                                                                const SizedBox(
                                                                    height: 9),
                                                                Text(
                                                                    'Sign in to\nWPCC Community',
                                                                    textAlign:
                                                                        TextAlign
                                                                            .center,
                                                                    style: heading(
                                                                        short
                                                                            ? 29
                                                                            : 31)),
                                                                const SizedBox(
                                                                    height: 14),
                                                                Text(
                                                                    'Use your membership code or email address to continue.',
                                                                    textAlign:
                                                                        TextAlign
                                                                            .center,
                                                                    style: body(
                                                                        14,
                                                                        color: Colors
                                                                            .white
                                                                            .withValues(alpha: .76))),
                                                                AnimatedSize(
                                                                    duration: MediaQuery.disableAnimationsOf(
                                                                            context)
                                                                        ? Duration
                                                                            .zero
                                                                        : AppMotion
                                                                            .control,
                                                                    curve: AppMotion
                                                                        .curve,
                                                                    child: selected
                                                                        ? const SizedBox(height: 22)
                                                                        : Padding(
                                                                            padding: EdgeInsets.only(top: short ? 20 : 26),
                                                                            child: Column(children: [
                                                                              button('Sign in with membership code', () => choose(false, false)),
                                                                              const SizedBox(height: 12),
                                                                              button('Sign in with email', () => choose(true, false), fill: const Color(0xff8f6cf4)),
                                                                              TextButton(onPressed: () => choose(true, true), child: Text('Sign in with password', style: body(12, color: Colors.white70))),
                                                                            ]))),
                                                                if (selected) ...[
                                                                  AnimatedBuilder(
                                                                      animation:
                                                                          fieldEntrance,
                                                                      child: field(
                                                                          widget.useEmail || widget.usePassword
                                                                              ? 'Email address'
                                                                              : 'Membership code',
                                                                          widget.useEmail || widget.usePassword
                                                                              ? widget
                                                                                  .email
                                                                              : widget
                                                                                  .code,
                                                                          email: widget.useEmail ||
                                                                              widget
                                                                                  .usePassword),
                                                                      builder:
                                                                          (context,
                                                                              child) {
                                                                        final progress = AppMotion
                                                                            .curve
                                                                            .transform(fieldEntrance.value);
                                                                        return Opacity(
                                                                            opacity:
                                                                                progress,
                                                                            child:
                                                                                Transform.translate(offset: Offset(0, 8 * (1 - progress)), child: child));
                                                                      }),
                                                                  if (widget
                                                                      .usePassword) ...[
                                                                    const SizedBox(
                                                                        height:
                                                                            14),
                                                                    field(
                                                                        'Password',
                                                                        widget
                                                                            .password,
                                                                        secret:
                                                                            true)
                                                                  ],
                                                                  Align(
                                                                      alignment:
                                                                          Alignment
                                                                              .centerRight,
                                                                      child: TextButton(
                                                                          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                                                              content: Text(
                                                                                  'Contact church admin for help with your account.'))),
                                                                          child: Text(
                                                                              widget.useEmail ? 'Forgot email address?' : 'Forgot member code?',
                                                                              style: body(12, color: Colors.white70)))),
                                                                  if (widget
                                                                          .error !=
                                                                      null)
                                                                    Semantics(
                                                                        liveRegion:
                                                                            true,
                                                                        child: Text(
                                                                            widget
                                                                                .error!,
                                                                            textAlign:
                                                                                TextAlign.center,
                                                                            style: body(12, color: const Color(0xffff8787)))),
                                                                  const SizedBox(
                                                                      height:
                                                                          20),
                                                                  button(
                                                                      widget.loading
                                                                          ? 'Please wait…'
                                                                          : 'Continue',
                                                                      canSubmit
                                                                          ? widget
                                                                              .onSubmit
                                                                          : null),
                                                                  TextButton(
                                                                      onPressed: widget
                                                                              .loading
                                                                          ? null
                                                                          : () => choose(
                                                                              !widget
                                                                                  .useEmail,
                                                                              false),
                                                                      child: Text(
                                                                          widget.useEmail
                                                                              ? 'Use Membership Code'
                                                                              : 'Use Email Address',
                                                                          style: body(
                                                                              12,
                                                                              color: Colors.white))),
                                                                  if (!widget
                                                                      .usePassword)
                                                                    TextButton(
                                                                        onPressed: widget.loading
                                                                            ? null
                                                                            : () => choose(true,
                                                                                true),
                                                                        child: Text(
                                                                            'Use password',
                                                                            style:
                                                                                body(12, color: Colors.white70))),
                                                                ],
                                                                Padding(
                                                                    padding: const EdgeInsets
                                                                        .only(
                                                                        top:
                                                                            18),
                                                                    child: Wrap(
                                                                        alignment:
                                                                            WrapAlignment
                                                                                .center,
                                                                        crossAxisAlignment:
                                                                            WrapCrossAlignment.center,
                                                                        children: [
                                                                          Text(
                                                                              'By signing in, you agree to our ',
                                                                              style: body(11, color: Colors.white70)),
                                                                          for (final title
                                                                              in [
                                                                            'Terms of Service',
                                                                            'Privacy Policy'
                                                                          ])
                                                                            TextButton(
                                                                                style: TextButton.styleFrom(
                                                                                    padding: const EdgeInsets.symmetric(
                                                                                        horizontal:
                                                                                            3),
                                                                                    minimumSize: Size
                                                                                        .zero,
                                                                                    tapTargetSize: MaterialTapTargetSize
                                                                                        .shrinkWrap),
                                                                                onPressed: () => showDialog<void>(
                                                                                    context:
                                                                                        context,
                                                                                    builder: (context) => AlertDialog(title: Text(title), content: const Text('Placeholder — this document has not been published yet.'), actions: [
                                                                                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))
                                                                                        ])),
                                                                                child: Text(title, style: body(11, weight: FontWeight.w600).copyWith(decoration: TextDecoration.underline))),
                                                                        ])),
                                                                if (widget
                                                                    .verifying)
                                                                  Padding(
                                                                      padding: const EdgeInsets
                                                                          .only(
                                                                          top:
                                                                              16),
                                                                      child: Text(
                                                                          'Signing you in…',
                                                                          style:
                                                                              body(14))),
                                                              ])))))),
                          ])),
                        ]))))));
  }

  Widget _verification(bool short) =>
      Column(mainAxisAlignment: MainAxisAlignment.start, children: [
        SizedBox(height: short ? 40 : 66),
        Text('Verification',
            style: body(12, color: Colors.white60, weight: FontWeight.w600)),
        const SizedBox(height: 9),
        Text(
            widget.linkSent
                ? 'Check your email\nfor a sign-in link'
                : 'Enter your\n6-digit code',
            textAlign: TextAlign.center,
            style: heading(short ? 29 : 34)),
        const SizedBox(height: 16),
        Text(
            widget.linkSent
                ? 'We sent a sign-in link to ${widget.maskedEmail ?? 'the email associated with your account'}.'
                : widget.useEmail
                    ? 'We sent a 6-digit verification code to ${_mask(widget.email.text)}.'
                    : 'We sent a 6-digit verification code to the email on your membership account.',
            textAlign: TextAlign.center,
            style: body(14, color: Colors.white70)),
        if (!widget.linkSent) ...[
          SizedBox(height: short ? 28 : 42),
          _OtpBoxes(
              controller: widget.otp,
              onSubmit: widget.onVerify,
              enabled: !widget.loading),
        ],
        if (widget.error != null)
          Padding(
              padding: const EdgeInsets.only(top: 15),
              child: Semantics(
                  liveRegion: true,
                  child: Text(widget.error!,
                      textAlign: TextAlign.center,
                      style: body(12, color: const Color(0xffff8787))))),
        const SizedBox(height: 20),
        if (!widget.linkSent)
          button(widget.loading ? 'Verifying…' : 'Continue',
              widget.loading ? null : widget.onVerify),
        const SizedBox(height: 18),
        OutlinedButton(
            onPressed: widget.loading || widget.resendSeconds > 0
                ? null
                : widget.onResend,
            style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white54,
                backgroundColor: Colors.white10,
                side: const BorderSide(color: Colors.white24),
                shape: const StadiumBorder()),
            child: Text(widget.resendSeconds > 0
                ? 'Resend in ${widget.resendSeconds}s'
                : widget.linkSent
                    ? 'Resend link'
                    : 'Resend code')),
      ]);
  String _mask(String value) {
    final parts = value.split('@');
    if (parts.length != 2) return 'your email';
    return '${parts.first.isEmpty ? '' : parts.first.substring(0, 1)}***@${parts.last}';
  }
}

class _OtpBoxes extends StatefulWidget {
  const _OtpBoxes(
      {required this.controller,
      required this.onSubmit,
      required this.enabled});
  final TextEditingController controller;
  final VoidCallback onSubmit;
  final bool enabled;
  @override
  State<_OtpBoxes> createState() => _OtpBoxesState();
}

class _OtpBoxesState extends State<_OtpBoxes> {
  final boxes = List.generate(6, (_) => TextEditingController());
  final focus = List.generate(6, (_) => FocusNode());
  @override
  void dispose() {
    for (final c in boxes) {
      c.dispose();
    }
    for (final f in focus) {
      f.dispose();
    }
    super.dispose();
  }

  void update(int index, String value) {
    if (value.length > 1) {
      final digits =
          value.replaceAll(RegExp(r'\D'), '').split('').take(6).toList();
      for (var i = 0; i < 6; i++) {
        boxes[i].text = i < digits.length ? digits[i] : '';
      }
      focus[(digits.length - 1).clamp(0, 5)].requestFocus();
    } else if (value.isNotEmpty && index < 5) {
      focus[index + 1].requestFocus();
    }
    widget.controller.text = boxes.map((c) => c.text).join();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => AutofillGroup(
          child: Row(children: [
        for (var i = 0; i < 6; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
              child: Focus(
                  onKeyEvent: (_, event) {
                    if (event is! KeyDownEvent) return KeyEventResult.ignored;
                    if (event.logicalKey == LogicalKeyboardKey.backspace &&
                        boxes[i].text.isEmpty &&
                        i > 0) {
                      boxes[i - 1].clear();
                      focus[i - 1].requestFocus();
                      widget.controller.text = boxes.map((c) => c.text).join();
                      return KeyEventResult.handled;
                    }
                    if (event.logicalKey == LogicalKeyboardKey.arrowLeft &&
                        i > 0) {
                      focus[i - 1].requestFocus();
                      return KeyEventResult.handled;
                    }
                    if (event.logicalKey == LogicalKeyboardKey.arrowRight &&
                        i < 5) {
                      focus[i + 1].requestFocus();
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  },
                  child: TextField(
                      controller: boxes[i],
                      focusNode: focus[i],
                      enabled: widget.enabled,
                      keyboardType: TextInputType.number,
                      autofillHints:
                          i == 0 ? const [AutofillHints.oneTimeCode] : null,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6)
                      ],
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                      onChanged: (value) => update(i, value),
                      onSubmitted: (_) => widget.onSubmit(),
                      decoration: InputDecoration(
                          counterText: '',
                          semanticCounterText: 'Digit ${i + 1}',
                          filled: true,
                          fillColor: boxes[i].text.isEmpty
                              ? Colors.white10
                              : Colors.white.withValues(alpha: .16),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 16),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide:
                                  const BorderSide(color: Colors.white24)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide:
                                  const BorderSide(color: Colors.white60)))))),
        ]
      ]));
}
