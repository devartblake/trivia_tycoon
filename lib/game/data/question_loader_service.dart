import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/question_model.dart';

class QuestionDataset {
  final String name;
  final String path;
  final String? description;
  final List<String> categories;
  final Map<String, dynamic>? metadata;

  const QuestionDataset({
    required this.name,
    required this.path,
    this.description,
    this.categories = const [],
    this.metadata,
  });
}

class AdaptedQuestionLoaderService {
  // Define available datasets with proper paths and metadata
  static const List<QuestionDataset> _availableDatasets = [
    QuestionDataset(
      name: 'General Knowledge',
      path: 'assets/data/questions/questions.json',
      description: 'Mixed categories including science, history, movies, geography, and music',
      categories: ['science', 'history', 'movies', 'geography', 'music'],
    ),
    QuestionDataset(
      name: 'Science & Technology',
      path: 'assets/data/questions/science_questions.json',
      description: 'Questions focused on science, technology, and innovation',
      categories: ['science', 'technology', 'physics', 'chemistry', 'biology'],
    ),
    QuestionDataset(
      name: 'History & Culture',
      path: 'assets/data/questions/history_questions.json',
      description: 'Historical events, cultural knowledge, and world civilizations',
      categories: ['history', 'culture', 'ancient', 'modern', 'world_wars'],
    ),
    QuestionDataset(
      name: 'Entertainment',
      path: 'assets/data/questions/entertainment_questions.json',
      description: 'Movies, music, celebrities, and popular culture',
      categories: ['movies', 'music', 'celebrities', 'tv_shows', 'games'],
    ),
    QuestionDataset(
      name: 'Sports & Recreation',
      path: 'assets/data/questions/sports_questions.json',
      description: 'Sports, games, fitness, and recreational activities',
      categories: ['sports', 'olympics', 'football', 'basketball', 'fitness'],
    ),
    QuestionDataset(
      name: 'Geography & Travel',
      path: 'assets/data/questions/geography_questions.json',
      description: 'World geography, countries, capitals, and travel knowledge',
      categories: ['geography', 'countries', 'capitals', 'travel', 'landmarks'],
    ),
    QuestionDataset(
      name: 'Literature & Arts',
      path: 'assets/data/questions/literature_questions.json',
      description: 'Books, authors, poetry, visual arts, and creative works',
      categories: ['literature', 'books', 'poetry', 'art', 'authors'],
    ),
    QuestionDataset(
      name: 'Mathematics',
      path: 'assets/data/questions/math_questions.json',
      description: 'Mathematical concepts, problems, and applications',
      categories: ['math', 'algebra', 'geometry', 'statistics', 'calculus'],
    ),
    QuestionDataset(
      name: 'Bonus Questions',
      path: 'assets/data/questions/bonus_questions.json',
      description: 'Special bonus questions for solo and multiplayer games',
      categories: ['bonus', 'special', 'challenge', 'multiplayer', 'rewards'],
    ),
    QuestionDataset(
      name: 'Kids Questions',
      path: 'assets/data/questions/kids_questions.json',
      description: 'Age-appropriate questions for children, teens, and young adults',
      categories: ['kids', 'teens', 'young_adults', 'family', 'educational'],
    ),
    QuestionDataset(
      name: 'Media & Communication',
      path: 'assets/data/questions/media_questions.json',
      description: 'Questions about media, journalism, communication, and digital platforms',
      categories: ['media', 'journalism', 'communication', 'digital', 'broadcasting'],
    ),
    QuestionDataset(
      name: 'Social Studies',
      path: 'assets/data/questions/social_questions.json',
      description: 'Social sciences, sociology, psychology, and human behavior',
      categories: ['social', 'sociology', 'psychology', 'anthropology', 'politics'],
    ),
    QuestionDataset(
      name: 'Music & Audio',
      path: 'assets/data/questions/music_questions.json',
      description: 'Music theory, artists, instruments, genres, and audio production',
      categories: ['music', 'instruments', 'genres', 'artists', 'audio', 'production'],
    ),
    QuestionDataset(
      name: 'Technology & Computing',
      path: 'assets/data/questions/tech_questions.json',
      description: 'Programming, software, hardware, AI, and modern technology',
      categories: ['technology', 'programming', 'software', 'hardware', 'ai', 'computing'],
    ),
    QuestionDataset(
      name: 'World Affairs',
      path: 'assets/data/questions/world_questions.json',
      description: 'Current events, international relations, and global knowledge',
      categories: ['world', 'international', 'current_events', 'global', 'politics', 'economics'],
    ),
  ];

