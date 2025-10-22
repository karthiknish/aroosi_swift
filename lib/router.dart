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
import 'package:aroosi_flutter/screens/main/sacred_circle_screen.dart';
import 'package:aroosi_flutter/screens/main/quick_picks_screen.dart';
import 'package:aroosi_flutter/screens/main/shortlists_screen.dart';
import 'package:aroosi_flutter/screens/main/language_screen.dart';
import 'package:aroosi_flutter/screens/main/cultural_assessment_screen.dart';
import 'package:aroosi_flutter/screens/main/family_approval_screen.dart';
import 'package:aroosi_flutter/screens/main/cultural_matching_dashboard.dart';
import 'package:aroosi_flutter/screens/main/afghan_cultural_features_screen.dart';
import 'package:aroosi_flutter/screens/main/matches_screen.dart';

import 'package:aroosi_flutter/screens/cultural/cultural_compatibility_screen.dart'
    as cultural;
import 'package:aroosi_flutter/screens/onboarding/onboarding_checklist_screen.dart';
import 'package:aroosi_flutter/screens/onboarding/onboarding_complete_screen.dart';
import 'package:aroosi_flutter/screens/onboarding/profile_setup_wizard_screen.dart';
import 'package:aroosi_flutter/screens/onboarding/welcome_screen.dart';
import 'package:aroosi_flutter/screens/settings/about_screen.dart';
import 'package:aroosi_flutter/screens/settings/blocked_users_screen.dart';
import 'package:aroosi_flutter/screens/settings/notification_settings_screen.dart';
import 'package:aroosi_flutter/screens/settings/privacy_policy_screen.dart';
import 'package:aroosi_flutter/screens/settings/privacy_settings_screen.dart';
import 'package:aroosi_flutter/screens/settings/safety_guidelines_screen.dart';
import 'package:aroosi_flutter/screens/settings/settings_screen.dart';
import 'package:aroosi_flutter/screens/settings/terms_of_service_screen.dart';
import 'package:aroosi_flutter/screens/support/ai_chatbot_screen.dart';
import 'package:aroosi_flutter/screens/support/contact_screen.dart';
import 'package:aroosi_flutter/screens/cultural/cultural_profile_setup_screen.dart';
import 'package:aroosi_flutter/screens/cultural/compatibility_details_screen.dart';
import 'package:aroosi_flutter/screens/settings/language_settings_screen.dart';
import 'package:aroosi_flutter/utils/debug_logger.dart';
import 'features/auth/auth_state.dart';

/// ChangeNotifier that listens to auth state and notifies GoRouter without
/// forcing a full router reconstruction (prevents losing navigation actions
/// mid-transition such as a manual context.go from a screen listener).
class GoRouterRefresh extends ChangeNotifier {
  GoRouterRefresh(this.ref) {
    _auth = ref.read(authControllerProvider);
    ref.listen<AuthState>(authControllerProvider, (prev, next) {
      _prevAuth = prev;
      _auth = next;
      notifyListeners();
    });
  }
  final Ref ref;
  late AuthState _auth;
  AuthState? _prevAuth;
  AuthState get auth => _auth;
  AuthState? get prevAuth => _prevAuth;
}

