import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/zylo_background.dart';

final momentNotificationsProvider =
    StateNotifierProvider<MomentSettingsNotifier, bool>((ref) {
  return MomentSettingsNotifier('zylo_moment_notifications');
});

final momentExpiringAlertsProvider =
    StateNotifierProvider<MomentSettingsNotifier, bool>((ref) {
  return MomentSettingsNotifier('zylo_moment_expiring_alerts');
});

class MomentSettingsNotifier extends StateNotifier<bool> {
  final String key;
  MomentSettingsNotifier(this.key) : super(true) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(key) ?? true;
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, state);
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showThemeDialog(BuildContext context, WidgetRef ref) {
    final currentMode = ref.read(themeModeProvider);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Choose Theme'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('System Default'),
              trailing: currentMode == ThemeMode.system
                  ? const Icon(Icons.check_circle, color: AppColors.primaryOrange)
                  : null,
              onTap: () {
                ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('Light (Cream & Orange)'),
              trailing: currentMode == ThemeMode.light
                  ? const Icon(Icons.check_circle, color: AppColors.primaryOrange)
                  : null,
              onTap: () {
                ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('Dark (Deep & Bold)'),
              trailing: currentMode == ThemeMode.dark
                  ? const Icon(Icons.check_circle, color: AppColors.primaryOrange)
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
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out of Zylo?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorRed),
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
    final themeMode = ref.watch(themeModeProvider);
    final momentNotifs = ref.watch(momentNotificationsProvider);
    final momentExpiring = ref.watch(momentExpiringAlertsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final themeLabel = themeMode == ThemeMode.dark
        ? 'Dark'
        : (themeMode == ThemeMode.light ? 'Light' : 'System Default');

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(letterSpacing: -0.2),
        ),
        backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
        elevation: 0,
      ),
      body: ZyloBackground(
        intensity: ZyloBackgroundIntensity.subtle,
        showTopGlow: true,
        child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Section 1: Appearance
          _buildSectionHeader('Appearance'),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                leading: const Icon(Icons.palette_outlined, color: AppColors.primaryOrange),
                title: const Text('Theme'),
                subtitle: Text(themeLabel),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showThemeDialog(context, ref),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Section 2: Moments
          _buildSectionHeader('Moments'),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Text('✨', style: TextStyle(fontSize: 18)),
                    title: const Text('Moment Daily Reminders'),
                    subtitle: const Text('Friendly notice when a friend is waiting'),
                    activeThumbColor: AppColors.primaryOrange,
                    value: momentNotifs,
                    onChanged: (_) =>
                        ref.read(momentNotificationsProvider.notifier).toggle(),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.access_time, color: AppColors.warningAmber),
                    title: const Text('Expiration Alerts'),
                    subtitle: const Text('Notify when a Moment has 3 hours remaining'),
                    activeThumbColor: AppColors.primaryOrange,
                    value: momentExpiring,
                    onChanged: (_) =>
                        ref.read(momentExpiringAlertsProvider.notifier).toggle(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Section 3: Account
          _buildSectionHeader('Account'),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person_outline, color: AppColors.primaryOrange),
                    title: const Text('Edit Profile'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/edit-profile'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Log Out
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.errorRed),
            title: const Text(
              'Log Out',
              style: TextStyle(color: AppColors.errorRed, fontWeight: FontWeight.w600),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppColors.errorRed.withValues(alpha: 0.3)),
            ),
            tileColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            onTap: () => _confirmLogout(context, ref),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 4, 6, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
