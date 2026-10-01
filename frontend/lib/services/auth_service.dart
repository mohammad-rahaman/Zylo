import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/user.dart';

class AuthResult {
  final String accessToken;
  final String refreshToken;
  final User user;

  AuthResult({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      accessToken: json['accessToken'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
      user: User.fromJson(json['user']),
    );
  }
}

class AuthService {
  final ApiClient apiClient;

  AuthService({required this.apiClient});

  Future<AuthResult> register({
    required String username,
    required String displayName,
    required String email,
    required String password,
  }) async {
    final response = await apiClient.dio.post(
      ApiConstants.register,
      data: {
        'username': username,
        'displayName': displayName,
        'email': email,
        'password': password,
      },
    );
    return AuthResult.fromJson(response.data);
  }

  Future<AuthResult> login({
    required String login,
    required String password,
  }) async {
    final response = await apiClient.dio.post(
      ApiConstants.login,
      data: {
        'login': login,
        'password': password,
      },
    );
    return AuthResult.fromJson(response.data);
  }

  Future<AuthResult> refresh(String refreshToken) async {
    final response = await apiClient.dio.post(
      ApiConstants.refresh,
      data: {'refreshToken': refreshToken},
    );
    return AuthResult.fromJson(response.data);
  }

  Future<void> logout([String? refreshToken]) async {
    try {
      await apiClient.dio.post(
        ApiConstants.logout,
        data: refreshToken != null ? {'refreshToken': refreshToken} : {},
      );
    } catch (_) {}
  }
}
