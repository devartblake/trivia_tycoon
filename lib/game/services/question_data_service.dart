import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/question_paths.dart';
import '../models/question_model.dart';

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
      debugPrint('Failed to load from exact path $exactPath: $e');
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
      return Arts.ARTS_QUESTION;

    case 'general':
    case 'general knowledge':
    case 'mixed':
      return General.GENERAL_QUESTIONS;

    case 'science':
    case 'natural science':
    case 'physics':
    case 'chemistry':
    case 'biology':
      return Science.SCIENCE_QUESTION;

    case 'history':
    case 'world history':
    case 'historical':
      return History.HISTORY_QUESTION;

    case 'entertainment':
    case 'movies':
    case 'film':
    case 'music':
    case 'celebrities':
      return Entertainment.ENTERTAINMENT_QUESTION;

    case 'sports':
    case 'athletics':
    case 'games':
    case 'fitness':
      return Sports.SPORTS_QUESTION;

    case 'geography':
    case 'world_geography':
    case 'countries':
    case 'capitals':
      return Geography.GEOGRAPHY_QUESTION;

    case 'literature':
    case 'books':
    case 'authors':
    case 'poetry':
    case 'writing':
      return Literature.LITERATURE_QUESTION;

    case 'mathematics':
    case 'math':
    case 'maths':
    case 'algebra':
    case 'geometry':
      return Math.MATH_QUESTION;

    case 'kids':
    case 'kids_questions':
    case 'children':
    case 'family':
      return Kids.KIDS_QUESTIONS;

    case 'media':
    case 'journalism':
    case 'communication':
      return Media.MEDIA_QUESTION;

    case 'social':
    case 'social_studies':
    case 'sociology':
      return Social.SOCIAL_QUESTION;

    case 'technology':
    case 'tech':
    case 'computing':
    case 'programming':
    case 'it':
      return Tech.TECH_QUESTION;

    case 'world':
    case 'world_affairs':
    case 'international':
    case 'global':
      return World.WORLD_QUESTION;

  // Extended subjects
    case 'current_events':
    case 'news':
    case 'current_affairs':
      return CurrentEvents.CURRENT_EVENTS_QUESTION;

    case 'economics':
    case 'economy':
    case 'finance':
      return Economics.ECONOMICS_QUESTION;

    case 'environment':
    case 'environmental':
    case 'ecology':
    case 'climate':
      return Environment.ENVIRONMENT_QUESTION;

    case 'health':
    case 'medicine':
    case 'medical':
    case 'wellness':
    case 'nutrition':
      return Health.HEALTH_QUESTION;

    case 'law':
    case 'legal':
    case 'justice':
    case 'rights':
      return Law.LAW_QUESTION;

    case 'philosophy':
    case 'ethics':
    case 'logic':
    case 'critical thinking':
      return Philosophy.PHILOSOPHY_QUESTION;

    case 'politics':
    case 'political':
    case 'government':
    case 'civic':
      return Politics.POLITICS_QUESTION;

    case 'psychology':
    case 'mental_health':
    case 'behavior':
    case 'cognition':
      return Psychology.PSYCHOLOGY_QUESTION;

  // NEW CATEGORIES FROM YOUR QUESTION_PATHS.DART
    case 'architecture':
    case 'architectural':
    case 'buildings':
    case 'design':
      return Architecture.ARCHITECTURE_QUESTION;

    case 'art_history':
    case 'art history':
    case 'artistic history':
    case 'fine arts history':
      return ArtHistory.ART_HISTORY_QUESTION;

    case 'astronomy':
    case 'space':
    case 'stars':
    case 'planets':
    case 'cosmos':
      return Astronomy.ASTRONOMY_QUESTION;

    case 'entrepreneurship':
    case 'management':
    case 'commerce':
    case 'business':
      return Business.BUSINESS_QUESTION;

    case 'civics_law':
      return CivicsLaw.CIVICS_LAW_QUESTION;

    case 'comparative_religions':
    case 'comparative religions':
    case 'religions':
    case 'religious studies':
    case 'theology':
      return ComparativeReligions.COMPARATIVE_RELIGIONS_QUESTION;

    case 'computer_science':
    case 'computer science':
    case 'software engineering':
    case 'algorithms':
      return ComputerScience.COMPUTER_SCIENCE_QUESTION;

    case 'cultures':
    case 'global_cultures':
    case 'global cultures':
    case 'cultural studies':
    case 'anthropology':
      return Cultures.GLOBAL_CULTURES_QUESTION;

    case 'economics_finance':
    case 'economics finance':
    case 'financial economics':
    case 'finance economics':
      return EconomicsFinance.ECONOMICS_FINANCE_QUESTION;

    case 'engineering_technology':
    case 'engineering technology':
    case 'engineering':
    case 'mechanical engineering':
    case 'electrical engineering':
      return EngineeringTechnology.ENGINEERING_TECHNOLOGY_QUESTION;

    case 'environmental_science':
    case 'environmental science':
    case 'environmental studies':
    case 'ecology advanced':
      return EnvironmentalScience.ENVIRONMENTAL_SCIENCE_ADVANCED_QUESTION;

    case 'health_medicine':
    case 'health medicine':
    case 'medical science':
    case 'healthcare':
      return HealthMedicine.HEALTH_MEDICINE_QUESTION;

    case 'kids_grade2':
    case 'kids grade2':
    case 'grade 2 kids':
    case 'second grade':
      return Kids.KIDS_GRADE2_QUESTIONS;

    case 'statistics_data':
    case 'statistics data':
    case 'data literacy':
    case 'statistics':
    case 'data science':
      return StatisticsData.STATISTICS_DATA_LITERACY_QUESTION;

    case 'world_literature':
    case 'world literature':
    case 'international literature':
    case 'global literature':
      return WorldLiterature.WORLD_LITERATURE_QUESTION;

  // Alternative file paths for existing categories
    case 'media_questions':
    case 'media alternative':
      return Media.MEDIA_QUESTIONS;

    case 'science_questions':
    case 'science alternative':
      return Science.SCIENCE_QUESTIONS;

    case 'world_ext':
    case 'world extended':
    case 'world extension':
      return World.WORLD_EXT_QUESTION;

  // Misc categories
    case 'misc':
    case 'miscellaneous':
    case 'mixed questions':
      return Misc.QUESTIONS;

    case 'offline':
    case 'offline pack':
    case 'questions offline':
      return Misc.QUESTIONS_OFFLINE_PACK;

  // Game mode categories
    case 'media_challenge':
    case 'media challenge':
    case 'challenge media':
      return Modes.MEDIA_CHALLENGE_QUESTION;

    case 'multimedia':
    case 'multi media':
    case 'mixed media':
      return Modes.MULTIMEDIA_QUESTION;

    case 'multiplayer':
    case 'multi player':
    case 'team play':
      return Modes.MULTIPLAYER_QUESTION;

    case 'speed_round':
    case 'speed round':
    case 'speed quiz':
    case 'quick round':
      return Modes.SPEED_ROUND_QUESTION;

    case 'speed_ultra':
    case 'speed ultra':
    case 'ultra speed':
    case 'lightning round':
      return Modes.SPEED_ULTRA_QUESTION;

  // Class-based categories with multiple variations
    case 'class k':
    case 'class_k':
    case 'kindergarten':
    case 'grade k':
    case 'k':
      return Classes.CLASS_K_QUESTIONS;

    case 'class 1':
    case 'class_1':
    case 'grade 1':
    case 'first grade':
    case '1':
      return Classes.CLASS_1_QUESTIONS;

    case 'class 2':
    case 'class_2':
    case 'grade 2':
    case '2':
      return Classes.CLASS_2_QUESTIONS;

    case 'class 3':
    case 'class_3':
    case 'grade 3':
    case 'third grade':
    case '3':
      return Classes.CLASS_3_QUESTIONS;

    case 'class 4':
    case 'class_4':
    case 'grade 4':
    case 'fourth grade':
    case '4':
      return Classes.CLASS_4_QUESTIONS;

    case 'class 5':
    case 'class_5':
    case 'grade 5':
    case 'fifth grade':
    case '5':
      return Classes.CLASS_5_QUESTIONS;

    case 'class 6':
    case 'class_6':
    case 'grade 6':
    case 'sixth grade':
    case '6':
      return Classes.CLASS_6_QUESTIONS;

    case 'class 7':
    case 'class_7':
    case 'grade 7':
    case 'seventh grade':
    case '7':
      return Classes.CLASS_7_QUESTIONS;

    case 'class 8':
    case 'class_8':
    case 'grade 8':
    case 'eighth grade':
    case '8':
      return Classes.CLASS_8_QUESTIONS;

    case 'class 9':
    case 'class_9':
    case 'grade 9':
    case 'ninth grade':
    case '9':
      return Classes.CLASS_9_QUESTIONS;

    case 'class 10':
    case 'class_10':
    case 'grade 10':
    case 'tenth grade':
    case '10':
      return Classes.CLASS_10_QUESTIONS;

    case 'class 11':
    case 'class_11':
    case 'grade 11':
    case 'eleventh grade':
    case '11':
      return Classes.CLASS_11_QUESTIONS;

    case 'class 12':
    case 'class_12':
    case 'grade 12':
    case 'twelfth grade':
    case '12':
      return Classes.CLASS_12_QUESTIONS;

  // Bonus/Extended content
    case 'bonus':
    case 'extended':
    case 'special':
    case 'challenge':
      return Bonus.EXTENDED_QUESTIONS;

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
    final commonDirs = ['general', 'science', 'math', 'history', 'arts', 'technology', 'classes'];
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
      debugPrint('Successfully loaded questions from: $path');
      return data.map((e) => QuestionModel.fromJson(e)).toList();
    } catch (e) {
      lastErr = e;
      debugPrint('loadQuestionsFromAsset: miss on $path ($e)');
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
    throw FlutterError('Failed to load questions from path: $fullPath. Error: $e');
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
Future<List<QuestionModel>> loadQuestionsFromMultipleCategories(List<String> categories) async {
  final List<QuestionModel> allQuestions = [];
  final List<String> failedCategories = [];

  for (final category in categories) {
    try {
      final questions = await loadQuestionsByCategory(category);
      allQuestions.addAll(questions);
      debugPrint('Successfully loaded ${questions.length} questions from $category');
    } catch (e) {
      failedCategories.add(category);
      debugPrint('Warning: Failed to load questions for category $category: $e');
    }
  }

  if (failedCategories.isNotEmpty && allQuestions.isEmpty) {
    // If all categories failed, try to load from general questions as fallback
    try {
      final generalQuestions = await loadQuestionsByCategory('general');
      allQuestions.addAll(generalQuestions);
      debugPrint('Loaded ${generalQuestions.length} questions from general fallback');
    } catch (e) {
      throw FlutterError('All categories failed to load: $failedCategories. General fallback also failed: $e');
    }
  }

  return allQuestions;
}

/// Discover available question files dynamically
Future<List<String>> discoverAvailableCategories() async {
  final List<String> availableCategories = [];

  // Test common category paths
  final testCategories = [
    'science', 'math', 'history', 'geography', 'arts', 'literature',
    'technology', 'sports', 'entertainment', 'health', 'economics',
    'philosophy', 'psychology', 'politics', 'law', 'environment',
    'current_events', 'world', 'social', 'media', 'kids', 'general'
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
    debugPrint('Error getting question count for $category: $e');
    return 0;
  }
}

/// Validate question data structure
bool validateQuestionData(Map<String, dynamic> questionJson) {
  final requiredFields = ['question', 'answers', 'correctAnswer'];

  for (final field in requiredFields) {
    if (!questionJson.containsKey(field) || questionJson[field] == null) {
      debugPrint('Missing required field: $field');
      return false;
    }
  }

  // Validate answers structure
  if (questionJson['answers'] is! List || (questionJson['answers'] as List).isEmpty) {
    debugPrint('Invalid answers structure');
    return false;
  }

  return true;
}

/// Load questions with validation
Future<List<QuestionModel>> loadQuestionsWithValidation(String category) async {
  try {
    final questions = await loadQuestionsByCategory(category);

    // Filter out invalid questions
    final validQuestions = questions.where((q) =>
    q.question.isNotEmpty &&
        q.options.isNotEmpty &&
        q.correctAnswer.isNotEmpty
    ).toList();

    if (validQuestions.length != questions.length) {
      debugPrint('Filtered out ${questions.length - validQuestions.length} invalid questions from $category');
    }

    return validQuestions;
  } catch (e) {
    debugPrint('Error loading questions with validation for $category: $e');
    rethrow;
  }
}
