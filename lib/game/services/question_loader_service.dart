import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/question_paths.dart';
import 'quiz_category.dart';
import '../models/question_model.dart';

class QuestionDataset {
  final String name;
  final String path;
  final String? description;
  final List<QuizCategory> categories; // Changed to use QuizCategory enum
  final Map<String, dynamic>? metadata;
  final bool isActive;
  final QuizCategory? primaryCategory; // Add primary category for better mapping

  const QuestionDataset({
    required this.name,
    required this.path,
    this.description,
    this.categories = const [],
    this.metadata,
    this.isActive = true,
    this.primaryCategory,
  });
}

class AdaptedQuestionLoaderService {
  // Enhanced datasets using QuizCategory enum
  static const List<QuestionDataset> _coreDatasets = [
    QuestionDataset(
      name: 'Arts',
      path: Arts.ARTS_QUESTION,
      description: 'Visual arts, music, theater, and creative expressions',
      categories: [QuizCategory.arts],
      primaryCategory: QuizCategory.arts,
    ),
    QuestionDataset(
      name: 'General Knowledge',
      path: General.GENERAL_QUESTIONS,
      description: 'Mixed categories including science, history, movies, geography, and music',
      categories: [QuizCategory.general, QuizCategory.science, QuizCategory.history, QuizCategory.geography, QuizCategory.entertainment],
      primaryCategory: QuizCategory.general,
    ),
    QuestionDataset(
      name: 'Science',
      path: Science.SCIENCE_QUESTION,
      description: 'Questions focused on science, technology, and innovation',
      categories: [QuizCategory.science, QuizCategory.technology],
      primaryCategory: QuizCategory.science,
    ),
    QuestionDataset(
      name: 'History',
      path: History.HISTORY_QUESTION,
      description: 'Historical events, cultural knowledge, and world civilizations',
      categories: [QuizCategory.history, QuizCategory.globalCultures],
      primaryCategory: QuizCategory.history,
    ),
    QuestionDataset(
      name: 'Entertainment',
      path: Entertainment.ENTERTAINMENT_QUESTION,
      description: 'Movies, music, celebrities, and popular culture',
      categories: [QuizCategory.entertainment],
      primaryCategory: QuizCategory.entertainment,
    ),
    QuestionDataset(
      name: 'Sports',
      path: Sports.SPORTS_QUESTION,
      description: 'Sports, games, fitness, and recreational activities',
      categories: [QuizCategory.sports],
      primaryCategory: QuizCategory.sports,
    ),
    QuestionDataset(
      name: 'Geography',
      path: Geography.GEOGRAPHY_QUESTION,
      description: 'World geography, countries, capitals, and travel knowledge',
      categories: [QuizCategory.geography],
      primaryCategory: QuizCategory.geography,
    ),
    QuestionDataset(
      name: 'Literature',
      path: Literature.LITERATURE_QUESTION,
      description: 'Books, authors, poetry, visual arts, and creative works',
      categories: [QuizCategory.literature, QuizCategory.arts],
      primaryCategory: QuizCategory.literature,
    ),
    QuestionDataset(
      name: 'Mathematics',
      path: Math.MATH_QUESTION,
      description: 'Mathematical concepts, problems, and applications',
      categories: [QuizCategory.mathematics],
      primaryCategory: QuizCategory.mathematics,
    ),
    QuestionDataset(
      name: 'Kids Questions',
      path: Kids.KIDS_QUESTIONS,
      description: 'Age-appropriate questions for children, teens, and young adults',
      categories: [QuizCategory.kids],
      primaryCategory: QuizCategory.kids,
    ),
  ];

