// Synaptix Phase 1: Route paths and GoRoute names are intentionally unchanged.
// Display-facing label updates (e.g. "Arena", "Labs", "Pathways") are deferred
// to FE-B2 (Phase 3). Do NOT rename route path constants here.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trivia_tycoon/admin/admin_dashboard.dart';
import 'package:trivia_tycoon/admin/events_management/admin_event_queue_screen.dart';
import 'package:trivia_tycoon/core/router/auth_guard.dart';
import 'package:trivia_tycoon/core/router/enhanced_admin_guard.dart';
import 'package:trivia_tycoon/screens/invite_log_screen.dart';
import 'package:trivia_tycoon/screens/leaderboard/tier_rank_screen.dart';
import 'package:trivia_tycoon/screens/menu/game_menu_screen.dart';
import 'package:trivia_tycoon/screens/not_found_screen.dart';
import 'package:trivia_tycoon/screens/question/categories/favorites_quiz_screen.dart';
import 'package:trivia_tycoon/screens/question/question_screen.dart';
import 'package:trivia_tycoon/screens/store/store_screen.dart';
import 'package:trivia_tycoon/screens/leaderboard/leaderboard_screen.dart';
import 'package:trivia_tycoon/screens/settings/settings_screen.dart';
import '../../admin/admin_dashboard_shell.dart';
import '../../admin/analytics/analytics_screen.dart';
import '../../admin/audit/admin_audit_log_screen.dart';
import '../../admin/config/config_settings_screen.dart';
import '../../admin/encryption/encryption_manager_screen.dart';
import '../../admin/notifications/admin_notifications_screen.dart';
import '../../admin/questions/file_import_export_screen.dart';
import '../../admin/leaderboard/leaderboard_filter_screen.dart';
import '../../admin/questions/question_editor_screen.dart';
import '../../admin/questions/question_list_screen.dart';
import '../../admin/user_management/admin_users_screen.dart';
import '../../admin/widgets/encrypted_file_preview.dart';
import '../../arcade/leaderboards/local_arcade_leaderboard_screen.dart';
import '../../arcade/missions/arcade_missions_screen.dart';
import '../../arcade/ui/screens/arcade_hub_screen.dart';
import '../../arcade/ui/screens/daily_bonus_screen.dart';
import '../../game/models/game_mode.dart';
import '../../game/models/question_model.dart';
import '../../screens/challenge/challenge_screen.dart';
import '../../screens/menu/invite_screen.dart';
import '../../screens/messages/messages_screen.dart';
import '../../screens/mini_games/puzzles/connections_puzzle_screen.dart';
import '../../screens/mini_games/puzzles/crossword_screen.dart';
import '../../screens/mini_games/puzzles/flow_connect_puzzle_screen.dart';
import '../../screens/mini_games/puzzles/game_2048_screen.dart';
import '../../screens/mini_games/puzzles/memory_match_screen.dart';
import '../../screens/mini_games/mini_games_hub_screen.dart';
import '../../screens/mini_games/puzzles/sudoku_puzzle_screen.dart';
import '../../screens/mini_games/puzzles/sun_moon_puzzle_screen.dart';
import '../../screens/mini_games/puzzles/word_search_screen.dart';
import '../../screens/multiplayer/live_match_screen.dart';
import '../../screens/multiplayer/matchmaking_screen.dart';
import '../../screens/multiplayer/multiplayer_game_matchmaking_screen.dart';
import '../../screens/multiplayer/multiplayer_hub_screen.dart';
import '../../screens/multiplayer/multiplayer_question_screen.dart';
import '../../screens/multiplayer/multiplayer_results_screen.dart';
import '../../screens/multiplayer/room_lobby_screen.dart';
import '../../screens/notifications/notifications_screen.dart';
import '../../core/models/notifications/player_inbox_item.dart';
import '../../screens/preferences_screen.dart';
import '../../screens/profile/enhanced/add_friends_screen.dart';
import '../../screens/profile/profile_selection_screen.dart';
import '../../screens/question/categories/category_quiz_screen.dart';
import '../../screens/question/categories/class_quiz_screen.dart';
import '../../screens/question/categories/featured_challenge_screen.dart';
import '../../screens/question/categories/monthly_quiz_screen.dart';
import '../../screens/question/score_summary_screen_wrapper.dart';
import '../../screens/question/transitional/how_to_play_screen.dart';
import '../../screens/report_screen.dart';
import '../../screens/rewards/mission_screen.dart';
import '../../screens/rewards/spin_earn_screen.dart';
import '../../screens/social/multiplayer_screen.dart';
import '../../screens/store/gifts_screen.dart';
import '../../screens/store/store_payment_return_screen.dart';
import '../../screens/store/store_hub_screen.dart';
import '../../screens/store/premium_store.dart';
import '../../screens/store/store_special_screen.dart';
import '../../screens/store/daily_items_screen.dart';
import '../../screens/users/achievements_screen.dart';
import '../../screens/browse/all_actions_screen.dart';
import '../../screens/browse/all_categories_screen.dart';
import '../../screens/browse/all_classes_screen.dart';
import '../../screens/menu/main_menu_screen.dart';
import '../../screens/question/categories/daily_quiz_screen.dart';
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
import '../dto/learning_dto.dart';
import '../../screens/learn_hub/learn_hub_screen.dart';
import '../../screens/learn_hub/lesson_screen.dart';
import '../../screens/learn_hub/module_complete_screen.dart';
import '../../screens/learn_hub/module_detail_screen.dart';
import '../../screens/login_screen.dart';
import '../../screens/onboarding/onboarding_screen.dart';
import '../../screens/profile/avatar_selection_screen.dart';
import '../../screens/profile/friends_screen.dart';
import '../../screens/help_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/question/question_details_screen.dart';
import '../../screens/users/quiz_history_screen.dart';
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

