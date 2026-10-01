import 'package:intl/intl.dart';

class DateFormatter {
  static String formatMessageTime(DateTime dateTime) {
    return DateFormat.jm().format(dateTime.toLocal()); // e.g. 10:45 AM
  }

  static String formatChatListTime(DateTime dateTime) {
    final now = DateTime.now();
    final local = dateTime.toLocal();
    final diff = now.difference(local);

    if (diff.inDays == 0 && now.day == local.day) {
      return DateFormat.jm().format(local);
    } else if (diff.inDays <= 1 || (now.day - local.day == 1 && diff.inDays < 2)) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return DateFormat.E().format(local); // e.g. Mon, Tue
    } else {
      return DateFormat.yMd().format(local); // e.g. 9/30/2026
    }
  }

  static String formatLastSeen(DateTime? lastSeen, bool isOnline) {
    if (isOnline) return 'Online';
    if (lastSeen == null) return 'Offline';

    final now = DateTime.now();
    final local = lastSeen.toLocal();
    final diff = now.difference(local);

    if (diff.inMinutes < 1) {
      return 'Last seen just now';
    } else if (diff.inMinutes < 60) {
      return 'Last seen ${diff.inMinutes}m ago';
    } else if (diff.inHours < 24 && now.day == local.day) {
      return 'Last seen today at ${DateFormat.jm().format(local)}';
    } else if (diff.inDays <= 1) {
      return 'Last seen yesterday at ${DateFormat.jm().format(local)}';
    } else {
      return 'Last seen ${DateFormat.MMMd().format(local)} at ${DateFormat.jm().format(local)}';
    }
  }
}
