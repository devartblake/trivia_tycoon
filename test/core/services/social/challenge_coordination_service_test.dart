import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/core/services/social/challenge_coordination_service.dart';
import 'package:trivia_tycoon/game/models/pvp_challenge_models.dart';

// ChallengeCoordinationService is a singleton, so tests must use unique
// userId strings to isolate coin balances and challenge lists.

ChallengeCoordinationService _svc = ChallengeCoordinationService();

// Helper that creates a basic no-wager challenge between two users
Future<PVPChallenge> _createNoWagerChallenge(
  ChallengeCoordinationService svc, {
  required String challengerId,
  required String opponentId,
  String suffix = '',
}) async {
  final challenge = await svc.createChallenge(
    challengerId: challengerId,
    challengerName: 'Challenger$suffix',
    opponentId: opponentId,
    opponentName: 'Opponent$suffix',
    category: 'Science',
    questionCount: 5,
    difficulty: 'medium',
  );
  return challenge!;
}

void main() {
  setUpAll(() {
    _svc = ChallengeCoordinationService();
    _svc.initialize();
  });

  tearDownAll(() {
    _svc.dispose();
  });

  // -------------------------------------------------------------------------
  // PVPChallengeStatus enum
  // -------------------------------------------------------------------------

  group('PVPChallengeStatus enum', () {
    test('has 6 values', () {
      expect(PVPChallengeStatus.values.length, 6);
    });

    test('isActive true for accepted only', () {
      expect(PVPChallengeStatus.accepted.isActive, isTrue);
      expect(PVPChallengeStatus.pending.isActive, isFalse);
      expect(PVPChallengeStatus.completed.isActive, isFalse);
    });

    test('isPending true for pending only', () {
      expect(PVPChallengeStatus.pending.isPending, isTrue);
      expect(PVPChallengeStatus.accepted.isPending, isFalse);
    });

    test('isFinished true for completed/declined/expired/cancelled', () {
      expect(PVPChallengeStatus.completed.isFinished, isTrue);
      expect(PVPChallengeStatus.declined.isFinished, isTrue);
      expect(PVPChallengeStatus.expired.isFinished, isTrue);
      expect(PVPChallengeStatus.cancelled.isFinished, isTrue);
    });

    test('isFinished false for pending and accepted', () {
      expect(PVPChallengeStatus.pending.isFinished, isFalse);
      expect(PVPChallengeStatus.accepted.isFinished, isFalse);
    });

    test('all have non-empty displayName', () {
      for (final s in PVPChallengeStatus.values) {
        expect(s.displayName.isNotEmpty, isTrue);
      }
    });
  });

  // -------------------------------------------------------------------------
  // PVPChallenge model
  // -------------------------------------------------------------------------

  group('PVPChallenge model', () {
    final now = DateTime(2026, 1, 1);
    final challenge = PVPChallenge(
      id: 'ch1',
      challengerId: 'c_user',
      challengerName: 'Challenger',
      opponentId: 'o_user',
      opponentName: 'Opponent',
      category: 'History',
      questionCount: 5,
      difficulty: 'hard',
      wager: 0,
      createdAt: now,
      expiresAt: now.add(const Duration(hours: 24)),
    );

    test('hasWager false when wager=0', () {
      expect(challenge.hasWager, isFalse);
    });

    test('hasWager true when wager > 0', () {
      final wagered = challenge.copyWith(wager: 100);
      expect(wagered.hasWager, isTrue);
    });

    test('status defaults to pending', () {
      expect(challenge.status, PVPChallengeStatus.pending);
    });

    test('isExpired false for future expiresAt', () {
      expect(challenge.isExpired, isFalse);
    });

    test('getWinnerName null when no winner', () {
      expect(challenge.getWinnerName(), isNull);
    });

    test('getWinnerName returns challenger name when challenger wins', () {
      final won = challenge.copyWith(
          winnerId: 'c_user',
          status: PVPChallengeStatus.completed);
      expect(won.getWinnerName(), 'Challenger');
    });

    test('getWinnerName returns opponent name when opponent wins', () {
      final won = challenge.copyWith(
          winnerId: 'o_user',
          status: PVPChallengeStatus.completed);
      expect(won.getWinnerName(), 'Opponent');
    });

    test('copyWith updates status', () {
      final accepted = challenge.copyWith(status: PVPChallengeStatus.accepted);
      expect(accepted.status, PVPChallengeStatus.accepted);
      expect(accepted.id, 'ch1');
    });
  });

  // -------------------------------------------------------------------------
  // getCoinBalance — initial mock balances
  // -------------------------------------------------------------------------

  group('getCoinBalance', () {
    test('0 for unknown user', () {
      expect(_svc.getCoinBalance('absolutely_unknown_user_xyz'), 0);
    });

    test('current_user has 1250 after initialize', () {
      expect(_svc.getCoinBalance('current_user'), 1250);
    });

    test('user_1 has 800 after initialize', () {
      expect(_svc.getCoinBalance('user_1'), 800);
    });

    test('user_2 has 1500 after initialize', () {
      expect(_svc.getCoinBalance('user_2'), 1500);
    });
  });

  // -------------------------------------------------------------------------
  // addCoins
  // -------------------------------------------------------------------------

  group('addCoins', () {
    test('returns true and increases balance', () async {
      const uid = 'addcoins_test_u1';
      final before = _svc.getCoinBalance(uid);
      final result = await _svc.addCoins(uid, 100);
      expect(result, isTrue);
      expect(_svc.getCoinBalance(uid), before + 100);
    });

    test('returns false for amount <= 0', () async {
      final result = await _svc.addCoins('addcoins_test_u2', 0);
      expect(result, isFalse);
    });

    test('returns false for negative amount', () async {
      final result = await _svc.addCoins('addcoins_test_u3', -50);
      expect(result, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // createChallenge
  // -------------------------------------------------------------------------

  group('createChallenge', () {
    test('returns non-null challenge', () async {
      final challenge = await _createNoWagerChallenge(
        _svc, challengerId: 'cc_c1', opponentId: 'cc_o1', suffix: '1',
      );
      expect(challenge, isNotNull);
    });

    test('challenge has pending status initially', () async {
      final challenge = await _createNoWagerChallenge(
        _svc, challengerId: 'cc_c2', opponentId: 'cc_o2', suffix: '2',
      );
      expect(challenge.status, PVPChallengeStatus.pending);
    });

    test('challenge retrievable by ID', () async {
      final challenge = await _createNoWagerChallenge(
        _svc, challengerId: 'cc_c3', opponentId: 'cc_o3', suffix: '3',
      );
      expect(_svc.getChallenge(challenge.id), isNotNull);
    });

    test('challenge appears in getUserChallenges for challenger', () async {
      final challenge = await _createNoWagerChallenge(
        _svc, challengerId: 'cc_c4', opponentId: 'cc_o4', suffix: '4',
      );
      final challenges = _svc.getUserChallenges('cc_c4');
      expect(challenges.any((c) => c.id == challenge.id), isTrue);
    });

    test('challenge appears in getUserChallenges for opponent', () async {
      final challenge = await _createNoWagerChallenge(
        _svc, challengerId: 'cc_c5', opponentId: 'cc_o5', suffix: '5',
      );
      final challenges = _svc.getUserChallenges('cc_o5');
      expect(challenges.any((c) => c.id == challenge.id), isTrue);
    });

    test('returns null when wager > coin balance', () async {
      final result = await _svc.createChallenge(
        challengerId: 'cc_broke_user',
        challengerName: 'Broke',
        opponentId: 'cc_opponent_b',
        opponentName: 'Opponent',
        category: 'Science',
        questionCount: 5,
        difficulty: 'easy',
        wager: 999999,
      );
      expect(result, isNull);
    });

    test('wager deducted from challenger on create', () async {
      await _svc.addCoins('cc_wagerer', 500);
      final before = _svc.getCoinBalance('cc_wagerer');
      await _svc.createChallenge(
        challengerId: 'cc_wagerer',
        challengerName: 'Wagerer',
        opponentId: 'cc_wager_opp',
        opponentName: 'WagerOpp',
        category: 'Science',
        questionCount: 5,
        difficulty: 'easy',
        wager: 100,
      );
      expect(_svc.getCoinBalance('cc_wagerer'), before - 100);
    });
  });

  // -------------------------------------------------------------------------
  // acceptChallenge
  // -------------------------------------------------------------------------

  group('acceptChallenge', () {
    test('true when opponent accepts pending challenge', () async {
      final ch = await _createNoWagerChallenge(
        _svc, challengerId: 'ac_c1', opponentId: 'ac_o1', suffix: 'ac1',
      );
      final result = await _svc.acceptChallenge(ch.id, 'ac_o1');
      expect(result, isTrue);
    });

    test('status becomes accepted after accept', () async {
      final ch = await _createNoWagerChallenge(
        _svc, challengerId: 'ac_c2', opponentId: 'ac_o2', suffix: 'ac2',
      );
      await _svc.acceptChallenge(ch.id, 'ac_o2');
      expect(_svc.getChallenge(ch.id)!.status, PVPChallengeStatus.accepted);
    });

    test('false when non-opponent tries to accept', () async {
      final ch = await _createNoWagerChallenge(
        _svc, challengerId: 'ac_c3', opponentId: 'ac_o3', suffix: 'ac3',
      );
      final result = await _svc.acceptChallenge(ch.id, 'wrong_user');
      expect(result, isFalse);
    });

    test('false when challenge already accepted', () async {
      final ch = await _createNoWagerChallenge(
        _svc, challengerId: 'ac_c4', opponentId: 'ac_o4', suffix: 'ac4',
      );
      await _svc.acceptChallenge(ch.id, 'ac_o4');
      final result = await _svc.acceptChallenge(ch.id, 'ac_o4');
      expect(result, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // declineChallenge
  // -------------------------------------------------------------------------

  group('declineChallenge', () {
    test('true when opponent declines pending challenge', () async {
      final ch = await _createNoWagerChallenge(
        _svc, challengerId: 'dc_c1', opponentId: 'dc_o1', suffix: 'dc1',
      );
      final result = await _svc.declineChallenge(ch.id, 'dc_o1');
      expect(result, isTrue);
    });

    test('status becomes declined after decline', () async {
      final ch = await _createNoWagerChallenge(
        _svc, challengerId: 'dc_c2', opponentId: 'dc_o2', suffix: 'dc2',
      );
      await _svc.declineChallenge(ch.id, 'dc_o2');
      expect(_svc.getChallenge(ch.id)!.status, PVPChallengeStatus.declined);
    });

    test('false when non-opponent tries to decline', () async {
      final ch = await _createNoWagerChallenge(
        _svc, challengerId: 'dc_c3', opponentId: 'dc_o3', suffix: 'dc3',
      );
      final result = await _svc.declineChallenge(ch.id, 'wrong_user3');
      expect(result, isFalse);
    });

    test('wager refunded to challenger after decline', () async {
      await _svc.addCoins('dc_wagerer', 500);
      final ch = await _svc.createChallenge(
        challengerId: 'dc_wagerer',
        challengerName: 'Wagerer',
        opponentId: 'dc_wager_opp',
        opponentName: 'Opp',
        category: 'Science',
        questionCount: 5,
        difficulty: 'easy',
        wager: 50,
      );
      final balanceAfterCreate = _svc.getCoinBalance('dc_wagerer');
      await _svc.declineChallenge(ch!.id, 'dc_wager_opp');
      expect(_svc.getCoinBalance('dc_wagerer'), balanceAfterCreate + 50);
    });
  });

  // -------------------------------------------------------------------------
  // cancelChallenge
  // -------------------------------------------------------------------------

  group('cancelChallenge', () {
    test('true when challenger cancels pending challenge', () async {
      final ch = await _createNoWagerChallenge(
        _svc, challengerId: 'cancel_c1', opponentId: 'cancel_o1',
        suffix: 'cancel1',
      );
      final result = await _svc.cancelChallenge(ch.id, 'cancel_c1');
      expect(result, isTrue);
    });

    test('status becomes cancelled', () async {
      final ch = await _createNoWagerChallenge(
        _svc, challengerId: 'cancel_c2', opponentId: 'cancel_o2',
        suffix: 'cancel2',
      );
      await _svc.cancelChallenge(ch.id, 'cancel_c2');
      expect(_svc.getChallenge(ch.id)!.status, PVPChallengeStatus.cancelled);
    });

    test('false when non-challenger tries to cancel', () async {
      final ch = await _createNoWagerChallenge(
        _svc, challengerId: 'cancel_c3', opponentId: 'cancel_o3',
        suffix: 'cancel3',
      );
      final result = await _svc.cancelChallenge(ch.id, 'cancel_o3');
      expect(result, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // completeChallenge
  // -------------------------------------------------------------------------

  group('completeChallenge', () {
    test('returns PVPChallengeResult with correct winner when challenger wins',
        () async {
      final ch = await _createNoWagerChallenge(
        _svc, challengerId: 'comp_c1', opponentId: 'comp_o1', suffix: 'comp1',
      );
      await _svc.acceptChallenge(ch.id, 'comp_o1');
      final result = await _svc.completeChallenge(
        challengeId: ch.id,
        challengerScore: 10,
        opponentScore: 5,
      );
      expect(result, isNotNull);
      expect(result!.winnerId, 'comp_c1');
    });

    test('winner is opponent when opponent has higher score', () async {
      final ch = await _createNoWagerChallenge(
        _svc, challengerId: 'comp_c2', opponentId: 'comp_o2', suffix: 'comp2',
      );
      await _svc.acceptChallenge(ch.id, 'comp_o2');
      final result = await _svc.completeChallenge(
        challengeId: ch.id,
        challengerScore: 3,
        opponentScore: 8,
      );
      expect(result!.winnerId, 'comp_o2');
    });

    test('draw: winnerId is empty string in result', () async {
      final ch = await _createNoWagerChallenge(
        _svc, challengerId: 'comp_c3', opponentId: 'comp_o3', suffix: 'comp3',
      );
      await _svc.acceptChallenge(ch.id, 'comp_o3');
      final result = await _svc.completeChallenge(
        challengeId: ch.id,
        challengerScore: 5,
        opponentScore: 5,
      );
      expect(result!.winnerId, '');
    });

    test('challenge status becomes completed', () async {
      final ch = await _createNoWagerChallenge(
        _svc, challengerId: 'comp_c4', opponentId: 'comp_o4', suffix: 'comp4',
      );
      await _svc.acceptChallenge(ch.id, 'comp_o4');
      await _svc.completeChallenge(
          challengeId: ch.id, challengerScore: 5, opponentScore: 3);
      expect(
          _svc.getChallenge(ch.id)!.status, PVPChallengeStatus.completed);
    });

    test('returns null for non-active challenge', () async {
      final ch = await _createNoWagerChallenge(
        _svc, challengerId: 'comp_c5', opponentId: 'comp_o5', suffix: 'comp5',
      );
      // Not accepted, still pending
      final result = await _svc.completeChallenge(
          challengeId: ch.id, challengerScore: 5, opponentScore: 3);
      expect(result, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // submitScore
  // -------------------------------------------------------------------------

  group('submitScore', () {
    test('true when challenger submits score', () async {
      final ch = await _createNoWagerChallenge(
        _svc, challengerId: 'ss_c1', opponentId: 'ss_o1', suffix: 'ss1',
      );
      await _svc.acceptChallenge(ch.id, 'ss_o1');
      final result = await _svc.submitScore(
          challengeId: ch.id, userId: 'ss_c1', score: 7);
      expect(result, isTrue);
    });

    test('true when opponent submits score', () async {
      final ch = await _createNoWagerChallenge(
        _svc, challengerId: 'ss_c2', opponentId: 'ss_o2', suffix: 'ss2',
      );
      await _svc.acceptChallenge(ch.id, 'ss_o2');
      final result = await _svc.submitScore(
          challengeId: ch.id, userId: 'ss_o2', score: 4);
      expect(result, isTrue);
    });

    test('false for non-participant', () async {
      final ch = await _createNoWagerChallenge(
        _svc, challengerId: 'ss_c3', opponentId: 'ss_o3', suffix: 'ss3',
      );
      await _svc.acceptChallenge(ch.id, 'ss_o3');
      final result = await _svc.submitScore(
          challengeId: ch.id, userId: 'ss_outsider', score: 9);
      expect(result, isFalse);
    });

    test('auto-completes when both scores submitted', () async {
      final ch = await _createNoWagerChallenge(
        _svc, challengerId: 'ss_c4', opponentId: 'ss_o4', suffix: 'ss4',
      );
      await _svc.acceptChallenge(ch.id, 'ss_o4');
      await _svc.submitScore(challengeId: ch.id, userId: 'ss_c4', score: 8);
      await _svc.submitScore(challengeId: ch.id, userId: 'ss_o4', score: 6);
      expect(
          _svc.getChallenge(ch.id)!.status, PVPChallengeStatus.completed);
    });
  });

  // -------------------------------------------------------------------------
  // query methods
  // -------------------------------------------------------------------------

  group('getPendingChallenges', () {
    test('contains pending challenge for opponent', () async {
      final ch = await _createNoWagerChallenge(
        _svc, challengerId: 'pend_c1', opponentId: 'pend_o1', suffix: 'pend1',
      );
      final pending = _svc.getPendingChallenges('pend_o1');
      expect(pending.any((c) => c.id == ch.id), isTrue);
    });

    test('not in pending after accept', () async {
      final ch = await _createNoWagerChallenge(
        _svc, challengerId: 'pend_c2', opponentId: 'pend_o2', suffix: 'pend2',
      );
      await _svc.acceptChallenge(ch.id, 'pend_o2');
      final pending = _svc.getPendingChallenges('pend_o2');
      expect(pending.any((c) => c.id == ch.id), isFalse);
    });
  });

  group('getSentChallenges', () {
    test('contains sent challenge for challenger', () async {
      final ch = await _createNoWagerChallenge(
        _svc, challengerId: 'sent_c1', opponentId: 'sent_o1', suffix: 'sent1',
      );
      final sent = _svc.getSentChallenges('sent_c1');
      expect(sent.any((c) => c.id == ch.id), isTrue);
    });
  });

  group('getActiveChallenges', () {
    test('empty for user with no active challenges', () {
      final active = _svc.getActiveChallenges('no_active_user_xyz');
      expect(active, isEmpty);
    });

    test('contains challenge after accept', () async {
      final ch = await _createNoWagerChallenge(
        _svc, challengerId: 'active_c1', opponentId: 'active_o1',
        suffix: 'active1',
      );
      await _svc.acceptChallenge(ch.id, 'active_o1');
      final active = _svc.getActiveChallenges('active_c1');
      expect(active.any((c) => c.id == ch.id), isTrue);
    });
  });

  group('getCompletedChallenges', () {
    test('contains completed challenge', () async {
      final ch = await _createNoWagerChallenge(
        _svc, challengerId: 'cmpl_c1', opponentId: 'cmpl_o1', suffix: 'cmpl1',
      );
      await _svc.acceptChallenge(ch.id, 'cmpl_o1');
      await _svc.completeChallenge(
          challengeId: ch.id, challengerScore: 5, opponentScore: 3);
      final completed = _svc.getCompletedChallenges('cmpl_c1');
      expect(completed.any((c) => c.id == ch.id), isTrue);
    });
  });

  group('getChallengeHistory', () {
    test('returns finished challenges', () async {
      final ch = await _createNoWagerChallenge(
        _svc, challengerId: 'hist_c1', opponentId: 'hist_o1', suffix: 'hist1',
      );
      await _svc.declineChallenge(ch.id, 'hist_o1');
      final history = _svc.getChallengeHistory('hist_c1');
      expect(history.any((c) => c.id == ch.id), isTrue);
    });

    test('respects limit parameter', () async {
      for (int i = 0; i < 3; i++) {
        final ch = await _createNoWagerChallenge(
          _svc,
          challengerId: 'hist_limit_c',
          opponentId: 'hist_limit_o$i',
          suffix: 'histlim$i',
        );
        await _svc.declineChallenge(ch.id, 'hist_limit_o$i');
      }
      final history = _svc.getChallengeHistory('hist_limit_c', limit: 2);
      expect(history.length, lessThanOrEqualTo(2));
    });
  });

  // -------------------------------------------------------------------------
  // getChallengeStats
  // -------------------------------------------------------------------------

  group('getChallengeStats', () {
    test('returns map with wins key', () async {
      final stats = _svc.getChallengeStats('stats_user_1');
      expect(stats.containsKey('wins'), isTrue);
    });

    test('returns map with losses key', () {
      expect(_svc.getChallengeStats('stats_user_2').containsKey('losses'),
          isTrue);
    });

    test('returns map with draws key', () {
      expect(_svc.getChallengeStats('stats_user_3').containsKey('draws'),
          isTrue);
    });

    test('returns map with coinBalance key', () {
      expect(
          _svc.getChallengeStats('stats_user_4').containsKey('coinBalance'),
          isTrue);
    });

    test('coinBalance in stats matches getCoinBalance', () async {
      await _svc.addCoins('stats_bal_user', 250);
      final stats = _svc.getChallengeStats('stats_bal_user');
      expect(stats['coinBalance'], _svc.getCoinBalance('stats_bal_user'));
    });

    test('wins count correct after winning a challenge', () async {
      final ch = await _createNoWagerChallenge(
        _svc, challengerId: 'stats_winner', opponentId: 'stats_loser',
        suffix: 'statswin',
      );
      await _svc.acceptChallenge(ch.id, 'stats_loser');
      await _svc.completeChallenge(
          challengeId: ch.id, challengerScore: 10, opponentScore: 5);
      final stats = _svc.getChallengeStats('stats_winner');
      expect(stats['wins'], greaterThanOrEqualTo(1));
    });
  });

  // -------------------------------------------------------------------------
  // watchUserChallenges stream
  // -------------------------------------------------------------------------

  group('watchUserChallenges stream', () {
    test('emits after creating a challenge', () async {
      const streamUser = 'stream_watch_user_1';
      final stream = _svc.watchUserChallenges(streamUser);
      final future = stream.first;
      await _createNoWagerChallenge(
        _svc,
        challengerId: streamUser,
        opponentId: 'stream_opp_1',
        suffix: 'stream1',
      );
      final emitted =
          await future.timeout(const Duration(seconds: 2));
      expect(emitted, isA<List<PVPChallenge>>());
    });
  });

  // -------------------------------------------------------------------------
  // updateSettings / getSettings
  // -------------------------------------------------------------------------

  group('updateSettings / getSettings', () {
    test('getSettings returns map with challengeExpiration key', () {
      final settings = _svc.getSettings();
      expect(settings.containsKey('challengeExpiration'), isTrue);
    });

    test('getSettings returns map with maxActiveChallenges key', () {
      expect(_svc.getSettings().containsKey('maxActiveChallenges'), isTrue);
    });

    test('getSettings returns map with minWager key', () {
      expect(_svc.getSettings().containsKey('minWager'), isTrue);
    });

    test('updateSettings changes maxActiveChallenges', () {
      _svc.updateSettings(maxActiveChallenges: 5);
      expect(_svc.getSettings()['maxActiveChallenges'], 5);
      _svc.updateSettings(maxActiveChallenges: 10); // restore
    });

    test('updateSettings changes minWager', () {
      _svc.updateSettings(minWager: 20);
      expect(_svc.getSettings()['minWager'], 20);
      _svc.updateSettings(minWager: 10); // restore
    });

    test('challenge below minWager returns null', () async {
      _svc.updateSettings(minWager: 500);
      await _svc.addCoins('wager_test_u', 1000);
      final result = await _svc.createChallenge(
        challengerId: 'wager_test_u',
        challengerName: 'Tester',
        opponentId: 'wager_test_opp',
        opponentName: 'Opp',
        category: 'Science',
        questionCount: 5,
        difficulty: 'easy',
        wager: 100, // below minWager of 500
      );
      expect(result, isNull);
      _svc.updateSettings(minWager: 10); // restore
    });
  });
}