  // Class-based datasets for educational content
  static const List<QuestionDataset> _classDatasets = [
    QuestionDataset(
      name: 'Class 6',
      path: 'assets/data/questions/class6_questions.json',
      description: 'Grade 6 curriculum questions',
      categories: ['science', 'math', 'social_studies', 'english'],
    ),
    QuestionDataset(
      name: 'Class 7',
      path: 'assets/data/questions/class7_questions.json',
      description: 'Grade 7 curriculum questions',
      categories: ['science', 'math', 'social_studies', 'english'],
    ),
    QuestionDataset(
      name: 'Class 8',
      path: 'assets/data/questions/class8_questions.json',
      description: 'Grade 8 curriculum questions',
      categories: ['science', 'math', 'social_studies', 'english'],
    ),
    QuestionDataset(
      name: 'Class 9',
      path: 'assets/data/questions/class9_questions.json',
      description: 'Grade 9 curriculum questions',
      categories: ['science', 'math', 'social_studies', 'english'],
    ),
    QuestionDataset(
      name: 'Class 10',
      path: 'assets/data/questions/class10_questions.json',
      description: 'Grade 10 curriculum questions',
      categories: ['science', 'math', 'social_studies', 'english'],
    ),
  ];

  // Cache management
  final Map<String, List<QuestionModel>> _cachedDatasets = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(hours: 1);

  /// Get all available datasets (both standard and class-based)
  List<QuestionDataset> get availableDatasets => [..._availableDatasets, ..._classDatasets];

  /// Get only standard subject datasets
  List<QuestionDataset> get standardDatasets => _availableDatasets;

  /// Get only class-based datasets
  List<QuestionDataset> get classDatasets => _classDatasets;

  /// Load questions from a specific dataset by name
  Future<List<QuestionModel>> loadDataset(String datasetName) async {
    // Check cache validity first
    if (_cachedDatasets.containsKey(datasetName) && _isCacheValid(datasetName)) {
      return _cachedDatasets[datasetName]!;
    }

    // Find the dataset configuration
    final dataset = availableDatasets.firstWhere(
          (ds) => ds.name == datasetName,
      orElse: () => _availableDatasets.first, // Fallback to general knowledge
    );

    try {
      final String jsonString = await rootBundle.loadString(dataset.path);
      final List<dynamic> jsonList = json.decode(jsonString);

      final questions = jsonList
          .map((json) => _parseQuestionFromMixedFormat(json, datasetName))
          .where((question) => question.options.isNotEmpty)
          .toList();

      // Cache the loaded questions
      _cachedDatasets[datasetName] = questions;
      _cacheTimestamps[datasetName] = DateTime.now();

      return questions;
    } catch (e) {
      // If specific dataset fails and it's not the fallback, try general knowledge
      if (datasetName != 'General Knowledge') {
        debugPrint('Warning: Failed to load $datasetName, falling back to General Knowledge');
        return await loadDataset('General Knowledge');
      }
      throw Exception('Failed to load questions from $datasetName: $e');
    }
  }

  /// Load all questions from all available datasets
  Future<List<QuestionModel>> loadAllQuestions() async {
    final allQuestions = <QuestionModel>[];

    for (final dataset in availableDatasets) {
      try {
        final questions = await loadDataset(dataset.name);
        allQuestions.addAll(questions);
      } catch (e) {
        debugPrint('Warning: Failed to load ${dataset.name}: $e');
        // Continue loading other datasets
      }
    }

    return allQuestions;
  }

  /// Load questions from multiple specific datasets
  Future<List<QuestionModel>> loadQuestionsFromDatasets(List<String> datasetNames) async {
    final allQuestions = <QuestionModel>[];

    for (final datasetName in datasetNames) {
      try {
        final questions = await loadDataset(datasetName);
        allQuestions.addAll(questions);
      } catch (e) {
        debugPrint('Warning: Failed to load $datasetName: $e');
      }
    }

    return allQuestions;
  }

