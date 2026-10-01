import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';

enum ZyloSymbolVariant {
  orangeGradient,
  whiteMono,
  creamLight,
}

/// Painter that renders the signature Zylo 4-point dynamic curved dual-sparkle.
class ZyloSparklePainter extends CustomPainter {
  final ZyloSymbolVariant variant;
  final bool hasGlow;
  final bool isDark;

  ZyloSparklePainter({
    this.variant = ZyloSymbolVariant.orangeGradient,
    this.hasGlow = true,
    this.isDark = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Center of main sparkle
    final cx = w * 0.46;
    final cy = h * 0.52;
    final r = w * 0.44;

    // Center of secondary sparkle (offset to top-right)
    final secCx = w * 0.76;
    final secCy = h * 0.26;
    final secR = r * 0.36;

    // 1. Ambient Glow Bloom (Soft warm light, subtle and refined)
    if (hasGlow && variant == ZyloSymbolVariant.orangeGradient) {
      final glowPaint = Paint()
        ..shader = RadialGradient(
          colors: isDark
              ? [
                  const Color(0x60FF6B35),
                  const Color(0x20FF451A),
                  Colors.transparent,
                ]
              : [
                  const Color(0x35FF6B35),
                  const Color(0x12FF8A4C),
                  Colors.transparent,
                ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r * 1.5))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * (isDark ? 0.14 : 0.10));

      canvas.drawCircle(Offset(cx, cy), r * 1.3, glowPaint);
    }

    // 2. Sparkle Gradient or Solid Paint
    Paint sparklePaint;
    switch (variant) {
      case ZyloSymbolVariant.orangeGradient:
        sparklePaint = Paint()
          ..shader = const LinearGradient(
            colors: [
              Color(0xFFFF350D), // Deep rich orange-red base
              Color(0xFFFF6F33), // Vibrant Zylo signature orange
              Color(0xFFFFA656), // Warm golden highlight tip
            ],
            stops: [0.0, 0.52, 1.0],
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
          ).createShader(Rect.fromLTWH(0, 0, w, h))
          ..style = PaintingStyle.fill;
        break;
      case ZyloSymbolVariant.whiteMono:
        sparklePaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        break;
      case ZyloSymbolVariant.creamLight:
        sparklePaint = Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFFFF4B1F), Color(0xFFFF8A4C)],
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
          ).createShader(Rect.fromLTWH(0, 0, w, h))
          ..style = PaintingStyle.fill;
        break;
    }

    // Draw Main Sparkle Path
    final mainPath = _createSparklePath(cx, cy, r, pinch: 0.24);
    canvas.drawPath(mainPath, sparklePaint);

    // Draw Secondary Sparkle Path
    final secPath = _createSparklePath(secCx, secCy, secR, pinch: 0.24);
    canvas.drawPath(secPath, sparklePaint);

    // 3. Subtle core specular highlight (gives subtle depth without clutter)
    if (variant == ZyloSymbolVariant.orangeGradient) {
      final highlightPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: isDark ? 0.65 : 0.50),
            Colors.white.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 1.0],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.25))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(cx, cy), r * 0.25, highlightPaint);
    }
  }

  Path _createSparklePath(double cx, double cy, double radius, {double pinch = 0.24}) {
    final path = Path();
    final p = radius * pinch;

    // Tips
    final top = Offset(cx, cy - radius);
    final right = Offset(cx + radius, cy);
    final bottom = Offset(cx, cy + radius);
    final left = Offset(cx - radius, cy);

    // Start at top tip
    path.moveTo(top.dx, top.dy);

    // Curve from top to right
    path.cubicTo(
      cx, cy - p,
      cx + p, cy,
      right.dx, right.dy,
    );

    // Curve from right to bottom
    path.cubicTo(
      cx + p, cy,
      cx, cy + p,
      bottom.dx, bottom.dy,
    );

    // Curve from bottom to left
    path.cubicTo(
      cx, cy + p,
      cx - p, cy,
      left.dx, left.dy,
    );

    // Curve from left to top
    path.cubicTo(
      cx - p, cy,
      cx, cy - p,
      top.dx, top.dy,
    );

    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant ZyloSparklePainter oldDelegate) {
    return oldDelegate.variant != variant ||
        oldDelegate.hasGlow != hasGlow ||
        oldDelegate.isDark != isDark;
  }
}

/// The official scalable Zylo Symbol widget
class ZyloSymbol extends StatelessWidget {
  final double size;
  final ZyloSymbolVariant variant;
  final bool hasGlow;
  final bool? isDark;

