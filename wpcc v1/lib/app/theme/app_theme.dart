import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';
import 'design_tokens.dart';
import '../../shared/widgets/app_motion.dart';

abstract final class AppTheme {
  static ThemeData light() {
    final tokens = const AppDesignTokens.light();
    final textTheme = AppTypography.textTheme(tokens);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      surface: tokens.surface,
    ).copyWith(
      primary: AppColors.primary,
      secondary: AppColors.gold,
      surface: tokens.surface,
      onSurface: tokens.textPrimary,
      error: AppColors.danger,
    );
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      scaffoldBackgroundColor: tokens.background,
      canvasColor: tokens.background,
      colorScheme: colorScheme,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      cardColor: tokens.surface,
      dividerColor: tokens.border,
      iconTheme: const IconThemeData(color: AppColors.primary),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
      ),
      pageTransitionsTheme: _pageTransitionsTheme,
      extensions: [tokens],
    );
  }

  static ThemeData dark() {
    final tokens = const AppDesignTokens.dark();
    final textTheme = AppTypography.textTheme(tokens);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      surface: tokens.surface,
    ).copyWith(
      primary: AppColors.primary,
      secondary: AppColors.gold,
      surface: tokens.surface,
      onSurface: tokens.textPrimary,
      error: AppColors.danger,
    );
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: tokens.background,
      canvasColor: tokens.background,
      colorScheme: colorScheme,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      cardColor: tokens.surface,
      dividerColor: tokens.border,
      iconTheme: const IconThemeData(color: AppColors.primary),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
      ),
      pageTransitionsTheme: _pageTransitionsTheme,
      extensions: [tokens],
    );
  }

  static const _pageTransitionsTheme = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: AppPageTransitionsBuilder(),
      TargetPlatform.iOS: AppPageTransitionsBuilder(),
      TargetPlatform.macOS: AppPageTransitionsBuilder(),
      TargetPlatform.windows: AppPageTransitionsBuilder(),
      TargetPlatform.linux: AppPageTransitionsBuilder(),
      TargetPlatform.fuchsia: AppPageTransitionsBuilder(),
    },
  );
}
