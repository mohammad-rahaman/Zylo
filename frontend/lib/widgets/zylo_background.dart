import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_shadows.dart';

enum ZyloBackgroundIntensity {
  subtle,
  medium,
  strong,
}

/// Signature ambient background for Zylo with warm cinematic lighting,
/// soft orange ambient glow, faint abstract sparkle/orbit watermark, and depth transitions.
class ZyloBackground extends StatelessWidget {
  final Widget? child;
  final ZyloBackgroundIntensity intensity;
  final bool showTopGlow;
  final bool showBottomGlow;
  final bool showAmbientCanvas;

  const ZyloBackground({
    super.key,
    this.child,
    this.intensity = ZyloBackgroundIntensity.subtle,
    this.showTopGlow = true,
    this.showBottomGlow = false,
    this.showAmbientCanvas = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Intensity opacity factors
    final double glowAlpha;
    final double intensityFactor;
    switch (intensity) {
      case ZyloBackgroundIntensity.subtle:
        glowAlpha = isDark ? 0.07 : 0.05;
        intensityFactor = 1.0;
        break;
      case ZyloBackgroundIntensity.medium:
        glowAlpha = isDark ? 0.12 : 0.09;
        intensityFactor = 1.4;
        break;
      case ZyloBackgroundIntensity.strong:
        glowAlpha = isDark ? 0.20 : 0.15;
        intensityFactor = 1.8;
        break;
    }

    final baseBgColor = isDark ? AppColors.bgDark : AppColors.bgLight;

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Base solid canvas (#121212 dark / #FFF8F3 light)
        Container(color: baseBgColor),

        // 2. Warm ambient top radial gradient
        if (showTopGlow)
          Positioned(
            top: -120,
            right: -60,
            width: 380,
            height: 380,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFF6B35).withValues(alpha: glowAlpha * 1.5),
                      const Color(0xFFFF9B71).withValues(alpha: glowAlpha * 0.8),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),
          ),

        // 3. Warm ambient bottom radial gradient
        if (showBottomGlow)
          Positioned(
            bottom: -100,
            left: -80,
            width: 320,
            height: 320,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFF451A).withValues(alpha: glowAlpha),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
            ),
          ),

        // 4. Subtle ambient celestial orbits & Zylo sparkle watermark (3-8% intensity)
        if (showAmbientCanvas)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: ZyloAmbientCanvasPainter(
                  isDark: isDark,
                  intensityFactor: intensityFactor,
                ),
                isComplex: true,
                willChange: false,
              ),
            ),
          ),

        // 5. Child Screen Content (rendered safely on top)
        if (child != null) child!,
      ],
    );
  }
}

/// Custom painter that renders the signature Oversized Zylo Sparkle watermark
/// and rich ambient peach/orange gradient mesh in the lower screen canvas.
class ZyloAmbientCanvasPainter extends CustomPainter {
  final bool isDark;
  final double intensityFactor;

  ZyloAmbientCanvasPainter({
    required this.isDark,
    this.intensityFactor = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Center and radius of the Oversized Sparkle
    final cx = w * 0.70;
    final cy = h * 0.65;
    final r = w * 0.30; // ~235px full span

    // ==========================================
    // 1. ORGANIC AMBIENT GRADIENT MESH
    // ==========================================

    // Layer A: Broad warm ambient wash across lower-half (organic elliptical gradient)
    final broadCenter = Offset(w * 0.72, h * 0.68);
    final broadRect = Rect.fromCenter(
      center: broadCenter,
      width: w * 1.5,
      height: h * 0.85,
    );
    final broadMeshPaint = Paint()
      ..shader = RadialGradient(
        colors: isDark
            ? [
                const Color(0x38FF6B35), // ~22% warm orange
                const Color(0x22FF451A), // ~13% deep amber
                const Color(0x0CFF8A50), // ~5% soft peach
                Colors.transparent,
              ]
            : [
                const Color(0x32FFA873), // ~20% warm peach
                const Color(0x1EFF7A3D), // ~12% soft coral
                const Color(0x0AFFD4BD), // ~4% light cream-peach
                Colors.transparent,
              ],
        stops: const [0.0, 0.38, 0.72, 1.0],
      ).createShader(broadRect);
    canvas.drawOval(broadRect, broadMeshPaint);

    // Layer B: Concentrated warm peach/orange glow directly around the sparkle
    final focalRect = Rect.fromCircle(center: Offset(cx, cy), radius: r * 1.6);
    final focalMeshPaint = Paint()
      ..shader = RadialGradient(
        colors: isDark
            ? [
                const Color(0x48FF6B35), // ~28% radiant orange
                const Color(0x1EFF451A), // ~12% deep ember
                Colors.transparent,
              ]
            : [
                const Color(0x3CFFA066), // ~24% radiant peach-orange
                const Color(0x16FF7E40), // ~9% soft apricot
                Colors.transparent,
              ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(focalRect);
    canvas.drawCircle(Offset(cx, cy), r * 1.6, focalMeshPaint);

    // Layer C: Soft bottom-right corner ambient fill (smooth corner wash)
    final cornerRect = Rect.fromLTWH(w * 0.20, h * 0.45, w * 0.90, h * 0.60);
    final cornerMeshPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.85, 0.75),
        radius: 0.90,
        colors: isDark
            ? [
                const Color(0x28FF5722),
                const Color(0x14FF7A3D),
                Colors.transparent,
              ]
            : [
                const Color(0x24FFB288),
                const Color(0x0EFF8A50),
                Colors.transparent,
              ],
        stops: const [0.0, 0.50, 1.0],
      ).createShader(cornerRect);
    canvas.drawRect(cornerRect, cornerMeshPaint);

    // ==========================================
    // 2. OVERSIZED ZYLO SPARKLE WATERMARK
    // ==========================================

    // Subtle soft glow blur directly hugging the sparkle silhouette
    final glowPath = _createSparklePath(cx, cy, r * 1.08, pinch: 0.24);
    final auraPaint = Paint()
      ..color = (isDark ? const Color(0x35FF6B35) : const Color(0x28FF7A3D))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22.0);
    canvas.drawPath(glowPath, auraPaint);

    // A. Main Oversized Sparkle - Translucent Solid Gradient Fill
    final sparkleFillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: isDark
            ? [
                const Color(0x38FF350D), // ~22% deep orange
                const Color(0x2EFF6B35), // ~18% signature orange
                const Color(0x22FFA656), // ~13% warm golden highlight
              ]
            : [
                const Color(0x28FF451A), // ~16% vibrant base
                const Color(0x20FF6B35), // ~12% signature orange
                const Color(0x18FFAA70), // ~9% golden peach tip
              ],
        stops: const [0.0, 0.52, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r))
      ..style = PaintingStyle.fill;

