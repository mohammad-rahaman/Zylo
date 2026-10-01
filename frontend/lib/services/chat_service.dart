import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/conversation.dart';
import '../models/message.dart';

class PaginatedMessages {
  final List<Message> messages;
  final String? nextCursor;
  final bool hasMore;

  PaginatedMessages({
    required this.messages,
    this.nextCursor,
    required this.hasMore,
  });

  factory PaginatedMessages.fromJson(Map<String, dynamic> json) {
    final list = (json['messages'] as List? ?? [])
        .map((m) => Message.fromJson(Map<String, dynamic>.from(m)))
        .toList();
    return PaginatedMessages(
      messages: list,
      nextCursor: json['nextCursor'],
      hasMore: json['hasMore'] ?? false,
    );
  }
}

class ChatService {
  final ApiClient apiClient;

  ChatService({required this.apiClient});

  Future<List<Conversation>> getConversations(String currentUserId) async {
    final response = await apiClient.dio.get(ApiConstants.conversations);
    final data = response.data as List;
    return data
        .map((json) => Conversation.fromJson(Map<String, dynamic>.from(json), currentUserId: currentUserId))
        .toList();
  }

  Future<Conversation> createConversation(String participantId, String currentUserId) async {
    final response = await apiClient.dio.post(
      ApiConstants.conversations,
      data: {'participantId': participantId},
    );
    return Conversation.fromJson(response.data, currentUserId: currentUserId);
  }

  Future<Conversation> getConversation(String id, String currentUserId) async {
    final response = await apiClient.dio.get(ApiConstants.conversation(id));
    return Conversation.fromJson(response.data, currentUserId: currentUserId);
  }

  Future<void> deleteConversation(String id) async {
    await apiClient.dio.delete(ApiConstants.conversation(id));
  }

  Future<PaginatedMessages> getMessages({
    required String conversationId,
    String? cursor,
    int limit = 30,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{'limit': limit};
    if (cursor != null) queryParams['cursor'] = cursor;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final response = await apiClient.dio.get(
      ApiConstants.conversationMessages(conversationId),
      queryParameters: queryParams,
    );
    return PaginatedMessages.fromJson(response.data);
  }

  Future<Message> sendMessage({
    required String conversationId,
    required MessageType type,
    String? content,
    String? mediaUrl,
    MediaMetadata? mediaMetadata,
    String? replyToId,
  }) async {
    final response = await apiClient.dio.post(
      ApiConstants.conversationMessages(conversationId),
      data: {
        'type': type.toServerString(),
        'content': content,
        'mediaUrl': mediaUrl,
        'mediaMetadata': mediaMetadata?.toJson(),
        'replyToId': replyToId,
      },
    );
    return Message.fromJson(response.data);
  }

  Future<void> updateMessageStatus(String messageId, MessageStatus status) async {
    await apiClient.dio.patch(
      ApiConstants.message(messageId),
      data: {'status': status.toServerString()},
    );
  }

  Future<void> deleteMessage(String messageId) async {
    await apiClient.dio.delete(ApiConstants.message(messageId));
  }
}
