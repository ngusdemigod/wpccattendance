import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_motion.dart';

/// Shared presentation tokens and components for the onboarding flow: photo
/// onboarding, authentication, profile confirmation and the award screen.
/// Presentation only. Behaviour stays with the screens that use these.
///
/// Spacing sits on a 4/8 scale. Radii: 12 inputs and small controls, 20 cards
/// and photographs, a full pill only for the one primary action on a screen.
abstract final class Onb {
  // Colour. One accent hue in two tones, off-white ink and an off-black canvas.
  static const canvas = Color(0xff0b0910);
  static const ink = Color(0xfff6f3fa);
  static const onInk = Color(0xff17131f);
  static const accent = Color(0xff8b6cf6);
  static const accentLight = Color(0xffb9a6fb);
  static const error = Color(0xffffa3a3);

  // Spacing.
  static const s4 = 4.0, s8 = 8.0, s12 = 12.0, s16 = 16.0, s20 = 20.0;
  static const s24 = 24.0, s32 = 32.0, s40 = 40.0, s48 = 48.0;

  // Radii.
  static const radiusControl = 12.0;
  static const radiusCard = 20.0;
  static const minTarget = 48.0;
  static const buttonHeight = 56.0;

  static Color inkAlpha(double alpha) => ink.withValues(alpha: alpha);

  static TextStyle heading(double size, {double height = 1.1}) =>
      GoogleFonts.manrope(
          fontSize: size,
          height: height,
          letterSpacing: -size * .035,
          fontWeight: FontWeight.w800,
          color: ink);

  static TextStyle body(double size,
          {double alpha = .74,
          FontWeight weight = FontWeight.w400,
          double height = 1.5}) =>
      GoogleFonts.dmSans(
          fontSize: size,
          height: height,
          fontWeight: weight,
          color: inkAlpha(alpha));

  static TextStyle label({double alpha = .86}) =>
      body(13, alpha: alpha, weight: FontWeight.w600, height: 1.3);

  /// Phone, compact and tablet spacing. Reading widths are bounded by callers.
  static double gutter(double width, {required bool short}) =>
      width >= 600 ? 32 : (short ? 20 : 24);

  /// Plain-words progress label shown with the segmented indicator.
  static String stepLabel(int current, int total) =>
      'Step $current of $total';
}

/// Photographic scrim: a tinted vertical fade plus one restrained accent glow
/// at the bottom edge. [base] darkens the whole photograph first.
class OnbScrim extends StatelessWidget {
  const OnbScrim({super.key, this.base = .3, this.bottom = .86});
  final double base;
  final double bottom;
  @override
  Widget build(BuildContext context) => IgnorePointer(
          child: Stack(fit: StackFit.expand, children: [
        ColoredBox(color: Onb.canvas.withValues(alpha: base)),
        DecoratedBox(
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
              Onb.canvas.withValues(alpha: .1),
              Onb.canvas.withValues(alpha: .38),
              Onb.canvas.withValues(alpha: .68),
              Onb.canvas.withValues(alpha: bottom)
            ],
                    stops: const [
              0,
              .34,
              .7,
              1
            ]))),
        const DecoratedBox(
            decoration: BoxDecoration(
                gradient: RadialGradient(
                    center: Alignment(0, 1.3),
                    radius: 1,
                    colors: [Color(0x2e8b6cf6), Color(0x00000000)]))),
      ]));
}

/// 48 by 48 back control with the shared 12 radius and press feedback.
class OnbBackButton extends StatelessWidget {
  const OnbBackButton({super.key, required this.tooltip, this.onPressed});
  final String tooltip;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => AppPressMotion(
      child: IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          style: IconButton.styleFrom(
              fixedSize: const Size.square(Onb.minTarget),
              minimumSize: const Size.square(Onb.minTarget),
              padding: EdgeInsets.zero,
              backgroundColor: Onb.inkAlpha(.08),
              foregroundColor: Onb.ink,
              disabledBackgroundColor: Onb.inkAlpha(.04),
              disabledForegroundColor: Onb.inkAlpha(.32),
              side: BorderSide(color: Onb.inkAlpha(.14)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Onb.radiusControl))),
          icon: Icon(PhosphorIcons.arrowLeft(), size: 20)));
}

