import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:synaptix/game/services/referral_storage_service.dart';
import 'package:synaptix/game/models/referral_models.dart';

ReferralCode _code(String code) => ReferralCode(
      code: code,
      ownerUserId: 'owner1',
      createdAt: DateTime.utc(2026, 1, 1),
    );

ReferralScanEvent _scan(String code) => ReferralScanEvent(
      code: code,
      scannedAt: DateTime.utc(2026, 1, 1),
    );

ReferralInvite _invite(String id, {String code = 'RCTEST'}) => ReferralInvite(
      id: id,
      referrerUserId: 'ref1',
      referralCode: code,
      createdAt: DateTime.utc(2026, 1, 1),
      expiresAt: DateTime.utc(2027, 1, 1),
    );

void main() {
  late Directory tempDir;
  late ReferralStorageService svc;

  setUpAll(() async {
    tempDir =
        await Directory.systemTemp.createTemp('referral_storage_service_test');
    Hive.init(tempDir.path);
  });

  setUp(() async {
    svc = ReferralStorageService();
    await svc.initialize();
  });

  tearDown(() async {
    const boxName = 'referral_box';
    if (Hive.isBoxOpen(boxName)) {
      await Hive.box(boxName).clear();
      await Hive.box(boxName).close();
      await Hive.deleteBoxFromDisk(boxName);
    }
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  // -------------------------------------------------------------------------
  // saveReferralCode / getReferralCode
  // -------------------------------------------------------------------------

  group('saveReferralCode / getReferralCode', () {
    test('getReferralCode returns null before any save', () {
      expect(svc.getReferralCode(), isNull);
    });

    test('getReferralCode returns saved code after saveReferralCode', () async {
      final rc = _code('RCABC123');
      await svc.saveReferralCode(rc);
      final loaded = svc.getReferralCode();
      expect(loaded, isNotNull);
      expect(loaded!.code, 'RCABC123');
    });

    test('saved code preserves ownerUserId', () async {
      final rc = _code('RCTEST01');
      await svc.saveReferralCode(rc);
      expect(svc.getReferralCode()!.ownerUserId, 'owner1');
    });

    test('saved code preserves status (defaults to active)', () async {
      await svc.saveReferralCode(_code('RCTEST02'));
      expect(svc.getReferralCode()!.status, ReferralCodeStatus.active);
    });

    test('saved code preserves isSynced (defaults to false)', () async {
      await svc.saveReferralCode(_code('RCTEST03'));
      expect(svc.getReferralCode()!.isSynced, isFalse);
    });

    test('overwriting with a new code replaces the old one', () async {
      await svc.saveReferralCode(_code('RCFIRST'));
      await svc.saveReferralCode(_code('RCSECOND'));
      expect(svc.getReferralCode()!.code, 'RCSECOND');
    });
  });

  // -------------------------------------------------------------------------
  // updateSyncStatus
  // -------------------------------------------------------------------------

  group('updateSyncStatus', () {
    test('matching code sets isSynced to true', () async {
      await svc.saveReferralCode(_code('RCSYNC'));
      await svc.updateSyncStatus('RCSYNC', true);
      expect(svc.getReferralCode()!.isSynced, isTrue);
    });

    test('non-matching code is a no-op', () async {
      await svc.saveReferralCode(_code('RCORIGINAL'));
      await svc.updateSyncStatus('RCOTHER', true);
      // Original code is unchanged
      final loaded = svc.getReferralCode();
      expect(loaded!.code, 'RCORIGINAL');
      expect(loaded.isSynced, isFalse);
    });

    test('sets optional serverId when provided', () async {
      await svc.saveReferralCode(_code('RCSRV'));
      await svc.updateSyncStatus('RCSRV', true, serverId: 'server-42');
      expect(svc.getReferralCode()!.serverId, 'server-42');
    });
  });

  // -------------------------------------------------------------------------
  // saveScanEvent / getScanHistory
  // -------------------------------------------------------------------------

  group('saveScanEvent / getScanHistory', () {
    test('getScanHistory returns empty list initially', () {
      expect(svc.getScanHistory(), isEmpty);
    });

    test('single saved event appears in history', () async {
      await svc.saveScanEvent(_scan('RCSCAN1'));
      expect(svc.getScanHistory().length, 1);
    });

    test('saved event preserves code', () async {
      await svc.saveScanEvent(_scan('RCEVT'));
      expect(svc.getScanHistory().first.code, 'RCEVT');
    });

    test('saved event preserves source (defaults to qr)', () async {
      await svc.saveScanEvent(_scan('RCSRC'));
      expect(svc.getScanHistory().first.source, 'qr');
    });

    test('multiple events accumulate in history', () async {
      await svc.saveScanEvent(_scan('RC001'));
      await svc.saveScanEvent(_scan('RC002'));
      await svc.saveScanEvent(_scan('RC003'));
      expect(svc.getScanHistory().length, 3);
    });
  });

  // -------------------------------------------------------------------------
  // clearReferralCode
  // -------------------------------------------------------------------------

  group('clearReferralCode', () {
    test('getReferralCode returns null after clearReferralCode', () async {
      await svc.saveReferralCode(_code('RCCLEAR'));
      await svc.clearReferralCode();
      expect(svc.getReferralCode(), isNull);
    });

    test('clearReferralCode does not affect scan history', () async {
      await svc.saveScanEvent(_scan('RCSC'));
      await svc.saveReferralCode(_code('RCCLR2'));
      await svc.clearReferralCode();
      expect(svc.getScanHistory().length, 1);
    });
  });

  // -------------------------------------------------------------------------
  // ReferralInviteStorage extension — saveInvite / getInvites
  // -------------------------------------------------------------------------

  group('ReferralInviteStorage.saveInvite / getInvites', () {
    test('getInvites returns empty list initially', () {
      expect(svc.getInvites(), isEmpty);
    });

    test('single saved invite appears in list', () async {
      await svc.saveInvite(_invite('inv1'));
      expect(svc.getInvites().length, 1);
    });

    test('saved invite preserves id', () async {
      await svc.saveInvite(_invite('inv-abc'));
      expect(svc.getInvites().first.id, 'inv-abc');
    });

    test('saved invite preserves referralCode', () async {
      await svc.saveInvite(_invite('inv2', code: 'RCMYCODE'));
      expect(svc.getInvites().first.referralCode, 'RCMYCODE');
    });

    test('saved invite status defaults to pending', () async {
      await svc.saveInvite(_invite('inv3'));
      expect(svc.getInvites().first.status, InviteStatus.pending);
    });

    test('multiple invites accumulate', () async {
      await svc.saveInvite(_invite('i1'));
      await svc.saveInvite(_invite('i2'));
      expect(svc.getInvites().length, 2);
    });

    test('saving invite with existing id updates it rather than duplicating',
        () async {
      await svc.saveInvite(_invite('dup'));
      final updated = _invite('dup', code: 'RCUPDATED');
      await svc.saveInvite(updated);
      expect(svc.getInvites().length, 1);
      expect(svc.getInvites().first.referralCode, 'RCUPDATED');
    });
  });

  // -------------------------------------------------------------------------
  // ReferralInviteStorage extension — updateInviteStatus
  // -------------------------------------------------------------------------

  group('ReferralInviteStorage.updateInviteStatus', () {
    test('updates status of matching invite to redeemed', () async {
      await svc.saveInvite(_invite('upd1'));
      await svc.updateInviteStatus('upd1', InviteStatus.redeemed);
      expect(svc.getInvites().first.status, InviteStatus.redeemed);
    });

    test('unmatched id is a no-op (invite unchanged)', () async {
      await svc.saveInvite(_invite('orig'));
      await svc.updateInviteStatus('nonexistent', InviteStatus.redeemed);
      expect(svc.getInvites().first.status, InviteStatus.pending);
    });

    test('updates status to expired', () async {
      await svc.saveInvite(_invite('exp1'));
      await svc.updateInviteStatus('exp1', InviteStatus.expired);
      expect(svc.getInvites().first.status, InviteStatus.expired);
    });
  });
}
