
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/skill_cooldown_service.dart';

final skillCooldownServiceProvider = Provider<SkillCooldownService>((ref) {
  return SkillCooldownService();
});
