import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/core/services/presence/read_receipt_service.dart';

void main() {
  // ReadReceiptService is a singleton — state persists across tests.
  // Use unique message IDs per test and avoid calling dispose().
  final ReadReceiptService svc = ReadReceiptService();

  setUpAll(() {
    svc.initialize();
  });

  // ---------------------------------------------------------------------------
  // ReadStatus enum
  // ---------------------------------------------------------------------------

  group('ReadStatus enum', () {
    test('has 4 values', () {
      expect(ReadStatus.values.length, 4);
    });

    test('displayName is non-empty for all values', () {
      for (final status in ReadStatus.values) {
        expect(status.displayName.isNotEmpty, isTrue,
            reason: '${status.name}.displayName is empty');
      }
    });

    test('isDelivered: delivered → true', () {
      expect(ReadStatus.delivered.isDelivered, isTrue);
    });

    test('isDelivered: read → true (includes read)', () {
      expect(ReadStatus.read.isDelivered, isTrue);
    });

    test('isDelivered: sent → false', () {
      expect(ReadStatus.sent.isDelivered, isFalse);
    });

    test('isDelivered: failed → false', () {
      expect(ReadStatus.failed.isDelivered, isFalse);
    });

    test('isRead: read → true', () {
      expect(ReadStatus.read.isRead, isTrue);
    });

    test('isRead: delivered → false', () {
      expect(ReadStatus.delivered.isRead, isFalse);
    });

    test('isRead: sent → false', () {
      expect(ReadStatus.sent.isRead, isFalse);
    });

    test('isRead: failed → false', () {
      expect(ReadStatus.failed.isRead, isFalse);
    });

    test('displayName values are Sent/Delivered/Read/Failed', () {
      expect(ReadStatus.sent.displayName, 'Sent');
      expect(ReadStatus.delivered.displayName, 'Delivered');
      expect(ReadStatus.read.displayName, 'Read');
      expect(ReadStatus.failed.displayName, 'Failed');
    });
  });

  // ---------------------------------------------------------------------------
  // ReadReceipt data class
  // ---------------------------------------------------------------------------

  group('ReadReceipt', () {
    final ts = DateTime(2026, 1, 1, 12);

    test('holds all fields', () {
      final r = ReadReceipt(
        messageId: 'msg1',
        userId: 'user1',
        status: ReadStatus.delivered,
        timestamp: ts,
      );
      expect(r.messageId, 'msg1');
      expect(r.userId, 'user1');
      expect(r.status, ReadStatus.delivered);
      expect(r.timestamp, ts);
      expect(r.error, isNull);
    });

    test('error field when provided', () {
      final r = ReadReceipt(
        messageId: 'm',
        userId: 'u',
        status: ReadStatus.failed,
        timestamp: ts,
        error: 'network timeout',
      );
      expect(r.error, 'network timeout');
    });

    test('copyWith status updated, others preserved', () {
      final r = ReadReceipt(
          messageId: 'msg2',
          userId: 'u2',
          status: ReadStatus.sent,
          timestamp: ts);
      final updated = r.copyWith(status: ReadStatus.read);
      expect(updated.status, ReadStatus.read);
      expect(updated.messageId, 'msg2');
      expect(updated.userId, 'u2');
    });

    test('copyWith error updated', () {
      final r = ReadReceipt(
          messageId: 'm3',
          userId: 'u3',
          status: ReadStatus.failed,
          timestamp: ts);
      final withErr = r.copyWith(error: 'bad gateway');
      expect(withErr.error, 'bad gateway');
    });

    test('toJson / fromJson round-trip', () {
      final r = ReadReceipt(
        messageId: 'rr_msg',
        userId: 'rr_user',
        status: ReadStatus.delivered,
        timestamp: ts,
      );
      final json = r.toJson();
      final restored = ReadReceipt.fromJson(json);
      expect(restored.messageId, r.messageId);
      expect(restored.userId, r.userId);
      expect(restored.status, r.status);
      expect(
          restored.timestamp.toIso8601String(), r.timestamp.toIso8601String());
      expect(restored.error, isNull);
    });

    test('toJson / fromJson preserves error field', () {
      final r = ReadReceipt(
        messageId: 'err_msg',
        userId: 'err_user',
        status: ReadStatus.failed,
        timestamp: ts,
        error: 'timeout',
      );
      final restored = ReadReceipt.fromJson(r.toJson());
      expect(restored.error, 'timeout');
    });

    test('toJson includes all required keys', () {
      final r = ReadReceipt(
          messageId: 'm', userId: 'u', status: ReadStatus.sent, timestamp: ts);
      final json = r.toJson();
      expect(json.containsKey('messageId'), isTrue);
      expect(json.containsKey('userId'), isTrue);
      expect(json.containsKey('status'), isTrue);
      expect(json.containsKey('timestamp'), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // MessageReadStatus data class
  // ---------------------------------------------------------------------------

  group('MessageReadStatus', () {
    final ts = DateTime(2026, 1, 1, 12);

    MessageReadStatus _makeStatus(Map<String, ReadStatus> userStatuses) {
      final receipts = <String, ReadReceipt>{};
      for (final entry in userStatuses.entries) {
        receipts[entry.key] = ReadReceipt(
          messageId: 'msg_x',
          userId: entry.key,
          status: entry.value,
          timestamp: ts,
        );
      }
      return MessageReadStatus(
          messageId: 'msg_x', receipts: receipts, lastUpdated: ts);
    }

    test('totalRecipients', () {
      final s = _makeStatus({
        'u1': ReadStatus.read,
        'u2': ReadStatus.delivered,
        'u3': ReadStatus.sent
      });
      expect(s.totalRecipients, 3);
    });

    test('readCount counts only read status', () {
      final s =
          _makeStatus({'u1': ReadStatus.read, 'u2': ReadStatus.delivered});
      expect(s.readCount, 1);
    });

    test('deliveredCount counts read and delivered', () {
      final s = _makeStatus({
        'u1': ReadStatus.read,
        'u2': ReadStatus.delivered,
        'u3': ReadStatus.sent
      });
      expect(s.deliveredCount, 2); // read + delivered
    });

    test('isReadByAll true when all read', () {
      final s = _makeStatus({'u1': ReadStatus.read, 'u2': ReadStatus.read});
      expect(s.isReadByAll, isTrue);
    });

    test('isReadByAll false when some not read', () {
      final s =
          _makeStatus({'u1': ReadStatus.read, 'u2': ReadStatus.delivered});
      expect(s.isReadByAll, isFalse);
    });

    test('isReadByAll true for empty receipts (vacuously)', () {
      final s = MessageReadStatus(
          messageId: 'empty', receipts: const {}, lastUpdated: ts);
      expect(s.isReadByAll, isTrue);
    });

    test('isDeliveredToAll true when all delivered or read', () {
      final s =
          _makeStatus({'u1': ReadStatus.read, 'u2': ReadStatus.delivered});
      expect(s.isDeliveredToAll, isTrue);
    });

    test('isDeliveredToAll false when any sent or failed', () {
      final s =
          _makeStatus({'u1': ReadStatus.delivered, 'u2': ReadStatus.sent});
      expect(s.isDeliveredToAll, isFalse);
    });

    test('hasFailures true when any failed', () {
      final s =
          _makeStatus({'u1': ReadStatus.delivered, 'u2': ReadStatus.failed});
      expect(s.hasFailures, isTrue);
    });

    test('hasFailures false when none failed', () {
      final s =
          _makeStatus({'u1': ReadStatus.read, 'u2': ReadStatus.delivered});
      expect(s.hasFailures, isFalse);
    });

    test('getReceiptForUser returns correct receipt', () {
      final s =
          _makeStatus({'u1': ReadStatus.read, 'u2': ReadStatus.delivered});
      expect(s.getReceiptForUser('u1')?.status, ReadStatus.read);
    });

    test('getReceiptForUser returns null for unknown user', () {
      final s = _makeStatus({'u1': ReadStatus.read});
      expect(s.getReceiptForUser('unknown_xyz'), isNull);
    });

    test('getReceiptsByStatus filters correctly', () {
      final s = _makeStatus({
        'u1': ReadStatus.read,
        'u2': ReadStatus.delivered,
        'u3': ReadStatus.delivered,
      });
      final delivered = s.getReceiptsByStatus(ReadStatus.delivered);
      expect(delivered.length, 2);
      expect(delivered.map((r) => r.userId), containsAll(['u2', 'u3']));
    });

    test('getReceiptsByStatus returns empty when none match', () {
      final s = _makeStatus({'u1': ReadStatus.read});
      expect(s.getReceiptsByStatus(ReadStatus.failed), isEmpty);
    });

    test('copyWith messageId updated', () {
      final s = _makeStatus({'u1': ReadStatus.read});
      final updated = s.copyWith(messageId: 'new_id');
      expect(updated.messageId, 'new_id');
      expect(updated.receipts.length, 1); // preserved
    });
  });

  // ---------------------------------------------------------------------------
  // ReadReceiptService — trackMessage / getMessageStatus
  // ---------------------------------------------------------------------------

  group('trackMessage and getMessageStatus', () {
    test('getMessageStatus returns null for unknown message', () {
      expect(svc.getMessageStatus('not_tracked_xyz'), isNull);
    });

    test('trackMessage creates a status entry', () {
      svc.trackMessage(messageId: 'tm1_msg', recipientIds: ['u_a', 'u_b']);
      final status = svc.getMessageStatus('tm1_msg');
      expect(status, isNotNull);
      expect(status!.messageId, 'tm1_msg');
    });

    test('trackMessage stores all recipients', () {
      svc.trackMessage(messageId: 'tm2_msg', recipientIds: ['x1', 'x2', 'x3']);
      final status = svc.getMessageStatus('tm2_msg');
      expect(status!.totalRecipients, 3);
    });

    test('trackMessage uses sent as default initial status', () {
      svc.trackMessage(messageId: 'tm3_msg', recipientIds: ['u_default']);
      final status = svc.getMessageStatus('tm3_msg');
      final receipt = status?.getReceiptForUser('u_default');
      expect(receipt?.status, ReadStatus.sent);
    });

    test('trackMessage with delivered initial status', () {
      svc.trackMessage(
        messageId: 'tm4_msg',
        recipientIds: ['u_init'],
        initialStatus: ReadStatus.delivered,
      );
      final status = svc.getMessageStatus('tm4_msg');
      expect(status?.getReceiptForUser('u_init')?.status, ReadStatus.delivered);
    });

    test('trackMessage appears in allMessageStatuses', () {
      svc.trackMessage(messageId: 'tm5_msg', recipientIds: ['u_all']);
      expect(svc.allMessageStatuses.containsKey('tm5_msg'), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // ReadReceiptService — updateMessageStatus
  // ---------------------------------------------------------------------------

  group('updateMessageStatus', () {
    test('updates status for tracked recipient', () {
      svc.trackMessage(messageId: 'ums1_msg', recipientIds: ['ums_u1']);
      svc.updateMessageStatus(
          messageId: 'ums1_msg',
          userId: 'ums_u1',
          status: ReadStatus.delivered);
      final receipt =
          svc.getMessageStatus('ums1_msg')?.getReceiptForUser('ums_u1');
      expect(receipt?.status, ReadStatus.delivered);
    });

    test('does not downgrade status from read to delivered', () {
      svc.trackMessage(messageId: 'ums2_msg', recipientIds: ['ums_u2']);
      svc.updateMessageStatus(
          messageId: 'ums2_msg', userId: 'ums_u2', status: ReadStatus.read);
      svc.updateMessageStatus(
          messageId: 'ums2_msg',
          userId: 'ums_u2',
          status: ReadStatus.delivered);
      final receipt =
          svc.getMessageStatus('ums2_msg')?.getReceiptForUser('ums_u2');
      expect(receipt?.status, ReadStatus.read); // not downgraded
    });

    test('no-op for unknown message', () {
      expect(
        () => svc.updateMessageStatus(
            messageId: 'no_such_msg', userId: 'u', status: ReadStatus.read),
        returnsNormally,
      );
    });

    test('no-op for unknown userId in tracked message', () {
      svc.trackMessage(messageId: 'ums3_msg', recipientIds: ['ums_u3']);
      expect(
        () => svc.updateMessageStatus(
            messageId: 'ums3_msg',
            userId: 'not_a_recipient',
            status: ReadStatus.delivered),
        returnsNormally,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // ReadReceiptService — markMessageAsRead / markMultipleAsRead
  // ---------------------------------------------------------------------------

  group('markMessageAsRead', () {
    test('sets receipt to read status', () {
      svc.trackMessage(messageId: 'mar1_msg', recipientIds: ['mar_u1']);
      svc.markMessageAsRead('mar1_msg', 'mar_u1');
      expect(
        svc.getMessageStatus('mar1_msg')?.getReceiptForUser('mar_u1')?.status,
        ReadStatus.read,
      );
    });

    test('markMultipleAsRead marks all listed messages as read', () {
      svc.trackMessage(messageId: 'mmar1_msg', recipientIds: ['mmar_user']);
      svc.trackMessage(messageId: 'mmar2_msg', recipientIds: ['mmar_user']);
      svc.markMultipleAsRead(['mmar1_msg', 'mmar2_msg'], 'mmar_user');
      expect(
        svc
            .getMessageStatus('mmar1_msg')
            ?.getReceiptForUser('mmar_user')
            ?.status,
        ReadStatus.read,
      );
      expect(
        svc
            .getMessageStatus('mmar2_msg')
            ?.getReceiptForUser('mmar_user')
            ?.status,
        ReadStatus.read,
      );
    });

    test('markMultipleAsRead with empty list is no-op', () {
      expect(() => svc.markMultipleAsRead([], 'any_user'), returnsNormally);
    });
  });

  // ---------------------------------------------------------------------------
  // ReadReceiptService — updateMultipleStatuses (Dart records)
  // ---------------------------------------------------------------------------

  group('updateMultipleStatuses', () {
    test('batch updates multiple message statuses', () {
      svc.trackMessage(messageId: 'batch1_msg', recipientIds: ['batch_u']);
      svc.trackMessage(messageId: 'batch2_msg', recipientIds: ['batch_u']);
      svc.updateMultipleStatuses([
        (
          messageId: 'batch1_msg',
          userId: 'batch_u',
          status: ReadStatus.delivered,
          error: null,
        ),
        (
          messageId: 'batch2_msg',
          userId: 'batch_u',
          status: ReadStatus.read,
          error: null,
        ),
      ]);
      expect(
        svc
            .getMessageStatus('batch1_msg')
            ?.getReceiptForUser('batch_u')
            ?.status,
        ReadStatus.delivered,
      );
      expect(
        svc
            .getMessageStatus('batch2_msg')
            ?.getReceiptForUser('batch_u')
            ?.status,
        ReadStatus.read,
      );
    });

    test('empty list is no-op', () {
      expect(() => svc.updateMultipleStatuses([]), returnsNormally);
    });
  });

  // ---------------------------------------------------------------------------
  // ReadReceiptService — getStatusSummary
  // ---------------------------------------------------------------------------

  group('getStatusSummary', () {
    test('returns "Unknown" for untracked message', () {
      expect(svc.getStatusSummary('no_such_msg_xyz'), 'Unknown');
    });

    test('returns "Sending" when all recipients are sent', () {
      svc.trackMessage(
          messageId: 'gss1_msg',
          recipientIds: ['gss_u1'],
          initialStatus: ReadStatus.sent);
      expect(svc.getStatusSummary('gss1_msg'), 'Sending');
    });

    test('returns "Delivered to all" when all delivered', () {
      svc.trackMessage(
          messageId: 'gss2_msg',
          recipientIds: ['gss_u2'],
          initialStatus: ReadStatus.delivered);
      expect(svc.getStatusSummary('gss2_msg'), 'Delivered to all');
    });

    test('returns "Read by all" when all read', () {
      svc.trackMessage(messageId: 'gss3_msg', recipientIds: ['gss_u3']);
      svc.markMessageAsRead('gss3_msg', 'gss_u3');
      expect(svc.getStatusSummary('gss3_msg'), 'Read by all');
    });

    test('returns "Failed" when any failed', () {
      svc.trackMessage(
          messageId: 'gss4_msg',
          recipientIds: ['gss_u4'],
          initialStatus: ReadStatus.failed);
      expect(svc.getStatusSummary('gss4_msg'), 'Failed');
    });
  });

  // ---------------------------------------------------------------------------
  // ReadReceiptService — shouldShowReadReceipts / shouldShowDeliveryStatus
  // ---------------------------------------------------------------------------

  group('shouldShowReadReceipts and shouldShowDeliveryStatus', () {
    test('shouldShowReadReceipts false for untracked message', () {
      expect(svc.shouldShowReadReceipts('untracked_xyz'), isFalse);
    });

    test('shouldShowReadReceipts true for tracked message (when enabled)', () {
      svc.updateSettings(readReceiptsEnabled: true);
      svc.trackMessage(messageId: 'ssrr_msg', recipientIds: ['ssrr_u']);
      expect(svc.shouldShowReadReceipts('ssrr_msg'), isTrue);
    });

    test('shouldShowReadReceipts false when setting disabled', () {
      svc.trackMessage(messageId: 'ssrr2_msg', recipientIds: ['ssrr2_u']);
      svc.updateSettings(readReceiptsEnabled: false);
      expect(svc.shouldShowReadReceipts('ssrr2_msg'), isFalse);
      svc.updateSettings(readReceiptsEnabled: true); // restore
    });

    test('shouldShowDeliveryStatus false for untracked message', () {
      expect(svc.shouldShowDeliveryStatus('untracked_abc'), isFalse);
    });

    test('shouldShowDeliveryStatus true for tracked message (when enabled)',
        () {
      svc.updateSettings(deliveryReceiptsEnabled: true);
      svc.trackMessage(messageId: 'ssds_msg', recipientIds: ['ssds_u']);
      expect(svc.shouldShowDeliveryStatus('ssds_msg'), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // ReadReceiptService — getUnreadCount
  // ---------------------------------------------------------------------------

  group('getUnreadCount', () {
    test('0 for empty list', () {
      expect(svc.getUnreadCount([], 'any_user'), 0);
    });

    test('counts messages where user has not read', () {
      svc.trackMessage(messageId: 'uc1_msg', recipientIds: ['uc_user']);
      svc.trackMessage(messageId: 'uc2_msg', recipientIds: ['uc_user']);
      svc.trackMessage(messageId: 'uc3_msg', recipientIds: ['uc_user']);
      svc.markMessageAsRead('uc1_msg', 'uc_user'); // uc1 is read
      final count =
          svc.getUnreadCount(['uc1_msg', 'uc2_msg', 'uc3_msg'], 'uc_user');
      expect(count, 2); // uc2 and uc3 are not read
    });

    test('0 when all messages are read', () {
      svc.trackMessage(messageId: 'uc4_msg', recipientIds: ['uc4_user']);
      svc.markMessageAsRead('uc4_msg', 'uc4_user');
      expect(svc.getUnreadCount(['uc4_msg'], 'uc4_user'), 0);
    });

    test('0 for untracked messages (not in map)', () {
      expect(svc.getUnreadCount(['completely_unknown_msg'], 'any_user'), 0);
    });
  });

  // ---------------------------------------------------------------------------
  // ReadReceiptService — getAnalytics
  // ---------------------------------------------------------------------------

  group('getAnalytics', () {
    test('returns map with required keys', () {
      final analytics = svc.getAnalytics();
      expect(analytics.containsKey('totalMessages'), isTrue);
      expect(analytics.containsKey('totalReceipts'), isTrue);
      expect(analytics.containsKey('averageRecipientsPerMessage'), isTrue);
      expect(analytics.containsKey('statusDistribution'), isTrue);
      expect(analytics.containsKey('settingsEnabled'), isTrue);
    });

    test('totalMessages increases after trackMessage', () {
      final before = svc.getAnalytics()['totalMessages'] as int;
      svc.trackMessage(
          messageId: 'analytics_${DateTime.now().microsecondsSinceEpoch}',
          recipientIds: ['ana_u']);
      final after = svc.getAnalytics()['totalMessages'] as int;
      expect(after, greaterThan(before));
    });

    test('settingsEnabled reflects current settings', () {
      final settings =
          svc.getAnalytics()['settingsEnabled'] as Map<String, dynamic>;
      expect(settings.containsKey('readReceipts'), isTrue);
      expect(settings.containsKey('deliveryReceipts'), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // ReadReceiptService — updateSettings
  // ---------------------------------------------------------------------------

  group('updateSettings', () {
    test('readReceiptsEnabled getter reflects setting', () {
      svc.updateSettings(readReceiptsEnabled: false);
      expect(svc.readReceiptsEnabled, isFalse);
      svc.updateSettings(readReceiptsEnabled: true);
      expect(svc.readReceiptsEnabled, isTrue);
    });

    test('deliveryReceiptsEnabled getter reflects setting', () {
      svc.updateSettings(deliveryReceiptsEnabled: false);
      expect(svc.deliveryReceiptsEnabled, isFalse);
      svc.updateSettings(deliveryReceiptsEnabled: true);
      expect(svc.deliveryReceiptsEnabled, isTrue);
    });

    test('trackMessage no-op when both receipts disabled', () {
      svc.updateSettings(
          readReceiptsEnabled: false, deliveryReceiptsEnabled: false);
      svc.trackMessage(messageId: 'disabled_msg', recipientIds: ['u']);
      // Should NOT be tracked since both disabled
      expect(svc.getMessageStatus('disabled_msg'), isNull);
      svc.updateSettings(
          readReceiptsEnabled: true, deliveryReceiptsEnabled: true); // restore
    });
  });

  // ---------------------------------------------------------------------------
  // ReadReceiptService — watchReceipts stream
  // ---------------------------------------------------------------------------

  group('watchReceipts stream', () {
    test('emits ReadReceipt after updateMessageStatus', () async {
      svc.trackMessage(messageId: 'wr1_msg', recipientIds: ['wr_u1']);
      final stream = svc.watchReceipts('wr1_msg');

      final completer = Completer<ReadReceipt>();
      final sub = stream.listen(completer.complete);

      svc.updateMessageStatus(
          messageId: 'wr1_msg', userId: 'wr_u1', status: ReadStatus.delivered);

      final receipt =
          await completer.future.timeout(const Duration(seconds: 2));
      expect(receipt.userId, 'wr_u1');
      expect(receipt.status, ReadStatus.delivered);
      await sub.cancel();
    });

    test('emits after markMessageAsRead', () async {
      svc.trackMessage(messageId: 'wr2_msg', recipientIds: ['wr_u2']);
      final stream = svc.watchReceipts('wr2_msg');

      final completer = Completer<ReadReceipt>();
      final sub = stream.listen(completer.complete);

      svc.markMessageAsRead('wr2_msg', 'wr_u2');

      final receipt =
          await completer.future.timeout(const Duration(seconds: 2));
      expect(receipt.status, ReadStatus.read);
      await sub.cancel();
    });
  });

  // ---------------------------------------------------------------------------
  // ReadReceiptService — watchMessageStatus stream
  // ---------------------------------------------------------------------------

  group('watchMessageStatus stream', () {
    test('emits after status change', () async {
      svc.trackMessage(messageId: 'wms1_msg', recipientIds: ['wms_u1']);
      final stream = svc.watchMessageStatus('wms1_msg');

      MessageReadStatus? received;
      final sub = stream.listen((s) => received = s);

      await Future.delayed(const Duration(milliseconds: 200));
      svc.markMessageAsRead('wms1_msg', 'wms_u1');
      await Future.delayed(const Duration(milliseconds: 300));

      expect(received, isNotNull);
      expect(received!.messageId, 'wms1_msg');
      await sub.cancel();
    });
  });
}
