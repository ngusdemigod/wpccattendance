import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WpccColors {
  static const ink = Color(0xFF1C1E24);
  static const navActive = Color(0xFF111217);
  static const inkSoft = Color(0xFF6F7077);
  static const muted = Color(0xFF8B8C93);
  static const surface = Colors.white;
  static const subtle = Color(0xFFF9F9FC);
  static const background = Color(0xFFF6F7FA);
  static const screenWhite = Color(0xFFFBFCFF);
  static const line = Color(0xFFE9EAED);
  static const lineSubtle = Color(0xFFF0F1F3);
  static const primary = Color(0xFF7C4EA6);
  static const primaryDeep = Color(0xFF683793);
  static const primarySoft = Color(0xFFF1E6FA);
  static const lavender = Color(0xFFE3C7F5);
  static const coolBlue = Color(0xFFD6DCF1);
  static const warm = Color(0xFFF2E8DF);
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
  Widget build(BuildContext context) => Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0, .42, 1],
                colors: [
                  Color(0xFFF4F6FC),
                  WpccColors.screenWhite,
                  Color(0xFFF2F4FA),
                ],
              ),
            ),
          ),
          const Positioned(
            left: -150,
            top: -190,
            width: 430,
            height: 430,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [Color(0x42B1BDE6), Color(0x00B1BDE6)],
                ),
              ),
            ),
          ),
          const Positioned(
            right: -180,
            bottom: -210,
            width: 500,
            height: 500,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [Color(0x5CE8ECF8), Color(0x00E8ECF8)],
                ),
              ),
            ),
          ),
          child,
        ],
      );
}

ThemeData buildWpccTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.transparent,
    colorScheme: ColorScheme.fromSeed(
      seedColor: WpccColors.primary,
      surface: WpccColors.surface,
    ).copyWith(
      primary: WpccColors.primary,
      secondary: WpccColors.primaryDeep,
      error: WpccColors.error,
    ),
  );
  final text = GoogleFonts.instrumentSansTextTheme(base.textTheme).apply(
    bodyColor: WpccColors.ink,
    displayColor: WpccColors.ink,
  );
  return base.copyWith(
    textTheme: text,
    splashFactory: NoSplash.splashFactory,
    dividerColor: WpccColors.line,
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: WpccColors.primary,
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: WpccColors.primaryDeep),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? Colors.white
            : const Color(0xFFD7D8DC),
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? WpccColors.primary
            : WpccColors.line,
      ),
    ),
    cardTheme: const CardThemeData(
      elevation: 0,
      color: WpccColors.surface,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24))),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      hintStyle: text.bodySmall?.copyWith(color: WpccColors.muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: WpccColors.line)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: WpccColors.line)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: WpccColors.ink)),
    ),
  );
}