  /// Get questions by category across all datasets
  Future<List<QuestionModel>> getQuestionsByCategory(String category) async {
    final allQuestions = await loadAllQuestions();
    return allQuestions
        .where((q) => q.category.toLowerCase() == category.toLowerCase())
        .toList();
  }

  /// Get questions by category from specific dataset
  Future<List<QuestionModel>> getQuestionsByCategoryFromDataset(
      String category,
      String datasetName,
      ) async {
    final questions = await loadDataset(datasetName);
    return questions
        .where((q) => q.category.toLowerCase() == category.toLowerCase())
        .toList();
  }

  /// Get questions by difficulty level
  Future<List<QuestionModel>> getQuestionsByDifficulty(
      dynamic difficulty, {
        String? datasetName,
        List<String>? fromDatasets,
      }) async {
    List<QuestionModel> questions;

    if (fromDatasets != null && fromDatasets.isNotEmpty) {
      questions = await loadQuestionsFromDatasets(fromDatasets);
    } else if (datasetName != null) {
      questions = await loadDataset(datasetName);
    } else {
      questions = await loadAllQuestions();
    }

    if (difficulty is String) {
      final difficultyInt = _stringToIntDifficulty(difficulty);
      return questions.where((q) => q.difficulty == difficultyInt).toList();
    } else if (difficulty is int) {
      return questions.where((q) => q.difficulty == difficulty).toList();
    }

    return questions;
  }

  /// Get quiz questions specifically designed for a class/grade level
  Future<List<QuestionModel>> getQuizByClass(int classNumber, {int questionCount = 10}) async {
    final className = 'Class $classNumber';

    try {
      // Try to load from specific class dataset first
      final classQuestions = await loadDataset(className);
      if (classQuestions.isNotEmpty) {
        classQuestions.shuffle();
        return classQuestions.take(questionCount).toList();
      }
    } catch (e) {
      debugPrint('Class dataset not available, generating from general content');
    }

    // Fallback: Generate appropriate questions based on class level
    List<String> categories;
    List<int> difficulties;

    switch (classNumber) {
      case 6:
        categories = ['science', 'history', 'geography', 'math'];
        difficulties = [1]; // Easy only
        break;
      case 7:
        categories = ['science', 'history', 'geography', 'math', 'literature'];
        difficulties = [1, 2]; // Easy to medium
        break;
      case 8:
        categories = ['science', 'history', 'geography', 'technology', 'math'];
        difficulties = [2]; // Medium
        break;
      case 9:
        categories = ['science', 'history', 'geography', 'technology', 'literature'];
        difficulties = [2, 3]; // Medium to hard
        break;
      case 10:
        categories = ['science', 'history', 'geography', 'technology', 'literature', 'math'];
        difficulties = [2, 3]; // Medium to hard
        break;
      default:
        categories = ['science', 'history', 'geography'];
        difficulties = [1, 2, 3]; // All difficulties
    }

    return getMixedQuiz(
      questionCount: questionCount,
      categories: categories,
      difficulties: difficulties,
      balanceDifficulties: true,
    );
  }

  /// Get daily quiz with rotating categories and content
  Future<List<QuestionModel>> getDailyQuiz({int questionCount = 5}) async {
    final today = DateTime.now();
    final dayOfYear = today.difference(DateTime(today.year, 1, 1)).inDays;

    // Rotate categories based on day of year
    final availableCategories = await getAvailableCategories();
    if (availableCategories.isEmpty) {
      // Fallback to any available questions
      final allQuestions = await loadAllQuestions();
      allQuestions.shuffle();
      return allQuestions.take(questionCount).toList();
    }

    final categoryIndex = dayOfYear % availableCategories.length;
    final selectedCategory = availableCategories[categoryIndex];

    final categoryQuestions = await getQuestionsByCategory(selectedCategory);
    categoryQuestions.shuffle();
    return categoryQuestions.take(questionCount).toList();
  }

