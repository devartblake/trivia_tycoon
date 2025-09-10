
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/game/providers/profile_service_provider.dart';
import 'package:trivia_tycoon/game/providers/skill_cooldown_service_provider.dart';
import '../services/game_session.dart';

final gameSessionProvider = Provider<GameSession>((ref) {
  final profile = ref.read(profileServiceProvider);
  final cooldowns = ref.read(skillCooldownServiceProvider);
  return GameSession(profile: profile, cooldowns: cooldowns);
});