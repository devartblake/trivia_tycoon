import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/game_session.dart';
import '../logic/skill_effect_handler.dart';
import '../models/skill_tree_graph.dart';

class GameSessionController extends StateNotifier<GameSession> {
  final Ref ref;
  final SkillEffectHandler effectHandler;

  GameSessionController(this.ref)
      : effectHandler = ref.read(skillEffectHandlerProvider),
        super(ref.read(gameSessionProvider));

  /// Convenience method if you want to trigger from here instead of SkillTreeController
  bool useSkill(SkillNode node) {
    return effectHandler.triggerSkill(node);
  }
}

final gameSessionControllerProvider =
StateNotifierProvider<GameSessionController, GameSession>((ref) {
  return GameSessionController(ref);
});