  // Extended subject datasets
  static const List<QuestionDataset> _extendedDatasets = [
    QuestionDataset(
      name: 'Extended Questions',
      path: Bonus.EXTENDED_QUESTIONS,
      description: 'Special bonus questions for solo and multiplayer games',
      categories: [QuizCategory.general],
      primaryCategory: QuizCategory.general,
    ),
    QuestionDataset(
      name: 'Media',
      path: Media.MEDIA_QUESTION,
      description: 'Questions about media, journalism, communication, and digital platforms',
      categories: [QuizCategory.media],
      primaryCategory: QuizCategory.media,
    ),
    QuestionDataset(
      name: 'Social Studies',
      path: Social.SOCIAL_QUESTION,
      description: 'Social sciences, sociology, psychology, and human behavior',
      categories: [QuizCategory.socialStudies, QuizCategory.psychology],
      primaryCategory: QuizCategory.socialStudies,
    ),
    QuestionDataset(
      name: 'Technology',
      path: Tech.TECH_QUESTION,
      description: 'Programming, software, hardware, AI, and modern technology',
      categories: [QuizCategory.technology, QuizCategory.computerScience],
      primaryCategory: QuizCategory.technology,
    ),
    QuestionDataset(
      name: 'World Affairs',
      path: World.WORLD_QUESTION,
      description: 'Current events, international relations, and global knowledge',
      categories: [QuizCategory.currentEvents, QuizCategory.politics, QuizCategory.globalCultures],
      primaryCategory: QuizCategory.currentEvents,
    ),
    QuestionDataset(
      name: 'Current Events',
      path: CurrentEvents.CURRENT_EVENTS_QUESTION,
      description: 'Recent news, current affairs, and contemporary issues',
      categories: [QuizCategory.currentEvents],
      primaryCategory: QuizCategory.currentEvents,
    ),
    QuestionDataset(
      name: 'Economics',
      path: Economics.ECONOMICS_QUESTION,
      description: 'Economic principles, markets, and financial concepts',
      categories: [QuizCategory.economics],
      primaryCategory: QuizCategory.economics,
    ),
    QuestionDataset(
      name: 'Environment',
      path: Environment.ENVIRONMENT_QUESTION,
      description: 'Environmental science, climate, and sustainability',
      categories: [QuizCategory.environment],
      primaryCategory: QuizCategory.environment,
    ),
    QuestionDataset(
      name: 'Health',
      path: Health.HEALTH_QUESTION,
      description: 'Health, medicine, nutrition, and wellness',
      categories: [QuizCategory.health],
      primaryCategory: QuizCategory.health,
    ),
    QuestionDataset(
      name: 'Law',
      path: Law.LAW_QUESTION,
      description: 'Legal concepts, rights, and judicial systems',
      categories: [QuizCategory.law],
      primaryCategory: QuizCategory.law,
    ),
    QuestionDataset(
      name: 'Philosophy',
      path: Philosophy.PHILOSOPHY_QUESTION,
      description: 'Philosophical concepts, ethics, and critical thinking',
      categories: [QuizCategory.philosophy],
      primaryCategory: QuizCategory.philosophy,
    ),
    QuestionDataset(
      name: 'Politics',
      path: Politics.POLITICS_QUESTION,
      description: 'Political systems, governance, and civic knowledge',
      categories: [QuizCategory.politics],
      primaryCategory: QuizCategory.politics,
    ),
    QuestionDataset(
      name: 'Psychology',
      path: Psychology.PSYCHOLOGY_QUESTION,
      description: 'Psychological concepts, behavior, and mental processes',
      categories: [QuizCategory.psychology],
      primaryCategory: QuizCategory.psychology,
    ),

    // NEW EXPANDED DATASETS
    QuestionDataset(
      name: 'Architecture',
      path: Architecture.ARCHITECTURE_QUESTION,
      description: 'Architecture, building design, and structural concepts',
      categories: [QuizCategory.architecture],
      primaryCategory: QuizCategory.architecture,
    ),
    QuestionDataset(
      name: 'Art History',
      path: ArtHistory.ART_HISTORY_QUESTION,
      description: 'History of art, artistic movements, and famous artworks',
      categories: [QuizCategory.artHistory, QuizCategory.arts],
      primaryCategory: QuizCategory.artHistory,
    ),
    QuestionDataset(
      name: 'Astronomy',
      path: Astronomy.ASTRONOMY_QUESTION,
      description: 'Space, stars, planets, and astronomical phenomena',
      categories: [QuizCategory.astronomy, QuizCategory.science],
      primaryCategory: QuizCategory.astronomy,
    ),
    QuestionDataset(
      name: 'Business',
      path: Business.BUSINESS_QUESTION,
      description: 'Business concepts, entrepreneurship, and management',
      categories: [QuizCategory.business],
      primaryCategory: QuizCategory.business,
    ),
    QuestionDataset(
      name: 'Civics & Law',
      path: CivicsLaw.CIVICS_LAW_QUESTION,
      description: 'Civic duties, government, and basic legal concepts',
      categories: [QuizCategory.civicsLaw, QuizCategory.politics, QuizCategory.law],
      primaryCategory: QuizCategory.civicsLaw,
    ),
    QuestionDataset(
      name: 'Comparative Religions',
      path: ComparativeReligions.COMPARATIVE_RELIGIONS_QUESTION,
      description: 'World religions, beliefs, and spiritual practices',
      categories: [QuizCategory.comparativeReligions, QuizCategory.globalCultures],
      primaryCategory: QuizCategory.comparativeReligions,
    ),
    QuestionDataset(
      name: 'Computer Science',
      path: ComputerScience.COMPUTER_SCIENCE_QUESTION,
      description: 'Programming, algorithms, and computer science concepts',
      categories: [QuizCategory.computerScience, QuizCategory.technology],
      primaryCategory: QuizCategory.computerScience,
    ),
    QuestionDataset(
      name: 'Global Cultures',
      path: Cultures.GLOBAL_CULTURES_QUESTION,
      description: 'World cultures, traditions, and cultural studies',
      categories: [QuizCategory.globalCultures],
      primaryCategory: QuizCategory.globalCultures,
    ),
    QuestionDataset(
      name: 'Economics & Finance',
      path: EconomicsFinance.ECONOMICS_FINANCE_QUESTION,
      description: 'Advanced economics and financial concepts',
      categories: [QuizCategory.economicsFinance, QuizCategory.economics, QuizCategory.business],
      primaryCategory: QuizCategory.economicsFinance,
    ),
    QuestionDataset(
      name: 'Engineering & Technology',
      path: EngineeringTechnology.ENGINEERING_TECHNOLOGY_QUESTION,
      description: 'Engineering principles and technological applications',
      categories: [QuizCategory.engineeringTechnology, QuizCategory.technology],
      primaryCategory: QuizCategory.engineeringTechnology,
    ),
    QuestionDataset(
      name: 'Environmental Science',
      path: EnvironmentalScience.ENVIRONMENTAL_SCIENCE_ADVANCED_QUESTION,
      description: 'Advanced environmental science and ecological studies',
      categories: [QuizCategory.environmentalScience, QuizCategory.environment, QuizCategory.science],
      primaryCategory: QuizCategory.environmentalScience,
    ),
    QuestionDataset(
      name: 'Health & Medicine',
      path: HealthMedicine.HEALTH_MEDICINE_QUESTION,
      description: 'Medical science, healthcare, and advanced health topics',
      categories: [QuizCategory.healthMedicine, QuizCategory.health],
      primaryCategory: QuizCategory.healthMedicine,
    ),
    QuestionDataset(
      name: 'Statistics & Data',
      path: StatisticsData.STATISTICS_DATA_LITERACY_QUESTION,
      description: 'Statistics, data analysis, and data literacy',
      categories: [QuizCategory.statisticsData, QuizCategory.mathematics],
      primaryCategory: QuizCategory.statisticsData,
    ),
    QuestionDataset(
      name: 'World Literature',
      path: WorldLiterature.WORLD_LITERATURE_QUESTION,
      description: 'International literature and global literary works',
      categories: [QuizCategory.worldLiterature, QuizCategory.literature],
      primaryCategory: QuizCategory.worldLiterature,
    ),
    QuestionDataset(
      name: 'Kids Grade 2',
      path: Kids.KIDS_GRADE2_QUESTIONS,
      description: 'Specific questions designed for grade 2 students',
      categories: [QuizCategory.kidsGrade2, QuizCategory.kids],
      primaryCategory: QuizCategory.kidsGrade2,
    ),
  ];

  // Specialized mode datasets
  static const List<QuestionDataset> _modeDatasets = [
    QuestionDataset(
      name: 'Media Challenge',
      path: Modes.MEDIA_CHALLENGE_QUESTION,
      description: 'Media-focused challenge questions',
      categories: [QuizCategory.media],
      primaryCategory: QuizCategory.media,
    ),
    QuestionDataset(
      name: 'Multimedia',
      path: Modes.MULTIMEDIA_QUESTION,
      description: 'Questions with multimedia content',
      categories: [QuizCategory.general],
      primaryCategory: QuizCategory.general,
    ),
    QuestionDataset(
      name: 'Multiplayer',
      path: Modes.MULTIPLAYER_QUESTION,
      description: 'Questions designed for multiplayer games',
      categories: [QuizCategory.general],
      primaryCategory: QuizCategory.general,
    ),
    QuestionDataset(
      name: 'Speed Round',
      path: Modes.SPEED_ROUND_QUESTION,
      description: 'Fast-paced quiz questions for speed rounds',
      categories: [QuizCategory.general],
      primaryCategory: QuizCategory.general,
    ),
    QuestionDataset(
      name: 'Speed Ultra',
      path: Modes.SPEED_ULTRA_QUESTION,
      description: 'Ultra-fast lightning round questions',
      categories: [QuizCategory.general],
      primaryCategory: QuizCategory.general,
    ),
  ];

