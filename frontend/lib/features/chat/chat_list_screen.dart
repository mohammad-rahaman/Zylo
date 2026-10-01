import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
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

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ZyloBackground(
        intensity: ZyloBackgroundIntensity.subtle,
        showTopGlow: true,
        showBottomGlow: true,
        showAmbientCanvas: true,
        child: SafeArea(
          child: Column(
            children: [
              // 1. Premium Zylo Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ZyloBrand(
                      size: 26,
                      isDark: isDark,
                      animate: true,
                    ),
                    Row(
                      children: [
                        // New Chat / Search People Button with Surface Container
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E1A18) : const Color(0xFFF7ECE4),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark ? const Color(0x30FF6B35) : const Color(0x2050280A),
                              width: 1,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () {
                                HapticFeedback.selectionClick();
                                context.push('/new-chat');
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(9),
                                child: Icon(
                                  Icons.edit_square,
                                  size: 20,
                                  color: AppColors.primaryOrange,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 2. Branded Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: ZyloSearchBar(
                  controller: _searchController,
                  hintText: 'Search chats or friends...',
                  onChanged: (val) => setState(() => _searchFilter = val),
                  onClear: () => setState(() => _searchFilter = ''),
                ),
              ),

              const SizedBox(height: 6),

              // 3. Conversation List or State
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
                            color: AppColors.primaryOrange,
                            onRefresh: () async {
                              await ref.read(conversationsProvider.notifier).loadConversations();
                              await ref.read(momentsProvider.notifier).loadMoments();
                            },
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                              itemCount: conversations.length,
                              itemBuilder: (context, index) {
                                final conv = conversations[index];
                                return _ConversationListTile(
                                  conv: conv,
                                  currentUserId: currentUserId,
                                  momentByFriendId: momentByFriendId,
                                  isDark: isDark,
                                );
                              },
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

  const _ConversationListTile({
    required this.conv,
    required this.currentUserId,
    required this.momentByFriendId,
    required this.isDark,
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

    // Check if a Moment exists with this user
    final moment = otherId != null ? momentByFriendId[otherId] : null;
    final hasActiveMoment = moment != null && moment.isActive;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1715) : const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasActiveMoment
              ? AppColors.primaryOrange.withValues(alpha: isDark ? 0.35 : 0.28)
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
          width: hasActiveMoment ? 1.2 : 1.0,
        ),
        boxShadow: [
          if (hasActiveMoment)
            BoxShadow(
              color: AppColors.primaryOrange.withValues(alpha: isDark ? 0.08 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            )
          else
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 6,
          ),
          leading: UserAvatar(
            imageUrl: otherPhoto,
            name: otherUserName,
            radius: 25,
            showOnlineStatus: true,
            isOnline: isOnline,
            hasGlow: hasActiveMoment,
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  otherUserName,
                  style: TextStyle(
                    fontWeight: unreadCount > 0 ? FontWeight.w800 : FontWeight.w700,
                    fontSize: 16,
                    letterSpacing: -0.2,
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
                  DateFormatter.formatMessageTime(lastMsg.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
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
                      fontSize: 13,
                      color: unreadCount > 0
                          ? (isDark ? Colors.white : AppColors.textPrimaryLight)
                          : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                      fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                if (unreadCount > 0)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x66FF6B35),
                          blurRadius: 6,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          onTap: () {
            HapticFeedback.selectionClick();
            context.push(
              '/chat/${conv.id}',
              extra: otherUser != null
                  ? conv.copyWith(otherParticipant: otherUser)
                  : conv,
            );
          },
        ),
      ),
    );
  }
}
