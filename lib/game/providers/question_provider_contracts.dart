import '../services/quiz_category.dart';

Map<String, dynamic> normalizeQuestionStats(Map<String, dynamic> raw) {
  return {
    ...raw,
    'questionCount': _asInt(raw['questionCount'] ?? raw['totalQuestions'] ?? raw['total']),
    'categoryCount': _asInt(raw['categoryCount'] ?? raw['categories'] ?? raw['totalCategories']),
    'source': (raw['source'] ?? 'backend').toString(),
  };
}

Map<String, dynamic> normalizeDatasetInfo(Map<String, dynamic> raw) {
  return {
    ...raw,
    'name': (raw['name'] ?? raw['datasetName'] ?? 'default').toString(),
    'version': (raw['version'] ?? raw['datasetVersion'] ?? 'unknown').toString(),
    'questionCount': _asInt(raw['questionCount'] ?? raw['totalQuestions'] ?? raw['total']),
    'source': (raw['source'] ?? 'backend').toString(),
  };
}

Map<String, dynamic> normalizeCategoryStats(Map<String, dynamic> raw, QuizCategory category) {
  return {
    ...raw,
    'category': (raw['category'] ?? category.name).toString(),
    'questionCount': _asInt(raw['questionCount'] ?? raw['totalQuestions'] ?? raw['total']),
    'difficulty': (raw['difficulty'] ?? 'mixed').toString(),
    'source': (raw['source'] ?? 'backend').toString(),
  };
}

Map<String, dynamic> normalizeClassStats(Map<String, dynamic> raw) {
  final rawCategories = raw['availableCategories'];
  final availableCategories = rawCategories is List
      ? rawCategories.whereType<QuizCategory>().toList()
      : const <QuizCategory>[];

  return {
    ...raw,
    'questionCount': _asInt(raw['questionCount'] ?? raw['totalQuestions'] ?? raw['total']),
    'subjectCount': _asInt(raw['subjectCount'] ?? raw['categoryCount'] ?? availableCategories.length),
    'availableCategories': availableCategories,
    'source': (raw['source'] ?? 'backend').toString(),
  };
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