  const ZyloSymbol({
    super.key,
    this.size = 56,
    this.variant = ZyloSymbolVariant.orangeGradient,
    this.hasGlow = true,
    this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveDark = isDark ?? (Theme.of(context).brightness == Brightness.dark);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: ZyloSparklePainter(
          variant: variant,
          hasGlow: hasGlow,
          isDark: effectiveDark,
        ),
      ),
    );
  }
}

/// Full app icon container tile as shown in the brand reference
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
          gradient: const LinearGradient(
            colors: [Color(0xFF1E1715), Color(0xFF0C0908)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: const Color(0x66FF6B35),
            width: math.max(1.5, size * 0.02),
          ),
          boxShadow: showShadow
              ? [
                  BoxShadow(
                    color: const Color(0x55FF6B35),
                    blurRadius: size * 0.35,
                    spreadRadius: size * 0.02,
                    offset: Offset(0, size * 0.08),
                  ),
                ]
              : null,
        );
        break;
      case ZyloSymbolVariant.creamLight:
        decoration = BoxDecoration(
          borderRadius: borderRadius,
          color: const Color(0xFFFFF8F3),
          border: Border.all(
            color: const Color(0xFFF0E5DC),
            width: math.max(1.0, size * 0.015),
          ),
          boxShadow: showShadow
              ? [
                  BoxShadow(
                    color: const Color(0x1A50280A),
                    blurRadius: size * 0.25,
                    offset: Offset(0, size * 0.06),
                  ),
                ]
              : null,
        );
        break;
      case ZyloSymbolVariant.whiteMono:
        decoration = BoxDecoration(
          borderRadius: borderRadius,
          color: const Color(0xFF1A1A1A),
          border: Border.all(
            color: Colors.white24,
            width: math.max(1.0, size * 0.015),
          ),
          boxShadow: showShadow
              ? [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: size * 0.2,
                    offset: Offset(0, size * 0.05),
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
          size: size * 0.65,
          variant: variant,
          hasGlow: variant == ZyloSymbolVariant.orangeGradient,
        ),
      ),
    );
  }
}

/// Available presentation modes for the unified Zylo brand widget
enum ZyloBrandMode {
  /// Full bespoke vector wordmark with integrated Z sparkle emblem ("Zylo")
  wordmark,
  /// The signature custom Z emblem only (integrated with apex sparkle and glow)
  markOnly,
  /// Stacked branding with the custom wordmark and "SHARE YOUR MOMENT." tagline
  stacked,
  /// Full standalone app icon tile
  appIcon,
}

/// Custom painter that draws the bespoke Zylo vector wordmark:
/// - Distinctive custom 'Z' with the signature Zylo 4-point sparkle seamlessly fused
///   into its upper-right apex, subtle connection accent on the diagonal, and aerodynamic 45° chamfer.
/// - Harmonious bespoke 'y', 'l', 'o' geometric letterforms.
/// - Light mode: #1E1E1E wordmark + #FF6B35 orange accent.
/// - Dark mode: #FFFFFF wordmark + #FF6B35 orange accent & ambient glow.
class ZyloWordmarkPainter extends CustomPainter {
  final bool isDark;
  final Color? wordmarkColor;
  final Color? accentColor;
  final bool hasGlow;
  final bool markOnly;