    final mainSparklePath = _createSparklePath(cx, cy, r, pinch: 0.24);
    canvas.drawPath(mainSparklePath, sparkleFillPaint);

    // B. Subtle Sparkle Perimeter Contour (soft outer definition)
    final sparkleStrokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..shader = LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: isDark
            ? [
                const Color(0x45FF5722),
                const Color(0x55FF7A3D),
                const Color(0x35FFA656),
              ]
            : [
                const Color(0x35FF6B35),
                const Color(0x40FFA066),
                const Color(0x25FFC299),
              ],
        stops: const [0.0, 0.50, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
    canvas.drawPath(mainSparklePath, sparkleStrokePaint);

    // C. Optical Center Specular Highlight (warm subtle lens core)
    final specularPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          (isDark ? Colors.white : const Color(0xFFFFF0E6)).withValues(alpha: isDark ? 0.35 : 0.25),
          Colors.transparent,
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.32))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), r * 0.32, specularPaint);

    // D. Companion Secondary Sparkle (anchored to upper-right)
    final secCx = cx + r * 0.70;
    final secCy = cy - r * 0.56;
    final secR = r * 0.34;

    final secSparklePath = _createSparklePath(secCx, secCy, secR, pinch: 0.24);

    final secFillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: isDark
            ? [
                const Color(0x30FF451A),
                const Color(0x28FF6B35),
                const Color(0x1EFFA656),
              ]
            : [
                const Color(0x22FF5722),
                const Color(0x1CFF6B35),
                const Color(0x14FFAA70),
              ],
        stops: const [0.0, 0.52, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(secCx, secCy), radius: secR))
      ..style = PaintingStyle.fill;
    canvas.drawPath(secSparklePath, secFillPaint);

    final secStrokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = (isDark ? const Color(0x45FF7A3D) : const Color(0x30FF6B35));
    canvas.drawPath(secSparklePath, secStrokePaint);
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
  bool shouldRepaint(covariant ZyloAmbientCanvasPainter oldDelegate) {
    return oldDelegate.isDark != isDark || oldDelegate.intensityFactor != intensityFactor;
  }
}



/// Standard Zylo Glass / Elevated Surface
class ZyloSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final bool enableGlow;
  final VoidCallback? onTap;

  const ZyloSurface({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.enableGlow = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? AppRadius.cardBorder;

    final boxDecoration = BoxDecoration(
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      borderRadius: radius,
      border: Border.all(
        color: isDark ? AppColors.borderDark : AppColors.borderLight,
        width: 1,
      ),
      boxShadow: [
        if (enableGlow)
          AppShadows.orangeGlow
        else if (isDark)
          AppShadows.cardDark
        else
          AppShadows.cardLight,
      ],
    );

    if (onTap != null) {
      return Container(
        margin: margin,
        decoration: boxDecoration,
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: Padding(
              padding: padding ?? const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ),
      );
    }

    return Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: boxDecoration,
      child: child,
    );
  }
}
