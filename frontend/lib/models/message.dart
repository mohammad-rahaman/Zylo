enum MessageType {
  text,
  image,
  video,
  file,
  system;

  static MessageType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'image':
        return MessageType.image;
      case 'video':
        return MessageType.video;
      case 'file':
        return MessageType.file;
      case 'system':
        return MessageType.system;
      case 'text':
      default:
        return MessageType.text;
    }
  }

  String toServerString() {
    return name;
  }
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed;

  static MessageStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'read':
        return MessageStatus.read;
      case 'delivered':
        return MessageStatus.delivered;
      case 'sending':
        return MessageStatus.sending;
      case 'failed':
        return MessageStatus.failed;
      case 'sent':
      default:
        return MessageStatus.sent;
    }
  }

  String toServerString() {
    return name;
  }
}

class MediaMetadata {
  final String? fileName;
  final int? fileSize;
  final String? mimeType;
  final int? duration;
  final int? width;
  final int? height;

  MediaMetadata({
    this.fileName,
    this.fileSize,
    this.mimeType,
    this.duration,
    this.width,
    this.height,
  });

  factory MediaMetadata.fromJson(Map<String, dynamic> json) {
    return MediaMetadata(
      fileName: json['fileName'],
      fileSize: json['fileSize'],
      mimeType: json['mimeType'],
      duration: json['duration'],
      width: json['width'],
      height: json['height'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fileName': fileName,
      'fileSize': fileSize,
      'mimeType': mimeType,
      'duration': duration,
      'width': width,
      'height': height,
    };
  }
}

class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final MessageType type;
  final String content;
  final String? mediaUrl;
  final MediaMetadata? mediaMetadata;
  final Message? replyTo;
  final MessageStatus status;
  final bool isDeleted;
  final DateTime createdAt;
  final String? tempId;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.type,
    required this.content,
    this.mediaUrl,
    this.mediaMetadata,
    this.replyTo,
    this.status = MessageStatus.sent,
    this.isDeleted = false,
    required this.createdAt,
    this.tempId,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    final senderObj = json['senderId'];
    final sId = senderObj is Map ? (senderObj['_id'] ?? senderObj['id'] ?? '') : (senderObj ?? '');

    return Message(
      id: json['id'] ?? json['_id'] ?? '',
      conversationId: json['conversationId'] is Map
          ? (json['conversationId']['_id'] ?? json['conversationId']['id'] ?? '')
          : (json['conversationId'] ?? ''),
      senderId: sId.toString(),
      type: MessageType.fromString(json['type'] ?? 'text'),
      content: json['content'] ?? '',
      mediaUrl: json['mediaUrl'],
      mediaMetadata: json['mediaMetadata'] != null
          ? MediaMetadata.fromJson(Map<String, dynamic>.from(json['mediaMetadata']))
          : null,
      replyTo: json['replyToId'] is Map
          ? Message.fromJson(Map<String, dynamic>.from(json['replyToId']))
          : null,
      status: MessageStatus.fromString(json['status'] ?? 'sent'),
      isDeleted: json['isDeleted'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      tempId: json['tempId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'type': type.toServerString(),
      'content': content,
      'mediaUrl': mediaUrl,
      'mediaMetadata': mediaMetadata?.toJson(),
      'replyToId': replyTo?.id,
      'status': status.toServerString(),
      'isDeleted': isDeleted,
      'createdAt': createdAt.toIso8601String(),
      'tempId': tempId,
    };
  }

  Message copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    MessageType? type,
    String? content,
    String? mediaUrl,
    MediaMetadata? mediaMetadata,
    Message? replyTo,
    MessageStatus? status,
    bool? isDeleted,
    DateTime? createdAt,
    String? tempId,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      type: type ?? this.type,
      content: content ?? this.content,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaMetadata: mediaMetadata ?? this.mediaMetadata,
      replyTo: replyTo ?? this.replyTo,
      status: status ?? this.status,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      tempId: tempId ?? this.tempId,
    );
  }
}
