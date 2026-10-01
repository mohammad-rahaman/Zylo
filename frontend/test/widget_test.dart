import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zylo/main.dart';
import 'package:zylo/widgets/user_avatar.dart';
import 'package:zylo/widgets/moment_badge.dart';
import 'package:zylo/features/chat/widgets/message_status_icon.dart';
import 'package:zylo/models/message.dart';
import 'package:zylo/models/user.dart';
import 'package:zylo/features/moments/widgets/share_moment_modal.dart';

void main() {
  testWidgets('ZyloApp initial smoke test renders splash branding', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: ZyloApp(),
      ),
    );

    expect(find.text('Zylo'), findsOneWidget);
    expect(find.text('SHARE YOUR MOMENT.'), findsOneWidget);

    // Settle splash redirect timer
    await tester.pumpAndSettle(const Duration(seconds: 2));
  });

  testWidgets('UserAvatar renders initials when no image provided', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: UserAvatar(name: 'Sarah Connor'),
        ),
      ),
    );

    expect(find.text('SC'), findsOneWidget);
  });

  testWidgets('MessageStatusIcon renders appropriate icons for each status', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              MessageStatusIcon(status: MessageStatus.sent),
              MessageStatusIcon(status: MessageStatus.delivered),
              MessageStatusIcon(status: MessageStatus.read),
            ],
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(find.byIcon(Icons.done_all), findsNWidgets(2));
  });

  testWidgets('ShareMomentModal renders camera, gallery, and location options', (WidgetTester tester) async {
    final targetUser = User(
      id: 'user_123',
      username: 'alicew',
      displayName: 'Alice Walker',
      email: 'alice@example.com',
      isOnline: true,
      lastSeen: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ShareMomentModal(targetUser: targetUser),
          ),
        ),
      ),
    );

    expect(find.text('SHARE A MOMENT'), findsOneWidget);
    expect(find.text('with Alice Walker'), findsOneWidget);
    expect(find.text('Take Photo'), findsOneWidget);
    expect(find.text('Select Photo'), findsOneWidget);
    expect(find.text('Add Map Location to Moment'), findsOneWidget);
  });

  testWidgets('MomentBadge renders normal count with sparkle icon', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MomentBadge(count: 24),
        ),
      ),
    );

    expect(find.text('✨'), findsOneWidget);
    expect(find.text('24'), findsOneWidget);
  });

  testWidgets('MomentBadge renders expiring count and hours remaining', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MomentBadge(count: 24, isExpiringSoon: true, hoursRemaining: 2),
        ),
      ),
    );

    expect(find.text('✨'), findsOneWidget);
    expect(find.text('24 · 2h'), findsOneWidget);
  });

  testWidgets('MomentBadge renders empty when count is 0', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MomentBadge(count: 0),
        ),
      ),
    );

    expect(find.text('✨'), findsNothing);
    expect(find.text('0'), findsNothing);
  });
}
