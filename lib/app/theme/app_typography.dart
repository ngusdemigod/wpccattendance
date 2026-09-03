import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'design_tokens.dart';

abstract final class AppTypography {
  static TextTheme textTheme(AppDesignTokens tokens) {
    final base = GoogleFonts.instrumentSansTextTheme().apply(
      bodyColor: tokens.textPrimary,
      displayColor: tokens.textPrimary,
    );

    return base.copyWith(
      displayLarge: GoogleFonts.instrumentSerif(
        fontSize: 36,
        height: 42 / 36,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.36,
        color: tokens.textPrimary,
      ),
      displayMedium: GoogleFonts.instrumentSerif(
        fontSize: 32,
        height: 38 / 32,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.32,
        color: tokens.textPrimary,
      ),
      displaySmall: GoogleFonts.instrumentSerif(
        fontSize: 24,
        height: 23 / 24,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.48,
        color: tokens.textPrimary,
      ),
      headlineLarge: GoogleFonts.instrumentSans(
        fontSize: 25,
        height: 25 / 25,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.8,
        color: tokens.textPrimary,
      ),
      headlineMedium: GoogleFonts.instrumentSans(
        fontSize: 24,
        height: 30 / 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.48,
        color: tokens.textPrimary,
      ),
      headlineSmall: GoogleFonts.instrumentSans(
        fontSize: 20,
        height: 24 / 20,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.5,
        color: tokens.textPrimary,
      ),
      titleLarge: GoogleFonts.instrumentSans(
        fontSize: 17,
        height: 24 / 17,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.5,
        color: tokens.textPrimary,
      ),
      titleMedium: GoogleFonts.instrumentSans(
        fontSize: 15,
        height: 18 / 15,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.5,
        color: tokens.textPrimary,
      ),
      titleSmall: GoogleFonts.instrumentSans(
        fontSize: 14,
        height: 17 / 14,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.35,
        color: tokens.textPrimary,
      ),
      bodyLarge: GoogleFonts.instrumentSans(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.5,
        color: tokens.textPrimary,
      ),
      bodyMedium: GoogleFonts.instrumentSans(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.35,
        color: tokens.textPrimary,
      ),
      bodySmall: GoogleFonts.instrumentSans(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.5,
        color: tokens.textMuted,
      ),
      labelLarge: GoogleFonts.instrumentSans(
        fontSize: 13,
        height: 18 / 13,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.35,
        color: tokens.textPrimary,
      ),
      labelMedium: GoogleFonts.instrumentSans(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.5,
        color: tokens.textMuted,
      ),
      labelSmall: GoogleFonts.instrumentSans(
        fontSize: 10,
        height: 10 / 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: tokens.textMuted,
      ),
    );
  }
}

class AppTypeStyles {
  const AppTypeStyles(this.context);

  final BuildContext context;

  AppDesignTokens get _tokens => context.tokens;
  TextTheme get _textTheme => Theme.of(context).textTheme;

  TextStyle serifDisplay({
    Color? color,
    double? fontSize,
  }) {
    return _textTheme.displayLarge!.copyWith(
      color: color ?? _tokens.textPrimary,
      fontSize: fontSize,
    );
  }

  TextStyle serifHero({
    Color? color,
    double? fontSize,
  }) {
    return _textTheme.displaySmall!.copyWith(
      color: color ?? _tokens.textPrimary,
      fontSize: fontSize,
    );
  }

  TextStyle pageGreeting({
    Color? color,
  }) {
    return _textTheme.bodySmall!.copyWith(
      color: color ?? _tokens.textMuted,
      fontWeight: FontWeight.w400,
      height: 1.2,
    );
  }

  TextStyle pageName({
    Color? color,
  }) {
    return _textTheme.displaySmall!.copyWith(
      fontSize: 25,
      height: 1.05,
      color: color ?? _tokens.textPrimary,
    );
  }

  TextStyle sectionTitle({
    Color? color,
    FontWeight? fontWeight,
  }) {
    return _textTheme.titleMedium!.copyWith(
      color: color ?? _tokens.textPrimary,
      fontWeight: fontWeight ?? FontWeight.w400,
    );
  }

  TextStyle cardTitleSans({
    Color? color,
    FontWeight? fontWeight,
  }) {
    return _textTheme.bodyLarge!.copyWith(
      color: color ?? _tokens.textPrimary,
      fontWeight: fontWeight ?? FontWeight.w400,
    );
  }

  TextStyle cardTitleStrong({
    Color? color,
  }) {
    return _textTheme.titleSmall!.copyWith(
      color: color ?? _tokens.textPrimary,
    );
  }

  TextStyle supportText({
    Color? color,
    FontWeight? fontWeight,
  }) {
    return _textTheme.bodySmall!.copyWith(
      color: color ?? _tokens.textMuted,
      fontWeight: fontWeight ?? FontWeight.w400,
    );
  }

  TextStyle metadataText({
    Color? color,
    FontWeight? fontWeight,
  }) {
    return _textTheme.labelMedium!.copyWith(
      color: color ?? _tokens.textMuted,
      fontWeight: fontWeight ?? FontWeight.w400,
    );
  }

  TextStyle eyebrow({
    Color? color,
    FontWeight? fontWeight,
  }) {
    return _textTheme.labelSmall!.copyWith(
      color: color ?? _tokens.textPrimary,
      fontWeight: fontWeight ?? FontWeight.w600,
    );
  }

  TextStyle badge({
    Color? color,
  }) {
    return _textTheme.labelSmall!.copyWith(
      color: color ?? _tokens.textPrimary,
    );
  }

  TextStyle pillLabel({
    Color? color,
  }) {
    return _textTheme.bodySmall!.copyWith(
      color: color ?? _tokens.textPrimary,
      fontWeight: FontWeight.w600,
      height: 1,
    );
  }

  TextStyle compactCaption({
    Color? color,
  }) {
    return _textTheme.bodySmall!.copyWith(
      color: color ?? _tokens.textMuted,
      fontSize: 11.5,
      height: 1.35,
    );
  }
}

extension AppTypographyContextX on BuildContext {
  AppTypeStyles get appText => AppTypeStyles(this);
}
