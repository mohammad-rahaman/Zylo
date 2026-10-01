import 'package:flutter/material.dart';

/// Centralized Zylo Glow and Elevation Shadow System
class AppShadows {
  /// Signature Zylo soft orange ambient glow
  static const BoxShadow orangeGlow = BoxShadow(
    color: Color(0x55FF6B35),
    blurRadius: 20,
    spreadRadius: 2,
    offset: Offset(0, 4),
  );

  /// Subtle button tap / highlight glow
  static const BoxShadow buttonGlow = BoxShadow(
    color: Color(0x66FF6B35),
    blurRadius: 16,
    offset: Offset(0, 6),
  );

  /// Low-key ambient glow for dark mode tiles
  static const BoxShadow darkTileGlow = BoxShadow(
    color: Color(0x40FF6B35),
    blurRadius: 28,
    spreadRadius: 0,
    offset: Offset(0, 8),
  );

  /// Premium light mode card shadow (warm cream tone)
  static const BoxShadow cardLight = BoxShadow(
    color: Color(0x1250280A),
    blurRadius: 18,
    offset: Offset(0, 6),
  );

  /// Dark mode subtle elevation shadow
  static const BoxShadow cardDark = BoxShadow(
    color: Color(0x40000000),
    blurRadius: 16,
    offset: Offset(0, 4),
  );
}