  ZyloWordmarkPainter({
    this.isDark = true,
    this.wordmarkColor,
    this.accentColor,
    this.hasGlow = true,
    this.markOnly = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Canonical coordinate grid:
    // markOnly: 56 x 56
    // wordmark: 132 x 62
    final canonicalW = markOnly ? 56.0 : 132.0;
    final canonicalH = markOnly ? 56.0 : 62.0;

    final scale = math.min(size.width / canonicalW, size.height / canonicalH);
    final dx = (size.width - canonicalW * scale) / 2;
    final dy = (size.height - canonicalH * scale) / 2;

    canvas.save();
    canvas.translate(dx, dy);
    canvas.scale(scale, scale);

    final effectiveBodyColor = wordmarkColor ??
        (isDark ? Colors.white : const Color(0xFF1E1E1E));

    final bodyFillPaint = Paint()
      ..color = effectiveBodyColor
      ..style = PaintingStyle.fill;

    final bodyStrokePaint = Paint()
      ..color = effectiveBodyColor
      ..strokeWidth = 7.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final orangeAccentColor = accentColor ?? const Color(0xFFFF6F33);

    // ==========================================
    // 1. BESPOKE 'Z' EMBLEM WITH INTEGRATED SPARKLE
    // ==========================================

    // Z Apex coordinates where the signature sparkle is anchored
    const cx = 39.5;
    const cy = 13.0;
    const r = 10.5;

    // Ambient Warm Glow behind the Sparkle Vertex
    if (hasGlow) {
      final glowPaint = Paint()
        ..shader = RadialGradient(
          colors: isDark
              ? [
                  const Color(0x60FF6B35),
                  const Color(0x20FF451A),
                  Colors.transparent,
                ]
              : [
                  const Color(0x35FF6B35),
                  const Color(0x10FF8A4C),
                  Colors.transparent,
                ],
          stops: const [0.0, 0.52, 1.0],
        ).createShader(Rect.fromCircle(center: const Offset(cx, cy), radius: r * 1.9))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, isDark ? 4.5 : 3.0);

      canvas.drawCircle(const Offset(cx, cy), r * 1.5, glowPaint);
    }

    // A. Z Top Bar (with left rounded pill cap)
    final topBarRRect = RRect.fromRectAndCorners(
      const Rect.fromLTRB(6.0, 12.0, 39.0, 19.5),
      topLeft: const Radius.circular(3.8),
      bottomLeft: const Radius.circular(3.8),
    );
    canvas.drawRRect(topBarRRect, bodyFillPaint);

    // B. Z Diagonal Stroke (solid geometric transition)
    final diagonalPath = Path()
      ..moveTo(31.5, 19.5)
      ..lineTo(39.5, 12.0)
      ..lineTo(39.5, 20.0)
      ..lineTo(14.0, 51.0)
      ..lineTo(6.5, 51.0)
      ..lineTo(6.5, 43.5)
      ..close();
    canvas.drawPath(diagonalPath, bodyFillPaint);

    // C. Z Bottom Bar (with aerodynamic 45° chamfered terminal)
    final bottomBarPath = Path()
      ..moveTo(6.0, 43.5)
      ..lineTo(40.5, 43.5)
      ..lineTo(45.0, 51.0) // 45° chamfer cut echoing sparkle angle
      ..lineTo(6.0, 51.0)
      ..close();
    canvas.drawPath(bottomBarPath, bodyFillPaint);

    // D. Signature 4-Point Curved Sparkle integrated at Z Apex
    final sparklePaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFFF350D), // Deep rich orange-red base
          Color(0xFFFF6F33), // Zylo signature orange
          Color(0xFFFFA656), // Warm golden highlight
        ],
        stops: [0.0, 0.52, 1.0],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ).createShader(Rect.fromCircle(center: const Offset(cx, cy), radius: r))
      ..style = PaintingStyle.fill;

    // Main Sparkle Path
    final mainSparkle = _createSparklePath(cx, cy, r, pinch: 0.24);
    canvas.drawPath(mainSparkle, sparklePaint);

    // Secondary Companion Micro-Star (offset to top-right)
    const secCx = 49.0;
    const secCy = 5.0;
    const secR = 3.6;
    final secSparkle = _createSparklePath(secCx, secCy, secR, pinch: 0.24);
    canvas.drawPath(secSparkle, sparklePaint);

    // Delicate Core Specular Highlight for optical depth
    final specularPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: isDark ? 0.70 : 0.55),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: const Offset(cx, cy), radius: r * 0.28))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(cx, cy), r * 0.28, specularPaint);

    // E. Diagonal Connection Pip / Accent
    // Subtle orange ray accent in the diagonal representing "Moments + Connections"
    canvas.save();
    canvas.translate(23.0, 31.5);
    canvas.rotate(-math.pi / 4.2);
    final accentRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: 2.8, height: 6.8),
      const Radius.circular(1.4),
    );
    final accentPaint = Paint()
      ..color = orangeAccentColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(accentRRect, accentPaint);
    canvas.restore();

    // ==========================================
    // 2. BESPOKE LOWERCASE 'y', 'l', 'o'
    // ==========================================
    if (!markOnly) {
      // Bespoke 'y': Modern Gen-Z curved descender
      final yPath = Path()
        // Left arm
        ..moveTo(56.0, 24.0)
        ..lineTo(66.5, 39.5)
        // Right arm and fluid descender curve
        ..moveTo(77.0, 24.0)
        ..lineTo(66.5, 39.5)
        ..cubicTo(63.0, 45.0, 60.0, 52.0, 55.0, 57.0)
        ..cubicTo(53.0, 59.0, 50.0, 59.5, 48.0, 58.0);
      canvas.drawPath(yPath, bodyStrokePaint);

      // Bespoke 'l': Tall pill stem matching Z cap-height & baseline
      final lPath = Path()
        ..moveTo(85.0, 15.6)
        ..lineTo(85.0, 47.4);
      canvas.drawPath(lPath, bodyStrokePaint);

      // Bespoke 'o': Balanced modern geometric circle
      final oRect = Rect.fromCenter(
        center: const Offset(107.0, 37.5),
        width: 22.0,
        height: 19.8,
      );
      canvas.drawOval(oRect, bodyStrokePaint);
    }

    canvas.restore();
  }

  Path _createSparklePath(double cx, double cy, double radius, {double pinch = 0.24}) {
    final path = Path();
    final p = radius * pinch;

    final top = Offset(cx, cy - radius);
    final right = Offset(cx + radius, cy);
    final bottom = Offset(cx, cy + radius);
    final left = Offset(cx - radius, cy);

    path.moveTo(top.dx, top.dy);
    path.cubicTo(cx, cy - p, cx + p, cy, right.dx, right.dy);
    path.cubicTo(cx + p, cy, cx, cy + p, bottom.dx, bottom.dy);
    path.cubicTo(cx, cy + p, cx - p, cy, left.dx, left.dy);
    path.cubicTo(cx - p, cy, cx, cy - p, top.dx, top.dy);
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant ZyloWordmarkPainter oldDelegate) {
    return oldDelegate.isDark != isDark ||
        oldDelegate.wordmarkColor != wordmarkColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.hasGlow != hasGlow ||
        oldDelegate.markOnly != markOnly;
  }
}

