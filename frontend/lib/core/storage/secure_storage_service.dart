import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _accessTokenKey = 'zylo_access_token';
  static const String _refreshTokenKey = 'zylo_refresh_token';
  static const String _userIdKey = 'zylo_user_id';
  static const String _userJsonKey = 'zylo_user_json';

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  Future<void> saveUserData({required String userId, required String userJson}) async {
    await _storage.write(key: _userIdKey, value: userId);
    await _storage.write(key: _userJsonKey, value: userJson);
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  Future<String?> getUserJson() async {
    return await _storage.read(key: _userJsonKey);
  }

  Future<void> clearAuth() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _userJsonKey);
  }
}
