import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConstants {
  /// Production API origin, supplied at build time, e.g.
  ///   flutter build --dart-define=API_URL=https://your-app.onrender.com
  /// When empty, the app falls back to local development defaults below.
  static const String _envApiUrl = String.fromEnvironment('API_URL');

  /// Optional host override for local development (host only, no scheme/port).
  static const String _envHost = String.fromEnvironment('API_HOST');

  /// Local development origin (scheme + host + port), used only when
  /// [_envApiUrl] is not provided.
  static String get _localOrigin {
    final String host;
    if (_envHost.isNotEmpty) {
      host = _envHost;
    } else if (kIsWeb) {
      host = 'localhost';
    } else if (Platform.isAndroid) {
      host = '10.0.2.2';
    } else {
      // Mac's local network IP for iOS physical devices and simulators.
      host = '192.168.1.2';
    }
    return 'http://$host:3000';
  }

  /// API origin without the `/api/v1` suffix. Prefers the build-time
  /// [_envApiUrl] (production), otherwise the local development origin.
  static String get origin {
    if (_envApiUrl.isNotEmpty) {
      return _envApiUrl.endsWith('/')
          ? _envApiUrl.substring(0, _envApiUrl.length - 1)
          : _envApiUrl;
    }
    return _localOrigin;
  }

  static String get baseUrl => '$origin/api/v1';

  /// Socket.IO origin. Passed as the same http(s) origin as the API; the
  /// client negotiates the secure websocket (wss) transport when the origin
  /// is https.
  static String get socketUrl => origin;

  static String resolveMediaUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('/')) {
      return '$origin$url';
    }
    return url
        .replaceFirst('http://localhost:3000', origin)
        .replaceFirst('http://127.0.0.1:3000', origin);
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