  /// Enhanced mixed quiz with comprehensive filtering options including audio
  Future<List<QuestionModel>> getMixedQuiz({
    int questionCount = 10,
    List<String>? categories,
    List<dynamic>? difficulties,
    List<String>? types,
    List<String>? tags,
    List<String>? datasets,
    bool includeImages = true,
    bool includeVideos = true,
    bool includeAudio = true,
    bool balanceDifficulties = false,
  }) async {
    List<QuestionModel> allQuestions;

    // Load from specific datasets or all datasets
    if (datasets != null && datasets.isNotEmpty) {
      allQuestions = await loadQuestionsFromDatasets(datasets);
    } else {
      allQuestions = await loadAllQuestions();
    }

    var filteredQuestions = allQuestions;

    // Apply category filter
    if (categories != null && categories.isNotEmpty) {
      filteredQuestions = filteredQuestions
          .where((q) => categories.any((cat) =>
      q.category.toLowerCase() == cat.toLowerCase()))
          .toList();
    }

    // Apply difficulty filter
    if (difficulties != null && difficulties.isNotEmpty) {
      filteredQuestions = filteredQuestions.where((q) {
        return difficulties.any((diff) {
          if (diff is String) {
            return q.difficulty == _stringToIntDifficulty(diff);
          } else if (diff is int) {
            return q.difficulty == diff;
          }
          return false;
        });
      }).toList();
    }

    // Apply type filter
    if (types != null && types.isNotEmpty) {
      filteredQuestions = filteredQuestions
          .where((q) => types.any((type) =>
      q.type.toLowerCase() == type.toLowerCase()))
          .toList();
    }

    // Apply tags filter
    if (tags != null && tags.isNotEmpty) {
      filteredQuestions = filteredQuestions.where((q) =>
      q.tags?.any((tag) => tags.contains(tag.toLowerCase())) == true
      ).toList();
    }

    // Apply media filters
    if (!includeImages) {
      filteredQuestions = filteredQuestions
          .where((q) => q.imageUrl?.isEmpty != false)
          .toList();
    }

    if (!includeVideos) {
      filteredQuestions = filteredQuestions
          .where((q) => q.videoUrl?.isEmpty != false)
          .toList();
    }

    if (!includeAudio) {
      filteredQuestions = filteredQuestions
          .where((q) => q.audioUrl?.isEmpty != false)
          .toList();
    }

    // Balance difficulties if requested and we have enough questions
    if (balanceDifficulties && filteredQuestions.length >= questionCount) {
      return _getBalancedQuestions(filteredQuestions, questionCount);
    }

    // Regular random selection
    filteredQuestions.shuffle();
    return filteredQuestions.take(questionCount).toList();
  }

  /// Get available categories across all or specific datasets
  Future<List<String>> getAvailableCategories({
    String? datasetName,
    List<String>? fromDatasets,
  }) async {
    List<QuestionModel> questions;

    if (fromDatasets != null && fromDatasets.isNotEmpty) {
      questions = await loadQuestionsFromDatasets(fromDatasets);
    } else if (datasetName != null) {
      questions = await loadDataset(datasetName);
    } else {
      questions = await loadAllQuestions();
    }

    final categories = questions.map((q) => q.category).toSet().toList();
    categories.sort();
    return categories;
  }

  /// Get available difficulties with both string and int representations
  Future<Map<String, List<dynamic>>> getAvailableDifficulties({
    String? datasetName,
    List<String>? fromDatasets,
  }) async {
    List<QuestionModel> questions;

    if (fromDatasets != null && fromDatasets.isNotEmpty) {
      questions = await loadQuestionsFromDatasets(fromDatasets);
    } else if (datasetName != null) {
      questions = await loadDataset(datasetName);
    } else {
      questions = await loadAllQuestions();
    }

    final difficultyInts = questions.map((q) => q.difficulty).toSet().toList();
    difficultyInts.sort();

    final difficultyStrings = difficultyInts.map((d) {
      switch (d) {
        case 1:
          return 'easy';
        case 2:
          return 'medium';
        case 3:
          return 'hard';
        default:
          return 'easy';
      }
    }).toList();

    return {
      'integers': difficultyInts,
      'strings': difficultyStrings,
    };
  }

