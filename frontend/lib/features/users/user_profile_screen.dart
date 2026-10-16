import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/conversation.dart';
import '../../models/moment.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/moment_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/moment_badge.dart';
import '../../widgets/zylo_background.dart';
import '../../widgets/zylo_states.dart';
import '../../widgets/zylo_button.dart';
import '../../core/theme/app_typography.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  final String userId;
  final User? initialUser;

  const UserProfileScreen({
    super.key,
    required this.userId,
    this.initialUser,
  });

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  bool _isLoadingAction = false;

  void _startChat(User user) async {
    setState(() => _isLoadingAction = true);
    try {
      // 1. Check if conversation already exists in conversationsProvider
      final convs = ref.read(conversationsProvider).conversations;
      Conversation? existing;
      try {
        existing = convs.firstWhere((c) =>
            c.otherParticipant?.id == user.id ||
            c.participants.any((p) => p.id == user.id));
      } catch (_) {}

      if (existing != null) {
        if (mounted) {
          context.push('/chat/${existing.id}', extra: existing);
        }
        return;
      }

      // 2. Start conversation via existing flow (getOrCreateOneToOne in backend is idempotent)
      final conv = await ref
          .read(conversationsProvider.notifier)
          .startConversation(user.id);
      if (mounted) {
        context.push('/chat/${conv.id}', extra: conv);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start chat: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingAction = false);
    }
  }

  void _sendMoment(User user) {
    HapticFeedback.selectionClick();
    context.push('/camera?recipientId=${user.id}', extra: user.id);
  }

  void _handleStartMoment(User user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Start a Moment with ${user.resolvedName}?'),
        content: const Text(
          'Share something every day and keep your Moment alive. You will both maintain a daily connection together ✨',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Start Moment'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoadingAction = true);
    try {
      await ref.read(momentsProvider.notifier).startMoment(user.id);
      ref.invalidate(momentWithUserProvider(user.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✨ Started a Moment with ${user.resolvedName}!'),
            backgroundColor: AppColors.primaryOrange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start Moment: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingAction = false);
    }
  }

  void _toggleBlock(User user) async {
    final willBlock = !user.isBlocked;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(willBlock ? 'Block ${user.resolvedName}?' : 'Unblock ${user.resolvedName}?'),
        content: Text(
          willBlock
              ? 'Blocked contacts will no longer be able to send you messages or Moments.'
              : 'You will be able to receive messages and Moments from this contact again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: willBlock ? AppColors.errorRed : AppColors.primaryOrange,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(willBlock ? 'Block' : 'Unblock'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoadingAction = true);
    try {
      if (willBlock) {
        await ref.read(profileControllerProvider.notifier).blockUser(user.id);
      } else {
        await ref.read(profileControllerProvider.notifier).unblockUser(user.id);
      }
      ref.invalidate(userProfileProvider(user.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              willBlock
                  ? '${user.resolvedName} has been blocked'
                  : '${user.resolvedName} unblocked',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingAction = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(authProvider).user?.id;
    final profileAsync = ref.watch(userProfileProvider(widget.userId));
    final momentAsync = ref.watch(momentWithUserProvider(widget.userId));

    final user = profileAsync.valueOrNull ?? widget.initialUser;
    final isMe = widget.userId == currentUserId || user?.id == currentUserId;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final moment = momentAsync.asData?.value;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          user?.resolvedName ?? (isMe ? 'My Profile' : 'Profile'),
          style: const TextStyle(letterSpacing: -0.2),
        ),
        backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (user != null && !isMe)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              onSelected: (val) {
                if (val == 'block') _toggleBlock(user);
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: 'block',
                  child: Row(
                    children: [
                      Icon(
                        user.isBlocked ? Icons.check_circle_outline : Icons.block,
                        color: user.isBlocked ? AppColors.primaryOrange : AppColors.errorRed,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        user.isBlocked ? 'Unblock Contact' : 'Block Contact',
                        style: TextStyle(
                          color: user.isBlocked ? AppColors.primaryOrange : AppColors.errorRed,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: user != null
          ? _buildProfileContent(context, user, isMe, moment, isDark)
          : profileAsync.when(
              data: (fetchedUser) =>
                  _buildProfileContent(context, fetchedUser, isMe, moment, isDark),
              loading: () => const Center(child: ZyloLoadingIndicator(size: 38)),
              error: (err, _) => Center(
                child: ZyloEmptyState(
                  title: "Couldn't load this profile.",
                  message: 'Check your connection or this user might no longer exist.',
                  showSparkle: false,
                  icon: Icons.person_off_rounded,
                  actionLabel: 'Try Again',
                  onAction: () => ref.invalidate(userProfileProvider(widget.userId)),
                ),
              ),
            ),
    );
  }

  Widget _buildProfileContent(
    BuildContext context,
    User user,
    bool isMe,
    Moment? moment,
    bool isDark,
  ) {
    return ZyloBackground(
      intensity: ZyloBackgroundIntensity.subtle,
      showTopGlow: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          children: [
            // 1. Avatar with Glow
            Center(
              child: UserAvatar(
                imageUrl: user.profilePhoto,
                name: user.resolvedName,
                radius: 52,
                showOnlineStatus: true,
                isOnline: user.isOnline,
                hasGlow: true,
              ),
            ),
            const SizedBox(height: 16),

            // 2. Display Name
            Text(
              user.resolvedName,
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: AppTypography.serifFamily, fontSize: 34, height: 1.1, letterSpacing: -0.3),
            ),

            // 3. Username if available
            if (user.username.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '@${user.username}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            ],

            const SizedBox(height: 8),

            // 4. Online Presence / Last Seen
            Text(
              DateFormatter.formatLastSeen(user.lastSeen, user.isOnline),
              style: TextStyle(
                fontSize: 13,
                color: user.isOnline ? AppColors.onlineGreen : Colors.grey,
                fontWeight: user.isOnline ? FontWeight.w600 : FontWeight.normal,
              ),
            ),

            // 5. Moment Status Pill (if active Moment exists)
            if (moment != null && moment.isActive) ...[
              const SizedBox(height: 14),
              MomentBadge.fromMoment(moment),
            ],

            const SizedBox(height: 22),

            // 6. Action Buttons
            if (!isMe)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Message Button
                  ZyloPrimaryButton(
                    label: 'Message',
                    icon: Icons.chat_bubble_outline_rounded,
                    height: 46,
                    expand: false,
                    onPressed: _isLoadingAction ? null : () => _startChat(user),
                  ),
                  const SizedBox(width: 12),

                  // Send Moment Button
                  SizedBox(
                    height: 46,
                    child: OutlinedButton.icon(
                      onPressed: () => _sendMoment(user),
                      icon: const Icon(Icons.camera_alt_outlined, size: 18),
                      label: const Text('Send Moment'),
                    ),
                  ),
                ],
              )
            else
              // Self Profile: Edit Profile Button
              ZyloPrimaryButton(
                label: 'Edit Profile',
                icon: Icons.edit_outlined,
                height: 46,
                expand: false,
                onPressed: () => context.push('/edit-profile'),
              ),

            const SizedBox(height: 24),

            // 7. Moment Card (For Other Users)
            if (!isMe) ...[
              if (moment != null && moment.isActive)
                ZyloSurface(
                  enableGlow: true,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('✨', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          const Text(
                            'YOUR MOMENT',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                              color: AppColors.primaryOrange,
                            ),
                          ),
                          const SizedBox(width: 8),
                          MomentBadge.fromMoment(moment),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        moment.daysTogetherText,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        moment.hasInteractedInCurrentWindow
                            ? 'Shared for today ✨'
                            : 'Share your moment today with a photo',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ZyloPrimaryButton(
                        label: 'Share Moment Photo ✨',
                        icon: Icons.camera_alt_outlined,
                        height: 46,
                        expand: false,
                        onPressed: () => _sendMoment(user),
                      ),
                    ],
                  ),
                )
              else
                ZyloSurface(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text('✨', style: TextStyle(fontSize: 32)),
                      const SizedBox(height: 8),
                      const Text(
                        'Share Daily Moments',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: -0.2),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Keep a daily connection alive with ${user.resolvedName}.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ZyloPrimaryButton(
                            label: 'Send Moment',
                            icon: Icons.camera_alt_outlined,
                            height: 46,
                            expand: false,
                            onPressed: _isLoadingAction ? null : () => _sendMoment(user),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton(
                            onPressed: _isLoadingAction ? null : () => _handleStartMoment(user),
                            style: OutlinedButton.styleFrom(
                              shape: const RoundedRectangleBorder(borderRadius: AppRadius.pillBorder),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                              side: BorderSide(
                                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                              ),
                            ),
                            child: const Text('Start', style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
            ],

            // 8. About & Email Card
            ZyloSurface(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ABOUT',
                    style: TextStyle(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user.bio.isNotEmpty ? user.bio : 'Hey there! I am using Zylo.',
                    style: const TextStyle(fontSize: 15, height: 1.3),
                  ),
                  if (user.email.isNotEmpty) ...[
                    Divider(
                      height: 28,
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                    Text(
                      'EMAIL',
                      style: TextStyle(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(user.email, style: const TextStyle(fontSize: 15)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
