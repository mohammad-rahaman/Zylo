import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/message.dart';

class ChatInputBar extends StatefulWidget {
  final Function(String text) onSendText;
  final Function(String filePath, String fileName, MessageType type) onSendAttachment;
  final VoidCallback onTypingStart;
  final VoidCallback onTypingStop;
  final Message? replyingTo;
  final VoidCallback? onCancelReply;

  const ChatInputBar({
    super.key,
    required this.onSendText,
    required this.onSendAttachment,
    required this.onTypingStart,
    required this.onTypingStop,
    this.replyingTo,
    this.onCancelReply,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final PermissionService _permissionService = PermissionService();
  bool _hasText = false;
  bool _isSendPressed = false;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }

    if (hasText) {
      widget.onTypingStart();
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 3), () {
        widget.onTypingStop();
      });
    } else {
      widget.onTypingStop();
    }
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    HapticFeedback.lightImpact();
    _controller.clear();
    widget.onTypingStop();
    widget.onSendText(text);
  }

  Future<void> _pickImage(ImageSource source) async {
    bool granted = false;
    if (source == ImageSource.camera) {
      granted = await _permissionService.requestCameraPermission(context: context);
    } else {
      granted = await _permissionService.requestPhotosPermission(context: context);
    }
    if (!granted) return;

    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1080,
        maxHeight: 1080,
        requestFullMetadata: false,
      );
      if (picked != null) {
        widget.onSendAttachment(picked.path, picked.name, MessageType.image);
      }
    } catch (_) {}
  }

  Future<void> _shareLocation() async {
    final granted = await _permissionService.requestLocationPermission(context: context);
    if (!granted) return;

    widget.onSendText('📍 Shared Location: https://maps.google.com/?q=28.6139,77.2090');
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result != null && result.files.single.path != null) {
        final file = result.files.single;
        widget.onSendAttachment(file.path!, file.name, MessageType.file);
      }
    } catch (_) {}
  }

  void _showAttachmentSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Container(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildAttachmentOption(
                      icon: Icons.image_rounded,
                      color: AppColors.primaryOrange,
                      label: 'Photos',
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickImage(ImageSource.gallery);
                      },
                    ),
                    _buildAttachmentOption(
                      icon: Icons.camera_alt_rounded,
                      color: AppColors.primaryOrange,
                      label: 'Camera',
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickImage(ImageSource.camera);
                      },
                    ),
                    _buildAttachmentOption(
                      icon: Icons.insert_drive_file_rounded,
                      color: AppColors.primaryOrange,
                      label: 'Document',
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickFile();
                      },
                    ),
                    _buildAttachmentOption(
                      icon: Icons.location_on_rounded,
                      color: AppColors.primaryOrange,
                      label: 'Location',
                      onTap: () {
                        Navigator.pop(ctx);
                        _shareLocation();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.16 : 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: isDark ? 0.35 : 0.25),
                width: 1.2,
              ),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Replying Header Banner
        if (widget.replyingTo != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceSubduedDark : AppColors.surfaceSubduedLight,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.reply_rounded, size: 18, color: AppColors.primaryOrange),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Replying to message',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryOrange,
                        ),
                      ),
                      Text(
                        widget.replyingTo!.content.isEmpty
                            ? 'Attachment'
                            : widget.replyingTo!.content,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: widget.onCancelReply,
                ),
              ],
            ),
          ),

        // Unified Rounded Composer
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: _hasText
                    ? AppColors.primaryOrange.withValues(alpha: isDark ? 0.45 : 0.35)
                    : (isDark ? AppColors.borderDark : AppColors.borderLight),
                width: _hasText ? 1.2 : 1.0,
              ),
              boxShadow: [
                if (_hasText)
                  BoxShadow(
                    color: AppColors.primaryOrange.withValues(alpha: isDark ? 0.12 : 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  )
                else
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(width: 16),

                // Text Input Field
                Expanded(
                  child: TextField(
                    controller: _controller,
                    maxLines: 4,
                    minLines: 1,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(fontSize: 14.5),
                    decoration: InputDecoration(
                      hintText: 'Message...',
                      hintStyle: TextStyle(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                        fontSize: 14.5,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),

                // Attachment Button (+)
                IconButton(
                  icon: Icon(
                    Icons.add_circle_outline_rounded,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    size: 22,
                  ),
                  onPressed: _showAttachmentSheet,
                ),

                // Quick Camera (when no text)
                if (!_hasText)
                  IconButton(
                    icon: Icon(
                      Icons.camera_alt_outlined,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      size: 21,
                    ),
                    onPressed: () => _pickImage(ImageSource.camera),
                  ),

                // Send Button (➤) with glowing orange active state and press scale
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTapDown: _hasText ? (_) => setState(() => _isSendPressed = true) : null,
                    onTapUp: _hasText
                        ? (_) {
                            setState(() => _isSendPressed = false);
                            _handleSend();
                          }
                        : null,
                    onTapCancel: () => setState(() => _isSendPressed = false),
                    child: AnimatedScale(
                      scale: _isSendPressed ? 0.88 : 1.0,
                      duration: const Duration(milliseconds: 120),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _hasText
                              ? (isDark ? AppColors.emberLight : AppColors.primaryOrange)
                                  .withValues(alpha: isDark ? 0.16 : 0.10)
                              : (isDark ? AppColors.surfaceSubduedDark : AppColors.surfaceSubduedLight),
                          border: Border.all(
                            color: _hasText
                                ? (isDark ? AppColors.emberLight : AppColors.primaryOrange)
                                    .withValues(alpha: 0.85)
                                : (isDark ? AppColors.borderDark : AppColors.borderLight),
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.arrow_upward_rounded,
                            color: _hasText
                                ? (isDark ? AppColors.emberLight : AppColors.primaryOrange)
                                : (isDark ? Colors.white30 : Colors.black26),
                            size: 19,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