  /// Get available question types
  Future<List<String>> getAvailableTypes({
    String? datasetName,
    List<String>? fromDatasets,
  }) async {
    List<QuestionModel> questions;

    if (fromDatasets != null && fromDatasets.isNotEmpty) {
      questions = await loadQuestionsFromDatasets(fromDatasets);
    } else if (datasetName != null) {
      questions = await loadDataset(datasetName);
    } else {
      questions = await loadAllQuestions();
    }

    final types = questions.map((q) => q.type).toSet().toList();
    types.sort();
    return types;
  }

  /// Get available tags
  Future<List<String>> getAvailableTags({
    String? datasetName,
    List<String>? fromDatasets,
  }) async {
    List<QuestionModel> questions;

    if (fromDatasets != null && fromDatasets.isNotEmpty) {
      questions = await loadQuestionsFromDatasets(fromDatasets);
    } else if (datasetName != null) {
      questions = await loadDataset(datasetName);
    } else {
      questions = await loadAllQuestions();
    }

    final allTags = <String>{};
    for (final question in questions) {
      if (question.tags != null) {
        allTags.addAll(question.tags!);
      }
    }

    final tagsList = allTags.toList();
    tagsList.sort();
    return tagsList;
  }

  /// Get statistics for a specific dataset
  Future<Map<String, dynamic>> getDatasetStats(String datasetName) async {
    final questions = await loadDataset(datasetName);

    final Map<String, int> categoryCount = {};
    final Map<int, int> difficultyCount = {};
    final Map<String, int> typeCount = {};
    final Map<String, int> mediaCount = {};
    int imageCount = 0;
    int videoCount = 0;
    int audioCount = 0;
    int powerUpCount = 0;

    for (final question in questions) {
      categoryCount[question.category] = (categoryCount[question.category] ?? 0) + 1;
      difficultyCount[question.difficulty] = (difficultyCount[question.difficulty] ?? 0) + 1;
      typeCount[question.type] = (typeCount[question.type] ?? 0) + 1;

      // Count media types
      mediaCount[question.mediaType] = (mediaCount[question.mediaType] ?? 0) + 1;

      if (question.imageUrl?.isNotEmpty == true) imageCount++;
      if (question.videoUrl?.isNotEmpty == true) videoCount++;
      if (question.audioUrl?.isNotEmpty == true) audioCount++;
      if (question.powerUpHint?.isNotEmpty == true) powerUpCount++;
    }

    return {
      'datasetName': datasetName,
      'totalQuestions': questions.length,
      'categoryCounts': categoryCount,
      'difficultyCounts': difficultyCount,
      'typeCounts': typeCount,
      'mediaCounts': mediaCount,
      'imageQuestions': imageCount,
      'videoQuestions': videoCount,
      'audioQuestions': audioCount,
      'powerUpQuestions': powerUpCount,
      'multimediaQuestions': questions.where((q) => q.isMultimedia).length,
    };
  }

  /// Get comprehensive statistics across all datasets
  Future<Map<String, dynamic>> getAllDatasetStats() async {
    final allStats = <String, dynamic>{};
    int totalQuestions = 0;
    final Map<String, int> allCategoryCount = {};
    final Map<int, int> allDifficultyCount = {};

    for (final dataset in availableDatasets) {
      try {
        final stats = await getDatasetStats(dataset.name);
        allStats[dataset.name] = stats;
        totalQuestions += stats['totalQuestions'] as int;

        // Aggregate category counts
        final categoryCount = stats['categoryCounts'] as Map<String, int>;
        for (final entry in categoryCount.entries) {
          allCategoryCount[entry.key] = (allCategoryCount[entry.key] ?? 0) + entry.value;
        }

        // Aggregate difficulty counts
        final difficultyCount = stats['difficultyCounts'] as Map<int, int>;
        for (final entry in difficultyCount.entries) {
          allDifficultyCount[entry.key] = (allDifficultyCount[entry.key] ?? 0) + entry.value;
        }
      } catch (e) {
        allStats[dataset.name] = {'error': e.toString()};
      }
    }

    allStats['summary'] = {
      'totalQuestions': totalQuestions,
      'totalDatasets': availableDatasets.length,
      'categoryCounts': allCategoryCount,
      'difficultyCounts': allDifficultyCount,
    };

    return allStats;
  }

