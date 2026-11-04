import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../repositories/chat_repository.dart';
import '../services/chat_service.dart';
import '../services/socket_service.dart';
import 'auth_provider.dart';

final chatServiceProvider = Provider<ChatService>((ref) {
  final client = ref.watch(apiClientProvider);
  return ChatService(apiClient: client);
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(
    chatService: ref.watch(chatServiceProvider),
    socketService: ref.watch(socketServiceProvider),
  );
});

// Conversations List State
class ConversationsState {
  final bool isLoading;
  final List<Conversation> conversations;
  final String? error;

  const ConversationsState({
    this.isLoading = false,
    this.conversations = const [],
    this.error,
  });

  ConversationsState copyWith({
    bool? isLoading,
    List<Conversation>? conversations,
    String? error,
  }) {
    return ConversationsState(
      isLoading: isLoading ?? this.isLoading,
      conversations: conversations ?? this.conversations,
      error: error,
    );
  }
}

class ConversationsNotifier extends StateNotifier<ConversationsState> {
  final ChatRepository repository;
  final SocketService socketService;
  final String? currentUserId;
  StreamSubscription? _msgSub;
  StreamSubscription? _convSub;
  StreamSubscription? _presenceSub;

  ConversationsNotifier({
    required this.repository,
    required this.socketService,
    required this.currentUserId,
  }) : super(const ConversationsState()) {
    if (currentUserId != null) {
      loadConversations();
      _listenToSocket();
    }
  }

  void _listenToSocket() {
    _msgSub = socketService.onNewMessage.listen((msg) {
      _handleIncomingMessage(msg);
    });

    _convSub = socketService.onConversationUpdated.listen((data) {
      loadConversations(showLoading: false);
    });

    _presenceSub = socketService.onPresenceUpdate.listen((data) {
      final userId = data['userId'];
      final isOnline = data['isOnline'] ?? false;
      final lastSeen = data['lastSeen'] != null ? DateTime.tryParse(data['lastSeen']) : null;

      final updated = state.conversations.map((conv) {
        if (conv.otherParticipant?.id == userId) {
          final updatedOther = conv.otherParticipant!.copyWith(
            isOnline: isOnline,
            lastSeen: lastSeen,
          );
          return conv.copyWith(otherParticipant: updatedOther);
        }
        return conv;
      }).toList();

      state = state.copyWith(conversations: updated);
    });
  }

  void _handleIncomingMessage(Message msg) {
    final list = List<Conversation>.from(state.conversations);
    final index = list.indexWhere((c) => c.id == msg.conversationId);

    if (index != -1) {
      final current = list[index];
      final isFromMe = msg.senderId == currentUserId;
      final newUnread = isFromMe ? current.unreadCount : current.unreadCount + 1;

      final updated = current.copyWith(
        lastMessage: msg,
        lastMessageAt: msg.createdAt,
        unreadCount: newUnread,
      );

      list.removeAt(index);
      list.insert(0, updated);
      state = state.copyWith(conversations: list);
    } else {
      // New conversation initiated
      loadConversations(showLoading: false);
    }
  }

  Future<void> loadConversations({bool showLoading = true}) async {
    if (currentUserId == null) return;
    if (showLoading) state = state.copyWith(isLoading: true);
    try {
      final conversations = await repository.getConversations(currentUserId!);
      state = state.copyWith(isLoading: false, conversations: conversations);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<Conversation> startConversation(String participantId) async {
    if (currentUserId == null) throw Exception('Not authenticated');
    final conv = await repository.getOrCreateConversation(participantId, currentUserId!);
    await loadConversations(showLoading: false);
    return conv;
  }

  @override
  void dispose() {
    _msgSub?.cancel();
    _convSub?.cancel();
    _presenceSub?.cancel();
    super.dispose();
  }
}

final conversationsProvider =
    StateNotifierProvider<ConversationsNotifier, ConversationsState>((ref) {
  final user = ref.watch(authProvider).user;
  return ConversationsNotifier(
    repository: ref.watch(chatRepositoryProvider),
    socketService: ref.watch(socketServiceProvider),
    currentUserId: user?.id,
  );
});

final singleConversationProvider =
    FutureProvider.family<Conversation, String>((ref, conversationId) async {
  final user = ref.watch(authProvider).user;
  if (user == null) throw Exception('Not authenticated');
  final repo = ref.watch(chatRepositoryProvider);
  return repo.getConversation(conversationId, user.id);
});

// Single Conversation Messages State
class MessagesState {
  final bool isLoading;
  final bool isLoadingMore;
  final List<Message> messages;
  final String? nextCursor;
  final bool hasMore;
  final bool isOtherTyping;
  final String? error;

  const MessagesState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.messages = const [],
    this.nextCursor,
    this.hasMore = false,
    this.isOtherTyping = false,
    this.error,
  });

  MessagesState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    List<Message>? messages,
    String? nextCursor,
    bool? hasMore,
    bool? isOtherTyping,
    String? error,
  }) {
    return MessagesState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      messages: messages ?? this.messages,
      nextCursor: nextCursor ?? this.nextCursor,
      hasMore: hasMore ?? this.hasMore,
      isOtherTyping: isOtherTyping ?? this.isOtherTyping,
      error: error,
    );
  }
}

class MessagesNotifier extends StateNotifier<MessagesState> {
  final String conversationId;
  final ChatRepository repository;
  final SocketService socketService;
  final String? currentUserId;

