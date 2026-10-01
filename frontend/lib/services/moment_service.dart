import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/moment.dart';
import '../models/moment_shortcut.dart';

class SendMomentResult {
  final bool success;
  final String mediaUrl;
  final List<RecipientSendStatus> results;

  const SendMomentResult({
    required this.success,
    required this.mediaUrl,
    required this.results,
  });

  factory SendMomentResult.fromJson(Map<String, dynamic> json) {
    final list = (json['results'] as List<dynamic>?)
            ?.map((e) => RecipientSendStatus.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return SendMomentResult(
      success: json['success'] ?? false,
      mediaUrl: json['mediaUrl'] ?? '',
      results: list,
    );
  }
}

class RecipientSendStatus {
  final String recipientId;
  final bool success;
  final Moment? moment;
  final String? error;

  const RecipientSendStatus({
    required this.recipientId,
    required this.success,
    this.moment,
    this.error,
  });

  factory RecipientSendStatus.fromJson(Map<String, dynamic> json) {
    return RecipientSendStatus(
      recipientId: json['recipientId'] ?? '',
      success: json['success'] ?? false,
      moment: json['moment'] != null
          ? Moment.fromJson(json['moment'] as Map<String, dynamic>)
          : null,
      error: json['error'],
    );
  }
}

class MomentService {
  final ApiClient apiClient;

  MomentService({required this.apiClient});

  Future<List<Moment>> getMyMoments() async {
    final response = await apiClient.get(ApiConstants.moments);
    final list = response.data as List;
    return list.map((item) => Moment.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<Moment?> getMomentWithUser(String userId) async {
    try {
      final response = await apiClient.get(ApiConstants.momentWithUser(userId));
      if (response.data == null) return null;
      return Moment.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<Moment> startMoment(String targetUserId) async {
    final response = await apiClient.post(
      ApiConstants.moments,
      data: {'targetUserId': targetUserId},
    );
    return Moment.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> endMoment(String momentId) async {
    await apiClient.delete(ApiConstants.endMoment(momentId));
  }

  /// Dispatches one uploaded media asset to multiple recipients independently
  Future<SendMomentResult> sendMoment({
    required String mediaUrl,
    required List<String> recipientIds,
    String? caption,
    String? filter,
  }) async {
    final response = await apiClient.post(
      ApiConstants.sendMoment,
      data: {
        'mediaUrl': mediaUrl,
        'recipientIds': recipientIds,
        if (caption != null && caption.trim().isNotEmpty) 'caption': caption.trim(),
        if (filter != null) 'filter': filter,
      },
    );
    return SendMomentResult.fromJson(response.data as Map<String, dynamic>);
  }

  // --- SHORTCUTS API ---

  Future<List<MomentShortcut>> getShortcuts() async {
    try {
      final response = await apiClient.get(ApiConstants.momentShortcuts);
      final list = response.data as List;
      return list
          .map((item) => MomentShortcut.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<MomentShortcut> createShortcut({
    required String name,
    String emoji = '✨',
    List<String> contactIds = const [],
  }) async {
    final response = await apiClient.post(
      ApiConstants.momentShortcuts,
      data: {
        'name': name.trim(),
        'emoji': emoji,
        'contactIds': contactIds,
      },
    );
    return MomentShortcut.fromJson(response.data as Map<String, dynamic>);
  }

  Future<MomentShortcut> updateShortcut({
    required String id,
    String? name,
    String? emoji,
    List<String>? contactIds,
  }) async {
    final response = await apiClient.patch(
      ApiConstants.momentShortcut(id),
      data: {
        if (name != null) 'name': name.trim(),
        if (emoji != null) 'emoji': emoji,
        if (contactIds != null) 'contactIds': contactIds,
      },
    );
    return MomentShortcut.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteShortcut(String id) async {
    await apiClient.delete(ApiConstants.momentShortcut(id));
  }
}
