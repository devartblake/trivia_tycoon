import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';

class WordSearchDataLoader {
  static Future<List<String>> loadWords(String assetPath,
      {String? difficulty}) async {
    try {
      final jsonString = await rootBundle.loadString(assetPath);
      final jsonData = json.decode(jsonString);

      List<String> words = [];

      if (jsonData is List) {
        // New format: [{"word": "CAT", "difficulty": "easy"}, ...]
        for (var item in jsonData) {
          if (item is Map && item.containsKey('word')) {
            // Filter by difficulty if specified
            if (difficulty == null || item['difficulty'] == difficulty) {
              words.add(item['word'].toString().toUpperCase());
            }
          } else if (item is String) {
            // Old format: ["WORD1", "WORD2", ...]
            words.add(item.toUpperCase());
          }
        }
      } else if (jsonData is Map && jsonData.containsKey('words')) {
        // Alternative format: {"words": [...]}
        words = List<String>.from(
            jsonData['words'].map((w) => w.toString().toUpperCase()));
      }

      if (words.isEmpty) {
        throw Exception('No words found in JSON');
      }

      // Shuffle to get random selection
      words.shuffle();

      return words;
    } catch (e) {
      LogManager.debug('Error loading words: $e');
      // Fallback words if file not found
      return [
        'FLUTTER',
        'DART',
        'WIDGET',
        'STATE',
        'BUILD',
        'RENDER',
        'LAYOUT',
        'PAINT',
      ];
    }
  }
}
