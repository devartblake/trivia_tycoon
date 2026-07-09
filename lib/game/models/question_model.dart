import 'package:trivia_tycoon/game/models/answer.dart';
import 'package:trivia_tycoon/game/models/question_type.dart';
import 'package:trivia_tycoon/game/models/question_difficulty.dart';

class QuestionModel {
  final String id;
  final String category;
  final String question;
  final List<Answer> answers;
  final String correctAnswer;
  final List<String> options;
  final QuestionType type;
  final QuestionDifficulty difficulty;
  final int correctIndex;
  final String? imageUrl;
  final String? videoUrl;
  final String? audioUrl; // Audio file URL for audio-based questions
  final String? audioTranscript; // Optional transcript for accessibility
  final int? audioDuration; // Duration in seconds for UI purposes
  final String? powerUpHint;
  final String? powerUpType;
  final bool showHint;
  final List<String>? reducedOptions; // For eliminate power-up
  final int? multiplier; // For XP power-ups
  final bool isBoostedTime;
  final bool isShielded;
  final List<String>? tags;
  final Map<String, String>? optionIdByText;

  QuestionModel({
    required this.id,
    required this.category,
    required this.question,
    required this.answers,
    required this.correctAnswer,
    required this.type,
    required this.difficulty,
    required this.options,
    required this.correctIndex,
    this.imageUrl,
    this.videoUrl,
    this.audioUrl,
    this.audioTranscript,
    this.audioDuration,
    this.powerUpHint,
    this.powerUpType,
    this.showHint = false,
    this.reducedOptions,
    this.multiplier,
    this.isBoostedTime = false,
    this.isShielded = false,
    this.tags,
    this.optionIdByText,
  });

  bool checkAnswer(int selectedIndex) => selectedIndex == correctIndex;

  bool isCorrectAnswer(String selectedAnswer) {
    if (type == QuestionType.freeText) {
      // Typed answers can't be exact-matched fairly: ignore case and
      // collapse internal whitespace before comparing.
      return _normalizeFreeText(selectedAnswer) ==
          _normalizeFreeText(correctAnswer);
    }
    return selectedAnswer == correctAnswer;
  }

  static String _normalizeFreeText(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  String optionIdForAnswer(String selectedAnswer) {
    return optionIdByText?[selectedAnswer] ?? selectedAnswer;
  }

  String answerTextForOptionId(String optionId) {
    if (optionIdByText == null) return optionId;
    for (final entry in optionIdByText!.entries) {
      if (entry.value == optionId) return entry.key;
    }
    return optionId;
  }

  /// Check if this question has audio content
  bool get hasAudio => audioUrl?.isNotEmpty == true;

  /// Check if this question has video content
  bool get hasVideo => videoUrl?.isNotEmpty == true;

  /// Check if this question has image content
  bool get hasImage => imageUrl?.isNotEmpty == true;

  /// Get the media type for this question
  String get mediaType {
    if (hasAudio) return 'audio';
    if (hasVideo) return 'video';
    if (hasImage) return 'image';
    return 'text';
  }

  /// Check if this is a multimedia question
  bool get isMultimedia => hasAudio || hasVideo || hasImage;

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    final rawAnswers = json['answers'];
    final rawOptions = json['options'];
    final optionIdByText = <String, String>{};
    final serializedOptionIds = json['optionIdByText'];
    if (serializedOptionIds is Map) {
      serializedOptionIds.forEach((key, value) {
        optionIdByText[key.toString()] = value.toString();
      });
    }
    final answerMaps = rawAnswers is List
        ? rawAnswers.whereType<Map>().map((answer) {
            final map = Map<String, dynamic>.from(answer);
            final text = map['text']?.toString() ?? '';
            final optionId = (map['optionId'] ?? map['id'])?.toString();
            if (text.isNotEmpty && optionId != null && optionId.isNotEmpty) {
              optionIdByText[text] = optionId;
            }
            return map;
          }).toList()
        : rawOptions is List
            ? rawOptions.map((option) {
                if (option is Map) {
                  final map = Map<String, dynamic>.from(option);
                  final text =
                      (map['text'] ?? map['label'] ?? map['optionText'] ?? '')
                          .toString();
                  final optionId =
                      (map['optionId'] ?? map['id'] ?? text).toString();
                  if (text.isNotEmpty) optionIdByText[text] = optionId;
                  return {
                    'text': text,
                    'isCorrect': false,
                    'optionId': optionId,
                  };
                }
                return {
                  'text': option.toString(),
                  'isCorrect': false,
                };
              }).toList()
            : <Map<String, dynamic>>[];
    final options = answerMaps.map((a) => a['text'].toString()).toList();
    final correctOption = (json['correctAnswer'] ??
            json['correctOptionId'] ??
            json['expectedAnswer'] ??
            '')
        .toString();
    final correctIndex = answerMaps.indexWhere((a) {
      if (a['isCorrect'] == true) return true;
      final optionId = (a['optionId'] ?? a['id'] ?? a['text']).toString();
      return correctOption.isNotEmpty && optionId == correctOption;
    });

    return QuestionModel(
      id: (json['id'] ?? json['questionId'] ?? '').toString(),
      category: json['category'] ?? 'General',
      question: (json['question'] ?? json['text'] ?? '').toString(),
      answers: answerMaps.map(Answer.fromJson).toList(),
      correctAnswer: correctOption,
      type: QuestionTypeExtension.fromString(json['type'] as String?),
      difficulty: QuestionDifficultyExtension.parse(json['difficulty']),
      options: options,
      correctIndex: correctIndex,
      imageUrl: json['imageUrl'] ?? json['mediaKey'],
      videoUrl: json['videoUrl'],
      audioUrl: json['audioUrl'],
      audioTranscript: json['audioTranscript'],
      audioDuration: json['audioDuration'],
      powerUpHint: json['powerUpHint'],
      powerUpType: json['powerUpType'],
      // Defaults for power-up-related data
      showHint: json['showHint'] ?? false,
      reducedOptions: json['reducedOptions'] != null
          ? List<String>.from(json['reducedOptions'])
          : null,
      multiplier: json['multiplier'],
      isBoostedTime: json['isBoostedTime'] ?? false,
      isShielded: json['isShielded'] ?? false,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      optionIdByText: optionIdByText.isEmpty ? null : optionIdByText,
    );
  }

