import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import 'camera_filters.dart';
import 'camera_send_screen.dart';

class CameraPreviewScreen extends StatefulWidget {
  final String imagePath;
  final ZyloFilterType initialFilter;
  final bool isFrontCamera;

  final List<String>? initialRecipientIds;

  const CameraPreviewScreen({
    super.key,
    required this.imagePath,
    this.initialFilter = ZyloFilterType.normal,
    this.isFrontCamera = false,
    this.initialRecipientIds,
  });

  @override
  State<CameraPreviewScreen> createState() => _CameraPreviewScreenState();
}

class _CameraPreviewScreenState extends State<CameraPreviewScreen> {
  late ZyloFilterType _currentFilter;
  late bool _isFlipped;

  @override
  void initState() {
    super.initState();
    _currentFilter = widget.initialFilter;
    _isFlipped = widget.isFrontCamera;
  }

  void _onNext() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CameraSendScreen(
          imagePath: widget.imagePath,
          filter: _currentFilter,
          isFlipped: _isFlipped,
          initialRecipientIds: widget.initialRecipientIds,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorFilter = _currentFilter.colorFilter;

    Widget imageWidget = Image.file(
      File(widget.imagePath),
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );

    if (_isFlipped) {
      imageWidget = Transform.flip(
        flipX: true,
        child: imageWidget,
      );
    }

    if (colorFilter != null) {
      imageWidget = ColorFiltered(
        colorFilter: colorFilter,
        child: imageWidget,
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Dominant Filtered Image
          Center(child: imageWidget),

          // 2. Cinematic Top Vignette Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black87, Colors.transparent],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back Button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24, width: 1),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),

                    // Top Mode Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('✨', style: TextStyle(fontSize: 13)),
                          SizedBox(width: 5),
                          Text(
                            'MOMENT PREVIEW',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 44), // Balances back button
                  ],
                ),
              ),
            ),
          ),

          // 3. Cinematic Bottom Controls & Visual Filter Thumbnails
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.only(bottom: 32, top: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black87, Colors.black],
                  stops: [0.0, 0.45, 1.0],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Rich Visual Thumbnail Filters Carousel
                  SizedBox(
                    height: 86,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: ZyloFilterType.values.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final filter = ZyloFilterType.values[index];
                        final isSelected = filter == _currentFilter;

                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _currentFilter = filter);
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Visual Filter Image Thumbnail
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primaryOrange
                                        : Colors.white30,
                                    width: isSelected ? 2.5 : 1.2,
                                  ),
                                  boxShadow: isSelected
                                      ? const [AppShadows.orangeGlow]
                                      : null,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      // Scaled & filtered miniature
                                      Transform.flip(
                                        flipX: _isFlipped,
                                        child: filter.colorFilter != null
                                            ? ColorFiltered(
                                                colorFilter: filter.colorFilter!,
                                                child: Image.file(
                                                  File(widget.imagePath),
                                                  fit: BoxFit.cover,
                                                ),
                                              )
                                            : Image.file(
                                                File(widget.imagePath),
                                                fit: BoxFit.cover,
                                              ),
                                      ),
                                      // Subtle dark overlay with emoji
                                      Container(
                                        alignment: Alignment.bottomRight,
                                        padding: const EdgeInsets.all(2),
                                        child: Text(
                                          filter.icon,
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                filter.displayName,
                                style: TextStyle(
                                  color: isSelected
                                      ? AppColors.primaryOrange
                                      : Colors.white70,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Bottom Action Buttons: Retake vs Next ➔
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        // Retake
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: AppRadius.pillBorder,
                              border: Border.all(color: Colors.white24, width: 1),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: AppRadius.pillBorder,
                              child: InkWell(
                                borderRadius: AppRadius.pillBorder,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  Navigator.of(context).pop();
                                },
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.replay_rounded, size: 18, color: Colors.white),
                                      SizedBox(width: 8),
                                      Text(
                                        'Retake',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 14),

                        // Next ➔ Recipient Selection with glowing orange gradient pill
                        Expanded(
                          flex: 2,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.emberLight.withValues(alpha: 0.16),
                              borderRadius: AppRadius.pillBorder,
                              border: Border.all(color: AppColors.emberLight.withValues(alpha: 0.9)),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: AppRadius.pillBorder,
                              child: InkWell(
                                borderRadius: AppRadius.pillBorder,
                                onTap: _onNext,
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Next',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
