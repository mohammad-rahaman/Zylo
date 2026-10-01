import 'package:flutter/material.dart';

/// Centralized Zylo Design System Colors
/// Inspired by the official visual brand reference: warm cream light mode, deep cinematic dark mode,
/// and luminous #FF6B35 orange glow accents.
class AppColors {
  // Brand Core Colors
  static const Color primaryOrange = Color(0xFFFF6B35);
  static const Color secondaryOrange = Color(0xFFFF9B71);
  static const Color secondaryOrangeDark = Color(0xFFFFB38A);
  static const Color momentSparkle = Color(0xFFFF8A00);

  // Signature Gradients
  static const Color primaryGradientStart = Color(0xFFFF4B1F);
  static const Color primaryGradientEnd = Color(0xFFFF8A4C);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryGradientStart, primaryGradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient sparkleGradient = LinearGradient(
    colors: [Color(0xFFFF451A), Color(0xFFFFA040)],
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
  );

  static const LinearGradient darkTileGradient = LinearGradient(
    colors: [Color(0xFF181818), Color(0xFF0D0D0D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Lighting & Glow Accents
  static const Color glowOrange = Color(0x66FF6B35);
  static const Color rimGlow = Color(0x4DFF6B35);
  static const Color ambientGlow = Color(0x26FF6B35);

  // Light Mode Colors
  static const Color bgLight = Color(0xFFFFF8F3); // Warm Cream (Dominant)
  static const Color surfaceLight = Color(0xFFFFFFFF); // Card & surface white
  static const Color surfaceSubduedLight = Color(0xFFF7EFE9);
  static const Color textPrimaryLight = Color(0xFF1E1E1E);
  static const Color textSecondaryLight = Color(0xFF706B67);
  static const Color borderLight = Color(0xFFF0E5DC);

  // Light Mode Bubbles
  static const Color bubbleSenderLight = Color(0xFFFF6B35);
  static const Color bubbleReceiverLight = Color(0xFFFFFFFF);

  // Dark Mode Colors
  static const Color bgDark = Color(0xFF121212); // Deep Charcoal
  static const Color surfaceDark = Color(0xFF1E1E1E); // Elevated Card
  static const Color surfaceSubduedDark = Color(0xFF262626);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFA0A0A0);
  static const Color borderDark = Color(0xFF2D2D2D);

  // Dark Mode Bubbles
  static const Color bubbleSenderDark = Color(0xFFFF6B35);
  static const Color bubbleReceiverDark = Color(0xFF1E1E1E);

  // Status & Utility Colors
  static const Color onlineGreen = Color(0xFF10B981);
  static const Color readReceiptBlue = Color(0xFF38BDF8);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color warningAmber = Color(0xFFF59E0B);

  // Legacy aliases for backward compatibility
  static const Color primaryLight = primaryOrange;
  static const Color primaryDark = primaryOrange;
  static const Color unreadBadgeGreen = primaryOrange;
  static const Color offlineGrey = Color(0xFF9CA3AF);
}
