/// Phase 3 — Game flow integration tests.
///
/// Covers: answer submission (QuestionModel.isCorrectAnswer),
/// XP award on correct answers, streak tracking, and tier progression
/// via TierAssigner (pure leaderboard ranking function).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/models/question_model.dart';
import 'package:trivia_tycoon/game/services/xp_service.dart';
import 'package:trivia_tycoon/game/utils/tier_assigner.dart';
import 'package:trivia_tycoon/game/models/leaderboard_entry.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

QuestionModel _makeQuestion({
  String id = 'q1',
  String correct = 'Paris',
}) {
  return QuestionModel.fromJson({
    'id': id,
    'category': 'geography',
    'question': 'What is the capital of France?',
    'type': 'multiple_choice',
    'difficulty': 2,
    'correctAnswer': correct,
    'answers': [
      {'text': 'Paris', 'isCorrect': correct == 'Paris'},
      {'text': 'Berlin', 'isCorrect': correct == 'Berlin'},
      {'text': 'Madrid', 'isCorrect': false},
      {'text': 'Rome', 'isCorrect': false},
    ],
  });
}

LeaderboardEntry _makeEntry({
  required int userId,
  required int score,
}) {
  final now = DateTime(2026, 1, 1);
  return LeaderboardEntry(
    userId: userId,
    playerName: 'Player$userId',
    score: score,
    rank: 0,
    tier: 0,
    tierRank: 0,
    isPromotionEligible: false,
    isRewardEligible: false,
    wins: 0,
    country: 'US',
    state: 'CA',
    countryCode: 'US',
    level: 1,
    badges: '',
    xpProgress: 0,
    timeframe: 'global',
    avatar: '',
    lastActive: now,
    timestamp: now,
    gender: 'other',
    ageGroup: 'adults',
    joinedDate: now,
    streak: 0,
    accuracy: 0.5,
    favoriteCategory: 'science',
    title: 'Rookie',
    status: 'active',
    device: 'mobile',
    language: 'en',
    sessionLength: 0,
    lastQuestionCategory: 'science',
    interests: const [],
    emailVerified: true,
    accountStatus: 'active',
    timezone: 'UTC',
    powerUps: const [],
    lastDeviceType: 'mobile',
    preferredNotificationMethod: 'push',
    subscriptionStatus: 'free',
    averageAnswerTime: 5.0,
    isBot: false,
    accountAgeDays: 30,
    engagementScore: 0.5,
  );
}

// ---------------------------------------------------------------------------
// Answer submission tests
// ---------------------------------------------------------------------------

