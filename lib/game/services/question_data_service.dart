import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/question_paths.dart';
import '../models/question_model.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';

/// Enhanced question loading with fallback strategies and dynamic path discovery
Future<List<QuestionModel>> loadQuestionsFromAsset(
  String category, {
  String? categoryPath,
}) async {
  // First, try to use exact paths from constants if available
  final exactPath = _getExactPathFromConstants(category);
  if (exactPath != null) {
    try {
      final jsonStr = await rootBundle.loadString(exactPath);
      final List<dynamic> data = json.decode(jsonStr) as List<dynamic>;
      return data.map((e) => QuestionModel.fromJson(e)).toList();
    } catch (e) {
      LogManager.debug('Failed to load from exact path $exactPath: $e');
      // Fall through to dynamic path resolution
    }
  }

  // Fallback to dynamic path resolution
  return _loadWithDynamicPaths(category, categoryPath);
}

/// Load questions using exact paths from QuestionPaths constants
String? _getExactPathFromConstants(String category) {
  final categoryLower = category.toLowerCase().trim();

  // Core subject mappings
  switch (categoryLower) {
    // Basic subjects
    case 'arts':
    case 'art':
    case 'visual_arts':
    case 'creative_arts':
      return Arts.artsQuestion;

    case 'general':
    case 'general knowledge':
    case 'mixed':
      return General.generalQuestions;

    case 'science':
    case 'natural science':
    case 'physics':
    case 'chemistry':
    case 'biology':
      return Science.scienceQuestion;

    case 'history':
    case 'world history':
    case 'historical':
      return History.historyQuestion;

    case 'entertainment':
    case 'movies':
    case 'film':
    case 'music':
    case 'celebrities':
      return Entertainment.entertainmentQuestion;

    case 'sports':
    case 'athletics':
    case 'games':
    case 'fitness':
      return Sports.sportsQuestion;

    case 'geography':
    case 'world_geography':
    case 'countries':
    case 'capitals':
      return Geography.geographyQuestion;

    case 'literature':
    case 'books':
    case 'authors':
    case 'poetry':
    case 'writing':
      return Literature.literatureQuestion;

    case 'mathematics':
    case 'math':
    case 'maths':
    case 'algebra':
    case 'geometry':
      return Math.mathQuestion;

    case 'kids':
    case 'kids_questions':
    case 'children':
    case 'family':
      return Kids.kidsQuestions;

    case 'media':
    case 'journalism':
    case 'communication':
      return Media.mediaQuestion;

    case 'social':
    case 'social_studies':
    case 'sociology':
      return Social.socialQuestion;

    case 'technology':
    case 'tech':
    case 'computing':
    case 'programming':
    case 'it':
      return Tech.techQuestion;

    case 'world':
    case 'world_affairs':
    case 'international':
    case 'global':
      return World.worldQuestion;

    // Extended subjects
    case 'current_events':
    case 'news':
    case 'current_affairs':
      return CurrentEvents.currentEventsQuestion;

    case 'economics':
    case 'economy':
    case 'finance':
      return Economics.economicsQuestion;

    case 'environment':
    case 'environmental':
    case 'ecology':
    case 'climate':
      return Environment.environmentQuestion;

    case 'health':
    case 'medicine':
    case 'medical':
    case 'wellness':
    case 'nutrition':
      return Health.healthQuestion;

    case 'law':
    case 'legal':
    case 'justice':
    case 'rights':
      return Law.lawQuestion;

    case 'philosophy':
    case 'ethics':
    case 'logic':
    case 'critical thinking':
      return Philosophy.philosophyQuestion;

    case 'politics':
    case 'political':
    case 'government':
    case 'civic':
      return Politics.politicsQuestion;

    case 'psychology':
    case 'mental_health':
    case 'behavior':
    case 'cognition':
      return Psychology.psychologyQuestion;

    // NEW CATEGORIES FROM YOUR QUESTION_PATHS.DART
    case 'architecture':
    case 'architectural':
    case 'buildings':
    case 'design':
      return Architecture.architectureQuestion;

    case 'art_history':
    case 'art history':
    case 'artistic history':
    case 'fine arts history':
      return ArtHistory.artHistoryQuestion;

    case 'astronomy':
    case 'space':
    case 'stars':
    case 'planets':
    case 'cosmos':
      return Astronomy.astronomyQuestion;

    case 'entrepreneurship':
    case 'management':
    case 'commerce':
    case 'business':
      return Business.businessQuestion;

    case 'civics_law':
      return CivicsLaw.civicsLawQuestion;

    case 'comparative_religions':
    case 'comparative religions':
    case 'religions':
    case 'religious studies':
    case 'theology':
      return ComparativeReligions.comparativeReligionsQuestion;

    case 'computer_science':
    case 'computer science':
    case 'software engineering':
    case 'algorithms':
      return ComputerScience.computerScienceQuestion;

    case 'cultures':
    case 'global_cultures':
    case 'global cultures':
    case 'cultural studies':
    case 'anthropology':
      return Cultures.globalCulturesQuestion;

    case 'economics_finance':
    case 'economics finance':
    case 'financial economics':
    case 'finance economics':
      return EconomicsFinance.economicsFinanceQuestion;

    case 'engineering_technology':
    case 'engineering technology':
    case 'engineering':
    case 'mechanical engineering':
    case 'electrical engineering':
      return EngineeringTechnology.engineeringTechnologyQuestion;

    case 'environmental_science':
    case 'environmental science':
    case 'environmental studies':
    case 'ecology advanced':
      return EnvironmentalScience.environmentalScienceAdvancedQuestion;

    case 'health_medicine':
    case 'health medicine':
    case 'medical science':
    case 'healthcare':
      return HealthMedicine.healthMedicineQuestion;

    case 'kids_grade2':
    case 'kids grade2':
    case 'grade 2 kids':
    case 'second grade':
      return Kids.kidsGrade2Questions;

    case 'statistics_data':
    case 'statistics data':
    case 'data literacy':
    case 'statistics':
    case 'data science':
      return StatisticsData.statisticsDataLiteracyQuestion;

    case 'world_literature':
    case 'world literature':
    case 'international literature':
    case 'global literature':
      return WorldLiterature.worldLiteratureQuestion;

    // Alternative file paths for existing categories
    case 'media_questions':
    case 'media alternative':
      return Media.mediaQuestion;

    case 'science_questions':
    case 'science alternative':
      return Science.scienceQuestion;

    case 'world_ext':
    case 'world extended':
    case 'world extension':
      return World.worldExtQuestion;

    // Misc categories
    case 'misc':
    case 'miscellaneous':
    case 'mixed questions':
      return Misc.questions;

    case 'offline':
    case 'offline pack':
    case 'questions offline':
      return Misc.questionsOfflinePack;

    // Game mode categories
    case 'media_challenge':
    case 'media challenge':
    case 'challenge media':
      return Modes.mediaChallengeQuestion;

    case 'multimedia':
    case 'multi media':
    case 'mixed media':
      return Modes.multimediaQuestion;

    case 'multiplayer':
    case 'multi player':
    case 'team play':
      return Modes.multiplayerQuestion;

    case 'speed_round':
    case 'speed round':
    case 'speed quiz':
    case 'quick round':
      return Modes.speedRoundQuestion;

    case 'speed_ultra':
    case 'speed ultra':
    case 'ultra speed':
    case 'lightning round':
      return Modes.speedUltraQuestion;

    // Class-based categories with multiple variations
    case 'class k':
    case 'class_k':
    case 'kindergarten':
    case 'grade k':
    case 'k':
      return Classes.classKQuestions;

    case 'class 1':
    case 'class_1':
    case 'grade 1':
    case 'first grade':
    case '1':
      return Classes.class1Questions;

    case 'class 2':
    case 'class_2':
    case 'grade 2':
    case '2':
      return Classes.class2Questions;

    case 'class 3':
    case 'class_3':
    case 'grade 3':
    case 'third grade':
    case '3':
      return Classes.class3Questions;

    case 'class 4':
    case 'class_4':
    case 'grade 4':
    case 'fourth grade':
    case '4':
      return Classes.class4Questions;

    case 'class 5':
    case 'class_5':
    case 'grade 5':
    case 'fifth grade':
    case '5':
      return Classes.class5Questions;

    case 'class 6':
    case 'class_6':
    case 'grade 6':
    case 'sixth grade':
    case '6':
      return Classes.class6Questions;

    case 'class 7':
    case 'class_7':
    case 'grade 7':
    case 'seventh grade':
    case '7':
      return Classes.class7Questions;

    case 'class 8':
    case 'class_8':
    case 'grade 8':
    case 'eighth grade':
    case '8':
      return Classes.class8Questions;

    case 'class 9':
    case 'class_9':
    case 'grade 9':
    case 'ninth grade':
    case '9':
      return Classes.class9Questions;

    case 'class 10':
    case 'class_10':
    case 'grade 10':
    case 'tenth grade':
    case '10':
      return Classes.class10Questions;

    case 'class 11':
    case 'class_11':
    case 'grade 11':
    case 'eleventh grade':
    case '11':
      return Classes.class11Questions;

    case 'class 12':
    case 'class_12':
    case 'grade 12':
    case 'twelfth grade':
    case '12':
      return Classes.class12Questions;

    // Bonus/Extended content
    case 'bonus':
    case 'extended':
    case 'special':
    case 'challenge':
      return Bonus.extendedQuestions;

    default:
      return null; // No exact match found
  }
}

