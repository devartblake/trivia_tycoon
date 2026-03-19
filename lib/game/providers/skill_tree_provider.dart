import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/dto/skill_dto.dart';
import '../data/skill_tree_loader.dart';
import '../data/skill_tree_dto_mapper.dart';
import '../models/skill_tree_graph.dart';
import '../controllers/skill_tree_controller.dart';
import 'core_providers.dart';
import 'game_providers.dart';

/// Loads the skill tree definition from the bundled asset JSON.
/// This is the source of truth for all node definition fields.
final skillTreeGraphProvider = FutureProvider<SkillTreeGraph>((ref) async {
  return loadSkillTreeFromAsset('assets/data/skill_tree/skill_tree.json');
});

/// Fetches the player's skill tree state from the server.
/// Returns null on any error so callers can fall back to asset data.
final serverSkillTreeProvider =
FutureProvider.autoDispose.family<SkillTreeDto?, String>((ref, playerId) async {
  try {
    return await ref
        .read(serviceManagerProvider)
        .tycoonApiClient
        .getSkillTree(playerId: playerId);
  } catch (_) {
    return null; // offline / unauthenticated — fall back to local
  }
});

/// Watches the logged-in player's ID, fetches server skill state, and
/// merges it onto the asset graph. Falls back to asset-only when offline
/// or when the player is not authenticated.
final mergedSkillTreeGraphProvider =
FutureProvider.autoDispose<SkillTreeGraph>((ref) async {
  final assetGraph = await ref.watch(skillTreeGraphProvider.future);

  // Get player ID from local profile storage (set during login)
  final profileService = ref.read(playerProfileServiceProvider);
  final playerId = await profileService.getUserId();

  if (playerId == null || playerId.isEmpty) return assetGraph;

  final dto = await ref.watch(serverSkillTreeProvider(playerId).future);
  if (dto == null) return assetGraph;

  return SkillTreeDtoMapper.merge(assetGraph, dto);
});

/// The canonical skill tree provider consumed by UI screens.
/// Uses the merged (server + asset) graph; falls back to an empty graph
/// while data is loading so the UI remains alive.
final skillTreeProvider =
StateNotifierProvider<SkillTreeController, SkillTreeState>((ref) {
  final graphAsync = ref.watch(mergedSkillTreeGraphProvider);

  final graph = graphAsync.maybeWhen(
    data: (g) => g,
    orElse: () => const SkillTreeGraph(nodes: [], edges: []),
  );

  // If your controller already expects (ref, initialGraph: ...)
  return SkillTreeController(
    ref,
    initialGraph: graph,
    // optional persistence hooks can still be passed here
  );
});
