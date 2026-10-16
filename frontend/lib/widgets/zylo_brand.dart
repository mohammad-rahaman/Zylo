import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';

enum ZyloSymbolVariant {
  /// Default: ink/ivory Z with an ember orbit (adapts to light/dark).
  orangeGradient,

  /// All-white mark for photos and colored surfaces.
  whiteMono,

  /// Ink Z with an ember orbit, for light surfaces regardless of theme.
  creamLight,
}

/// Paints the Zylo "Orbit Z": a monoline Z circled by a tilted orbit carrying
/// a single ember dot — the moment.
///
/// Geometry lives on a 120×120 grid (the same grid as the app icon, see
/// assets/app_icon) and scales to any size. Strokes are thickened at small
/// sizes so the mark stays legible down to ~16px.
class ZyloMarkPainter extends CustomPainter {
  final Color zColor;
  final Color orbitColor;
  final Color dotColor;
  final bool hasGlow;

  /// Position of the dot along the orbit, in radians. [restingPhase] places it
  /// at the upper right, clear of the Z (the position used in the logo).
  final double phase;

  ZyloMarkPainter({
    required this.zColor,
    required this.orbitColor,
    required this.dotColor,
    this.hasGlow = false,
    this.phase = restingPhase,
  });

  static const double restingPhase = -0.40; // upper right, clear of the Z
  static const double _grid = 120;
  static const Offset _orbitCenter = Offset(60, 61);
  static const double _orbitRx = 46;
  static const double _orbitRy = 17;
  static const double _orbitTilt = -24 * math.pi / 180;

  /// Point on the tilted orbit for a given phase (grid units).
  static Offset orbitPoint(double phase) {
    final x = _orbitRx * math.cos(phase);
    final y = _orbitRy * math.sin(phase);
    final c = math.cos(_orbitTilt);
    final s = math.sin(_orbitTilt);
    return _orbitCenter + Offset(x * c - y * s, x * s + y * c);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width, size.height) / _grid;
    canvas.save();
    canvas.translate((size.width - _grid * scale) / 2, (size.height - _grid * scale) / 2);
    canvas.scale(scale);

    // Stroke widths in grid units, with a minimum rendered thickness in pixels.
    final zWidth = math.max(9.0, 2.6 / scale);
    final orbitWidth = math.max(2.4, 1.2 / scale);
    final dotRadius = math.max(6.0, 2.2 / scale);
    final dot = orbitPoint(phase);
    final orbitRect = Rect.fromCenter(center: Offset.zero, width: _orbitRx * 2, height: _orbitRy * 2);
    final orbitPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = orbitWidth
      ..color = orbitColor;

    void inOrbitSpace(void Function() draw) {
      canvas.save();
      canvas.translate(_orbitCenter.dx, _orbitCenter.dy);
      canvas.rotate(_orbitTilt);
      draw();
      canvas.restore();
    }

    if (hasGlow) {
      final glowRadius = dotRadius * 3.4;
      canvas.drawCircle(
        dot,
        glowRadius,
        Paint()
          ..shader = RadialGradient(
            colors: [dotColor.withValues(alpha: 0.30), dotColor.withValues(alpha: 0.0)],
          ).createShader(Rect.fromCircle(center: dot, radius: glowRadius)),
      );
    }

    // 1. Orbit (sits behind the Z)
    inOrbitSpace(() => canvas.drawOval(orbitRect, orbitPaint));

    // 2. Monoline Z
    final z = Path()
      ..moveTo(39, 41)
      ..lineTo(81, 41)
      ..lineTo(39, 81)
      ..lineTo(81, 81);
    canvas.drawPath(
      z,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = zWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = zColor,
    );

    // 3. The moment dot
    canvas.drawCircle(dot, dotRadius, Paint()..color = dotColor);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ZyloMarkPainter oldDelegate) {
    return oldDelegate.zColor != zColor ||
        oldDelegate.orbitColor != orbitColor ||
        oldDelegate.dotColor != dotColor ||
        oldDelegate.hasGlow != hasGlow ||
        oldDelegate.phase != phase;
  }
}

/// The official scalable Zylo mark (Orbit Z).
class ZyloSymbol extends StatelessWidget {
  final double size;
  final ZyloSymbolVariant variant;
  final bool hasGlow;
  final bool? isDark;

  /// Override the Z color (e.g. to match a wordmark color).
  final Color? markColor;

  /// Override the orbit and dot color.
  final Color? accentColor;

  /// Dot position along the orbit (radians); animate it for loading states.
  final double phase;

