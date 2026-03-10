import '../../game/models/question_model.dart';
import '../../game/models/game_mode.dart';
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

  Future<Map<String, dynamic>> getClassStats(String classId);

  Future<List<QuestionModel>> getMixedQuiz({
    int questionCount = 10,
    List<String>? categories,
    List<String>? difficulties,
    bool balanceDifficulties = false,
  });

  Future<List<QuestionModel>> getQuestionsForMode({
    required GameMode mode,
    int amount = 10,
    String? category,
    int? difficulty,
  });

  Future<List<QuestionModel>> getMultiplayerQuestions({
    int amount = 10,
    String? category,
  });
}
