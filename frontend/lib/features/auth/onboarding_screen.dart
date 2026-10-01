import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../widgets/zylo_brand.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: Stack(
        children: [
          // 1. Warm Ambient Lighting Bloom in Background
          Positioned(
            top: size.height * 0.15,
            left: size.width * 0.5 - 160,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primaryOrange.withValues(alpha: isDark ? 0.35 : 0.20),
                    AppColors.secondaryOrange.withValues(alpha: isDark ? 0.15 : 0.08),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // 2. Main Content Layout
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 32),

                // Brand Header: Bespoke "Zylo" + "SHARE YOUR MOMENT."
                ZyloBrand(
                  size: 38,
                  mode: ZyloBrandMode.stacked,
                  isDark: isDark,
                ),

                const Spacer(),

                // Center Cinematic Hero Visual: Glowing Zylo App Icon Tile
                Center(
                  child: Hero(
                    tag: 'zylo_hero_symbol',
                    child: ZyloAppIconTile(
                      size: 130,
                      variant: isDark
                          ? ZyloSymbolVariant.orangeGradient
                          : ZyloSymbolVariant.creamLight,
                      showShadow: true,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Inspiring Sub-headline
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Moments captured. Connections kept alive.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                      height: 1.4,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),

                const Spacer(),

                // Bottom Floating Action Card
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        width: 1.2,
                      ),
                      boxShadow: [
                        isDark ? AppShadows.cardDark : AppShadows.cardLight,
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Primary CTA: "Get Started →" (large pill with circular arrow)
                        InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            context.go('/register');
                          },
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              gradient: AppColors.primaryGradient,
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x55FF6B35),
                                  blurRadius: 16,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const SizedBox(width: 32), // balance arrow pill
                                const Text(
                                  'Get Started',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.arrow_forward_rounded,
                                    color: AppColors.primaryOrange,
                                    size: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Secondary CTA: Surface "Log In" Pill
                        InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () {
                            HapticFeedback.lightImpact();
                            context.go('/login');
                          },
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.surfaceSubduedDark
                                  : AppColors.surfaceSubduedLight,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Log In',
                              style: TextStyle(
                                color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
