import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

/// A pill the member can switch on or off (amount presets, day pickers,
/// categories). The fill and text colour animate on the app's standard curve,
/// it scales to 0.97 while pressed, and the tap target is at least 48px tall.
class MemberChoice extends StatelessWidget {
  const MemberChoice(
      {super.key,
      required this.label,
      required this.selected,
      required this.onTap,
      this.minWidth = 0});
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme.labelMedium!;
    return Semantics(
      button: true,
      selected: selected,
      enabled: onTap != null,
      excludeSemantics: true,
      label: label,
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? .5 : 1,
        child: AppPressMotion(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: 48, minWidth: minWidth),
              child: Center(
                widthFactor: 1,
                child: AnimatedContainer(
                  duration: AppMotion.duration(context, AppMotion.tab),
                  curve: AppMotion.curve,
                  constraints: BoxConstraints(minWidth: minWidth),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                      color: selected
                          ? scheme.onSurface
                          : scheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(24)),
                  child: AnimatedDefaultTextStyle(
                    duration: AppMotion.duration(context, AppMotion.tab),
                    curve: AppMotion.curve,
                    style: textStyle.copyWith(
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400,
                        color: selected
                            ? scheme.surfaceContainerLowest
                            : scheme.onSurface),
                    child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                              child: Text(label, textAlign: TextAlign.center))
                        ]),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