  /// Get quiz recommendations based on user preferences and performance
  Future<List<QuestionModel>> getRecommendedQuiz({
    required String userLevel,
    required List<String> preferredCategories,
    int questionCount = 10,
    List<String>? fromDatasets,
    Map<String, double>? categoryPerformance,
  }) async {
    List<QuestionModel> sourceQuestions;

    if (fromDatasets != null && fromDatasets.isNotEmpty) {
      sourceQuestions = await loadQuestionsFromDatasets(fromDatasets);
    } else {
      sourceQuestions = await loadAllQuestions();
    }

    // Determine difficulty distribution based on user level
    List<int> targetDifficulties;
    switch (userLevel.toLowerCase()) {
      case 'beginner':
        targetDifficulties = [1, 1, 1, 2]; // 75% easy, 25% medium
        break;
      case 'intermediate':
        targetDifficulties = [1, 2, 2, 3]; // 25% easy, 50% medium, 25% hard
        break;
      case 'advanced':
        targetDifficulties = [2, 3, 3, 3]; // 25% medium, 75% hard
        break;
      default:
        targetDifficulties = [1, 2, 3]; // Balanced mix
    }

    final recommendedQuestions = <QuestionModel>[];

    // Prioritize categories based on performance (weaker areas for improvement)
    List<String> orderedCategories = List.from(preferredCategories);
    if (categoryPerformance != null) {
      orderedCategories.sort((a, b) {
        final aPerf = categoryPerformance[a] ?? 0.5;
        final bPerf = categoryPerformance[b] ?? 0.5;
        return aPerf.compareTo(bPerf); // Lower performance first
      });
    }

    // Get questions for each category and difficulty
    for (final category in orderedCategories) {
      final categoryQuestions = sourceQuestions
          .where((q) => q.category.toLowerCase() == category.toLowerCase())
          .toList();

      if (categoryQuestions.isNotEmpty) {
        for (final difficulty in targetDifficulties) {
          final difficultyQuestions = categoryQuestions
              .where((q) => q.difficulty == difficulty)
              .toList();

          if (difficultyQuestions.isNotEmpty) {
            difficultyQuestions.shuffle();
            recommendedQuestions.add(difficultyQuestions.first);

            if (recommendedQuestions.length >= questionCount) break;
          }
        }

        if (recommendedQuestions.length >= questionCount) break;
      }
    }

    // Fill remaining slots if needed
    if (recommendedQuestions.length < questionCount) {
      final remainingQuestions = sourceQuestions
          .where((q) => !recommendedQuestions.contains(q))
          .toList();
      remainingQuestions.shuffle();

      final needed = questionCount - recommendedQuestions.length;
      recommendedQuestions.addAll(remainingQuestions.take(needed));
    }

    // Final shuffle
    recommendedQuestions.shuffle();
    return recommendedQuestions.take(questionCount).toList();
  }

  /// Parse question from mixed JSON format and add source tracking
  QuestionModel _parseQuestionFromMixedFormat(Map<String, dynamic> json, String sourceDataset) {
    List<Map<String, dynamic>> answers = [];
    String correctAnswer = '';

    if (json.containsKey('answers')) {
      final answersList = json['answers'] as List;
      answers = answersList.map((a) => {
        'text': a['text'].toString(),
        'isCorrect': a['isCorrect'] == "True" || a['isCorrect'] == true,
      }).toList();
      correctAnswer = answers.firstWhere((a) => a['isCorrect'] == true)['text'];
    } else if (json.containsKey('correct_answer') && json.containsKey('incorrect_answers')) {
      correctAnswer = json['correct_answer'];
      final incorrectAnswers = List<String>.from(json['incorrect_answers']);

      answers = [
        {'text': correctAnswer, 'isCorrect': true},
        ...incorrectAnswers.map((text) => {'text': text, 'isCorrect': false}),
      ];
      answers.shuffle();
    } else if (json.containsKey('correctAnswer')) {
      correctAnswer = json['correctAnswer'];
      answers = [{'text': correctAnswer, 'isCorrect': true}];
    }

    final difficulty = json['difficulty'] != null
        ? _parseDifficulty(json['difficulty'])
        : 1;

    final normalizedJson = {
      'id': json['id'] ?? '${sourceDataset}_${DateTime.now().millisecondsSinceEpoch}',
      'category': json['category'] ?? json['category_id'] ?? _inferCategoryFromDataset(sourceDataset),
      'question': json['question'] ?? '',
      'answers': answers,
      'correctAnswer': correctAnswer,
      'type': json['type'] ?? 'multiple_choice',
      'difficulty': difficulty,
      'imageUrl': json['imageUrl'],
      'videoUrl': json['videoUrl'],
      'audioUrl': json['audioUrl'],
      'audioTranscript': json['audioTranscript'],
      'audioDuration': json['audioDuration'],
      'powerUpHint': json['powerUpHint'],
      'powerUpType': json['powerUpType'],
      'showHint': json['showHint'] ?? false,
      'reducedOptions': json['reducedOptions'],
      'multiplier': json['multiplier'],
      'isBoostedTime': json['isBoostedTime'] ?? false,
      'isShielded': json['isShielded'] ?? false,
      'tags': json['tags'],
      'sourceDataset': sourceDataset, // Track source for analytics
    };

    return QuestionModel.fromJson(normalizedJson);
  }