final goRouterRefreshProvider = Provider<GoRouterRefresh>((ref) {
  final notifier = GoRouterRefresh(ref);
  ref.onDispose(notifier.dispose);
  return notifier;
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ref.watch(goRouterRefreshProvider); // stable instance

  final router = GoRouter(
    initialLocation: '/startup',
    refreshListenable: refresh,
    observers: [_RouteObserver()],
    routes: [
      GoRoute(
        path: '/startup',
        name: 'startup',
        pageBuilder: (context, state) =>
            _adaptivePage(state, const WelcomeScreen()),
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
            builder: (context, state) => const ProfileSetupScreen(),
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
      GoRoute(
        path: '/cultural-profile',
        name: 'culturalProfile',
        pageBuilder: (context, state) =>
            _adaptivePage(state, const CulturalProfileSetupScreen()),
      ),
      GoRoute(
        path: '/family-approval',
        name: 'familyApproval',
        pageBuilder: (context, state) =>
            _adaptivePage(state, const FamilyApprovalScreen()),
      ),
      GoRoute(
        path: '/cultural-compatibility/:userId1/:userId2',
        name: 'culturalCompatibility',
        pageBuilder: (context, state) {
          final userId1 = state.pathParameters['userId1']!;
          final userId2 = state.pathParameters['userId2']!;
          final userName2 = state.uri.queryParameters['name'];
          return _adaptivePage(
            state,
            cultural.CulturalCompatibilityScreen(
              userId1: userId1,
              userId2: userId2,
              userName2: userName2,
            ),
          );
        },
      ),
      GoRoute(
        path: '/compatibility-details/:userId1/:userId2',
        name: 'compatibilityDetails',
        pageBuilder: (context, state) {
          final userId1 = state.pathParameters['userId1']!;
          final userId2 = state.pathParameters['userId2']!;
          return _adaptivePage(
            state,
            CompatibilityDetailsScreen(userId1: userId1, userId2: userId2),
          );
        },
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
            path: 'sacred-circle',
            name: 'mainSacredCircle',
            pageBuilder: (context, state) =>
                _adaptivePage(state, const SacredCircleScreen()),
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
            path: 'matches',
            name: 'mainMatches',
            pageBuilder: (context, state) =>
                _adaptivePage(state, const MatchesScreen()),
          ),
          GoRoute(
            path: 'language',
            name: 'mainLanguage',
            pageBuilder: (context, state) =>
                _adaptivePage(state, const LanguageScreen()),
          ),
          GoRoute(
            path: 'cultural-assessment',
            name: 'mainCulturalAssessment',
            pageBuilder: (context, state) =>
                _adaptivePage(state, const CulturalAssessmentScreen()),
          ),
          GoRoute(
            path: 'family-approval',
            name: 'mainFamilyApproval',
            pageBuilder: (context, state) =>
                _adaptivePage(state, const FamilyApprovalScreen()),
          ),
          GoRoute(
            path: 'cultural-matching',
            name: 'mainCulturalMatching',
            pageBuilder: (context, state) =>
                _adaptivePage(state, const CulturalMatchingDashboard()),
          ),
          GoRoute(
            path: 'afghan-culture',
            name: 'mainAfghanCulture',
            pageBuilder: (context, state) =>
                _adaptivePage(state, const AfghanCulturalFeaturesScreen()),
          ),
        ],
      ),
      GoRoute(
        path: '/favorites',
        name: 'favorites',
        pageBuilder: (context, state) =>
            _adaptivePage(state, const FavoritesScreen()),
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
            path: 'language',
            name: 'settingsLanguage',
            pageBuilder: (context, state) =>
                _adaptivePage(state, const LanguageSettingsScreen()),
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
          GoRoute(
            path: 'privacy-policy',
            name: 'settingsPrivacyPolicy',
            pageBuilder: (context, state) =>
                _adaptivePage(state, const PrivacyPolicyScreen()),
          ),
          GoRoute(
            path: 'terms-of-service',
            name: 'settingsTermsOfService',
            pageBuilder: (context, state) =>
                _adaptivePage(state, const TermsOfServiceScreen()),
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      final auth = refresh.auth;
      if (auth.loading) return null;

      final location = state.matchedLocation;
      final isAuthRoute =
          location == '/login' ||
          location == '/signup' ||
          location == '/forgot' ||
          location == '/reset';
      final isOnboardingRoute = location.startsWith('/onboarding');
      final isLoginRoute = location == '/login';
      final isSupportRoute = location.startsWith('/support');
      final isStartup = location == '/startup';
      final isPublic = isStartup || isAuthRoute || isSupportRoute;

      final needsProfile = auth.isAuthenticated && auth.profile == null;

      // If on startup and already authenticated, redirect to appropriate page
      if (isStartup && auth.isAuthenticated) {
        if (needsProfile) {
          logRouter('redirect: startup->onboarding/profile-setup');
          return '/onboarding/profile-setup';
        }
        logRouter('redirect: startup->search');
        return '/search';
      }

      // Unauthenticated users should always see /startup unless navigating to a public route
      if (!auth.isAuthenticated && !isPublic) {
        logRouter('redirect: unauthenticated -> /startup (from=$location)');
        return '/startup';
      }

      // If authenticated but profile is missing, force onboarding
      if (needsProfile && !isOnboardingRoute && !isLoginRoute) {
        logRouter(
          'redirect: needsProfile -> /onboarding/profile-setup (from=$location)',
        );
        return '/onboarding/profile-setup';
      }

      // If on login and just authenticated, go to search or onboarding
      if (isLoginRoute && auth.isAuthenticated) {
        final wasUnauth = refresh.prevAuth?.isAuthenticated == false;
        if (wasUnauth) {
          if (needsProfile) {
            logRouter('redirect: login->onboarding/profile-setup');
            return '/onboarding/profile-setup';
          }
          logRouter('redirect: login->search');
          return '/search';
        }
      }

      // If authenticated and on a public route (but not startup), go to search (if profile present) or onboarding (if profile missing)
      if (auth.isAuthenticated && isPublic && !isStartup) {
        if (auth.profile != null) {
          logRouter(
            'redirect: authenticated+profile on public route -> /search (from=$location)',
          );
          return '/search';
        } else {
          logRouter(
            'redirect: authenticated but no profile on public route -> /onboarding/profile-setup (from=$location)',
          );
          return '/onboarding/profile-setup';
        }
      }

      logRouter(
        'redirect: no change (location=$location auth=${auth.isAuthenticated} needsProfile=$needsProfile profileNull=${auth.profile == null})',
      );
      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Not found')),
      body: Center(child: Text('No route defined for ${state.uri}')),
    ),
  );
  ref.onDispose(router.dispose);
  return router;
});

class _RouteObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    logRouter(
      'observer: didPush name=${route.settings.name} path=${route.settings} from=${previousRoute?.settings.name}',
    );
    super.didPush(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    logRouter(
      'observer: didReplace old=${oldRoute?.settings.name} new=${newRoute?.settings.name}',
    );
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    logRouter(
      'observer: didPop name=${route.settings.name} to=${previousRoute?.settings.name}',
    );
    super.didPop(route, previousRoute);
  }
}

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
  // Only use state.pageKey at the top MaterialPage, not in children
  return MaterialPage(key: state.pageKey, child: child);
}