  const ZyloSymbol({
    super.key,
    this.size = 56,
    this.variant = ZyloSymbolVariant.orangeGradient,
    this.hasGlow = true,
    this.isDark,
    this.markColor,
    this.accentColor,
    this.phase = ZyloMarkPainter.restingPhase,
  });

  @override
  Widget build(BuildContext context) {
    final dark = isDark ?? (Theme.of(context).brightness == Brightness.dark);

    final Color z;
    final Color orbit;
    final Color dot;
    switch (variant) {
      case ZyloSymbolVariant.orangeGradient:
        z = dark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
        orbit = dot = dark ? AppColors.emberLight : AppColors.primaryOrange;
        break;
      case ZyloSymbolVariant.creamLight:
        z = AppColors.textPrimaryLight;
        orbit = dot = AppColors.primaryOrange;
        break;
      case ZyloSymbolVariant.whiteMono:
        z = Colors.white;
        orbit = Colors.white.withValues(alpha: 0.6);
        dot = Colors.white;
        break;
    }

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: ZyloMarkPainter(
          zColor: markColor ?? z,
          orbitColor: accentColor ?? orbit,
          dotColor: accentColor ?? dot,
          hasGlow: hasGlow,
          phase: phase,
        ),
      ),
    );
  }
}

/// Full app icon tile, matching the launcher icon in assets/app_icon.
class ZyloAppIconTile extends StatelessWidget {
  final double size;
  final ZyloSymbolVariant variant;
  final bool showShadow;

  const ZyloAppIconTile({
    super.key,
    this.size = 96,
    this.variant = ZyloSymbolVariant.orangeGradient,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(size * 0.23);

    BoxDecoration decoration;
    switch (variant) {
      case ZyloSymbolVariant.orangeGradient:
        decoration = BoxDecoration(
          borderRadius: borderRadius,
          gradient: AppColors.darkTileGradient,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: math.max(1.0, size * 0.012),
          ),
          boxShadow: showShadow
              ? [
                  BoxShadow(
                    color: const Color(0x47000000),
                    blurRadius: size * 0.30,
                    spreadRadius: -size * 0.04,
                    offset: Offset(0, size * 0.08),
                  ),
                ]
              : null,
        );
        break;
      case ZyloSymbolVariant.creamLight:
        decoration = BoxDecoration(
          borderRadius: borderRadius,
          color: AppColors.surfaceLight,
          border: Border.all(
            color: AppColors.borderLight,
            width: math.max(1.0, size * 0.012),
          ),
          boxShadow: showShadow
              ? [
                  BoxShadow(
                    color: const Color(0x161B1A18),
                    blurRadius: size * 0.28,
                    spreadRadius: -size * 0.04,
                    offset: Offset(0, size * 0.07),
                  ),
                ]
              : null,
        );
        break;
      case ZyloSymbolVariant.whiteMono:
        decoration = BoxDecoration(
          borderRadius: borderRadius,
          color: AppColors.surfaceDark,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.10),
            width: math.max(1.0, size * 0.012),
          ),
          boxShadow: showShadow
              ? [
                  BoxShadow(
                    color: const Color(0x47000000),
                    blurRadius: size * 0.22,
                    spreadRadius: -size * 0.03,
                    offset: Offset(0, size * 0.06),
                  ),
                ]
              : null,
        );
        break;
    }

    return Container(
      width: size,
      height: size,
      decoration: decoration,
      child: Center(
        child: ZyloSymbol(
          size: size * 0.9,
          variant: variant,
          hasGlow: false,
          // Dark tiles always need the light mark, whatever the app theme.
          isDark: variant != ZyloSymbolVariant.creamLight,
        ),
      ),
    );
  }
}

/// Available presentation modes for the unified Zylo brand widget
enum ZyloBrandMode {
  /// Mark + serif "Zylo" wordmark
  wordmark,

  /// The Orbit Z mark only
  markOnly,

  /// Wordmark with the "SHARE YOUR MOMENT." tagline underneath
  stacked,

  /// Full standalone app icon tile
  appIcon,
}

/// The unified Zylo brand widget for Home, Splash, Onboarding, and Auth screens.
class ZyloBrand extends StatefulWidget {
  /// Base height of the mark/wordmark (e.g. 24 in a header, 42 on splash)
  final double size;

  /// Presentation mode (wordmark, markOnly, stacked, appIcon)
  final ZyloBrandMode mode;

  /// Theme override (defaults to active theme brightness)
  final bool? isDark;

  /// Wordmark text (and Z) color override
  final Color? wordmarkColor;

