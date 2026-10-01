import 'package:flutter_test/flutter_test.dart';
import 'package:zylo/repositories/auth_repository.dart';
import 'package:zylo/services/auth_service.dart';
import 'package:zylo/services/user_service.dart';
import 'package:zylo/core/storage/secure_storage_service.dart';
import 'package:zylo/models/user.dart';

class MockAuthService implements AuthService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<AuthResult> register({
    required String username,
    required String displayName,
    required String email,
    required String password,
  }) async {
    return AuthResult(
      accessToken: 'test_access_token',
      refreshToken: 'test_refresh_token',
      user: User(
        id: 'u123',
        username: username,
        displayName: displayName,
        email: email,
      ),
    );
  }

  @override
  Future<AuthResult> login({
    required String login,
    required String password,
  }) async {
    return AuthResult(
      accessToken: 'login_access_token',
      refreshToken: 'login_refresh_token',
      user: User(
        id: 'u123',
        username: 'testuser',
        displayName: 'Test User',
        email: 'test@zylo.com',
      ),
    );
  }

  @override
  Future<void> logout([String? refreshToken]) async {}
}

class MockUserService implements UserService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<User> getMe() async {
    return User(
      id: 'u123',
      username: 'testuser',
      displayName: 'Test User',
      email: 'test@zylo.com',
    );
  }
}

class MockSecureStorageService implements SecureStorageService {
  final Map<String, String> _storage = {};

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    _storage['access'] = accessToken;
    _storage['refresh'] = refreshToken;
  }

  @override
  Future<String?> getAccessToken() async => _storage['access'];

  @override
  Future<String?> getRefreshToken() async => _storage['refresh'];

  @override
  Future<void> saveUserData({required String userId, required String userJson}) async {
    _storage['userId'] = userId;
    _storage['userJson'] = userJson;
  }

  @override
  Future<String?> getUserId() async => _storage['userId'];

  @override
  Future<String?> getUserJson() async => _storage['userJson'];

  @override
  Future<void> clearAuth() async => _storage.clear();
}

void main() {
  group('AuthRepository Unit Tests', () {
    late AuthRepository repository;
    late MockAuthService mockAuthService;
    late MockUserService mockUserService;
    late MockSecureStorageService mockStorageService;

  setUp(() {
    mockAuthService = MockAuthService();
    mockUserService = MockUserService();
    mockStorageService = MockSecureStorageService();

    repository = AuthRepository(
      authService: mockAuthService,
      userService: mockUserService,
      storageService: mockStorageService,
    );
  });

  test('register persists tokens and user data', () async {
    final user = await repository.register(
      username: 'johndoe',
      displayName: 'John Doe',
      email: 'john@zylo.com',
      password: 'Password123!',
    );

    expect(user.username, 'johndoe');
    expect(await mockStorageService.getAccessToken(), 'test_access_token');
    expect(await mockStorageService.getRefreshToken(), 'test_refresh_token');
    expect(await mockStorageService.getUserId(), 'u123');
  });

  test('login saves tokens and returns authenticated user', () async {
    final user = await repository.login(
      login: 'testuser',
      password: 'Password123!',
    );

    expect(user.username, 'testuser');
    expect(await mockStorageService.getAccessToken(), 'login_access_token');
  });

  test('logout clears tokens and cached user data', () async {
    await repository.login(login: 'testuser', password: 'Password123!');
    expect(await mockStorageService.getAccessToken(), isNotNull);

    await repository.logout();
    expect(await mockStorageService.getAccessToken(), isNull);
    expect(await mockStorageService.getUserId(), isNull);
  });
  });
}
