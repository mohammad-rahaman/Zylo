import 'package:flutter/material.dart';

/// Centralized Zylo Design System Colors — "Graphite Luxe".
///
/// Dark-first: warm graphite carries the interface (with a paper light mode) and a
/// single muted ember accent marks what matters (primary actions, your own
/// messages, the brand mark). Glows and saturated gradients are intentionally
/// avoided; depth comes from soft shadows and hairline borders instead.
class AppColors {
  // Brand Accent — muted ember (white text on it passes WCAG AA)
  static const Color primaryOrange = Color(0xFFC0562F);
  static const Color secondaryOrange = Color(0xFFD98A68); // soft clay
  static const Color secondaryOrangeDark = Color(0xFFE2A386); // light clay, for links on dark
  static const Color emberLight = Color(0xFFD9805A); // accent lines, rings and labels on graphite
  static const Color momentSparkle = Color(0xFFC08A4F); // muted brass

  // Signature Gradients — subtle tonal sheens, not rainbows
  static const Color primaryGradientStart = Color(0xFFC55D36);
  static const Color primaryGradientEnd = Color(0xFFA9482A);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryGradientStart, primaryGradientEnd],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient sparkleGradient = LinearGradient(
    colors: [Color(0xFFA9482A), Color(0xFFC0562F), Color(0xFFD47D58)],
    stops: [0.0, 0.55, 1.0],
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
  );

  static const LinearGradient darkTileGradient = LinearGradient(
    colors: [Color(0xFF1E1D1B), Color(0xFF121110)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Accent tints (kept faint on purpose)
  static const Color glowOrange = Color(0x29C0562F);
  static const Color rimGlow = Color(0x1FC0562F);
  static const Color ambientGlow = Color(0x14C0562F);

  // Light Mode — warm paper & stone
  static const Color bgLight = Color(0xFFF7F5F1);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceSubduedLight = Color(0xFFEFECE7);
  static const Color textPrimaryLight = Color(0xFF1B1A18);
  static const Color textSecondaryLight = Color(0xFF6F6B65);
  static const Color borderLight = Color(0xFFE7E3DD);

  // Light Mode Bubbles
  static const Color bubbleSenderLight = primaryOrange;
  static const Color bubbleReceiverLight = surfaceLight;

  // Dark Mode — warm graphite
  static const Color bgDark = Color(0xFF0F0F0E);
  static const Color surfaceDark = Color(0xFF1A1918);
  static const Color surfaceSubduedDark = Color(0xFF232220);
  static const Color textPrimaryDark = Color(0xFFF3F1ED);
  static const Color textSecondaryDark = Color(0xFF9C978F);
  static const Color borderDark = Color(0xFF2A2926);

  // Dark Mode Bubbles
  static const Color bubbleSenderDark = primaryOrange;
  static const Color bubbleReceiverDark = surfaceDark;

  // Status & Utility Colors — desaturated so they inform without shouting
  static const Color onlineGreen = Color(0xFF3F9A6B);
  static const Color readReceiptBlue = Color(0xFF5B93C7);
  static const Color errorRed = Color(0xFFD04A40);
  static const Color warningAmber = Color(0xFFC98A2E);

  // Legacy aliases for backward compatibility
  static const Color primaryLight = primaryOrange;
  static const Color primaryDark = primaryOrange;
  static const Color unreadBadgeGreen = primaryOrange;
  static const Color offlineGrey = Color(0xFF9C978F);
}
