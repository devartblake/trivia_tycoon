import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/controllers/power_up_controller.dart';
import 'package:trivia_tycoon/game/models/power_up.dart';
import 'package:trivia_tycoon/game/providers/core_providers.dart';
import 'package:trivia_tycoon/game/providers/ui_state_providers.dart';
import 'package:trivia_tycoon/core/services/settings/general_key_value_storage_service.dart';

// ---------------------------------------------------------------------------
// Fake storage (in-memory; no Hive required)
// ---------------------------------------------------------------------------

class _FakeStorage extends GeneralKeyValueStorageService {
  final Map<String, dynamic> _store = {};

  @override
  Future<String?> getString(String key) async {
    final v = _store[key];
    return v is String ? v : null;
  }

  @override
  Future<void> setString(String key, String value) async => _store[key] = value;

  @override
  Future<void> remove(String key) async => _store.remove(key);

  @override
  Future<dynamic> get(String key) async => _store[key];

  @override
  Future<int> getInt(String key) async {
    final v = _store[key];
    return v is int ? v : 0;
  }

  @override
  Future<void> setInt(String key, int value) async => _store[key] = value;

  @override
  Future<bool?> getBool(String key) async {
    final v = _store[key];
    return v is bool ? v : null;
  }

  @override
  Future<void> setBool(String key, bool value) async => _store[key] = value;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

PowerUp _makePowerUp({
  String id = 'xp_boost',
  int duration = 300, // 5 min
}) =>
    PowerUp(
      id: id,
      name: 'XP Boost',
      description: 'Doubles XP for a while',
      iconPath: 'assets/icons/xp.png',
      duration: duration,
      price: 100,
      currency: 'coins',
      type: 'xp',
    );

ProviderContainer _buildContainer(_FakeStorage storage) {
  final container = ProviderContainer(
    overrides: [
      generalKeyValueStorageProvider.overrideWithValue(storage),
    ],
  );
  return container;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('PowerUpController.activate', () {
    test('sets state to the activated power-up', () async {
      final storage = _FakeStorage();
      final container = _buildContainer(storage);
      addTearDown(container.dispose);

      final notifier =
          container.read(equippedPowerUpProvider.notifier);
      final pu = _makePowerUp();

      await notifier.activate(pu);

      expect(container.read(equippedPowerUpProvider)?.id, pu.id);
    });

    test('persists id and timestamp to storage', () async {
      final storage = _FakeStorage();
      final container = _buildContainer(storage);
      addTearDown(container.dispose);

      final notifier = container.read(equippedPowerUpProvider.notifier);
      final pu = _makePowerUp();

      final before = DateTime.now();
      await notifier.activate(pu);
      final after = DateTime.now();

      expect(await storage.getString('equipped_power_up'), pu.id);

      final raw = await storage.getString('active_power_up_timestamp');
      expect(raw, isNotNull);
      final ts = DateTime.parse(raw!);
      expect(ts.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
      expect(ts.isBefore(after.add(const Duration(seconds: 1))), isTrue);
    });
  });

  group('PowerUpController.clearEquippedPowerUp', () {
    test('sets state to null', () async {
      final storage = _FakeStorage();
      final container = _buildContainer(storage);
      addTearDown(container.dispose);

      final notifier = container.read(equippedPowerUpProvider.notifier);
      await notifier.activate(_makePowerUp());

      await notifier.clearEquippedPowerUp();

      expect(container.read(equippedPowerUpProvider), isNull);
    });

    test('removes keys from storage', () async {
      final storage = _FakeStorage();
      final container = _buildContainer(storage);
      addTearDown(container.dispose);

      final notifier = container.read(equippedPowerUpProvider.notifier);
      await notifier.activate(_makePowerUp());
      await notifier.clearEquippedPowerUp();

      expect(await storage.getString('equipped_power_up'), isNull);
      expect(await storage.getString('active_power_up_timestamp'), isNull);
    });
  });

  group('PowerUpController.usePowerUp', () {
    test('returns true and equips when no power-up is active', () async {
      final storage = _FakeStorage();
      final container = _buildContainer(storage);
      addTearDown(container.dispose);

      final notifier = container.read(equippedPowerUpProvider.notifier);
      final pu = _makePowerUp();

      final result = await notifier.usePowerUp(pu);

      expect(result, isTrue);
      expect(container.read(equippedPowerUpProvider)?.id, pu.id);
    });

    test('returns false when same power-up is already active', () async {
      final storage = _FakeStorage();
      final container = _buildContainer(storage);
      addTearDown(container.dispose);

      final notifier = container.read(equippedPowerUpProvider.notifier);
      final pu = _makePowerUp();

      await notifier.activate(pu);
      final result = await notifier.usePowerUp(pu);

      expect(result, isFalse);
    });

    test('replaces with a different power-up and returns true', () async {
      final storage = _FakeStorage();
      final container = _buildContainer(storage);
      addTearDown(container.dispose);

      final notifier = container.read(equippedPowerUpProvider.notifier);
      await notifier.activate(_makePowerUp(id: 'shield'));

      final newPu = _makePowerUp(id: 'hint');
      final result = await notifier.usePowerUp(newPu);

      expect(result, isTrue);
      expect(container.read(equippedPowerUpProvider)?.id, 'hint');
    });
  });

  group('PowerUpController.isEquipped', () {
    test('returns true when the power-up is equipped', () async {
      final storage = _FakeStorage();
      final container = _buildContainer(storage);
      addTearDown(container.dispose);

      final notifier = container.read(equippedPowerUpProvider.notifier);
      await notifier.activate(_makePowerUp(id: 'xp_boost'));

      expect(notifier.isEquipped('xp_boost'), isTrue);
      expect(notifier.isEquipped('shield'), isFalse);
    });

    test('returns false when nothing is equipped', () async {
      final storage = _FakeStorage();
      final container = _buildContainer(storage);
      addTearDown(container.dispose);

      final notifier = container.read(equippedPowerUpProvider.notifier);
      expect(notifier.isEquipped('xp_boost'), isFalse);
    });
  });

  group('PowerUpController.isExpired', () {
    test('returns true when no power-up is active', () async {
      final storage = _FakeStorage();
      final container = _buildContainer(storage);
      addTearDown(container.dispose);

      final notifier = container.read(equippedPowerUpProvider.notifier);
      expect(await notifier.isExpired(), isTrue);
    });

    test('returns false immediately after activation (duration > 0)', () async {
      final storage = _FakeStorage();
      final container = _buildContainer(storage);
      addTearDown(container.dispose);

      final notifier = container.read(equippedPowerUpProvider.notifier);
      await notifier.activate(_makePowerUp(duration: 300));

      expect(await notifier.isExpired(), isFalse);
    });

    test('returns true when timestamp is in the past beyond duration', () async {
      final storage = _FakeStorage();
      // Manually seed an old timestamp (1 hour ago) with a 60s duration
      final old =
          DateTime.now().subtract(const Duration(hours: 1)).toIso8601String();
      storage._store['equipped_power_up'] = 'xp_boost';
      storage._store['active_power_up_timestamp'] = old;

      final container = _buildContainer(storage);
      addTearDown(container.dispose);

      // Restore the power-up into state
      final notifier = container.read(equippedPowerUpProvider.notifier);
      await notifier.restoreFromStorage([_makePowerUp(id: 'xp_boost', duration: 60)]);

      // After restore, state should be null (expired) and isExpired returns true
      expect(container.read(equippedPowerUpProvider), isNull);
      expect(await notifier.isExpired(), isTrue);
    });
  });

  group('PowerUpController.getRemainingTime', () {
    test('returns zero when nothing is equipped', () async {
      final storage = _FakeStorage();
      final container = _buildContainer(storage);
      addTearDown(container.dispose);

      final notifier = container.read(equippedPowerUpProvider.notifier);
      expect(await notifier.getRemainingTime(), Duration.zero);
    });

    test('returns positive duration immediately after activation', () async {
      final storage = _FakeStorage();
      final container = _buildContainer(storage);
      addTearDown(container.dispose);

      final notifier = container.read(equippedPowerUpProvider.notifier);
      await notifier.activate(_makePowerUp(duration: 300));

      final remaining = await notifier.getRemainingTime();
      expect(remaining.inSeconds, greaterThan(290));
      expect(remaining.inSeconds, lessThanOrEqualTo(300));
    });
  });

  group('PowerUpController.restoreFromStorage', () {
    test('restores valid unexpired power-up from storage', () async {
      final storage = _FakeStorage();
      final recentTs = DateTime.now()
          .subtract(const Duration(seconds: 10))
          .toIso8601String();
      storage._store['equipped_power_up'] = 'xp_boost';
      storage._store['active_power_up_timestamp'] = recentTs;

      final container = _buildContainer(storage);
      addTearDown(container.dispose);

      final notifier = container.read(equippedPowerUpProvider.notifier);
      await notifier.restoreFromStorage([_makePowerUp(id: 'xp_boost', duration: 300)]);

      expect(container.read(equippedPowerUpProvider)?.id, 'xp_boost');
    });

    test('clears state when stored power-up is expired', () async {
      final storage = _FakeStorage();
      final oldTs =
          DateTime.now().subtract(const Duration(hours: 2)).toIso8601String();
      storage._store['equipped_power_up'] = 'xp_boost';
      storage._store['active_power_up_timestamp'] = oldTs;

      final container = _buildContainer(storage);
      addTearDown(container.dispose);

      final notifier = container.read(equippedPowerUpProvider.notifier);
      await notifier.restoreFromStorage([_makePowerUp(id: 'xp_boost', duration: 60)]);

      expect(container.read(equippedPowerUpProvider), isNull);
    });

    test('clears state when stored id has no matching power-up', () async {
      final storage = _FakeStorage();
      storage._store['equipped_power_up'] = 'unknown_id';
      storage._store['active_power_up_timestamp'] =
          DateTime.now().toIso8601String();

      final container = _buildContainer(storage);
      addTearDown(container.dispose);

      final notifier = container.read(equippedPowerUpProvider.notifier);
      await notifier.restoreFromStorage([_makePowerUp(id: 'xp_boost')]);

      expect(container.read(equippedPowerUpProvider), isNull);
    });

    test('clears state when storage is empty', () async {
      final storage = _FakeStorage();
      final container = _buildContainer(storage);
      addTearDown(container.dispose);

      final notifier = container.read(equippedPowerUpProvider.notifier);
      await notifier.restoreFromStorage([_makePowerUp()]);

      expect(container.read(equippedPowerUpProvider), isNull);
    });
  });

  group('PowerUpController.equipById', () {
    test('equips matching power-up', () async {
      final storage = _FakeStorage();
      final container = _buildContainer(storage);
      addTearDown(container.dispose);

      final notifier = container.read(equippedPowerUpProvider.notifier);
      final available = [
        _makePowerUp(id: 'shield'),
        _makePowerUp(id: 'xp_boost'),
      ];

      await notifier.equipById('shield', available);

      expect(container.read(equippedPowerUpProvider)?.id, 'shield');
    });

    test('does nothing when id is not in available list', () async {
      final storage = _FakeStorage();
      final container = _buildContainer(storage);
      addTearDown(container.dispose);

      final notifier = container.read(equippedPowerUpProvider.notifier);

      await notifier.equipById('nonexistent', [_makePowerUp(id: 'shield')]);

      expect(container.read(equippedPowerUpProvider), isNull);
    });
  });

  group('PowerUpController.checkAndClearIfExpired', () {
    test('clears an expired power-up', () async {
      final storage = _FakeStorage();
      final oldTs =
          DateTime.now().subtract(const Duration(hours: 1)).toIso8601String();
      storage._store['equipped_power_up'] = 'xp_boost';
      storage._store['active_power_up_timestamp'] = oldTs;

      final container = _buildContainer(storage);
      addTearDown(container.dispose);

      final notifier = container.read(equippedPowerUpProvider.notifier);
      // Manually set state (simulate it was restored but is expired)
      await notifier.activate(_makePowerUp(id: 'xp_boost', duration: 1));
      // Overwrite timestamp with old value to force expiry
      await storage.setString('active_power_up_timestamp', oldTs);

      await notifier.checkAndClearIfExpired();

      expect(container.read(equippedPowerUpProvider), isNull);
    });

    test('keeps a still-valid power-up', () async {
      final storage = _FakeStorage();
      final container = _buildContainer(storage);
      addTearDown(container.dispose);

      final notifier = container.read(equippedPowerUpProvider.notifier);
      await notifier.activate(_makePowerUp(duration: 300));

      await notifier.checkAndClearIfExpired();

      expect(container.read(equippedPowerUpProvider), isNotNull);
    });
  });

  group('PowerUpController.loadEquipped', () {
    test('loads power-up by id from storage without timestamp check', () async {
      final storage = _FakeStorage();
      storage._store['equipped_power_up'] = 'shield';

      final container = _buildContainer(storage);
      addTearDown(container.dispose);

      final notifier = container.read(equippedPowerUpProvider.notifier);
      await notifier.loadEquipped([
        _makePowerUp(id: 'shield'),
        _makePowerUp(id: 'xp_boost'),
      ]);

      expect(container.read(equippedPowerUpProvider)?.id, 'shield');
    });

    test('does nothing when stored id is absent', () async {
      final storage = _FakeStorage();
      final container = _buildContainer(storage);
      addTearDown(container.dispose);

      final notifier = container.read(equippedPowerUpProvider.notifier);
      await notifier.loadEquipped([_makePowerUp(id: 'shield')]);

      expect(container.read(equippedPowerUpProvider), isNull);
    });
  });
}
