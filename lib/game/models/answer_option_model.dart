/// Represents a single answer option for a question
class AnswerOptionModel {
  final String id;
  final String text;
  final String? mediaUrl; // Image/video for image-based questions
  final String? semanticLabel; // For accessibility
  final bool isCorrect;

  const AnswerOptionModel({
    required this.id,
    required this.text,
    this.mediaUrl,
    this.semanticLabel,
    this.isCorrect = false,
  });

  /// Create from JSON
  factory AnswerOptionModel.fromJson(Map<String, dynamic> json) {
    return AnswerOptionModel(
      id: (json['optionId'] ?? json['id'] ?? json['text'] ?? '').toString(),
      text: (json['text'] ?? json['label'] ?? json['optionText'] ?? '')
          .toString(),
      mediaUrl: json['mediaUrl'] ?? json['imageUrl'] ?? json['imageKey'],
      semanticLabel: json['semanticLabel'] ?? json['ariaLabel'],
      isCorrect: json['isCorrect'] == true,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'optionId': id,
      'text': text,
      'mediaUrl': mediaUrl,
      'semanticLabel': semanticLabel,
      'isCorrect': isCorrect,
    };
  }

  /// Create a copy with optional modifications
  AnswerOptionModel copyWith({
    String? id,
    String? text,
    String? mediaUrl,
    String? semanticLabel,
    bool? isCorrect,
  }) {
    return AnswerOptionModel(
      id: id ?? this.id,
      text: text ?? this.text,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      semanticLabel: semanticLabel ?? this.semanticLabel,
      isCorrect: isCorrect ?? this.isCorrect,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnswerOptionModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          text == other.text &&
          mediaUrl == other.mediaUrl &&
          isCorrect == other.isCorrect;

  @override
  int get hashCode => Object.hash(id, text, mediaUrl, isCorrect);

  @override
  String toString() =>
      'AnswerOptionModel(id: $id, text: $text, isCorrect: $isCorrect)';
}
