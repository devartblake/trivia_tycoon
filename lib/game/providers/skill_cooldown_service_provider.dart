import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/core_providers.dart';
import '../services/skill_cooldown_service.dart';

final skillCooldownServiceProvider = Provider<SkillCooldownService>((ref) {
  return SkillCooldownService(
    storage: ref.read(generalKeyValueStorageProvider),
  );
});
