// lib/core/services/advanced/gift_transaction_service.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';

enum TransactionType {
  giftSent,
  giftReceived,
  themePurchase,
  stickerPurchase,
  coinPurchase,
  challengeWager,
  challengeWin,
  achievementReward,
  dailyBonus;

  String get displayName {
    switch (this) {
      case TransactionType.giftSent:
        return 'Gift Sent';
      case TransactionType.giftReceived:
        return 'Gift Received';
      case TransactionType.themePurchase:
        return 'Theme Purchase';
      case TransactionType.stickerPurchase:
        return 'Sticker Purchase';
      case TransactionType.coinPurchase:
        return 'Coins Purchased';
      case TransactionType.challengeWager:
        return 'Challenge Wager';
      case TransactionType.challengeWin:
        return 'Challenge Won';
      case TransactionType.achievementReward:
        return 'Achievement Reward';
      case TransactionType.dailyBonus:
        return 'Daily Bonus';
    }
  }

  bool get isExpense => [giftSent, themePurchase, stickerPurchase, challengeWager].contains(this);
  bool get isIncome => !isExpense;
}

class Transaction {
  final String id;
  final String userId;
  final TransactionType type;
  final int amount; // Positive for income, can be negative for display
  final int balanceAfter;
  final DateTime timestamp;
  final String? description;
  final String? relatedUserId;
  final String? relatedItemId;

  const Transaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    required this.timestamp,
    this.description,
    this.relatedUserId,
    this.relatedItemId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'amount': amount,
      'balanceAfter': balanceAfter,
      'timestamp': timestamp.toIso8601String(),
      if (description != null) 'description': description,
      if (relatedUserId != null) 'relatedUserId': relatedUserId,
      if (relatedItemId != null) 'relatedItemId': relatedItemId,
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: TransactionType.values.byName(json['type'] as String),
      amount: json['amount'] as int,
      balanceAfter: json['balanceAfter'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      description: json['description'] as String?,
      relatedUserId: json['relatedUserId'] as String?,
      relatedItemId: json['relatedItemId'] as String?,
    );
  }
}

class GiftTransactionService extends ChangeNotifier {
  static final GiftTransactionService _instance = GiftTransactionService._internal();
  factory GiftTransactionService() => _instance;
  GiftTransactionService._internal();

  // Storage
  final Map<String, int> _coinBalances = {};
  final Map<String, List<Transaction>> _transactionHistory = {};

  // Streams
  final Map<String, StreamController<int>> _balanceStreams = {};
  final Map<String, StreamController<List<Transaction>>> _transactionStreams = {};

  void initialize() {
    _loadInitialBalances();
    LogManager.debug('GiftTransactionService initialized');
  }

  void dispose() {
    for (final controller in _balanceStreams.values) {
      controller.close();
    }
    for (final controller in _transactionStreams.values) {
      controller.close();
    }
    _balanceStreams.clear();
    _transactionStreams.clear();
    super.dispose();
  }

  // ============ Balance Management ============

  int getCoinBalance(String userId) {
    return _coinBalances[userId] ?? 0;
  }

  Future<bool> addCoins({
    required String userId,
    required int amount,
    required TransactionType type,
    String? description,
    String? relatedUserId,
    String? relatedItemId,
  }) async {
    if (amount <= 0) return false;

    final currentBalance = getCoinBalance(userId);
    final newBalance = currentBalance + amount;
    _coinBalances[userId] = newBalance;

    // Record transaction
    final transaction = Transaction(
      id: _generateTransactionId(),
      userId: userId,
      type: type,
      amount: amount,
      balanceAfter: newBalance,
      timestamp: DateTime.now(),
      description: description,
      relatedUserId: relatedUserId,
      relatedItemId: relatedItemId,
    );

    _transactionHistory[userId] ??= [];
    _transactionHistory[userId]!.add(transaction);

    LogManager.debug('Added $amount coins to $userId. New balance: $newBalance');

    _broadcastBalanceUpdate(userId);
    _broadcastTransactionUpdate(userId);
    notifyListeners();

    return true;
  }

  Future<bool> deductCoins({
    required String userId,
    required int amount,
    required TransactionType type,
    String? description,
    String? relatedUserId,
    String? relatedItemId,
  }) async {
    if (amount <= 0) return false;

    final currentBalance = getCoinBalance(userId);
    if (currentBalance < amount) {
      LogManager.debug('Insufficient balance for user $userId');
      return false;
    }

    final newBalance = currentBalance - amount;
    _coinBalances[userId] = newBalance;

    // Record transaction
    final transaction = Transaction(
      id: _generateTransactionId(),
      userId: userId,
      type: type,
      amount: -amount, // Negative for expenses
      balanceAfter: newBalance,
      timestamp: DateTime.now(),
      description: description,
      relatedUserId: relatedUserId,
      relatedItemId: relatedItemId,
    );

    _transactionHistory[userId] ??= [];
    _transactionHistory[userId]!.add(transaction);

    LogManager.debug('Deducted $amount coins from $userId. New balance: $newBalance');

    _broadcastBalanceUpdate(userId);
    _broadcastTransactionUpdate(userId);
    notifyListeners();

    return true;
  }

