import 'dart:convert';
import '../core/storage/secure_storage_service.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class AuthRepository {
  final AuthService authService;
  final UserService userService;
  final SecureStorageService storageService;

  AuthRepository({
    required this.authService,
    required this.userService,
    required this.storageService,
  });

  Future<User?> checkAuth() async {
    final token = await storageService.getAccessToken();
    if (token == null || token.isEmpty) {
      return null;
    }

    try {
      // First verify stored user cached json
      final cachedJson = await storageService.getUserJson();
      if (cachedJson != null) {
        // Fetch fresh profile in background
        userService.getMe().then((freshUser) {
          storageService.saveUserData(
            userId: freshUser.id,
            userJson: jsonEncode(freshUser.toJson()),
          );
        }).catchError((_) {});
        return User.fromJson(jsonDecode(cachedJson));
      }

      final freshUser = await userService.getMe();
      await storageService.saveUserData(
        userId: freshUser.id,
        userJson: jsonEncode(freshUser.toJson()),
      );
      return freshUser;
    } catch (_) {
      // Token might be expired or invalid
      await storageService.clearAuth();
      return null;
    }
  }

  Future<User> register({
    required String username,
    required String displayName,
    required String email,
    required String password,
  }) async {
    final result = await authService.register(
      username: username,
      displayName: displayName,
      email: email,
      password: password,
    );

    await storageService.saveTokens(
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
    );
    await storageService.saveUserData(
      userId: result.user.id,
      userJson: jsonEncode(result.user.toJson()),
    );

    return result.user;
  }

  Future<User> login({
    required String login,
    required String password,
  }) async {
    final result = await authService.login(
      login: login,
      password: password,
    );

    await storageService.saveTokens(
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
    );
    await storageService.saveUserData(
      userId: result.user.id,
      userJson: jsonEncode(result.user.toJson()),
    );

    return result.user;
  }

  Future<void> logout() async {
    final refreshToken = await storageService.getRefreshToken();
    await authService.logout(refreshToken);
    await storageService.clearAuth();
  }
}
