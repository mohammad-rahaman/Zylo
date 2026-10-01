import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/message.dart';
import '../../../models/user.dart';
import '../../../providers/chat_provider.dart';
import '../../../providers/moment_provider.dart';
import '../../../services/upload_service.dart';
import '../../../widgets/user_avatar.dart';

class ShareMomentModal extends ConsumerStatefulWidget {
  final User targetUser;
  final String? conversationId;

  const ShareMomentModal({
    super.key,
    required this.targetUser,
    this.conversationId,
  });

  static Future<void> show(
    BuildContext context, {
    required User targetUser,
    String? conversationId,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ShareMomentModal(
        targetUser: targetUser,
        conversationId: conversationId,
      ),
    );
  }

  @override
  ConsumerState<ShareMomentModal> createState() => _ShareMomentModalState();
}

class _ShareMomentModalState extends ConsumerState<ShareMomentModal> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _captionController = TextEditingController();

  XFile? _selectedImage;
  Uint8List? _imageBytes;
  bool _isUploading = false;
  bool _isFlipped = false;
  String? _locationTag;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final permService = ref.read(permissionServiceProvider);
    bool granted = false;

    if (source == ImageSource.camera) {
      granted = await permService.requestCameraPermission(context: context);
    } else {
      granted = await permService.requestPhotosPermission(context: context);
    }

    if (!granted) return;

    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1080,
        maxHeight: 1080,
        requestFullMetadata: false,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _selectedImage = picked;
          _imageBytes = bytes;
          _isFlipped = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open ${source == ImageSource.camera ? 'camera' : 'gallery'}: $e')),
        );
      }
    }
  }

  Future<void> _toggleLocation() async {
    if (_locationTag != null) {
      setState(() => _locationTag = null);
      return;
    }

    final permService = ref.read(permissionServiceProvider);
    final granted = await permService.requestLocationPermission(context: context);
    if (!granted) return;

    setState(() {
      _locationTag = '📍 Shared Location';
    });
  }

  Future<void> _handleShareMoment() async {
    if (_imageBytes == null || _selectedImage == null) return;

    setState(() => _isUploading = true);

    try {
      final uploadService = ref.read(uploadServiceProvider);
      final filename = _selectedImage!.name.isNotEmpty
          ? _selectedImage!.name
          : 'moment_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Parallelize file upload and conversation resolution for maximum speed
      final uploadFuture = uploadService.uploadBytes(
        bytes: _imageBytes!,
        fileName: filename,
      );

      final convFuture = (widget.conversationId != null && widget.conversationId!.isNotEmpty)
          ? Future.value(widget.conversationId!)
          : ref
              .read(conversationsProvider.notifier)
              .startConversation(widget.targetUser.id)
              .then((c) => c.id);

      final results = await Future.wait([uploadFuture, convFuture]);
      final uploadResult = results[0] as Map<String, dynamic>;
      final convId = results[1] as String;

      final mediaUrl = uploadResult['url'] as String;
      final metadata = MediaMetadata(
        fileName: uploadResult['fileName'] ?? filename,
        fileSize: uploadResult['fileSize'] ?? _imageBytes!.length,
        mimeType: uploadResult['mimeType'] ?? 'image/jpeg',
        width: uploadResult['width'],
        height: uploadResult['height'],
      );

      // Compose caption with location tag
      String finalCaption = _captionController.text.trim();
      if (_locationTag != null) {
        finalCaption = finalCaption.isEmpty
            ? _locationTag!
            : '$finalCaption\n$_locationTag';
      }

      // Send the Moment photo message
      await ref.read(messagesProvider(convId).notifier).sendMessage(
            type: MessageType.image,
            content: finalCaption,
            mediaUrl: mediaUrl,
            mediaMetadata: metadata,
          );

      // Trigger Moment start & refresh
      try {
        await ref.read(momentsProvider.notifier).startMoment(widget.targetUser.id);
      } catch (_) {}
      ref.read(momentsProvider.notifier).loadMoments();
      ref.invalidate(momentWithUserProvider(widget.targetUser.id));

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primaryOrange,
            content: Row(
              children: [
                const Text('✨ ', style: TextStyle(fontSize: 16)),
                Expanded(
                  child: Text(
                    'Moment photo shared with ${widget.targetUser.displayName}!',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share moment: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header with Friend Info
            Row(
              children: [
                UserAvatar(
                  imageUrl: widget.targetUser.profilePhoto,
                  name: widget.targetUser.displayName,
                  radius: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('✨', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 5),
                          Text(
                            'SHARE A MOMENT',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                              color: AppColors.primaryOrange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'with ${widget.targetUser.displayName}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Image Preview or Image Selection Buttons
            if (_imageBytes != null) ...[
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.rotationY(_isFlipped ? math.pi : 0),
                      child: Image.memory(
                        _imageBytes!,
                        height: 260,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: IconButton(
                            icon: Icon(
                              _isFlipped ? Icons.flip_camera_android_rounded : Icons.flip_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            tooltip: 'Mirror / Flip horizontal',
                            onPressed: _isUploading
                                ? null
                                : () => setState(() => _isFlipped = !_isFlipped),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                            tooltip: 'Choose another image',
                            onPressed: _isUploading
                                ? null
                                : () => setState(() {
                                      _selectedImage = null;
                                      _imageBytes = null;
                                      _isFlipped = false;
                                    }),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Caption TextField
              TextField(
                controller: _captionController,
                enabled: !_isUploading,
                decoration: InputDecoration(
                  hintText: 'Add a moment note... ✨',
                  prefixIcon: const Icon(Icons.edit_outlined, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _locationTag != null
                          ? Icons.location_on_rounded
                          : Icons.add_location_alt_outlined,
                      color: _locationTag != null ? AppColors.primaryOrange : null,
                    ),
                    tooltip: 'Tag Location',
                    onPressed: _isUploading ? null : _toggleLocation,
                  ),
                ),
              ),

              if (_locationTag != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Chip(
                    avatar: const Icon(Icons.location_on, size: 16, color: AppColors.primaryOrange),
                    label: Text(_locationTag!),
                    deleteIcon: const Icon(Icons.close, size: 14),
                    onDeleted: () => setState(() => _locationTag = null),
                  ),
                ),
              ],

              const SizedBox(height: 18),

              // Submit Button
              ElevatedButton.icon(
                onPressed: _isUploading ? null : _handleShareMoment,
                icon: _isUploading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('✨', style: TextStyle(fontSize: 16)),
                label: Text(_isUploading ? 'Uploading & Sharing...' : 'Share Moment ✨'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ] else ...[
              // Option Cards for Camera & Gallery
              Text(
                'Capture or select a photo to share your day and keep your Moment connection alive.',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: _buildActionTile(
                      context,
                      icon: Icons.camera_alt_rounded,
                      title: 'Take Photo',
                      subtitle: 'Camera',
                      color: AppColors.primaryOrange,
                      onTap: () => _pickImage(ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildActionTile(
                      context,
                      icon: Icons.photo_library_rounded,
                      title: 'Select Photo',
                      subtitle: 'Gallery',
                      color: const Color(0xFFC32AA3),
                      onTap: () => _pickImage(ImageSource.gallery),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Location Option Tile
              OutlinedButton.icon(
                onPressed: _toggleLocation,
                icon: Icon(
                  _locationTag != null ? Icons.location_on_rounded : Icons.location_on_outlined,
                  color: _locationTag != null ? AppColors.primaryOrange : null,
                  size: 18,
                ),
                label: Text(
                  _locationTag ?? 'Add Map Location to Moment',
                  style: TextStyle(
                    color: _locationTag != null ? AppColors.primaryOrange : null,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