/// The one primary action on a screen: full pill, off-white on dark.
class OnbPrimaryButton extends StatelessWidget {
  const OnbPrimaryButton(
      {super.key,
      required this.label,
      this.onPressed,
      this.height = Onb.buttonHeight});
  final String label;
  final VoidCallback? onPressed;
  final double height;
  @override
  Widget build(BuildContext context) => AppPressMotion(
      child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
              minimumSize: Size.fromHeight(height),
              padding:
                  const EdgeInsets.symmetric(horizontal: Onb.s24, vertical: 16),
              backgroundColor: Onb.ink,
              foregroundColor: Onb.onInk,
              disabledBackgroundColor: Onb.inkAlpha(.14),
              disabledForegroundColor: Onb.inkAlpha(.4),
              shape: const StadiumBorder(),
              textStyle: Onb.body(15, weight: FontWeight.w600, height: 1.25)),
          child: Text(label, textAlign: TextAlign.center)));
}

/// Secondary action: an outlined 12-radius button. Never competes with the pill.
class OnbSecondaryButton extends StatelessWidget {
  const OnbSecondaryButton(
      {super.key, required this.label, this.onPressed, this.icon});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => AppPressMotion(
      child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(Onb.minTarget + 4),
              padding:
                  const EdgeInsets.symmetric(horizontal: Onb.s16, vertical: 12),
              foregroundColor: Onb.ink,
              disabledForegroundColor: Onb.inkAlpha(.4),
              backgroundColor: Onb.inkAlpha(.05),
              side: BorderSide(
                  color: Onb.inkAlpha(onPressed == null ? .1 : .22)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Onb.radiusControl)),
              textStyle: Onb.body(14, weight: FontWeight.w600, height: 1.25)),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18),
                  const SizedBox(width: Onb.s8)
                ],
                Flexible(child: Text(label, textAlign: TextAlign.center)),
              ])));
}

/// Quiet text action with a 48 logical pixel target.
class OnbTextAction extends StatelessWidget {
  const OnbTextAction(
      {super.key, required this.label, this.onPressed, this.alpha = .78});
  final String label;
  final VoidCallback? onPressed;
  final double alpha;
  @override
  Widget build(BuildContext context) => TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
          minimumSize: const Size(Onb.minTarget, Onb.minTarget),
          padding: const EdgeInsets.symmetric(horizontal: Onb.s12),
          foregroundColor: Onb.inkAlpha(alpha),
          disabledForegroundColor: Onb.inkAlpha(.34),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Onb.radiusControl)),
          textStyle: Onb.body(14, weight: FontWeight.w600, height: 1.25)),
      child: Text(label));
}

/// Inline helper or error line shown below a field.
class OnbMessage extends StatelessWidget {
  const OnbMessage(this.text, {super.key, this.isError = false});
  final String text;
  final bool isError;
  @override
  Widget build(BuildContext context) => Semantics(
      liveRegion: isError,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (isError) ...[
          Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(PhosphorIcons.warningCircle(),
                  size: 16, color: Onb.error)),
          const SizedBox(width: Onb.s8),
        ],
        Expanded(
            child: Text(text,
                style: Onb.body(13,
                    alpha: isError ? 1 : .64,
                    weight: isError ? FontWeight.w500 : FontWeight.w400,
                    height: 1.4)
                    .copyWith(color: isError ? Onb.error : null))),
      ]));
}

/// Labelled text field: label above, helper or error below, calm focus ring.
class OnbField extends StatelessWidget {
  const OnbField(
      {super.key,
      required this.label,
      required this.controller,
      this.hint,
      this.helper,
      this.error,
      this.keyboard,
      this.lines = 1,
      this.readOnly = false,
      this.enabled = true,
      this.obscure = false,
      this.autofillHints,
      this.onTap,
      this.onChanged,
      this.onSubmitted,
      this.suffix,
      this.prefix});
  final String label;
  final TextEditingController controller;
  final String? hint, helper, error;
  final TextInputType? keyboard;
  final int lines;
  final bool readOnly, enabled, obscure;
  final Iterable<String>? autofillHints;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffix, prefix;

