import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/user.dart';

class UserService {
  final ApiClient apiClient;

  UserService({required this.apiClient});

  Future<List<User>> searchUsers([String? query]) async {
    final response = await apiClient.dio.get(
      ApiConstants.searchUsers,
      queryParameters: query != null && query.isNotEmpty ? {'q': query} : null,
    );
    final data = response.data as List;
    return data.map((json) => User.fromJson(Map<String, dynamic>.from(json))).toList();
  }

  Future<User> getMe() async {
    final response = await apiClient.dio.get(ApiConstants.me);
    return User.fromJson(response.data);
  }

  Future<User> updateMe({
    String? displayName,
    String? bio,
    String? profilePhoto,
  }) async {
    final response = await apiClient.dio.patch(
      ApiConstants.me,
      data: {
        if (displayName != null) 'displayName': displayName,
        if (bio != null) 'bio': bio,
        if (profilePhoto != null) 'profilePhoto': profilePhoto,
      },
    );
    return User.fromJson(response.data);
  }

  Future<User> getUser(String id) async {
    final response = await apiClient.dio.get(ApiConstants.user(id));
    return User.fromJson(response.data);
  }

  Future<void> blockUser(String id) async {
    await apiClient.dio.post(ApiConstants.blockUser(id));
  }

  Future<void> unblockUser(String id) async {
    await apiClient.dio.delete(ApiConstants.blockUser(id));
  }
}
