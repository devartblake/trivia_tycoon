import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/core/services/advanced/gift_transaction_service.dart';

void main() {
  late GiftTransactionService svc;

  setUp(() {
    svc = GiftTransactionService();
    svc.initialize();
  });

  // -------------------------------------------------------------------------
  // getCoinBalance
  // -------------------------------------------------------------------------

  group('getCoinBalance', () {
    test('0 for unknown user', () {
      expect(svc.getCoinBalance('nobody'), 0);
    });

    test('reflects added coins', () async {
      await svc.addCoins(
          userId: 'u1', amount: 100, type: TransactionType.dailyBonus);
      expect(svc.getCoinBalance('u1'), greaterThan(0));
    });

    test('reflects deducted coins', () async {
      await svc.addCoins(
          userId: 'u2', amount: 200, type: TransactionType.dailyBonus);
      await svc.deductCoins(
          userId: 'u2', amount: 50, type: TransactionType.challengeWager);
      expect(svc.getCoinBalance('u2'), 150);
    });
  });

  // -------------------------------------------------------------------------
  // addCoins
  // -------------------------------------------------------------------------

  group('addCoins', () {
    test('returns true on success', () async {
      final result = await svc.addCoins(
          userId: 'a1', amount: 100, type: TransactionType.achievementReward);
      expect(result, isTrue);
    });

    test('balance updated after addCoins', () async {
      await svc.addCoins(
          userId: 'a2', amount: 300, type: TransactionType.coinPurchase);
      expect(svc.getCoinBalance('a2'), 300);
    });

    test('amount <= 0 returns false', () async {
      final result = await svc.addCoins(
          userId: 'a3', amount: 0, type: TransactionType.dailyBonus);
      expect(result, isFalse);
    });

    test('negative amount returns false', () async {
      final result = await svc.addCoins(
          userId: 'a4', amount: -50, type: TransactionType.dailyBonus);
      expect(result, isFalse);
    });

    test('transaction appears in history', () async {
      await svc.addCoins(
          userId: 'a5',
          amount: 100,
          type: TransactionType.achievementReward,
          description: 'Test reward');
      final history = svc.getTransactionHistory('a5');
      expect(history.isNotEmpty, isTrue);
      expect(history.first.type, TransactionType.achievementReward);
    });
  });

  // -------------------------------------------------------------------------
  // deductCoins
  // -------------------------------------------------------------------------

  group('deductCoins', () {
    test('returns true when sufficient balance', () async {
      await svc.addCoins(
          userId: 'd1', amount: 200, type: TransactionType.dailyBonus);
      final result = await svc.deductCoins(
          userId: 'd1', amount: 100, type: TransactionType.challengeWager);
      expect(result, isTrue);
    });

    test('returns false when insufficient balance', () async {
      await svc.addCoins(
          userId: 'd2', amount: 50, type: TransactionType.dailyBonus);
      final result = await svc.deductCoins(
          userId: 'd2', amount: 100, type: TransactionType.challengeWager);
      expect(result, isFalse);
    });

    test('balance unchanged on failure', () async {
      await svc.addCoins(
          userId: 'd3', amount: 50, type: TransactionType.dailyBonus);
      await svc.deductCoins(
          userId: 'd3', amount: 100, type: TransactionType.challengeWager);
      expect(svc.getCoinBalance('d3'), 50);
    });

    test('exact balance deducts to 0', () async {
      await svc.addCoins(
          userId: 'd4', amount: 100, type: TransactionType.dailyBonus);
      await svc.deductCoins(
          userId: 'd4', amount: 100, type: TransactionType.challengeWager);
      expect(svc.getCoinBalance('d4'), 0);
    });
  });

  // -------------------------------------------------------------------------
  // sendGift
  // -------------------------------------------------------------------------

  group('sendGift', () {
    test('deducts from sender', () async {
      await svc.addCoins(
          userId: 'sender1', amount: 200, type: TransactionType.dailyBonus);
      await svc.sendGift(
          senderId: 'sender1',
          recipientId: 'recv1',
          giftId: 'gift_a',
          cost: 50);
      expect(svc.getCoinBalance('sender1'), 150);
    });

    test('returns false if sender has insufficient balance', () async {
      await svc.addCoins(
          userId: 'sender2', amount: 10, type: TransactionType.dailyBonus);
      final result = await svc.sendGift(
          senderId: 'sender2',
          recipientId: 'recv2',
          giftId: 'gift_b',
          cost: 50);
      expect(result, isFalse);
    });

    test('sender transaction type is giftSent', () async {
      await svc.addCoins(
          userId: 'sender3', amount: 200, type: TransactionType.dailyBonus);
      await svc.sendGift(
          senderId: 'sender3',
          recipientId: 'recv3',
          giftId: 'gift_c',
          cost: 50);
      final history = svc.getTransactionHistory('sender3');
      expect(history.any((t) => t.type == TransactionType.giftSent), isTrue);
    });

    test('no coins added to recipient', () async {
      await svc.addCoins(
          userId: 'sender4', amount: 200, type: TransactionType.dailyBonus);
      final recvBalanceBefore = svc.getCoinBalance('recv4');
      await svc.sendGift(
          senderId: 'sender4',
          recipientId: 'recv4',
          giftId: 'gift_d',
          cost: 50);
      expect(svc.getCoinBalance('recv4'), recvBalanceBefore);
    });
  });

  // -------------------------------------------------------------------------
  // purchaseTheme / purchaseStickerPack / purchaseCoins
  // -------------------------------------------------------------------------

  group('purchaseTheme', () {
    test('deducts price from user', () async {
      await svc.addCoins(
          userId: 'p1', amount: 500, type: TransactionType.dailyBonus);
      await svc.purchaseTheme(userId: 'p1', themeId: 'theme_dark', price: 200);
      expect(svc.getCoinBalance('p1'), 300);
    });

    test('returns false if insufficient balance', () async {
      await svc.addCoins(
          userId: 'p2', amount: 50, type: TransactionType.dailyBonus);
      final result = await svc.purchaseTheme(
          userId: 'p2', themeId: 'theme_neon', price: 200);
      expect(result, isFalse);
    });
  });

  group('purchaseStickerPack', () {
    test('deducts price from user', () async {
      await svc.addCoins(
          userId: 'sp1', amount: 300, type: TransactionType.dailyBonus);
      await svc.purchaseStickerPack(
          userId: 'sp1', packId: 'pack_1', price: 100);
      expect(svc.getCoinBalance('sp1'), 200);
    });

    test('returns false if insufficient', () async {
      final result = await svc.purchaseStickerPack(
          userId: 'sp2', packId: 'pack_2', price: 100);
      expect(result, isFalse);
    });
  });

  group('purchaseCoins', () {
    test('adds coins to user', () async {
      await svc.purchaseCoins(
          userId: 'pc1', amount: 1000, realMoneyAmount: 4.99);
      expect(svc.getCoinBalance('pc1'), greaterThan(0));
    });
  });

  // -------------------------------------------------------------------------
  // getTransactionHistory
  // -------------------------------------------------------------------------

  group('getTransactionHistory', () {
    test('empty before any transaction', () {
      expect(svc.getTransactionHistory('fresh_user'), isEmpty);
    });

    test('accumulates transactions', () async {
      await svc.addCoins(
          userId: 'th1', amount: 100, type: TransactionType.dailyBonus);
      await svc.addCoins(
          userId: 'th1', amount: 200, type: TransactionType.achievementReward);
      expect(svc.getTransactionHistory('th1').length, 2);
    });

    test('respects limit parameter', () async {
      for (int i = 0; i < 10; i++) {
        await svc.addCoins(
            userId: 'th2', amount: 10, type: TransactionType.dailyBonus);
      }
      expect(svc.getTransactionHistory('th2', limit: 3).length, 3);
    });

    test('most recent first (reversed)', () async {
      await svc.addCoins(
          userId: 'th3',
          amount: 100,
          type: TransactionType.dailyBonus,
          description: 'first');
      await svc.addCoins(
          userId: 'th3',
          amount: 200,
          type: TransactionType.dailyBonus,
          description: 'second');
      final history = svc.getTransactionHistory('th3');
      expect(history.first.description, 'second');
    });
  });

  // -------------------------------------------------------------------------
  // getTransactionsByType
  // -------------------------------------------------------------------------

  group('getTransactionsByType', () {
    test('returns only transactions of specified type', () async {
      await svc.addCoins(
          userId: 'tt1', amount: 100, type: TransactionType.dailyBonus);
      await svc.addCoins(
          userId: 'tt1', amount: 50, type: TransactionType.achievementReward);
      final daily =
          svc.getTransactionsByType('tt1', TransactionType.dailyBonus);
      expect(daily.every((t) => t.type == TransactionType.dailyBonus), isTrue);
      expect(daily.length, 1);
    });

    test('returns empty when type not present', () {
      final result =
          svc.getTransactionsByType('nobody', TransactionType.giftSent);
      expect(result, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // getTransactionsByDateRange
  // -------------------------------------------------------------------------

  group('getTransactionsByDateRange', () {
    test('returns only transactions within range', () async {
      await svc.addCoins(
          userId: 'dr1', amount: 100, type: TransactionType.dailyBonus);
      final start = DateTime.now().subtract(const Duration(minutes: 1));
      final end = DateTime.now().add(const Duration(minutes: 1));
      final inRange = svc.getTransactionsByDateRange('dr1', start, end);
      expect(inRange.isNotEmpty, isTrue);
    });

    test('returns empty when no transactions in range', () async {
      await svc.addCoins(
          userId: 'dr2', amount: 100, type: TransactionType.dailyBonus);
      final start = DateTime.now().subtract(const Duration(days: 2));
      final end = DateTime.now().subtract(const Duration(days: 1));
      final outOfRange = svc.getTransactionsByDateRange('dr2', start, end);
      expect(outOfRange, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // TransactionType enum
  // -------------------------------------------------------------------------

  group('TransactionType enum', () {
    test('isExpense true for giftSent', () {
      expect(TransactionType.giftSent.isExpense, isTrue);
    });

    test('isExpense true for themePurchase', () {
      expect(TransactionType.themePurchase.isExpense, isTrue);
    });

    test('isExpense true for stickerPurchase', () {
      expect(TransactionType.stickerPurchase.isExpense, isTrue);
    });

    test('isExpense true for challengeWager', () {
      expect(TransactionType.challengeWager.isExpense, isTrue);
    });

    test('isExpense false for giftReceived', () {
      expect(TransactionType.giftReceived.isExpense, isFalse);
    });

    test('isIncome inverse of isExpense', () {
      for (final type in TransactionType.values) {
        expect(type.isIncome, !type.isExpense);
      }
    });

    test('displayName non-empty for all 9 values', () {
      for (final type in TransactionType.values) {
        expect(type.displayName.isNotEmpty, isTrue);
      }
    });

    test('there are 9 TransactionType values', () {
      expect(TransactionType.values.length, 9);
    });
  });

  // -------------------------------------------------------------------------
  // getTransactionAnalytics
  // -------------------------------------------------------------------------

  group('getTransactionAnalytics', () {
    test('returns currentBalance', () async {
      await svc.addCoins(
          userId: 'ta1', amount: 500, type: TransactionType.dailyBonus);
      final analytics = svc.getTransactionAnalytics('ta1');
      expect(analytics['currentBalance'], 500);
    });

    test('totalTransactions counts all-time', () async {
      await svc.addCoins(
          userId: 'ta2', amount: 100, type: TransactionType.dailyBonus);
      await svc.addCoins(
          userId: 'ta2', amount: 50, type: TransactionType.achievementReward);
      final analytics = svc.getTransactionAnalytics('ta2');
      expect(analytics['totalTransactions'], greaterThanOrEqualTo(2));
    });

    test('contains net30Days key', () async {
      await svc.addCoins(
          userId: 'ta3', amount: 100, type: TransactionType.dailyBonus);
      final analytics = svc.getTransactionAnalytics('ta3');
      expect(analytics.containsKey('net30Days'), isTrue);
    });

    test('typeBreakdown has entries after transactions', () async {
      await svc.addCoins(
          userId: 'ta4', amount: 100, type: TransactionType.dailyBonus);
      final analytics = svc.getTransactionAnalytics('ta4');
      final breakdown = analytics['typeBreakdown'] as Map;
      expect(breakdown.isNotEmpty, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // streams
  // -------------------------------------------------------------------------

  group('streams', () {
    test('watchBalance emits after addCoins', () async {
      final stream = svc.watchBalance('stream_u1');
      final future = stream.first;
      await svc.addCoins(
          userId: 'stream_u1', amount: 100, type: TransactionType.dailyBonus);
      final balance = await future.timeout(const Duration(seconds: 2));
      expect(balance, 100);
    });

    test('watchTransactions emits after transaction', () async {
      final stream = svc.watchTransactions('stream_u2');
      final future = stream.first;
      await svc.addCoins(
          userId: 'stream_u2', amount: 50, type: TransactionType.dailyBonus);
      final transactions = await future.timeout(const Duration(seconds: 2));
      expect(transactions.isNotEmpty, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // _loadInitialBalances
  // -------------------------------------------------------------------------

  group('_loadInitialBalances', () {
    test('current_user has balance 1250 after initialize', () {
      expect(svc.getCoinBalance('current_user'), 1250);
    });

    test('user_1 has balance 800 after initialize', () {
      expect(svc.getCoinBalance('user_1'), 800);
    });

    test('user_2 has balance 1500 after initialize', () {
      expect(svc.getCoinBalance('user_2'), 1500);
    });
  });
}