  // Alternative file datasets
  static const List<QuestionDataset> _alternativeDatasets = [
    QuestionDataset(
      name: 'Media Questions Alt',
      path: Media.MEDIA_QUESTIONS,
      description: 'Alternative media questions dataset',
      categories: [QuizCategory.media],
      primaryCategory: QuizCategory.media,
    ),
    QuestionDataset(
      name: 'Science Questions Alt',
      path: Science.SCIENCE_QUESTIONS,
      description: 'Alternative science questions dataset',
      categories: [QuizCategory.science],
      primaryCategory: QuizCategory.science,
    ),
    QuestionDataset(
      name: 'World Extended',
      path: World.WORLD_EXT_QUESTION,
      description: 'Extended world affairs and international topics',
      categories: [QuizCategory.currentEvents, QuizCategory.globalCultures],
      primaryCategory: QuizCategory.currentEvents,
    ),
    QuestionDataset(
      name: 'Misc Questions',
      path: Misc.QUESTIONS,
      description: 'Miscellaneous and mixed topic questions',
      categories: [QuizCategory.general],
      primaryCategory: QuizCategory.general,
    ),
    QuestionDataset(
      name: 'Offline Pack',
      path: Misc.QUESTIONS_OFFLINE_PACK,
      description: 'Offline question pack for standalone use',
      categories: [QuizCategory.general],
      primaryCategory: QuizCategory.general,
    ),
  ];

  // Class-based datasets for educational content
  static const List<QuestionDataset> _classDatasets = [
    QuestionDataset(
      name: 'Class K',
      path: Classes.CLASS_K_QUESTIONS,
      description: 'Kindergarten curriculum questions',
      categories: [QuizCategory.kids],
      primaryCategory: QuizCategory.kids,
    ),
    QuestionDataset(
      name: 'Class 1',
      path: Classes.CLASS_1_QUESTIONS,
      description: 'Grade 1 curriculum questions',
      categories: [QuizCategory.kids],
      primaryCategory: QuizCategory.kids,
    ),
    QuestionDataset(
      name: 'Class 2',
      path: Classes.CLASS_2_QUESTIONS,
      description: 'Grade 2 curriculum questions',
      categories: [QuizCategory.kidsGrade2, QuizCategory.kids],
      primaryCategory: QuizCategory.kidsGrade2,
    ),
    QuestionDataset(
      name: 'Class 3',
      path: Classes.CLASS_3_QUESTIONS,
      description: 'Grade 3 curriculum questions',
      categories: [QuizCategory.kids],
      primaryCategory: QuizCategory.kids,
    ),
    QuestionDataset(
      name: 'Class 4',
      path: Classes.CLASS_4_QUESTIONS,
      description: 'Grade 4 curriculum questions',
      categories: [QuizCategory.kids],
      primaryCategory: QuizCategory.kids,
    ),
    QuestionDataset(
      name: 'Class 5',
      path: Classes.CLASS_5_QUESTIONS,
      description: 'Grade 5 curriculum questions',
      categories: [QuizCategory.kids],
      primaryCategory: QuizCategory.kids,
    ),
    QuestionDataset(
      name: 'Class 6',
      path: Classes.CLASS_6_QUESTIONS,
      description: 'Grade 6 curriculum questions',
      categories: [QuizCategory.general],
      primaryCategory: QuizCategory.general,
    ),
    QuestionDataset(
      name: 'Class 7',
      path: Classes.CLASS_7_QUESTIONS,
      description: 'Grade 7 curriculum questions',
      categories: [QuizCategory.general],
      primaryCategory: QuizCategory.general,
    ),
    QuestionDataset(
      name: 'Class 8',
      path: Classes.CLASS_8_QUESTIONS,
      description: 'Grade 8 curriculum questions',
      categories: [QuizCategory.general],
      primaryCategory: QuizCategory.general,
    ),
    QuestionDataset(
      name: 'Class 9',
      path: Classes.CLASS_9_QUESTIONS,
      description: 'Grade 9 curriculum questions',
      categories: [QuizCategory.general],
      primaryCategory: QuizCategory.general,
    ),
    QuestionDataset(
      name: 'Class 10',
      path: Classes.CLASS_10_QUESTIONS,
      description: 'Grade 10 curriculum questions',
      categories: [QuizCategory.general],
      primaryCategory: QuizCategory.general,
    ),
    QuestionDataset(
      name: 'Class 11',
      path: Classes.CLASS_11_QUESTIONS,
      description: 'Grade 11 curriculum questions',
      categories: [QuizCategory.general],
      primaryCategory: QuizCategory.general,
    ),
    QuestionDataset(
      name: 'Class 12',
      path: Classes.CLASS_12_QUESTIONS,
      description: 'Grade 12 curriculum questions',
      categories: [QuizCategory.general],
      primaryCategory: QuizCategory.general,
    ),
  ];

  // Cache management with improved expiry
  final Map<String, List<QuestionModel>> _cachedDatasets = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Map<String, bool> _datasetAvailability = {};
  static const Duration _cacheExpiry = Duration(hours: 2);

  /// Get all available datasets (core + extended + class-based)
  List<QuestionDataset> get availableDatasets => [
    ..._coreDatasets.where((ds) => ds.isActive),
    ..._extendedDatasets.where((ds) => ds.isActive),
    ..._modeDatasets.where((ds) => ds.isActive),
    ..._alternativeDatasets.where((ds) => ds.isActive),
    ..._classDatasets.where((ds) => ds.isActive)
  ];

  /// Get only core subject datasets
  List<QuestionDataset> get coreDatasets => _coreDatasets.where((ds) => ds.isActive).toList();

  /// Get only extended subject datasets
  List<QuestionDataset> get extendedDatasets => _extendedDatasets.where((ds) => ds.isActive).toList();

  /// Get only specialized mode datasets
  List<QuestionDataset> get modeDatasets => _modeDatasets.where((ds) => ds.isActive).toList();

  /// Get only alternative datasets
  List<QuestionDataset> get alternativeDatasets => _alternativeDatasets.where((ds) => ds.isActive).toList();

  /// Get only class-based datasets
  List<QuestionDataset> get classDatasets => _classDatasets.where((ds) => ds.isActive).toList();