void main() {
  group('QuestionModel — answer submission', () {
    test('isCorrectAnswer returns true for matching answer', () {
      final q = _makeQuestion(correct: 'Paris');
      expect(q.isCorrectAnswer('Paris'), isTrue);
    });

    test('isCorrectAnswer returns false for wrong answer', () {
      final q = _makeQuestion(correct: 'Paris');
      expect(q.isCorrectAnswer('Berlin'), isFalse);
      expect(q.isCorrectAnswer('Madrid'), isFalse);
    });

    test('isCorrectAnswer is case-sensitive', () {
      final q = _makeQuestion(correct: 'Paris');
      expect(q.isCorrectAnswer('paris'), isFalse);
      expect(q.isCorrectAnswer('PARIS'), isFalse);
    });

    test('isCorrectAnswer handles empty string gracefully', () {
      final q = _makeQuestion(correct: 'Paris');
      expect(q.isCorrectAnswer(''), isFalse);
    });
  });

  group('Game flow — XP award on answer submission', () {
    const xpPerCorrectAnswer = 10;

    test('correct answer awards XP and increments streak', () {
      final xp = XPService();
      final q = _makeQuestion(correct: 'Paris');
      int streak = 0;

      if (q.isCorrectAnswer('Paris')) {
        xp.addXP(xpPerCorrectAnswer);
        streak++;
      }

      expect(xp.playerXP, xpPerCorrectAnswer);
      expect(streak, 1);
    });

    test('wrong answer awards no XP and resets streak', () {
      final xp = XPService();
      final q = _makeQuestion(correct: 'Paris');
      int streak = 3; // player had a streak going

      if (!q.isCorrectAnswer('Berlin')) {
        streak = 0;
      }

      expect(xp.playerXP, 0);
      expect(streak, 0);
    });

    test('simulated 5-question round: 3 correct, 2 wrong', () {
      final xp = XPService();
      final questions = [
        _makeQuestion(id: 'q1', correct: 'Paris'),
        _makeQuestion(id: 'q2', correct: 'London'),
        _makeQuestion(id: 'q3', correct: 'Berlin'),
        _makeQuestion(id: 'q4', correct: 'Rome'),
        _makeQuestion(id: 'q5', correct: 'Tokyo'),
      ];

      final playerAnswers = ['Paris', 'WRONG', 'Berlin', 'WRONG', 'Tokyo'];
      int score = 0;
      int streak = 0;

      for (int i = 0; i < questions.length; i++) {
        if (questions[i].isCorrectAnswer(playerAnswers[i])) {
          score += xpPerCorrectAnswer;
          xp.addXP(xpPerCorrectAnswer);
          streak++;
        } else {
          streak = 0;
        }
      }

      expect(score, 30); // 3 correct × 10 XP
      expect(xp.playerXP, 30);
      expect(streak, 1); // ended on 'Tokyo' which was correct
    });

    test('XP multiplier doubles reward for boosted session', () {
      final xp = XPService();
      xp.applyTemporaryXPBoost(2.0, duration: const Duration(minutes: 5));
      final q = _makeQuestion(correct: 'Paris');

      if (q.isCorrectAnswer('Paris')) {
        xp.addXP(xpPerCorrectAnswer);
      }

      expect(xp.playerXP, xpPerCorrectAnswer * 2);
    });
  });

  group('TierAssigner — tier progression', () {
    test('sorts entries by score descending', () {
      final entries = [
        _makeEntry(userId: 1, score: 100),
        _makeEntry(userId: 2, score: 500),
        _makeEntry(userId: 3, score: 250),
      ];

      final result = TierAssigner.assignTiers(entries);

      expect(result[0].userId, 2); // highest score first
      expect(result[1].userId, 3);
      expect(result[2].userId, 1);
    });

    test('assigns rank 1 to highest scorer', () {
      final entries = [
        _makeEntry(userId: 1, score: 1000),
        _makeEntry(userId: 2, score: 200),
      ];

      final result = TierAssigner.assignTiers(entries);
      expect(result.first.rank, 1);
      expect(result.last.rank, 2);
    });

    test('tierRank cycles within 1–100 per tier', () {
      // Create 150 entries to span two tier groups
      final entries = List.generate(
        150,
        (i) => _makeEntry(userId: i + 1, score: 150 - i),
      );

      final result = TierAssigner.assignTiers(entries);

      // First 100 entries: tierRank 1..100
      for (int i = 0; i < 100; i++) {
        expect(result[i].tierRank, i + 1);
      }
      // Next 50 entries: tierRank starts over from 1
      for (int i = 100; i < 150; i++) {
        expect(result[i].tierRank, i - 100 + 1);
      }
    });

    test('promotion eligibility: top 25 in tier are eligible', () {
      final entries = List.generate(
        50,
        (i) => _makeEntry(userId: i + 1, score: 50 - i),
      );

      final result = TierAssigner.assignTiers(entries);

      for (int i = 0; i < 25; i++) {
        expect(result[i].isPromotionEligible, isTrue,
            reason: 'rank ${i + 1} should be promotion-eligible');
      }
      for (int i = 25; i < 50; i++) {
        expect(result[i].isPromotionEligible, isFalse,
            reason: 'rank ${i + 1} should not be promotion-eligible');
      }
    });

    test('reward eligibility: top 20 in tier are eligible', () {
      final entries = List.generate(
        30,
        (i) => _makeEntry(userId: i + 1, score: 30 - i),
      );

      final result = TierAssigner.assignTiers(entries);

      for (int i = 0; i < 20; i++) {
        expect(result[i].isRewardEligible, isTrue);
      }
      for (int i = 20; i < 30; i++) {
        expect(result[i].isRewardEligible, isFalse);
      }
    });

    test('entries beyond rank 1000 are assigned tier 0', () {
      final entries = List.generate(
        1001,
        (i) => _makeEntry(userId: i + 1, score: 1001 - i),
      );

      final result = TierAssigner.assignTiers(entries);

      // Last entry (rank 1001) should be tier 0
      expect(result.last.rank, 1001);
      expect(result.last.tier, 0);
    });

    test('empty list returns empty list', () {
      expect(TierAssigner.assignTiers([]), isEmpty);
    });

    test('single entry gets rank 1, tier > 0', () {
      final result = TierAssigner.assignTiers([
        _makeEntry(userId: 1, score: 500),
      ]);
      expect(result.length, 1);
      expect(result.first.rank, 1);
      expect(result.first.tier, greaterThan(0));
      expect(result.first.tierRank, 1);
    });
  });
}
