import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/member_material.dart';

/// Visual tokens from docs/department-tools-cards.css, scoped to these tools.
abstract final class DepartmentToolStyle {
  static bool dark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
  static Color ink(BuildContext context) =>
      dark(context) ? const Color(0xFFF6F6F8) : const Color(0xFF1C2024);
  static Color muted(BuildContext context) =>
      dark(context) ? const Color(0xFFB7B9BC) : const Color(0xFF596168);
  static Color page(BuildContext context) =>
      dark(context) ? const Color(0xFF141517) : const Color(0xFFF5F6F7);
  static TextStyle text(BuildContext context, double size,
          {bool muted = false,
          FontWeight weight = FontWeight.w400,
          double height = 1.5}) =>
      TextStyle(
          fontFamily: 'DM Sans',
          fontSize: size,
          fontWeight: weight,
          height: height,
          letterSpacing: 0,
          color: muted ? DepartmentToolStyle.muted(context) : ink(context));
}

class DepartmentToolCard extends StatefulWidget {
  const DepartmentToolCard(
      {super.key,
      required this.title,
      required this.description,
      required this.icon,
      required this.onTap,
      this.unavailable = false});
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback? onTap;
  final bool unavailable;

  @override
  State<DepartmentToolCard> createState() => _DepartmentToolCardState();
}

class _DepartmentToolCardState extends State<DepartmentToolCard> {
  bool hovered = false;
  bool pressed = false;
  bool focused = false;

  @override
  Widget build(BuildContext context) {
    final dark = DepartmentToolStyle.dark(context);
    final tablet = MediaQuery.sizeOf(context).width >= 600;
    final large = MediaQuery.textScalerOf(context).scale(16) >= 22;
    final solid = MemberMaterials.solid(context);
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final fill = solid
        ? (dark ? const Color(0xFF26272B) : Colors.white)
        : dark
            ? Color(hovered ? 0x12FFFFFF : 0x0CFFFFFF)
            : Color(hovered ? 0xFFFFFFFF : 0xC9FFFFFF);
    final radius = BorderRadius.circular(20);
    final content = AnimatedContainer(
      duration:
          reducedMotion ? Duration.zero : const Duration(milliseconds: 140),
      constraints: BoxConstraints(minHeight: large ? 48 : (tablet ? 204 : 194)),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: radius,
        border: Border.all(
            color: focused || MediaQuery.highContrastOf(context)
                ? DepartmentToolStyle.ink(context)
                : dark
                    ? const Color(0x09FFFFFF)
                    : const Color(0x0A16201C),
            width: focused ? 2 : 1),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          onTap: widget.onTap,
          onHover: (value) => setState(() => hovered = value),
          onHighlightChanged: (value) => setState(() => pressed = value),
          onFocusChange: (value) => setState(() => focused = value),
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          focusColor: Colors.transparent,
          child: Padding(
            padding: large || tablet
                ? const EdgeInsets.all(21)
                : const EdgeInsets.symmetric(horizontal: 15, vertical: 19),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                      height: 28,
                      child: Row(children: [
                        Icon(widget.icon,
                            size: 26, color: DepartmentToolStyle.ink(context)),
                        const Spacer(),
                        Icon(PhosphorIconsRegular.arrowRight,
                            size: 16,
                            color: DepartmentToolStyle.muted(context)),
                      ])),
                  SizedBox(height: large ? 16 : 20),
                  Text(widget.title,
                      style: DepartmentToolStyle.text(context, 15,
                          weight: FontWeight.w600, height: 1.4)),
                  const SizedBox(height: 8),
                  Text(widget.description,
                      style:
                          DepartmentToolStyle.text(context, 13, muted: true)),
                  if (widget.unavailable) ...[
                    const SizedBox(height: 8),
                    Text('Not available yet',
                        style:
                            DepartmentToolStyle.text(context, 12, muted: true)),
                  ],
                ]),
          ),
        ),
      ),
    );
    return Semantics(
        button: true,
        enabled: widget.onTap != null,
        child: AnimatedScale(
            scale: pressed && !reducedMotion ? .98 : 1,
            duration: reducedMotion
                ? Duration.zero
                : const Duration(milliseconds: 100),
            child: ClipRRect(
                borderRadius: radius,
                child: solid
                    ? content
                    : BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                        child: content))));
  }
}

class DepartmentToolGrid extends StatelessWidget {
  const DepartmentToolGrid({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    final tablet = MediaQuery.sizeOf(context).width >= 600;
    final columns = MediaQuery.textScalerOf(context).scale(16) >= 22
        ? 1
        : tablet
            ? 3
            : 2;
    final gap = tablet ? 16.0 : 12.0;
    return Column(children: [
      for (var start = 0; start < children.length; start += columns) ...[
        if (start > 0) SizedBox(height: gap),
        IntrinsicHeight(
            child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var col = 0; col < columns; col++) ...[
              if (col > 0) SizedBox(width: gap),
              Expanded(
                  child: start + col < children.length
                      ? children[start + col]
                      : const SizedBox.shrink()),
            ]
          ],
        )),
      ],
    ]);
  }
}
