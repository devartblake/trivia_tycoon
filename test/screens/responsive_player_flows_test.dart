import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:trivia_tycoon/core/models/question_validation_models.dart';
import 'package:trivia_tycoon/core/repositories/question_repository.dart';
import 'package:trivia_tycoon/core/services/api_service.dart';
import 'package:trivia_tycoon/core/services/event_queue_service.dart';
import 'package:trivia_tycoon/core/services/settings/general_key_value_storage_service.dart';
import 'package:trivia_tycoon/core/services/settings/multi_profile_service.dart';
import 'package:trivia_tycoon/core/services/settings/player_profile_service.dart';
import 'package:trivia_tycoon/game/controllers/coin_balance_notifier.dart';
import 'package:trivia_tycoon/game/analytics/providers/analytics_providers.dart';
import 'package:trivia_tycoon/game/analytics/services/analytics_service.dart';
import 'package:trivia_tycoon/game/models/answer.dart';
import 'package:trivia_tycoon/game/models/conversation_models.dart';
import 'package:trivia_tycoon/game/models/game_mode.dart';
import 'package:trivia_tycoon/game/models/question_model.dart';
import 'package:trivia_tycoon/game/providers/message_providers.dart';
import 'package:trivia_tycoon/game/providers/profile_providers.dart'
    as profile_data;
import 'package:trivia_tycoon/game/providers/question_providers.dart'
    as question_data;
import 'package:trivia_tycoon/game/services/quiz_category.dart';
import 'package:trivia_tycoon/screens/messages/messages_screen.dart';
import 'package:trivia_tycoon/screens/profile/profile_selection_screen.dart';
import 'package:trivia_tycoon/screens/question/question_screen.dart';
import 'package:trivia_tycoon/screens/question/widgets/challenges/daily_quiz_widget.dart';
import 'package:trivia_tycoon/screens/question/widgets/challenges/featured_challenge_widget.dart';
import 'package:trivia_tycoon/screens/question/widgets/challenges/monthly_quiz_widget.dart';
import 'package:trivia_tycoon/synaptix/mode/synaptix_mode_notifier.dart';
import 'package:trivia_tycoon/synaptix/mode/synaptix_mode_provider.dart';

void main() {
  group('responsive player flows', () {
    for (final size in const [
      Size(390, 800),
      Size(900, 900),
      Size(1280, 900),
    ]) {
      testWidgets('profile selection renders at ${size.width}px',
          (tester) async {
        await _setSurface(tester, size);
        await tester.pumpWidget(_profileSelectionHarness());
        await tester.pumpAndSettle();

        expect(find.text("Who's playing?"), findsOneWidget);
        expect(find.text('Player One'), findsOneWidget);
        expect(find.text('Manage Profiles'), findsOneWidget);
      });

      testWidgets('messages renders at ${size.width}px', (tester) async {
        await _setSurface(tester, size);
        await tester.pumpWidget(_messagesHarness());
        await tester.pumpAndSettle();

        expect(find.text('Messages'), findsOneWidget);
        expect(find.text('Study Squad'), findsWidgets);
        if (size.width >= 1100) {
          expect(find.text('Select a conversation'), findsOneWidget);
        }
      });

      testWidgets('quiz hub renders at ${size.width}px', (tester) async {
        await _setSurface(tester, size);
        await tester.pumpWidget(_quizHarness());
        await tester.pumpAndSettle();

        expect(find.text('Play Quiz'), findsOneWidget);
        expect(find.text('Quick Actions'), findsOneWidget);
        expect(find.text('Explore Classes'), findsOneWidget);
      });
    }
  });
}

