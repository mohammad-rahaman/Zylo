import 'package:flutter/material.dart';

enum ZyloFilterType {
  normal('Normal', '✨'),
  orangePop('Orange Pop', '🍊'),
  sunset('Sunset', '🌅'),
  glow('Glow', '💫'),
  softFocus('Soft Focus', '🌸'),
  retro('Retro', '📻'),
  cool('Cool', '🌊'),
  vintage('Vintage', '🎞️'),
  blackAndWhite('B&W', '🖤'),
  neon('Neon', '⚡'),
  comic('Comic', '🎨');

  final String displayName;
  final String icon;

  const ZyloFilterType(this.displayName, this.icon);

  ColorFilter? get colorFilter {
    switch (this) {
      case ZyloFilterType.normal:
        return null;

      case ZyloFilterType.orangePop:
        // Boosts warm oranges, reds and highlights (Zylo primary theme accent)
        return const ColorFilter.matrix(<double>[
          1.3, 0.0, 0.0, 0.0, 20.0,
          0.0, 1.05, 0.0, 0.0, 5.0,
          0.0, 0.0, 0.85, 0.0, -10.0,
          0.0, 0.0, 0.0, 1.0, 0.0,
        ]);

      case ZyloFilterType.sunset:
        // Golden warm sunset glow
        return const ColorFilter.matrix(<double>[
          1.25, 0.1, 0.0, 0.0, 30.0,
          0.05, 1.1, 0.0, 0.0, 15.0,
          0.0, 0.0, 0.8, 0.0, -15.0,
          0.0, 0.0, 0.0, 1.0, 0.0,
        ]);

      case ZyloFilterType.glow:
        // Bright radiant exposure
        return const ColorFilter.matrix(<double>[
          1.15, 0.0, 0.0, 0.0, 25.0,
          0.0, 1.15, 0.0, 0.0, 25.0,
          0.0, 0.0, 1.15, 0.0, 25.0,
          0.0, 0.0, 0.0, 1.0, 0.0,
        ]);

      case ZyloFilterType.softFocus:
        // Gentle pastel softness with light magenta-rose lift
        return const ColorFilter.matrix(<double>[
          1.08, 0.05, 0.0, 0.0, 18.0,
          0.02, 1.05, 0.02, 0.0, 12.0,
          0.05, 0.02, 1.12, 0.0, 18.0,
          0.0, 0.0, 0.0, 1.0, 0.0,
        ]);

      case ZyloFilterType.retro:
        // Sepia retro warm tint
        return const ColorFilter.matrix(<double>[
          0.393 + 0.607 * 0.4, 0.769 - 0.769 * 0.4, 0.189 - 0.189 * 0.4, 0.0, 0.0,
          0.349 - 0.349 * 0.4, 0.686 + 0.314 * 0.4, 0.168 - 0.168 * 0.4, 0.0, 0.0,
          0.272 - 0.272 * 0.4, 0.534 - 0.534 * 0.4, 0.131 + 0.869 * 0.4, 0.0, 0.0,
          0.0, 0.0, 0.0, 1.0, 0.0,
        ]);

      case ZyloFilterType.cool:
        // Cool crisp blues
        return const ColorFilter.matrix(<double>[
          0.9, 0.0, 0.0, 0.0, -10.0,
          0.0, 1.0, 0.0, 0.0, 5.0,
          0.0, 0.0, 1.25, 0.0, 25.0,
          0.0, 0.0, 0.0, 1.0, 0.0,
        ]);

      case ZyloFilterType.vintage:
        // Desaturated nostalgic film
        return const ColorFilter.matrix(<double>[
          0.85, 0.1, 0.05, 0.0, 10.0,
          0.05, 0.85, 0.1, 0.0, 10.0,
          0.1, 0.05, 0.75, 0.0, 15.0,
          0.0, 0.0, 0.0, 1.0, 0.0,
        ]);

      case ZyloFilterType.blackAndWhite:
        // High contrast monochrome
        return const ColorFilter.matrix(<double>[
          0.33, 0.59, 0.11, 0.0, 0.0,
          0.33, 0.59, 0.11, 0.0, 0.0,
          0.33, 0.59, 0.11, 0.0, 0.0,
          0.0, 0.0, 0.0, 1.0, 0.0,
        ]);

      case ZyloFilterType.neon:
        // Vivid punchy saturated contrast
        return const ColorFilter.matrix(<double>[
          1.4, -0.2, -0.2, 0.0, -10.0,
          -0.2, 1.4, -0.2, 0.0, -10.0,
          -0.2, -0.2, 1.6, 0.0, 0.0,
          0.0, 0.0, 0.0, 1.0, 0.0,
        ]);

      case ZyloFilterType.comic:
        // Stylized pop art vibrance
        return const ColorFilter.matrix(<double>[
          1.5, 0.0, 0.0, 0.0, -25.0,
          0.0, 1.4, 0.0, 0.0, -20.0,
          0.0, 0.0, 1.3, 0.0, -15.0,
          0.0, 0.0, 0.0, 1.0, 0.0,
        ]);
    }
  }
}