  // ============ Gift Transactions ============

  Future<bool> sendGift({
    required String senderId,
    required String recipientId,
    required String giftId,
    required int cost,
  }) async {
    // Deduct from sender
    final deducted = await deductCoins(
      userId: senderId,
      amount: cost,
      type: TransactionType.giftSent,
      description: 'Sent gift: $giftId',
      relatedUserId: recipientId,
      relatedItemId: giftId,
    );

    if (!deducted) return false;

    // Add to recipient (maybe partial value, or no value - just for tracking)
    // For now, gifts don't add coins to recipient, just a social gesture

    LogManager.debug('Gift sent from $senderId to $recipientId');
    return true;
  }

  // ============ Purchase Transactions ============

  Future<bool> purchaseTheme({
    required String userId,
    required String themeId,
    required int price,
  }) async {
    return await deductCoins(
      userId: userId,
      amount: price,
      type: TransactionType.themePurchase,
      description: 'Purchased theme',
      relatedItemId: themeId,
    );
  }

  Future<bool> purchaseStickerPack({
    required String userId,
    required String packId,
    required int price,
  }) async {
    return await deductCoins(
      userId: userId,
      amount: price,
      type: TransactionType.stickerPurchase,
      description: 'Purchased sticker pack',
      relatedItemId: packId,
    );
  }

  Future<bool> purchaseCoins({
    required String userId,
    required int amount,
    required double realMoneyAmount,
  }) async {
    // In a real app, this would integrate with payment gateway
    return await addCoins(
      userId: userId,
      amount: amount,
      type: TransactionType.coinPurchase,
      description: 'Purchased $amount coins for \$realMoneyAmount',
    );
  }

  // ============ Transaction History ============

  List<Transaction> getTransactionHistory(String userId, {int limit = 50}) {
    final history = _transactionHistory[userId] ?? [];
    return history.reversed.take(limit).toList();
  }

  List<Transaction> getTransactionsByType(String userId, TransactionType type) {
    final history = _transactionHistory[userId] ?? [];
    return history.where((t) => t.type == type).toList();
  }

  List<Transaction> getTransactionsByDateRange(
      String userId,
      DateTime start,
      DateTime end,
      ) {
    final history = _transactionHistory[userId] ?? [];
    return history
        .where((t) => t.timestamp.isAfter(start) && t.timestamp.isBefore(end))
        .toList();
  }

  // ============ Analytics ============

  Map<String, dynamic> getTransactionAnalytics(String userId) {
    final history = _transactionHistory[userId] ?? [];
    final now = DateTime.now();
    final last30Days = now.subtract(const Duration(days: 30));

    final recent = history.where((t) => t.timestamp.isAfter(last30Days));
    final totalSpent = recent
        .where((t) => t.type.isExpense)
        .fold<int>(0, (sum, t) => sum + t.amount.abs());
    final totalEarned = recent
        .where((t) => t.type.isIncome)
        .fold<int>(0, (sum, t) => sum + t.amount);

    final typeBreakdown = <String, int>{};
    for (final transaction in recent) {
      typeBreakdown[transaction.type.name] =
          (typeBreakdown[transaction.type.name] ?? 0) + transaction.amount.abs();
    }

    return {
      'currentBalance': getCoinBalance(userId),
      'totalTransactions': history.length,
      'recentTransactions': recent.length,
      'totalSpent30Days': totalSpent,
      'totalEarned30Days': totalEarned,
      'net30Days': totalEarned - totalSpent,
      'typeBreakdown': typeBreakdown,
    };
  }

  // ============ Streams ============

  Stream<int> watchBalance(String userId) {
    _balanceStreams[userId] ??= StreamController<int>.broadcast();

    Future.delayed(Duration.zero, () {
      _broadcastBalanceUpdate(userId);
    });

    return _balanceStreams[userId]!.stream;
  }

  Stream<List<Transaction>> watchTransactions(String userId) {
    _transactionStreams[userId] ??=
    StreamController<List<Transaction>>.broadcast();

    Future.delayed(Duration.zero, () {
      _broadcastTransactionUpdate(userId);
    });

    return _transactionStreams[userId]!.stream;
  }

  void _broadcastBalanceUpdate(String userId) {
    final controller = _balanceStreams[userId];
    if (controller != null && !controller.isClosed) {
      controller.add(getCoinBalance(userId));
    }
  }

  void _broadcastTransactionUpdate(String userId) {
    final controller = _transactionStreams[userId];
    if (controller != null && !controller.isClosed) {
      controller.add(getTransactionHistory(userId));
    }
  }

  // ============ Helper Methods ============

  String _generateTransactionId() {
    return 'txn_${DateTime.now().millisecondsSinceEpoch}_${_transactionHistory.length}';
  }

  void _loadInitialBalances() {
    _coinBalances['current_user'] = 1250;
    _coinBalances['user_1'] = 800;
    _coinBalances['user_2'] = 1500;
  }
}
