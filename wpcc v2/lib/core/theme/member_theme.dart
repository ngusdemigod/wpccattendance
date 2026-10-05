import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'member_material.dart';

/// Member-only styling: entry, installation and confirmation keep their theme.
class MemberTheme extends StatelessWidget {
  const MemberTheme(
      {super.key,
      required this.child,
      this.media = false,
      this.backdrop = true,
      this.route = '/home'});
  final String route;
  final Widget child;
  final bool media;
  final bool backdrop;

  @override
  Widget build(BuildContext context) {
    final theme = buildMemberTheme(Theme.of(context));
    return Theme(
      data: theme,
      child: backdrop
          ? MemberBackdrop(media: media, route: route, child: child)
          : child,
    );
  }
}

ThemeData buildMemberTheme(ThemeData base) {
  final dark = base.brightness == Brightness.dark;
  final background = dark ? const Color(0xFF151517) : const Color(0xFFF7F7F8);
  final surface = dark ? const Color(0x08FFFFFF) : const Color(0x04000000);
  final raised = dark ? const Color(0x12FFFFFF) : const Color(0x0A000000);
  final ink = dark ? const Color(0xFFFAFAFA) : const Color(0xFF202023);
  final secondary = dark ? const Color(0xFFB8B3B7) : const Color(0xFF625D63);
  final line = dark ? const Color(0x0BFFFFFF) : const Color(0x0C000000);
  final accent = ink;
  final onAccent = background;
  final colors = base.colorScheme.copyWith(
    surface: surface,
    onSurface: ink,
    onSurfaceVariant: secondary,
    surfaceContainerLowest: background,
    surfaceContainerLow: raised,
    surfaceContainer: raised,
    surfaceContainerHigh: raised,
    surfaceContainerHighest: raised,
    outline: line,
    outlineVariant: line,
    primary: accent,
    onPrimary: onAccent,
    primaryContainer: raised,
    onPrimaryContainer: ink,
  );
  TextStyle style(double size, double lineHeight, FontWeight weight,
          {Color? color}) =>
      TextStyle(
        fontFamily: 'DM Sans',
        fontSize: size,
        height: lineHeight / size,
        fontWeight: weight,
        letterSpacing: 0,
        color: color ?? ink,
      );
  final text = base.textTheme.apply(fontFamily: 'DM Sans').copyWith(
    headlineLarge: style(40, 49, FontWeight.w600),
    headlineMedium: style(38, 46, FontWeight.w600),
    headlineSmall: style(28, 35, FontWeight.w600),
    titleLarge: style(19, 25, FontWeight.w600),
    titleMedium: style(15, 21, FontWeight.w500),
    titleSmall: style(14, 20, FontWeight.w600),
    bodyLarge: style(16, 27, FontWeight.w400),
    bodyMedium: style(14, 21, FontWeight.w400),
    bodySmall: style(12, 18, FontWeight.w400, color: secondary),
    labelLarge: style(14, 20, FontWeight.w600),
    labelMedium: style(13, 18, FontWeight.w400),
    labelSmall: style(11, 16, FontWeight.w400),
  );
  final buttonShape =
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(26));
  return base.copyWith(
    visualDensity: VisualDensity.standard,
    scaffoldBackgroundColor: Colors.transparent,
    colorScheme: colors,
    textTheme: text,
    primaryTextTheme: base.primaryTextTheme.apply(fontFamily: 'DM Sans'),
    iconTheme: IconThemeData(color: ink, size: 22),
    actionIconTheme: ActionIconThemeData(
        backButtonIconBuilder: (_) =>
            const Icon(PhosphorIconsRegular.caretLeft, size: 20)),
    appBarTheme: base.appBarTheme.copyWith(
      backgroundColor: Colors.transparent,
      titleTextStyle: text.titleSmall?.copyWith(fontSize: 20, height: 26 / 20),
      foregroundColor: ink,
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: ink,
        minimumSize: const Size(48, 48),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: onAccent,
        minimumSize: const Size(48, 48),
        shape: buttonShape,
        textStyle: text.labelLarge,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: onAccent,
        minimumSize: const Size(48, 48),
        elevation: 0,
        shape: buttonShape,
        textStyle: text.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ink,
        minimumSize: const Size(48, 48),
        side: BorderSide(color: line),
        shape: buttonShape,
        textStyle: text.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: accent,
        minimumSize: const Size(48, 48),
        textStyle: text.labelLarge,
        shape: buttonShape,
      ),
    ),
    cardTheme: base.cardTheme.copyWith(
      color: surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: const StadiumBorder(),
      side: BorderSide.none,
      backgroundColor: raised,
      selectedColor: colors.primaryContainer,
      labelStyle: text.labelMedium,
      secondaryLabelStyle:
          text.labelMedium?.copyWith(color: colors.onPrimaryContainer),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    ),
    dialogTheme: base.dialogTheme.copyWith(
      backgroundColor: dark ? const Color(0xF5343236) : const Color(0xF5F4F2F5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
    ),
    bottomSheetTheme: base.bottomSheetTheme.copyWith(
      backgroundColor: dark ? const Color(0xF5343236) : const Color(0xF5F4F2F5),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      dragHandleColor: secondary,
    ),
    inputDecorationTheme: base.inputDecorationTheme.copyWith(
      fillColor: raised,
      hintStyle: text.bodyMedium?.copyWith(color: secondary),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(
              color: dark ? const Color(0xFFD8B1FF) : const Color(0xFF673AB7),
              width: 2)),
    ),
  );
}

