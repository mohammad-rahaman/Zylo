import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/moment.dart';

class MomentBadge extends StatelessWidget {
  final int count;
  final bool isExpiringSoon;
  final int? hoursRemaining;
  final double fontSize;
  final double iconSize;
  final EdgeInsetsGeometry padding;

  const MomentBadge({
    super.key,
    required this.count,
    this.isExpiringSoon = false,
    this.hoursRemaining,
    this.fontSize = 12,
    this.iconSize = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
  });

  /// Factory constructor to build directly from a Moment instance
  factory MomentBadge.fromMoment(
    Moment? moment, {
    double fontSize = 12,
    double iconSize = 12,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
  }) {
    if (moment == null || !moment.isActive || moment.currentCount <= 0) {
      return MomentBadge(
        count: 0,
        fontSize: fontSize,
        iconSize: iconSize,
        padding: padding,
      );
    }

    return MomentBadge(
      count: moment.currentCount,
      isExpiringSoon: moment.isExpiringSoon,
      hoursRemaining: moment.hoursRemaining,
      fontSize: fontSize,
      iconSize: iconSize,
      padding: padding,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (count <= 0) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Use warning amber border/background accent if expiring soon, otherwise Zylo orange
    final badgeColor = isExpiringSoon ? AppColors.warningAmber : AppColors.primaryOrange;
    final bgColor = badgeColor.withValues(alpha: isDark ? 0.18 : 0.12);
    final borderColor = badgeColor.withValues(alpha: isDark ? 0.45 : 0.35);

    String label = '$count';
    if (isExpiringSoon && hoursRemaining != null && hoursRemaining! > 0) {
      label = '$count · ${hoursRemaining}h';
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withValues(alpha: isExpiringSoon ? (isDark ? 0.40 : 0.25) : (isDark ? 0.20 : 0.10)),
            blurRadius: isExpiringSoon ? 8 : 4,
            spreadRadius: isExpiringSoon ? 1 : 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '✨',
            style: TextStyle(fontSize: iconSize, height: 1),
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: badgeColor,
              fontWeight: FontWeight.bold,
              fontSize: fontSize,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}
