import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/moment.dart';
import '../models/moment_shortcut.dart';
import '../services/moment_service.dart';
import 'auth_provider.dart';

final momentServiceProvider = Provider<MomentService>((ref) {
  final client = ref.watch(apiClientProvider);
  return MomentService(apiClient: client);
});

class MomentsState {
  final bool isLoading;
  final List<Moment> moments;
  final String? error;

  const MomentsState({
    this.isLoading = false,
    this.moments = const [],
    this.error,
  });

  MomentsState copyWith({
    bool? isLoading,
    List<Moment>? moments,
    String? error,
  }) {
    return MomentsState(
      isLoading: isLoading ?? this.isLoading,
      moments: moments ?? this.moments,
      error: error,
    );
  }
}

class MomentsNotifier extends StateNotifier<MomentsState> {
  final MomentService _service;

  MomentsNotifier(this._service) : super(const MomentsState()) {
    loadMoments();
  }

  Future<void> loadMoments() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final list = await _service.getMyMoments();
      state = state.copyWith(isLoading: false, moments: list);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<Moment> startMoment(String targetUserId) async {
    final newMoment = await _service.startMoment(targetUserId);
    await loadMoments();
    return newMoment;
  }

  Future<void> endMoment(String momentId) async {
    await _service.endMoment(momentId);
    state = state.copyWith(
      moments: state.moments.where((m) => m.id != momentId).toList(),
    );
  }
}

final momentsProvider =
    StateNotifierProvider<MomentsNotifier, MomentsState>((ref) {
  final service = ref.watch(momentServiceProvider);
  return MomentsNotifier(service);
});

final momentWithUserProvider =
    FutureProvider.family<Moment?, String>((ref, userId) async {
  final service = ref.watch(momentServiceProvider);
  return service.getMomentWithUser(userId);
});

// --- SHORTCUTS PROVIDER ---

class ShortcutsNotifier extends StateNotifier<AsyncValue<List<MomentShortcut>>> {
  final MomentService _service;

  ShortcutsNotifier(this._service) : super(const AsyncValue.loading()) {
    loadShortcuts();
  }

  Future<void> loadShortcuts() async {
    try {
      final list = await _service.getShortcuts();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<MomentShortcut> createShortcut({
    required String name,
    String emoji = '✨',
    List<String> contactIds = const [],
  }) async {
    final created = await _service.createShortcut(
      name: name,
      emoji: emoji,
      contactIds: contactIds,
    );
    await loadShortcuts();
    return created;
  }

  Future<void> deleteShortcut(String id) async {
    await _service.deleteShortcut(id);
    await loadShortcuts();
  }
}

final shortcutsProvider =
    StateNotifierProvider<ShortcutsNotifier, AsyncValue<List<MomentShortcut>>>((ref) {
  final service = ref.watch(momentServiceProvider);
  return ShortcutsNotifier(service);
});
