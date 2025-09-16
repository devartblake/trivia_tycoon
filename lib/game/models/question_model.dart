import 'package:trivia_tycoon/game/models/answer.dart';

class QuestionModel {
  final String id;
  final String category;
  final String question;
  final List<Answer> answers;
  final String correctAnswer;
  final List<String> options;
  final String type;
  final int difficulty; // Scale 1-3 or easy, medium, hard
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
  });

  bool checkAnswer(int selectedIndex) => selectedIndex == correctIndex;

  bool isCorrectAnswer(String selectedAnswer) {
    return selectedAnswer == correctAnswer;
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
    return QuestionModel(
      id: json['id'] ?? '',
      category: json['category'] ?? 'General',
      question: json['question'] ?? '',
      answers: (json['answers'] as List<dynamic>)
          .map((a) => Answer.fromJson(a))
          .toList(),
      correctAnswer: json['correctAnswer'] ?? '',
      type: json['type'] ?? 'multiple_choice',
      difficulty: json['difficulty'] ?? 1,
      options: (json['answers'] as List<dynamic>)
          .map((a) => a['text'].toString())
          .toList(),
      correctIndex: (json['answers'] as List<dynamic>)
          .indexWhere((a) => a['isCorrect'] == true),
      imageUrl: json['imageUrl'],
      videoUrl: json['videoUrl'],
      audioUrl: json['audioUrl'],
      audioTranscript: json['audioTranscript'],
      audioDuration: json['audioDuration'],
      powerUpHint: json['powerUpHint'],
      powerUpType: json['powerUpType'],
      // Defaults for power-up-related data
      showHint: json['showHint'] ?? false,
      reducedOptions: json['reducedOptions'] != null ? List<String>.from(json['reducedOptions']) : null,
      multiplier: json['multiplier'],
      isBoostedTime: json['isBoostedTime'] ?? false,
      isShielded: json['isShielded'] ?? false,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'question': question,
      'answers': answers.map((a) => a.toJson()).toList(),
      'correctAnswer': correctAnswer,
      'type': type,
      'difficulty': difficulty,
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
    };
  }

  QuestionModel copyWith({
    String? id,
    String? category,
    String? question,
    List<Answer>? answers,
    String? correctAnswer,
    List<String>? options,
    String? type,
    int? difficulty,
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
    );
  }
}
