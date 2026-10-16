import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Centralized Zylo Design System Typography.
/// Editorial serif for screen titles, a quiet sans for everything else.
class AppTypography {
  /// Bundled display serif (see pubspec.yaml). Single weight — use size, not boldness.
  static const String serifFamily = 'InstrumentSerif';

  /// Large editorial screen title, e.g. "Chats", "Welcome back".
  static TextStyle serifTitle({double fontSize = 36, Color? color, bool isDark = true}) {
    return TextStyle(
      fontFamily: serifFamily,
      fontSize: fontSize,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.3,
      height: 1.05,
      color: color ?? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
    );
  }

  /// Primary "Zylo" brand wordmark style
  static TextStyle wordmark({
    double fontSize = 34,
    Color? color,
    FontWeight fontWeight = FontWeight.w700,
    double letterSpacing = -0.8,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      color: color ?? AppColors.primaryOrange,
      height: 1.05,
    );
  }

  /// Official brand tagline: "SHARE YOUR MOMENT."
  static TextStyle tagline({
    double fontSize = 11,
    Color? color,
    double letterSpacing = 2.8,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
      letterSpacing: letterSpacing,
      color: color ?? AppColors.textSecondaryLight,
      height: 1.2,
    );
  }

  /// Hero titles (e.g. Welcome Screen, Sheet headers)
  static TextStyle displayLarge({Color? color, bool isDark = false}) {
    return TextStyle(
      fontFamily: serifFamily,
      fontSize: 40,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.4,
      color: color ?? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
      height: 1.15,
    );
  }

  static TextStyle displayMedium({Color? color, bool isDark = false}) {
    return TextStyle(
      fontFamily: serifFamily,
      fontSize: 30,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.3,
      color: color ?? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
      height: 1.2,
    );
  }

  static TextStyle headline({Color? color, bool isDark = false}) {
    return TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.3,
      color: color ?? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
    );
  }

  static TextStyle bodyLarge({Color? color, bool isDark = false}) {
    return TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.1,
      color: color ?? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
      height: 1.45,
    );
  }

  static TextStyle bodyMedium({Color? color, bool isDark = false}) {
    return TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: color ?? (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
      height: 1.4,
    );
  }

  static TextStyle caption({Color? color, bool isDark = false}) {
    return TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: color ?? (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
      letterSpacing: 0.1,
    );
  }

  /// Moment relationship metadata badge
  static const TextStyle momentBadge = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    height: 1.0,
  );
}
