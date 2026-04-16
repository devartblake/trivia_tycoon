import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dto/learning_dto.dart';
import '../../core/repositories/learning_repository.dart';
import 'core_providers.dart';
import 'game_providers.dart';

// ---------------------------------------------------------------------------
// Repository provider
// ---------------------------------------------------------------------------

final learningRepositoryProvider = Provider<LearningRepository>((ref) {
  return ApiLearningRepository(ref.watch(apiServiceProvider));
});

// ---------------------------------------------------------------------------
// Data providers
// ---------------------------------------------------------------------------

/// Fetches published modules, optionally decorating each with `isCompleted`
/// for the given player ID. Pass null when the player is not authenticated.
final modulesProvider = FutureProvider.autoDispose
    .family<List<ModuleDto>, String?>((ref, playerId) async {
  return ref
      .read(learningRepositoryProvider)
      .getModules(playerId: playerId);
});

/// Fetches modules filtered by difficulty (1–4). The playerId is still
/// threaded through so completed state is available on filtered lists.
/// Key is encoded as "$playerId|$difficulty" to distinguish family instances.
final modulesByDifficultyProvider = FutureProvider.autoDispose
    .family<List<ModuleDto>, String>((ref, key) async {
  // key format: "<playerId>|<difficulty>"  (playerId may be empty)
  final parts = key.split('|');
  final playerId = parts[0].isEmpty ? null : parts[0];
  final difficulty = parts.length > 1 ? int.tryParse(parts[1]) : null;
  return ref
      .read(learningRepositoryProvider)
      .getModules(playerId: playerId, difficulty: difficulty);
});

/// Fetches a single module's detail by ID.
final moduleDetailProvider =
    FutureProvider.autoDispose.family<ModuleDto, String>((ref, moduleId) async {
  return ref.read(learningRepositoryProvider).getModule(moduleId);
});

/// Fetches the ordered lesson list for a module.
final lessonsProvider = FutureProvider.autoDispose
    .family<List<LessonDto>, String>((ref, moduleId) async {
  return ref.read(learningRepositoryProvider).getLessons(moduleId);
});

// ---------------------------------------------------------------------------
// Lesson flow state
// ---------------------------------------------------------------------------

class LessonFlowState {
  final int currentIndex;
  final String? selectedOptionId;
  final bool answered;

  const LessonFlowState({
    this.currentIndex = 0,
    this.selectedOptionId,
    this.answered = false,
  });

  LessonFlowState copyWith({
    int? currentIndex,
    String? selectedOptionId,
    bool? answered,
    bool clearSelection = false,
  }) {
    return LessonFlowState(
      currentIndex: currentIndex ?? this.currentIndex,
      selectedOptionId:
          clearSelection ? null : (selectedOptionId ?? this.selectedOptionId),
      answered: answered ?? this.answered,
    );
  }
}

class LessonFlowNotifier extends StateNotifier<LessonFlowState> {
  final List<LessonDto> lessons;

  LessonFlowNotifier(this.lessons) : super(const LessonFlowState());

  void selectOption(String optionId) {
    if (state.answered) return;
    state = state.copyWith(selectedOptionId: optionId, answered: true);
  }

  void nextLesson() {
    if (!state.answered) return;
    final next = state.currentIndex + 1;
    if (next < lessons.length) {
      state = LessonFlowState(currentIndex: next);
    }
  }

  bool get isLastLesson => state.currentIndex >= lessons.length - 1;

  LessonDto get currentLesson => lessons[state.currentIndex];
}

/// Family keyed by moduleId. The list of lessons is injected after they load.
/// In practice the screen creates this provider once lessons are available.
final lessonFlowProvider = StateNotifierProvider.autoDispose
    .family<LessonFlowNotifier, LessonFlowState, List<LessonDto>>(
  (ref, lessons) => LessonFlowNotifier(lessons),
);

// ---------------------------------------------------------------------------
// Player ID helper (mirrors skill_tree_provider.dart pattern)
// ---------------------------------------------------------------------------

/// Resolves the current player's ID from local profile storage.
/// Returns null when the player is not authenticated / ID not yet set.
final currentPlayerIdProvider = FutureProvider.autoDispose<String?>((ref) async {
  final profileService = ref.read(playerProfileServiceProvider);
  final id = await profileService.getUserId();
  return (id != null && id.isNotEmpty) ? id : null;
});