// ── Screens registered in this pass ─────────────────────────────────────────
import '../../arcade/domain/arcade_difficulty.dart';
import '../../arcade/domain/arcade_game_definition.dart';
import '../../arcade/ui/screens/arcade_game_shell.dart';
import '../../admin/audio/admin_audio_player_screen.dart';
import '../../admin/splash_screen/splash_selector_screen.dart';
import '../../admin/store/screens/admin_store_inventory_screen.dart';
import '../../admin/store/screens/admin_stock_policy_screen.dart';
import '../../admin/store/screens/admin_flash_sales_screen.dart';
import '../../admin/store/screens/admin_reward_limits_screen.dart';
import '../../admin/store/screens/admin_stock_analytics_screen.dart';
import '../../game/models/leaderboard_entry.dart';
import '../../screens/group_chat/group_settings_screen.dart';
import '../../screens/messages/message_detail_screen.dart';
import '../../screens/messages/dialogs/create_dm_dialog.dart';
import '../../screens/messages/dialogs/message_request_dialog.dart';
import '../../screens/notifications/notification_detail_screen.dart';
import '../../screens/profile/dialogs/add_friend_dialog.dart';
import '../../screens/profile/enhanced/enhanced_profile_screen.dart';
import '../../screens/profile/enhanced/mutual_friends_screen.dart';
import '../../screens/profile/user_profile_screen.dart';
import '../../screens/search/dialogs/search_dialog.dart';
import '../../screens/spectate/spectate_mode_screen.dart';
import '../../screens/store/crypto_wallet_screen.dart';
import '../../screens/widgets/slimy_card_preview_screen.dart';
import '../../ui_components/spin_wheel/ui/screen/wheel_screen.dart';