Future<void> _setSurface(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _profileSelectionHarness() {
  final router = GoRouter(
    initialLocation: '/profile-selection',
    routes: [
      GoRoute(
        path: '/profile-selection',
        builder: (_, __) => const ProfileSelectionScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (_, __) => const Scaffold(body: Text('route:/home')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      profilesProvider.overrideWith((_) async => _profiles),
      activeProfileProvider.overrideWith((_) async => _profiles.first),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

Widget _messagesHarness() {
  final router = GoRouter(
    initialLocation: '/messages',
    routes: [
      GoRoute(
        path: '/messages',
        builder: (_, __) => const MessagesScreen(),
      ),
      GoRoute(
        path: '/messages/detail/:conversationId',
        builder: (context, state) => Scaffold(
          body: Text('route:${state.uri.path}'),
        ),
      ),
      GoRoute(
        path: '/messages/search',
        builder: (_, __) => const Scaffold(body: Text('route:/messages/search')),
      ),
      GoRoute(
        path: '/messages/add-friend',
        builder: (_, __) =>
            const Scaffold(body: Text('route:/messages/add-friend')),
      ),
      GoRoute(
        path: '/messages/requests',
        builder: (_, __) =>
            const Scaffold(body: Text('route:/messages/requests')),
      ),
      GoRoute(
        path: '/messages/new',
        builder: (_, __) => const Scaffold(body: Text('route:/messages/new')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      analyticsServiceProvider.overrideWithValue(_NoopAnalyticsService()),
      synaptixModeProvider
          .overrideWith((_) => SynaptixModeNotifier(PlayerProfileService())),
      currentUserIdProvider.overrideWith((_) => 'local-guest'),
      messageRealtimeSyncProvider.overrideWith((_) {}),
      userConversationsProvider('local-guest')
          .overrideWith((_) async => _conversations),
      directMessageUnreadCountProvider('local-guest')
          .overrideWith((_) async => 0),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

Widget _quizHarness() {
  final router = GoRouter(
    initialLocation: '/quiz',
    routes: [
      GoRoute(
        path: '/quiz',
        builder: (_, __) => const QuestionScreen(),
      ),
      GoRoute(
        path: '/:path(.*)',
        builder: (context, state) => Scaffold(
          body: Text('route:${state.uri.path}'),
        ),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      question_data.questionRepositoryProvider
          .overrideWithValue(_FakeQuestionRepository()),
      profile_data.userProfileProvider
          .overrideWith((_) => const {'username': 'Player One'}),
      profile_data.coinBalanceProvider
          .overrideWith((_) => CoinBalanceNotifier(_MemoryStorage(1000))),
      dailyQuizProvider.overrideWith(
        (_) async => DailyQuizData(
          questions: _questions,
          totalQuestions: _questions.length,
          totalXPReward: 75,
          isCompleted: false,
        ),
      ),
      dailyQuizStatusProvider.overrideWith(
        (_) => const DailyQuizStatus(
          isAvailable: true,
          timeUntilReset: '8h',
          canPlay: true,
          completionStreak: 2,
        ),
      ),
      monthlyQuizPreviewProvider.overrideWith(
        (_) async => MonthlyQuizPreview(
          theme: 'science',
          monthName: 'January',
          totalQuestions: 15,
          previewQuestions: _questions,
          difficulty: 'Medium',
          xpReward: 375,
          isCompleted: false,
          completionRate: 0,
        ),
      ),
      featuredChallengeProvider.overrideWith(
        (_) async => FeaturedChallenge(
          title: 'Science Masters Quiz',
          description: 'Test your knowledge',
          questions: _questions,
          totalQuestions: _questions.length,
          difficulty: 'Expert',
          xpMultiplier: 2,
          bonusReward: 'Badge',
          timeLimit: 600,
          isUnlocked: true,
          participantCount: 1200,
          completionRate: 0.2,
        ),
      ),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

final _profiles = [
  ProfileData(
    id: 'p1',
    name: 'Player One',
    ageGroup: 'teens',
    createdAt: DateTime(2026, 1, 1),
    lastActive: DateTime(2026, 1, 2),
  ),
  ProfileData(
    id: 'p2',
    name: 'Player Two',
    ageGroup: 'adults',
    createdAt: DateTime(2026, 1, 1),
    lastActive: DateTime(2026, 1, 2),
  ),
];

final _conversations = [
  Conversation(
    id: 'c1',
    type: ConversationType.direct,
    participantIds: const ['local-guest', 'friend-1'],
    name: 'Study Squad',
    lastMessageTime: DateTime(2026, 1, 2),
    metadata: const {'lastMessagePreview': 'Ready for another round?'},
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 2),
  ),
];

final _questions = [
  QuestionModel(
    id: 'q1',
    category: 'science',
    question: 'What is water made of?',
    answers: [
      Answer(text: 'Hydrogen and oxygen', isCorrect: true),
      Answer(text: 'Carbon and iron', isCorrect: false),
    ],
    correctAnswer: 'Hydrogen and oxygen',
    type: 'multiple_choice',
    difficulty: 1,
    options: const ['Hydrogen and oxygen', 'Carbon and iron'],
    correctIndex: 0,
  ),
];

class _FakeQuestionRepository implements QuestionRepository {
  @override
  Future<List<QuestionModel>> getQuestionsForCategory({
    required String category,
    int amount = 10,
    int? difficulty,
    String mode = 'practice',
    String? playerId,
  }) async =>
      _questions;

  @override
  Future<List<QuestionModel>> getDailyQuestions({int count = 5}) async =>
      _questions;

  @override
  Future<List<QuizCategory>> getAvailableCategories() async => const [
        QuizCategory.science,
        QuizCategory.history,
        QuizCategory.technology,
        QuizCategory.mathematics,
        QuizCategory.geography,
        QuizCategory.arts,
      ];

  @override
  Future<Map<String, dynamic>> getQuestionStats() async => {
        'summary': {
          'totalQuestions': 120,
          'totalDatasets': 3,
          'categoryCounts': {
            'science': 40,
            'history': 30,
          },
        },
      };

  @override
  Future<Map<String, dynamic>> getDatasetInfo() async => const {};

  @override
  Future<Map<String, dynamic>> getCategoryStats(QuizCategory category) async =>
      const {'questionCount': 20};

  @override
  Future<Map<String, dynamic>> getClassStats(String classId) async =>
      const {'questionCount': 12};

  @override
  Future<List<QuestionModel>> getMixedQuiz({
    int questionCount = 10,
    List<String>? categories,
    List<String>? difficulties,
    bool balanceDifficulties = false,
    String mode = 'practice',
    String? playerId,
  }) async =>
      _questions;

  @override
  Future<List<QuestionModel>> getQuestionsForMode({
    required GameMode mode,
    int amount = 10,
    String? category,
    int? difficulty,
    String? playerId,
  }) async =>
      _questions;

  @override
  Future<List<QuestionModel>> getMultiplayerQuestions({
    int amount = 10,
    String? category,
    int? difficulty,
  }) async =>
      _questions;

  @override
  Future<QuestionAnswerCheckResult> checkAnswer({
    required QuestionModel question,
    required String selectedAnswer,
  }) async =>
      QuestionAnswerCheckResult(
        questionId: question.id,
        selectedAnswer: selectedAnswer,
        isCorrect: question.isCorrectAnswer(selectedAnswer),
        correctAnswer: question.correctAnswer,
      );

  @override
  Future<List<QuestionAnswerCheckResult>> checkAnswerBatch({
    required List<QuestionAnswerSubmission> submissions,
  }) async {
    final results = <QuestionAnswerCheckResult>[];
    for (final submission in submissions) {
      results.add(
        await checkAnswer(
          question: submission.question,
          selectedAnswer: submission.selectedAnswer,
        ),
      );
    }
    return results;
  }
}

class _MemoryStorage extends GeneralKeyValueStorageService {
  _MemoryStorage(this.initialCoins);

  final int initialCoins;
  final Map<String, int> _ints = {};

  @override
  Future<int> getInt(String key) async => _ints[key] ?? initialCoins;

  @override
  Future<void> setInt(String key, int value) async {
    _ints[key] = value;
  }
}

class _NoopAnalyticsService extends AnalyticsService {
  _NoopAnalyticsService()
      : super(
          ApiService(baseUrl: 'https://example.test', initializeCache: false),
          EventQueueService(),
        );

  @override
  Future<void> trackEvent(String eventName, Map<String, dynamic> data) async {}
}
