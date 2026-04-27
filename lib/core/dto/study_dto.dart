/// DTOs for the Study surface — /study-sets and /study-sessions endpoints.
/// Study set detail intentionally exposes correctOptionId (rehearsal, not gameplay).

// ── Study Sets ────────────────────────────────────────────────────────────────

class StudySetListItem {
  final String id;
  final String title;
  final String description;
  final String kind;
  final String category;
  final int questionCount;

  const StudySetListItem({
    required this.id,
    required this.title,
    this.description = '',
    required this.kind,
    required this.category,
    this.questionCount = 0,
  });

  factory StudySetListItem.fromJson(Map<String, dynamic> json) {
    return StudySetListItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      kind: json['kind']?.toString() ?? 'Category',
      category: json['category']?.toString() ?? '',
      questionCount: (json['questionCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class StudyQuestion {
  final String id;
  final String text;
  final String category;
  final String difficulty;
  final List<StudyOption> options;
  final String? correctOptionId;
  final String? explanation;
  final String? mediaKey;

  const StudyQuestion({
    required this.id,
    required this.text,
    required this.category,
    this.difficulty = 'Easy',
    required this.options,
    this.correctOptionId,
    this.explanation,
    this.mediaKey,
  });

  factory StudyQuestion.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'] as List<dynamic>? ?? const [];
    return StudyQuestion(
      id: json['id']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      difficulty: json['difficulty']?.toString() ?? 'Easy',
      options: rawOptions
          .whereType<Map>()
          .map((o) => StudyOption.fromJson(Map<String, dynamic>.from(o)))
          .toList(),
      correctOptionId: json['correctOptionId']?.toString(),
      explanation: json['explanation']?.toString(),
      mediaKey: json['mediaKey']?.toString(),
    );
  }
}

class StudyOption {
  final String id;
  final String text;

  const StudyOption({required this.id, required this.text});

  factory StudyOption.fromJson(Map<String, dynamic> json) {
    return StudyOption(
      id: json['id']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
    );
  }
}

class StudySetDetail {
  final String id;
  final String title;
  final String description;
  final String kind;
  final String category;
  final int questionCount;
  final List<StudyQuestion> questions;

  const StudySetDetail({
    required this.id,
    required this.title,
    this.description = '',
    required this.kind,
    required this.category,
    this.questionCount = 0,
    this.questions = const [],
  });

  factory StudySetDetail.fromJson(Map<String, dynamic> json) {
    final rawQuestions = json['questions'] as List<dynamic>? ?? const [];
    return StudySetDetail(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      kind: json['kind']?.toString() ?? 'Category',
      category: json['category']?.toString() ?? '',
      questionCount: (json['questionCount'] as num?)?.toInt() ?? 0,
      questions: rawQuestions
          .whereType<Map>()
          .map((q) => StudyQuestion.fromJson(Map<String, dynamic>.from(q)))
          .toList(),
    );
  }
}

// ── Study Sessions ────────────────────────────────────────────────────────────

enum StudySessionMode { selfTest, flashcard }

extension StudySessionModeExt on StudySessionMode {
  String get apiValue => switch (this) {
        StudySessionMode.selfTest => 'SelfTest',
        StudySessionMode.flashcard => 'Flashcard',
      };
}

enum FlashcardAction { again, hard, good, easy }

extension FlashcardActionExt on FlashcardAction {
  String get apiValue => switch (this) {
        FlashcardAction.again => 'Again',
        FlashcardAction.hard => 'Hard',
        FlashcardAction.good => 'Good',
        FlashcardAction.easy => 'Easy',
      };
}

class StudySession {
  final String id;
  final String studySetId;
  final StudySessionMode mode;
  final String title;
  final String kind;
  final int questionCount;
  final int answeredCount;
  final int correctCount;
  final int currentQuestionIndex;
  final bool isCompleted;
  final List<String> questionIds;
  final List<String> answeredQuestionIds;

  const StudySession({
    required this.id,
    required this.studySetId,
    required this.mode,
    required this.title,
    required this.kind,
    required this.questionCount,
    this.answeredCount = 0,
    this.correctCount = 0,
    this.currentQuestionIndex = 0,
    this.isCompleted = false,
    this.questionIds = const [],
    this.answeredQuestionIds = const [],
  });

  factory StudySession.fromJson(Map<String, dynamic> json) {
    final modeStr = json['mode']?.toString() ?? 'SelfTest';
    return StudySession(
      id: json['id']?.toString() ?? '',
      studySetId: json['studySetId']?.toString() ?? '',
      mode: modeStr == 'Flashcard'
          ? StudySessionMode.flashcard
          : StudySessionMode.selfTest,
      title: json['title']?.toString() ?? '',
      kind: json['kind']?.toString() ?? '',
      questionCount: (json['questionCount'] as num?)?.toInt() ?? 0,
      answeredCount: (json['answeredCount'] as num?)?.toInt() ?? 0,
      correctCount: (json['correctCount'] as num?)?.toInt() ?? 0,
      currentQuestionIndex:
          (json['currentQuestionIndex'] as num?)?.toInt() ?? 0,
      isCompleted: json['isCompleted'] as bool? ?? false,
      questionIds: (json['questionIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      answeredQuestionIds: (json['answeredQuestionIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}
