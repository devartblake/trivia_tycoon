import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/services/xp_service.dart';

void main() {
  group('XPService — core XP operations', () {
    late XPService svc;

    setUp(() => svc = XPService());

    test('starts at zero XP', () {
      expect(svc.playerXP, 0);
    });

    test('addXP increases XP by exact amount when no multiplier', () {
      svc.addXP(100);
      expect(svc.playerXP, 100);
    });

    test('addXP accumulates across multiple calls', () {
      svc.addXP(50);
      svc.addXP(75);
      expect(svc.playerXP, 125);
    });

    test('addXP applies active multiplier by default', () {
      svc.setBonusMultiplier(2.0, duration: const Duration(minutes: 10));
      svc.addXP(100);
      expect(svc.playerXP, 200);
    });

    test('addXP ignores multiplier when applyMultiplier is false', () {
      svc.setBonusMultiplier(3.0, duration: const Duration(minutes: 10));
      svc.addXP(100, applyMultiplier: false);
      expect(svc.playerXP, 100);
    });

    test('deductXP reduces XP correctly', () {
      svc.addXP(200);
      svc.deductXP(75);
      expect(svc.playerXP, 125);
    });

    test('deductXP clamps at zero, never goes negative', () {
      svc.addXP(10);
      svc.deductXP(9999);
      expect(svc.playerXP, 0);
    });

    test('hasEnoughXP returns true when XP is sufficient', () {
      svc.addXP(500);
      expect(svc.hasEnoughXP(500), isTrue);
      expect(svc.hasEnoughXP(499), isTrue);
    });

    test('hasEnoughXP returns false when XP is insufficient', () {
      svc.addXP(100);
      expect(svc.hasEnoughXP(101), isFalse);
    });

    test('resetXP clears XP and multiplier', () {
      svc.addXP(300);
      svc.setBonusMultiplier(2.0, duration: const Duration(minutes: 10));
      svc.resetXP();
      expect(svc.playerXP, 0);
      expect(svc.effectiveMultiplier, 1.0);
      expect(svc.isBoostActive, isFalse);
    });
  });

  group('XPService — XP boost / multiplier', () {
    late XPService svc;

    setUp(() => svc = XPService());

    test('boost is inactive by default', () {
      expect(svc.isBoostActive, isFalse);
      expect(svc.boostRemaining(), isNull);
    });

    test('setBonusMultiplier activates boost', () {
      svc.setBonusMultiplier(1.5, duration: const Duration(minutes: 5));
      expect(svc.isBoostActive, isTrue);
      expect(svc.effectiveMultiplier, 1.5);
      expect(svc.boostRemaining(), isNotNull);
    });

    test('applyTemporaryXPBoost activates boost', () {
      svc.applyTemporaryXPBoost(2.0, duration: const Duration(minutes: 15));
      expect(svc.isBoostActive, isTrue);
      expect(svc.effectiveMultiplier, 2.0);
    });

    test('applyTemporaryXPBoost clamps multiplier to [0.1, 100]', () {
      svc.applyTemporaryXPBoost(200.0);
      expect(svc.effectiveMultiplier, 100.0);

      svc.applyTemporaryXPBoost(-5.0);
      expect(svc.effectiveMultiplier, 0.1);
    });

    test('tick() expires a past boost', () {
      // Activate a boost that already expired
      svc.setBonusMultiplier(2.0, duration: const Duration(milliseconds: 1));
      // Wait for boost to expire
      Future.delayed(const Duration(milliseconds: 5), () {
        svc.tick();
        expect(svc.isBoostActive, isFalse);
        expect(svc.effectiveMultiplier, 1.0);
      });
    });
  });

  group('XPService — tier progression (XP thresholds)', () {
    test('can accumulate XP across tier boundaries', () {
      final svc = XPService();
      for (int i = 0; i < 10; i++) {
        svc.addXP(1000);
      }
      expect(svc.playerXP, 10000);
    });

    test('respects custom starting XP', () {
      final svc = XPService(startingPlayerXP: 500);
      expect(svc.playerXP, 500);
      svc.addXP(100);
      expect(svc.playerXP, 600);
    });
  });
}