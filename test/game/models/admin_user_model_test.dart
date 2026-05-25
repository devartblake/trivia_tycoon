import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/models/admin_user_model.dart';

Map<String, dynamic> _baseJson({
  String id = 'uid_1',
  String username = 'alice',
  String email = 'alice@example.com',
  String? avatarUrl,
  String status = 'online',
  String role = 'user',
  String ageGroup = 'adults',
  String createdAt = '2024-01-15T08:00:00.000Z',
  String lastActive = '2025-05-01T12:00:00.000Z',
  int totalGamesPlayed = 42,
  int totalPoints = 1500,
  double winRate = 0.65,
  bool isVerified = true,
  bool isBanned = false,
  String? banReason,
  Map<String, dynamic>? metadata,
}) =>
    {
      'id': id,
      'username': username,
      'email': email,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      'status': status,
      'role': role,
      'ageGroup': ageGroup,
      'createdAt': createdAt,
      'lastActive': lastActive,
      'totalGamesPlayed': totalGamesPlayed,
      'totalPoints': totalPoints,
      'winRate': winRate,
      'isVerified': isVerified,
      'isBanned': isBanned,
      if (banReason != null) 'banReason': banReason,
      if (metadata != null) 'metadata': metadata,
    };

void main() {
  // -------------------------------------------------------------------------
  // AdminUserModel.fromJson — scalar fields
  // -------------------------------------------------------------------------

  group('AdminUserModel.fromJson — scalar fields', () {
    test('parses id', () {
      expect(AdminUserModel.fromJson(_baseJson(id: 'uid_99')).id, 'uid_99');
    });

    test('parses username', () {
      expect(
          AdminUserModel.fromJson(_baseJson(username: 'bob')).username, 'bob');
    });

    test('parses email', () {
      expect(
        AdminUserModel.fromJson(_baseJson(email: 'bob@test.com')).email,
        'bob@test.com',
      );
    });

    test('parses avatarUrl when present', () {
      final m = AdminUserModel.fromJson(
          _baseJson(avatarUrl: 'https://example.com/avatar.png'));
      expect(m.avatarUrl, 'https://example.com/avatar.png');
    });

    test('avatarUrl is null when absent', () {
      expect(AdminUserModel.fromJson(_baseJson()).avatarUrl, isNull);
    });

    test('parses totalGamesPlayed', () {
      expect(
          AdminUserModel.fromJson(_baseJson(totalGamesPlayed: 100))
              .totalGamesPlayed,
          100);
    });

    test('totalGamesPlayed defaults to 0 when absent', () {
      final json = _baseJson();
      json.remove('totalGamesPlayed');
      expect(AdminUserModel.fromJson(json).totalGamesPlayed, 0);
    });

    test('parses totalPoints', () {
      expect(AdminUserModel.fromJson(_baseJson(totalPoints: 999)).totalPoints,
          999);
    });

    test('totalPoints defaults to 0 when absent', () {
      final json = _baseJson();
      json.remove('totalPoints');
      expect(AdminUserModel.fromJson(json).totalPoints, 0);
    });

    test('parses winRate', () {
      final m = AdminUserModel.fromJson(_baseJson(winRate: 0.75));
      expect(m.winRate, closeTo(0.75, 0.001));
    });

    test('winRate defaults to 0.0 when absent', () {
      final json = _baseJson();
      json.remove('winRate');
      expect(AdminUserModel.fromJson(json).winRate, closeTo(0.0, 0.001));
    });

    test('parses isVerified', () {
      expect(AdminUserModel.fromJson(_baseJson(isVerified: true)).isVerified,
          isTrue);
      expect(AdminUserModel.fromJson(_baseJson(isVerified: false)).isVerified,
          isFalse);
    });

    test('isVerified defaults to false when absent', () {
      final json = _baseJson();
      json.remove('isVerified');
      expect(AdminUserModel.fromJson(json).isVerified, isFalse);
    });

    test('parses isBanned', () {
      expect(
          AdminUserModel.fromJson(_baseJson(isBanned: true)).isBanned, isTrue);
    });

    test('parses banReason', () {
      final m = AdminUserModel.fromJson(_baseJson(banReason: 'cheating'));
      expect(m.banReason, 'cheating');
    });

    test('banReason is null when absent', () {
      expect(AdminUserModel.fromJson(_baseJson()).banReason, isNull);
    });

    test('parses metadata', () {
      final m = AdminUserModel.fromJson(
          _baseJson(metadata: {'region': 'us-east', 'flags': 3}));
      expect(m.metadata!['region'], 'us-east');
    });

    test('metadata is null when absent', () {
      expect(AdminUserModel.fromJson(_baseJson()).metadata, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // AdminUserModel.fromJson — DateTime fields
  // -------------------------------------------------------------------------

  group('AdminUserModel.fromJson — DateTime fields', () {
    test('parses createdAt', () {
      final m = AdminUserModel.fromJson(
          _baseJson(createdAt: '2024-03-10T09:30:00.000Z'));
      expect(m.createdAt.month, 3);
      expect(m.createdAt.day, 10);
    });

    test('parses lastActive', () {
      final m = AdminUserModel.fromJson(
          _baseJson(lastActive: '2025-06-01T15:00:00.000Z'));
      expect(m.lastActive.year, 2025);
    });
  });

  // -------------------------------------------------------------------------
  // AdminUserModel.fromJson — enum parsing
  // -------------------------------------------------------------------------

  group('AdminUserModel.fromJson — UserStatus', () {
    for (final s in UserStatus.values) {
      test('parses status ${s.name}', () {
        expect(AdminUserModel.fromJson(_baseJson(status: s.name)).status, s);
      });
    }

    test('unknown status falls back to offline', () {
      final m = AdminUserModel.fromJson(_baseJson(status: 'invisible'));
      expect(m.status, UserStatus.offline);
    });
  });

  group('AdminUserModel.fromJson — UserRole', () {
    for (final r in UserRole.values) {
      test('parses role ${r.name}', () {
        expect(AdminUserModel.fromJson(_baseJson(role: r.name)).role, r);
      });
    }

    test('unknown role falls back to user', () {
      final m = AdminUserModel.fromJson(_baseJson(role: 'superuser'));
      expect(m.role, UserRole.user);
    });
  });

  group('AdminUserModel.fromJson — AgeGroup', () {
    for (final ag in AgeGroup.values) {
      test('parses ageGroup ${ag.name}', () {
        expect(
            AdminUserModel.fromJson(_baseJson(ageGroup: ag.name)).ageGroup, ag);
      });
    }

    test('unknown ageGroup falls back to adults', () {
      final m = AdminUserModel.fromJson(_baseJson(ageGroup: 'unknown_group'));
      expect(m.ageGroup, AgeGroup.adults);
    });
  });

  // -------------------------------------------------------------------------
  // statusColor / statusText
  // -------------------------------------------------------------------------

  group('AdminUserModel — statusColor', () {
    test('online → green 0xFF10B981', () {
      final m = AdminUserModel.fromJson(_baseJson(status: 'online'));
      expect(m.statusColor, const Color(0xFF10B981));
    });

    test('offline → gray 0xFF6B7280', () {
      final m = AdminUserModel.fromJson(_baseJson(status: 'offline'));
      expect(m.statusColor, const Color(0xFF6B7280));
    });

    test('away → amber 0xFFF59E0B', () {
      final m = AdminUserModel.fromJson(_baseJson(status: 'away'));
      expect(m.statusColor, const Color(0xFFF59E0B));
    });

    test('busy → red 0xFFEF4444', () {
      final m = AdminUserModel.fromJson(_baseJson(status: 'busy'));
      expect(m.statusColor, const Color(0xFFEF4444));
    });
  });

  group('AdminUserModel — statusText', () {
    test('online → "Online"', () {
      expect(AdminUserModel.fromJson(_baseJson(status: 'online')).statusText,
          'Online');
    });

    test('offline → "Offline"', () {
      expect(AdminUserModel.fromJson(_baseJson(status: 'offline')).statusText,
          'Offline');
    });

    test('away → "Away"', () {
      expect(AdminUserModel.fromJson(_baseJson(status: 'away')).statusText,
          'Away');
    });

    test('busy → "Busy"', () {
      expect(AdminUserModel.fromJson(_baseJson(status: 'busy')).statusText,
          'Busy');
    });
  });

  // -------------------------------------------------------------------------
  // roleColor / roleText / roleIcon
  // -------------------------------------------------------------------------

  group('AdminUserModel — roleColor', () {
    test('user → gray 0xFF6B7280', () {
      expect(AdminUserModel.fromJson(_baseJson(role: 'user')).roleColor,
          const Color(0xFF6B7280));
    });

    test('premium → gold 0xFFFFD700', () {
      expect(AdminUserModel.fromJson(_baseJson(role: 'premium')).roleColor,
          const Color(0xFFFFD700));
    });

    test('moderator → blue 0xFF3B82F6', () {
      expect(AdminUserModel.fromJson(_baseJson(role: 'moderator')).roleColor,
          const Color(0xFF3B82F6));
    });

    test('admin → red 0xFFEF4444', () {
      expect(AdminUserModel.fromJson(_baseJson(role: 'admin')).roleColor,
          const Color(0xFFEF4444));
    });
  });

  group('AdminUserModel — roleText', () {
    test('user → "User"', () {
      expect(AdminUserModel.fromJson(_baseJson(role: 'user')).roleText, 'User');
    });

    test('premium → "Premium"', () {
      expect(AdminUserModel.fromJson(_baseJson(role: 'premium')).roleText,
          'Premium');
    });

    test('moderator → "Moderator"', () {
      expect(AdminUserModel.fromJson(_baseJson(role: 'moderator')).roleText,
          'Moderator');
    });

    test('admin → "Admin"', () {
      expect(
          AdminUserModel.fromJson(_baseJson(role: 'admin')).roleText, 'Admin');
    });
  });

  group('AdminUserModel — roleIcon', () {
    test('user → Icons.person', () {
      expect(AdminUserModel.fromJson(_baseJson(role: 'user')).roleIcon,
          Icons.person);
    });

    test('premium → Icons.stars', () {
      expect(AdminUserModel.fromJson(_baseJson(role: 'premium')).roleIcon,
          Icons.stars);
    });

    test('moderator → Icons.shield', () {
      expect(AdminUserModel.fromJson(_baseJson(role: 'moderator')).roleIcon,
          Icons.shield);
    });

    test('admin → Icons.admin_panel_settings', () {
      expect(AdminUserModel.fromJson(_baseJson(role: 'admin')).roleIcon,
          Icons.admin_panel_settings);
    });
  });

  // -------------------------------------------------------------------------
  // ageGroupText / ageGroupColor
  // -------------------------------------------------------------------------

  group('AdminUserModel — ageGroupText', () {
    test('kids → "Child (6-12)"', () {
      expect(AdminUserModel.fromJson(_baseJson(ageGroup: 'kids')).ageGroupText,
          'Child (6-12)');
    });

    test('teens → "Teen (13-17)"', () {
      expect(AdminUserModel.fromJson(_baseJson(ageGroup: 'teens')).ageGroupText,
          'Teen (13-17)');
    });

    test('adults → "Adult (18-64)"', () {
      expect(
          AdminUserModel.fromJson(_baseJson(ageGroup: 'adults')).ageGroupText,
          'Adult (18-64)');
    });

    test('general → "Senior (65+)"', () {
      expect(
          AdminUserModel.fromJson(_baseJson(ageGroup: 'general')).ageGroupText,
          'Senior (65+)');
    });
  });

  group('AdminUserModel — ageGroupColor', () {
    test('kids → purple 0xFF8B5CF6', () {
      expect(AdminUserModel.fromJson(_baseJson(ageGroup: 'kids')).ageGroupColor,
          const Color(0xFF8B5CF6));
    });

    test('teens → blue 0xFF3B82F6', () {
      expect(
          AdminUserModel.fromJson(_baseJson(ageGroup: 'teens')).ageGroupColor,
          const Color(0xFF3B82F6));
    });

    test('adults → green 0xFF10B981', () {
      expect(
          AdminUserModel.fromJson(_baseJson(ageGroup: 'adults')).ageGroupColor,
          const Color(0xFF10B981));
    });

    test('general → amber 0xFFF59E0B', () {
      expect(
          AdminUserModel.fromJson(_baseJson(ageGroup: 'general')).ageGroupColor,
          const Color(0xFFF59E0B));
    });
  });

  // -------------------------------------------------------------------------
  // toJson
  // -------------------------------------------------------------------------

  group('AdminUserModel.toJson', () {
    test('serializes status as name string', () {
      final m = AdminUserModel.fromJson(_baseJson(status: 'away'));
      expect(m.toJson()['status'], 'away');
    });

    test('serializes role as name string', () {
      final m = AdminUserModel.fromJson(_baseJson(role: 'moderator'));
      expect(m.toJson()['role'], 'moderator');
    });

    test('serializes ageGroup as name string', () {
      final m = AdminUserModel.fromJson(_baseJson(ageGroup: 'teens'));
      expect(m.toJson()['ageGroup'], 'teens');
    });

    test('serializes createdAt as ISO string', () {
      final m = AdminUserModel.fromJson(_baseJson());
      expect(m.toJson()['createdAt'], isA<String>());
    });

    test('serializes lastActive as ISO string', () {
      final m = AdminUserModel.fromJson(_baseJson());
      expect(m.toJson()['lastActive'], isA<String>());
    });

    test('round-trip preserves all scalar fields', () {
      final original = AdminUserModel.fromJson(
        _baseJson(
          avatarUrl: 'https://img.test/a.png',
          banReason: 'spamming',
          isBanned: true,
        ),
      );
      final restored = AdminUserModel.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.username, original.username);
      expect(restored.email, original.email);
      expect(restored.avatarUrl, original.avatarUrl);
      expect(restored.status, original.status);
      expect(restored.role, original.role);
      expect(restored.ageGroup, original.ageGroup);
      expect(restored.totalGamesPlayed, original.totalGamesPlayed);
      expect(restored.totalPoints, original.totalPoints);
      expect(restored.winRate, closeTo(original.winRate, 0.001));
      expect(restored.isVerified, original.isVerified);
      expect(restored.isBanned, original.isBanned);
      expect(restored.banReason, original.banReason);
    });
  });

  // -------------------------------------------------------------------------
  // copyWith
  // -------------------------------------------------------------------------

  group('AdminUserModel.copyWith', () {
    late AdminUserModel base;
    setUp(() => base = AdminUserModel.fromJson(_baseJson()));

    test('copies status', () {
      expect(base.copyWith(status: UserStatus.busy).status, UserStatus.busy);
    });

    test('copies role', () {
      expect(base.copyWith(role: UserRole.admin).role, UserRole.admin);
    });

    test('copies ageGroup', () {
      expect(base.copyWith(ageGroup: AgeGroup.kids).ageGroup, AgeGroup.kids);
    });

    test('copies totalPoints', () {
      expect(base.copyWith(totalPoints: 9999).totalPoints, 9999);
    });

    test('copies isBanned + banReason', () {
      final updated = base.copyWith(isBanned: true, banReason: 'cheating');
      expect(updated.isBanned, isTrue);
      expect(updated.banReason, 'cheating');
    });

    test('copies winRate', () {
      final updated = base.copyWith(winRate: 0.99);
      expect(updated.winRate, closeTo(0.99, 0.001));
    });

    test('preserves unchanged fields', () {
      final updated = base.copyWith(totalPoints: 0);
      expect(updated.id, base.id);
      expect(updated.username, base.username);
      expect(updated.email, base.email);
      expect(updated.status, base.status);
    });
  });
}
