import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConstants {
  static const String _envHost = String.fromEnvironment('API_HOST');

  static String get host {
    if (_envHost.isNotEmpty) return _envHost;
    if (kIsWeb) return 'localhost';
    if (Platform.isAndroid) return '10.0.2.2';
    // Use Mac's local network IP for iOS physical devices and simulators
    return '192.168.1.2';
  }

  static String get baseUrl => 'http://$host:3000/api/v1';
  static String get socketUrl => 'http://$host:3000';

  static String resolveMediaUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('/')) {
      return 'http://$host:3000$url';
    }
    return url
        .replaceFirst('://localhost:3000', '://$host:3000')
        .replaceFirst('://127.0.0.1:3000', '://$host:3000');
  }

  // Auth endpoints
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';

  // Users endpoints
  static const String searchUsers = '/users/search';
  static const String me = '/users/me';
  static String user(String id) => '/users/$id';
  static String blockUser(String id) => '/users/$id/block';

  // Conversations endpoints
  static const String conversations = '/conversations';
  static String conversation(String id) => '/conversations/$id';

  // Messages endpoints
  static String conversationMessages(String id) => '/conversations/$id/messages';
  static String message(String id) => '/messages/$id';

  // Moments endpoints
  static const String moments = '/moments';
  static const String sendMoment = '/moments/send';
  static const String momentShortcuts = '/moments/shortcuts';
  static String momentShortcut(String id) => '/moments/shortcuts/$id';
  static String momentWithUser(String userId) => '/moments/with/$userId';
  static String endMoment(String id) => '/moments/$id';

  // Uploads & Notifications
  static const String uploads = '/uploads';
  static const String deviceToken = '/notifications/device-token';
}
