import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../providers/auth_provider.dart';
import '../../providers/moment_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/zylo_background.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showThemeSelector(BuildContext context, WidgetRef ref) {
    final currentMode = ref.read(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Container(
            color: isDark ? const Color(0xFF191513) : const Color(0xFFFFF8F3),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Appearance',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.brightness_auto_outlined, color: AppColors.primaryOrange),
                  title: const Text('System Default'),
                  trailing: currentMode == ThemeMode.system
                      ? const Icon(Icons.check_circle_rounded, color: AppColors.primaryOrange)
                      : null,
                  onTap: () {
                    ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system);
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.wb_sunny_outlined, color: AppColors.primaryOrange),
                  title: const Text('Light Mode (Warm Cream)'),
                  trailing: currentMode == ThemeMode.light
                      ? const Icon(Icons.check_circle_rounded, color: AppColors.primaryOrange)
                      : null,
                  onTap: () {
                    ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light);
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.nightlight_outlined, color: AppColors.primaryOrange),
                  title: const Text('Dark Mode (Deep Cinematic)'),
                  trailing: currentMode == ThemeMode.dark
                      ? const Icon(Icons.check_circle_rounded, color: AppColors.primaryOrange)
                      : null,
                  onTap: () {
                    ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out of Zylo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(authProvider.notifier).logout();
      if (context.mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final momentsState = ref.watch(momentsProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final themeLabel = themeMode == ThemeMode.light
        ? 'Light'
        : (themeMode == ThemeMode.dark ? 'Dark' : 'System Default');

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ZyloBackground(
        intensity: ZyloBackgroundIntensity.subtle,
        showTopGlow: true,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // Header
              const Text(
                'Profile',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.6),
              ),
              const SizedBox(height: 20),

              // Profile Social Hero Card with Ambient Glow
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1B1715) : const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: isDark ? const Color(0x35FF6B35) : const Color(0x1850280A),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6B35).withValues(alpha: isDark ? 0.08 : 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Avatar with glowing ring
                    UserAvatar(
                      imageUrl: user?.profilePhoto,
                      name: user?.displayName ?? 'User',
                      radius: 46,
                      hasGlow: true,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user?.displayName ?? 'Zylo User',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.3),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@${user?.username ?? 'username'}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    if (user?.bio != null && user!.bio.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        user.bio,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          height: 1.3,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Connection / Moments summary badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryOrange.withValues(alpha: isDark ? 0.16 : 0.10),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primaryOrange.withValues(alpha: isDark ? 0.35 : 0.25),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('✨', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          Text(
                            '${momentsState.moments.length} Active Moments',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryOrange,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Edit Profile Button
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF26201E) : const Color(0xFFF7ECE4),
                        borderRadius: AppRadius.pillBorder,
                        border: Border.all(
                          color: AppColors.primaryOrange.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: AppRadius.pillBorder,
                        child: InkWell(
                          borderRadius: AppRadius.pillBorder,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            context.push('/edit-profile');
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.edit_outlined, size: 16, color: AppColors.primaryOrange),
                                SizedBox(width: 8),
                                Text(
                                  'Edit Profile',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryOrange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const Text(
                'Settings & Preferences',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: -0.2),
              ),
              const SizedBox(height: 12),

              // Grouped Settings Card
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1B1715) : const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(22),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryOrange.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.palette_outlined, color: AppColors.primaryOrange, size: 20),
                        ),
                        title: const Text('Appearance', style: TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(themeLabel, style: const TextStyle(fontSize: 12)),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => _showThemeSelector(context, ref),
                      ),
                      Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.borderLight),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDE7A22).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.settings_outlined, color: Color(0xFFDE7A22), size: 20),
                        ),
                        title: const Text('Account & Privacy', style: TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: const Text('Notifications, security, blocked users', style: TextStyle(fontSize: 12)),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => context.push('/settings'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Log Out Button
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1B1715) : const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.errorRed.withValues(alpha: 0.35),
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.errorRed.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.logout_rounded, color: AppColors.errorRed, size: 20),
                    ),
                    title: const Text(
                      'Log Out',
                      style: TextStyle(color: AppColors.errorRed, fontWeight: FontWeight.w700),
                    ),
                    onTap: () => _confirmLogout(context, ref),
                  ),
                ),
              ),

              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }
}
