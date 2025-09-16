import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trivia_tycoon/admin/admin_dashboard.dart';
import 'package:trivia_tycoon/core/router/auth_guard.dart';
import 'package:trivia_tycoon/core/router/enhanced_admin_guard.dart';
import 'package:trivia_tycoon/screens/menu/game_menu_screen.dart';
import 'package:trivia_tycoon/screens/not_found_screen.dart';
import 'package:trivia_tycoon/screens/question/question_screen.dart';
import 'package:trivia_tycoon/screens/splash_variants/main_splash.dart';
import 'package:trivia_tycoon/screens/store/store_screen.dart';
import 'package:trivia_tycoon/screens/leaderboard/leaderboard_screen.dart';
import 'package:trivia_tycoon/screens/settings/settings_screen.dart';
import '../../admin/config/config_settings_screen.dart';
import '../../admin/encryption/encryption_manager_screen.dart';
import '../../admin/questions/file_import_export_screen.dart';
import '../../admin/leaderboard/leaderboard_filter_screen.dart';
import '../../admin/questions/question_editor_screen.dart';
import '../../admin/questions/question_list_screen.dart';
import '../../admin/widgets/encrypted_file_preview.dart';
import '../../game/providers/onboarding_providers.dart';
import '../../game/providers/auth_providers.dart';
import '../../screens/question/monthly_quiz_screen.dart';
import '../../screens/social/multiplayer_screen.dart';
import '../../screens/users/achievements_screen.dart';
import '../../screens/browse/all_actions_screen.dart';
import '../../screens/browse/all_categories_screen.dart';
import '../../screens/browse/all_classes_screen.dart';
import '../../screens/menu/main_menu_screen.dart';
import '../../screens/onboarding/profile_setup_screen.dart';
import '../../screens/onboarding/intro_carousel_screen.dart';
import '../../screens/question/category_quiz_screen.dart';
import '../../screens/question/class_quiz_screen.dart';
import '../../screens/question/daily_quiz_screen.dart';
import '../../screens/question/featured_challenge_screen.dart';
import '../../screens/question/question_view_screen.dart';
import '../../screens/settings/skill_theme_screen.dart';
import '../../screens/skills_tree/skill_branch_detail_screen.dart';
import '../../screens/skills_tree/skill_tree_nav_screen.dart';
import '../../screens/skills_tree/skill_tree_screen.dart';
import '../../screens/skills_tree/widgets/skills_tree_test_screen.dart';
import '../../screens/users/favorites_screen.dart';
import '../../ui_components/color_picker/ui/color_picker_screen.dart';
import '../../ui_components/confetti/ui/confetti_settings.dart';
import '../../ui_components/depth_card_3d/theme_editor/gradient_editor_screen.dart';
import '../../ui_components/qr_code/screens/qr_scan_settings_screen.dart';
import '../../ui_components/qr_code/screens/qr_scanner_screen.dart';
import '../../screens/util/alerts_screen.dart';
import '../../screens/login_screen.dart';
import '../../screens/onboarding/onboarding_screen.dart';
import '../../screens/profile/avatar_selection_screen.dart';
import '../../screens/profile/friends_screen.dart';
import '../../screens/profile/help_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/question/question_details_screen.dart';
import '../../screens/users/quiz_history_screen.dart';
import '../../screens/question/score_summary_screen.dart';
import '../../screens/question/transitional/trivia_transition_screen.dart';
import '../../screens/question/create_quiz_screen.dart';
import '../../screens/question/join_quiz_screen.dart';
import '../../screens/question/play_quiz_screen.dart';
import '../../screens/rewards/reward_screen.dart';
import '../../screens/util/search_screen.dart';
import '../../screens/settings/music_screen.dart';
import '../../screens/settings/theme/theme_color_picker_screen.dart';
import '../../screens/settings/theme/theme_editor_screen.dart';
import '../../screens/settings/theme/theme_settings_screen.dart';
import '../../screens/settings/user_settings_screen.dart';
import 'main_nav_bar.dart';
import 'navigation_redirect_service.dart';

