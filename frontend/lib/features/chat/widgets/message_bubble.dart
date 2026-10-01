import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/message.dart';
import '../../../widgets/media_preview_modal.dart';
import 'message_status_icon.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final VoidCallback? onReply;
  final VoidCallback? onDelete;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.onReply,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Controlled Zylo colors: Sent messages use warm surface with subtle orange accent, not flat neon orange
    final Color bubbleBgColor;
    final Border? bubbleBorder;
    final List<BoxShadow> bubbleShadow;

    if (isMe) {
      bubbleBgColor = isDark ? const Color(0xFF261C18) : const Color(0xFFFFF2EB);
      bubbleBorder = Border.all(
        color: const Color(0xFFFF6B35).withValues(alpha: isDark ? 0.35 : 0.28),
        width: 1.0,
      );
      bubbleShadow = [
        BoxShadow(
          color: const Color(0xFFFF6B35).withValues(alpha: isDark ? 0.08 : 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];
    } else {
      bubbleBgColor = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF);
      bubbleBorder = Border.all(
        color: isDark ? const Color(0x1FFFFFFF) : const Color(0xFFEFE5DC),
        width: 1.0,
      );
      bubbleShadow = [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.03),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];
    }

    final textColor = isDark ? Colors.white : const Color(0xFF1E1614);
    final timeColor = isDark ? Colors.white54 : const Color(0xFF8C7C75);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        child: GestureDetector(
          onLongPress: () => _showContextMenu(context),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 3.5),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: bubbleBgColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isMe ? 20 : 5),
                bottomRight: Radius.circular(isMe ? 5 : 20),
              ),
              border: bubbleBorder,
              boxShadow: bubbleShadow,
            ),
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Replied Message Header Banner
                if (message.replyTo != null) _buildReplyPreview(context, isDark),

                // Media Content (Image/Video/File)
                if (message.mediaUrl != null &&
                    message.mediaUrl!.isNotEmpty &&
                    !message.isDeleted)
                  _buildMediaAttachment(context),

                // Text Content
                if (message.content.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      message.content,
                      style: TextStyle(
                        fontSize: 15,
                        color: message.isDeleted ? Colors.grey : textColor,
                        fontStyle:
                            message.isDeleted ? FontStyle.italic : FontStyle.normal,
                        height: 1.35,
                      ),
                    ),
                  ),

                // Timestamp and Status Icon
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormatter.formatMessageTime(message.createdAt),
                        style: TextStyle(
                          fontSize: 10.5,
                          color: timeColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        MessageStatusIcon(
                          status: message.status,
                          size: 13,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReplyPreview(BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryOrange.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(10),
        border: const Border(
          left: BorderSide(color: AppColors.primaryOrange, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Replying to',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryOrange,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            message.replyTo!.content.isEmpty
                ? 'Media Attachment'
                : message.replyTo!.content,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaAttachment(BuildContext context) {
    String fullUrl = message.mediaUrl!;
    if (!fullUrl.startsWith('http://') && !fullUrl.startsWith('https://')) {
      final base = ApiConstants.baseUrl.replaceAll('/api/v1', '');
      fullUrl = '$base$fullUrl';
    }

    if (message.type == MessageType.image) {
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MediaPreviewModal(
                mediaUrl: fullUrl,
                title: message.mediaMetadata?.fileName ?? 'Photo',
                mimeType: message.mediaMetadata?.mimeType,
              ),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          constraints: const BoxConstraints(maxHeight: 240),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              fullUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              loadingBuilder: (ctx, child, progress) {
                if (progress == null) return child;
                return Container(
                  height: 160,
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryOrange,
                  ),
                );
              },
              errorBuilder: (_, __, ___) => Container(
                height: 120,
                color: Colors.black12,
                alignment: Alignment.center,
                child: const Icon(Icons.broken_image, color: Colors.grey),
              ),
            ),
          ),
        ),
      );
    }

    // Default File Attachment Widget
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.insert_drive_file, color: AppColors.primaryOrange),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message.mediaMetadata?.fileName ?? 'Attachment',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              if (onReply != null)
                ListTile(
                  leading: const Icon(Icons.reply, color: AppColors.primaryOrange),
                  title: const Text('Reply'),
                  onTap: () {
                    Navigator.pop(ctx);
                    onReply!();
                  },
                ),
              if (isMe && onDelete != null && !message.isDeleted)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: AppColors.errorRed),
                  title: const Text(
                    'Delete for Everyone',
                    style: TextStyle(color: AppColors.errorRed),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    onDelete!();
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