  /// Load questions from a specific QuizCategory
  Future<List<QuestionModel>> loadQuestionsByCategory(QuizCategory category) async {
    final datasetName = category.datasetName;
    return loadDataset(datasetName);
  }

  /// Get questions by QuizCategory enum
  Future<List<QuestionModel>> getQuestionsByQuizCategory(QuizCategory category) async {
    // First try to find a dedicated dataset for this category
    final dedicatedDataset = _findDatasetForQuizCategory(category);
    if (dedicatedDataset != null) {
      try {
        final questions = await loadDataset(dedicatedDataset.name);
        return questions.where((q) =>
        q.category.toLowerCase() == category.datasetName.toLowerCase()
        ).toList();
      } catch (e) {
        debugPrint('Failed to load dedicated dataset for ${category.displayName}: $e');
      }
    }

    // Fallback to searching across all datasets
    final allQuestions = await loadAllQuestions();
    return allQuestions
        .where((q) => _matchesCategory(q, category))
        .toList();
  }

  /// Get datasets that contain questions for a specific QuizCategory
  List<QuestionDataset> getDatasetsForCategory(QuizCategory category) {
    return availableDatasets
        .where((dataset) => dataset.categories.contains(category) || dataset.primaryCategory == category)
        .toList();
  }

  /// Get available QuizCategories from loaded datasets
  Future<List<QuizCategory>> getAvailableQuizCategories() async {
    final availableCategories = <QuizCategory>{};

    for (final dataset in availableDatasets) {
      availableCategories.addAll(dataset.categories);
      if (dataset.primaryCategory != null) {
        availableCategories.add(dataset.primaryCategory!);
      }
    }

    return availableCategories.toList();
  }

  /// Start category quiz (compatibility method)
  Future<List<QuestionModel>> startCategoryQuiz({
    required QuizCategory category,
    int questionCount = 10,
    List<int>? difficulties,
    bool includeImages = true,
    bool includeVideos = true,
    bool includeAudio = true,
  }) async {
    return getMixedQuizByCategories(
      questionCount: questionCount,
      categories: [category],
      difficulties: difficulties,
      includeImages: includeImages,
      includeVideos: includeVideos,
      includeAudio: includeAudio,
    );
  }

