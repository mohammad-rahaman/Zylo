import '../models/conversation.dart';
import '../models/message.dart';
import '../services/chat_service.dart';
import '../services/socket_service.dart';

class ChatRepository {
  final ChatService chatService;
  final SocketService socketService;

  ChatRepository({
    required this.chatService,
    required this.socketService,
  });

  Future<List<Conversation>> getConversations(String currentUserId) {
    return chatService.getConversations(currentUserId);
  }

  Future<Conversation> getConversation(String id, String currentUserId) {
    return chatService.getConversation(id, currentUserId);
  }

  Future<Conversation> getOrCreateConversation(String participantId, String currentUserId) {
    return chatService.createConversation(participantId, currentUserId);
  }

  Future<PaginatedMessages> getMessages({
    required String conversationId,
    String? cursor,
    int limit = 30,
    String? search,
  }) {
    return chatService.getMessages(
      conversationId: conversationId,
      cursor: cursor,
      limit: limit,
      search: search,
    );
  }

  Future<Message> sendMessage({
    required String conversationId,
    required MessageType type,
    String? content,
    String? mediaUrl,
    MediaMetadata? mediaMetadata,
    String? replyToId,
  }) {
    return chatService.sendMessage(
      conversationId: conversationId,
      type: type,
      content: content,
      mediaUrl: mediaUrl,
      mediaMetadata: mediaMetadata,
      replyToId: replyToId,
    );
  }

  void sendRealtimeMessage({
    required String conversationId,
    required String type,
    String? content,
    String? mediaUrl,
    Map<String, dynamic>? mediaMetadata,
    String? replyToId,
    String? tempId,
  }) {
    socketService.sendMessage(
      conversationId: conversationId,
      type: type,
      content: content,
      mediaUrl: mediaUrl,
      mediaMetadata: mediaMetadata,
      replyToId: replyToId,
      tempId: tempId,
    );
  }

  Future<void> deleteMessage(String messageId, String conversationId) async {
    await chatService.deleteMessage(messageId);
    socketService.emitDeleteMessage(messageId, conversationId);
  }

  void markDelivered(String messageId, String conversationId) {
    socketService.emitDelivered(messageId, conversationId);
  }

  void markRead(String messageId, String conversationId) {
    socketService.emitRead(messageId, conversationId);
  }

  void sendTypingStart(String conversationId) {
    socketService.emitTypingStart(conversationId);
  }

  void sendTypingStop(String conversationId) {
    socketService.emitTypingStop(conversationId);
  }
}
