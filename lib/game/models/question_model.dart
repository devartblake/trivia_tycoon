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
      powerUpHint: powerUpHint ?? this.powerUpHint,
      powerUpType: powerUpType ?? this.powerUpType,
      showHint: showHint ?? this.showHint,
      reducedOptions: reducedOptions ?? this.reducedOptions,
      multiplier: multiplier ?? this.multiplier,
      isBoostedTime: isBoostedTime ?? this.isBoostedTime,
      isShielded: isShielded ?? this.isShielded,
      tags: tags ??  this.tags,
    );
  }

}
