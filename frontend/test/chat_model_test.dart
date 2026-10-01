import 'package:flutter_test/flutter_test.dart';
import 'package:zylo/models/message.dart';
import 'package:zylo/models/conversation.dart';
import 'package:zylo/models/user.dart';
import 'package:zylo/models/moment.dart';
import 'package:zylo/models/moment_shortcut.dart';

void main() {
  group('Models & Serialization Unit Tests', () {
    test('User serialization and deserialization', () {
      final user = User(
        id: 'user123',
        username: 'alice',
        displayName: 'Alice Cooper',
        email: 'alice@zylo.com',
        bio: 'Hello Zylo',
        isOnline: true,
      );

      final json = user.toJson();
      expect(json['username'], 'alice');
      expect(json['isOnline'], true);

      final restored = User.fromJson(json);
      expect(restored.id, 'user123');
      expect(restored.displayName, 'Alice Cooper');
    });

    test('Message serialization with text and media metadata', () {
      final message = Message(
        id: 'msg1',
        conversationId: 'conv1',
        senderId: 'user123',
        type: MessageType.image,
        content: 'Check this photo',
        mediaUrl: 'https://cloudinary.com/photo.jpg',
        mediaMetadata: MediaMetadata(
          fileName: 'photo.jpg',
          fileSize: 10240,
          mimeType: 'image/jpeg',
          width: 800,
          height: 600,
        ),
        status: MessageStatus.delivered,
        createdAt: DateTime.now(),
      );

      final json = message.toJson();
      expect(json['type'], 'image');
      expect(json['status'], 'delivered');
      expect(json['mediaUrl'], 'https://cloudinary.com/photo.jpg');

      final fromJson = Message.fromJson(json);
      expect(fromJson.type, MessageType.image);
      expect(fromJson.status, MessageStatus.delivered);
      expect(fromJson.mediaMetadata?.fileName, 'photo.jpg');
    });

    test('Conversation model participant resolution', () {
      final userA = User(id: 'userA', username: 'alice', displayName: 'Alice', email: 'a@zylo.com');
      final userB = User(id: 'userB', username: 'bob', displayName: 'Bob', email: 'b@zylo.com');

      final conv = Conversation(
        id: 'conv123',
        participants: [userA, userB],
        otherParticipant: userB,
        lastMessageAt: DateTime.now(),
        unreadCount: 3,
      );

      expect(conv.otherParticipant?.id, 'userB');
      expect(conv.unreadCount, 3);
    });

    test('Moment serialization and rolling window status helpers', () {
      final friend = User(id: 'friend1', username: 'rahul', displayName: 'Rahul', email: 'rahul@zylo.com');
      final moment = Moment(
        id: 'moment123',
        currentCount: 24,
        status: 'active',
        startedAt: DateTime.now().subtract(const Duration(days: 24)),
        currentWindowStartedAt: DateTime.now().subtract(const Duration(hours: 2)),
        lastCompletedAt: DateTime.now().subtract(const Duration(hours: 2)),
        expiresAt: DateTime.now().add(const Duration(hours: 22)),
        hoursRemaining: 22,
        isExpiringSoon: false,
        hasInteractedInCurrentWindow: true,
        friend: friend,
      );

      final json = moment.toJson();
      expect(json['currentCount'], 24);
      expect(json['status'], 'active');
      expect(json['hoursRemaining'], 22);

      final restored = Moment.fromJson(json);
      expect(restored.currentCount, 24);
      expect(restored.daysTogetherText, '24 days together');
      expect(restored.isActive, true);
      expect(restored.isExpiringSoon, false);
      expect(restored.friend?.displayName, 'Rahul');
    });

    test('MomentShortcut model serialization and deserialization', () {
      final now = DateTime(2026, 1, 1);
      final shortcut = MomentShortcut(
        id: 'sc1',
        name: 'Besties',
        emoji: '✨',
        contactIds: ['u2', 'u3'],
        contacts: [
          User(id: 'u2', username: 'sarah', displayName: 'Sarah Connor', email: 'sarah@zylo.com'),
        ],
        createdAt: now,
        updatedAt: now,
      );

      final json = shortcut.toJson();
      expect(json['name'], 'Besties');
      expect(json['emoji'], '✨');
      expect(json['contactIds'], ['u2', 'u3']);

      final restored = MomentShortcut.fromJson(json);
      expect(restored.id, 'sc1');
      expect(restored.name, 'Besties');
      expect(restored.emoji, '✨');
      expect(restored.contactIds.length, 2);
      expect(restored.contacts.first.displayName, 'Sarah Connor');
    });

    test('User resolvedName fallback hierarchy', () {
      // 1. displayName takes precedence
      final u1 = User(id: '1', username: 'alex_99', displayName: 'Alex Mercer', email: 'alex@zylo.com');
      expect(u1.resolvedName, 'Alex Mercer');

      // 2. username when displayName is empty/whitespace
      final u2 = User(id: '2', username: 'alex_99', displayName: '   ', email: 'alex@zylo.com');
      expect(u2.resolvedName, 'alex_99');

      // 3. email prefix when displayName and username are empty/whitespace
      final u3 = User(id: '3', username: '', displayName: '', email: 'alex.cool@zylo.com');
      expect(u3.resolvedName, 'alex.cool');

      // 4. 'User' when all fields are empty or whitespace
      final u4 = User(id: '4', username: '  ', displayName: '', email: '');
      expect(u4.resolvedName, 'User');
      expect(u4.resolvedName, isNot('Zylo Contact'));
    });

    test('Conversation otherUserName resolution and fallbacks', () {
      final userA = User(id: 'me', username: 'my_user', displayName: 'Me', email: 'me@zylo.com');
      final userB = User(id: 'them', username: 'other_user', displayName: 'Sam', email: 'sam@zylo.com');

      // otherParticipant explicit
      final conv1 = Conversation(
        id: 'c1',
        participants: [userA, userB],
        otherParticipant: userB,
        lastMessageAt: DateTime.now(),
      );
      expect(conv1.otherUserName, 'Sam');
      expect(conv1.otherUserId, 'them');

      // otherParticipant null, resolved from participants list
      final conv2 = Conversation(
        id: 'c2',
        participants: [userA, userB],
        lastMessageAt: DateTime.now(),
      );
      expect(conv2.otherUserName, 'Sam');

      // No other user, fallback is 'User', never 'Zylo Contact'
      final conv3 = Conversation(
        id: 'c3',
        participants: [],
        lastMessageAt: DateTime.now(),
      );
      expect(conv3.otherUserName, 'User');
      expect(conv3.otherUserName, isNot('Zylo Contact'));
    });
  });
}
