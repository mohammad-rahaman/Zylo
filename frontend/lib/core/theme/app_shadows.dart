import 'package:flutter/material.dart';

/// Centralized Zylo Elevation System.
///
/// Soft, tight shadows with negative spread read as "lifted" rather than
/// "glowing". Names are kept from the original glow system for compatibility.
class AppShadows {
  /// Elevated surface with a faint warm lift (formerly an orange glow)
  static const BoxShadow orangeGlow = BoxShadow(
    color: Color(0x1A6B2E18),
    blurRadius: 22,
    spreadRadius: -4,
    offset: Offset(0, 8),
  );

  /// Primary button lift — a whisper of the accent beneath the button
  static const BoxShadow buttonGlow = BoxShadow(
    color: Color(0x2E8E3D20),
    blurRadius: 14,
    spreadRadius: -4,
    offset: Offset(0, 6),
  );

  /// Dark mode tile elevation
  static const BoxShadow darkTileGlow = BoxShadow(
    color: Color(0x47000000),
    blurRadius: 24,
    spreadRadius: -6,
    offset: Offset(0, 10),
  );

  /// Light mode card shadow
  static const BoxShadow cardLight = BoxShadow(
    color: Color(0x0F1B1A18),
    blurRadius: 24,
    spreadRadius: -6,
    offset: Offset(0, 8),
  );

  /// Dark mode card shadow
  static const BoxShadow cardDark = BoxShadow(
    color: Color(0x52000000),
    blurRadius: 20,
    spreadRadius: -6,
    offset: Offset(0, 8),
  );
}