  /// Helper methods
  int _parseDifficulty(dynamic difficulty) {
    if (difficulty is String) {
      return _stringToIntDifficulty(difficulty);
    } else if (difficulty is int) {
      return difficulty;
    }
    return 1;
  }

  int _stringToIntDifficulty(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return 1;
      case 'medium':
        return 2;
      case 'hard':
        return 3;
      default:
        return 1;
    }
  }

  String _inferCategoryFromDataset(String datasetName) {
    if (datasetName.contains('Science')) return 'science';
    if (datasetName.contains('History')) return 'history';
    if (datasetName.contains('Entertainment')) return 'entertainment';
    if (datasetName.contains('Sports')) return 'sports';
    if (datasetName.contains('Geography')) return 'geography';
    if (datasetName.contains('Literature')) return 'literature';
    if (datasetName.contains('Math')) return 'math';
    if (datasetName.contains('Class')) return 'education';
    return 'general';
  }

  bool _isCacheValid(String datasetName) {
    final timestamp = _cacheTimestamps[datasetName];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheExpiry;
  }

  List<QuestionModel> _getBalancedQuestions(List<QuestionModel> questions, int count) {
    final easyQuestions = questions.where((q) => q.difficulty == 1).toList();
    final mediumQuestions = questions.where((q) => q.difficulty == 2).toList();
    final hardQuestions = questions.where((q) => q.difficulty == 3).toList();

    final balanced = <QuestionModel>[];
    final targetEach = count ~/ 3;
    final remainder = count % 3;

    // Shuffle each difficulty group
    easyQuestions.shuffle();
    mediumQuestions.shuffle();
    hardQuestions.shuffle();

    // Add questions from each difficulty level
    balanced.addAll(easyQuestions.take(targetEach + (remainder > 0 ? 1 : 0)));
    balanced.addAll(mediumQuestions.take(targetEach + (remainder > 1 ? 1 : 0)));
    balanced.addAll(hardQuestions.take(targetEach));

    // Fill any remaining slots with random questions
    final remaining = count - balanced.length;
    if (remaining > 0) {
      final allRemaining = [...easyQuestions, ...mediumQuestions, ...hardQuestions]
          .where((q) => !balanced.contains(q))
          .toList();
      allRemaining.shuffle();
      balanced.addAll(allRemaining.take(remaining));
    }

    balanced.shuffle();
    return balanced.take(count).toList();
  }

  /// Clear cache for specific dataset or all datasets
  void clearCache([String? datasetName]) {
    if (datasetName != null) {
      _cachedDatasets.remove(datasetName);
      _cacheTimestamps.remove(datasetName);
    } else {
      _cachedDatasets.clear();
      _cacheTimestamps.clear();
    }
  }

  /// Get dataset information for UI purposes
  Map<String, dynamic> getDatasetInfo() {
    return {
      'standardDatasets': _availableDatasets.map((ds) => {
        'name': ds.name,
        'description': ds.description,
        'categories': ds.categories,
      }).toList(),
      'classDatasets': _classDatasets.map((ds) => {
        'name': ds.name,
        'description': ds.description,
        'categories': ds.categories,
      }).toList(),
      'totalDatasets': availableDatasets.length,
    };
  }
}