  factory QuestionModel.fromGameplayDto(Map<String, dynamic> json) {
    return QuestionModel.fromJson(json);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'question': question,
      'answers': answers.map((a) => a.toJson()).toList(),
      'correctAnswer': correctAnswer,
      'type': type.value,
      'difficulty': difficulty.value,
      'options': options,
      'correctIndex': correctIndex,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'audioUrl': audioUrl,
      'audioTranscript': audioTranscript,
      'audioDuration': audioDuration,
      'powerUpHint': powerUpHint,
      'powerUpType': powerUpType,
      'showHint': showHint,
      'reducedOptions': reducedOptions,
      'multiplier': multiplier,
      'isBoostedTime': isBoostedTime,
      'isShielded': isShielded,
      'tags': tags,
      'optionIdByText': optionIdByText,
    };
  }

  QuestionModel copyWith({
    String? id,
    String? category,
    String? question,
    List<Answer>? answers,
    String? correctAnswer,
    List<String>? options,
    QuestionType? type,
    QuestionDifficulty? difficulty,
    int? correctIndex,
    String? imageUrl,
    String? videoUrl,
    String? audioUrl,
    String? audioTranscript,
    int? audioDuration,
    String? powerUpHint,
    String? powerUpType,
    bool? showHint,
    List<String>? reducedOptions,
    int? multiplier,
    bool? isBoostedTime,
    bool? isShielded,
    List<String>? tags,
    Map<String, String>? optionIdByText,
  }) {
    return QuestionModel(
      id: id ?? this.id,
      category: category ?? this.category,
      question: question ?? this.question,
      answers: answers ?? this.answers,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      options: options ?? this.options,
      type: type ?? this.type,
      difficulty: difficulty ?? this.difficulty,
      correctIndex: correctIndex ?? this.correctIndex,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      audioTranscript: audioTranscript ?? this.audioTranscript,
      audioDuration: audioDuration ?? this.audioDuration,
      powerUpHint: powerUpHint ?? this.powerUpHint,
      powerUpType: powerUpType ?? this.powerUpType,
      showHint: showHint ?? this.showHint,
      reducedOptions: reducedOptions ?? this.reducedOptions,
      multiplier: multiplier ?? this.multiplier,
      isBoostedTime: isBoostedTime ?? this.isBoostedTime,
      isShielded: isShielded ?? this.isShielded,
      tags: tags ?? this.tags,
      optionIdByText: optionIdByText ?? this.optionIdByText,
    );
  }
}
