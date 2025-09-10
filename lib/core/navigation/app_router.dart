import 'package:go_router/go_router.dart';
import 'package:trivia_tycoon/core/router/auth_guard.dart';
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
import '../../screens/menu/main_menu_screen.dart';
import '../../screens/settings/skill_theme_screen.dart';
import '../../screens/skills_tree/skill_branch_detail_screen.dart';
import '../../screens/skills_tree/skill_tree_nav_screen.dart';
import '../../screens/skills_tree/skill_tree_screen.dart';
import '../../screens/skills_tree/widgets/skills_tree_test_screen.dart';
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
import '../../screens/question/question_history_screen.dart';
import '../../screens/question/score_summary_screen.dart';
import '../../screens/question/trivia_transition_screen.dart';
import '../../screens/questions/create_quiz_screen.dart';
import '../../screens/questions/join_quiz_screen.dart';
import '../../screens/questions/play_quiz_screen.dart';
import '../../screens/rewards/reward_screen.dart';
import '../../screens/util/search_screen.dart';
import '../../screens/settings/music_screen.dart';
import '../../screens/settings/theme/theme_color_picker_screen.dart';
import '../../screens/settings/theme/theme_editor_screen.dart';
import '../../screens/settings/theme/theme_settings_screen.dart';
import '../../screens/settings/user_settings_screen.dart';
import 'main_nav_bar.dart';
import 'package:trivia_tycoon/core/services/settings/app_settings.dart';
import 'package:trivia_tycoon/admin/admin_dashboard.dart';

class AppRouter {
  static Future<GoRouter> router() async {
    final bool isAdminEnabled = await AppSettings.isAdminMode();

    return GoRouter(
      initialLocation: '/',
      errorBuilder: (context, state) => const NotFoundScreen(),
      routes: [
        /// 🌟 Universal Splash Entry Point
        GoRoute(
          path: '/',
          builder: (context, state) => SimpleSplashScreen(
            onDone: () {
              context.go('/main');
            },
          ),
        ),

        /// Conditional Admin menu display
        if (isAdminEnabled && await AppSettings.isAdminUser())
          GoRoute(
            path: '/admin',
            builder: (context, state) {
              final isAdmin = true; // You could check a Hive flag, token, etc.
              return isAdmin ? const AdminDashboardScreen() : const NotFoundScreen();
            },
          ),

        /// 🧠 Question Flow
        GoRoute(
          path: '/quiz',
          builder: (context, state) => const QuestionScreen(),
        ),
        GoRoute(
          path: '/trivia-transition',
          builder: (context, state) => const TriviaTransitionScreen(),
        ),
        GoRoute(
          path: '/play-quiz',
          builder: (context, state) => const PlayQuizScreen(),
        ),
        /// 🧭 Shell Route with MainNavBar (applies only to these screens)
        ShellRoute(
          builder: (context, state, child) => MainNavBar(child: child),
          routes: [
            GoRoute(
              path: '/game',
              builder: (context, state) => const MainMenuScreen(),
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
          ]
        ),

        /// 🛡️ Admin Routes (Protected)
        GoRoute(
          path: '/admin/leaderboard-filters',
          name: 'adminLeaderboardFilter',
          builder: (context, state) => const AdminLeaderboardFilterScreen(),
          redirect: adminGuard,
        ),
        GoRoute(
          path: '/admin/encryption-manager',
          builder: (context, state) => const EncryptionManagerScreen(),
          redirect: adminGuard,
        ),
        GoRoute(
          path: '/admin/config-settings',
          builder: (context, state) => const ConfigSettingsScreen(),
          redirect: adminGuard,
        ),
        GoRoute(
          path: '/admin/file-import-export',
          builder: (context, state) => const FileImportExportScreen(),
          redirect: adminGuard,
        ),
        GoRoute(
          path: '/admin/question-list',
          builder: (context, state) => const QuestionListScreen(),
          redirect: adminGuard,
        ),
        GoRoute(
          path: '/admin/question-editor',
          builder: (context, state) => const QuestionEditorScreen(),
          redirect: adminGuard,
        ),
        GoRoute(
          path: '/admin/encryption-preview',
          builder: (context, state) => const EncryptedFilePreview(),
          redirect: adminGuard,
        ),

        /// 🔐 Auth + Onboarding
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),

        /// 🧩 Misc Routes
        GoRoute(
          path: '/quiz-details',
          builder: (context, state) => const QuestionDetailsScreen(),
        ),
        GoRoute(
          path: '/quiz-history',
          builder: (context, state) => const QuestionHistoryScreen(),
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
          path: '/music',
          builder: (context, state) => const MusicScreen(),
        ),
        GoRoute(
          path: '/skill-theme',
          builder: (context, state) => const SkillThemeScreen(),
        ),
        GoRoute(
          path: '/search',
          builder: (context, state) => const SearchScreen(),
        ),
        GoRoute(
          path: '/alerts',
          builder: (context, state) => const AlertsScreen(),
        ),
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
          path: '/friends',
          builder: (context, state) => const FriendsScreen(),
        ),
        GoRoute(
          path: '/help',
          builder: (context, state) => const HelpScreen(),
        ),
        GoRoute(
          path: '/theme-settings',
          builder: (context, state) => const ThemeSettingsScreen(),
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
          path: '/avatar-selection',
          builder: (context, state) => const AvatarSelectionScreen(),
        ),
        GoRoute(
          path: '/gradient-editor',
          builder: (context, state) => const GradientEditorScreen(),
        ),
        GoRoute(
          path: '/qr-scanner',
          name: 'qrScanner',
          builder: (context, state) => const QrScannerScreen(),
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
  }
}