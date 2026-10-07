import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/app_motion.dart';
import 'announcement_palette.dart';

/// Row of background swatches (plus a "none" option). 48px targets, animated
/// selection. [value] is a palette key or null for the default look.
class AnnouncementColorPicker extends StatelessWidget {
  const AnnouncementColorPicker(
      {super.key, required this.value, required this.onChanged});
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = AnnouncementPalette.byKey(value)?.key;
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        _Swatch(
            label: 'Default background',
            selected: selected == null,
            onTap: () => onChanged(null)),
        for (final style in AnnouncementPalette.styles)
          _Swatch(
              label: style.label,
              style: style,
              selected: selected == style.key,
              onTap: () => onChanged(style.key)),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch(
      {required this.label,
      required this.selected,
      required this.onTap,
      this.style});
  final String label;
  final AnnouncementStyle? style;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = style?.foreground ?? scheme.onSurface;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: ExcludeSemantics(
        child: AppPressMotion(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: SizedBox.square(
              dimension: 48,
              child: Center(
                child: AnimatedContainer(
                  duration: AppMotion.duration(context, AppMotion.control),
                  curve: AppMotion.curve,
                  width: selected ? 44 : 38,
                  height: selected ? 44 : 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: style?.gradient,
                    color: style == null ? scheme.surface : null,
                    border: Border.all(
                        color: selected
                            ? scheme.primary
                            : scheme.outline.withValues(alpha: .5),
                        width: selected ? 3 : 1),
                  ),
                  child: AnimatedOpacity(
                    duration: AppMotion.duration(context, AppMotion.control),
                    opacity: selected || style == null ? 1 : 0,
                    child: Icon(
                        style == null
                            ? PhosphorIcons.prohibit()
                            : PhosphorIcons.check(PhosphorIconsStyle.bold),
                        size: 18,
                        color: fg),
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

/// Live Facebook-status style preview of an announcement on its background.
class AnnouncementStatusPreview extends StatelessWidget {
  const AnnouncementStatusPreview(
      {super.key, required this.text, required this.styleKey});
  final String text;
  final String? styleKey;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = AnnouncementPalette.byKey(styleKey);
    final from = style?.from ?? scheme.surfaceContainerHighest;
    final to = style?.to ?? scheme.surfaceContainerHighest;
    final fg = style?.foreground ?? scheme.onSurface;
    final shown =
        text.trim().isEmpty ? 'Your message appears here' : text.trim();
    return AnimatedContainer(
      duration: AppMotion.duration(context, AppMotion.page),
      curve: AppMotion.curve,
      constraints: const BoxConstraints(minHeight: 180),
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [from, to]),
        border: Border.all(
            color: style == null
                ? scheme.outline.withValues(alpha: .4)
                : Colors.transparent),
      ),
      child: Semantics(
        label: 'Announcement preview',
        child: AnimatedDefaultTextStyle(
          duration: AppMotion.duration(context, AppMotion.control),
          style: TextStyle(
              color: fg,
              fontFamily: 'DM Sans',
              fontSize: AnnouncementPalette.statusFontSize(shown),
              height: 1.25,
              fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
          child: Text(shown,
              textAlign: TextAlign.center,
              maxLines: 8,
              overflow: TextOverflow.ellipsis),
        ),
      ),
    );
  }
}
