import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/services/skill_cooldown_service.dart';

void main() {
  group('SkillCooldownService.remainingLabel', () {
    test('returns 00:00 when no cooldown exists', () {
      final service = SkillCooldownService();
      expect(service.remainingLabel('missing'), '00:00');
    });

    test('returns mm:ss while cooldown is active', () {
      final service = SkillCooldownService();
      service.startCooldown('n1', const Duration(seconds: 75));

      final label = service.remainingLabel('n1');
      expect(RegExp(r'^\d{2}:\d{2}$').hasMatch(label), isTrue);
      expect(label.compareTo('00:00') > 0, isTrue);
    });

    test('does not wrap minutes over 59', () {
      final service = SkillCooldownService();
      service.startCooldown('n2', const Duration(minutes: 75));

      final label = service.remainingLabel('n2');
      final minutes = int.parse(label.split(':').first);
      expect(minutes, greaterThanOrEqualTo(74));
    });
  });
}
