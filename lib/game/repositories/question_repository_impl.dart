import '../../core/repositories/question_repository.dart';
import '../../core/services/question/question_service.dart';
import '../models/question_model.dart';
import '../services/question_hub_service.dart';
import '../services/quiz_category.dart';

class QuestionRepositoryImpl implements QuestionRepository {
  QuestionRepositoryImpl({
    required QuestionService questionService,
    required QuestionHubService questionHubService,
  })  : _questionService = questionService,
        _questionHubService = questionHubService;

  final QuestionService _questionService;
  final QuestionHubService _questionHubService;

  @override
  Future<List<QuestionModel>> getQuestionsForCategory({
    required String category,
    int amount = 10,
    int? difficulty,
  }) {
    return _questionService.fetchQuestionsWithFallback(
      amount: amount,
      category: category,
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
}
