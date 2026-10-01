import 'user.dart';
import 'message.dart';

class Conversation {
  final String id;
  final List<User> participants;
  final User? otherParticipant;
  final Message? lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;
  final DateTime? createdAt;

  Conversation({
    required this.id,
    required this.participants,
    this.otherParticipant,
    this.lastMessage,
    required this.lastMessageAt,
    this.unreadCount = 0,
    this.createdAt,
  });

  /// Reliable name of the other user in this conversation.
  /// Never returns 'Zylo Contact'.
  String get otherUserName {
    if (otherParticipant != null) {
      return otherParticipant!.resolvedName;
    }
    if (participants.isNotEmpty) {
      return participants.last.resolvedName;
    }
    return 'User';
  }

  /// ID of the other participant if available
  String? get otherUserId {
    return otherParticipant?.id ?? (participants.isNotEmpty ? participants.last.id : null);
  }

  factory Conversation.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    List<User> participantsList = [];
    if (json['participants'] is List) {
      for (final p in json['participants'] as List) {
        if (p is Map) {
          participantsList.add(User.fromJson(Map<String, dynamic>.from(p)));
        } else if (p is String && p.isNotEmpty) {
          participantsList.add(User(
            id: p,
            username: '',
            displayName: '',
            email: '',
          ));
        }
      }
    }

    User? other;
    if (json['otherParticipant'] is Map) {
      other = User.fromJson(Map<String, dynamic>.from(json['otherParticipant']));
    } else if (json['otherParticipant'] is String && (json['otherParticipant'] as String).isNotEmpty) {
      final otherId = json['otherParticipant'] as String;
      try {
        other = participantsList.firstWhere((p) => p.id == otherId);
      } catch (_) {
        other = User(id: otherId, username: '', displayName: '', email: '');
      }
    } else if (currentUserId != null && participantsList.isNotEmpty) {
      try {
        other = participantsList.firstWhere((p) => p.id != currentUserId);
      } catch (_) {
        other = participantsList.first;
      }
    } else if (participantsList.isNotEmpty) {
      other = participantsList.first;
    }

    Message? lastMsg;
    if (json['lastMessage'] is Map) {
      lastMsg = Message.fromJson(Map<String, dynamic>.from(json['lastMessage']));
    }

    int resolvedUnread = 0;
    if (json['unreadCount'] is int) {
      resolvedUnread = json['unreadCount'] as int;
    } else if (json['unreadCounts'] is Map && currentUserId != null) {
      final countsMap = json['unreadCounts'] as Map;
      final val = countsMap[currentUserId];
      if (val is int) resolvedUnread = val;
    }

    return Conversation(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      participants: participantsList,
      otherParticipant: other,
      lastMessage: lastMsg,
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.tryParse(json['lastMessageAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      unreadCount: resolvedUnread,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Conversation copyWith({
    String? id,
    List<User>? participants,
    User? otherParticipant,
    Message? lastMessage,
    DateTime? lastMessageAt,
    int? unreadCount,
    DateTime? createdAt,
  }) {
    return Conversation(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      otherParticipant: otherParticipant ?? this.otherParticipant,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