/// Fallback dynamic path resolution with enhanced path discovery
Future<List<QuestionModel>> _loadWithDynamicPaths(
  String category,
  String? categoryPath,
) async {
  const String base = 'assets/questions';

  // Normalize category name variants
  String raw = category.trim();
  final variants = <String>{
    raw,
    raw.toLowerCase(),
    raw.replaceAll(' ', '_'),
    raw.toLowerCase().replaceAll(' ', '_'),
    raw.replaceAll(' ', '-'),
    raw.toLowerCase().replaceAll(' ', '-'),
    raw.replaceAll('_', ' '),
    raw.replaceAll('-', ' '),
  }.toList();

  // Build candidate paths in priority order
  final List<String> candidates = [];
  final String dir = (categoryPath ?? '').trim();

  void addWithDir(String name) {
    if (dir.isNotEmpty) {
      // Try with custom directory
      candidates.addAll([
        '$base/$dir/${name}_questions.json',
        '$base/$dir/${name}_question.json',
        '$base/$dir/$name.json',
      ]);
    }

    // Try in common subject directories
    final commonDirs = [
      'general',
      'science',
      'math',
      'history',
      'arts',
      'technology',
      'classes'
    ];
    for (final commonDir in commonDirs) {
      candidates.addAll([
        '$base/$commonDir/${name}_questions.json',
        '$base/$commonDir/${name}_question.json',
        '$base/$commonDir/$name.json',
      ]);
    }

    // Try in root questions directory
    candidates.addAll([
      '$base/${name}_questions.json',
      '$base/${name}_question.json',
      '$base/$name.json',
    ]);
  }

  for (final v in variants) {
    addWithDir(v);
  }

  // Deduplicate while preserving order
  final tried = <String>{};
  final ordered = <String>[];
  for (final p in candidates) {
    if (tried.add(p)) ordered.add(p);
  }

  Object? lastErr;
  for (final path in ordered) {
    try {
      final jsonStr = await rootBundle.loadString(path);
      final List<dynamic> data = json.decode(jsonStr) as List<dynamic>;
      LogManager.debug('Successfully loaded questions from: $path');
      return data.map((e) => QuestionModel.fromJson(e)).toList();
    } catch (e) {
      lastErr = e;
      LogManager.debug('loadQuestionsFromAsset: miss on $path ($e)');
    }
  }

  throw FlutterError(
    'No matching asset for category="$category", categoryPath="$categoryPath". '
    'Tried paths: ${ordered.join(", ")}. Last error: $lastErr',
  );
}