  OutlineInputBorder _border(Color color, [double width = 1]) =>
      OutlineInputBorder(
          borderRadius: BorderRadius.circular(Onb.radiusControl),
          borderSide: BorderSide(color: color, width: width));

  @override
  Widget build(BuildContext context) {
    final failed = error != null;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ExcludeSemantics(child: Text(label, style: Onb.label())),
      const SizedBox(height: Onb.s8),
      Semantics(
          label: label,
          child: TextField(
              controller: controller,
              enabled: enabled,
              readOnly: readOnly,
              obscureText: obscure,
              autofillHints: autofillHints,
              keyboardType: keyboard,
              maxLines: lines,
              onTap: onTap,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              cursorColor: Onb.accentLight,
              style: Onb.body(16, alpha: 1, weight: FontWeight.w500, height: 1.3),
              decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: Onb.body(16, alpha: .5, height: 1.3),
                  filled: true,
                  fillColor: Onb.inkAlpha(.08),
                  prefixIcon: prefix,
                  suffixIcon: suffix,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: Onb.s16, vertical: 18),
                  border: _border(Onb.inkAlpha(.22)),
                  enabledBorder:
                      _border(failed ? Onb.error : Onb.inkAlpha(.22)),
                  disabledBorder: _border(Onb.inkAlpha(.12)),
                  focusedBorder:
                      _border(failed ? Onb.error : Onb.accentLight, 1.5)))),
      if (failed || helper != null) ...[
        const SizedBox(height: Onb.s8),
        OnbMessage(error ?? helper!, isError: failed),
      ],
    ]);
  }
}

/// Segmented progress: one segment per step. Decorative: the plain-words count
/// ([Onb.stepLabel]) is the accessible label and is shown beside it.
class OnbStepSegments extends StatelessWidget {
  const OnbStepSegments(
      {super.key, required this.current, required this.total});
  final int current, total;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
          child: Row(children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: Onb.s4),
          Expanded(
              child: AnimatedContainer(
                  duration: AppMotion.duration(context, AppMotion.control),
                  curve: AppMotion.curve,
                  height: 4,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: i < current
                          ? Onb.accentLight
                          : Onb.inkAlpha(.18)))),
        ]
      ]));
}

/// Selectable or removable chip with the shared 12 radius. Interactive chips
/// keep a 48 logical pixel target; static ones are compact.
class OnbChip extends StatelessWidget {
  const OnbChip(
      {super.key,
      required this.label,
      this.selected = false,
      this.onTap,
      this.trailing,
      this.semanticLabel});
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? trailing;
  final String? semanticLabel;
  @override
  Widget build(BuildContext context) {
    final interactive = onTap != null;
    final emphasised = selected || !interactive;
    return Semantics(
        button: interactive,
        selected: selected,
        label: semanticLabel,
        child: Material(
            color: emphasised
                ? Onb.accent.withValues(alpha: .28)
                : Onb.inkAlpha(.06),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Onb.radiusControl),
                side: BorderSide(
                    color: emphasised
                        ? Onb.accentLight.withValues(alpha: .55)
                        : Onb.inkAlpha(.2))),
            child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(Onb.radiusControl),
                child: ConstrainedBox(
                    constraints: BoxConstraints(
                        minHeight: interactive ? Onb.minTarget : 36),
                    child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: Onb.s16, vertical: Onb.s8),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Flexible(
                              child: Text(label,
                                  style: Onb.body(13,
                                      alpha: 1,
                                      weight: FontWeight.w500,
                                      height: 1.25))),
                          if (trailing != null) ...[
                            const SizedBox(width: Onb.s8),
                            trailing!
                          ],
                        ]))))));
  }
}
