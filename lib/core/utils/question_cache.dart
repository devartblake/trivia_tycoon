import 'package:trivia_tycoon/core/services/storage/app_cache_service.dart';
import '../../game/models/question_model.dart';

class QuestionCache {
  static final Map<String, List<QuestionModel>> _memoryCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheLifespan = Duration(minutes: 10);
  static late AppCacheService appCache;

  /// Saves to memory + Hive
  static Future<void> save(String key, List<QuestionModel> questions) async {
    _memoryCache[key] = questions;
    _cacheTimestamps[key] = DateTime.now();
    await appCache.saveQuestionCache(key, questions);
  }

  /// Loads from memory or Hive
  static Future<List<QuestionModel>> load(String key) async {
    final now = DateTime.now();

    if (_memoryCache.containsKey(key) &&
        now.difference(_cacheTimestamps[key] ?? DateTime(2000)).inMinutes <
            _cacheLifespan.inMinutes) {
      return _memoryCache[key]!;
    }

    final cached = await appCache.loadQuestionCache(key);
    if (cached.isNotEmpty) {
      _memoryCache[key] = cached;
      _cacheTimestamps[key] = now;
    }

    return cached;
  }

  /// Optional clear for manual invalidation
  static Future<void> clear(String key) async {
    _memoryCache.remove(key);
    _cacheTimestamps.remove(key);
    await appCache.clearQuestionCache(key);
  }
}