// Reactive router provider that rebuilds when navigation state changes
final goRouterProvider = Provider<GoRouter>((ref) {
  // Watch navigation state to trigger rebuilds
  ref.watch(navigationStateProvider);
  final redirectService = ref.read(navigationRedirectServiceProvider);

  // Create a new router instance when state changes
  return GoRouter(
    initialLocation: '/home',
    errorBuilder: (context, state) => const NotFoundScreen(),
    debugLogDiagnostics: true,

    // Simplified redirect logic using the service
    redirect: (context, state) {
      final currentPath = state.fullPath ?? '';
      return redirectService.determineRedirect(currentPath);
    },

    routes: [
      /// 🌟 Root Entry Point
      GoRoute(
        path: '/',
        redirect: (context, state) => '/home',
      ),

      /// 🔐 Auth + Onboarding
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      /// 📚 Onboarding Routes
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      /// 🏠 Main App Routes
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const MainMenuScreen(),
      ),

      /// 🛡️ Admin Routes (Protected & Conditional)
      // Main admin dashboard
      /*GoRoute(
        path: '/admin',
        builder: (context, state) {
          return const AdminRouteWrapper(
            routeName: 'Synaptix Command',
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
        path: '/admin/events-queue',
        name: 'Events Queue Manager',
        builder: (context, state) => const AdminEventQueueScreen(),
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
        builder: (context, state) => QuestionEditorScreen(
          initialQuestion: state.extra as QuestionModel?,
        ),
      ),
      createAdminRoute(
        path: '/admin/encryption-preview',
        name: 'Encryption Preview',
        builder: (context, state) => const EncryptedFilePreview(),
      ),*/

      // --- ADMIN SHELL ROUTE → "Synaptix Command" ---
      // This single ShellRoute handles all '/admin/*' paths.
      // The guard is applied once to the shell, protecting all child routes.
      ShellRoute(
        builder: (context, state, child) => AdminDashboardShell(child: child),
        // Add your admin guard here to protect the entire section
        redirect: enhancedAdminGuard,
        routes: [
          GoRoute(
            path: '/admin',
            name: 'admin-dashboard',
            builder: (context, state) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: '/admin/analytics',
            name: 'admin-analytics',
            builder: (context, state) =>
                const AnalyticsScreen(), // Your real Analytics screen
          ),
          GoRoute(
            path: '/admin/settings',
            name: 'admin-settings',
            builder: (context, state) => const ConfigSettingsScreen(),
          ),
          GoRoute(
            path: '/admin/notifications',
            name: 'admin-notifications',
            builder: (context, state) => const AdminNotificationsScreen(),
          ),
          GoRoute(
            path: '/admin/events',
            name: 'admin-events',
            builder: (context, state) => const AdminEventQueueScreen(),
          ),
          GoRoute(
            path: '/admin/leaderboard-filters',
            name: 'leaderboard-filters',
            builder: (context, state) => const AdminLeaderboardFilterScreen(),
          ),
          GoRoute(
            path: '/admin/encryption',
            name: 'admin-encryption',
            builder: (context, state) => const EncryptionManagerScreen(),
          ),
          GoRoute(
            path: '/admin/config-settings',
            name: 'config-settings',
            builder: (context, state) => const ConfigSettingsScreen(),
          ),
          GoRoute(
            path: '/admin/events-queue',
            name: 'events-queue',
            builder: (context, state) => const AdminEventQueueScreen(),
          ),
          GoRoute(
            path: '/admin/file-import-export',
            name: 'file-import-export',
            builder: (context, state) => const FileImportExportScreen(),
          ),
          GoRoute(
            path: '/admin/question-list',
            name: 'question-list',
            builder: (context, state) => const QuestionListScreen(),
          ),
          GoRoute(
            path: '/admin/question-editor',
            name: 'question-editor',
            builder: (context, state) => QuestionEditorScreen(
              initialQuestion: state.extra as QuestionModel?,
            ),
          ),
          GoRoute(
            path: '/admin/encryption-preview',
            name: 'encryption-preview',
            builder: (context, state) => const EncryptedFilePreview(),
          ),
          GoRoute(
            path: '/admin/users',
            name: 'admin-users',
            builder: (context, state) => const AdminUsersScreen(),
          ),
          GoRoute(
            path: '/admin/audit',
            name: 'admin-audit',
            builder: (context, state) => AdminAuditLogScreen(
              userId: state.uri.queryParameters['userId'],
            ),
          ),
          GoRoute(
            path: '/admin/card-demo',
            name: 'admin-card-demo',
            builder: (context, state) => const SlimyCardPreviewScreen(),
          ),
          GoRoute(
            path: '/admin/splash-selector',
            name: 'admin-splash-selector',
            builder: (context, state) => const SplashSelectorScreen(),
          ),
          GoRoute(
            path: '/admin/audio-studio',
            name: 'admin-audio-studio',
            builder: (context, state) => const AdminAudioPlayerScreen(),
          ),
          GoRoute(
            path: '/admin/store',
            name: 'admin-store-inventory',
            builder: (context, state) => const AdminStoreInventoryScreen(),
          ),
          GoRoute(
            path: '/admin/store/policies',
            name: 'admin-store-policies',
            builder: (context, state) => const AdminStockPolicyScreen(),
          ),
          GoRoute(
            path: '/admin/store/flash-sales',
            name: 'admin-store-flash-sales',
            builder: (context, state) => const AdminFlashSalesScreen(),
          ),
          GoRoute(
            path: '/admin/store/reward-limits',
            name: 'admin-store-reward-limits',
            builder: (context, state) => const AdminRewardLimitsScreen(),
          ),
          GoRoute(
            path: '/admin/store/analytics',
            name: 'admin-store-analytics',
            builder: (context, state) => const AdminStockAnalyticsScreen(),
          ),
        ],
      ),

      /// 🧭 Shell Route with MainNavBar (applies only to these screens)
      /// Synaptix Phase 3 display label mapping:
      ///   /game        → "Synaptix Hub"
      ///   /leaderboard → "Arena"
      ///   /arcade      → "Labs"
      ///   /skills      → "Pathways"
      ///   /profile     → "Journey"
      ///   /messages    → "Circles"
      ///   /admin       → "Command"
      /// Route paths are intentionally unchanged.
      ShellRoute(
          builder: (context, state, child) => MainNavBar(child: child),
          routes: [
            GoRoute(
              path: '/game', // Synaptix Hub
              builder: (context, state) => const GameMenuScreen(),
              redirect: onboardingGuard,
            ),
            GoRoute(
              path: '/store', // Exchange / Store
              builder: (context, state) => const StoreScreen(),
              redirect: onboardingGuard,
            ),
            GoRoute(
              path: '/profile', // Journey
              builder: (context, state) => const ProfileScreen(),
              redirect: onboardingGuard,
            ),
            GoRoute(
              path: '/leaderboard', // Arena
              builder: (context, state) => const LeaderboardScreen(),
              redirect: onboardingGuard,
            ),
            GoRoute(
              path: '/rewards', // Rewards / Unlocks
              builder: (context, state) => const RewardsScreen(),
              redirect: onboardingGuard,
            ),
          ]),

      /// Arcade Hub → "Labs"
      GoRoute(
        path: '/arcade', // Labs
        builder: (context, state) => const ArcadeHubScreen(),
      ),
      GoRoute(
        path: '/arcade/daily-bonus',
        builder: (context, state) => const DailyBonusScreen(),
      ),
      GoRoute(
        path: '/arcade/missions',
        builder: (context, state) => const ArcadeMissionsScreen(),
      ),
      GoRoute(
        path: '/arcade/local-leaderboards',
        builder: (context, state) => const LocalArcadeLeaderboardScreen(),
      ),
      GoRoute(
        path: '/arcade/play',
        name: 'arcade-play',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return ArcadeGameShell(
            game: extra['game'] as ArcadeGameDefinition,
            difficulty: extra['difficulty'] as ArcadeDifficulty,
          );
        },
        redirect: onboardingGuard,
      ),

      /// Leaderboard Routes
      GoRoute(
        path: '/ranking',
        builder: (context, state) => const TierRankScreen(),
      ),

      /// 🏆 Reward Routes
      GoRoute(
        path: '/spin-earn',
        builder: (context, state) => const SpinEarnScreen(),
      ),
      GoRoute(
        path: '/spin-earn/wheel',
        name: 'spin-wheel',
        builder: (context, state) => const WheelScreen(),
        redirect: onboardingGuard,
      ),
      GoRoute(
        path: '/missions',
        builder: (context, state) =>
            const MissionsScreen(), // Your full mission screen
      ),
      GoRoute(
        path: '/challenges',
        name: 'Challenge',
        builder: (context, state) => const ChallengeScreen(),
      ),
      GoRoute(path: '/invite', builder: (context, state) => InviteScreen()),
      // Add this route to test:
      GoRoute(
        path: '/invite-log',
        builder: (context, state) => const InviteLogScreen(),
      ),
      GoRoute(path: '/rewards', builder: (context, state) => RewardsScreen()),
      GoRoute(
          path: '/leaderboard',
          builder: (context, state) => LeaderboardScreen()),
      GoRoute(path: '/settings', builder: (context, state) => SettingsScreen()),

      /// Store Routes
      GoRoute(
          path: '/store-hub',
          name: 'Store Hub',
          builder: (context, state) => StoreHubScreen()),
      GoRoute(
        path: '/offers',
        name: 'Offers',
        redirect: (context, state) => '/store-special',
      ),
      GoRoute(
        path: '/store-special',
        name: 'Store Special',
        builder: (context, state) => const StoreSpecialScreen(),
      ),
      GoRoute(
        path: '/store/daily',
        name: 'Daily Items',
        builder: (context, state) => const DailyItemsScreen(),
      ),
      GoRoute(
          path: '/gifts',
          name: 'Gifts',
          builder: (context, state) => GiftsScreen()),
      GoRoute(
          path: '/store',
          name: 'Store',
          builder: (context, state) => StoreScreen()),
      GoRoute(
        path: '/store/crypto-wallet',
        name: 'crypto-wallet',
        builder: (context, state) => const CryptoWalletScreen(),
        redirect: onboardingGuard,
      ),
      GoRoute(
        path: '/store/payment-return',
        name: 'Store Payment Return',
        builder: (context, state) => StorePaymentReturnScreen(
          mode: StoreReturnMode.purchase,
          queryParameters: state.uri.queryParameters,
        ),
      ),
      GoRoute(
        path: '/store/subscription-return',
        name: 'Store Subscription Return',
        builder: (context, state) => StorePaymentReturnScreen(
          mode: StoreReturnMode.subscription,
          queryParameters: state.uri.queryParameters,
        ),
      ),
      GoRoute(
          path: '/store-premium',
          name: 'Store Premium',
          builder: (context, state) => const StoreSecondaryScreen()),

      /// 🎯 Daily Quiz & Featured Content Routes (Referenced in CarouselSection)
      GoRoute(
        path: '/daily-quiz',
        name: 'Daily Quiz',
        builder: (context, state) => const DailyQuizScreen(),
        redirect: onboardingGuard,
      ),
      GoRoute(
        path: '/monthly-quiz',
        name: 'Monthly Quiz',
        builder: (context, state) => const MonthlyQuizScreen(),
        redirect: onboardingGuard,
      ),
      GoRoute(
        path: '/featured-challenge',
        name: 'Featured Challenge',
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
        builder: (context, state) => const AllClassesScreen(),
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
        path: '/quiz/question',
        builder: (context, state) => const AdaptedQuestionScreen(),
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
        path: '/quiz/play',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is Map<String, dynamic>) {
            final categories = extra['categories'] is List
                ? List<String>.from(extra['categories'] as List)
                : const <String>[];
            final category = (extra['category'] as String?) ??
                (extra['subject'] as String?) ??
                (categories.isNotEmpty ? categories.first : null);
            final questions = extra['questions'] is List
                ? (extra['questions'] as List)
                    .whereType<QuestionModel>()
                    .toList()
                : const <QuestionModel>[];
            final classLevel = extra['classLevel']?.toString();
            final questionCount = (extra['questionCount'] as num?)?.toInt();
            final displayTitle =
                extra['displayTitle']?.toString() ?? extra['title']?.toString();

            final hasLaunchPayload = questions.isNotEmpty ||
                category != null ||
                classLevel != null ||
                questionCount != null;

            if (hasLaunchPayload) {
              return AdaptedQuestionScreen(
                classLevel: classLevel,
                category: category,
                questionCount: questionCount,
                initialQuestions: questions.isEmpty ? null : questions,
                displayTitle: displayTitle,
              );
            }
          }
          return const PlayQuizScreen();
        },
      ),
      GoRoute(
        path: '/favorites-quiz',
        name: 'Favorites Quiz',
        builder: (context, state) => const FavoritesQuizScreen(),
      ),
      GoRoute(
        path: '/quiz/start/:gameMode',
        builder: (context, state) {
          final gameMode = state.pathParameters['gameMode']!;
          return AdaptedQuestionScreen(
            classLevel: AppRouter._getGameModeClassLevel(gameMode),
            category: AppRouter._getGameModeCategory(gameMode),
            questionCount: AppRouter._getGameModeQuestionCount(gameMode),
          );
        },
      ),
      GoRoute(
        path: '/how-to-play/:gameMode',
        builder: (context, state) {
          final gameModeString = state.pathParameters['gameMode']!;
          final isMultiplayer =
              state.uri.queryParameters['isMultiplayer'] == 'true';

          // Convert string to GameMode enum
          final gameMode = GameMode.values.firstWhere(
            (mode) => mode.name == gameModeString,
            orElse: () => GameMode.classic, // Fallback to classic if not found
          );

          return HowToPlayScreen(
            gameMode: gameMode,
            isMultiplayer: isMultiplayer,
          );
        },
      ),
      GoRoute(
        path: '/trivia-transition',
        builder: (context, state) => const TriviaTransitionScreen(),
      ),
      GoRoute(
        path: '/score-summary',
        builder: (context, state) {
          return const ScoreSummaryScreenWrapper();
        },
      ),

      /// Multiplayer game mode routes
      GoRoute(
          path: '/multiplayer',
          name: 'multiplayer',
          builder: (context, state) => MultiplayerHubScreen()),
      GoRoute(
          path: '/multiplayer/find',
          name: 'find-match',
          builder: (context, state) => MatchmakingScreen()),
      GoRoute(
          path: '/multiplayer/rooms',
          name: 'find-room',
          builder: (context, state) => RoomLobbyScreen()),
      GoRoute(
          path: '/multiplayer/match',
          name: 'live-match',
          builder: (context, state) => LiveMatchScreen()),
      GoRoute(
        path: '/multiplayer/matchmaking/:gameMode',
        name: 'multiplayer-matchmaking',
        builder: (context, state) {
          final gameMode =
              normalizeGameModeName(state.pathParameters['gameMode']!);
          return MultiplayerGameMatchmakingScreen(gameMode: gameMode);
        },
      ),

      GoRoute(
        path: '/multiplayer/quiz/:gameMode',
        name: 'multiplayer-quiz',
        builder: (context, state) {
          final gameMode =
              normalizeGameModeName(state.pathParameters['gameMode']!);
          return MultiplayerQuestionScreen(gameMode: gameMode);
        },
      ),

      GoRoute(
        path: '/multiplayer/results/:gameMode',
        name: 'multiplayer-results',
        builder: (context, state) {
          final gameMode =
              normalizeGameModeName(state.pathParameters['gameMode']!);
          return MultiplayerResultsScreen(gameMode: gameMode);
        },
      ),
      /*GoRoute(
          path: '/multiplayer/rooms/:roomId',
          builder: (context, state) {
            final roomId = state.pathParameters['roomId']!;
            return RoomLobbyScreen(roomId: roomId);
          }
      ),*/

      /// 🎮 Mini Games
      GoRoute(
        path: '/mini-games',
        name: 'mini-games',
        builder: (context, state) => const MiniGamesHubScreen(),
        redirect: onboardingGuard,
      ),
      GoRoute(
        path: '/sun-moon-puzzle',
        name: 'sunmoon-puzzle',
        builder: (context, state) => const SunMoonPuzzleScreen(),
        redirect: onboardingGuard,
      ),
      GoRoute(
        path: '/connections-puzzle',
        name: 'connections-puzzle',
        builder: (context, state) => const ConnectionsPuzzleScreen(),
        redirect: onboardingGuard,
      ),
      GoRoute(
        path: '/flow-connect',
        name: 'flow-connect',
        builder: (context, state) => const FlowConnectPuzzleScreen(),
        redirect: onboardingGuard,
      ),
      GoRoute(
        path: '/sudoku-puzzle',
        name: 'sudoku-puzzle',
        builder: (context, state) => const SudokuPuzzleScreen(),
        redirect: onboardingGuard,
      ),
      GoRoute(
        path: '/game-2048',
        name: 'game2048',
        builder: (context, state) => const Game2048Screen(),
        redirect: onboardingGuard,
      ),
      GoRoute(
        path: '/memory-match',
        name: 'memoryMatch',
        builder: (context, state) => const MemoryMatchScreen(),
        redirect: onboardingGuard,
      ),
      GoRoute(
        path: '/word-search',
        name: 'wordSearch',
        builder: (context, state) => const WordSearchScreen(),
        redirect: onboardingGuard,
      ),
      GoRoute(
        path: '/crossword',
        name: 'crossword',
        builder: (context, state) => const CrosswordScreen(),
        redirect: onboardingGuard,
      ),

      /// 📚 Learn Hub
      GoRoute(
        path: '/learn-hub',
        name: 'learn-hub',
        builder: (context, state) => const LearnHubScreen(),
        redirect: onboardingGuard,
      ),
      GoRoute(
        path: '/learn-hub/module/:moduleId',
        name: 'module-detail',
        builder: (context, state) => ModuleDetailScreen(
          moduleId: state.pathParameters['moduleId']!,
        ),
        redirect: onboardingGuard,
      ),
      GoRoute(
        path: '/learn-hub/module/:moduleId/lessons',
        name: 'module-lessons',
        builder: (context, state) => LessonScreen(
          moduleId: state.pathParameters['moduleId']!,
        ),
        redirect: onboardingGuard,
      ),
      GoRoute(
        path: '/learn-hub/module/:moduleId/complete',
        name: 'module-complete',
        builder: (context, state) => ModuleCompleteScreen(
          moduleId: state.pathParameters['moduleId']!,
          completionData: state.extra is ModuleCompleteResponseDto
              ? state.extra as ModuleCompleteResponseDto
              : null,
        ),
        redirect: onboardingGuard,
      ),

      /// 👤 USER PROFILE & SOCIAL
      GoRoute(
        path: '/preferences',
        name: 'preferences',
        builder: (context, state) => const PreferencesScreen(),
      ),
      GoRoute(
        path: '/profile-selection',
        name: 'Profile Selection',
        builder: (context, state) => const ProfileSelectionScreen(),
      ),
      GoRoute(
        path: '/friends',
        name: 'Friends',
        builder: (context, state) => const FriendsScreen(),
      ),
      GoRoute(
        path: '/friends/add-username',
        name: 'Add Friend By Username',
        builder: (context, state) => const AddFriendByUsernameScreen(),
      ),
      GoRoute(
        path: '/profile/enhanced/:userId',
        name: 'enhanced-profile',
        builder: (context, state) => EnhancedProfileScreen(
          userId: state.pathParameters['userId']!,
          currentUserId: state.uri.queryParameters['currentUserId'] ?? '',
          isOwnProfile: state.uri.queryParameters['isOwnProfile'] == 'true',
        ),
        redirect: onboardingGuard,
      ),
      GoRoute(
        path: '/profile/mutual-friends/:userId',
        name: 'mutual-friends',
        builder: (context, state) => MutualFriendsScreen(
          userId: state.pathParameters['userId']!,
          currentUserId: state.extra as String? ?? '',
        ),
        redirect: onboardingGuard,
      ),
      GoRoute(
        path: '/spectate/:gameId',
        name: 'spectate',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return SpectateModeScreen(
            gameId: state.pathParameters['gameId']!,
            currentUserId: extra['currentUserId'] as String? ?? '',
            currentUserDisplayName:
                extra['currentUserDisplayName'] as String? ?? '',
          );
        },
        redirect: onboardingGuard,
      ),
      GoRoute(
        path: '/avatar-selection',
        name: 'Avatar Selection',
        builder: (context, state) => const AvatarSelectionScreen(),
      ),
      GoRoute(
        path: '/multiplayer',
        name: 'Multiplayer',
        builder: (context, state) => const MultiplayerScreen(),
        redirect: onboardingGuard,
      ),
      GoRoute(
        path: '/messages', // Circles
        name: 'Messages',
        builder: (context, state) => const MessagesScreen(),
        redirect: onboardingGuard,
      ),
      GoRoute(
        path: '/messages/detail/:conversationId',
        name: 'message-detail',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return MessageDetailScreen(
            conversationId: state.pathParameters['conversationId']!,
            contactName: extra['contactName'] as String? ?? 'Direct Message',
            contactAvatar: extra['contactAvatar'] as String?,
            isOnline: extra['isOnline'] as bool? ?? false,
            currentActivity: extra['currentActivity'] as String?,
          );
        },
        redirect: onboardingGuard,
      ),
      GoRoute(
        path: '/messages/search',
        name: 'messages-search',
        pageBuilder: (context, state) => const MaterialPage(
          fullscreenDialog: true,
          child: SearchDialog(),
        ),
        redirect: onboardingGuard,
      ),
      GoRoute(
        path: '/messages/add-friend',
        name: 'messages-add-friend',
        pageBuilder: (context, state) => const MaterialPage(
          fullscreenDialog: true,
          child: AddFriendDialog(),
        ),
        redirect: onboardingGuard,
      ),
      GoRoute(
        path: '/messages/requests',
        name: 'messages-requests',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return MaterialPage(
            fullscreenDialog: true,
            child: MessageRequestDialog(
              requestCount: extra['requestCount'] as int? ?? 0,
              onRequestHandled:
                  extra['onRequestHandled'] as void Function(bool)? ?? (_) {},
            ),
          );
        },
        redirect: onboardingGuard,
      ),
      GoRoute(
        path: '/messages/new',
        name: 'messages-new',
        pageBuilder: (context, state) => const MaterialPage(
          fullscreenDialog: true,
          child: CreateDMDialog(),
        ),
        redirect: onboardingGuard,
      ),
      GoRoute(
        path: '/messages/group/:groupId/settings',
        name: 'group-settings',
        builder: (context, state) => GroupSettingsScreen(
          groupId: state.pathParameters['groupId']!,
          currentUserId: state.extra as String? ?? '',
        ),
        redirect: onboardingGuard,
      ),

      /// ⚡ Quick Actions Routes (Referenced in Enhanced GridMenuSection)
      GoRoute(
        path: '/history',
        name: 'History',
        builder: (context, state) => const QuizHistoryScreen(),
        redirect: onboardingGuard,
      ),
      GoRoute(
        path: '/favorites',
        name: 'Favorites',
        builder: (context, state) => const FavoritesScreen(),
        redirect: onboardingGuard,
      ),
      GoRoute(
        path: '/all-actions',
        name: 'All Actions',
        builder: (context, state) => const AllActionsScreen(),
        redirect: onboardingGuard,
      ),

      /// 🎮 Enhanced Quiz Routes (Referenced in TopMenuSection)
      GoRoute(
        path: '/achievements',
        name: 'Achievements',
        builder: (context, state) => const AchievementsScreen(),
        redirect: onboardingGuard,
      ),

      GoRoute(
        path: '/music',
        name: 'Music',
        builder: (context, state) => const MusicScreen(),
      ),
      GoRoute(
        path: '/skill-theme',
        name: 'Skill Theme',
        builder: (context, state) => const SkillThemeScreen(),
      ),

      GoRoute(
        path: '/help',
        name: 'Help & Feedback',
        builder: (context, state) => const HelpScreen(),
      ),
      GoRoute(
        path: '/report',
        name: 'Report',
        builder: (context, state) => const ReportScreen(),
      ),

      /// 🧩 UTILITY & MISC
      GoRoute(
        path: '/search',
        name: 'Search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/alerts',
        name: 'Alerts',
        redirect: (context, state) => '/notifications?tab=alerts',
      ),
      GoRoute(
        path: '/notifications',
        name: 'Notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/notifications/detail',
        name: 'notification-detail',
        builder: (context, state) => NotificationDetailScreen(
          notification: state.extra as InboxItem,
        ),
        redirect: onboardingGuard,
      ),
      GoRoute(
        path: '/leaderboard/player',
        name: 'leaderboard-player',
        builder: (context, state) => UserProfileScreen(
          entry: state.extra as LeaderboardEntry,
        ),
        redirect: onboardingGuard,
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

      /// Skills Tree → "Pathways" / "Neural Pathways"
      GoRoute(
        path: '/skills', // Pathways
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
        path: '/skill-branch/:branchId',
        name: 'skillBranch',
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

  // Helper methods for game mode configuration
  static String? _getGameModeCategory(String gameMode) {
    switch (gameMode) {
      case 'classic':
        return 'mixed';
      case 'topicExplorer':
        return null; // User will choose
      case 'survival':
        return 'general';
      case 'arena':
        return 'mixed'; // Treasure Mine
      case 'teams':
        return 'general'; // Survival Arena
      case 'daily':
        return 'daily_challenge';
      default:
        return 'mixed';
    }
  }

  static int _getGameModeQuestionCount(String gameMode) {
    switch (gameMode) {
      case 'classic':
        return 10;
      case 'topicExplorer':
        return 15;
      case 'survival':
        return 20; // Keep going until wrong
      case 'arena':
        return 15; // Treasure Mine
      case 'teams':
        return 20; // Survival Arena
      case 'daily':
        return 5;
      default:
        return 10;
    }
  }

  static String _getGameModeClassLevel(String gameMode) {
    switch (gameMode) {
      case 'classic':
        return '6';
      case 'topicExplorer':
        return '7';
      case 'survival':
        return '8';
      case 'arena':
        return '8'; // Treasure Mine - Middle school
      case 'teams':
        return '10'; // Survival Arena - High school
      case 'daily':
        return '9';
      default:
        return '6';
    }
  }
}
