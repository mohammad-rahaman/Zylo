import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../models/moment.dart';
import '../../providers/chat_provider.dart';
import '../../providers/moment_provider.dart';
import '../../widgets/user_avatar.dart';
import 'widgets/share_moment_modal.dart';
import '../../core/theme/app_typography.dart';

class MomentsScreen extends ConsumerWidget {
  const MomentsScreen({super.key});

  void _showShareMomentModal(BuildContext context, WidgetRef ref, Moment moment) {
    final friend = moment.friend;
    if (friend == null) return;
    ShareMomentModal.show(context, targetUser: friend);
  }

  void _handleNewMoment(BuildContext context, WidgetRef ref, List<Moment> moments) {
    if (moments.isEmpty) {
      context.push('/new-chat');
      return;
    }
    if (moments.length == 1) {
      _showShareMomentModal(context, ref, moments.first);
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    'Share Moment with...',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: moments.length,
                    itemBuilder: (context, index) {
                      final m = moments[index];
                      final f = m.friend;
                      if (f == null) return const SizedBox.shrink();
                      return ListTile(
                        leading: UserAvatar(imageUrl: f.profilePhoto, name: f.displayName, radius: 20),
                        title: Text(f.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(m.daysTogetherText, style: const TextStyle(color: AppColors.primaryOrange)),
                        trailing: const Icon(Icons.camera_alt_rounded, color: AppColors.primaryOrange),
                        onTap: () {
                          Navigator.pop(ctx);
                          ShareMomentModal.show(context, targetUser: f);
                        },
                      );
                    },
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primaryOrange,
                    child: Icon(Icons.person_add_rounded, color: Colors.white),
                  ),
                  title: const Text('Find someone new', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/new-chat');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateToChat(BuildContext context, WidgetRef ref, Moment moment) async {
    final friend = moment.friend;
    if (friend == null) return;

    try {
      final conv = await ref
          .read(conversationsProvider.notifier)
          .startConversation(friend.id);
      if (context.mounted) {
        context.push('/chat/${conv.id}', extra: conv);
      }
    } catch (_) {}
  }

  void _showEndMomentDialog(BuildContext context, WidgetRef ref, Moment moment) {
    final friendName = moment.friend?.displayName ?? 'your friend';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End Moment?'),
        content: Text(
          'Are you sure you want to end your Moment with $friendName? Your daily connection will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(momentsProvider.notifier).endMoment(moment.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Moment with $friendName ended')),
              );
            },
            child: const Text('End Moment'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final momentsState = ref.watch(momentsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'moments_share_fab',
        backgroundColor: AppColors.primaryOrange,
        icon: const Icon(Icons.camera_alt_rounded, color: Colors.white),
        label: const Text(
          'Share Moment',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        onPressed: () => _handleNewMoment(context, ref, momentsState.moments),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryOrange,
          onRefresh: () => ref.read(momentsProvider.notifier).loadMoments(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Header & Brand Subtitle
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Moments',
                            style: TextStyle(fontFamily: AppTypography.serifFamily, fontSize: 42, height: 1.1, letterSpacing: -0.3),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryOrange.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              '✨',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Share your day. Keep your connections alive.',
                        style: TextStyle(
                          fontSize: 15,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Content / Empty State
              if (momentsState.isLoading && momentsState.moments.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primaryOrange),
                  ),
                )
              else if (momentsState.moments.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 36),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              color: AppColors.primaryOrange.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text('✨', style: TextStyle(fontSize: 40)),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'No Moments yet.',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start one with a friend and share your day together.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => context.push('/new-chat'),
                            icon: const Icon(Icons.people_outline, size: 20),
                            label: const Text('Find Friends'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final moment = momentsState.moments[index];
                        return _buildMomentCard(context, ref, moment, isDark);
                      },
                      childCount: momentsState.moments.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMomentCard(
    BuildContext context,
    WidgetRef ref,
    Moment moment,
    bool isDark,
  ) {
    final friend = moment.friend;
    final friendName = friend?.displayName ?? 'Friend';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: moment.isExpiringSoon
              ? AppColors.warningAmber.withValues(alpha: 0.6)
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
          width: moment.isExpiringSoon ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header Banner
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('✨', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      'YOUR MOMENT',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                        color: AppColors.primaryOrange,
                      ),
                    ),
                  ],
                ),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_horiz,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                  onSelected: (val) {
                    if (val == 'end') {
                      _showEndMomentDialog(context, ref, moment);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'end',
                      child: Row(
                        children: [
                          Icon(Icons.close, size: 18, color: AppColors.errorRed),
                          SizedBox(width: 8),
                          Text('End Moment', style: TextStyle(color: AppColors.errorRed)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Friend details & Days Together
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                UserAvatar(
                  imageUrl: friend?.profilePhoto,
                  name: friendName,
                  radius: 26,
                  showOnlineStatus: true,
                  isOnline: friend?.isOnline ?? false,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        friendName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryOrange.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('✨', style: TextStyle(fontSize: 11)),
                                const SizedBox(width: 4),
                                Text(
                                  moment.daysTogetherText,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryOrange,
                                  ),
                                ),
                              ],
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

          // Expiration warning if expiring soon
          if (moment.isExpiringSoon) ...[
            const SizedBox(height: 12),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 18),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.warningAmber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 16, color: AppColors.warningAmber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your Moment with $friendName is waiting ✨ (${moment.hoursRemaining}h left)',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.warningAmber,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),
          const Divider(height: 1),

          // Card Action Footer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    moment.hasInteractedInCurrentWindow
                        ? 'Shared today ✨'
                        : 'Share your moment today',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Chat',
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                  onPressed: () => _navigateToChat(context, ref, moment),
                ),
                const SizedBox(width: 4),
                ElevatedButton.icon(
                  onPressed: () => _showShareMomentModal(context, ref, moment),
                  icon: const Icon(Icons.camera_alt_rounded, size: 16),
                  label: const Text('Share Moment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
