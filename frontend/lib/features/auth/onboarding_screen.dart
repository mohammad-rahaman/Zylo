import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../widgets/zylo_brand.dart';
import '../../widgets/zylo_button.dart';

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
                    AppColors.primaryOrange.withValues(alpha: isDark ? 0.14 : 0.07),
                    AppColors.primaryOrange.withValues(alpha: isDark ? 0.05 : 0.025),
                    AppColors.primaryOrange.withValues(alpha: 0.0),
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
                  showMark: false, // the hero tile below carries the mark
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
                        ZyloPrimaryButton(
                          label: 'Get Started',
                          trailingIcon: Icons.arrow_forward_rounded,
                          height: 56,
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            context.go('/register');
                          },
                        ),
                        const SizedBox(height: 12),

                        // Secondary CTA: quiet text action
                        SizedBox(
                          height: 50,
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              context.go('/login');
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            ),
                            child: const Text('Log In'),
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
