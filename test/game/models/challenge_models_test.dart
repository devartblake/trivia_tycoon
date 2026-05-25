import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/models/challenge_models.dart';

Map<String, dynamic> _baseJson({
  String id = 'ch1',
  String type = 'daily',
  String title = 'Daily Grind',
  String description = 'Complete 5 quizzes',
  String rewardSummary = '100 coins',
  double progress = 0.0,
  bool completed = false,
}) =>
    {
      'id': id,
      'type': type,
      'title': title,
      'description': description,
      'rewardSummary': rewardSummary,
      'progress': progress,
      'completed': completed,
    };

void main() {
  // -------------------------------------------------------------------------
  // Challenge.fromJson — scalar fields
  // -------------------------------------------------------------------------

  group('Challenge.fromJson — scalar fields', () {
    test('parses id', () {
      expect(Challenge.fromJson(_baseJson(id: 'ch99')).id, 'ch99');
    });

    test('parses title', () {
      expect(
          Challenge.fromJson(_baseJson(title: 'Marathon')).title, 'Marathon');
    });

    test('parses description', () {
      expect(
          Challenge.fromJson(_baseJson(description: 'Play 10 games'))
              .description,
          'Play 10 games');
    });

    test('parses rewardSummary', () {
      expect(
          Challenge.fromJson(_baseJson(rewardSummary: '500 XP')).rewardSummary,
          '500 XP');
    });

    test('parses progress', () {
      expect(Challenge.fromJson(_baseJson(progress: 0.75)).progress, 0.75);
    });

    test('parses completed', () {
      expect(Challenge.fromJson(_baseJson(completed: true)).completed, isTrue);
    });

    test('icon defaults to flash_on_rounded', () {
      final ch = Challenge.fromJson(_baseJson());
      expect(ch.icon.codePoint, Icons.flash_on_rounded.codePoint);
    });
  });

  // -------------------------------------------------------------------------
  // Challenge.fromJson — ChallengeType
  // -------------------------------------------------------------------------

  group('Challenge.fromJson — ChallengeType', () {
    test('"daily" → ChallengeType.daily', () {
      expect(Challenge.fromJson(_baseJson(type: 'daily')).type,
          ChallengeType.daily);
    });

    test('"weekly" → ChallengeType.weekly', () {
      expect(Challenge.fromJson(_baseJson(type: 'weekly')).type,
          ChallengeType.weekly);
    });

    test('"special" → ChallengeType.special', () {
      expect(Challenge.fromJson(_baseJson(type: 'special')).type,
          ChallengeType.special);
    });
  });

  // -------------------------------------------------------------------------
  // Challenge.toJson
  // -------------------------------------------------------------------------

  group('Challenge.toJson', () {
    test('serializes type as name string', () {
      expect(Challenge.fromJson(_baseJson(type: 'weekly')).toJson()['type'],
          'weekly');
    });

    test('serializes progress', () {
      expect(Challenge.fromJson(_baseJson(progress: 0.5)).toJson()['progress'],
          0.5);
    });

    test('serializes completed', () {
      expect(
          Challenge.fromJson(_baseJson(completed: true)).toJson()['completed'],
          isTrue);
    });

    test('round-trip preserves type and progress', () {
      final original = Challenge.fromJson(
          _baseJson(type: 'special', progress: 0.33, completed: false));
      final restored = Challenge.fromJson(original.toJson());
      expect(restored.type, ChallengeType.special);
      expect(restored.progress, 0.33);
      expect(restored.completed, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // Challenge.copyWith
  // -------------------------------------------------------------------------

  group('Challenge.copyWith', () {
    late Challenge base;
    setUp(() => base = Challenge.fromJson(_baseJson()));

    test('copies progress', () {
      expect(base.copyWith(progress: 0.8).progress, 0.8);
    });

    test('copies completed', () {
      expect(base.copyWith(completed: true).completed, isTrue);
    });

    test('preserves unchanged fields on copyWith(progress)', () {
      final updated = base.copyWith(progress: 0.5);
      expect(updated.id, base.id);
      expect(updated.title, base.title);
      expect(updated.type, base.type);
    });
  });

  // -------------------------------------------------------------------------
  // ChallengeBundle
  // -------------------------------------------------------------------------

  group('ChallengeBundle', () {
    test('stores challenges list', () {
      final challenges = [
        Challenge.fromJson(_baseJson(id: 'ch1')),
        Challenge.fromJson(_baseJson(id: 'ch2', type: 'weekly')),
      ];
      final bundle = ChallengeBundle(
          challenges: challenges, refreshTime: DateTime(2025, 6, 1));
      expect(bundle.challenges.length, 2);
    });

    test('copyWith replaces challenges', () {
      final bundle = ChallengeBundle(
          challenges: [Challenge.fromJson(_baseJson())],
          refreshTime: DateTime(2025, 1, 1));
      final newChallenges = [Challenge.fromJson(_baseJson(id: 'new'))];
      expect(bundle.copyWith(challenges: newChallenges).challenges.first.id,
          'new');
    });

    test('copyWith replaces refreshTime', () {
      final bundle =
          ChallengeBundle(challenges: [], refreshTime: DateTime(2025, 1, 1));
      final newTime = DateTime(2026, 3, 15);
      expect(bundle.copyWith(refreshTime: newTime).refreshTime, newTime);
    });

    test('copyWith preserves unchanged fields', () {
      final original = [Challenge.fromJson(_baseJson())];
      final bundle = ChallengeBundle(
          challenges: original, refreshTime: DateTime(2025, 6, 1));
      final updated = bundle.copyWith(refreshTime: DateTime(2025, 7, 1));
      expect(updated.challenges, original);
    });
  });
}
