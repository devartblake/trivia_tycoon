import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/models/referral_models.dart';

void main() {
  // -------------------------------------------------------------------------
  // ReferralCode.fromJson / toJson / copyWith
  // -------------------------------------------------------------------------

  group('ReferralCode.fromJson', () {
    Map<String, dynamic> _json({
      String code = 'RC8A9K2M',
      String ownerUserId = 'uid_1',
      String createdAt = '2025-01-01T00:00:00.000Z',
      String? expiresAt,
      String status = 'active',
      bool isSynced = false,
      String? serverId,
    }) {
      return {
        'code': code,
        'ownerUserId': ownerUserId,
        'createdAt': createdAt,
        if (expiresAt != null) 'expiresAt': expiresAt,
        'status': status,
        'isSynced': isSynced,
        if (serverId != null) 'serverId': serverId,
      };
    }

    test('parses code and ownerUserId', () {
      final rc = ReferralCode.fromJson(_json(code: 'ABCD1234', ownerUserId: 'u42'));
      expect(rc.code, 'ABCD1234');
      expect(rc.ownerUserId, 'u42');
    });

    test('parses createdAt as UTC', () {
      final rc = ReferralCode.fromJson(_json(createdAt: '2025-06-15T10:00:00.000Z'));
      expect(rc.createdAt.isUtc, isTrue);
      expect(rc.createdAt.month, 6);
      expect(rc.createdAt.day, 15);
    });

    test('parses optional expiresAt', () {
      final rc = ReferralCode.fromJson(_json(expiresAt: '2025-12-31T23:59:59.000Z'));
      expect(rc.expiresAt, isNotNull);
      expect(rc.expiresAt!.isUtc, isTrue);
      expect(rc.expiresAt!.month, 12);
    });

    test('expiresAt is null when absent', () {
      expect(ReferralCode.fromJson(_json()).expiresAt, isNull);
    });

    test('parses status active', () {
      expect(ReferralCode.fromJson(_json(status: 'active')).status,
          ReferralCodeStatus.active);
    });

    test('parses status disabled', () {
      expect(ReferralCode.fromJson(_json(status: 'disabled')).status,
          ReferralCodeStatus.disabled);
    });

    test('parses status expired', () {
      expect(ReferralCode.fromJson(_json(status: 'expired')).status,
          ReferralCodeStatus.expired);
    });

    test('defaults status to active for unknown string', () {
      expect(ReferralCode.fromJson(_json(status: 'bogus')).status,
          ReferralCodeStatus.active);
    });

    test('parses isSynced', () {
      expect(ReferralCode.fromJson(_json(isSynced: true)).isSynced, isTrue);
      expect(ReferralCode.fromJson(_json(isSynced: false)).isSynced, isFalse);
    });

    test('parses optional serverId', () {
      final rc = ReferralCode.fromJson(_json(serverId: 'srv_99'));
      expect(rc.serverId, 'srv_99');
    });

    test('serverId is null when absent', () {
      expect(ReferralCode.fromJson(_json()).serverId, isNull);
    });
  });

  group('ReferralCode.toJson', () {
    test('serializes status as name string', () {
      const rc = ReferralCode(
        code: 'ABC',
        ownerUserId: 'u1',
        createdAt: DateTime(2025, 1, 1),
        status: ReferralCodeStatus.disabled,
        isSynced: true,
      );
      final json = rc.toJson();
      expect(json['status'], 'disabled');
      expect(json['isSynced'], isTrue);
    });

    test('serializes createdAt as UTC ISO string', () {
      const rc = ReferralCode(
        code: 'X',
        ownerUserId: 'u',
        createdAt: DateTime.utc(2025, 3, 10),
        isSynced: false,
      );
      expect(rc.toJson()['createdAt'], contains('2025'));
    });

    test('expiresAt is null in JSON when not set', () {
      const rc = ReferralCode(
          code: 'X', ownerUserId: 'u', createdAt: DateTime.utc(2025, 1, 1), isSynced: false);
      expect(rc.toJson()['expiresAt'], isNull);
    });
  });

  group('ReferralCode.copyWith', () {
    const base = ReferralCode(
      code: 'OLD',
      ownerUserId: 'u1',
      createdAt: DateTime.utc(2025, 1, 1),
      isSynced: false,
    );

    test('copies code', () => expect(base.copyWith(code: 'NEW').code, 'NEW'));
    test('copies status', () => expect(
        base.copyWith(status: ReferralCodeStatus.expired).status,
        ReferralCodeStatus.expired));
    test('copies isSynced', () => expect(base.copyWith(isSynced: true).isSynced, isTrue));
    test('copies serverId', () => expect(base.copyWith(serverId: 's1').serverId, 's1'));
    test('preserves unchanged fields', () {
      final updated = base.copyWith(isSynced: true);
      expect(updated.code, 'OLD');
      expect(updated.ownerUserId, 'u1');
    });
  });

  group('ReferralCode — Equatable props', () {
    test('two identical instances are equal', () {
      const a = ReferralCode(
        code: 'ABC',
        ownerUserId: 'u1',
        createdAt: DateTime.utc(2025, 1, 1),
        isSynced: false,
      );
      const b = ReferralCode(
        code: 'ABC',
        ownerUserId: 'u1',
        createdAt: DateTime.utc(2025, 1, 1),
        isSynced: false,
      );
      expect(a, equals(b));
    });

    test('instances with different codes are not equal', () {
      const a = ReferralCode(code: 'AAA', ownerUserId: 'u1', createdAt: DateTime.utc(2025), isSynced: false);
      const b = ReferralCode(code: 'BBB', ownerUserId: 'u1', createdAt: DateTime.utc(2025), isSynced: false);
      expect(a, isNot(equals(b)));
    });
  });

  // -------------------------------------------------------------------------
  // ReferralInvite.fromJson / toJson / copyWith / computed props
  // -------------------------------------------------------------------------

  Map<String, dynamic> _inviteJson({
    String id = 'inv_1',
    String referrerUserId = 'uid_ref',
    String referralCode = 'RC123',
    String createdAt = '2025-02-01T00:00:00.000Z',
    String expiresAt = '2025-02-08T00:00:00.000Z',
    String status = 'pending',
    String? redeemedBy,
    String? redeemedAt,
    String? inviteeName,
    String? inviteeEmail,
    bool isSynced = false,
    String? serverId,
  }) {
    return {
      'id': id,
      'referrerUserId': referrerUserId,
      'referralCode': referralCode,
      'createdAt': createdAt,
      'expiresAt': expiresAt,
      'status': status,
      if (redeemedBy != null) 'redeemedBy': redeemedBy,
      if (redeemedAt != null) 'redeemedAt': redeemedAt,
      if (inviteeName != null) 'inviteeName': inviteeName,
      if (inviteeEmail != null) 'inviteeEmail': inviteeEmail,
      'isSynced': isSynced,
      if (serverId != null) 'serverId': serverId,
    };
  }

  group('ReferralInvite.fromJson', () {
    test('parses all required fields', () {
      final inv = ReferralInvite.fromJson(_inviteJson(
        id: 'inv_99',
        referrerUserId: 'u_ref',
        referralCode: 'CODE_X',
      ));
      expect(inv.id, 'inv_99');
      expect(inv.referrerUserId, 'u_ref');
      expect(inv.referralCode, 'CODE_X');
    });

    test('parses status pending', () {
      expect(ReferralInvite.fromJson(_inviteJson(status: 'pending')).status,
          InviteStatus.pending);
    });

    test('parses status redeemed', () {
      expect(ReferralInvite.fromJson(_inviteJson(status: 'redeemed')).status,
          InviteStatus.redeemed);
    });

    test('parses status expired', () {
      expect(ReferralInvite.fromJson(_inviteJson(status: 'expired')).status,
          InviteStatus.expired);
    });

    test('defaults status to pending for unknown', () {
      expect(ReferralInvite.fromJson(_inviteJson(status: 'nope')).status,
          InviteStatus.pending);
    });

    test('parses optional redeemedBy and redeemedAt', () {
      final inv = ReferralInvite.fromJson(_inviteJson(
        redeemedBy: 'uid_redeemer',
        redeemedAt: '2025-02-04T12:00:00.000Z',
      ));
      expect(inv.redeemedBy, 'uid_redeemer');
      expect(inv.redeemedAt, isNotNull);
      expect(inv.redeemedAt!.day, 4);
    });

    test('redeemedBy and redeemedAt are null when absent', () {
      final inv = ReferralInvite.fromJson(_inviteJson());
      expect(inv.redeemedBy, isNull);
      expect(inv.redeemedAt, isNull);
    });

    test('parses inviteeName and inviteeEmail', () {
      final inv = ReferralInvite.fromJson(_inviteJson(
        inviteeName: 'Charlie',
        inviteeEmail: 'charlie@test.com',
      ));
      expect(inv.inviteeName, 'Charlie');
      expect(inv.inviteeEmail, 'charlie@test.com');
    });
  });

  group('ReferralInvite — computed properties', () {
    ReferralInvite _invite({
      InviteStatus status = InviteStatus.pending,
      DateTime? expiresAt,
    }) {
      return ReferralInvite(
        id: 'inv_t',
        referrerUserId: 'u1',
        referralCode: 'CODE',
        createdAt: DateTime.utc(2025, 1, 1),
        expiresAt: expiresAt ?? DateTime.utc(2099, 12, 31),
        status: status,
      );
    }

    test('isRedeemed true when status is redeemed', () {
      expect(_invite(status: InviteStatus.redeemed).isRedeemed, isTrue);
    });

    test('isRedeemed false for pending', () {
      expect(_invite(status: InviteStatus.pending).isRedeemed, isFalse);
    });

    test('isExpired true when status is expired', () {
      expect(_invite(status: InviteStatus.expired).isExpired, isTrue);
    });

    test('isExpired true when expiresAt is in the past', () {
      final inv = _invite(
          status: InviteStatus.pending,
          expiresAt: DateTime.now().subtract(const Duration(hours: 1)));
      expect(inv.isExpired, isTrue);
    });

    test('isExpired false when expiresAt is in the future', () {
      final inv = _invite(
          status: InviteStatus.pending,
          expiresAt: DateTime.now().add(const Duration(days: 7)));
      expect(inv.isExpired, isFalse);
    });

    test('isPending true when status pending and not expired', () {
      final inv = _invite(status: InviteStatus.pending);
      expect(inv.isPending, isTrue);
    });

    test('isPending false when expired', () {
      final inv = _invite(
          status: InviteStatus.pending,
          expiresAt: DateTime.now().subtract(const Duration(hours: 1)));
      expect(inv.isPending, isFalse);
    });

    test('daysUntilExpiration returns 0 when expired', () {
      final inv = _invite(
          status: InviteStatus.pending,
          expiresAt: DateTime.now().subtract(const Duration(hours: 1)));
      expect(inv.daysUntilExpiration, 0);
    });

    test('daysUntilExpiration returns 0 when redeemed', () {
      expect(_invite(status: InviteStatus.redeemed).daysUntilExpiration, 0);
    });

    test('daysUntilExpiration returns positive days for future expiry', () {
      final inv = _invite(
          status: InviteStatus.pending,
          expiresAt: DateTime.now().add(const Duration(days: 5)));
      expect(inv.daysUntilExpiration, greaterThanOrEqualTo(4));
    });

    test('hoursUntilExpiration returns 0 when expired', () {
      final inv = _invite(
          status: InviteStatus.pending,
          expiresAt: DateTime.now().subtract(const Duration(hours: 1)));
      expect(inv.hoursUntilExpiration, 0);
    });

    test('hoursUntilExpiration returns positive hours for future expiry', () {
      final inv = _invite(
          status: InviteStatus.pending,
          expiresAt: DateTime.now().add(const Duration(hours: 10)));
      expect(inv.hoursUntilExpiration, greaterThanOrEqualTo(9));
    });
  });

  group('ReferralInvite.toJson', () {
    test('serializes status as name string', () {
      final inv = ReferralInvite(
        id: 'x',
        referrerUserId: 'u',
        referralCode: 'C',
        createdAt: DateTime.utc(2025, 1, 1),
        expiresAt: DateTime.utc(2025, 1, 8),
        status: InviteStatus.redeemed,
      );
      expect(inv.toJson()['status'], 'redeemed');
    });

    test('null optional fields appear as null in JSON', () {
      final inv = ReferralInvite(
        id: 'x',
        referrerUserId: 'u',
        referralCode: 'C',
        createdAt: DateTime.utc(2025, 1, 1),
        expiresAt: DateTime.utc(2025, 1, 8),
      );
      final json = inv.toJson();
      expect(json['redeemedBy'], isNull);
      expect(json['redeemedAt'], isNull);
      expect(json['inviteeName'], isNull);
    });
  });

  group('ReferralInvite.copyWith', () {
    final base = ReferralInvite(
      id: 'base',
      referrerUserId: 'u1',
      referralCode: 'CODE',
      createdAt: DateTime.utc(2025, 1, 1),
      expiresAt: DateTime.utc(2025, 1, 8),
    );

    test('copies status', () {
      expect(
          base.copyWith(status: InviteStatus.redeemed).status,
          InviteStatus.redeemed);
    });

    test('copies inviteeName', () {
      expect(base.copyWith(inviteeName: 'Dana').inviteeName, 'Dana');
    });

    test('copies isSynced', () {
      expect(base.copyWith(isSynced: true).isSynced, isTrue);
    });

    test('preserves unchanged fields', () {
      final updated = base.copyWith(isSynced: true);
      expect(updated.id, 'base');
      expect(updated.referralCode, 'CODE');
    });
  });

  // -------------------------------------------------------------------------
  // ReferralScanEvent.fromJson / toJson
  // -------------------------------------------------------------------------

  group('ReferralScanEvent.fromJson', () {
    test('parses code, scannedAt, source', () {
      final event = ReferralScanEvent.fromJson({
        'code': 'SCAN_CODE',
        'scannedAt': '2025-05-10T14:30:00.000Z',
        'source': 'link',
      });
      expect(event.code, 'SCAN_CODE');
      expect(event.scannedAt.isUtc, isTrue);
      expect(event.source, 'link');
    });

    test('defaults source to "qr" when absent', () {
      final event = ReferralScanEvent.fromJson({
        'code': 'X',
        'scannedAt': '2025-01-01T00:00:00.000Z',
      });
      expect(event.source, 'qr');
    });

    test('parses optional scannerUserId and campaignId', () {
      final event = ReferralScanEvent.fromJson({
        'code': 'X',
        'scannerUserId': 'uid_scanner',
        'scannedAt': '2025-01-01T00:00:00.000Z',
        'source': 'manual',
        'campaignId': 'camp_1',
      });
      expect(event.scannerUserId, 'uid_scanner');
      expect(event.campaignId, 'camp_1');
    });

    test('scannerUserId and campaignId are null when absent', () {
      final event = ReferralScanEvent.fromJson({
        'code': 'Y',
        'scannedAt': '2025-01-01T00:00:00.000Z',
      });
      expect(event.scannerUserId, isNull);
      expect(event.campaignId, isNull);
    });
  });

  group('ReferralScanEvent.toJson', () {
    test('serializes all fields', () {
      final event = ReferralScanEvent(
        code: 'EVENT_CODE',
        scannerUserId: 'uid_s',
        scannedAt: DateTime.utc(2025, 3, 20),
        source: 'qr',
        campaignId: 'c1',
      );
      final json = event.toJson();
      expect(json['code'], 'EVENT_CODE');
      expect(json['scannerUserId'], 'uid_s');
      expect(json['source'], 'qr');
      expect(json['campaignId'], 'c1');
      expect(json['scannedAt'], isA<String>());
    });
  });

  group('ReferralScanEvent — Equatable props', () {
    final ts = DateTime.utc(2025, 1, 1);

    test('equal when all props match', () {
      final a = ReferralScanEvent(code: 'X', scannedAt: ts, source: 'qr');
      final b = ReferralScanEvent(code: 'X', scannedAt: ts, source: 'qr');
      expect(a, equals(b));
    });

    test('not equal when source differs', () {
      final a = ReferralScanEvent(code: 'X', scannedAt: ts, source: 'qr');
      final b = ReferralScanEvent(code: 'X', scannedAt: ts, source: 'link');
      expect(a, isNot(equals(b)));
    });
  });
}
