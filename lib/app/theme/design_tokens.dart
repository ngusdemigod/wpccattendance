import 'package:flutter/material.dart';

class AppDesignTokens extends ThemeExtension<AppDesignTokens> {
  const AppDesignTokens({required this.background, required this.surface, required this.textPrimary, required this.textMuted, required this.border, required this.icyLavender});
  const AppDesignTokens.light() : this(background: const Color(0xFFFDFDFF), surface: const Color(0xFFFFFEFC), textPrimary: const Color(0xFF16151B), textMuted: const Color(0xFF706E7A), border: const Color(0x140F0D18), icyLavender: const Color(0xFFF5F3FF));
  const AppDesignTokens.dark() : this(background: const Color(0xFF17151C), surface: const Color(0xFF211F27), textPrimary: Colors.white, textMuted: const Color(0xFFCAC5D2), border: const Color(0x24FFFFFF), icyLavender: const Color(0xFF2B2735));
  final Color background; final Color surface; final Color textPrimary; final Color textMuted; final Color border; final Color icyLavender;
  @override AppDesignTokens copyWith({Color? background, Color? surface, Color? textPrimary, Color? textMuted, Color? border, Color? icyLavender}) => AppDesignTokens(background: background ?? this.background, surface: surface ?? this.surface, textPrimary: textPrimary ?? this.textPrimary, textMuted: textMuted ?? this.textMuted, border: border ?? this.border, icyLavender: icyLavender ?? this.icyLavender);
  @override AppDesignTokens lerp(ThemeExtension<AppDesignTokens>? other, double t) => other is! AppDesignTokens ? this : AppDesignTokens(background: Color.lerp(background, other.background, t)!, surface: Color.lerp(surface, other.surface, t)!, textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!, textMuted: Color.lerp(textMuted, other.textMuted, t)!, border: Color.lerp(border, other.border, t)!, icyLavender: Color.lerp(icyLavender, other.icyLavender, t)!);
}
extension AppDesignTokensContext on BuildContext { AppDesignTokens get tokens => Theme.of(this).extension<AppDesignTokens>() ?? const AppDesignTokens.light(); }
