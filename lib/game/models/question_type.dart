/// Question type enumeration for type-safe question rendering and handling
enum QuestionType {
  multipleChoice,
  trueFalse,
  imageChoice,
  videoChoice,
  audioChoice,
  dragDrop,
  sorting,
  matching,
  classification,
  labeling,
  freeText,
}

extension QuestionTypeExtension on QuestionType {
  /// Convert enum to string for API/storage
  String get value {
    switch (this) {
      case QuestionType.multipleChoice:
        return 'multiple_choice';
      case QuestionType.trueFalse:
        return 'true_false';
      case QuestionType.imageChoice:
        return 'image_choice';
      case QuestionType.videoChoice:
        return 'video_choice';
      case QuestionType.audioChoice:
        return 'audio_choice';
      case QuestionType.dragDrop:
        return 'drag_drop';
      case QuestionType.sorting:
        return 'sorting';
      case QuestionType.matching:
        return 'matching';
      case QuestionType.classification:
        return 'classification';
      case QuestionType.labeling:
        return 'labeling';
      case QuestionType.freeText:
        return 'free_text';
    }
  }

  /// Display name for UI
  String get displayName {
    switch (this) {
      case QuestionType.multipleChoice:
        return 'Multiple Choice';
      case QuestionType.trueFalse:
        return 'True/False';
      case QuestionType.imageChoice:
        return 'Image Question';
      case QuestionType.videoChoice:
        return 'Video Question';
      case QuestionType.audioChoice:
        return 'Audio Question';
      case QuestionType.dragDrop:
        return 'Drag & Drop';
      case QuestionType.sorting:
        return 'Sorting';
      case QuestionType.matching:
        return 'Matching';
      case QuestionType.classification:
        return 'Classification';
      case QuestionType.labeling:
        return 'Labeling';
      case QuestionType.freeText:
        return 'Free Text';
    }
  }

  /// Check if this type has multimedia content
  bool get isMultimedia {
    return this == QuestionType.imageChoice ||
        this == QuestionType.videoChoice ||
        this == QuestionType.audioChoice;
  }

  /// Parse string value to enum (backward compatible)
  static QuestionType fromString(String? value) {
    if (value == null || value.isEmpty) {
      return QuestionType.multipleChoice;
    }

    final normalized = value.toLowerCase().trim();

    switch (normalized) {
      case 'multiple_choice':
      case 'multiplechoice':
      case 'mc':
        return QuestionType.multipleChoice;
      case 'true_false':
      case 'truefalse':
      case 'tf':
      case 'boolean':
        return QuestionType.trueFalse;
      case 'image_choice':
      case 'imagechoice':
      case 'image':
        return QuestionType.imageChoice;
      case 'video_choice':
      case 'videochoice':
      case 'video':
        return QuestionType.videoChoice;
      case 'audio_choice':
      case 'audiochoice':
      case 'audio':
        return QuestionType.audioChoice;
      case 'drag_drop':
      case 'dragdrop':
        return QuestionType.dragDrop;
      case 'sorting':
        return QuestionType.sorting;
      case 'matching':
        return QuestionType.matching;
      case 'classification':
        return QuestionType.classification;
      case 'labeling':
      case 'labelling':
        return QuestionType.labeling;
      case 'free_text':
      case 'freetext':
      case 'text':
        return QuestionType.freeText;
      default:
        return QuestionType.multipleChoice;
    }
  }
}