// Reactive router provider that rebuilds when navigation state changes
final goRouterProvider = Provider<GoRouter>((ref) {
  // Watch navigation state to trigger rebuilds
  final navigationState = ref.watch(navigationStateProvider);
  final redirectService = ref.read(navigationRedirectServiceProvider);

  // Create a new router instance when state changes
  return GoRouter(
    initialLocation: '/',
    errorBuilder: (context, state) => const NotFoundScreen(),
    debugLogDiagnostics: true,

    // Simplified redirect logic using the service
    redirect: (context, state) {
      final currentPath = state.fullPath ?? '';
      return redirectService.determineRedirect(currentPath);
    },

    routes: [
      /// 🌟 Universal Splash Entry Point
      GoRoute(
        path: '/',
        builder: (context, state) => SimpleSplashScreen(
          onDone: () {
            // Let redirect logic handle where to go next
            context.go('/main');
          },
        ),
      ),

      /// 🔐 Auth + Onboarding
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      /// 📚 Onboarding Routes
      GoRoute(
        path: '/intro',
        name: 'intro',
        builder: (context, state) => const IntroCarouselScreen(),
      ),
      GoRoute(
        path: '/profile-setup',
        name: 'profileSetup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      /// 🏠 Main App Routes
      GoRoute(
        path: '/main',
        name: 'main',
        builder: (context, state) => const MainMenuScreen(),
      ),

      /// 🛡️ Admin Routes (Protected & Conditional)
      // Main admin dashboard
      GoRoute(
        path: '/admin',
        builder: (context, state) {
          return const AdminRouteWrapper(
            routeName: 'Admin Dashboard',
            child: AdminDashboardScreen(),
          );
        },
      ),

      // Other admin routes with enhanced protection
      createAdminRoute(
        path: '/admin/leaderboard-filters',
        name: 'Admin Leaderboard Filters',
        builder: (context, state) => const AdminLeaderboardFilterScreen(),
      ),
      createAdminRoute(
        path: '/admin/encryption-manager',
        name: 'Encryption Manager',
        builder: (context, state) => const EncryptionManagerScreen(),
      ),
      createAdminRoute(
        path: '/admin/config-settings',
        name: 'Config Settings',
        builder: (context, state) => const ConfigSettingsScreen(),
      ),
      createAdminRoute(
        path: '/admin/file-import-export',
        name: 'File Import/Export',
        builder: (context, state) => const FileImportExportScreen(),
      ),
      createAdminRoute(
        path: '/admin/question-list',
        name: 'Question List',
        builder: (context, state) => const QuestionListScreen(),
      ),
      createAdminRoute(
        path: '/admin/question-editor',
        name: 'Question Editor',
        builder: (context, state) => const QuestionEditorScreen(),
      ),
      createAdminRoute(
        path: '/admin/encryption-preview',
        name: 'Encryption Preview',
        builder: (context, state) => const EncryptedFilePreview(),
      ),

      /// 🧭 Shell Route with MainNavBar (applies only to these screens)
      ShellRoute(
          builder: (context, state, child) => MainNavBar(child: child),
          routes: [
            GoRoute(
              path: '/game',
              builder: (context, state) => const GameMenuScreen(),
              redirect: onboardingGuard,
            ),
            GoRoute(
              path: '/store',
              builder: (context, state) => const StoreScreen(),
              redirect: onboardingGuard,
            ),
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
              redirect: onboardingGuard,
            ),
            GoRoute(
              path: '/leaderboard',
              builder: (context, state) => const LeaderboardScreen(),
              redirect: onboardingGuard,
            ),
            GoRoute(
              path: '/rewards',
              builder: (context, state) => const RewardsScreen(),
              redirect: onboardingGuard,
            ),
          ]),

      /// 🧠 Question Flow
      GoRoute(
        path: '/quiz',
        builder: (context, state) => const QuestionScreen(),
      ),
      GoRoute(
        path: '/quiz-details',
        builder: (context, state) => const QuestionDetailsScreen(),
      ),
      GoRoute(
        path: '/create-quiz',
        builder: (context, state) => const CreateQuizScreen(),
      ),
      GoRoute(
        path: '/join-quiz',
        builder: (context, state) => const JoinQuizScreen(),
      ),
      GoRoute(
        path: '/play-quiz',
        builder: (context, state) => const PlayQuizScreen(),
      ),
      GoRoute(
        path: '/question',
        builder: (context, state) => const AdaptedQuestionScreen(),
      ),
      GoRoute(
        path: '/trivia-transition',
        builder: (context, state) => const TriviaTransitionScreen(),
      ),
      GoRoute(
        path: '/score-summary',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>;
          return ScoreSummaryScreen(
            score: args['score'],
            money: args['money'],
            diamonds: args['diamonds'],
          );
        }),

      /// 👤 USER PROFILE & SOCIAL
      GoRoute(
        path: '/friends',
        builder: (context, state) => const FriendsScreen(),
      ),
      GoRoute(
        path: '/avatar-selection',
        builder: (context, state) => const AvatarSelectionScreen(),
      ),
      GoRoute(
        path: '/multiplayer',
        builder: (context, state) => const MultiplayerScreen(),
        redirect: onboardingGuard,
      ),
      // GoRoute(
      //   path: '/multiplayer',
      //   builder: (context, state) => const MultiplayerScreen(),
      //   redirect: onboardingGuard,
      // ),

      /// 🎯 Daily Quiz & Featured Content Routes (Referenced in CarouselSection)
      GoRoute(
        path: '/daily-quiz',
        builder: (context, state) => const DailyQuizScreen(),
        redirect: onboardingGuard,
      ),
      GoRoute(
        path: '/monthly-quiz',
        builder: (context, state) => const MonthlyQuizScreen(),
        redirect: onboardingGuard,
      ),
      GoRoute(
        path: '/featured-challenge',
        builder: (context, state) => const FeaturedChallengeScreen(),
        redirect: onboardingGuard,
      ),

      /// 📚 Class-Based Quiz Routes (Referenced in GridMenuSection)
      GoRoute(
        path: '/class-quiz/:classLevel',
        name: 'classQuiz',
        builder: (context, state) {
          final classLevel = state.pathParameters['classLevel'] ?? '6';
          return ClassQuizScreen(classLevel: classLevel);
        },
        redirect: onboardingGuard,
      ),
      GoRoute(
        path: '/all-classes',
        builder: (context,state) => const AllClassesScreen(),
        redirect: onboardingGuard,
      ),

      // 🗂️ Category-Based Quiz Routes (Referenced in GridMenuSection)
      GoRoute(
        path: '/category-quiz/:category',
        name: 'categoryQuiz',
        builder: (context, state) {
          final category = state.pathParameters['category'] ?? 'general';
          return CategoryQuizScreen(category: category);
        },
        redirect: onboardingGuard,
      ),
      GoRoute(
        path: '/all-categories',
        builder: (context, state) => const AllCategoriesScreen(),
        redirect: onboardingGuard,
      ),

      /// ⚡ Quick Actions Routes (Referenced in Enhanced GridMenuSection)
      GoRoute(
        path: '/history',
        builder: (context, state) => const QuizHistoryScreen(),
        redirect: onboardingGuard,
      ),
      GoRoute(
        path: '/favorites',
        builder: (context, state) => const FavoritesScreen(),
        redirect: onboardingGuard,
      ),
      GoRoute(
        path: '/all-actions',
        builder: (context, state) => const AllActionsScreen(),
        redirect: onboardingGuard,
      ),

      /// 🎮 Enhanced Quiz Routes (Referenced in TopMenuSection)
      GoRoute(
        path: '/achievements',
        builder: (context, state) => const AchievementsScreen(),
        redirect: onboardingGuard,
      ),

      GoRoute(
        path: '/music',
        builder: (context, state) => const MusicScreen(),
      ),
      GoRoute(
        path: '/skill-theme',
        builder: (context, state) => const SkillThemeScreen(),
      ),

      /// 🧩 UTILITY & MISC
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/alerts',
        builder: (context, state) => const AlertsScreen(),
      ),
      GoRoute(
        path: '/qr-scanner',
        name: 'qrScanner',
        builder: (context, state) => const QrScannerScreen(),
      ),

      /// ⚙️ SETTINGS & CONFIGURATION
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
        redirect: authGuard,
      ),
      GoRoute(
        path: '/user-settings',
        builder: (context, state) => const UserSettingsScreen(),
      ),
      GoRoute(
        path: '/theme-settings',
        builder: (context, state) => const ThemeSettingsScreen(),
      ),
      GoRoute(
        path: '/help',
        builder: (context, state) => const HelpScreen(),
      ),
      GoRoute(
        path: '/confetti-settings',
        builder: (context, state) => const ConfettiSettings(),
      ),
      GoRoute(
        path: '/color-settings',
        builder: (context, state) => const ColorPickerScreen(),
      ),
      GoRoute(
        path: '/theme-editor',
        name: 'ThemeEditor',
        builder: (context, state) => const ThemeEditorScreen(),
      ),
      GoRoute(
        path: '/theme-color-picker',
        name: 'Theme Color Picker',
        builder: (context, state) => const ThemeColorPickerScreen(),
      ),
      GoRoute(
        path: '/gradient-editor',
        builder: (context, state) => const GradientEditorScreen(),
      ),
      GoRoute(
        path: '/qr-scan-settings',
        name: 'qrScanSettings',
        builder: (context, state) => const QrScanSettingsScreen(),
      ),

      /// Skills Tree
      GoRoute(
        path: '/skills',
        builder: (context, state) => const SkillTreeNavScreen(),
      ),
      GoRoute(
        path: '/skills-test',
        builder: (context, state) => const SkillTreeNavTestScreen(),
      ),
      GoRoute(
        path: '/skill-tree/:groupId',
        name: 'skillTree',
        builder: (context, state) {
          final groupId = state.pathParameters['groupId'] ?? '';
          return SkillTreeScreen(groupId: groupId);
        },
      ),
      GoRoute(
        path: '/skill-tree/:branchId',
        builder: (context, state) => SkillBranchDetailScreen(
          branchId: state.pathParameters['branchId']!,
          initialStep: int.tryParse(state.uri.queryParameters['step'] ?? ''),
          showPathInitially: state.uri.queryParameters['showPath'] == '1',
        ),
      ),
    ],
  );
});

class AppRouter {
  static Future<GoRouter> router() async {
    // This method is now simplified since GoRouter provider handles the logic
    final container = ProviderContainer();
    return container.read(goRouterProvider);
  }
}