  StreamSubscription? _msgSub;
  StreamSubscription? _statusSub;
  StreamSubscription? _typingSub;
  StreamSubscription? _delSub;
  Timer? _typingTimeoutTimer;

  MessagesNotifier({
    required this.conversationId,
    required this.repository,
    required this.socketService,
    required this.currentUserId,
  }) : super(const MessagesState()) {
    _init();
  }

  void _init() {
    socketService.joinConversation(conversationId);
    loadInitialMessages();
    _listenSocket();
  }

  void _listenSocket() {
    _msgSub = socketService.onNewMessage.listen((msg) {
      if (msg.conversationId == conversationId) {
        // Replace temp optimistic message if tempId matches
        final list = List<Message>.from(state.messages);
        final tempIdx = msg.tempId != null ? list.indexWhere((m) => m.tempId == msg.tempId) : -1;

        if (tempIdx != -1) {
          list[tempIdx] = msg;
        } else {
          final exists = list.any((m) => m.id == msg.id);
          if (!exists) {
            list.insert(0, msg);
          }
        }

        state = state.copyWith(messages: list);

        // If from other participant, emit delivered & read
        if (msg.senderId != currentUserId) {
          repository.markDelivered(msg.id, conversationId);
          repository.markRead(msg.id, conversationId);
        }
      }
    });

    _statusSub = socketService.onMessageStatusUpdated.listen((data) {
      if (data['conversationId'] == conversationId) {
        final messageId = data['messageId'];
        final statusStr = data['status'];
        final status = MessageStatus.fromString(statusStr);

        final updated = state.messages.map((m) {
          if (m.id == messageId) {
            return m.copyWith(status: status);
          }
          return m;
        }).toList();

        state = state.copyWith(messages: updated);
      }
    });

    _typingSub = socketService.onTyping.listen((data) {
      if (data['conversationId'] == conversationId) {
        final userId = data['userId'];
        if (userId != currentUserId) {
          final isTyping = data['isTyping'] ?? false;
          state = state.copyWith(isOtherTyping: isTyping);

          if (isTyping) {
            _typingTimeoutTimer?.cancel();
            _typingTimeoutTimer = Timer(const Duration(seconds: 4), () {
              state = state.copyWith(isOtherTyping: false);
            });
          }
        }
      }
    });

    _delSub = socketService.onMessageDeleted.listen((data) {
      if (data['conversationId'] == conversationId) {
        final messageId = data['messageId'];
        final updated = state.messages.map((m) {
          if (m.id == messageId) {
            return m.copyWith(
              isDeleted: true,
              content: 'This message was deleted',
              mediaUrl: '',
            );
          }
          return m;
        }).toList();

        state = state.copyWith(messages: updated);
      }
    });
  }

  Future<void> loadInitialMessages() async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await repository.getMessages(conversationId: conversationId);
      state = state.copyWith(
        isLoading: false,
        messages: res.messages,
        nextCursor: res.nextCursor,
        hasMore: res.hasMore,
      );

      // Mark unread messages as read
      for (final m in res.messages) {
        if (m.senderId != currentUserId && m.status != MessageStatus.read) {
          repository.markRead(m.id, conversationId);
        }
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMoreMessages() async {
    if (state.isLoadingMore || !state.hasMore || state.nextCursor == null) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final res = await repository.getMessages(
        conversationId: conversationId,
        cursor: state.nextCursor,
      );
      state = state.copyWith(
        isLoadingMore: false,
        messages: [...state.messages, ...res.messages],
        nextCursor: res.nextCursor,
        hasMore: res.hasMore,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  Future<void> sendMessage({
    required MessageType type,
    String? content,
    String? mediaUrl,
    MediaMetadata? mediaMetadata,
    Message? replyTo,
  }) async {
    if (currentUserId == null) return;

    final tempId = const Uuid().v4();
    final optimisticMsg = Message(
      id: tempId,
      conversationId: conversationId,
      senderId: currentUserId!,
      type: type,
      content: content ?? '',
      mediaUrl: mediaUrl,
      mediaMetadata: mediaMetadata,
      replyTo: replyTo,
      status: MessageStatus.sending,
      createdAt: DateTime.now(),
      tempId: tempId,
    );

    state = state.copyWith(messages: [optimisticMsg, ...state.messages]);

    // Send over socket for realtime propagation
    repository.sendRealtimeMessage(
      conversationId: conversationId,
      type: type.toServerString(),
      content: content,
      mediaUrl: mediaUrl,
      mediaMetadata: mediaMetadata?.toJson(),
      replyToId: replyTo?.id,
      tempId: tempId,
    );
  }

  void startTyping() {
    repository.sendTypingStart(conversationId);
  }

  void stopTyping() {
    repository.sendTypingStop(conversationId);
  }

  Future<void> deleteMessage(String messageId) async {
    await repository.deleteMessage(messageId, conversationId);
  }

  @override
  void dispose() {
    socketService.leaveConversation(conversationId);
    _msgSub?.cancel();
    _statusSub?.cancel();
    _typingSub?.cancel();
    _delSub?.cancel();
    _typingTimeoutTimer?.cancel();
    super.dispose();
  }
}

final messagesProvider =
    StateNotifierProvider.family<MessagesNotifier, MessagesState, String>(
        (ref, conversationId) {
  final user = ref.watch(authProvider).user;
  return MessagesNotifier(
    conversationId: conversationId,
    repository: ref.watch(chatRepositoryProvider),
    socketService: ref.watch(socketServiceProvider),
    currentUserId: user?.id,
  );
});
