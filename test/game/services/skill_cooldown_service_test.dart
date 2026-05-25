import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/core/services/settings/general_key_value_storage_service.dart';
import 'package:trivia_tycoon/game/services/skill_cooldown_service.dart';

// ---------------------------------------------------------------------------
// Fake storage for tests
// ---------------------------------------------------------------------------

class _FakeStorage extends GeneralKeyValueStorageService {
  final Map<String, dynamic> _store = {};

  @override
  Future<Map<String, dynamic>?> getJson(String key) async {
    final raw = _store[key];
    if (raw is Map<String, dynamic>) return Map<String, dynamic>.from(raw);
    return null;
  }

  @override
  Future<void> setJson(String key, Map<String, dynamic> value) async {
    _store[key] = Map<String, dynamic>.from(value);
  }
}

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

  group('SkillCooldownService.nextAvailableLabel', () {
    test('returns null when cooldown is inactive', () {
      final service = SkillCooldownService();
      expect(service.nextAvailableLabel('missing'), isNull);
    });

    test('returns next-available message while cooldown is active', () {
      final service = SkillCooldownService();
      service.startCooldown('n3', const Duration(seconds: 30));

      final label = service.nextAvailableLabel('n3');
      expect(label, isNotNull);
      expect(label, startsWith('Next available in '));
    });
  });

  group('SkillCooldownService.nextAvailableChipLabel', () {
    test('returns null when cooldown is inactive', () {
      final service = SkillCooldownService();
      expect(service.nextAvailableChipLabel('missing'), isNull);
    });

    test('returns compact next label while cooldown is active', () {
      final service = SkillCooldownService();
      service.startCooldown('n4', const Duration(seconds: 30));

      final label = service.nextAvailableChipLabel('n4');
      expect(label, isNotNull);
      expect(label, startsWith('Next '));
      expect(label, isNot(contains('available in')));
    });
  });

  // ── persistCooldowns / restoreCooldowns ─────────────────────────────────

  group('SkillCooldownService — persistence', () {
    test('persistCooldowns is no-op when storage is null', () async {
      final service = SkillCooldownService();
      service.startCooldown('s1', const Duration(minutes: 5));
      // Should not throw
      await expectLater(service.persistCooldowns(), completes);
    });

    test('restoreCooldowns is no-op when storage is null', () async {
      final service = SkillCooldownService();
      await expectLater(service.restoreCooldowns(), completes);
      expect(service.isOnCooldown('s1'), isFalse);
    });

    test(
        'persistCooldowns saves active cooldowns; restoreCooldowns reloads them',
        () async {
      final storage = _FakeStorage();

      // Service A sets a cooldown and persists it.
      final serviceA = SkillCooldownService(storage: storage);
      serviceA.startCooldown('skill_x', const Duration(hours: 1));
      await serviceA.persistCooldowns();

      // Service B (fresh instance, same storage) should restore the cooldown.
      final serviceB = SkillCooldownService(storage: storage);
      expect(serviceB.isOnCooldown('skill_x'), isFalse); // not yet restored
      await serviceB.restoreCooldowns();
      expect(serviceB.isOnCooldown('skill_x'), isTrue);
    });

    test('restoreCooldowns ignores already-expired entries', () async {
      final storage = _FakeStorage();

      // Manually write an expired timestamp.
      await storage.setJson('skillCooldownExpiry', {
        'stale_skill': DateTime.now()
            .subtract(const Duration(seconds: 1))
            .toIso8601String(),
      });

      final service = SkillCooldownService(storage: storage);
      await service.restoreCooldowns();

      expect(service.isOnCooldown('stale_skill'), isFalse);
    });

    test('persistCooldowns only saves non-expired entries', () async {
      final storage = _FakeStorage();
      final service = SkillCooldownService(storage: storage);

      // Start one expired-immediately and one still-active cooldown.
      service.startCooldown('gone', Duration.zero);
      service.startCooldown('active', const Duration(hours: 2));
      await service.persistCooldowns();

      final data = await storage.getJson('skillCooldownExpiry');
      expect(data, isNotNull);
      expect(data!.containsKey('active'), isTrue);
      expect(data.containsKey('gone'), isFalse);
    });

    test('restoreCooldowns is safe with empty storage', () async {
      final storage = _FakeStorage();
      final service = SkillCooldownService(storage: storage);
      await service.restoreCooldowns(); // should not throw
      expect(service.isOnCooldown('any'), isFalse);
    });
  });
}