/// Load questions from asset with full path (preferred method for constants)
Future<List<QuestionModel>> loadQuestionsFromAssetPath(String fullPath) async {
  try {
    final String jsonStr = await rootBundle.loadString(fullPath);
    final List<dynamic> data = json.decode(jsonStr);
    return data.map((e) => QuestionModel.fromJson(e)).toList();
  } catch (e) {
    throw FlutterError(
        'Failed to load questions from path: $fullPath. Error: $e');
  }
}

/// Helper method to load questions by category with automatic path resolution
Future<List<QuestionModel>> loadQuestionsByCategory(String category) async {
  return loadQuestionsFromAsset(category);
}

/// Load questions for a specific class level with enhanced mapping
Future<List<QuestionModel>> loadQuestionsForClass(dynamic classLevel) async {
  String category;

  if (classLevel == 0 || classLevel == 'k' || classLevel == 'K') {
    category = 'class k';
  } else if (classLevel is int) {
    category = 'class $classLevel';
  } else if (classLevel is String) {
    // Handle string inputs like "grade 5", "class_3", etc.
    final normalized = classLevel.toLowerCase().trim();
    if (normalized.contains('k') || normalized.contains('kindergarten')) {
      category = 'class k';
    } else {
      // Extract number from string
      final match = RegExp(r'\d+').firstMatch(normalized);
      if (match != null) {
        category = 'class ${match.group(0)}';
      } else {
        category = 'class 1'; // Default fallback
      }
    }
  } else {
    category = 'class 1'; // Default fallback
  }

  return loadQuestionsByCategory(category);
}

