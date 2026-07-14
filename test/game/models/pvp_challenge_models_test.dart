import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/game/models/pvp_challenge_models.dart';

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

Map<String, dynamic> _challengeJson({
  String id = 'ch1',
  String challengerId = 'uid_a',
  String challengerName = 'Alice',
  String opponentId = 'uid_b',
  String opponentName = 'Bob',
  String category = 'science',
  int questionCount = 10,
  String difficulty = 'medium',
  int wager = 0,
  String status = 'pending',
  String createdAt = '2025-03-01T08:00:00.000Z',
  String? acceptedAt,
  String? completedAt,
  String expiresAt = '2025-03-02T08:00:00.000Z',
  String? challengerScore,
  String? opponentScore,
  String? winnerId,
}) {
  return {
    'id': id,
    'challengerId': challengerId,
    'challengerName': challengerName,
    'opponentId': opponentId,
    'opponentName': opponentName,
    'category': category,
    'questionCount': questionCount,
    'difficulty': difficulty,
    'wager': wager,
    'status': status,
    'createdAt': createdAt,
    if (acceptedAt != null) 'acceptedAt': acceptedAt,
    if (completedAt != null) 'completedAt': completedAt,
    'expiresAt': expiresAt,
    if (challengerScore != null) 'challengerScore': challengerScore,
    if (opponentScore != null) 'opponentScore': opponentScore,
    if (winnerId != null) 'winnerId': winnerId,
  };
}

PVPChallenge _challenge({
  String id = 'ch1',
  String challengerId = 'uid_a',
  String challengerName = 'Alice',
  String opponentId = 'uid_b',
  String opponentName = 'Bob',
  String category = 'science',
  int questionCount = 10,
  String difficulty = 'medium',
  int wager = 0,
  PVPChallengeStatus status = PVPChallengeStatus.pending,
  DateTime? createdAt,
  DateTime? expiresAt,
  String? winnerId,
}) {
  return PVPChallenge(
    id: id,
    challengerId: challengerId,
    challengerName: challengerName,
    opponentId: opponentId,
    opponentName: opponentName,
    category: category,
    questionCount: questionCount,
    difficulty: difficulty,
    wager: wager,
    status: status,
    createdAt: createdAt ?? DateTime(2025, 3, 1),
    expiresAt: expiresAt ?? DateTime(2025, 3, 2),
    winnerId: winnerId,
  );
}