  /// Orbit/dot color override
  final Color? accentColor;

  /// Whether to render the soft glow around the moment dot
  final bool hasGlow;

  /// Whether to play a subtle 260ms single-shot entrance animation
  final bool animate;

  /// Whether to show the "SHARE YOUR MOMENT." brand tagline (used in stacked mode)
  final bool showTagline;

  /// Whether the wordmark includes the mark. Turn off where a large mark is
  /// already on screen (splash, onboarding) to avoid repeating it.
  final bool showMark;

  /// Optional tap handler with light haptic feedback
  final VoidCallback? onTap;

  const ZyloBrand({
    super.key,
    this.size = 28,
    this.mode = ZyloBrandMode.wordmark,
    this.isDark,
    this.wordmarkColor,
    this.accentColor,
    this.hasGlow = true,
    this.animate = false,
    this.showTagline = false,
    this.showMark = true,
    this.onTap,
  });

  @override
  State<ZyloBrand> createState() => _ZyloBrandState();
}

class _ZyloBrandState extends State<ZyloBrand> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveDark = widget.isDark ?? (Theme.of(context).brightness == Brightness.dark);

    // Standalone app icon container mode
    if (widget.mode == ZyloBrandMode.appIcon) {
      return ZyloAppIconTile(
        size: widget.size,
        variant: effectiveDark ? ZyloSymbolVariant.orangeGradient : ZyloSymbolVariant.creamLight,
        showShadow: true,
      );
    }

    final mark = ZyloSymbol(
      size: widget.size * 1.1,
      isDark: effectiveDark,
      hasGlow: widget.hasGlow && widget.mode == ZyloBrandMode.markOnly,
      markColor: widget.wordmarkColor,
      accentColor: widget.accentColor,
    );

    Widget content;
    if (widget.mode == ZyloBrandMode.markOnly) {
      content = Semantics(label: 'Zylo', child: mark);
    } else {
      final wordmark = Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (widget.showMark) ...[
            mark,
            SizedBox(width: widget.size * 0.14),
          ],
          Text(
            'Zylo',
            style: AppTypography.serifTitle(
              fontSize: widget.size * 1.25,
              isDark: effectiveDark,
              color: widget.wordmarkColor,
            ).copyWith(height: 1.0, letterSpacing: -0.2),
          ),
        ],
      );

      if (widget.mode == ZyloBrandMode.stacked || widget.showTagline) {
        content = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            wordmark,
            SizedBox(height: widget.size * 0.22),
            Text(
              'SHARE YOUR MOMENT.',
              style: AppTypography.tagline(
                fontSize: math.max(9.0, widget.size * 0.26),
                color: effectiveDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                letterSpacing: 3.2,
              ),
            ),
          ],
        );
      } else {
        content = wordmark;
      }
      content = Semantics(header: true, child: content);
    }

    // Optional entrance animation
    if (widget.animate) {
      content = FadeTransition(
        opacity: _fade,
        child: ScaleTransition(
          scale: _scale,
          alignment: Alignment.centerLeft,
          child: content,
        ),
      );
    }

    if (widget.onTap != null) {
      return GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap!();
        },
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }

    return content;
  }
}

/// Backward-compatible wrapper for ZyloBrandLockup
class ZyloBrandLockup extends StatelessWidget {
  final double symbolSize;
  final double fontSize;
  final double? size;
  final bool? isDark;
  final bool animate;
  final bool showWordmark;
  final VoidCallback? onTap;

  const ZyloBrandLockup({
    super.key,
    this.symbolSize = 28,
    this.fontSize = 24,
    this.size,
    this.isDark,
    this.animate = true,
    this.showWordmark = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ZyloBrand(
      size: size ?? fontSize + 2.0,
      mode: showWordmark ? ZyloBrandMode.wordmark : ZyloBrandMode.markOnly,
      isDark: isDark,
      animate: animate,
      onTap: onTap,
    );
  }
}

/// Reusable alias for the Zylo brand lockup
typedef ZyloLogo = ZyloBrand;

/// Backward-compatible wrapper for ZyloWordmark
class ZyloWordmark extends StatelessWidget {
  final double fontSize;
  final bool showTagline;
  final Color? color;
  final bool isDark;

  const ZyloWordmark({
    super.key,
    this.fontSize = 32,
    this.showTagline = true,
    this.color,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    return ZyloBrand(
      size: fontSize,
      mode: showTagline ? ZyloBrandMode.stacked : ZyloBrandMode.wordmark,
      isDark: isDark,
      wordmarkColor: color,
      showTagline: showTagline,
    );
  }
}