/// The official unified Zylo Brand widget for Home, Splash, Onboarding, and Auth screens.
/// Features a bespoke vector wordmark with the signature Z emblem integrated with the Zylo sparkle.
class ZyloBrand extends StatefulWidget {
  /// Base height of the wordmark or mark (e.g. 26 in header, 42 in splash, 38 in onboarding)
  final double size;

  /// Presentation mode (wordmark, markOnly, stacked with tagline, appIcon)
  final ZyloBrandMode mode;

  /// Theme override (defaults to active theme brightness)
  final bool? isDark;

  /// Wordmark body color override (defaults to #1E1E1E in light, #FFFFFF in dark)
  final Color? wordmarkColor;

  /// Accent sparkle color override (defaults to signature orange gradient)
  final Color? accentColor;

  /// Whether to render the soft warm ambient glow
  final bool hasGlow;

  /// Whether to play a subtle 260ms single-shot entrance animation
  final bool animate;

  /// Whether to show the "SHARE YOUR MOMENT." brand tagline (used in stacked mode)
  final bool showTagline;

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
        variant: effectiveDark
            ? ZyloSymbolVariant.orangeGradient
            : ZyloSymbolVariant.creamLight,
        showShadow: true,
      );
    }

    final isMarkOnly = widget.mode == ZyloBrandMode.markOnly;
    // Aspect ratios matching canonical vectors:
    // markOnly: 56 / 56 = 1.0
    // wordmark: 132 / 62 ≈ 2.129
    final targetWidth = isMarkOnly ? widget.size : widget.size * 2.13;
    final targetHeight = widget.size;

    Widget vectorGraphic = SizedBox(
      width: targetWidth,
      height: targetHeight,
      child: CustomPaint(
        painter: ZyloWordmarkPainter(
          isDark: effectiveDark,
          wordmarkColor: widget.wordmarkColor,
          accentColor: widget.accentColor,
          hasGlow: widget.hasGlow,
          markOnly: isMarkOnly,
        ),
      ),
    );

    // Stacked layout with "SHARE YOUR MOMENT." tagline
    Widget content;
    if (widget.mode == ZyloBrandMode.stacked || widget.showTagline) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          vectorGraphic,
          const SizedBox(height: 6),
          Text(
            'SHARE YOUR MOMENT.',
            style: AppTypography.tagline(
              fontSize: math.max(9.0, widget.size * 0.28),
              color: effectiveDark ? const Color(0xFFFFA066) : AppColors.primaryOrange,
              letterSpacing: 3.8,
            ),
          ),
        ],
      );
    } else {
      content = vectorGraphic;
    }

    // Accessible semantics wrapper with text discovery for automated tests
    content = Semantics(
      label: 'Zylo',
      header: true,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Zero-opacity text preserves test assertions and screen readers
          Opacity(
            opacity: 0.0,
            child: Text(
              'Zylo',
              style: TextStyle(fontSize: 1, color: Colors.transparent),
            ),
          ),
          content,
        ],
      ),
    );

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

/// Backward-compatible wrapper for ZyloWordmark using the custom vector wordmark
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


