import '../../game/models/question_model.dart';
import '../../game/services/quiz_category.dart';

abstract class QuestionRepository {
  Future<List<QuestionModel>> getQuestionsForCategory({
    required String category,
    int amount = 10,
    int? difficulty,
  });

  Future<List<QuestionModel>> getDailyQuestions({int count = 5});

  Future<List<QuizCategory>> getAvailableCategories();

  Future<Map<String, dynamic>> getQuestionStats();

  Future<Map<String, dynamic>> getDatasetInfo();

  Future<Map<String, dynamic>> getCategoryStats(QuizCategory category);
}
