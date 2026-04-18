import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

import 'package:trivia_tycoon/core/manager/log_manager.dart';

import '../models/answer.dart';
import '../models/question_model.dart';
import '../services/quiz_category.dart';

class QuestionAssetIndexEntry {
  const QuestionAssetIndexEntry({
    required this.folder,
    required this.subfolder,
    required this.filename,
    required this.assetPath,
  });

  final String folder;
  final String subfolder;
  final String filename;
  final String assetPath;

  factory QuestionAssetIndexEntry.fromJson(Map<String, dynamic> json) {
    return QuestionAssetIndexEntry(
      folder: json['folder']?.toString() ?? '',
      subfolder: json['subfolder']?.toString() ?? '',
      filename: json['filename']?.toString() ?? '',
      assetPath: json['asset_path']?.toString() ?? '',
    );
  }
}

class QuestionAssetIndexLoader {
  static const String indexAssetPath =
      'assets/questions/question_paths_index.json';

  List<QuestionAssetIndexEntry>? _cachedEntries;

  Future<List<QuestionAssetIndexEntry>> loadEntries() async {
    if (_cachedEntries != null) {
      return _cachedEntries!;
    }

    final jsonString = await rootBundle.loadString(indexAssetPath);
    final raw = json.decode(jsonString);
    if (raw is! List) {
      throw const FormatException(
        'question_paths_index.json must contain a top-level array',
      );
    }

    _cachedEntries = raw
        .whereType<Map>()
        .map((item) => QuestionAssetIndexEntry.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .where((entry) => entry.assetPath.isNotEmpty)
        .toList(growable: false);
    return _cachedEntries!;
  }

  Future<String?> resolveAssetPath(String query) async {
    final normalizedQuery = _normalize(query);
    if (normalizedQuery.isEmpty) {
      return null;
    }

    final entries = await loadEntries();
    final aliases = _buildAliases(query);

    for (final alias in aliases) {
      for (final entry in entries) {
        if (_entryTokens(entry).contains(alias)) {
          return entry.assetPath;
        }
      }
    }

    for (final alias in aliases) {
      for (final entry in entries) {
        final matches = _entryTokens(entry).any(
          (token) => token.contains(alias) || alias.contains(token),
        );
        if (matches) {
          return entry.assetPath;
        }
      }
    }

    return null;
  }

  Set<String> _entryTokens(QuestionAssetIndexEntry entry) {
    return {
      _normalize(entry.folder),
      _normalize(entry.subfolder),
      _normalize(entry.filename),
      _normalize(entry.assetPath),
      ...entry.assetPath
          .split('/')
          .map(_normalize)
          .where((token) => token.isNotEmpty),
    };
  }

  Set<String> _buildAliases(String query) {
    final normalized = _normalize(query);
    final aliases = <String>{
      normalized,
      normalized.replaceAll('question', ''),
      normalized.replaceAll('questions', ''),
      normalized.replaceAll('knowledge', ''),
    }..removeWhere((alias) => alias.isEmpty);

    final category = QuizCategoryManager.fromString(query);
    if (category != null) {
      aliases.add(_normalize(category.name));
      aliases.add(_normalize(category.displayName));
      aliases.add(_normalize(category.datasetName));
    }

    final extraAliases = _manualAliases[normalized];
    if (extraAliases != null) {
      aliases.addAll(extraAliases.map(_normalize));
    }

    return aliases;
  }

  String _normalize(String value) {
    final lower = value.toLowerCase().trim();
    return lower.replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }

  static const Map<String, List<String>> _manualAliases = {
    'generalknowledge': ['general', 'general_questions'],
    'mathematics': ['math', 'math_question'],
    'technology': ['tech', 'tech_question'],
    'socialstudies': ['social', 'social_question'],
    'currentevents': ['current_events', 'current_events_question'],
    'kidsquestions': ['kids', 'kids_questions'],
    'kidsgrade2': ['class_2_questions', 'kids_grade2_questions'],
    'civicslaw': ['civics_law', 'civics_law_question'],
    'economicsfinance': [
      'economics_finance',
      'economics_finance_question',
    ],
    'engineeringtechnology': [
      'engineering_technology',
      'engineering_technology_question',
    ],
    'environmentalscience': [
      'environmental_science',
      'environmental_science_advanced_question',
    ],
    'healthmedicine': ['health_medicine', 'health_medicine_question'],
    'statisticsdata': [
      'statistics_data',
      'statistics_data_literacy_question',
    ],
    'worldliterature': ['world_literature', 'world_literature_question'],
  };
}

class QuestionPresentationRandomizer {
  static List<QuestionModel> shuffleQuestions(
    Iterable<QuestionModel> questions, {
    Random? random,
  }) {
    final shuffled = questions.toList(growable: true);
    shuffled.shuffle(random);
    return shuffled;
  }

  static QuestionModel shuffleQuestionAnswers(
    QuestionModel question, {
    Random? random,
  }) {
    if (question.answers.length <= 1) {
      return question;
    }

    final shuffledAnswers = question.answers
        .map((answer) => Answer(text: answer.text, isCorrect: answer.isCorrect))
        .toList(growable: true);
    shuffledAnswers.shuffle(random);

    final correctIndex =
        shuffledAnswers.indexWhere((answer) => answer.isCorrect == true);
    final correctAnswer = correctIndex >= 0
        ? shuffledAnswers[correctIndex].text
        : question.correctAnswer;

    return question.copyWith(
      answers: shuffledAnswers,
      options: shuffledAnswers.map((answer) => answer.text).toList(),
      correctIndex: correctIndex >= 0 ? correctIndex : question.correctIndex,
      correctAnswer: correctAnswer,
    );
  }

  static List<QuestionModel> shuffleQuestionsAndAnswers(
    Iterable<QuestionModel> questions, {
    Random? random,
  }) {
    final seededRandom = random ?? Random();
    final shuffledQuestions = questions
        .map((question) => shuffleQuestionAnswers(
              question,
              random: seededRandom,
            ))
        .toList(growable: true);
    shuffledQuestions.shuffle(seededRandom);
    return shuffledQuestions;
  }
}

Future<List<QuestionModel>> loadIndexedQuestionAssets({
  String? query,
  QuestionAssetIndexLoader? indexLoader,
}) async {
  final loader = indexLoader ?? QuestionAssetIndexLoader();
  final resolvedPath =
      query == null ? null : await loader.resolveAssetPath(query);
  if (resolvedPath == null) {
    return const <QuestionModel>[];
  }

  try {
    final jsonString = await rootBundle.loadString(resolvedPath);
    final raw = json.decode(jsonString);
    if (raw is! List) {
      throw const FormatException(
        'Question asset must contain a top-level array',
      );
    }

    final questions = raw
        .whereType<Map>()
        .map((item) => QuestionModel.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
    return QuestionPresentationRandomizer.shuffleQuestionsAndAnswers(questions);
  } catch (error) {
    LogManager.debug(
      'Failed to load indexed question asset for "$query": $error',
    );
    return const <QuestionModel>[];
  }
}
