import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../../game/models/question_model.dart';

class QuestionLoader {
  /// Loads questions from a prioritized list of asset paths
  static Future<List<QuestionModel>> loadFromAssets({
    List<String> fallbackAssets = const [],
    bool shuffle = true,
    int limit = 10,
    int? difficultyFilter,
    required String category,
  }) async {
    for (final asset in fallbackAssets) {
      try {
        final jsonString = await rootBundle.loadString(asset);
        final jsonData = json.decode(jsonString) as List;
        var questions = jsonData.map((e) => QuestionModel.fromJson(e)).toList();

        // Optional: filter by difficulty
        if (difficultyFilter != null) {
          questions = questions.where((q) => q.difficulty == difficultyFilter).toList();
        }

        if (shuffle) {
          questions.shuffle();
        }

        return questions.take(limit).toList();
      } catch (e) {
        if (kDebugMode) print('⚠️ Could not load $asset: $e');
        continue;
      }
    }

    return [];
  }
}
