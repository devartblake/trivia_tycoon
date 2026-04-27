import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/dto/skill_dto.dart';
import '../data/skill_tree_loader.dart';
import '../data/skill_tree_dto_mapper.dart';
import '../models/skill_tree_graph.dart';
import '../controllers/skill_tree_controller.dart';
import 'core_providers.dart';
import 'game_providers.dart';
import 'xp_provider.dart';

/// Loads the skill tree node/edge definitions from the bundled asset JSON.
/// This is the source of truth for all node definition fields.
final skillTreeGraphProvider = FutureProvider<SkillTreeGraph>((ref) async {
  return loadSkillTreeFromAsset('assets/data/skill_tree/skill_tree.json');
});

/// Fetches the player's persisted skill tree state (unlocks + available points)
/// from the server. Returns null on any error so callers can fall back to the
/// asset graph.
final serverSkillTreeProvider = FutureProvider.autoDispose
    .family<SkillTreeDto?, String>((ref, playerId) async {
  try {
    return await ref
        .read(serviceManagerProvider)
        .synaptixApiClient
        .getSkillTree(playerId: playerId);
  } catch (_) {
    return null; // offline / unauthenticated — fall back to local
  }
});

/// Merges server-side unlock state onto the asset graph. Falls back to the
/// asset-only graph when the player is offline or unauthenticated.
final mergedSkillTreeGraphProvider =
    FutureProvider.autoDispose<SkillTreeGraph>((ref) async {
  final assetGraph = await ref.watch(skillTreeGraphProvider.future);

  final profileService = ref.read(playerProfileServiceProvider);
  final playerId = await profileService.getUserId();
  if (playerId == null || playerId.isEmpty) return assetGraph;

  final dto = await ref.watch(serverSkillTreeProvider(playerId).future);
  if (dto == null) return assetGraph;

  return SkillTreeDtoMapper.merge(assetGraph, dto);
});

/// Resolves the player's server-side available skill points.
/// Used to seed [playerXPProvider] on first launch after login.
/// Returns 0 on any error so callers never block on this.
final serverAvailablePointsProvider =
    FutureProvider.autoDispose<int>((ref) async {
  try {
    final profileService = ref.read(playerProfileServiceProvider);
    final playerId = await profileService.getUserId();
    if (playerId == null || playerId.isEmpty) return 0;
    final dto = await ref.watch(serverSkillTreeProvider(playerId).future);
    return dto?.availablePoints ?? 0;
  } catch (_) {
    return 0;
  }
});

/// The canonical skill tree provider consumed by all UI screens.
///
/// The [SkillTreeController] is created **once** and kept alive for the
/// lifetime of the provider. When new server data arrives the graph is
/// hot-swapped via [SkillTreeController.loadGraph], so local selection,
/// positions, and optimistic unlock state are never lost on a server refresh.
///
/// On first authenticated load, [playerXPProvider] is seeded from the
/// server's `availablePoints` field if local XP is still at zero.
final skillTreeProvider =
    StateNotifierProvider<SkillTreeController, SkillTreeState>((ref) {
  final controller = SkillTreeController(
    ref,
    initialGraph: const SkillTreeGraph(nodes: [], edges: []),
  );

  // Hot-swap the graph whenever the merged (server + asset) data changes,
  // without recreating the controller or wiping local state.
  ref.listen<AsyncValue<SkillTreeGraph>>(
    mergedSkillTreeGraphProvider,
    (_, next) {
      next.whenData((g) => controller.loadGraph(g));
    },
    fireImmediately: true,
  );

  // Seed playerXPProvider from server availablePoints on first authenticated
  // load, but only when local XP is still 0 (fresh install / new login).
  ref.listen<AsyncValue<int>>(
    serverAvailablePointsProvider,
    (_, next) {
      next.whenData((serverPts) {
        if (serverPts <= 0) return;
        final xpService = ref.read(xpServiceProvider);
        if (xpService.playerXP == 0) {
          xpService.addXP(serverPts, applyMultiplier: false);
          ref.read(playerXPProvider.notifier).state = xpService.playerXP;
        }
      });
    },
    fireImmediately: true,
  );

  return controller;
});
