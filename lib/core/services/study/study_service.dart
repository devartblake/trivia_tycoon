import '../../dto/study_dto.dart';
import '../api_service.dart';

/// Wraps all /study-sets and /study-sessions backend endpoints.
class StudyService {
  final ApiService _api;

  const StudyService(this._api);

  // ── Study Set Discovery ───────────────────────────────────────────────────

  Future<List<StudySetListItem>> fetchStudySets() async {
    final json = await _api.get('/study-sets');
    final items = json['items'] as List<dynamic>? ?? const [];
    return items
        .whereType<Map>()
        .map((m) => StudySetListItem.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<List<StudySetListItem>> fetchRecommended() async {
    final json = await _api.get('/study-sets/recommended');
    final items = json['items'] as List<dynamic>? ?? const [];
    return items
        .whereType<Map>()
        .map((m) => StudySetListItem.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<StudySetDetail> fetchStudySet(String setId) async {
    final json = await _api.get('/study-sets/$setId');
    return StudySetDetail.fromJson(json);
  }

  // ── Favorites ─────────────────────────────────────────────────────────────

  Future<void> addFavorite(String questionId) {
    return _api.post('/study-sets/favorites/$questionId', body: {});
  }

  Future<void> removeFavorite(String questionId) {
    return _api.delete('/study-sets/favorites/$questionId');
  }

  // ── Custom Study Sets ─────────────────────────────────────────────────────

  Future<StudySetDetail> createStudySet({
    required String title,
    String description = '',
    required List<String> questionIds,
  }) async {
    final json = await _api.post('/study-sets', body: {
      'title': title,
      if (description.isNotEmpty) 'description': description,
      'questionIds': questionIds,
    });
    return StudySetDetail.fromJson(json);
  }

  Future<StudySetDetail> updateStudySet({
    required String setId,
    required String title,
    String description = '',
    required List<String> questionIds,
  }) async {
    final json = await _api.patch('/study-sets/$setId', body: {
      'title': title,
      if (description.isNotEmpty) 'description': description,
      'questionIds': questionIds,
    });
    return StudySetDetail.fromJson(json);
  }

  // ── Study Sessions ────────────────────────────────────────────────────────

  Future<StudySession> createSession({
    required String studySetId,
    StudySessionMode mode = StudySessionMode.selfTest,
    int? count,
  }) async {
    final json = await _api.post('/study-sessions', body: {
      'studySetId': studySetId,
      'mode': mode.apiValue,
      if (count != null) 'count': count,
    });
    return StudySession.fromJson(json);
  }

  Future<StudySession> updateProgress({
    required String sessionId,
    required String questionId,
    String? selectedOptionId,
    FlashcardAction? flashcardAction,
    int? currentQuestionIndex,
    double? confidence,
    bool? answerRevealed,
    bool isCompleted = false,
  }) async {
    final json = await _api.post('/study-sessions/$sessionId/progress', body: {
      'questionId': questionId,
      if (selectedOptionId != null) 'selectedOptionId': selectedOptionId,
      if (flashcardAction != null) 'flashcardAction': flashcardAction.apiValue,
      if (currentQuestionIndex != null)
        'currentQuestionIndex': currentQuestionIndex,
      if (confidence != null) 'confidence': confidence,
      if (answerRevealed != null) 'answerRevealed': answerRevealed,
      'isCompleted': isCompleted,
    });
    return StudySession.fromJson(json);
  }

  Future<StudySession> getSessionSummary(String sessionId) async {
    final json = await _api.get('/study-sessions/$sessionId/summary');
    return StudySession.fromJson(json);
  }
}
