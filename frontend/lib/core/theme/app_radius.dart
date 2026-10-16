import 'package:flutter/material.dart';

/// Centralized Zylo Design System Corner Radius Tokens.
/// Slightly tighter than before for a more tailored, less bubbly feel.
class AppRadius {
  static const double sm = 10.0;
  static const double md = 14.0;
  static const double lg = 18.0;
  static const double card = 20.0;
  static const double sheet = 24.0;
  static const double heroCard = 28.0;
  static const double pill = 999.0;

  static const BorderRadius smBorder = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdBorder = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgBorder = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius cardBorder = BorderRadius.all(Radius.circular(card));
  static const BorderRadius sheetBorder = BorderRadius.vertical(top: Radius.circular(sheet));
  static const BorderRadius heroCardBorder = BorderRadius.all(Radius.circular(heroCard));
  static const BorderRadius pillBorder = BorderRadius.all(Radius.circular(pill));
}
