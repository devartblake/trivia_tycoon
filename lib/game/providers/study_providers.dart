import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dto/study_dto.dart';
import '../../core/services/study/study_service.dart';
import 'core_providers.dart';

final studyServiceProvider = Provider<StudyService>((ref) {
  return StudyService(ref.watch(apiServiceProvider));
});

// ── Discovery ─────────────────────────────────────────────────────────────────

final studySetsProvider = FutureProvider<List<StudySetListItem>>((ref) {
  return ref.watch(studyServiceProvider).fetchStudySets();
});

final recommendedStudySetsProvider =
    FutureProvider<List<StudySetListItem>>((ref) {
  return ref.watch(studyServiceProvider).fetchRecommended();
});

final studySetDetailProvider =
    FutureProvider.family<StudySetDetail, String>((ref, setId) {
  return ref.watch(studyServiceProvider).fetchStudySet(setId);
});

// ── Sessions ──────────────────────────────────────────────────────────────────

final studySessionSummaryProvider =
    FutureProvider.family<StudySession, String>((ref, sessionId) {
  return ref.watch(studyServiceProvider).getSessionSummary(sessionId);
});
