import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/game/providers/xp_provider.dart';
import '../logic/skill_effect_handler.dart';
import 'game_session_provider.dart';

/// Provider that builds the handler from the session
final skillEffectHandlerProvider = Provider<SkillEffectHandler>((ref) {
  final gameSession = ref.read(gameSessionProvider);
  final xp = ref.read(xpServiceProvider);

  return SkillEffectHandler(
    gameSession: gameSession,
    xpService: xp,
    profileService: gameSession.getProfileService(),
    cooldownService: gameSession.getSkillCooldownService(),
  );
});
