import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// The single primary action button used across Zylo.
///
/// Styling comes from `elevatedButtonTheme` in AppTheme (ember outline over a
/// faint ember wash); this widget only adds the bits every call site repeated:
/// full width, a loading state, and optional leading/trailing icons.
class ZyloPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final IconData? trailingIcon;
  final double height;
  final bool expand;

  const ZyloPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.trailingIcon,
    this.height = 52,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.emberLight : AppColors.primaryOrange;

    final Widget content = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: accent),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: accent),
                const SizedBox(width: 8),
              ],
              Text(label),
              if (trailingIcon != null) ...[
                const SizedBox(width: 10),
                Icon(trailingIcon, size: 18, color: accent),
              ],
            ],
          );

    return SizedBox(
      width: expand ? double.infinity : null,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        child: content,
      ),
    );
  }
}

/// Circular icon action in the same ember-outline language (camera, send, etc.).
class ZyloCircleAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final bool active;

  const ZyloCircleAction({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 44,
    this.iconSize = 20,
    this.active = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.emberLight : AppColors.primaryOrange;
    final muted = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Material(
      color: active
          ? accent.withValues(alpha: isDark ? 0.14 : 0.10)
          : (isDark ? AppColors.surfaceSubduedDark : AppColors.surfaceSubduedLight),
      shape: CircleBorder(
        side: BorderSide(
          color: active
              ? accent.withValues(alpha: 0.85)
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: iconSize, color: active ? accent : muted),
        ),
      ),
    );
  }
}
