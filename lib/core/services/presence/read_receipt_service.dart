import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';

enum ReadStatus {
  sent,
  delivered,
  read,
  failed;

  String get displayName {
    switch (this) {
      case ReadStatus.sent:
        return 'Sent';
      case ReadStatus.delivered:
        return 'Delivered';
      case ReadStatus.read:
        return 'Read';
      case ReadStatus.failed:
        return 'Failed';
    }
  }

  bool get isDelivered =>
      this == ReadStatus.delivered || this == ReadStatus.read;
  bool get isRead => this == ReadStatus.read;
}

class ReadReceipt {
  final String messageId;
  final String userId;
  final ReadStatus status;
  final DateTime timestamp;
  final String? error;

  const ReadReceipt({
    required this.messageId,
    required this.userId,
    required this.status,
    required this.timestamp,
    this.error,
  });

  ReadReceipt copyWith({
    String? messageId,
    String? userId,
    ReadStatus? status,
    DateTime? timestamp,
    String? error,
  }) {
    return ReadReceipt(
      messageId: messageId ?? this.messageId,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      error: error ?? this.error,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'userId': userId,
      'status': status.name,
      'timestamp': timestamp.toIso8601String(),
      if (error != null) 'error': error,
    };
  }

  factory ReadReceipt.fromJson(Map<String, dynamic> json) {
    return ReadReceipt(
      messageId: json['messageId'] as String,
      userId: json['userId'] as String,
      status: ReadStatus.values.byName(json['status'] as String),
      timestamp: DateTime.parse(json['timestamp'] as String),
      error: json['error'] as String?,
    );
  }
}

class MessageReadStatus {
  final String messageId;
  final Map<String, ReadReceipt> receipts;
  final DateTime lastUpdated;

  const MessageReadStatus({
    required this.messageId,
    required this.receipts,
    required this.lastUpdated,
  });

  bool get isDeliveredToAll =>
      receipts.values.every((r) => r.status.isDelivered);
  bool get isReadByAll => receipts.values.every((r) => r.status.isRead);
  bool get hasFailures =>
      receipts.values.any((r) => r.status == ReadStatus.failed);

  int get deliveredCount =>
      receipts.values.where((r) => r.status.isDelivered).length;
  int get readCount => receipts.values.where((r) => r.status.isRead).length;
  int get totalRecipients => receipts.length;

  ReadReceipt? getReceiptForUser(String userId) => receipts[userId];

  List<ReadReceipt> getReceiptsByStatus(ReadStatus status) {
    return receipts.values.where((r) => r.status == status).toList();
  }