  /// Enhanced mixed quiz with QuizCategory support
  Future<List<QuestionModel>> getMixedQuizByCategories({
    int questionCount = 10,
    List<QuizCategory>? categories,
    List<dynamic>? difficulties,
    List<String>? types,
    List<String>? tags,
    List<String>? datasets,
    bool includeImages = true,
    bool includeVideos = true,
    bool includeAudio = true,
    bool balanceDifficulties = false,
    bool balanceCategories = false,
  }) async {
    List<QuestionModel> allQuestions;

    // Load from specific datasets or all datasets
    if (datasets != null && datasets.isNotEmpty) {
      allQuestions = await loadQuestionsFromDatasets(datasets);
    } else {
      allQuestions = await loadAllQuestions();
    }

    var filteredQuestions = allQuestions;

    // Apply QuizCategory filter
    if (categories != null && categories.isNotEmpty) {
      filteredQuestions = filteredQuestions
          .where((q) => categories.any((cat) => _matchesCategory(q, cat)))
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

    // Balance difficulties and/or categories if requested
    if (balanceDifficulties && balanceCategories && filteredQuestions.length >= questionCount) {
      return _getBalancedQuestionsAdvancedByCategories(filteredQuestions, questionCount, categories);
    } else if (balanceDifficulties && filteredQuestions.length >= questionCount) {
      return _getBalancedQuestions(filteredQuestions, questionCount);
    } else if (balanceCategories && categories != null && filteredQuestions.length >= questionCount) {
      return _getBalancedByQuizCategories(filteredQuestions, questionCount, categories);
    }

    // Regular random selection
    filteredQuestions.shuffle();
    return filteredQuestions.take(questionCount).toList();
  }

  /// Get question count for a QuizCategory
  Future<int> getQuizCategoryQuestionCount(QuizCategory category) async {
    try {
      final questions = await getQuestionsByQuizCategory(category);
      return questions.length;
    } catch (e) {
      debugPrint('Error getting question count for ${category.displayName}: $e');
      return 0;
    }
  }

  /// Get category difficulty for a QuizCategory
  Future<String> getQuizCategoryDifficulty(QuizCategory category) async {
    try {
      final questions = await getQuestionsByQuizCategory(category);

      if (questions.isEmpty) return 'mixed';

      // Calculate difficulty distribution
      final difficultyCount = <int, int>{};
      for (final question in questions) {
        difficultyCount[question.difficulty] = (difficultyCount[question.difficulty] ?? 0) + 1;
      }

      // If only one difficulty level, return it
      if (difficultyCount.length == 1) {
        return _intToStringDifficulty(difficultyCount.keys.first);
      }

      // Calculate percentages
      final total = questions.length;
      final percentages = difficultyCount.map((key, value) =>
          MapEntry(key, value / total));

      // If one difficulty dominates (>70%), return it
      for (final entry in percentages.entries) {
        if (entry.value > 0.7) {
          return _intToStringDifficulty(entry.key);
        }
      }

      return 'mixed';
    } catch (e) {
      debugPrint('Error getting difficulty for ${category.displayName}: $e');
      return 'mixed';
    }
  }

  /// Get questions appropriate for a specific class level using QuizCategory
  Future<List<QuestionModel>> getQuizByClassLevel(String classLevel, {int questionCount = 10}) async {
    final categories = QuizCategoryManager.getCategoriesForClass(classLevel);

    return getMixedQuizByCategories(
      questionCount: questionCount,
      categories: categories,
      balanceCategories: true,
    );
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
    final categories = QuizCategoryManager.getCategoriesForClass(classNumber.toString());

    List<int> difficulties;
    if (classNumber <= 3) {
      difficulties = [1]; // Easy only for younger students
    } else if (classNumber <= 6) {
      difficulties = [1, 2]; // Easy to medium
    } else if (classNumber <= 9) {
      difficulties = [2]; // Medium
    } else {
      difficulties = [2, 3]; // Medium to hard for high school
    }

    return getMixedQuizByCategories(
      questionCount: questionCount,
      categories: categories,
      difficulties: difficulties,
      balanceDifficulties: true,
      balanceCategories: true,
    );
  }

  // Private helper methods

  /// Find the most appropriate dataset for a QuizCategory
  QuestionDataset? _findDatasetForQuizCategory(QuizCategory category) {
    // Check for datasets with this as primary category first
    for (final dataset in availableDatasets) {
      if (dataset.primaryCategory == category) {
        return dataset;
      }
    }

    // Check for datasets that include this category
    for (final dataset in availableDatasets) {
      if (dataset.categories.contains(category)) {
        return dataset;
      }
    }

    // Check by name matching
    for (final dataset in availableDatasets) {
      if (dataset.name.toLowerCase().contains(category.displayName.toLowerCase())) {
        return dataset;
      }
    }

    return null;
  }

  /// Check if a question matches a QuizCategory
  bool _matchesCategory(QuestionModel question, QuizCategory category) {
    final questionCategory = question.category.toLowerCase();
    final categoryName = category.displayName.toLowerCase();
    final datasetName = category.datasetName.toLowerCase();

    return questionCategory == categoryName ||
        questionCategory == datasetName ||
        questionCategory.contains(categoryName) ||
        categoryName.contains(questionCategory);
  }

  /// Get balanced questions by QuizCategories
  List<QuestionModel> _getBalancedByQuizCategories(List<QuestionModel> questions, int count, List<QuizCategory> categories) {
    final balanced = <QuestionModel>[];
    final questionsPerCategory = count ~/ categories.length;
    final remainder = count % categories.length;

    for (int i = 0; i < categories.length; i++) {
      final category = categories[i];
      final categoryQuestions = questions
          .where((q) => _matchesCategory(q, category))
          .toList();

      categoryQuestions.shuffle();
      final targetCount = questionsPerCategory + (i < remainder ? 1 : 0);
      balanced.addAll(categoryQuestions.take(targetCount));
    }

    // Fill remaining slots if needed
    final remaining = count - balanced.length;
    if (remaining > 0) {
      final unusedQuestions = questions.where((q) => !balanced.contains(q)).toList();
      unusedQuestions.shuffle();
      balanced.addAll(unusedQuestions.take(remaining));
    }

    balanced.shuffle();
    return balanced.take(count).toList();
  }

  /// Advanced balanced selection for both difficulty and QuizCategories
  List<QuestionModel> _getBalancedQuestionsAdvancedByCategories(List<QuestionModel> questions, int count, List<QuizCategory>? categories) {
    if (categories == null || categories.isEmpty) {
      return _getBalancedQuestions(questions, count);
    }

    final balanced = <QuestionModel>[];
    final questionsPerCategory = count ~/ categories.length;

    for (final category in categories) {
      final categoryQuestions = questions
          .where((q) => _matchesCategory(q, category))
          .toList();

      if (categoryQuestions.isNotEmpty) {
        final balancedForCategory = _getBalancedQuestions(categoryQuestions, questionsPerCategory);
        balanced.addAll(balancedForCategory);
      }
    }

    // Fill remaining slots
    final remaining = count - balanced.length;
    if (remaining > 0) {
      final unusedQuestions = questions.where((q) => !balanced.contains(q)).toList();
      final additionalQuestions = _getBalancedQuestions(unusedQuestions, remaining);
      balanced.addAll(additionalQuestions);
    }

    balanced.shuffle();
    return balanced.take(count).toList();
  }

  /// Load questions from a specific dataset by name with enhanced error handling
  Future<List<QuestionModel>> loadDataset(String datasetName) async {
    // Check cache validity first
    if (_cachedDatasets.containsKey(datasetName) && _isCacheValid(datasetName)) {
      return _cachedDatasets[datasetName]!;
    }

    // Check if dataset is known to be unavailable
    if (_datasetAvailability[datasetName] == false) {
      return _handleUnavailableDataset(datasetName);
    }

    // Find the dataset configuration
    final dataset = availableDatasets.firstWhere(
          (ds) => ds.name == datasetName,
      orElse: () => _coreDatasets.first, // Fallback to first core dataset
    );

    try {
      // Try direct path loading first
      final questions = await _loadFromPath(dataset.path, datasetName);

      // Cache the loaded questions
      _cachedDatasets[datasetName] = questions;
      _cacheTimestamps[datasetName] = DateTime.now();
      _datasetAvailability[datasetName] = true;

      return questions;
    } catch (e) {
      debugPrint('Failed to load dataset $datasetName from path ${dataset.path}: $e');
      _datasetAvailability[datasetName] = false;

      // Try fallback loading using the data service
      return _handleDatasetFallback(datasetName, dataset);
    }
  }

  /// Load questions directly from a path with validation
  Future<List<QuestionModel>> _loadFromPath(String path, String datasetName) async {
    final String jsonString = await rootBundle.loadString(path);
    final List<dynamic> jsonList = json.decode(jsonString);

    final questions = jsonList
        .map((json) => _parseQuestionFromMixedFormat(json, datasetName))
        .where((question) => question.options.isNotEmpty && question.question.isNotEmpty)
        .toList();

    if (questions.isEmpty) {
      throw Exception('No valid questions found in dataset $datasetName');
    }

    debugPrint('Successfully loaded ${questions.length} questions from $datasetName');
    return questions;
  }

  /// Handle unavailable dataset by trying alternatives
  Future<List<QuestionModel>> _handleUnavailableDataset(String datasetName) async {
    debugPrint('Dataset $datasetName is marked as unavailable, trying alternatives');

    // Try to find similar datasets based on categories
    final targetDataset = availableDatasets.firstWhere(
          (ds) => ds.name == datasetName,
      orElse: () => _coreDatasets.first,
    );

    // Find alternative datasets with overlapping categories
    final alternatives = availableDatasets.where((ds) =>
    ds.name != datasetName &&
        ds.categories.any((cat) => targetDataset.categories.contains(cat))
    ).toList();

    if (alternatives.isNotEmpty) {
      final alternative = alternatives.first;
      debugPrint('Using alternative dataset: ${alternative.name}');
      return loadDataset(alternative.name);
    }

    // Final fallback to General Knowledge
    if (datasetName != 'General Knowledge') {
      return loadDataset('General Knowledge');
    }

    throw Exception('No alternatives available for dataset $datasetName');
  }

  /// Handle dataset fallback using the data service
  Future<List<QuestionModel>> _handleDatasetFallback(String datasetName, QuestionDataset dataset) async {
    debugPrint('Attempting fallback loading for $datasetName using data service');

    // Try loading using category-based approach
    for (final category in dataset.categories) {
      try {
        final questions = await getQuestionsByQuizCategory(category);
        if (questions.isNotEmpty) {
          debugPrint('Fallback successful: loaded ${questions.length} questions for category ${category.displayName}');

          // Cache the successful result
          _cachedDatasets[datasetName] = questions;
          _cacheTimestamps[datasetName] = DateTime.now();
          _datasetAvailability[datasetName] = true;

          return questions;
        }
      } catch (e) {
        debugPrint('Fallback failed for category ${category.displayName}: $e');
      }
    }

    // If specific dataset fails and it's not the fallback, try general knowledge
    if (datasetName != 'General Knowledge') {
      debugPrint('All fallbacks failed, using General Knowledge');
      return loadDataset('General Knowledge');
    }

    throw Exception('Complete failure to load dataset $datasetName');
  }

  /// Load all questions from all available datasets with error resilience
  Future<List<QuestionModel>> loadAllQuestions() async {
    final allQuestions = <QuestionModel>[];
    final failedDatasets = <String>[];

    for (final dataset in availableDatasets) {
      try {
        final questions = await loadDataset(dataset.name);
        allQuestions.addAll(questions);
      } catch (e) {
        failedDatasets.add(dataset.name);
        debugPrint('Warning: Failed to load ${dataset.name}: $e');
      }
    }

    if (allQuestions.isEmpty) {
      throw Exception('Failed to load any questions. Failed datasets: $failedDatasets');
    }

    debugPrint('Loaded ${allQuestions.length} total questions from ${availableDatasets.length - failedDatasets.length} datasets');
    return allQuestions;
  }

  /// Load questions from multiple specific datasets
  Future<List<QuestionModel>> loadQuestionsFromDatasets(List<String> datasetNames) async {
    final allQuestions = <QuestionModel>[];
    final failedDatasets = <String>[];

    for (final datasetName in datasetNames) {
      try {
        final questions = await loadDataset(datasetName);
        allQuestions.addAll(questions);
      } catch (e) {
        failedDatasets.add(datasetName);
        debugPrint('Warning: Failed to load $datasetName: $e');
      }
    }

    if (allQuestions.isEmpty && datasetNames.isNotEmpty) {
      // Try fallback to any available core dataset
      for (final coreDataset in _coreDatasets) {
        try {
          final questions = await loadDataset(coreDataset.name);
          allQuestions.addAll(questions);
          debugPrint('Fallback successful using ${coreDataset.name}');
          break;
        } catch (e) {
          continue;
        }
      }
    }

    return allQuestions;
  }

  /// Legacy support: Get questions by category string (maps to QuizCategory)
  Future<List<QuestionModel>> getQuestionsByCategory(String category) async {
    // Try to map string to QuizCategory
    final quizCategory = QuizCategoryManager.fromString(category);
    if (quizCategory != null) {
      return getQuestionsByQuizCategory(quizCategory);
    }

    // Fallback to original string-based search
    final allQuestions = await loadAllQuestions();
    return allQuestions
        .where((q) => q.category.toLowerCase() == category.toLowerCase())
        .toList();
  }

  /// Enhanced validation and parsing
  QuestionModel _parseQuestionFromMixedFormat(Map<String, dynamic> json, String sourceDataset) {
    try {
      List<Map<String, dynamic>> answers = [];
      String correctAnswer = '';

      if (json.containsKey('answers')) {
        final answersList = json['answers'] as List;
        answers = answersList.map((a) => {
          'text': a['text'].toString(),
          'isCorrect': a['isCorrect'] == "True" || a['isCorrect'] == true,
        }).toList();

        // Fixed type casting issue
        Map<String, dynamic>? correctAnswerEntry;
        try {
          correctAnswerEntry = answers.firstWhere(
                (a) => a['isCorrect'] == true,
          );
        } catch (e) {
          // If no correct answer found, use first one
          correctAnswerEntry = answers.isNotEmpty ? answers.first : null;
        }

        // Check if we found a correct answer, otherwise use the first one
        if (correctAnswerEntry != null) {
          correctAnswer = correctAnswerEntry['text'].toString();
        } else if (answers.isNotEmpty) {
          correctAnswer = answers.first['text'].toString();
        }
      } else if (json.containsKey('correct_answer') && json.containsKey('incorrect_answers')) {
        correctAnswer = json['correct_answer'];
        final incorrectAnswers = List<String>.from(json['incorrect_answers'] ?? []);

        answers = [
          {'text': correctAnswer, 'isCorrect': true},
          ...incorrectAnswers.map((text) => {'text': text, 'isCorrect': false}),
        ];
        answers.shuffle();
      } else if (json.containsKey('correctAnswer')) {
        correctAnswer = json['correctAnswer'];
        answers = [{'text': correctAnswer, 'isCorrect': true}];
      }

      // Validate we have at least one answer
      if (answers.isEmpty || correctAnswer.isEmpty) {
        throw Exception('No valid answers found');
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
        'sourceDataset': sourceDataset,
      };

      return QuestionModel.fromJson(normalizedJson);
    } catch (e) {
      debugPrint('Error parsing question from $sourceDataset: $e');
      debugPrint('Problematic JSON: $json');
      rethrow;
    }
  }

  /// Helper methods
  int _parseDifficulty(dynamic difficulty) {
    if (difficulty is String) {
      return _stringToIntDifficulty(difficulty);
    } else if (difficulty is int) {
      return difficulty.clamp(1, 3);
    }
    return 1;
  }

  int _stringToIntDifficulty(String difficulty) {
    switch (difficulty.toLowerCase().trim()) {
      case 'easy':
      case 'beginner':
      case 'simple':
        return 1;
      case 'medium':
      case 'intermediate':
      case 'moderate':
        return 2;
      case 'hard':
      case 'difficult':
      case 'advanced':
      case 'expert':
        return 3;
      default:
        return 1;
    }
  }

  String _intToStringDifficulty(int difficulty) {
    switch (difficulty) {
      case 1:
        return 'easy';
      case 2:
        return 'medium';
      case 3:
        return 'hard';
      default:
        return 'easy';
    }
  }

  String _inferCategoryFromDataset(String datasetName) {
    final name = datasetName.toLowerCase();
    if (name.contains('science')) return 'science';
    if (name.contains('history')) return 'history';
    if (name.contains('entertainment')) return 'entertainment';
    if (name.contains('sports')) return 'sports';
    if (name.contains('geography')) return 'geography';
    if (name.contains('literature')) return 'literature';
    if (name.contains('math')) return 'math';
    if (name.contains('class')) return 'education';
    if (name.contains('arts')) return 'arts';
    if (name.contains('technology')) return 'technology';
    if (name.contains('health')) return 'health';
    return 'general';
  }

  bool _isCacheValid(String datasetName) {
    final timestamp = _cacheTimestamps[datasetName];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheExpiry;
  }

  List<QuestionModel> _getBalancedQuestions(List<QuestionModel> questions, int count) {
    if (questions.length <= count) return questions;

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

  /// Legacy support methods with enhanced functionality

  /// Get category question count with QuizCategory integration
  Future<int> getCategoryQuestionCount(String categoryId) async {
    try {
      // First try to map to QuizCategory
      final quizCategory = QuizCategoryManager.fromString(categoryId);
      if (quizCategory != null) {
        return getQuizCategoryQuestionCount(quizCategory);
      }

      // Fallback to original string-based approach
      final allQuestions = await loadAllQuestions();
      return allQuestions
          .where((q) => q.category.toLowerCase() == categoryId.toLowerCase())
          .length;
    } catch (e) {
      debugPrint('Error getting category question count for $categoryId: $e');
      return 0;
    }
  }

  /// Get category difficulty with QuizCategory integration
  Future<String> getCategoryDifficulty(String categoryId) async {
    try {
      // First try to map to QuizCategory
      final quizCategory = QuizCategoryManager.fromString(categoryId);
      if (quizCategory != null) {
        return getQuizCategoryDifficulty(quizCategory);
      }

      // Fallback to original string-based approach
      final allQuestions = await loadAllQuestions();
      final categoryQuestions = allQuestions
          .where((q) => q.category.toLowerCase() == categoryId.toLowerCase())
          .toList();

      if (categoryQuestions.isEmpty) return 'mixed';

      // Calculate difficulty distribution
      final difficultyCount = <int, int>{};
      for (final question in categoryQuestions) {
        difficultyCount[question.difficulty] = (difficultyCount[question.difficulty] ?? 0) + 1;
      }

      // If only one difficulty level, return it
      if (difficultyCount.length == 1) {
        return _intToStringDifficulty(difficultyCount.keys.first);
      }

      // Calculate percentages
      final total = categoryQuestions.length;
      final percentages = difficultyCount.map((key, value) =>
          MapEntry(key, value / total));

      // If one difficulty dominates (>70%), return it
      for (final entry in percentages.entries) {
        if (entry.value > 0.7) {
          return _intToStringDifficulty(entry.key);
        }
      }

      return 'mixed';
    } catch (e) {
      debugPrint('Error getting category difficulty for $categoryId: $e');
      return 'mixed';
    }
  }

  /// Enhanced mixed quiz with backward compatibility
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
    bool balanceCategories = false,
  }) async {
    // Convert string categories to QuizCategories if possible
    List<QuizCategory>? quizCategories;
    if (categories != null) {
      quizCategories = categories
          .map((cat) => QuizCategoryManager.fromString(cat))
          .where((cat) => cat != null)
          .cast<QuizCategory>()
          .toList();
    }

    return getMixedQuizByCategories(
      questionCount: questionCount,
      categories: quizCategories,
      difficulties: difficulties,
      types: types,
      tags: tags,
      datasets: datasets,
      includeImages: includeImages,
      includeVideos: includeVideos,
      includeAudio: includeAudio,
      balanceDifficulties: balanceDifficulties,
      balanceCategories: balanceCategories,
    );
  }

