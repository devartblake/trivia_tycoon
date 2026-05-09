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

// ── Favorites ─────────────────────────────────────────────────────────────────

/// Optimistic in-memory set of favorited question IDs.
/// The UI updates immediately; API calls are fire-and-forget.
final favoritedQuestionIdsProvider =
    StateProvider<Set<String>>((ref) => const {});

// ── Active sessions (resume) ──────────────────────────────────────────────────

/// Maps studySetId → in-progress sessionId so the user can resume a session
/// they started but did not complete.
final activeStudySessionsProvider =
    StateProvider<Map<String, String>>((ref) => const {});

// ── Category list (for hub quick-access chips) ────────────────────────────────

/// Static category list derived from loaded study sets.
/// Falls back to a curated default list when no sets are loaded.
final studyCategoryListProvider = Provider<List<String>>((ref) {
  final setsAsync = ref.watch(studySetsProvider);
  return setsAsync.whenOrNull(
        data: (sets) {
          final categories = sets
              .map((s) => s.category)
              .where((c) => c.isNotEmpty)
              .toSet()
              .toList()
            ..sort();
          return categories.isNotEmpty ? categories : _defaultCategories;
        },
      ) ??
      _defaultCategories;
});

const _defaultCategories = [
  'Science',
  'History',
  'Geography',
  'Literature',
  'Technology',
  'Sports',
  'Math',
  'Arts',
];
