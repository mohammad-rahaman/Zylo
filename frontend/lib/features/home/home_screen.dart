import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../chat/chat_list_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  bool _isCameraPressed = false;

  final List<Widget> _screens = const [
    ChatListScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.04),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 1. Chats Tab
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _currentIndex = 0);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: _currentIndex == 0
                                  ? (isDark ? AppColors.emberLight : AppColors.primaryOrange).withValues(alpha: isDark ? 0.10 : 0.08)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              _currentIndex == 0
                                  ? Icons.chat_bubble_rounded
                                  : Icons.chat_bubble_outline_rounded,
                              color: _currentIndex == 0
                                  ? (isDark ? AppColors.emberLight : AppColors.primaryOrange)
                                  : (isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight),
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Chats',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight:
                                  _currentIndex == 0 ? FontWeight.w600 : FontWeight.w500,
                              color: _currentIndex == 0
                                  ? (isDark ? AppColors.emberLight : AppColors.primaryOrange)
                                  : (isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 2. Hero Center Camera Action Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: GestureDetector(
                    onTapDown: (_) => setState(() => _isCameraPressed = true),
                    onTapUp: (_) {
                      setState(() => _isCameraPressed = false);
                      HapticFeedback.lightImpact();
                      context.push('/camera');
                    },
                    onTapCancel: () => setState(() => _isCameraPressed = false),
                    child: AnimatedScale(
                      scale: _isCameraPressed ? 0.90 : 1.0,
                      duration: const Duration(milliseconds: 140),
                      curve: Curves.easeOutCubic,
                      child: Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (isDark ? AppColors.emberLight : AppColors.primaryOrange)
                              .withValues(alpha: isDark ? 0.14 : 0.10),
                          border: Border.all(
                            color: (isDark ? AppColors.emberLight : AppColors.primaryOrange)
                                .withValues(alpha: 0.85),
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.camera_alt_outlined,
                            color: isDark ? AppColors.emberLight : AppColors.primaryOrange,
                            size: 27,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // 3. Profile Tab
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _currentIndex = 1);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: _currentIndex == 1
                                  ? (isDark ? AppColors.emberLight : AppColors.primaryOrange).withValues(alpha: isDark ? 0.10 : 0.08)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              _currentIndex == 1
                                  ? Icons.person_rounded
                                  : Icons.person_outline_rounded,
                              color: _currentIndex == 1
                                  ? (isDark ? AppColors.emberLight : AppColors.primaryOrange)
                                  : (isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight),
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Profile',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight:
                                  _currentIndex == 1 ? FontWeight.w600 : FontWeight.w500,
                              color: _currentIndex == 1
                                  ? (isDark ? AppColors.emberLight : AppColors.primaryOrange)
                                  : (isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
