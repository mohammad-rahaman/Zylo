import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import 'auth_provider.dart';

final userSearchProvider =
    FutureProvider.family<List<User>, String>((ref, query) async {
  final userService = ref.watch(userServiceProvider);
  return userService.searchUsers(query);
});

final userProfileProvider =
    FutureProvider.family<User, String>((ref, userId) async {
  final userService = ref.watch(userServiceProvider);
  return userService.getUser(userId);
});

class ProfileController extends StateNotifier<AsyncValue<void>> {
  final UserService userService;
  final Ref ref;

  ProfileController({required this.userService, required this.ref})
      : super(const AsyncValue.data(null));

  Future<bool> updateProfile({
    String? displayName,
    String? bio,
    String? profilePhoto,
  }) async {
    state = const AsyncValue.loading();
    try {
      final updatedUser = await userService.updateMe(
        displayName: displayName,
        bio: bio,
        profilePhoto: profilePhoto,
      );
      ref.read(authProvider.notifier).updateUser(updatedUser);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> blockUser(String userId) async {
    try {
      await userService.blockUser(userId);
      ref.invalidate(userProfileProvider(userId));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> unblockUser(String userId) async {
    try {
      await userService.unblockUser(userId);
      ref.invalidate(userProfileProvider(userId));
      return true;
    } catch (_) {
      return false;
    }
  }
}

final profileControllerProvider =
    StateNotifierProvider<ProfileController, AsyncValue<void>>((ref) {
  return ProfileController(
    userService: ref.watch(userServiceProvider),
    ref: ref,
  );
});
