import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/onboarding_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/auth/splash_screen.dart';
import '../features/camera/camera_screen.dart';
import '../features/chat/chat_screen.dart';
import '../features/chat/new_conversation_screen.dart';
import '../features/home/home_screen.dart';
import '../features/profile/edit_profile_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/users/user_profile_screen.dart';
import '../models/conversation.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/chat/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final conv = state.extra is Conversation ? state.extra as Conversation : null;
          return ChatScreen(conversationId: id, initialConversation: conv);
        },
      ),
      GoRoute(
        path: '/new-chat',
        builder: (context, state) => const NewConversationScreen(),
      ),
      GoRoute(
        path: '/user/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final user = state.extra is User ? state.extra as User : null;
          return UserProfileScreen(userId: id, initialUser: user);
        },
      ),
      GoRoute(
        path: '/users/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final user = state.extra is User ? state.extra as User : null;
          return UserProfileScreen(userId: id, initialUser: user);
        },
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/camera',
        builder: (context, state) {
          final recipientId = state.uri.queryParameters['recipientId'] ??
              (state.extra is String ? state.extra as String : null);
          final recipientIds = recipientId != null
              ? [recipientId]
              : (state.extra is List<String> ? state.extra as List<String> : null);
          return CameraScreen(initialRecipientIds: recipientIds);
        },
      ),
    ],
    redirect: (context, state) {
      final isAuth = authState.status == AuthStatus.authenticated;
      final isLoggingIn = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/onboarding' ||
          state.matchedLocation == '/';

      if (!isAuth && !isLoggingIn && authState.status != AuthStatus.initial) {
        return '/login';
      }
      return null;
    },
  );
});
