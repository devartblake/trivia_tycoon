import '../../core/models/question_validation_models.dart';
import '../../core/repositories/question_repository.dart';
import '../models/game_mode.dart';
import '../models/question_model.dart';
import '../services/question_hub_service.dart';
import '../services/quiz_category.dart';

class QuestionRepositoryImpl implements QuestionRepository {
  QuestionRepositoryImpl({
    required QuestionHubService questionHubService,
  }) : _questionHubService = questionHubService;

  final QuestionHubService _questionHubService;

  @override
  Future<List<QuestionModel>> getQuestionsForCategory({
    required String category,
    int amount = 10,
    int? difficulty,
  }) {
    return _questionHubService.getQuestionsForCategory(
      category: category,
      amount: amount,
      difficulty: difficulty,
    );
  }

  @override
  Future<List<QuestionModel>> getDailyQuestions({int count = 5}) {
    return _questionHubService.getDailyQuiz(questionCount: count);
  }

  @override
  Future<List<QuizCategory>> getAvailableCategories() {
    return _questionHubService.getAvailableCategories();
  }

  @override
  Future<Map<String, dynamic>> getQuestionStats() {
    return _questionHubService.getQuestionStats();
  }

  @override
  Future<Map<String, dynamic>> getDatasetInfo() {
    return _questionHubService.getDatasetInfo();
  }

  @override
  Future<Map<String, dynamic>> getCategoryStats(QuizCategory category) {
    return _questionHubService.getCategoryStats(category);
  }

  @override
  Future<Map<String, dynamic>> getClassStats(String classId) {
    return _questionHubService.getClassStats(classId);
  }

  @override
  Future<List<QuestionModel>> getMixedQuiz({
    int questionCount = 10,
    List<String>? categories,
    List<String>? difficulties,
    bool balanceDifficulties = false,
  }) {
    return _questionHubService.getMixedQuiz(
      questionCount: questionCount,
      categories: categories,
      difficulties: difficulties,
      balanceDifficulties: balanceDifficulties,
    );
  }

  @override
  Future<List<QuestionModel>> getQuestionsForMode({
    required GameMode mode,
    int amount = 10,
    String? category,
    int? difficulty,
  }) {
    switch (mode) {
      case GameMode.daily:
        return getDailyQuestions(count: amount);
      case GameMode.arena:
      case GameMode.teams:
        return getMultiplayerQuestions(
          amount: amount,
          category: category,
        );
      case GameMode.topicExplorer:
        return getQuestionsForCategory(
          category: category ?? 'general',
          amount: amount,
          difficulty: difficulty,
        );
      case GameMode.classic:
      case GameMode.survival:
        return getMixedQuiz(questionCount: amount);
    }
  }

  @override
  Future<List<QuestionModel>> getMultiplayerQuestions({
    int amount = 10,
    String? category,
  }) {
    final categories = category == null ? null : <String>[category];
    return getMixedQuiz(
      questionCount: amount,
      categories: categories,
      balanceDifficulties: true,
    );
  }

  @override
  Future<QuestionAnswerCheckResult> checkAnswer({
    required QuestionModel question,
    required String selectedAnswer,
  }) {
    return _questionHubService.checkAnswer(
      question: question,
      selectedAnswer: selectedAnswer,
    );
  }

  @override
  Future<List<QuestionAnswerCheckResult>> checkAnswerBatch({
    required List<QuestionAnswerSubmission> submissions,
  }) {
    return _questionHubService.checkAnswerBatch(submissions: submissions);
  }
}
