import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:trivia_tycoon/core/services/settings/quiz_progress_service.dart';
import 'package:trivia_tycoon/core/utils/question_cache.dart';
import '../../../game/models/question_model.dart';
import '../api_service.dart';
import '../../utils/question_loader.dart';

class QuestionService {
  final ApiService apiService;
  final QuizProgressService quizProgressService;

  static final Map<String, List<QuestionModel>> _memoryCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheLifespan = Duration(minutes: 20);

  QuestionService({required this.apiService, required this.quizProgressService});

  /// Attempts to fetch questions from the server, falling back to local if failed
  /// Combines cache + loader + server fallback
  Future<List<QuestionModel>> fetchQuestionsWithFallback({
    int amount = 10,
    String category = 'general',
    int? difficulty,
  }) async {
    final cacheKey = '$category-$difficulty-$amount';
    final cached = await QuestionCache.load(cacheKey);
    if (cached.isNotEmpty) return cached;

    try {
      final fetched = await fetchQuestionsFromServer(category, amount: amount);
      if (fetched.isNotEmpty) {
        await QuestionCache.save(cacheKey, fetched);
        return fetched;
      }
    } catch (e) {
      if (kDebugMode) print("🌐 Server fetch failed: $e");
    }

    // Example: Multi-fallback list
    final fallback = await QuestionLoader.loadFromAssets(
      fallbackAssets: [
        'assets/questions/extended_questions.json',
        'assets/questions/media_questions.json',
        'assets/questions/questions.json',
        'assets/questions/questions_$category.json',
        'assets/questions/questions_general.json',
        'assets/questions/questions_kids.json',
        'assets/questions/questions_offline_pack.json',
        'assets/questions/questions_science.json',
      ],
      shuffle: true,
      limit: amount,
      category: category,
      difficultyFilter: difficulty,
    );

    await QuestionCache.save(cacheKey, fallback);
    return fallback;
  }

  /// ✅ Fetches questions from the API (remote)
  Future<List<QuestionModel>> fetchQuestionsFromServer(String category, {int amount = 10}) async {
    final data = await apiService.fetchQuestions(amount: amount, category: category);
    return data.map((json) => QuestionModel.fromJson(json)).toList();
  }

  /// ✅ Loads fallback local questions (from assets with filtering, caching, and logging)
  Future<List<QuestionModel>> fetchLocalQuestions({
    List<String> fallbackAssets = const ['assets/data/questions/questions.json'],
    String? category,
    int? difficulty,
  }) async {
    final now = DateTime.now();
    final cacheKey = 'local_${category ?? 'all'}_${difficulty ?? 'any'}';

    // 🧠 In-memory cache check
    if (_memoryCache.containsKey(cacheKey) &&
        now.difference(_cacheTimestamps[cacheKey] ?? DateTime(2000)).inMinutes <
            _cacheLifespan.inMinutes) {
      return _memoryCache[cacheKey]!;
    }

    for (final asset in fallbackAssets) {
      try {
        final jsonString = await rootBundle.loadString(asset);
        final jsonData = json.decode(jsonString) as List;

        final parsed = jsonData
            .map((e) => QuestionModel.fromJson(e))
            .where((q) {
          final matchesCategory = category == null || q.category.toLowerCase() == category.toLowerCase();
          final matchesDifficulty = difficulty == null || q.difficulty == difficulty;
          return matchesCategory && matchesDifficulty;
        })
            .toList();

        if (parsed.isNotEmpty) {
          _memoryCache[cacheKey] = parsed;
          _cacheTimestamps[cacheKey] = now;

          if (kDebugMode) {
            print('✅ Loaded ${parsed.length} from $asset (category: $category, difficulty: $difficulty)');
          }

          return parsed;
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Failed to load from $asset: $e');
        }
      }
    }

    return [];
  }

  /// 💾 Save quiz progress
  Future<void> saveQuizProgress(String quizId, int score) async {
    // Retrieve current quiz progress
    Map<String, dynamic> progress = await quizProgressService.getQuizProgress();
    // Update progress for the specific quiz
    progress[quizId] = score;
    // Save updated progress map
    await quizProgressService.saveQuizProgress(progress);
  }

  /// 📊 Load quiz progress
  Future<int> getQuizProgress(String quizId) async {
    Map<String, dynamic> progress = await quizProgressService.getQuizProgress();
    // Return score for the specific quiz or 0 if not found
    return progress[quizId] ?? 0;
  }
}