  MessageReadStatus copyWith({
    String? messageId,
    Map<String, ReadReceipt>? receipts,
    DateTime? lastUpdated,
  }) {
    return MessageReadStatus(
      messageId: messageId ?? this.messageId,
      receipts: receipts ?? this.receipts,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class ReadReceiptService extends ChangeNotifier {
  static final ReadReceiptService _instance = ReadReceiptService._internal();
  factory ReadReceiptService() => _instance;
  ReadReceiptService._internal();

  final Map<String, MessageReadStatus> _messageStatuses = {};
  final Map<String, StreamController<ReadReceipt>> _receiptStreams = {};

  Timer? _cleanupTimer;

  // Settings
  bool _readReceiptsEnabled = true;
  bool _deliveryReceiptsEnabled = true;
  Duration _receiptTimeout = const Duration(minutes: 5);
  int _maxStoredReceipts = 1000;

  // Getters
  bool get readReceiptsEnabled => _readReceiptsEnabled;
  bool get deliveryReceiptsEnabled => _deliveryReceiptsEnabled;
  Map<String, MessageReadStatus> get allMessageStatuses =>
      Map.unmodifiable(_messageStatuses);

  void initialize() {
    _startCleanupTimer();
    LogManager.debug('ReadReceiptService initialized');
  }

  void dispose() {
    _cleanupTimer?.cancel();
    for (final controller in _receiptStreams.values) {
      controller.close();
    }
    _receiptStreams.clear();
    super.dispose();
  }

  // Settings management
  void updateSettings({
    bool? readReceiptsEnabled,
    bool? deliveryReceiptsEnabled,
    Duration? receiptTimeout,
    int? maxStoredReceipts,
  }) {
    _readReceiptsEnabled = readReceiptsEnabled ?? _readReceiptsEnabled;
    _deliveryReceiptsEnabled =
        deliveryReceiptsEnabled ?? _deliveryReceiptsEnabled;
    _receiptTimeout = receiptTimeout ?? _receiptTimeout;
    _maxStoredReceipts = maxStoredReceipts ?? _maxStoredReceipts;

    LogManager.debug('ReadReceiptService settings updated');
    notifyListeners();
  }

  // Message status tracking
  void trackMessage({
    required String messageId,
    required List<String> recipientIds,
    ReadStatus initialStatus = ReadStatus.sent,
  }) {
    if (!_deliveryReceiptsEnabled && !_readReceiptsEnabled) return;

    final receipts = <String, ReadReceipt>{};
    final now = DateTime.now();

    for (final userId in recipientIds) {
      receipts[userId] = ReadReceipt(
        messageId: messageId,
        userId: userId,
        status: initialStatus,
        timestamp: now,
      );
    }

    _messageStatuses[messageId] = MessageReadStatus(
      messageId: messageId,
      receipts: receipts,
      lastUpdated: now,
    );

    LogManager.debug(
        'Tracking message $messageId for ${recipientIds.length} recipients');
    notifyListeners();
    _broadcastStatusUpdate(messageId);
  }

  // Update message status
  void updateMessageStatus({
    required String messageId,
    required String userId,
    required ReadStatus status,
    String? error,
  }) {
    final messageStatus = _messageStatuses[messageId];
    if (messageStatus == null) return;

    final currentReceipt = messageStatus.receipts[userId];
    if (currentReceipt == null) return;

    // Don't downgrade status (e.g., from read to delivered)
    if (status.index < currentReceipt.status.index) return;

    final updatedReceipt = currentReceipt.copyWith(
      status: status,
      timestamp: DateTime.now(),
      error: error,
    );

    final updatedReceipts =
        Map<String, ReadReceipt>.from(messageStatus.receipts);
    updatedReceipts[userId] = updatedReceipt;

    _messageStatuses[messageId] = messageStatus.copyWith(
      receipts: updatedReceipts,
      lastUpdated: DateTime.now(),
    );

    LogManager.debug('Updated $messageId status for $userId: ${status.name}');
    notifyListeners();
    _broadcastReceiptUpdate(updatedReceipt);
    _broadcastStatusUpdate(messageId);
  }

  // Batch update for efficiency
  void updateMultipleStatuses(
      List<
              ({
                String messageId,
                String userId,
                ReadStatus status,
                String? error
              })>
          updates) {
    bool hasUpdates = false;

    for (final update in updates) {
      final messageStatus = _messageStatuses[update.messageId];
      if (messageStatus == null) continue;

      final currentReceipt = messageStatus.receipts[update.userId];
      if (currentReceipt == null) continue;

      // Don't downgrade status
      if (update.status.index < currentReceipt.status.index) continue;

      final updatedReceipt = currentReceipt.copyWith(
        status: update.status,
        timestamp: DateTime.now(),
        error: update.error,
      );

      final updatedReceipts =
          Map<String, ReadReceipt>.from(messageStatus.receipts);
      updatedReceipts[update.userId] = updatedReceipt;

      _messageStatuses[update.messageId] = messageStatus.copyWith(
        receipts: updatedReceipts,
        lastUpdated: DateTime.now(),
      );

      _broadcastReceiptUpdate(updatedReceipt);
      hasUpdates = true;
    }

    if (hasUpdates) {
      LogManager.debug('Batch updated ${updates.length} receipt statuses');
      notifyListeners();
    }
  }

  // Mark message as read by current user
  void markMessageAsRead(String messageId, String currentUserId) {
    if (!_readReceiptsEnabled) return;

    updateMessageStatus(
      messageId: messageId,
      userId: currentUserId,
      status: ReadStatus.read,
    );
  }

  // Mark multiple messages as read
  void markMultipleAsRead(List<String> messageIds, String currentUserId) {
    if (!_readReceiptsEnabled) return;

    final updates = messageIds
        .map((messageId) => (
              messageId: messageId,
              userId: currentUserId,
              status: ReadStatus.read,
              error: null as String?,
            ))
        .toList();

    updateMultipleStatuses(updates);
  }

  // Get message status
  MessageReadStatus? getMessageStatus(String messageId) {
    return _messageStatuses[messageId];
  }

  // Get formatted status summary
  String getStatusSummary(String messageId) {
    final status = _messageStatuses[messageId];
    if (status == null) return 'Unknown';

    if (status.hasFailures) return 'Failed';
    if (status.isReadByAll) return 'Read by all';
    if (status.isDeliveredToAll) return 'Delivered to all';

    final readCount = status.readCount;
    final deliveredCount = status.deliveredCount;
    final total = status.totalRecipients;

    if (readCount > 0) {
      return readCount == total ? 'Read' : 'Read by $readCount';
    }
    if (deliveredCount > 0) {
      return deliveredCount == total
          ? 'Delivered'
          : 'Delivered to $deliveredCount';
    }

    return 'Sending';
  }

  // Stream for specific message updates
  Stream<MessageReadStatus> watchMessageStatus(String messageId) {
    return Stream.periodic(const Duration(milliseconds: 100))
        .map((_) => _messageStatuses[messageId])
        .where((status) => status != null)
        .cast<MessageReadStatus>()
        .distinct();
  }

  // Stream for receipt updates
  Stream<ReadReceipt> watchReceipts(String messageId) {
    _receiptStreams[messageId] ??= StreamController<ReadReceipt>.broadcast();
    return _receiptStreams[messageId]!.stream;
  }

  // Cleanup old receipts
  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(const Duration(minutes: 10), (_) {
      _cleanupOldReceipts();
    });
  }

  void _cleanupOldReceipts() {
    final cutoff = DateTime.now().subtract(_receiptTimeout);
    final toRemove = <String>[];

    for (final entry in _messageStatuses.entries) {
      if (entry.value.lastUpdated.isBefore(cutoff)) {
        toRemove.add(entry.key);
      }
    }

    // Keep only the most recent receipts if we exceed the limit
    if (_messageStatuses.length > _maxStoredReceipts) {
      final sortedEntries = _messageStatuses.entries.toList()
        ..sort((a, b) => b.value.lastUpdated.compareTo(a.value.lastUpdated));

      final excess = sortedEntries.skip(_maxStoredReceipts);
      toRemove.addAll(excess.map((e) => e.key));
    }

    for (final messageId in toRemove) {
      _messageStatuses.remove(messageId);
      _receiptStreams[messageId]?.close();
      _receiptStreams.remove(messageId);
    }

    if (toRemove.isNotEmpty) {
      LogManager.debug('Cleaned up ${toRemove.length} old message statuses');
    }
  }

  void _broadcastReceiptUpdate(ReadReceipt receipt) {
    final controller = _receiptStreams[receipt.messageId];
    if (controller != null && !controller.isClosed) {
      controller.add(receipt);
    }
  }

  void _broadcastStatusUpdate(String messageId) {
    // This could broadcast to a general message status stream if needed
    LogManager.debug('Broadcasting status update for message $messageId');
  }

  // Helper methods for UI
  bool shouldShowReadReceipts(String messageId) {
    return _readReceiptsEnabled && _messageStatuses.containsKey(messageId);
  }

  bool shouldShowDeliveryStatus(String messageId) {
    return _deliveryReceiptsEnabled && _messageStatuses.containsKey(messageId);
  }

  // Get unread message count for a conversation
  int getUnreadCount(List<String> messageIds, String currentUserId) {
    return messageIds.where((messageId) {
      final status = _messageStatuses[messageId];
      if (status == null) return false;

      final receipt = status.receipts[currentUserId];
      return receipt != null && !receipt.status.isRead;
    }).length;
  }

  // Analytics helpers
  Map<String, dynamic> getAnalytics() {
    final totalMessages = _messageStatuses.length;
    final totalReceipts = _messageStatuses.values
        .fold<int>(0, (sum, status) => sum + status.receipts.length);

    final statusCounts = <ReadStatus, int>{};
    for (final status in _messageStatuses.values) {
      for (final receipt in status.receipts.values) {
        statusCounts[receipt.status] = (statusCounts[receipt.status] ?? 0) + 1;
      }
    }

    return {
      'totalMessages': totalMessages,
      'totalReceipts': totalReceipts,
      'averageRecipientsPerMessage':
          totalMessages > 0 ? totalReceipts / totalMessages : 0,
      'statusDistribution': statusCounts.map((k, v) => MapEntry(k.name, v)),
      'settingsEnabled': {
        'readReceipts': _readReceiptsEnabled,
        'deliveryReceipts': _deliveryReceiptsEnabled,
      },
    };
  }
}
