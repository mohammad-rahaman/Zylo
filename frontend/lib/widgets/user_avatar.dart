import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

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

  Color _generateColor(String text) {
    // Refined, warm social palette matching Zylo's identity
    final colors = [
      const Color(0xFFE05338), // Warm Terracotta
      const Color(0xFFDE7A22), // Golden Amber
      const Color(0xFF9E4770), // Dusty Plum
      const Color(0xFF2E6F7E), // Deep Cyan/Teal
      const Color(0xFF635694), // Warm Indigo
      const Color(0xFFC76C47), // Burnt Clay
      const Color(0xFF387D70), // Sage Slate
    ];
    int hash = 0;
    for (int i = 0; i < text.length; i++) {
      hash = text.codeUnitAt(i) + ((hash << 5) - hash);
    }
    return colors[hash.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: radius * 2,
          height: radius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: hasGlow
                  ? AppColors.primaryOrange
                  : (isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0x2050280A)),
              width: hasGlow ? 2.0 : 1.2,
            ),
            boxShadow: hasGlow
                ? [
                    BoxShadow(
                      color: AppColors.primaryOrange.withValues(alpha: 0.35),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: ClipOval(
            child: imageUrl != null && imageUrl!.isNotEmpty
                ? Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    width: radius * 2,
                    height: radius * 2,
                    errorBuilder: (_, __, ___) => _buildInitials(),
                  )
                : _buildInitials(),
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
                boxShadow: [
                  BoxShadow(
                    color: AppColors.onlineGreen.withValues(alpha: 0.45),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInitials() {
    return Container(
      color: _generateColor(name),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: radius * 0.75,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}
