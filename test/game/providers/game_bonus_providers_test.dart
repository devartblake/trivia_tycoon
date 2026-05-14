import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/providers/game_bonus_providers.dart';

ProviderContainer _container() {
  final c = ProviderContainer();
  addTearDown(c.dispose);
  return c;
}

void main() {
  // -------------------------------------------------------------------------
  // Int providers — initial value 0
  // -------------------------------------------------------------------------

  group('pendingTimerBonusProvider', () {
    test('initial value is 0', () {
      expect(_container().read(pendingTimerBonusProvider), 0);
    });

    test('can be mutated to positive value', () {
      final c = _container();
      c.read(pendingTimerBonusProvider.notifier).state = 30;
      expect(c.read(pendingTimerBonusProvider), 30);
    });
  });

  group('streakCountProvider', () {
    test('initial value is 0', () {
      expect(_container().read(streakCountProvider), 0);
    });

    test('mutation increments correctly', () {
      final c = _container();
      c.read(streakCountProvider.notifier).state = 5;
      expect(c.read(streakCountProvider), 5);
    });
  });

  group('streakShieldProvider', () {
    test('initial value is 0', () {
      expect(_container().read(streakShieldProvider), 0);
    });

    test('can be set to non-zero', () {
      final c = _container();
      c.read(streakShieldProvider.notifier).state = 2;
      expect(c.read(streakShieldProvider), 2);
    });
  });

  group('hintSpeedBonusProvider', () {
    test('initial value is 0', () {
      expect(_container().read(hintSpeedBonusProvider), 0);
    });

    test('mutation stores value', () {
      final c = _container();
      c.read(hintSpeedBonusProvider.notifier).state = 10;
      expect(c.read(hintSpeedBonusProvider), 10);
    });
  });

  group('periodicChaosIntervalProvider', () {
    test('initial value is 0 (disabled)', () {
      expect(_container().read(periodicChaosIntervalProvider), 0);
    });

    test('setting to N enables chaos every N questions', () {
      final c = _container();
      c.read(periodicChaosIntervalProvider.notifier).state = 5;
      expect(c.read(periodicChaosIntervalProvider), 5);
    });
  });

  // -------------------------------------------------------------------------
  // Double providers
  // -------------------------------------------------------------------------

  group('streakMultiplierProvider', () {
    test('initial value is 1.0', () {
      expect(_container().read(streakMultiplierProvider), 1.0);
    });

    test('can be set to higher multiplier', () {
      final c = _container();
      c.read(streakMultiplierProvider.notifier).state = 1.5;
      expect(c.read(streakMultiplierProvider), 1.5);
    });
  });

  group('scoreBonusMultiplierProvider', () {
    test('initial value is 1.0', () {
      expect(_container().read(scoreBonusMultiplierProvider), 1.0);
    });

    test('mutation updates value', () {
      final c = _container();
      c.read(scoreBonusMultiplierProvider.notifier).state = 2.0;
      expect(c.read(scoreBonusMultiplierProvider), 2.0);
    });
  });

  group('accuracyBonusProvider', () {
    test('initial value is 0.0', () {
      expect(_container().read(accuracyBonusProvider), 0.0);
    });

    test('mutation stores bonus rate', () {
      final c = _container();
      c.read(accuracyBonusProvider.notifier).state = 0.05;
      expect(c.read(accuracyBonusProvider), 0.05);
    });
  });

  group('autoCorrectChanceProvider', () {
    test('initial value is 0.0', () {
      expect(_container().read(autoCorrectChanceProvider), 0.0);
    });

    test('can be set to max 0.95', () {
      final c = _container();
      c.read(autoCorrectChanceProvider.notifier).state = 0.95;
      expect(c.read(autoCorrectChanceProvider), 0.95);
    });
  });

  group('speedBonusMultiplierProvider', () {
    test('initial value is 1.0', () {
      expect(_container().read(speedBonusMultiplierProvider), 1.0);
    });

    test('mutation stores speed bonus', () {
      final c = _container();
      c.read(speedBonusMultiplierProvider.notifier).state = 1.25;
      expect(c.read(speedBonusMultiplierProvider), 1.25);
    });
  });

  // -------------------------------------------------------------------------
  // Bool providers — initial value false
  // -------------------------------------------------------------------------

  group('eliteAccessUnlockedProvider', () {
    test('initial value is false', () {
      expect(_container().read(eliteAccessUnlockedProvider), isFalse);
    });

    test('can be unlocked', () {
      final c = _container();
      c.read(eliteAccessUnlockedProvider.notifier).state = true;
      expect(c.read(eliteAccessUnlockedProvider), isTrue);
    });
  });

  group('timerFrozenProvider', () {
    test('initial value is false', () {
      expect(_container().read(timerFrozenProvider), isFalse);
    });

    test('can be frozen', () {
      final c = _container();
      c.read(timerFrozenProvider.notifier).state = true;
      expect(c.read(timerFrozenProvider), isTrue);
    });
  });

  group('selectableCategoryProvider', () {
    test('initial value is false', () {
      expect(_container().read(selectableCategoryProvider), isFalse);
    });

    test('enabling allows category selection', () {
      final c = _container();
      c.read(selectableCategoryProvider.notifier).state = true;
      expect(c.read(selectableCategoryProvider), isTrue);
    });
  });

  group('masterKnowledgeUnlockedProvider', () {
    test('initial value is false', () {
      expect(_container().read(masterKnowledgeUnlockedProvider), isFalse);
    });

    test('can be unlocked', () {
      final c = _container();
      c.read(masterKnowledgeUnlockedProvider.notifier).state = true;
      expect(c.read(masterKnowledgeUnlockedProvider), isTrue);
    });
  });

  group('masterTacticsUnlockedProvider', () {
    test('initial value is false', () {
      expect(_container().read(masterTacticsUnlockedProvider), isFalse);
    });

    test('mutation isolated from masterKnowledgeUnlockedProvider', () {
      final c = _container();
      c.read(masterTacticsUnlockedProvider.notifier).state = true;
      expect(c.read(masterTacticsUnlockedProvider), isTrue);
      expect(c.read(masterKnowledgeUnlockedProvider), isFalse);
    });
  });

  group('pendingEliminateOneProvider', () {
    test('initial value is false', () {
      expect(_container().read(pendingEliminateOneProvider), isFalse);
    });

    test('setting true enables eliminate-one power', () {
      final c = _container();
      c.read(pendingEliminateOneProvider.notifier).state = true;
      expect(c.read(pendingEliminateOneProvider), isTrue);
    });
  });

  group('pendingEliminateHalfProvider', () {
    test('initial value is false', () {
      expect(_container().read(pendingEliminateHalfProvider), isFalse);
    });

    test('setting true does not affect eliminateOne', () {
      final c = _container();
      c.read(pendingEliminateHalfProvider.notifier).state = true;
      expect(c.read(pendingEliminateHalfProvider), isTrue);
      expect(c.read(pendingEliminateOneProvider), isFalse);
    });
  });

  group('pendingShowHintProvider', () {
    test('initial value is false', () {
      expect(_container().read(pendingShowHintProvider), isFalse);
    });

    test('mutation stores true', () {
      final c = _container();
      c.read(pendingShowHintProvider.notifier).state = true;
      expect(c.read(pendingShowHintProvider), isTrue);
    });
  });

  group('pendingRetryProvider', () {
    test('initial value is false', () {
      expect(_container().read(pendingRetryProvider), isFalse);
    });

    test('consumed by setting back to false', () {
      final c = _container();
      c.read(pendingRetryProvider.notifier).state = true;
      expect(c.read(pendingRetryProvider), isTrue);
      c.read(pendingRetryProvider.notifier).state = false;
      expect(c.read(pendingRetryProvider), isFalse);
    });
  });

  group('doubleOrNothingProvider', () {
    test('initial value is false', () {
      expect(_container().read(doubleOrNothingProvider), isFalse);
    });

    test('can be activated', () {
      final c = _container();
      c.read(doubleOrNothingProvider.notifier).state = true;
      expect(c.read(doubleOrNothingProvider), isTrue);
    });
  });

  group('fakeScoreActiveProvider', () {
    test('initial value is false', () {
      expect(_container().read(fakeScoreActiveProvider), isFalse);
    });

    test('mutation stores true', () {
      final c = _container();
      c.read(fakeScoreActiveProvider.notifier).state = true;
      expect(c.read(fakeScoreActiveProvider), isTrue);
    });
  });

  group('hideProgressActiveProvider', () {
    test('initial value is false', () {
      expect(_container().read(hideProgressActiveProvider), isFalse);
    });

    test('can be activated independently', () {
      final c = _container();
      c.read(hideProgressActiveProvider.notifier).state = true;
      expect(c.read(hideProgressActiveProvider), isTrue);
      expect(c.read(fakeScoreActiveProvider), isFalse);
    });
  });

  group('glitchScreensActiveProvider', () {
    test('initial value is false', () {
      expect(_container().read(glitchScreensActiveProvider), isFalse);
    });

    test('can be activated', () {
      final c = _container();
      c.read(glitchScreensActiveProvider.notifier).state = true;
      expect(c.read(glitchScreensActiveProvider), isTrue);
    });
  });

  group('randomBenefitActiveProvider', () {
    test('initial value is false', () {
      expect(_container().read(randomBenefitActiveProvider), isFalse);
    });

    test('mutation stores true', () {
      final c = _container();
      c.read(randomBenefitActiveProvider.notifier).state = true;
      expect(c.read(randomBenefitActiveProvider), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // Nullable / complex providers
  // -------------------------------------------------------------------------

  group('categoryBonusProvider', () {
    test('initial value is null', () {
      expect(_container().read(categoryBonusProvider), isNull);
    });

    test('can hold a category+bonus map', () {
      final c = _container();
      c.read(categoryBonusProvider.notifier).state = {
        'category': 'science',
        'bonus': 0.15,
      };
      final bonus = c.read(categoryBonusProvider);
      expect(bonus, isNotNull);
      expect(bonus!['category'], 'science');
      expect(bonus['bonus'], 0.15);
    });

    test('can be cleared back to null', () {
      final c = _container();
      c.read(categoryBonusProvider.notifier).state = {'category': 'math', 'bonus': 0.1};
      c.read(categoryBonusProvider.notifier).state = null;
      expect(c.read(categoryBonusProvider), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // Provider isolation — mutations in one container do not affect another
  // -------------------------------------------------------------------------

  group('container isolation', () {
    test('each container has independent state', () {
      final c1 = _container();
      final c2 = _container();

      c1.read(streakMultiplierProvider.notifier).state = 2.0;

      expect(c1.read(streakMultiplierProvider), 2.0);
      expect(c2.read(streakMultiplierProvider), 1.0);
    });

    test('resetting one bool provider does not affect another', () {
      final c = _container();
      c.read(timerFrozenProvider.notifier).state = true;
      c.read(pendingRetryProvider.notifier).state = true;

      c.read(timerFrozenProvider.notifier).state = false;

      expect(c.read(timerFrozenProvider), isFalse);
      expect(c.read(pendingRetryProvider), isTrue);
    });
  });
}
