import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/user_provider.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/zylo_background.dart';
import '../../widgets/zylo_states.dart';

class SearchUsersScreen extends ConsumerStatefulWidget {
  const SearchUsersScreen({super.key});

  @override
  ConsumerState<SearchUsersScreen> createState() => _SearchUsersScreenState();
}

class _SearchUsersScreenState extends ConsumerState<SearchUsersScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
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
          'Find People',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.3),
        ),
        backgroundColor: isDark ? const Color(0xFF161210) : const Color(0xFFFFF8F3),
        elevation: 0,
      ),
      body: ZyloBackground(
        intensity: ZyloBackgroundIntensity.subtle,
        showTopGlow: true,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: ZyloSearchBar(
                controller: _controller,
                hintText: 'Search people by username or name...',
                onChanged: (val) => setState(() => _query = val),
                onClear: () {
                  _controller.clear();
                  setState(() => _query = '');
                },
              ),
            ),
            Expanded(
              child: searchAsync.when(
                data: (users) {
                  if (users.isEmpty) {
                    return ZyloEmptyState(
                      title: _query.isNotEmpty ? 'No users found' : 'Explore the community',
                      subtitle: _query.isNotEmpty
                          ? 'Try typing another username or name.'
                          : 'Search for someone to share Moments with.',
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
                          onTap: () => context.push('/user/${user.id}', extra: user),
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
                                  radius: 24,
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
                                          fontWeight: FontWeight.w700,
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
                                  color: Colors.grey,
                                  size: 20,
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
                error: (err, _) => ZyloEmptyState(
                  title: 'Unable to search',
                  subtitle: 'Error: $err',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
