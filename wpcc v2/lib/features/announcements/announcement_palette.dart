import 'package:flutter/material.dart';

/// One curated announcement background. [key] is what is stored in the
/// `announcements.background_style` column; arbitrary CSS/colours are never
/// persisted, so unknown keys simply fall back to the default card.
@immutable
class AnnouncementStyle {
  const AnnouncementStyle(this.key, this.label, this.from, this.to);
  final String key;
  final String label;
  final Color from;
  final Color to;

  LinearGradient get gradient => LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [from, to]);

  /// Text colour with the best worst-case contrast across both gradient stops.
  Color get foreground => contrastForeground([from, to]);

  /// Secondary text colour (still readable, slightly softer).
  Color get mutedForeground => foreground.withValues(alpha: .88);
}

const _lightText = Color(0xFFFFFFFF);
const _darkText = Color(0xFF14161A);

double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + .05) / (lo + .05);
}

/// Picks white or near-black text, whichever reads best on every colour.
Color contrastForeground(List<Color> backgrounds) {
  double worst(Color text) => backgrounds
      .map((bg) => contrastRatio(text, bg))
      .reduce((a, b) => a < b ? a : b);
  return worst(_lightText) >= worst(_darkText) ? _lightText : _darkText;
}

abstract final class AnnouncementPalette {
  static const styles = <AnnouncementStyle>[
    AnnouncementStyle(
        'ocean', 'Ocean blue', Color(0xFF0B63B8), Color(0xFF0A3D7A)),
    AnnouncementStyle(
        'royal', 'Royal purple', Color(0xFF6A2DB8), Color(0xFF3F1A87)),
    AnnouncementStyle(
        'forest', 'Forest green', Color(0xFF1F7A4D), Color(0xFF0E4D33)),
    AnnouncementStyle(
        'crimson', 'Crimson', Color(0xFFC0392B), Color(0xFF8E1B3B)),
    AnnouncementStyle('sunset', 'Sunset', Color(0xFFB8470A), Color(0xFF8F2D56)),
    AnnouncementStyle(
        'midnight', 'Midnight', Color(0xFF1F2933), Color(0xFF0B1220)),
    AnnouncementStyle('gold', 'Golden', Color(0xFFFFD66B), Color(0xFFFFB347)),
    AnnouncementStyle(
        'mint', 'Fresh mint', Color(0xFFC4F2D8), Color(0xFF8FDCB5)),
  ];

  /// Returns the style for [key], or null when empty or unknown so callers
  /// fall back to the default card.
  static AnnouncementStyle? byKey(Object? key) {
    final value = key?.toString().trim();
    if (value == null || value.isEmpty) return null;
    for (final style in styles) {
      if (style.key == value) return style;
    }
    return null;
  }

  /// Facebook-status sizing: short posts are large, long posts shrink.
  static double statusFontSize(String text) {
    final length = text.trim().length;
    return length <= 70 ? 28.0 : (length <= 150 ? 22.0 : 17.0);
  }
}