  /// Get daily quiz with QuizCategory rotation
  Future<List<QuestionModel>> getDailyQuiz({int questionCount = 5}) async {
    final today = DateTime.now();
    final dayOfYear = today.difference(DateTime(today.year, 1, 1)).inDays;

    // Rotate categories based on day of year using QuizCategory
    final availableCategories = await getAvailableQuizCategories();
    if (availableCategories.isEmpty) {
      // Fallback to any available questions
      final allQuestions = await loadAllQuestions();
      allQuestions.shuffle();
      return allQuestions.take(questionCount).toList();
    }

    final categoryIndex = dayOfYear % availableCategories.length;
    final selectedCategory = availableCategories[categoryIndex];

    final categoryQuestions = await getQuestionsByQuizCategory(selectedCategory);
    categoryQuestions.shuffle();
    return categoryQuestions.take(questionCount).toList();
  }

  /// Get comprehensive service status with QuizCategory information
  Future<Map<String, dynamic>> getServiceStatus() async {
    final status = <String, dynamic>{
      'cacheSize': _cachedDatasets.length,
      'availableDatasets': <String, dynamic>{},
      'totalQuestionCount': 0,
      'availableQuizCategories': [],
      'lastUpdated': DateTime.now().toIso8601String(),
    };

    int totalQuestions = 0;

    for (final dataset in availableDatasets) {
      try {
        final questions = await loadDataset(dataset.name);
        status['availableDatasets'][dataset.name] = {
          'questionCount': questions.length,
          'status': 'available',
          'categories': dataset.categories.map((cat) => cat.displayName).toList(),
          'primaryCategory': dataset.primaryCategory?.displayName,
          'description': dataset.description,
        };
        totalQuestions += questions.length;
      } catch (e) {
        status['availableDatasets'][dataset.name] = {
          'questionCount': 0,
          'status': 'unavailable',
          'error': e.toString(),
        };
      }
    }

    // Add available QuizCategories
    final availableCategories = await getAvailableQuizCategories();
    status['availableQuizCategories'] = availableCategories
        .map((cat) => {
      'name': cat.displayName,
      'description': cat.description,
      'datasetName': cat.datasetName,
    }).toList();

    status['totalQuestionCount'] = totalQuestions;
    return status;
  }

