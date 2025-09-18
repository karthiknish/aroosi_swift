import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aroosi_flutter/features/auth/auth_controller.dart';
import 'package:aroosi_flutter/platform/platform_utils.dart';
import 'package:aroosi_flutter/theme/motion.dart';
import 'package:aroosi_flutter/screens/auth/forgot_password_screen.dart';
import 'package:aroosi_flutter/screens/auth/login_screen.dart';
import 'package:aroosi_flutter/screens/auth/reset_password_screen.dart';
import 'package:aroosi_flutter/screens/auth/signup_screen.dart';
import 'package:aroosi_flutter/screens/details_screen.dart';
import 'package:aroosi_flutter/screens/home/dashboard_screen.dart';
import 'package:aroosi_flutter/screens/home/favorites_screen.dart';
import 'package:aroosi_flutter/screens/home/home_shell.dart';
import 'package:aroosi_flutter/screens/home/profile_screen.dart';
import 'package:aroosi_flutter/screens/home/search_screen.dart';
import 'package:aroosi_flutter/screens/main/chat_screen.dart';
import 'package:aroosi_flutter/screens/main/conversation_list_screen.dart';
import 'package:aroosi_flutter/screens/main/edit_profile_screen.dart';
import 'package:aroosi_flutter/screens/main/icebreakers_screen.dart';
import 'package:aroosi_flutter/screens/main/interests_screen.dart';
import 'package:aroosi_flutter/screens/main/matches_screen.dart';
import 'package:aroosi_flutter/screens/main/quick_picks_screen.dart';
import 'package:aroosi_flutter/screens/main/shortlists_screen.dart';
import 'package:aroosi_flutter/screens/main/subscription_screen.dart';
import 'package:aroosi_flutter/screens/onboarding/onboarding_checklist_screen.dart';
import 'package:aroosi_flutter/screens/onboarding/onboarding_complete_screen.dart';
import 'package:aroosi_flutter/screens/onboarding/profile_setup_wizard_screen.dart';
import 'package:aroosi_flutter/screens/onboarding/welcome_screen.dart';
import 'package:aroosi_flutter/screens/settings/about_screen.dart';
import 'package:aroosi_flutter/screens/settings/blocked_users_screen.dart';
import 'package:aroosi_flutter/screens/settings/notification_settings_screen.dart';
import 'package:aroosi_flutter/screens/settings/privacy_settings_screen.dart';
import 'package:aroosi_flutter/screens/settings/safety_guidelines_screen.dart';
import 'package:aroosi_flutter/screens/settings/settings_screen.dart';
import 'package:aroosi_flutter/screens/startup_screen.dart';
import 'package:aroosi_flutter/screens/support/ai_chatbot_screen.dart';
import 'package:aroosi_flutter/screens/support/contact_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/onboarding',
    routes: [
      GoRoute(
        path: '/startup',
        name: 'startup',
        pageBuilder: (context, state) =>
            _adaptivePage(state, const StartupScreen()),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) =>
            _adaptivePage(state, const LoginScreen()),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        pageBuilder: (context, state) =>
            _adaptivePage(state, const SignupScreen()),
      ),
      GoRoute(
        path: '/forgot',
        name: 'forgot',
        pageBuilder: (context, state) =>
            _adaptivePage(state, const ForgotPasswordScreen()),
      ),
      GoRoute(
        path: '/reset',
        name: 'reset',
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboardingWelcome',
        pageBuilder: (context, state) =>
            _adaptivePage(state, const WelcomeScreen()),
        routes: [
          GoRoute(
            path: 'profile-setup',
            name: 'onboardingProfileSetup',
            pageBuilder: (context, state) =>
                _adaptivePage(state, const ProfileSetupScreen()),
          ),
          GoRoute(
            path: 'checklist',
            name: 'onboardingChecklist',
            pageBuilder: (context, state) =>
                _adaptivePage(state, const OnboardingChecklistScreen()),
          ),
          GoRoute(
            path: 'complete',
            name: 'onboardingComplete',
            pageBuilder: (context, state) =>
                _adaptivePage(state, const OnboardingCompleteScreen()),
          ),
        ],
      ),
      GoRoute(
        path: '/support',
        name: 'support',
        pageBuilder: (context, state) =>
            _adaptivePage(state, const ContactScreen()),
        routes: [
          GoRoute(
            path: 'ai-chatbot',
            name: 'supportAiChatbot',
            pageBuilder: (context, state) =>
                _adaptivePage(state, const AIChatbotScreen()),
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomeShell(shell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                name: 'dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/search',
                name: 'search',
                builder: (context, state) => const SearchScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/favorites',
                name: 'favorites',
                builder: (context, state) => const FavoritesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                name: 'profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/main',
        name: 'mainConversations',
        pageBuilder: (context, state) =>
            _adaptivePage(state, const ConversationListScreen()),
        routes: [
          GoRoute(
            path: 'chat',
            name: 'mainChat',
            pageBuilder: (context, state) {
              final convId = state.uri.queryParameters['conversationId'];
              final toUserId = state.uri.queryParameters['toUserId'];
              return _adaptivePage(
                state,
                ChatScreen(conversationId: convId, toUserId: toUserId),
              );
            },
          ),
          GoRoute(
            path: 'edit-profile',
            name: 'mainEditProfile',
            pageBuilder: (context, state) =>
                _adaptivePage(state, const EditProfileScreen()),
          ),
          GoRoute(
            path: 'icebreakers',
            name: 'mainIcebreakers',
            pageBuilder: (context, state) =>
                _adaptivePage(state, const IcebreakersScreen()),
          ),
          GoRoute(
            path: 'interests',
            name: 'mainInterests',
            pageBuilder: (context, state) =>
                _adaptivePage(state, const InterestsScreen()),
          ),
          GoRoute(
            path: 'matches',
            name: 'mainMatches',
            pageBuilder: (context, state) =>
                _adaptivePage(state, const MatchesScreen()),
          ),
          GoRoute(
            path: 'quick-picks',
            name: 'mainQuickPicks',
            pageBuilder: (context, state) =>
                _adaptivePage(state, const QuickPicksScreen()),
          ),
          GoRoute(
            path: 'shortlists',
            name: 'mainShortlists',
            pageBuilder: (context, state) =>
                _adaptivePage(state, const ShortlistsScreen()),
          ),
          GoRoute(
            path: 'subscription',
            name: 'mainSubscription',
            pageBuilder: (context, state) =>
                _adaptivePage(state, const SubscriptionScreen()),
          ),
        ],
      ),
      GoRoute(
        path: '/details/:id',
        name: 'details',
        pageBuilder: (context, state) => _adaptivePage(
          state,
          DetailsScreen(id: state.pathParameters['id'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        pageBuilder: (context, state) =>
            _adaptivePage(state, const SettingsScreen()),
        routes: [
          GoRoute(
            path: 'about',
            name: 'settingsAbout',
            pageBuilder: (context, state) =>
                _adaptivePage(state, const AboutScreen()),
          ),
          GoRoute(
            path: 'blocked-users',
            name: 'settingsBlockedUsers',
            pageBuilder: (context, state) =>
                _adaptivePage(state, const BlockedUsersScreen()),
          ),
          GoRoute(
            path: 'notifications',
            name: 'settingsNotifications',
            pageBuilder: (context, state) =>
                _adaptivePage(state, const NotificationSettingsScreen()),
          ),
          GoRoute(
            path: 'privacy',
            name: 'settingsPrivacy',
            pageBuilder: (context, state) =>
                _adaptivePage(state, const PrivacySettingsScreen()),
          ),
          GoRoute(
            path: 'safety',
            name: 'settingsSafety',
            pageBuilder: (context, state) =>
                _adaptivePage(state, const SafetyGuidelinesScreen()),
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      if (auth.loading) return null;

      final location = state.matchedLocation;
      final isAuthRoute =
          location == '/login' ||
          location == '/signup' ||
          location == '/forgot' ||
          location == '/reset';
      final isOnboardingRoute = location.startsWith('/onboarding');
      final isSupportRoute = location.startsWith('/support');
      final isPublic =
          location == '/startup' ||
          isAuthRoute ||
          isOnboardingRoute ||
          isSupportRoute;

      if (!auth.isAuthenticated && !isPublic) {
        return '/startup';
      }
      if (auth.isAuthenticated &&
          (location == '/startup' || isAuthRoute || isOnboardingRoute)) {
        return '/dashboard';
      }
      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Not found')),
      body: Center(child: Text('No route defined for ${state.uri}')),
    ),
  );
});

Page<dynamic> _adaptivePage(
  GoRouterState state,
  Widget child, {
  bool iosNoAnimation = false,
}) {
  if (isCupertinoPlatform()) {
    if (iosNoAnimation) {
      return CustomTransitionPage(
        key: state.pageKey,
        child: child,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        transitionsBuilder: (c, a, sA, w) => w,
      );
    }
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: AppMotionDurations.page,
      reverseTransitionDuration: AppMotionDurations.page,
      transitionsBuilder: (context, animation, secondaryAnimation, widget) {
        final curve = CurvedAnimation(
          parent: animation,
          curve: AppMotionCurves.easeOut,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(curve),
          child: widget,
        );
      },
    );
  }
  return MaterialPage(child: child, key: state.pageKey);
}
