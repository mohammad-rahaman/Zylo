import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/zylo_brand.dart';
import 'camera_filters.dart';
import 'camera_preview_screen.dart';

class CameraScreen extends StatefulWidget {
  final List<String>? initialRecipientIds;
  const CameraScreen({super.key, this.initialRecipientIds});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  int _selectedCameraIndex = 0;
  FlashMode _flashMode = FlashMode.off;
  ZyloFilterType _selectedFilter = ZyloFilterType.normal;
  bool _isInitializing = true;
  bool _isCapturing = false;
  bool _isShutterPressed = false;
  String? _errorMessage;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cameraController = _controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCameraController(cameraController.description);
    }
  }

  Future<void> _initializeCamera() async {
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _isInitializing = false;
          _errorMessage = 'No camera found on this device';
        });
        return;
      }

      // Default to back camera, fallback to first
      int initialIndex = _cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
      );
      if (initialIndex < 0) initialIndex = 0;
      _selectedCameraIndex = initialIndex;

      await _initializeCameraController(_cameras[_selectedCameraIndex]);
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _errorMessage = 'Camera initialization failed: $e';
      });
    }
  }

  Future<void> _initializeCameraController(CameraDescription description) async {
    final prev = _controller;
    if (prev != null) {
      await prev.dispose();
    }

    final controller = CameraController(
      description,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    _controller = controller;

    try {
      await controller.initialize();
      await controller.setFlashMode(_flashMode);
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _errorMessage = 'Could not start camera: $e';
        });
      }
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    HapticFeedback.lightImpact();

    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    setState(() => _isInitializing = true);
    await _initializeCameraController(_cameras[_selectedCameraIndex]);
  }

  Future<void> _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    HapticFeedback.selectionClick();

    FlashMode next;
    switch (_flashMode) {
      case FlashMode.off:
        next = FlashMode.always;
        break;
      case FlashMode.always:
        next = FlashMode.auto;
        break;
      case FlashMode.auto:
      default:
        next = FlashMode.off;
        break;
    }

    try {
      await _controller!.setFlashMode(next);
      setState(() => _flashMode = next);
    } catch (_) {}
  }

  bool get _isFrontCamera {
    if (_controller != null && _controller!.value.isInitialized) {
      return _controller!.description.lensDirection == CameraLensDirection.front;
    }
    if (_cameras.isEmpty || _selectedCameraIndex >= _cameras.length) return false;
    return _cameras[_selectedCameraIndex].lensDirection == CameraLensDirection.front;
  }

  Future<void> _capturePhoto() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isCapturing) {
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isCapturing = true);

    try {
      final isFront = _isFrontCamera;
      final file = await controller.takePicture();
      if (!mounted) return;

      setState(() => _isCapturing = false);
      _openPreview(file.path, isFrontCamera: isFront);
    } catch (e) {
      if (mounted) {
        setState(() => _isCapturing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to capture photo: $e')),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    HapticFeedback.lightImpact();
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (picked != null && mounted) {
        _openPreview(picked.path, isFrontCamera: false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open gallery: $e')),
        );
      }
    }
  }

  void _openPreview(String filePath, {bool isFrontCamera = false}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CameraPreviewScreen(
          imagePath: filePath,
          initialFilter: _selectedFilter,
          isFrontCamera: isFrontCamera,
          initialRecipientIds: widget.initialRecipientIds,
        ),
      ),
    );
  }

  IconData get _flashIcon {
    switch (_flashMode) {
      case FlashMode.always:
        return Icons.flash_on_rounded;
      case FlashMode.auto:
        return Icons.flash_auto_rounded;
      case FlashMode.off:
      default:
        return Icons.flash_off_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Camera Viewfinder or Fallback
          _buildViewfinder(),

          // 2. Top Controls Bar
          _buildTopControls(),

          // 3. Bottom Controls & Filter Bar
          _buildBottomControls(),

          // 4. Capturing Indicator
          if (_isCapturing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primaryOrange),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildViewfinder() {
    if (_isInitializing) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryOrange),
      );
    }

    if (_errorMessage != null || _controller == null || !_controller!.value.isInitialized) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderDark),
                ),
                child: const Icon(Icons.camera_alt_outlined, size: 48, color: AppColors.primaryOrange),
              ),
              const SizedBox(height: 18),
              Text(
                _errorMessage ?? 'Camera Unavailable',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _pickFromGallery,
                icon: const Icon(Icons.photo_library_rounded),
                label: const Text('Pick from Gallery'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget preview = CameraPreview(_controller!);

    final colorFilter = _selectedFilter.colorFilter;
    if (colorFilter != null) {
      preview = ColorFiltered(colorFilter: colorFilter, child: preview);
    }

    return Center(
      child: AspectRatio(
        aspectRatio: 1 / _controller!.value.aspectRatio,
        child: ClipRect(child: preview),
      ),
    );
  }

  Widget _buildTopControls() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black54, Colors.transparent],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Close / Back button
              _buildCircularIconButton(
                icon: Icons.close_rounded,
                onPressed: () => context.pop(),
              ),

              // Title badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ZyloSymbol(size: 18, hasGlow: false, isDark: true),
                    SizedBox(width: 6),
                    Text(
                      'Zylo Camera',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),

              // Action buttons (Flash & Switch Lens)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildCircularIconButton(
                    icon: _flashIcon,
                    onPressed: _toggleFlash,
                    color: _flashMode != FlashMode.off ? AppColors.warningAmber : Colors.white,
                  ),
                  const SizedBox(width: 8),
                  if (_cameras.length > 1)
                    _buildCircularIconButton(
                      icon: Icons.flip_camera_ios_rounded,
                      onPressed: _switchCamera,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.only(bottom: 28, top: 12),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.transparent, Colors.black87],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Filter Pills Carousel
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: ZyloFilterType.values.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = ZyloFilterType.values[index];
                  final isSelected = filter == _selectedFilter;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedFilter = filter);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryOrange
                            : Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppColors.primaryOrange : Colors.white24,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(filter.icon, style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Text(
                            filter.displayName,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Capture Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Gallery Button
                  _buildCircularIconButton(
                    icon: Icons.photo_library_outlined,
                    onPressed: _pickFromGallery,
                    size: 50,
                    iconSize: 24,
                  ),

                  // Prominent Shutter Capture Button
                  GestureDetector(
                    onTapDown: (_) => setState(() => _isShutterPressed = true),
                    onTapUp: (_) {
                      setState(() => _isShutterPressed = false);
                      _capturePhoto();
                    },
                    onTapCancel: () => setState(() => _isShutterPressed = false),
                    child: AnimatedScale(
                      scale: _isShutterPressed ? 0.90 : 1.0,
                      duration: const Duration(milliseconds: 120),
                      curve: Curves.easeOutCubic,
                      child: Container(
                        width: 82,
                        height: 82,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primaryOrange, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryOrange.withValues(alpha: 0.5),
                              blurRadius: 18,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Container(
                            width: 66,
                            height: 66,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Lens Switch or Placeholder
                  if (_cameras.length > 1)
                    _buildCircularIconButton(
                      icon: Icons.cameraswitch_outlined,
                      onPressed: _switchCamera,
                      size: 50,
                      iconSize: 24,
                    )
                  else
                    const SizedBox(width: 50),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color color = Colors.white,
    double size = 42,
    double iconSize = 22,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: color, size: iconSize),
        onPressed: onPressed,
      ),
    );
  }
}