  /// Clear cache for specific dataset or all datasets
  void clearCache([String? datasetName]) {
    if (datasetName != null) {
      _cachedDatasets.remove(datasetName);
      _cacheTimestamps.remove(datasetName);
      _datasetAvailability.remove(datasetName);
    } else {
      _cachedDatasets.clear();
      _cacheTimestamps.clear();
      _datasetAvailability.clear();
    }
  }

  /// Get question count for a specific class/grade level
  Future<int> getClassQuestionCount(String classId) async {
    try {
      // First try to get from specific class dataset
      final classDatasetName = _getClassDatasetName(classId);
      if (classDatasetName != null) {
        final classQuestions = await loadDataset(classDatasetName);
        return classQuestions.length;
      }

      // Fallback: count questions that would be appropriate for this class
      final allQuestions = await loadAllQuestions();
      final appropriateQuestions = _filterQuestionsForClass(allQuestions, classId);
      return appropriateQuestions.length;
    } catch (e) {
      debugPrint('Error getting class question count for $classId: $e');
      return 0;
    }
  }

  /// Get subject count for a specific class/grade level
  Future<int> getClassSubjectCount(String classId) async {
    try {
      // First try to get from specific class dataset
      final classDatasetName = _getClassDatasetName(classId);
      if (classDatasetName != null) {
        final classQuestions = await loadDataset(classDatasetName);
        final subjects = classQuestions.map((q) => q.category).toSet();
        return subjects.length;
      }

      // Fallback: return expected subject count based on class level
      return _getExpectedSubjectCount(classId);
    } catch (e) {
      debugPrint('Error getting class subject count for $classId: $e');
      return 4; // Default fallback
    }
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

  /// Helper method to convert class ID to dataset name
  String? _getClassDatasetName(String classId) {
    switch (classId.toLowerCase()) {
      case 'kindergarten':
        return 'Class K';
      case '1':
      case '2':
      case '3':
      case '4':
      case '5':
      case '6':
      case '7':
      case '8':
      case '9':
      case '10':
      case '11':
      case '12':
        return 'Class $classId';
      default:
        return null;
    }
  }

  /// Helper method to filter questions appropriate for a specific class
  List<QuestionModel> _filterQuestionsForClass(List<QuestionModel> questions, String classId) {
    final classConfig = _getClassConfiguration(classId);

    return questions.where((q) {
      final categoryMatch = classConfig['categories']?.contains(q.category.toLowerCase()) ?? false;
      final difficultyMatch = classConfig['difficulties']?.contains(q.difficulty) ?? true;
      return categoryMatch && difficultyMatch;
    }).toList();
  }

  /// Get class configuration for filtering
  Map<String, dynamic> _getClassConfiguration(String classId) {
    switch (classId.toLowerCase()) {
      case 'kindergarten':
        return {
          'categories': ['science', 'math', 'social_studies', 'english', 'arts'],
          'difficulties': [1],
        };
      case '1':
      case '2':
      case '3':
        return {
          'categories': ['science', 'math', 'social_studies', 'english', 'arts'],
          'difficulties': [1],
        };
      case '4':
      case '5':
        return {
          'categories': ['science', 'math', 'social_studies', 'english', 'arts', 'health'],
          'difficulties': [1, 2],
        };
      case '6':
      case '7':
      case '8':
        return {
          'categories': ['science', 'math', 'social_studies', 'english', 'history', 'geography', 'technology'],
          'difficulties': [1, 2, 3],
        };
      case '9':
      case '10':
      case '11':
      case '12':
        return {
          'categories': ['science', 'math', 'social_studies', 'english', 'history', 'geography', 'technology', 'literature', 'philosophy'],
          'difficulties': [2, 3],
        };
      default:
        return {
          'categories': ['science', 'math', 'social_studies', 'english'],
          'difficulties': [1, 2, 3],
        };
    }
  }

  /// Get expected number of subjects for a class level
  int _getExpectedSubjectCount(String classId) {
    switch (classId.toLowerCase()) {
      case 'kindergarten':
      case '1':
      case '2':
      case '3':
        return 4;
      case '4':
      case '5':
        return 5;
      case '6':
        return 6;
      case '7':
      case '8':
        return 7;
      case '9':
      case '10':
        return 8;
      case '11':
      case '12':
        return 9;
      default:
        return 4;
    }
  }

  /// Get dataset information for UI purposes with QuizCategory integration
  Map<String, dynamic> getDatasetInfo() {
    return {
      'coreDatasets': _coreDatasets.map((ds) => {
        'name': ds.name,
        'description': ds.description,
        'categories': ds.categories.map((cat) => cat.displayName).toList(),
        'primaryCategory': ds.primaryCategory?.displayName,
      }).toList(),
      'extendedDatasets': _extendedDatasets.map((ds) => {
        'name': ds.name,
        'description': ds.description,
        'categories': ds.categories.map((cat) => cat.displayName).toList(),
        'primaryCategory': ds.primaryCategory?.displayName,
      }).toList(),
      'classDatasets': _classDatasets.map((ds) => {
        'name': ds.name,
        'description': ds.description,
        'categories': ds.categories.map((cat) => cat.displayName).toList(),
        'primaryCategory': ds.primaryCategory?.displayName,
      }).toList(),
      'totalDatasets': availableDatasets.length,
      'availableQuizCategories': QuizCategory.values.map((cat) => {
        'name': cat.displayName,
        'description': cat.description,
        'datasetName': cat.datasetName,
      }).toList(),
    };
  }

  /// Comprehensive test with QuizCategory integration
  Future<void> runComprehensiveTest() async {
    debugPrint('=== Comprehensive Dataset Test with QuizCategory Integration ===');

    final testResults = <String, Map<String, dynamic>>{};
    int totalQuestions = 0;
    int successfulDatasets = 0;

    for (final dataset in availableDatasets) {
      debugPrint('Testing ${dataset.name}...');

      try {
        final startTime = DateTime.now();
        final questions = await loadDataset(dataset.name);
        final loadTime = DateTime.now().difference(startTime);

        testResults[dataset.name] = {
          'status': 'success',
          'questionCount': questions.length,
          'loadTimeMs': loadTime.inMilliseconds,
          'categories': questions.map((q) => q.category).toSet().toList(),
          'difficulties': questions.map((q) => q.difficulty).toSet().toList(),
          'hasMultimedia': questions.any((q) => q.isMultimedia),
          'quizCategories': dataset.categories.map((cat) => cat.displayName).toList(),
          'primaryCategory': dataset.primaryCategory?.displayName,
        };

        totalQuestions += questions.length;
        successfulDatasets++;

        debugPrint('✅ ${dataset.name}: ${questions.length} questions (${loadTime.inMilliseconds}ms)');
      } catch (e) {
        testResults[dataset.name] = {
          'status': 'failed',
          'error': e.toString(),
        };
        debugPrint('❌ ${dataset.name}: Failed - $e');
      }
    }

    debugPrint('=== Test Summary ===');
    debugPrint('Successful datasets: $successfulDatasets/${availableDatasets.length}');
    debugPrint('Total questions loaded: $totalQuestions');
    debugPrint('Cache entries: ${_cachedDatasets.length}');

    // Test QuizCategory functionality
    debugPrint('\n=== QuizCategory Integration Test ===');
    final testCategories = [
      QuizCategory.science,
      QuizCategory.mathematics,
      QuizCategory.arts,
      QuizCategory.history,
      QuizCategory.technology,
      QuizCategory.health,
    ];

    for (final category in testCategories) {
      try {
        final count = await getQuizCategoryQuestionCount(category);
        final difficulty = await getQuizCategoryDifficulty(category);
        debugPrint('✅ ${category.displayName}: $count questions, difficulty: $difficulty');
      } catch (e) {
        debugPrint('❌ ${category.displayName}: Failed - $e');
      }
    }

    debugPrint('=== End Comprehensive Test ===');
  }
}