/// Pixel tokens from the approved HTML, confined to member presentation.
abstract final class MemberVisuals {
  static const highlight = LinearGradient(
    begin: Alignment(-1, -.17),
    end: Alignment(1, .17),
    colors: [Color(0xFF9E74F5), Color(0xFFD79A61)],
  );
  static Color page(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF151517)
          : const Color(0xFFF7F7F8);
  static Color subtle(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF949095)
          : const Color(0xFF756F76);
  static Color dock(BuildContext context) =>
      MemberMaterials.fill(context, MemberMaterialWeight.navigation);
  static Color selected(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1B1B1B)
          : Colors.white;
  static Color sheet(BuildContext context) =>
      MemberMaterials.fill(context, MemberMaterialWeight.sheet);
  static TextStyle? display(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 600
          ? Theme.of(context).textTheme.headlineLarge
          : Theme.of(context).textTheme.headlineMedium;
}

class MemberBackdrop extends StatelessWidget {
  const MemberBackdrop(
      {super.key,
      required this.child,
      this.media = false,
      this.route = '/home'});
  final String route;
  final Widget child;
  final bool media;
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final dark = Theme.of(context).brightness == Brightness.dark;
        final height = box.maxHeight.isFinite
            ? box.maxHeight
            : MediaQuery.sizeOf(context).height;
        final colors = media
            ? dark
                ? const [
                    Color(0xFF182411),
                    Color(0xFF202317),
                    Color(0xFF110D0B),
                    Color(0xFF090A08)
                  ]
                : const [
                    Color(0xFFE4EADF),
                    Color(0xFFF0F0E8),
                    Color(0xFFF7F7F8),
                    Color(0xFFF7F7F8)
                  ]
            : dark
                ? const [
                    Color(0xFF3A1E25),
                    Color(0xFF271D21),
                    Color(0xFF151517),
                    Color(0xFF151517)
                  ]
                : const [
                    Color(0xFFF1E4E9),
                    Color(0xFFF4EDF0),
                    Color(0xFFF7F7F8),
                    Color(0xFFF7F7F8)
                  ];
        return DecoratedBox(
            decoration: BoxDecoration(
                gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: route == '/home' && !media
                  ? colors
                  : MemberPagePalette.colors(media ? '/media' : route, dark),
              stops: [
                0,
                ((media ? 200 : 180) / height).clamp(0, 1),
                ((media ? 480 : 430) / height).clamp(0, 1),
                1
              ],
            )),
            child: child);
      });
}

/// Stable route-family colors keep a detail page connected to its parent.
abstract final class MemberPagePalette {
  static List<Color> colors(String route, bool dark) {
    final family = Uri.parse(route)
            .path
            .split('/')
            .where((part) => part.isNotEmpty)
            .firstOrNull ??
        'home';
    final pair = switch (family) {
      'home' => (0xFF3A1E25, 0xFFF1E4E9),
      'events' => (0xFF19394B, 0xFFE2EDF7),
      'media' => (0xFF303D22, 0xFFE9EEDC),
      'give' => (0xFF153B36, 0xFFE3F1EA),
      'profile' => (0xFF38304B, 0xFFEDE6F5),
      'departments' => (0xFF263B40, 0xFFDDEEEF),
      'prayer-alerts' || 'prayer-session' => (0xFF25324C, 0xFFE4EAF9),
      'devotional' => (0xFF443A25, 0xFFF3EDDD),
      'souls' => (0xFF43302B, 0xFFF5E5DF),
      'search' => (0xFF2E3B39, 0xFFE5EEEB),
      _ => (0xFF39264D, 0xFFEDE3F6),
    };
    final tint = Color(dark ? pair.$1 : pair.$2);
    final base = dark ? const Color(0xFF151517) : const Color(0xFFF7F7F8);
    return [tint, Color.lerp(tint, base, .55)!, base, base];
  }
}
