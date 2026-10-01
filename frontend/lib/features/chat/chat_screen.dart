import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/conversation.dart';
import '../../models/message.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/moment_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/upload_service.dart';
import '../../widgets/moment_badge.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/zylo_background.dart';
import '../../widgets/zylo_states.dart';
import 'widgets/chat_input_bar.dart';
import 'widgets/message_bubble.dart';
import 'widgets/typing_indicator_widget.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final Conversation? initialConversation;

  const ChatScreen({
    super.key,
    required this.conversationId,
    this.initialConversation,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  Message? _replyingTo;
  bool _isUploadingMedia = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref
          .read(messagesProvider(widget.conversationId).notifier)
          .loadMoreMessages();
    }
  }

  void _handleSendText(String text) {
    ref.read(messagesProvider(widget.conversationId).notifier).sendMessage(
          type: MessageType.text,
          content: text,
          replyTo: _replyingTo,
        );
    setState(() => _replyingTo = null);
  }

  Future<void> _handleSendAttachment(
    String filePath,
    String fileName,
    MessageType type,
  ) async {
    setState(() => _isUploadingMedia = true);
    try {
      final uploadService = ref.read(uploadServiceProvider);
      final result = await uploadService.uploadFile(
        filePath: filePath,
        fileName: fileName,
      );

      final mediaUrl = result['url'] as String;
      final metadata = MediaMetadata(
        fileName: result['fileName'] ?? fileName,
        fileSize: result['fileSize'],
        mimeType: result['mimeType'],
        width: result['width'],
        height: result['height'],
        duration: result['duration'],
      );

      ref.read(messagesProvider(widget.conversationId).notifier).sendMessage(
            type: type,
            content: '',
            mediaUrl: mediaUrl,
            mediaMetadata: metadata,
            replyTo: _replyingTo,
          );
      setState(() => _replyingTo = null);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload file: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingMedia = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messagesState = ref.watch(messagesProvider(widget.conversationId));
    final messagesNotifier =
        ref.read(messagesProvider(widget.conversationId).notifier);
    final currentUserId = ref.watch(authProvider).user?.id;

    final convs = ref.watch(conversationsProvider).conversations;
    Conversation? currentConv;
    try {
      currentConv = convs.firstWhere((c) => c.id == widget.conversationId);
    } catch (_) {
      currentConv = widget.initialConversation;
    }

    if (currentConv == null || currentConv.otherParticipant == null) {
      final fetchedConv = ref.watch(singleConversationProvider(widget.conversationId)).valueOrNull;
      if (fetchedConv != null) {
        currentConv = fetchedConv;
      }
    }

    User? otherUser = currentConv?.otherParticipant;

    if (otherUser != null && otherUser.id.isNotEmpty) {
      final liveUser = ref.watch(userProfileProvider(otherUser.id)).valueOrNull;
      if (liveUser != null) {
        otherUser = liveUser;
      }
    }

    final targetUserId = otherUser?.id ?? currentConv?.otherUserId;
    final otherUserName = otherUser?.resolvedName ?? currentConv?.otherUserName ?? 'User';

    // Check if Moment is active with otherUser
    final momentAsync = targetUserId != null
        ? ref.watch(momentWithUserProvider(targetUserId))
        : null;
    final moment = momentAsync?.asData?.value;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: isDark ? const Color(0xFF161210) : const Color(0xFFFFF8F3),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            HapticFeedback.selectionClick();
            context.pop();
          },
        ),
        title: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            HapticFeedback.selectionClick();
            if (targetUserId != null && targetUserId.isNotEmpty) {
              if (targetUserId == currentUserId) {
                context.push('/profile');
              } else {
                context.push('/user/$targetUserId', extra: otherUser);
              }
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Row(
              children: [
                UserAvatar(
                  imageUrl: otherUser?.profilePhoto,
                  name: otherUserName,
                  radius: 19,
                  showOnlineStatus: true,
                  isOnline: otherUser?.isOnline ?? false,
                  hasGlow: moment != null && moment.isActive,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              otherUserName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (moment != null) ...[
                            const SizedBox(width: 6),
                            MomentBadge.fromMoment(moment),
                          ],
                          const SizedBox(width: 4),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: isDark
                                ? AppColors.textSecondaryDark.withValues(alpha: 0.7)
                                : AppColors.textSecondaryLight.withValues(alpha: 0.7),
                          ),
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(
                        messagesState.isOtherTyping
                            ? 'typing...'
                            : DateFormatter.formatLastSeen(
                                otherUser?.lastSeen,
                                otherUser?.isOnline ?? false,
                              ),
                        style: TextStyle(
                          fontSize: 12,
                          color: messagesState.isOtherTyping
                              ? AppColors.primaryOrange
                              : (isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight),
                          fontWeight: messagesState.isOtherTyping
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'view_profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline_rounded, size: 18),
                    SizedBox(width: 10),
                    Text('View Profile'),
                  ],
                ),
              ),
            ],
            onSelected: (val) {
              if (val == 'view_profile' && targetUserId != null && targetUserId.isNotEmpty) {
                if (targetUserId == currentUserId) {
                  context.push('/profile');
                } else {
                  context.push('/user/$targetUserId', extra: otherUser);
                }
              }
            },
          ),
        ],
      ),
      body: ZyloBackground(
        intensity: ZyloBackgroundIntensity.subtle,
        child: Column(
          children: [
            if (_isUploadingMedia)
              const LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                color: AppColors.primaryOrange,
              ),
            Expanded(
              child: messagesState.isLoading && messagesState.messages.isEmpty
                  ? const Center(child: ZyloLoadingIndicator(size: 36))
                  : messagesState.messages.isEmpty
                      ? ZyloEmptyState(
                          title: 'Say hello!',
                          message: otherUser != null
                              ? 'Start the chat with $otherUserName or share a Moment.'
                              : 'Send a message or a Moment to break the ice.',
                          showSparkle: true,
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          reverse: true,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          itemCount: messagesState.messages.length +
                              (messagesState.isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == messagesState.messages.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primaryOrange,
                                    ),
                                  ),
                                ),
                              );
                            }

                            final message = messagesState.messages[index];
                            final isMe = message.senderId == currentUserId;

                            return MessageBubble(
                              message: message,
                              isMe: isMe,
                              onReply: () => setState(() => _replyingTo = message),
                              onDelete: () => messagesNotifier.deleteMessage(message.id),
                            );
                          },
                        ),
            ),
            if (messagesState.isOtherTyping)
              TypingIndicatorWidget(
                username: otherUserName,
              ),
            ChatInputBar(
              onSendText: _handleSendText,
              onSendAttachment: _handleSendAttachment,
              onTypingStart: () => messagesNotifier.startTyping(),
              onTypingStop: () => messagesNotifier.stopTyping(),
              replyingTo: _replyingTo,
              onCancelReply: () => setState(() => _replyingTo = null),
            ),
          ],
        ),
      ),
    );
  }
}
