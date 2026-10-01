import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../core/constants/api_constants.dart';
import '../models/message.dart';

class SocketService {
  io.Socket? _socket;

  final _newMessageController = StreamController<Message>.broadcast();
  final _messageStatusController = StreamController<Map<String, dynamic>>.broadcast();
  final _typingController = StreamController<Map<String, dynamic>>.broadcast();
  final _presenceController = StreamController<Map<String, dynamic>>.broadcast();
  final _messageDeletedController = StreamController<Map<String, dynamic>>.broadcast();
  final _conversationUpdatedController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Message> get onNewMessage => _newMessageController.stream;
  Stream<Map<String, dynamic>> get onMessageStatusUpdated => _messageStatusController.stream;
  Stream<Map<String, dynamic>> get onTyping => _typingController.stream;
  Stream<Map<String, dynamic>> get onPresenceUpdate => _presenceController.stream;
  Stream<Map<String, dynamic>> get onMessageDeleted => _messageDeletedController.stream;
  Stream<Map<String, dynamic>> get onConversationUpdated => _conversationUpdatedController.stream;

  bool get isConnected => _socket?.connected ?? false;

  void connect(String accessToken) {
    if (_socket != null && _socket!.connected) return;

    _socket = io.io(
      ApiConstants.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .enableReconnection()
          .setAuth({'token': accessToken})
          .build(),
    );

    _socket!.onConnect((_) {
      debugPrint('[SocketService] Connected to realtime gateway');
    });

    _socket!.onDisconnect((_) {
      debugPrint('[SocketService] Disconnected from realtime gateway');
    });

    _socket!.onConnectError((err) {
      debugPrint('[SocketService] Connection error: $err');
    });

    _socket!.on('message:new', (data) {
      if (data is Map<String, dynamic>) {
        _newMessageController.add(Message.fromJson(data));
      } else if (data is Map) {
        _newMessageController.add(Message.fromJson(Map<String, dynamic>.from(data)));
      }
    });

    _socket!.on('message:status_updated', (data) {
      if (data is Map) {
        _messageStatusController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('typing:started', (data) {
      if (data is Map) {
        _typingController.add({'isTyping': true, ...Map<String, dynamic>.from(data)});
      }
    });

    _socket!.on('typing:stopped', (data) {
      if (data is Map) {
        _typingController.add({'isTyping': false, ...Map<String, dynamic>.from(data)});
      }
    });

    _socket!.on('presence:update', (data) {
      if (data is Map) {
        _presenceController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('message:deleted', (data) {
      if (data is Map) {
        _messageDeletedController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('conversation:updated', (data) {
      if (data is Map) {
        _conversationUpdatedController.add(Map<String, dynamic>.from(data));
      }
    });
  }

  void joinConversation(String conversationId) {
    _socket?.emit('conversation:join', {'conversationId': conversationId});
  }

  void leaveConversation(String conversationId) {
    _socket?.emit('conversation:leave', {'conversationId': conversationId});
  }

  void sendMessage({
    required String conversationId,
    required String type,
    String? content,
    String? mediaUrl,
    Map<String, dynamic>? mediaMetadata,
    String? replyToId,
    String? tempId,
  }) {
    _socket?.emit('message:send', {
      'conversationId': conversationId,
      'type': type,
      'content': content,
      'mediaUrl': mediaUrl,
      'mediaMetadata': mediaMetadata,
      'replyToId': replyToId,
      'tempId': tempId,
    });
  }

  void emitDelivered(String messageId, String conversationId) {
    _socket?.emit('message:delivered', {
      'messageId': messageId,
      'conversationId': conversationId,
    });
  }

  void emitRead(String messageId, String conversationId) {
    _socket?.emit('message:read', {
      'messageId': messageId,
      'conversationId': conversationId,
    });
  }

  void emitTypingStart(String conversationId) {
    _socket?.emit('typing:start', {'conversationId': conversationId});
  }

  void emitTypingStop(String conversationId) {
    _socket?.emit('typing:stop', {'conversationId': conversationId});
  }

  void emitDeleteMessage(String messageId, String conversationId) {
    _socket?.emit('message:delete', {
      'messageId': messageId,
      'conversationId': conversationId,
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  void dispose() {
    disconnect();
    _newMessageController.close();
    _messageStatusController.close();
    _typingController.close();
    _presenceController.close();
    _messageDeletedController.close();
    _conversationUpdatedController.close();
  }
}
