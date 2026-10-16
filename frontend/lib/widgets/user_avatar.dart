import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';

class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double radius;
  final bool showOnlineStatus;
  final bool isOnline;
  final bool hasGlow;

  const UserAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.radius = 24,
    this.showOnlineStatus = false,
    this.isOnline = false,
    this.hasGlow = false,
  });

  String get _initials {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.trim().substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.emberLight : AppColors.primaryOrange;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: radius * 2,
          height: radius * 2,
          // Active moment: a fine ember ring with a small gap around the photo.
          padding: hasGlow ? const EdgeInsets.all(2.5) : null,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: hasGlow ? accent : (isDark ? AppColors.borderDark : AppColors.borderLight),
              width: hasGlow ? 1.5 : 1.0,
            ),
          ),
          child: ClipOval(
            child: imageUrl != null && imageUrl!.isNotEmpty
                ? Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    width: radius * 2,
                    height: radius * 2,
                    errorBuilder: (_, __, ___) => _buildInitials(isDark),
                  )
                : _buildInitials(isDark),
          ),
        ),
        if (showOnlineStatus && isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: radius * 0.58,
              height: radius * 0.58,
              decoration: BoxDecoration(
                color: AppColors.onlineGreen,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  width: 2.0,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInitials(bool isDark) {
    // Neutral stone/graphite with serif initials — the accent is saved for moment rings.
    return Container(
      color: isDark ? AppColors.surfaceSubduedDark : const Color(0xFFE9E5DE),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: AppTypography.serifTitle(fontSize: radius * 0.9, isDark: isDark).copyWith(height: 1.0),
      ),
    );
  }
}