/// Load questions from multiple categories with error handling
Future<List<QuestionModel>> loadQuestionsFromMultipleCategories(
    List<String> categories) async {
  final List<QuestionModel> allQuestions = [];
  final List<String> failedCategories = [];

  for (final category in categories) {
    try {
      final questions = await loadQuestionsByCategory(category);
      allQuestions.addAll(questions);
      LogManager.debug(
          'Successfully loaded ${questions.length} questions from $category');
    } catch (e) {
      failedCategories.add(category);
      LogManager.debug(
          'Warning: Failed to load questions for category $category: $e');
    }
  }

  if (failedCategories.isNotEmpty && allQuestions.isEmpty) {
    // If all categories failed, try to load from general questions as fallback
    try {
      final generalQuestions = await loadQuestionsByCategory('general');
      allQuestions.addAll(generalQuestions);
      LogManager.debug(
          'Loaded ${generalQuestions.length} questions from general fallback');
    } catch (e) {
      throw FlutterError(
          'All categories failed to load: $failedCategories. General fallback also failed: $e');
    }
  }

  return allQuestions;
}

/// Discover available question files dynamically
Future<List<String>> discoverAvailableCategories() async {
  final List<String> availableCategories = [];

  // Test common category paths
  final testCategories = [
    'science',
    'math',
    'history',
    'geography',
    'arts',
    'literature',
    'technology',
    'sports',
    'entertainment',
    'health',
    'economics',
    'philosophy',
    'psychology',
    'politics',
    'law',
    'environment',
    'current_events',
    'world',
    'social',
    'media',
    'kids',
    'general'
  ];

  for (final category in testCategories) {
    try {
      await loadQuestionsByCategory(category);
      availableCategories.add(category);
    } catch (e) {
      // Category not available
    }
  }

  return availableCategories;
}

/// Get question count for a category without loading all questions
Future<int> getQuestionCount(String category) async {
  try {
    final questions = await loadQuestionsByCategory(category);
    return questions.length;
  } catch (e) {
    LogManager.debug('Error getting question count for $category: $e');
    return 0;
  }
}

/// Validate question data structure
bool validateQuestionData(Map<String, dynamic> questionJson) {
  final requiredFields = ['question', 'answers', 'correctAnswer'];

  for (final field in requiredFields) {
    if (!questionJson.containsKey(field) || questionJson[field] == null) {
      LogManager.debug('Missing required field: $field');
      return false;
    }
  }

  // Validate answers structure
  if (questionJson['answers'] is! List ||
      (questionJson['answers'] as List).isEmpty) {
    LogManager.debug('Invalid answers structure');
    return false;
  }

  return true;
}

/// Load questions with validation
Future<List<QuestionModel>> loadQuestionsWithValidation(String category) async {
  try {
    final questions = await loadQuestionsByCategory(category);

    // Filter out invalid questions
    final validQuestions = questions
        .where((q) =>
            q.question.isNotEmpty &&
            q.options.isNotEmpty &&
            q.correctAnswer.isNotEmpty)
        .toList();

    if (validQuestions.length != questions.length) {
      LogManager.debug(
          'Filtered out ${questions.length - validQuestions.length} invalid questions from $category');
    }

    return validQuestions;
  } catch (e) {
    LogManager.debug(
        'Error loading questions with validation for $category: $e');
    rethrow;
  }
}
