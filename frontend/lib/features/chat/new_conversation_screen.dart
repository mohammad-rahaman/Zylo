import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/zylo_background.dart';
import '../../widgets/zylo_states.dart';

class NewConversationScreen extends ConsumerStatefulWidget {
  const NewConversationScreen({super.key});

  @override
  ConsumerState<NewConversationScreen> createState() => _NewConversationScreenState();
}

class _NewConversationScreenState extends ConsumerState<NewConversationScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  bool _isStarting = false;

  void _startChat(User user) async {
    setState(() => _isStarting = true);
    try {
      final conv = await ref
          .read(conversationsProvider.notifier)
          .startConversation(user.id);
      if (mounted) {
        context.pushReplacement('/chat/${conv.id}', extra: conv);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start conversation: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchAsync = ref.watch(userSearchProvider(_query));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Select Contact',
          style: TextStyle(letterSpacing: -0.2),
        ),
        backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
        elevation: 0,
      ),
      body: ZyloBackground(
        intensity: ZyloBackgroundIntensity.subtle,
        showTopGlow: true,
        child: Column(
          children: [
            if (_isStarting)
              const LinearProgressIndicator(
                color: AppColors.primaryOrange,
                backgroundColor: Colors.transparent,
                minHeight: 2.5,
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: ZyloSearchBar(
                controller: _searchController,
                hintText: 'Search by username or name...',
                onChanged: (val) => setState(() => _query = val),
                onClear: () {
                  _searchController.clear();
                  setState(() => _query = '');
                },
              ),
            ),
            Expanded(
              child: searchAsync.when(
                data: (users) {
                  if (users.isEmpty) {
                    return ZyloEmptyState(
                      title: _query.isNotEmpty ? 'No users found' : 'Find your friends',
                      subtitle: _query.isNotEmpty
                          ? 'Try searching with another name or username.'
                          : 'Type a name or username above to connect.',
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: users.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _isStarting ? null : () => _startChat(user),
                          borderRadius: BorderRadius.circular(16),
                          child: Ink(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                              ),
                            ),
                            child: Row(
                              children: [
                                UserAvatar(
                                  imageUrl: user.profilePhoto,
                                  name: user.displayName,
                                  radius: 22,
                                  showOnlineStatus: true,
                                  isOnline: user.isOnline,
                                  hasGlow: user.isOnline,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user.displayName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '@${user.username}${user.bio.isNotEmpty ? ' • ${user.bio}' : ''}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isDark
                                              ? AppColors.textSecondaryDark
                                              : AppColors.textSecondaryLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  size: 20,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: ZyloLoadingIndicator(size: 38)),
                error: (err, _) {
                  final isAuthError = err.toString().contains('401');
                  return ZyloEmptyState(
                    title: isAuthError ? 'Session expired' : 'Unable to load contacts',
                    subtitle: isAuthError
                        ? 'Please log in again to continue.'
                        : 'Check your network connection and try again.',
                    actionLabel: isAuthError ? 'Log In' : null,
                    onAction: isAuthError
                        ? () {
                            ref.read(authProvider.notifier).logout();
                            context.go('/login');
                          }
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
