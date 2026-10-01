import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/zylo_brand.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.75, curve: Curves.easeOutCubic),
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeInOut),
      ),
    );

    _animController.forward();
    _checkRedirect();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _checkRedirect() async {
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    final authState = ref.read(authProvider);
    if (authState.status == AuthStatus.authenticated) {
      context.go('/home');
    } else {
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Stack(
        children: [
          // 1. Subtle warm ambient radial background glow
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return Positioned(
                top: size.height * 0.30,
                left: size.width * 0.5 - 140,
                child: Opacity(
                  opacity: _glowAnimation.value * 0.45,
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.primaryOrange.withValues(alpha: 0.5),
                          AppColors.primaryGradientStart.withValues(alpha: 0.2),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // 2. Central Brand Identity
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Zylo Signature Sparkle Symbol
                    const ZyloSymbol(
                      size: 92,
                      variant: ZyloSymbolVariant.orangeGradient,
                      hasGlow: true,
                    ),
                    const SizedBox(height: 24),

                    // Bespoke "Zylo" Vector Wordmark
                    const ZyloBrand(
                      size: 42,
                      isDark: true,
                      hasGlow: false,
                    ),
                    const SizedBox(height: 12),

                    // Brand Tagline
                    Text(
                      'SHARE YOUR MOMENT.',
                      style: AppTypography.tagline(
                        fontSize: 12,
                        color: const Color(0xFFFFA066),
                        letterSpacing: 4.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Cinematic Bottom Accent
          Positioned(
            bottom: 48,
            left: 48,
            right: 48,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Sleek minimal progress capsule with orange-amber gradient
                  Container(
                    height: 3,
                    width: 140,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        height: 3,
                        width: 90,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          gradient: AppColors.primaryGradient,
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x80FF6B35),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Good moments, better connections.',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 13,
                      color: AppColors.primaryOrange.withValues(alpha: 0.8),
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
