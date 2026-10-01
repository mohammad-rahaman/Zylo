import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../providers/auth_provider.dart';

final uploadServiceProvider = Provider<UploadService>((ref) {
  final client = ref.watch(apiClientProvider);
  return UploadService(apiClient: client);
});

class UploadService {
  final ApiClient apiClient;

  UploadService({required this.apiClient});

  Future<Map<String, dynamic>> uploadFile({
    required String filePath,
    required String fileName,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });

    final response = await apiClient.dio.post(
      ApiConstants.uploads,
      data: formData,
    );

    return Map<String, dynamic>.from(response.data);
  }

  Future<Map<String, dynamic>> uploadBytes({
    required List<int> bytes,
    required String fileName,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: fileName),
    });

    final response = await apiClient.dio.post(
      ApiConstants.uploads,
      data: formData,
    );

    return Map<String, dynamic>.from(response.data);
  }
}
