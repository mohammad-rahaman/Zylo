import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Centralized Zylo Design System Typography
/// Clean, contemporary, confident sans-serif hierarchy.
class AppTypography {
  /// Primary "Zylo" brand wordmark style
  static TextStyle wordmark({
    double fontSize = 34,
    Color? color,
    FontWeight fontWeight = FontWeight.w900,
    double letterSpacing = -0.5,
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
    double letterSpacing = 3.6,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      letterSpacing: letterSpacing,
      color: color ?? AppColors.primaryOrange.withValues(alpha: 0.85),
      height: 1.2,
    );
  }

  /// Hero titles (e.g. Welcome Screen, Sheet headers)
  static TextStyle displayLarge({Color? color, bool isDark = false}) {
    return TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.8,
      color: color ?? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
      height: 1.15,
    );
  }

  static TextStyle displayMedium({Color? color, bool isDark = false}) {
    return TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.4,
      color: color ?? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
      height: 1.2,
    );
  }

  static TextStyle headline({Color? color, bool isDark = false}) {
    return TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.2,
      color: color ?? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
    );
  }

  static TextStyle bodyLarge({Color? color, bool isDark = false}) {
    return TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: color ?? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
      height: 1.4,
    );
  }

  static TextStyle bodyMedium({Color? color, bool isDark = false}) {
    return TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: color ?? (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
      height: 1.35,
    );
  }

  static TextStyle caption({Color? color, bool isDark = false}) {
    return TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: color ?? (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
      letterSpacing: 0.2,
    );
  }

  /// Moment relationship metadata badge
  static const TextStyle momentBadge = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.2,
    height: 1.0,
  );
}
