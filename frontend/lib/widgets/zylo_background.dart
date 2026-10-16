import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_shadows.dart';

enum ZyloBackgroundIntensity {
  subtle,
  medium,
  strong,
}

/// Signature ambient background for Zylo: a quiet paper/graphite canvas with
/// a barely-there warm wash and a fine-line orbit motif.
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

    final double washAlpha;
    final double intensityFactor;
    switch (intensity) {
      case ZyloBackgroundIntensity.subtle:
        washAlpha = isDark ? 0.05 : 0.035;
        intensityFactor = 1.0;
        break;
      case ZyloBackgroundIntensity.medium:
        washAlpha = isDark ? 0.07 : 0.05;
        intensityFactor = 1.3;
        break;
      case ZyloBackgroundIntensity.strong:
        washAlpha = isDark ? 0.09 : 0.065;
        intensityFactor = 1.6;
        break;
    }

    final baseBgColor = isDark ? AppColors.bgDark : AppColors.bgLight;
    // A whisper of vertical light: the top of the canvas is marginally brighter.
    final topBgColor = Color.lerp(baseBgColor, Colors.white, isDark ? 0.025 : 0.45)!;

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Base canvas with a soft vertical tone shift
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [topBgColor, baseBgColor],
              stops: const [0.0, 0.6],
            ),
          ),
        ),

        // 2. Faint warm wash, top-right
        if (showTopGlow)
          Positioned(
            top: -160,
            right: -120,
            width: 420,
            height: 420,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primaryOrange.withValues(alpha: washAlpha),
                      AppColors.primaryOrange.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // 3. Faint warm wash, bottom-left
        if (showBottomGlow)
          Positioned(
            bottom: -140,
            left: -120,
            width: 360,
            height: 360,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primaryOrange.withValues(alpha: washAlpha * 0.8),
                      AppColors.primaryOrange.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // 4. Fine-line sparkle & orbit motif
        if (showAmbientCanvas)
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: ZyloAmbientCanvasPainter(
                    isDark: isDark,
                    intensityFactor: intensityFactor,
                  ),
                ),
              ),
            ),
          ),

        // 5. Child Screen Content (rendered safely on top)
        if (child != null) child!,
      ],
    );
  }
}

/// Paints the quiet brand motif in the lower-right of the canvas: two tilted
/// hairline orbits (echoing the Orbit Z mark) with a single ember moment dot.
class ZyloAmbientCanvasPainter extends CustomPainter {
  final bool isDark;
  final double intensityFactor;

  ZyloAmbientCanvasPainter({
    required this.isDark,
    this.intensityFactor = 1.0,
  });

  double _a(double base) => (base * intensityFactor).clamp(0.0, 1.0);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final center = Offset(w * 0.80, h * 0.72);
    final r = w * 0.30;

    // 1. Soft warm pool that anchors the motif
    final poolRadius = r * 2.2;
    final poolPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.primaryOrange.withValues(alpha: _a(isDark ? 0.045 : 0.03)),
          AppColors.primaryOrange.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: poolRadius));
    canvas.drawCircle(center, poolRadius, poolPaint);

    // 2. Tilted hairline orbits that echo the Orbit Z mark
    const tilt = -24 * math.pi / 180;
    final ink = isDark ? Colors.white : AppColors.textPrimaryLight;
    final accent = isDark ? AppColors.emberLight : AppColors.primaryOrange;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(tilt);

    final outerOrbit = Rect.fromCenter(center: Offset.zero, width: r * 4.4, height: r * 1.6);
    final innerOrbit = Rect.fromCenter(center: Offset.zero, width: r * 3.0, height: r * 1.1);
    canvas.drawOval(
      outerOrbit,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = ink.withValues(alpha: _a(isDark ? 0.06 : 0.07)),
    );
    canvas.drawOval(
      innerOrbit,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..color = accent.withValues(alpha: _a(isDark ? 0.22 : 0.16)),
    );

    // 3. The moment dot riding the inner orbit
    const phase = -2.2;
    final dot = Offset(
      innerOrbit.width / 2 * math.cos(phase),
      innerOrbit.height / 2 * math.sin(phase),
    );
    canvas.drawCircle(dot, 2.6, Paint()..color = accent.withValues(alpha: _a(isDark ? 0.6 : 0.5)));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ZyloAmbientCanvasPainter oldDelegate) {
    return oldDelegate.isDark != isDark || oldDelegate.intensityFactor != intensityFactor;
  }
}

/// Standard Zylo elevated surface: clean card, hairline border, soft lift.
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
