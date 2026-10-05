import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemePreference extends ValueNotifier<ThemeMode> {
  ThemePreference._() : super(ThemeMode.system);
  static final instance = ThemePreference._();
  Future<void> load() async {
    final saved =
        (await SharedPreferences.getInstance()).getString('wpcc.theme');
    value = ThemeMode.values.firstWhere((mode) => mode.name == saved,
        orElse: () => ThemeMode.system);
  }

  Future<void> select(ThemeMode mode) async {
    value = mode;
    await (await SharedPreferences.getInstance())
        .setString('wpcc.theme', mode.name);
  }
}

class WpccColors {
  static const ink = Color(0xFF202124);
  static const navActive = Color(0xFF202124);
  static const inkSoft = Color(0xFF62656B);
  static const muted = Color(0xFF74777D);
  static const surface = Color(0xFFFEFEFE);
  static const subtle = Color(0xFFF1F2F3);
  static const background = Color(0xFFF7F8F9);
  static const screenWhite = Color(0xFFF7F8F9);
  static const line = Color(0xFFE1E3E6);
  static const lineSubtle = Color(0xFFECEEF0);
  static const primary = Color(0xFF7C4EA6);
  static const primaryDeep = Color(0xFF683793);
  static const primarySoft = Color(0xFFF1EAF7);
  static const lavender = Color(0xFFE5D9EF);
  static const coolBlue = Color(0xFFE5E9EF);
  static const warm = Color(0xFFF0ECE8);
  static const success = Color(0xFF238636);
  static const successBackground = Color(0xFFEEF8F1);
  static const warning = Color(0xFFA86A00);
  static const warningBackground = Color(0xFFFFF7E6);
  static const error = Color(0xFFC9362B);
  static const errorBackground = Color(0xFFFFF0EF);
}

class WpccBackdrop extends StatelessWidget {
  const WpccBackdrop({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => ColoredBox(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF171819)
            : WpccColors.background,
        child: child,
      );
}

ThemeData buildWpccTheme({Brightness brightness = Brightness.light}) {
  final dark = brightness == Brightness.dark;
  final ink = dark ? const Color(0xFFF1F2F3) : WpccColors.ink;
  final secondary = dark ? const Color(0xFFA9ADB3) : WpccColors.inkSoft;
  final surface = dark ? const Color(0xFF212325) : WpccColors.surface;
  final line = dark ? const Color(0xFF3A3D41) : WpccColors.line;
  final low = dark ? const Color(0xFF292C2F) : WpccColors.subtle;
  final accent = dark ? const Color(0xFFCAA9E8) : WpccColors.primaryDeep;
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: Colors.transparent,
    colorScheme: ColorScheme.fromSeed(
            seedColor: WpccColors.primary, brightness: brightness)
        .copyWith(
      primary: accent,
      onPrimary: dark ? WpccColors.ink : Colors.white,
      secondary: accent,
      surface: surface,
      onSurface: ink,
      onSurfaceVariant: secondary,
      outline: line,
      outlineVariant: line,
      surfaceContainerLowest:
          dark ? const Color(0xFF171819) : WpccColors.background,
      surfaceContainerLow: low,
      surfaceContainer: low,
      surfaceContainerHigh: low,
      surfaceContainerHighest: low,
      primaryContainer: dark ? const Color(0xFF3D304A) : WpccColors.primarySoft,
      onPrimaryContainer:
          dark ? const Color(0xFFE8D7F6) : WpccColors.primaryDeep,
      error: dark ? const Color(0xFFFFABA4) : WpccColors.error,
    ),
  );
  final text = base.textTheme.apply(
      fontFamily: 'DM Sans', bodyColor: ink, displayColor: ink);
  return base.copyWith(
    textTheme: text.copyWith(
      headlineSmall: text.headlineSmall?.copyWith(
          fontSize: 23,
          height: 1.2,
          fontWeight: FontWeight.w600,
          letterSpacing: 0),
      titleLarge: text.titleLarge?.copyWith(
          fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: 0),
      titleMedium: text.titleMedium?.copyWith(
          fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0),
      titleSmall: text.titleSmall?.copyWith(
          fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0),
      bodyMedium: text.bodyMedium
          ?.copyWith(fontSize: 14, height: 1.5, letterSpacing: 0),
      bodySmall: text.bodySmall?.copyWith(
          fontSize: 13, height: 1.4, color: secondary, letterSpacing: 0),
      labelSmall: text.labelSmall?.copyWith(fontSize: 11, letterSpacing: 0),
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: ink.withValues(alpha: .06),
    hoverColor: ink.withValues(alpha: .04),
    focusColor: accent.withValues(alpha: .12),
    dividerColor: line,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      foregroundColor: ink,
      titleTextStyle: text.titleMedium?.copyWith(
          color: ink,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0),
    ),
    iconTheme: IconThemeData(color: ink, size: 22),
    iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
            foregroundColor: ink, minimumSize: const Size(44, 44))),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: accent),
    textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
            foregroundColor: accent,
            textStyle:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
    filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: dark ? WpccColors.ink : Colors.white,
            minimumSize: const Size(44, 48),
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)))),
    elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: dark ? WpccColors.ink : Colors.white,
            minimumSize: const Size(44, 48),
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)))),
    outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
            foregroundColor: ink,
            side: BorderSide(color: line),
            minimumSize: const Size(44, 48),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)))),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? surface : secondary),
      trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? accent : line),
    ),
    cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)))),
    dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
    bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)))),
    popupMenuTheme: PopupMenuThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      hintStyle: text.bodyMedium?.copyWith(color: secondary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: line)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: line)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: accent, width: 1.5)),
    ),
  );
}