void main() {
  // -------------------------------------------------------------------------
  // PVPChallengeStatus — displayName
  // -------------------------------------------------------------------------

  group('PVPChallengeStatus — displayName', () {
    test('pending → "Pending"', () {
      expect(PVPChallengeStatus.pending.displayName, 'Pending');
    });

    test('accepted → "Accepted"', () {
      expect(PVPChallengeStatus.accepted.displayName, 'Accepted');
    });

    test('declined → "Declined"', () {
      expect(PVPChallengeStatus.declined.displayName, 'Declined');
    });

    test('expired → "Expired"', () {
      expect(PVPChallengeStatus.expired.displayName, 'Expired');
    });

    test('completed → "Completed"', () {
      expect(PVPChallengeStatus.completed.displayName, 'Completed');
    });

    test('cancelled → "Cancelled"', () {
      expect(PVPChallengeStatus.cancelled.displayName, 'Cancelled');
    });
  });

  group('PVPChallengeStatus — isActive', () {
    test('true only for accepted', () {
      expect(PVPChallengeStatus.accepted.isActive, isTrue);
      for (final s in PVPChallengeStatus.values) {
        if (s != PVPChallengeStatus.accepted) {
          expect(s.isActive, isFalse, reason: '${s.name} should not be active');
        }
      }
    });
  });

  group('PVPChallengeStatus — isPending', () {
    test('true only for pending', () {
      expect(PVPChallengeStatus.pending.isPending, isTrue);
      for (final s in PVPChallengeStatus.values) {
        if (s != PVPChallengeStatus.pending) {
          expect(s.isPending, isFalse);
        }
      }
    });
  });

  group('PVPChallengeStatus — isFinished', () {
    test('true for completed, declined, expired, cancelled', () {
      expect(PVPChallengeStatus.completed.isFinished, isTrue);
      expect(PVPChallengeStatus.declined.isFinished, isTrue);
      expect(PVPChallengeStatus.expired.isFinished, isTrue);
      expect(PVPChallengeStatus.cancelled.isFinished, isTrue);
    });

    test('false for pending and accepted', () {
      expect(PVPChallengeStatus.pending.isFinished, isFalse);
      expect(PVPChallengeStatus.accepted.isFinished, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // PVPChallenge.fromJson
  // -------------------------------------------------------------------------

  group('PVPChallenge.fromJson — scalar fields', () {
    test('parses id', () {
      expect(PVPChallenge.fromJson(_challengeJson(id: 'ch99')).id, 'ch99');
    });

    test('parses challengerId and challengerName', () {
      final c = PVPChallenge.fromJson(
          _challengeJson(challengerId: 'uid_x', challengerName: 'Xavier'));
      expect(c.challengerId, 'uid_x');
      expect(c.challengerName, 'Xavier');
    });

    test('parses opponentId and opponentName', () {
      final c = PVPChallenge.fromJson(
          _challengeJson(opponentId: 'uid_y', opponentName: 'Yara'));
      expect(c.opponentId, 'uid_y');
      expect(c.opponentName, 'Yara');
    });

    test('parses category', () {
      final c = PVPChallenge.fromJson(_challengeJson(category: 'history'));
      expect(c.category, 'history');
    });

    test('parses questionCount', () {
      final c = PVPChallenge.fromJson(_challengeJson(questionCount: 15));
      expect(c.questionCount, 15);
    });

    test('parses difficulty', () {
      final c = PVPChallenge.fromJson(_challengeJson(difficulty: 'hard'));
      expect(c.difficulty, 'hard');
    });

    test('parses wager', () {
      final c = PVPChallenge.fromJson(_challengeJson(wager: 500));
      expect(c.wager, 500);
    });

    test('wager defaults to 0 when absent', () {
      final json = _challengeJson();
      json.remove('wager');
      final c = PVPChallenge.fromJson(json);
      expect(c.wager, 0);
    });
  });

  group('PVPChallenge.fromJson — status parsing', () {
    for (final status in PVPChallengeStatus.values) {
      test('parses status ${status.name}', () {
        final c = PVPChallenge.fromJson(_challengeJson(status: status.name));
        expect(c.status, status);
      });
    }
  });

  group('PVPChallenge.fromJson — DateTime fields', () {
    test('parses createdAt', () {
      final c = PVPChallenge.fromJson(
          _challengeJson(createdAt: '2025-06-01T10:00:00.000Z'));
      expect(c.createdAt.month, 6);
    });

    test('parses expiresAt', () {
      final c = PVPChallenge.fromJson(
          _challengeJson(expiresAt: '2025-06-02T10:00:00.000Z'));
      expect(c.expiresAt.day, 2);
    });

    test('parses optional acceptedAt', () {
      final c = PVPChallenge.fromJson(
          _challengeJson(acceptedAt: '2025-06-01T11:00:00.000Z'));
      expect(c.acceptedAt, isNotNull);
      expect(c.acceptedAt!.hour, 11);
    });

    test('acceptedAt is null when absent', () {
      expect(PVPChallenge.fromJson(_challengeJson()).acceptedAt, isNull);
    });

    test('parses optional completedAt', () {
      final c = PVPChallenge.fromJson(
          _challengeJson(completedAt: '2025-06-01T12:00:00.000Z'));
      expect(c.completedAt, isNotNull);
    });
  });

  group('PVPChallenge.fromJson — optional string fields', () {
    test('parses challengerScore', () {
      final c = PVPChallenge.fromJson(_challengeJson(challengerScore: '850'));
      expect(c.challengerScore, '850');
    });

    test('challengerScore is null when absent', () {
      expect(PVPChallenge.fromJson(_challengeJson()).challengerScore, isNull);
    });

    test('parses opponentScore', () {
      final c = PVPChallenge.fromJson(_challengeJson(opponentScore: '700'));
      expect(c.opponentScore, '700');
    });

    test('parses winnerId', () {
      final c = PVPChallenge.fromJson(_challengeJson(winnerId: 'uid_a'));
      expect(c.winnerId, 'uid_a');
    });

    test('winnerId is null when absent', () {
      expect(PVPChallenge.fromJson(_challengeJson()).winnerId, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // PVPChallenge — computed properties
  // -------------------------------------------------------------------------

  group('PVPChallenge — hasWager', () {
    test('true when wager > 0', () {
      expect(_challenge(wager: 100).hasWager, isTrue);
    });

    test('false when wager is 0', () {
      expect(_challenge(wager: 0).hasWager, isFalse);
    });
  });

  group('PVPChallenge — isExpired', () {
    test('true when expiresAt is in the past and status is not finished', () {
      final c = _challenge(
        status: PVPChallengeStatus.pending,
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
      );
      expect(c.isExpired, isTrue);
    });

    test('false when expiresAt is in the future', () {
      final c = _challenge(
        status: PVPChallengeStatus.pending,
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );
      expect(c.isExpired, isFalse);
    });

    test('false when status is finished (even if past expiresAt)', () {
      final c = _challenge(
        status: PVPChallengeStatus.completed,
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
      );
      expect(c.isExpired, isFalse);
    });
  });

  group('PVPChallenge — timeRemaining', () {
    test('returns positive duration for future expiresAt', () {
      final c =
          _challenge(expiresAt: DateTime.now().add(const Duration(hours: 2)));
      expect(c.timeRemaining.inMinutes, greaterThan(100));
    });

    test('returns negative duration for past expiresAt', () {
      final c = _challenge(
          expiresAt: DateTime.now().subtract(const Duration(hours: 1)));
      expect(c.timeRemaining.isNegative, isTrue);
    });
  });

  group('PVPChallenge — getWinnerName', () {
    test('returns null when winnerId is null', () {
      expect(_challenge().getWinnerName(), isNull);
    });

    test('returns challengerName when winnerId equals challengerId', () {
      final c = _challenge(
        challengerId: 'uid_a',
        challengerName: 'Alice',
        opponentId: 'uid_b',
        opponentName: 'Bob',
        winnerId: 'uid_a',
      );
      expect(c.getWinnerName(), 'Alice');
    });

    test('returns opponentName when winnerId does not equal challengerId', () {
      final c = _challenge(
        challengerId: 'uid_a',
        challengerName: 'Alice',
        opponentId: 'uid_b',
        opponentName: 'Bob',
        winnerId: 'uid_b',
      );
      expect(c.getWinnerName(), 'Bob');
    });
  });

  // -------------------------------------------------------------------------
  // PVPChallenge.toJson
  // -------------------------------------------------------------------------

  group('PVPChallenge.toJson', () {
    test('serializes status as name string', () {
      final c = _challenge(status: PVPChallengeStatus.accepted);
      expect(c.toJson()['status'], 'accepted');
    });

    test('serializes createdAt and expiresAt as ISO strings', () {
      final json = _challenge().toJson();
      expect(json['createdAt'], isA<String>());
      expect(json['expiresAt'], isA<String>());
    });

    test('optional fields absent from JSON when null', () {
      final json = _challenge().toJson();
      expect(json.containsKey('acceptedAt'), isFalse);
      expect(json.containsKey('completedAt'), isFalse);
      expect(json.containsKey('winnerId'), isFalse);
      expect(json.containsKey('challengerScore'), isFalse);
    });

    test('winnerId included in JSON when set', () {
      final c = _challenge(winnerId: 'uid_a');
      expect(c.toJson()['winnerId'], 'uid_a');
    });
  });

  // -------------------------------------------------------------------------
  // PVPChallenge.copyWith
  // -------------------------------------------------------------------------

  group('PVPChallenge.copyWith', () {
    test('copies status', () {
      final updated =
          _challenge().copyWith(status: PVPChallengeStatus.accepted);
      expect(updated.status, PVPChallengeStatus.accepted);
    });

    test('copies wager', () {
      final updated = _challenge(wager: 0).copyWith(wager: 250);
      expect(updated.wager, 250);
    });

    test('copies category', () {
      final updated =
          _challenge(category: 'science').copyWith(category: 'math');
      expect(updated.category, 'math');
    });

    test('copies challengerScore', () {
      final updated = _challenge().copyWith(challengerScore: '950');
      expect(updated.challengerScore, '950');
    });

    test('copies winnerId', () {
      final updated = _challenge().copyWith(winnerId: 'uid_winner');
      expect(updated.winnerId, 'uid_winner');
    });

    test('preserves unchanged fields', () {
      final original = _challenge(
        id: 'orig_id',
        challengerName: 'Alice',
        questionCount: 10,
      );
      final updated = original.copyWith(wager: 500);
      expect(updated.id, 'orig_id');
      expect(updated.challengerName, 'Alice');
      expect(updated.questionCount, 10);
    });
  });

  // -------------------------------------------------------------------------
  // PVPChallengeResult
  // -------------------------------------------------------------------------

  group('PVPChallengeResult — isDraw', () {
    final ts = DateTime(2025, 6, 1);

    test('true when scores are equal', () {
      final result = PVPChallengeResult(
        challengeId: 'ch1',
        winnerId: '',
        challengerScore: 700,
        opponentScore: 700,
        completedAt: ts,
      );
      expect(result.isDraw(), isTrue);
    });

    test('false when scores differ', () {
      final result = PVPChallengeResult(
        challengeId: 'ch1',
        winnerId: 'uid_a',
        challengerScore: 800,
        opponentScore: 700,
        completedAt: ts,
      );
      expect(result.isDraw(), isFalse);
    });
  });

  group('PVPChallengeResult — scoreDifference', () {
    final ts = DateTime(2025, 6, 1);

    test('returns absolute difference', () {
      final result = PVPChallengeResult(
        challengeId: 'ch1',
        winnerId: 'uid_b',
        challengerScore: 600,
        opponentScore: 800,
        completedAt: ts,
      );
      expect(result.scoreDifference, 200);
    });

    test('is always non-negative', () {
      final result = PVPChallengeResult(
        challengeId: 'ch2',
        winnerId: 'uid_a',
        challengerScore: 900,
        opponentScore: 750,
        completedAt: ts,
      );
      expect(result.scoreDifference, 150);
      expect(result.scoreDifference, greaterThanOrEqualTo(0));
    });

    test('returns 0 when scores are equal', () {
      final result = PVPChallengeResult(
        challengeId: 'ch3',
        winnerId: '',
        challengerScore: 500,
        opponentScore: 500,
        completedAt: ts,
      );
      expect(result.scoreDifference, 0);
    });
  });
}
