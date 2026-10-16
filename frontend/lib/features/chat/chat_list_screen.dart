import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/user.dart';
import '../../models/conversation.dart';
import '../../models/message.dart';
import '../../models/moment.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/moment_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/moment_badge.dart';
import '../../widgets/zylo_background.dart';
import '../../widgets/zylo_brand.dart';
import '../../widgets/zylo_button.dart';
import '../../widgets/zylo_states.dart';
import 'widgets/message_status_icon.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchFilter = '';

  static const double _panelRadius = 18;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final convState = ref.watch(conversationsProvider);
    final momentsState = ref.watch(momentsProvider);
    final currentUserId = ref.watch(authProvider).user?.id;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Build a lookup map of friend userId -> Moment
    final Map<String, Moment> momentByFriendId = {};
    for (final m in momentsState.moments) {
      if (m.friend != null) {
        momentByFriendId[m.friend!.id] = m;
      }
    }

    // Filter conversations based on search
    final conversations = convState.conversations.where((conv) {
      if (_searchFilter.isEmpty) return true;
      final name = conv.otherUserName;
      final username = conv.otherParticipant?.username ?? '';
      return name.toLowerCase().contains(_searchFilter.toLowerCase()) ||
          username.toLowerCase().contains(_searchFilter.toLowerCase());
    }).toList();

    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ZyloBackground(
        intensity: ZyloBackgroundIntensity.subtle,
        showTopGlow: true,
        showBottomGlow: false,
        showAmbientCanvas: true,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header: wordmark + new chat
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ZyloBrand(
                      size: 24,
                      isDark: isDark,
                      animate: true,
                    ),
                    ZyloCircleAction(
                      icon: Icons.edit_outlined,
                      size: 40,
                      iconSize: 18,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        context.push('/new-chat');
                      },
                    ),
                  ],
                ),
              ),

              // 2. Editorial title
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
                child: Text('Chats', style: AppTypography.serifTitle(fontSize: 44, isDark: isDark)),
              ),

              // 3. Search
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ZyloSearchBar(
                  controller: _searchController,
                  hintText: 'Search chats or friends...',
                  onChanged: (val) => setState(() => _searchFilter = val),
                  onClear: () => setState(() => _searchFilter = ''),
                ),
              ),

              const SizedBox(height: 10),

              // 4. Conversations: one grouped panel, rows split by hairlines
              Expanded(
                child: convState.isLoading && convState.conversations.isEmpty
                    ? const Center(child: ZyloLoadingIndicator(size: 38))
                    : conversations.isEmpty
                        ? ZyloEmptyState(
                            title: _searchFilter.isNotEmpty ? 'No chats found' : 'Nothing here yet.',
                            message: _searchFilter.isNotEmpty
                                ? 'No conversations match "$_searchFilter".'
                                : 'Start a conversation and make your first Moment.',
                            showSparkle: true,
                            actionLabel: _searchFilter.isNotEmpty ? null : 'Start a Conversation',
                            onAction: () => context.push('/new-chat'),
                          )
                        : RefreshIndicator(
                            color: isDark ? AppColors.emberLight : AppColors.primaryOrange,
                            onRefresh: () async {
                              await ref.read(conversationsProvider.notifier).loadConversations();
                              await ref.read(momentsProvider.notifier).loadMoments();
                            },
                            child: CustomScrollView(
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              slivers: [
                                SliverPadding(
                                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                                  sliver: DecoratedSliver(
                                    decoration: BoxDecoration(
                                      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                                      borderRadius: BorderRadius.circular(_panelRadius),
                                      border: Border.all(color: border),
                                    ),
                                    sliver: SliverList.separated(
                                      itemCount: conversations.length,
                                      separatorBuilder: (context, index) => Divider(
                                        height: 1,
                                        thickness: 0.6,
                                        indent: 74,
                                        endIndent: 16,
                                        color: border,
                                      ),
                                      itemBuilder: (context, index) {
                                        return _ConversationListTile(
                                          conv: conversations[index],
                                          currentUserId: currentUserId,
                                          momentByFriendId: momentByFriendId,
                                          isDark: isDark,
                                          borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(index == 0 ? _panelRadius : 0),
                                            bottom: Radius.circular(
                                              index == conversations.length - 1 ? _panelRadius : 0,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConversationListTile extends ConsumerWidget {
  final Conversation conv;
  final String? currentUserId;
  final Map<String, Moment> momentByFriendId;
  final bool isDark;

  /// Rounded only where the row touches the panel's corners, so ripples stay inside it.
  final BorderRadius borderRadius;

  const _ConversationListTile({
    required this.conv,
    required this.currentUserId,
    required this.momentByFriendId,
    required this.isDark,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    User? otherUser = conv.otherParticipant;
    final otherId = otherUser?.id ?? conv.otherUserId;

    if (otherId != null && otherId.isNotEmpty) {
      final liveUser = ref.watch(userProfileProvider(otherId)).valueOrNull;
      if (liveUser != null) {
        otherUser = liveUser;
      }
    }

    final otherUserName = otherUser?.resolvedName ?? conv.otherUserName;
    final otherPhoto = otherUser?.profilePhoto ?? conv.otherParticipant?.profilePhoto;
    final isOnline = otherUser?.isOnline ?? conv.otherParticipant?.isOnline ?? false;
    final lastMsg = conv.lastMessage;
    final isFromMe = lastMsg != null && lastMsg.senderId == currentUserId;
    final unreadCount = conv.unreadCount;
    final hasUnread = unreadCount > 0;

    // Check if a Moment exists with this user
    final moment = otherId != null ? momentByFriendId[otherId] : null;
    final hasActiveMoment = moment != null && moment.isActive;

    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final accent = isDark ? AppColors.emberLight : AppColors.primaryOrange;

    return Material(
      color: Colors.transparent,
      borderRadius: borderRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          context.push(
            '/chat/${conv.id}',
            extra: otherUser != null ? conv.copyWith(otherParticipant: otherUser) : conv,
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              UserAvatar(
                imageUrl: otherPhoto,
                name: otherUserName,
                radius: 22,
                showOnlineStatus: true,
                isOnline: isOnline,
                hasGlow: hasActiveMoment,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            otherUserName,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15.5,
                              letterSpacing: -0.2,
                              color: textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Moment Indicator Badge if active
                        if (moment != null) ...[
                          const SizedBox(width: 6),
                          MomentBadge.fromMoment(moment),
                        ],
                        const SizedBox(width: 8),
                        if (lastMsg != null)
                          Text(
                            DateFormatter.formatChatListTime(lastMsg.createdAt),
                            style: TextStyle(
                              fontSize: 11.5,
                              color: hasUnread ? accent : textSecondary,
                              fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (isFromMe) ...[
                          MessageStatusIcon(status: lastMsg.status, size: 14),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            lastMsg != null
                                ? (lastMsg.isDeleted
                                    ? 'This message was deleted'
                                    : (lastMsg.type == MessageType.image
                                        ? '📷 Photo'
                                        : (lastMsg.type == MessageType.file
                                            ? '📎 Attachment'
                                            : lastMsg.content)))
                                : 'No messages yet',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.5,
                              color: hasUnread ? textPrimary : textSecondary,
                              fontWeight: hasUnread ? FontWeight.w500 : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (hasUnread)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: accent.withValues(alpha: 0.7)),
                            ),
                            child: Text(
                              unreadCount > 99 ? '99+' : '$unreadCount',
                              style: TextStyle(
                                color: accent,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
