import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_client.dart';
import '../core/storage/secure_storage_service.dart';
import '../models/user.dart';
import '../repositories/auth_repository.dart';
import '../services/auth_service.dart';
import '../services/socket_service.dart';
import '../services/user_service.dart';

// Foundation Providers
final storageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return ApiClient(storageService: storage);
});

final socketServiceProvider = Provider<SocketService>((ref) {
  final socket = SocketService();
  ref.onDispose(() => socket.dispose());
  return socket;
});

final authServiceProvider = Provider<AuthService>((ref) {
  final client = ref.watch(apiClientProvider);
  return AuthService(apiClient: client);
});

final userServiceProvider = Provider<UserService>((ref) {
  final client = ref.watch(apiClientProvider);
  return UserService(apiClient: client);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    authService: ref.watch(authServiceProvider),
    userService: ref.watch(userServiceProvider),
    storageService: ref.watch(storageServiceProvider),
  );
});

// Auth State Definition
enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository repository;
  final SocketService socketService;
  final SecureStorageService storageService;

  AuthNotifier({
    required this.repository,
    required this.socketService,
    required this.storageService,
    ApiClient? apiClient,
  }) : super(const AuthState()) {
    apiClient?.onUnauthorized = handleSessionExpired;
    checkAuth();
  }

  Future<void> checkAuth() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final user = await repository.checkAuth();
      if (user != null) {
        final token = await storageService.getAccessToken();
        if (token != null) {
          socketService.connect(token);
        }
        state = state.copyWith(status: AuthStatus.authenticated, user: user);
      } else {
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      );
    }
  }

  Future<bool> login(String login, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await repository.login(login: login, password: password);
      final token = await storageService.getAccessToken();
      if (token != null) {
        socketService.connect(token);
      }
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> register({
    required String username,
    required String displayName,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await repository.register(
        username: username,
        displayName: displayName,
        email: email,
        password: password,
      );
      final token = await storageService.getAccessToken();
      if (token != null) {
        socketService.connect(token);
      }
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(status: AuthStatus.loading);
    await repository.logout();
    socketService.disconnect();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void handleSessionExpired() {
    socketService.disconnect();
    state = const AuthState(
      status: AuthStatus.unauthenticated,
      errorMessage: 'Your session has expired. Please log in again.',
    );
  }

  void updateUser(User updatedUser) {
    state = state.copyWith(user: updatedUser);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    repository: ref.watch(authRepositoryProvider),
    socketService: ref.watch(socketServiceProvider),
    storageService: ref.watch(storageServiceProvider),
    apiClient: ref.watch(apiClientProvider),
  );
});
