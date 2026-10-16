import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_shadows.dart';
import 'zylo_brand.dart';
import 'zylo_button.dart';

/// Signature Zylo Empty State Component
class ZyloEmptyState extends StatelessWidget {
  final String title;
  final String message;
  final IconData? icon;
  final bool showSparkle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const ZyloEmptyState({
    super.key,
    required this.title,
    String? message,
    String? subtitle,
    this.icon,
    this.showSparkle = true,
    this.actionLabel,
    this.onAction,
  }) : message = subtitle ?? message ?? '';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Glowing visual graphic
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryOrange.withValues(alpha: isDark ? 0.12 : 0.08),
                    AppColors.primaryOrange.withValues(alpha: isDark ? 0.03 : 0.02),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: AppColors.primaryOrange.withValues(alpha: isDark ? 0.22 : 0.16),
                  width: 1,
                ),
                boxShadow: const [AppShadows.orangeGlow],
              ),
              child: Center(
                child: showSparkle
                    ? const ZyloSymbol(size: 38, hasGlow: true)
                    : Icon(
                        icon ?? Icons.chat_bubble_outline_rounded,
                        size: 38,
                        color: AppColors.primaryOrange,
                      ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                height: 1.4,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ZyloPrimaryButton(
                label: actionLabel!,
                onPressed: onAction,
                icon: Icons.add_rounded,
                height: 46,
                expand: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Zylo Pulsing Sparkle Loading Indicator
class ZyloLoadingIndicator extends StatefulWidget {
  final double size;
  const ZyloLoadingIndicator({super.key, this.size = 36});

  @override
  State<ZyloLoadingIndicator> createState() => _ZyloLoadingIndicatorState();
}

class _ZyloLoadingIndicatorState extends State<ZyloLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // One full lap of the moment dot around the orbit.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final lap = Curves.easeInOut.transform(_controller.value) * 2 * math.pi;
          return ZyloSymbol(
            size: widget.size,
            hasGlow: true,
            phase: ZyloMarkPainter.restingPhase + lap,
          );
        },
      ),
    );
  }
}

/// Branded Zylo Search Bar with subtle focus glow
class ZyloSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final String hintText;

  const ZyloSearchBar({
    super.key,
    required this.controller,
    this.onChanged,
    this.onClear,
    this.hintText = 'Search...',
  });

  @override
  State<ZyloSearchBar> createState() => _ZyloSearchBarState();
}

class _ZyloSearchBarState extends State<ZyloSearchBar> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 48,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isFocused
              ? (isDark ? AppColors.emberLight : AppColors.primaryOrange).withValues(alpha: 0.8)
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        onChanged: widget.onChanged,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 20,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
          suffixIcon: widget.controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () {
                    widget.controller.clear();
                    widget.onClear?.call();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }
}
