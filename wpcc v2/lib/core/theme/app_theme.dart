import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WpccColors {
  static const ink = Color(0xFF111217);
  static const inkSoft = Color(0xFF4F5563);
  static const muted = Color(0xFF8A909D);
  static const surface = Colors.white;
  static const background = Color(0xFFF8F9FC);
  static const line = Color(0xFFE9EBF1);
  static const lavender = Color(0xFFE5D5F4);
  static const coolBlue = Color(0xFFD7DEEF);
  static const warm = Color(0xFFF2E8DF);
}

ThemeData buildWpccTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: WpccColors.background,
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7657D9), surface: Colors.white),
  );
  final text = GoogleFonts.instrumentSansTextTheme(base.textTheme).apply(
    bodyColor: WpccColors.ink,
    displayColor: WpccColors.ink,
  );
  return base.copyWith(
    textTheme: text,
    splashFactory: NoSplash.splashFactory,
    dividerColor: WpccColors.line,
    cardTheme: const CardThemeData(
      elevation: 0,
      color: WpccColors.surface,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      hintStyle: text.bodySmall?.copyWith(color: WpccColors.muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: WpccColors.line)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: WpccColors.line)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: WpccColors.ink)),
    ),
  );
}
