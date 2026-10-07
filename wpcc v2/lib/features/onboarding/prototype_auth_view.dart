import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_motion.dart';
import 'onboarding_style.dart';

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


  Widget _field(String label, TextEditingController controller,
          {bool email = false, bool secret = false, String? error}) =>
      OnbField(
          label: label,
          controller: controller,
          enabled: !widget.loading,
          obscure: secret && obscure,
          error: error,
          autofillHints: secret
              ? const [AutofillHints.password]
              : email
                  ? const [AutofillHints.email]
                  : null,
          keyboard: email ? TextInputType.emailAddress : TextInputType.text,
          hint: secret
              ? 'Enter your password'
              : email
                  ? 'Enter your email address'
                  : 'Enter your member code',
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => widget.onSubmit(),
          suffix: secret
              ? IconButton(
                  tooltip: obscure ? 'Show password' : 'Hide password',
                  onPressed: () => setState(() => obscure = !obscure),
                  icon: Icon(
                      obscure ? PhosphorIcons.eye() : PhosphorIcons.eyeSlash(),
                      size: 20,
                      color: Onb.inkAlpha(.72)))
              : null);

  Widget _backdrop() => AnimatedBuilder(
      animation: kenBurns,
      builder: (context, background) => Transform.scale(
          scale: 1.015 + .04 * kenBurns.value, child: background),
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
                  color: Onb.canvas.withValues(alpha: verification ? .38 : .2),
                  colorBlendMode: BlendMode.darken,
                  excludeFromSemantics: true))));

  void _back() {
    if (verification) {
      widget.onBack();
      return;
    }
    if (selected) {
      setState(() => selected = false);
      return;
    }
    widget.scope.onBack();
  }

  Widget _topBar(double gutter) => Center(
      child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                  padding: EdgeInsets.fromLTRB(
                      gutter, Onb.s12, gutter, Onb.s8),
                  child: OnbBackButton(
                      tooltip: 'Go back',
                      onPressed: widget.loading ? null : _back)))));

  Widget _chooser() => Column(children: [
        OnbPrimaryButton(
            label: 'Sign in with membership code',
            onPressed: () => choose(false, false)),
        const SizedBox(height: Onb.s12),
        OnbSecondaryButton(
            label: 'Sign in with email',
            icon: PhosphorIcons.envelopeSimple(),
            onPressed: () => choose(true, false)),
        const SizedBox(height: Onb.s4),
        Center(
            child: OnbTextAction(
                label: 'Sign in with password',
                onPressed: () => choose(true, true))),
      ]);

  Widget _form(BuildContext context) {
    final emailMode = widget.useEmail || widget.usePassword;
    final canSubmit = (emailMode
            ? widget.email.text.trim().isNotEmpty
            : widget.code.text.trim().isNotEmpty) &&
        (!widget.usePassword || widget.password.text.isNotEmpty) &&
        !widget.loading;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      AnimatedBuilder(
          animation: fieldEntrance,
          child: _field(emailMode ? 'Email address' : 'Membership code',
              emailMode ? widget.email : widget.code,
              email: emailMode,
              error: widget.usePassword ? null : widget.error),
          builder: (context, child) {
            final progress = AppMotion.curve.transform(fieldEntrance.value);
            return Opacity(
                opacity: progress,
                child: Transform.translate(
                    offset: Offset(0, 8 * (1 - progress)), child: child));
          }),
      if (widget.usePassword) ...[
        const SizedBox(height: Onb.s20),
        _field('Password', widget.password,
            secret: true, error: widget.error),
      ],
      Align(
          alignment: Alignment.centerRight,
          child: OnbTextAction(
              label: widget.useEmail ? 'Forgot email address?' : 'Forgot member code?',
              alpha: .7,
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'Contact church admin for help with your account.'))))),
      const SizedBox(height: Onb.s8),
      OnbPrimaryButton(
          label: widget.loading ? 'Please wait…' : 'Continue',
          onPressed: canSubmit ? widget.onSubmit : null),
      const SizedBox(height: Onb.s8),
      Center(
          child: Wrap(alignment: WrapAlignment.center, children: [
        OnbTextAction(
            label: widget.useEmail ? 'Use Membership Code' : 'Use Email Address',
            onPressed:
                widget.loading ? null : () => choose(!widget.useEmail, false)),
        if (!widget.usePassword)
          OnbTextAction(
              label: 'Use password',
              onPressed: widget.loading ? null : () => choose(true, true)),
      ])),
    ]);
  }

  Widget _terms(BuildContext context) => Padding(
      padding: const EdgeInsets.only(top: Onb.s8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('By signing in, you agree to our',
            style: Onb.body(12, alpha: .66, height: 1.4)),
        Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
          for (final (index, title)
              in ['Terms of Service', 'Privacy Policy'].indexed) ...[
            if (index == 1)
              Text('and', style: Onb.body(12, alpha: .66, height: 1.4)),
            TextButton(
                style: TextButton.styleFrom(
                    padding: EdgeInsets.only(left: index == 0 ? 0 : Onb.s8, right: Onb.s8),
                    minimumSize: const Size(Onb.s24, Onb.minTarget),
                    foregroundColor: Onb.ink,
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(Onb.radiusControl))),
                onPressed: () => showDialog<void>(
                    context: context,
                    builder: (context) => AlertDialog(
                            title: Text(title),
                            content: const Text(
                                'This document has not been published yet.'),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Close'))
                            ])),
                child: Text(title,
                    style: Onb.body(12, alpha: .92, weight: FontWeight.w600)
                        .copyWith(decoration: TextDecoration.underline))),
          ],
        ]),
      ]));

  /// Size change between the chooser and the form. Reduced motion skips the
  /// animated wrapper entirely (a zero-duration AnimatedSize re-lays itself out).
  Widget _modeSwitch(BuildContext context, Widget child) =>
      MediaQuery.disableAnimationsOf(context)
          ? child
          : AnimatedSize(
              duration: AppMotion.control, curve: AppMotion.curve, child: child);

  Widget _entry(BuildContext context, bool short) => Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset('assets/images/onboarding_logo.png',
                width: 44, height: 44, semanticLabel: 'WPCC logo'),
            SizedBox(height: short ? Onb.s20 : Onb.s24),
            Text('Sign in to\nWPCC Community',
                style: Onb.heading(short ? 29 : 32)),
            const SizedBox(height: Onb.s12),
            Text('Use your membership code or email address to continue.',
                style: Onb.body(15, alpha: .8)),
            _modeSwitch(
                context,
                selected
                    ? const SizedBox(width: double.infinity, height: Onb.s24)
                    : Padding(
                        padding:
                            EdgeInsets.only(top: short ? Onb.s24 : Onb.s32),
                        child: _chooser())),
            if (selected) _form(context),
            _terms(context),
            if (widget.verifying)
              Padding(
                  padding: const EdgeInsets.only(top: Onb.s16),
                  child: Text('Signing you in…', style: Onb.body(14, alpha: 1))),
          ]);

  @override
  Widget build(BuildContext context) {
    final short = MediaQuery.sizeOf(context).height <= 780;
    final gutter = Onb.gutter(MediaQuery.sizeOf(context).width, short: short);
    final transition = CurvedAnimation(parent: entrance, curve: ease);
    return Scaffold(
        backgroundColor: Onb.canvas,
        body: FadeTransition(
            opacity: transition,
            child: SlideTransition(
                position: Tween(begin: const Offset(0, .035), end: Offset.zero)
                    .animate(transition),
                child: Stack(fit: StackFit.expand, children: [
                  _backdrop(),
                  const OnbScrim(base: .1, bottom: .9),
                  SafeArea(
                      child: Column(children: [
                    _topBar(gutter),
                    Expanded(
                        child: LayoutBuilder(
                            builder: (context, c) => SingleChildScrollView(
                                padding: EdgeInsets.fromLTRB(gutter, 0, gutter,
                                    short ? Onb.s24 : Onb.s32),
                                child: Center(
                                    child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                            maxWidth: 520,
                                            minHeight: (c.maxHeight -
                                                    (short ? Onb.s24 : Onb.s32))
                                                .clamp(0, double.infinity)),
                                        child: verification
                                            ? _verification(short)
                                            : _entry(context, short)))))),
                  ])),
                ]))));
  }

  Widget _verification(bool short) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(height: short ? Onb.s16 : Onb.s32),
        Text(
            widget.linkSent
                ? 'Check your email\nfor a sign-in link'
                : 'Enter your\n6-digit code',
            style: Onb.heading(short ? 29 : 32)),
        const SizedBox(height: Onb.s12),
        Text(
            widget.linkSent
                ? 'We sent a sign-in link to ${widget.maskedEmail ?? 'the email associated with your account'}.'
                : widget.useEmail
                    ? 'We sent a 6-digit verification code to ${_mask(widget.email.text)}.'
                    : 'We sent a 6-digit verification code to the email on your membership account.',
            style: Onb.body(15, alpha: .8)),
        if (!widget.linkSent) ...[
          SizedBox(height: short ? Onb.s24 : Onb.s32),
          _OtpBoxes(
              controller: widget.otp,
              onSubmit: widget.onVerify,
              enabled: !widget.loading),
        ],
        if (widget.error != null)
          Padding(
              padding: const EdgeInsets.only(top: Onb.s16),
              child: OnbMessage(widget.error!, isError: true)),
        const SizedBox(height: Onb.s24),
        if (!widget.linkSent) ...[
          OnbPrimaryButton(
              label: widget.loading ? 'Verifying…' : 'Continue',
              onPressed: widget.loading ? null : widget.onVerify),
          const SizedBox(height: Onb.s12),
        ],
        OnbSecondaryButton(
            label: widget.resendSeconds > 0
                ? 'Resend in ${widget.resendSeconds}s'
                : widget.linkSent
                    ? 'Resend link'
                    : 'Resend code',
            onPressed: widget.loading || widget.resendSeconds > 0
                ? null
                : widget.onResend),
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
          if (i > 0) const SizedBox(width: Onb.s8),
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
                      cursorColor: Onb.accentLight,
                      style: GoogleFonts.manrope(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Onb.ink),
                      onChanged: (value) => update(i, value),
                      onSubmitted: (_) => widget.onSubmit(),
                      decoration: InputDecoration(
                          counterText: '',
                          semanticCounterText: 'Digit ${i + 1}',
                          filled: true,
                          fillColor: boxes[i].text.isEmpty
                              ? Onb.inkAlpha(.08)
                              : Onb.inkAlpha(.14),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: Onb.s16 + 2),
                          enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(Onb.radiusControl),
                              borderSide:
                                  BorderSide(color: Onb.inkAlpha(.22))),
                          focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(Onb.radiusControl),
                              borderSide: const BorderSide(
                                  color: Onb.accentLight, width: 1.5)))))),
        ]
      ]));
}
