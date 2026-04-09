import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/models/challenge_models.dart';
import 'package:trivia_tycoon/game/services/challenge_service.dart';

void main() {
  setUp(() {
    // Always start each test with an empty cache.
    ChallengeService.clearCache();
  });

  tearDown(() {
    ChallengeService.clearCache();
  });

  // ---------------------------------------------------------------------------
  // getChallenges — correct type + content
  // ---------------------------------------------------------------------------

  group('ChallengeService.getChallenges returns correct type', () {
    test('daily bundle contains daily challenges', () {
      final bundle = ChallengeService.getChallenges(ChallengeType.daily);
      expect(bundle.challenges, isNotEmpty);
      for (final c in bundle.challenges) {
        expect(c.type, ChallengeType.daily);
      }
    });

    test('weekly bundle contains weekly challenges', () {
      final bundle = ChallengeService.getChallenges(ChallengeType.weekly);
      expect(bundle.challenges, isNotEmpty);
      for (final c in bundle.challenges) {
        expect(c.type, ChallengeType.weekly);
      }
    });

    test('special bundle contains special challenges', () {
      final bundle = ChallengeService.getChallenges(ChallengeType.special);
      expect(bundle.challenges, isNotEmpty);
      for (final c in bundle.challenges) {
        expect(c.type, ChallengeType.special);
      }
    });

    test('each challenge has a non-empty id', () {
      for (final type in ChallengeType.values) {
        final bundle = ChallengeService.getChallenges(type);
        for (final c in bundle.challenges) {
          expect(c.id, isNotEmpty);
        }
      }
    });
  });

  // ---------------------------------------------------------------------------
  // Refresh times
  // ---------------------------------------------------------------------------

  group('ChallengeService refresh times', () {
    test('daily refreshTime is ~12 hours from now', () {
      final bundle = ChallengeService.getChallenges(ChallengeType.daily);
      final diff = bundle.refreshTime.difference(DateTime.now());
      // Allow ±5 s tolerance for test execution time
      expect(diff.inSeconds, greaterThan(12 * 3600 - 5));
      expect(diff.inSeconds, lessThan(12 * 3600 + 5));
    });

    test('weekly refreshTime is ~3 days from now', () {
      final bundle = ChallengeService.getChallenges(ChallengeType.weekly);
      final diff = bundle.refreshTime.difference(DateTime.now());
      expect(diff.inSeconds, greaterThan(3 * 86400 - 5));
      expect(diff.inSeconds, lessThan(3 * 86400 + 5));
    });

    test('special refreshTime is ~40 hours from now', () {
      final bundle = ChallengeService.getChallenges(ChallengeType.special);
      final diff = bundle.refreshTime.difference(DateTime.now());
      expect(diff.inSeconds, greaterThan(40 * 3600 - 5));
      expect(diff.inSeconds, lessThan(40 * 3600 + 5));
    });
  });

  // ---------------------------------------------------------------------------
  // Caching
  // ---------------------------------------------------------------------------

  group('ChallengeService caching', () {
    test('returns identical object on second call (cache hit)', () {
      final first = ChallengeService.getChallenges(ChallengeType.daily);
      final second = ChallengeService.getChallenges(ChallengeType.daily);
      // Same list identity (cached)
      expect(identical(first.challenges, second.challenges), isTrue);
    });

    test('clearCache forces new object on next call', () {
      final first = ChallengeService.getChallenges(ChallengeType.daily);
      ChallengeService.clearCache();
      final second = ChallengeService.getChallenges(ChallengeType.daily);
      // After clear the lists are re-created — not identical
      expect(identical(first.challenges, second.challenges), isFalse);
    });

    test('cache is independent per ChallengeType', () {
      final daily = ChallengeService.getChallenges(ChallengeType.daily);
      final weekly = ChallengeService.getChallenges(ChallengeType.weekly);
      expect(daily.challenges.first.type, ChallengeType.daily);
      expect(weekly.challenges.first.type, ChallengeType.weekly);
    });
  });

  // ---------------------------------------------------------------------------
  // Challenge model properties
  // ---------------------------------------------------------------------------

  group('Challenge model properties', () {
    test('completed challenge has progress == 1.0', () {
      final bundle = ChallengeService.getChallenges(ChallengeType.daily);
      final completed = bundle.challenges.where((c) => c.completed).toList();
      for (final c in completed) {
        expect(c.progress, 1.0);
      }
    });

    test('incomplete challenge has progress < 1.0', () {
      final bundle = ChallengeService.getChallenges(ChallengeType.daily);
      final incomplete = bundle.challenges.where((c) => !c.completed).toList();
      for (final c in incomplete) {
        expect(c.progress, lessThan(1.0));
      }
    });

    test('all challenges have non-empty title and description', () {
      for (final type in ChallengeType.values) {
        final bundle = ChallengeService.getChallenges(type);
        for (final c in bundle.challenges) {
          expect(c.title, isNotEmpty);
          expect(c.description, isNotEmpty);
        }
      }
    });

    test('all challenges have non-empty rewardSummary', () {
      for (final type in ChallengeType.values) {
        final bundle = ChallengeService.getChallenges(type);
        for (final c in bundle.challenges) {
          expect(c.rewardSummary, isNotEmpty);
        }
      }
    });
  });

  // ---------------------------------------------------------------------------
  // updateProgress
  // ---------------------------------------------------------------------------

  group('ChallengeService.updateProgress', () {
    test('returns updated challenge with new progress', () async {
      final bundle = ChallengeService.getChallenges(ChallengeType.daily);
      final original = bundle.challenges.first;

      final updated = await ChallengeService.updateProgress(original, 0.75);

      expect(updated.progress, 0.75);
      expect(updated.id, original.id);
    });

    test('marks completed when progress reaches 1.0', () async {
      final bundle = ChallengeService.getChallenges(ChallengeType.daily);
      final original = bundle.challenges.first;

      final updated = await ChallengeService.updateProgress(original, 1.0);

      expect(updated.completed, isTrue);
      expect(updated.progress, 1.0);
    });

    test('does not mark completed when progress < 1.0', () async {
      final bundle = ChallengeService.getChallenges(ChallengeType.daily);
      final original = bundle.challenges.first;

      final updated = await ChallengeService.updateProgress(original, 0.5);

      expect(updated.completed, isFalse);
    });

    test('clears cache so next getChallenges regenerates', () async {
      final firstBundle = ChallengeService.getChallenges(ChallengeType.daily);
      final original = firstBundle.challenges.first;

      await ChallengeService.updateProgress(original, 0.8);

      // updateProgress calls clearCache internally
      final secondBundle = ChallengeService.getChallenges(ChallengeType.daily);
      expect(identical(firstBundle.challenges, secondBundle.challenges), isFalse);
    });
  });
}
