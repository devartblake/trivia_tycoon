import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/game/models/mission_model.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Map<String, dynamic> _missionJson({
  String id = 'm1',
  String title = 'Answer 10 questions',
  String? description,
  int progress = 5,
  int total = 10,
  int target = 10,
  int rewardXp = 100,
  String icon = 'star',
  String badge = 'daily',
  String type = 'daily',
  String status = 'active',
  String createdAt = '2025-01-10T00:00:00.000Z',
  String? completedAt,
  String? expiresAt,
  Map<String, dynamic>? metadata,
}) {
  return {
    'id': id,
    'title': title,
    if (description != null) 'description': description,
    'progress': progress,
    'total': total,
    'target': target,
    'rewardXp': rewardXp,
    'icon_name': icon,
    'badge': badge,
    'type': type,
    'status': status,
    'created_at': createdAt,
    if (completedAt != null) 'completed_at': completedAt,
    if (expiresAt != null) 'expires_at': expiresAt,
    if (metadata != null) 'metadata': metadata,
  };
}

Mission _mission({
  String id = 'm1',
  String title = 'Mission 1',
  int progress = 3,
  int total = 5,
  int target = 5,
  int rewardXp = 50,
  MissionType type = MissionType.daily,
  MissionStatus status = MissionStatus.active,
  DateTime? createdAt,
  DateTime? completedAt,
  DateTime? expiresAt,
}) {
  return Mission(
    id: id,
    title: title,
    progress: progress,
    total: total,
    target: target,
    rewardXp: rewardXp,
    icon: Icons.star,
    badge: 'badge',
    type: type,
    status: status,
    createdAt: createdAt ?? DateTime(2025, 1, 1),
    completedAt: completedAt,
    expiresAt: expiresAt,
  );
}

void main() {
  // -------------------------------------------------------------------------
  // Mission.fromJson — basic fields
  // -------------------------------------------------------------------------

  group('Mission.fromJson — scalar fields', () {
    test('parses id', () {
      final m = Mission.fromJson(_missionJson(id: 'mission_99'));
      expect(m.id, 'mission_99');
    });

    test('parses id from missionId fallback', () {
      final json = _missionJson();
      json.remove('id');
      json['missionId'] = 'mid_1';
      final m = Mission.fromJson(json);
      expect(m.id, 'mid_1');
    });

    test('parses title replacing underscores with spaces', () {
      final m = Mission.fromJson(_missionJson(title: 'answer_10_questions'));
      expect(m.title, 'answer 10 questions');
    });

    test('parses title from key/missionKey fallback', () {
      final json = _missionJson();
      json.remove('title');
      json['key'] = 'streak_mission';
      final m = Mission.fromJson(json);
      expect(m.title, 'streak mission');
    });

    test('title defaults to "Mission" when empty', () {
      final json = _missionJson(title: '');
      final m = Mission.fromJson(json);
      expect(m.title, 'Mission');
    });

    test('parses description', () {
      final m = Mission.fromJson(_missionJson(description: 'A test mission'));
      expect(m.description, 'A test mission');
    });

    test('description is null when absent', () {
      final m = Mission.fromJson(_missionJson());
      expect(m.description, isNull);
    });

    test('parses progress', () {
      final m = Mission.fromJson(_missionJson(progress: 7));
      expect(m.progress, 7);
    });

    test('parses total from goal fallback', () {
      final json = _missionJson();
      json.remove('total');
      json['goal'] = 20;
      final m = Mission.fromJson(json);
      expect(m.total, 20);
    });

    test('total defaults to 1 when absent', () {
      final json = _missionJson();
      json.remove('total');
      json.remove('goal');
      json.remove('targetCount');
      final m = Mission.fromJson(json);
      expect(m.total, 1);
    });

    test('parses rewardXp from reward_xp fallback', () {
      final json = _missionJson();
      json.remove('rewardXp');
      json['reward_xp'] = 250;
      final m = Mission.fromJson(json);
      expect(m.rewardXp, 250);
    });

    test('parses badge', () {
      final m = Mission.fromJson(_missionJson(badge: 'weekly'));
      expect(m.badge, 'weekly');
    });
  });

  // -------------------------------------------------------------------------
  // Mission.fromJson — type parsing
  // -------------------------------------------------------------------------

  group('Mission.fromJson — MissionType parsing', () {
    test('daily → MissionType.daily', () {
      expect(Mission.fromJson(_missionJson(type: 'daily')).type,
          MissionType.daily);
    });

    test('weekly → MissionType.weekly', () {
      expect(Mission.fromJson(_missionJson(type: 'weekly')).type,
          MissionType.weekly);
    });

    test('seasonal → MissionType.seasonal', () {
      expect(Mission.fromJson(_missionJson(type: 'seasonal')).type,
          MissionType.seasonal);
    });

    test('one_time → MissionType.oneTime', () {
      expect(Mission.fromJson(_missionJson(type: 'one_time')).type,
          MissionType.oneTime);
    });

    test('onetime → MissionType.oneTime', () {
      expect(Mission.fromJson(_missionJson(type: 'onetime')).type,
          MissionType.oneTime);
    });

    test('one-time → MissionType.oneTime', () {
      expect(Mission.fromJson(_missionJson(type: 'one-time')).type,
          MissionType.oneTime);
    });

    test('unknown string → MissionType.unknown', () {
      expect(Mission.fromJson(_missionJson(type: 'bogus')).type,
          MissionType.unknown);
    });

    test('type from timeframe fallback', () {
      final json = _missionJson();
      json.remove('type');
      json['timeframe'] = 'weekly';
      expect(Mission.fromJson(json).type, MissionType.weekly);
    });
  });

  // -------------------------------------------------------------------------
  // Mission.fromJson — status parsing
  // -------------------------------------------------------------------------

  group('Mission.fromJson — MissionStatus parsing', () {
    test('active → MissionStatus.active', () {
      expect(Mission.fromJson(_missionJson(status: 'active')).status,
          MissionStatus.active);
    });

    test('completed → MissionStatus.completed', () {
      expect(Mission.fromJson(_missionJson(status: 'completed')).status,
          MissionStatus.completed);
    });

    test('complete → MissionStatus.completed', () {
      expect(Mission.fromJson(_missionJson(status: 'complete')).status,
          MissionStatus.completed);
    });

    test('expired → MissionStatus.expired', () {
      expect(Mission.fromJson(_missionJson(status: 'expired')).status,
          MissionStatus.expired);
    });

    test('swapped → MissionStatus.swapped', () {
      expect(Mission.fromJson(_missionJson(status: 'swapped')).status,
          MissionStatus.swapped);
    });

    test('unknown defaults to active', () {
      expect(Mission.fromJson(_missionJson(status: 'xyz')).status,
          MissionStatus.active);
    });
  });

  // -------------------------------------------------------------------------
  // Mission.fromJson — DateTime fields
  // -------------------------------------------------------------------------

  group('Mission.fromJson — DateTime fields', () {
    test('parses createdAt from created_at', () {
      final m =
          Mission.fromJson(_missionJson(createdAt: '2025-03-15T08:00:00.000Z'));
      expect(m.createdAt.month, 3);
      expect(m.createdAt.day, 15);
    });

    test('parses completedAt when present', () {
      final m = Mission.fromJson(
          _missionJson(completedAt: '2025-04-01T12:00:00.000Z'));
      expect(m.completedAt, isNotNull);
      expect(m.completedAt!.month, 4);
    });

    test('completedAt is null when absent', () {
      final m = Mission.fromJson(_missionJson());
      expect(m.completedAt, isNull);
    });

    test('parses expiresAt when present', () {
      final m =
          Mission.fromJson(_missionJson(expiresAt: '2025-12-31T23:59:59.000Z'));
      expect(m.expiresAt, isNotNull);
      expect(m.expiresAt!.year, 2025);
      expect(m.expiresAt!.month, 12);
    });

    test('expiresAt is null when absent', () {
      expect(Mission.fromJson(_missionJson()).expiresAt, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // Mission.fromJson — icon parsing
  // -------------------------------------------------------------------------

  group('Mission.fromJson — icon mapping', () {
    final iconCases = {
      'science': Icons.science,
      'flash_on': Icons.flash_on,
      'explore': Icons.explore,
      'calendar_today': Icons.calendar_today,
      'star': Icons.star,
      'fitness_center': Icons.fitness_center,
      'school': Icons.school,
      'timeline': Icons.timeline,
    };

    for (final entry in iconCases.entries) {
      test('${entry.key} maps to correct IconData', () {
        final m = Mission.fromJson(_missionJson(icon: entry.key));
        expect(m.icon, entry.value);
      });
    }

    test('unknown icon defaults to Icons.assignment', () {
      final m = Mission.fromJson(_missionJson(icon: 'unknown_icon'));
      expect(m.icon, Icons.assignment);
    });
  });

  // -------------------------------------------------------------------------
  // Mission — computed properties
  // -------------------------------------------------------------------------

  group('Mission — isCompleted', () {
    test('true when progress equals total', () {
      expect(_mission(progress: 5, total: 5).isCompleted, isTrue);
    });

    test('true when progress exceeds total', () {
      expect(_mission(progress: 10, total: 5).isCompleted, isTrue);
    });

    test('false when progress is less than total', () {
      expect(_mission(progress: 3, total: 5).isCompleted, isFalse);
    });
  });

  group('Mission — isExpired', () {
    test('false when expiresAt is null', () {
      expect(_mission().isExpired, isFalse);
    });

    test('false when expiresAt is in the future', () {
      final m =
          _mission(expiresAt: DateTime.now().add(const Duration(days: 1)));
      expect(m.isExpired, isFalse);
    });

    test('true when expiresAt is in the past', () {
      final m =
          _mission(expiresAt: DateTime.now().subtract(const Duration(days: 1)));
      expect(m.isExpired, isTrue);
    });
  });

  group('Mission — progressPercentage', () {
    test('returns ratio clamped to [0, 1]', () {
      expect(_mission(progress: 5, total: 10).progressPercentage, 0.5);
    });

    test('clamps to 1.0 when progress exceeds total', () {
      expect(_mission(progress: 20, total: 10).progressPercentage, 1.0);
    });

    test('clamps to 0.0 when progress is 0', () {
      expect(_mission(progress: 0, total: 10).progressPercentage, 0.0);
    });
  });

  // -------------------------------------------------------------------------
  // Mission.toJson
  // -------------------------------------------------------------------------

  group('Mission.toJson', () {
    test('serializes type and status as name strings', () {
      final m =
          _mission(type: MissionType.weekly, status: MissionStatus.completed);
      final json = m.toJson();
      expect(json['type'], 'weekly');
      expect(json['status'], 'completed');
    });

    test('serializes createdAt as ISO string', () {
      final m = _mission(createdAt: DateTime(2025, 6, 15));
      final json = m.toJson();
      expect(json['created_at'], contains('2025'));
    });

    test('completedAt is null in JSON when not set', () {
      final json = _mission().toJson();
      expect(json['completed_at'], isNull);
    });

    test('serializes completedAt as ISO string when set', () {
      final m = _mission(completedAt: DateTime(2025, 2, 1));
      final json = m.toJson();
      expect(json['completed_at'], contains('2025'));
    });
  });

  // -------------------------------------------------------------------------
  // Mission.copyWith
  // -------------------------------------------------------------------------

  group('Mission.copyWith', () {
    test('copies progress', () {
      final updated = _mission(progress: 3).copyWith(progress: 5);
      expect(updated.progress, 5);
    });

    test('copies status', () {
      final updated = _mission().copyWith(status: MissionStatus.completed);
      expect(updated.status, MissionStatus.completed);
    });

    test('copies type', () {
      final updated =
          _mission(type: MissionType.daily).copyWith(type: MissionType.weekly);
      expect(updated.type, MissionType.weekly);
    });

    test('copies rewardXp', () {
      final updated = _mission(rewardXp: 50).copyWith(rewardXp: 200);
      expect(updated.rewardXp, 200);
    });

    test('preserves unchanged fields', () {
      final original = _mission(id: 'orig', title: 'Original', total: 10);
      final updated = original.copyWith(progress: 9);
      expect(updated.id, 'orig');
      expect(updated.title, 'Original');
      expect(updated.total, 10);
    });
  });

  // -------------------------------------------------------------------------
  // UserMission.fromJson
  // -------------------------------------------------------------------------

  group('UserMission.fromJson', () {
    Map<String, dynamic> userMissionJson({
      String id = 'um1',
      String userId = 'user_1',
      String missionId = 'm1',
      int progress = 3,
      String status = 'active',
      String assignedAt = '2025-02-01T00:00:00.000Z',
      int swapCount = 0,
    }) {
      return {
        'id': id,
        'user_id': userId,
        'mission_id': missionId,
        'progress': progress,
        'status': status,
        'assigned_at': assignedAt,
        'swap_count': swapCount,
        'mission': _missionJson(id: missionId),
      };
    }

    test('parses id, userId, missionId', () {
      final um = UserMission.fromJson(userMissionJson(
        id: 'um99',
        userId: 'u42',
        missionId: 'mission_5',
      ));
      expect(um.id, 'um99');
      expect(um.userId, 'u42');
      expect(um.missionId, 'mission_5');
    });

    test('parses progress', () {
      final um = UserMission.fromJson(userMissionJson(progress: 7));
      expect(um.progress, 7);
    });

    test('parses status active', () {
      final um = UserMission.fromJson(userMissionJson(status: 'active'));
      expect(um.status, MissionStatus.active);
    });

    test('sets status to completed when claimed is true', () {
      final json = userMissionJson(status: 'active');
      json['claimed'] = true;
      final um = UserMission.fromJson(json);
      expect(um.status, MissionStatus.completed);
    });

    test('sets status to completed when completed flag is true', () {
      final json = userMissionJson(status: 'active');
      json['completed'] = true;
      final um = UserMission.fromJson(json);
      expect(um.status, MissionStatus.completed);
    });

    test('parses swapCount', () {
      final um = UserMission.fromJson(userMissionJson(swapCount: 2));
      expect(um.swapCount, 2);
    });

    test('parses nested mission', () {
      final um = UserMission.fromJson(userMissionJson(missionId: 'nest_m'));
      expect(um.mission.id, 'nest_m');
    });

    test('parses assignedAt DateTime', () {
      final um = UserMission.fromJson(
          userMissionJson(assignedAt: '2025-05-15T10:00:00.000Z'));
      expect(um.assignedAt.month, 5);
      expect(um.assignedAt.day, 15);
    });
  });

  // -------------------------------------------------------------------------
  // UserMission — computed properties
  // -------------------------------------------------------------------------

  group('UserMission — isCompleted', () {
    test('true when progress >= mission.total', () {
      final m = _mission(total: 5);
      final um = UserMission(
        id: 'u1',
        userId: 'user',
        missionId: 'm1',
        mission: m,
        progress: 5,
        status: MissionStatus.active,
        assignedAt: DateTime(2025, 1, 1),
      );
      expect(um.isCompleted, isTrue);
    });

    test('false when progress < mission.total', () {
      final m = _mission(total: 5);
      final um = UserMission(
        id: 'u2',
        userId: 'user',
        missionId: 'm1',
        mission: m,
        progress: 3,
        status: MissionStatus.active,
        assignedAt: DateTime(2025, 1, 1),
      );
      expect(um.isCompleted, isFalse);
    });
  });

  group('UserMission — canSwap', () {
    test('true when swapCount < 3 and status is active', () {
      final um = UserMission(
        id: 'u3',
        userId: 'user',
        missionId: 'm1',
        mission: _mission(),
        progress: 0,
        status: MissionStatus.active,
        assignedAt: DateTime(2025, 1, 1),
        swapCount: 2,
      );
      expect(um.canSwap, isTrue);
    });

    test('false when swapCount reaches 3', () {
      final um = UserMission(
        id: 'u4',
        userId: 'user',
        missionId: 'm1',
        mission: _mission(),
        progress: 0,
        status: MissionStatus.active,
        assignedAt: DateTime(2025, 1, 1),
        swapCount: 3,
      );
      expect(um.canSwap, isFalse);
    });

    test('false when status is not active', () {
      final um = UserMission(
        id: 'u5',
        userId: 'user',
        missionId: 'm1',
        mission: _mission(),
        progress: 5,
        status: MissionStatus.completed,
        assignedAt: DateTime(2025, 1, 1),
        swapCount: 0,
      );
      expect(um.canSwap, isFalse);
    });
  });

  group('UserMission — progressPercentage', () {
    test('returns ratio based on mission.total', () {
      final m = _mission(total: 10);
      final um = UserMission(
        id: 'u6',
        userId: 'user',
        missionId: 'm1',
        mission: m,
        progress: 4,
        status: MissionStatus.active,
        assignedAt: DateTime(2025, 1, 1),
      );
      expect(um.progressPercentage, 0.4);
    });
  });

  // -------------------------------------------------------------------------
  // UserMission.copyWith
  // -------------------------------------------------------------------------

  group('UserMission.copyWith', () {
    UserMission userMission() => UserMission(
          id: 'um_copy',
          userId: 'user_copy',
          missionId: 'm_copy',
          mission: _mission(),
          progress: 2,
          status: MissionStatus.active,
          assignedAt: DateTime(2025, 3, 1),
          swapCount: 1,
        );

    test('copies progress', () {
      final updated = userMission().copyWith(progress: 9);
      expect(updated.progress, 9);
    });

    test('copies status', () {
      final updated = userMission().copyWith(status: MissionStatus.completed);
      expect(updated.status, MissionStatus.completed);
    });

    test('copies swapCount', () {
      final updated = userMission().copyWith(swapCount: 3);
      expect(updated.swapCount, 3);
    });

    test('preserves unchanged fields', () {
      final original = userMission();
      final updated = original.copyWith(progress: 5);
      expect(updated.id, 'um_copy');
      expect(updated.userId, 'user_copy');
      expect(updated.missionId, 'm_copy');
    });
  });

  // -------------------------------------------------------------------------
  // UserMission.toJson
  // -------------------------------------------------------------------------

  group('UserMission.toJson', () {
    test('serializes status as name string', () {
      final um = UserMission(
        id: 'x',
        userId: 'u',
        missionId: 'm',
        mission: _mission(),
        progress: 3,
        status: MissionStatus.expired,
        assignedAt: DateTime(2025, 1, 1),
      );
      expect(um.toJson()['status'], 'expired');
    });

    test('serializes assignedAt as ISO string', () {
      final um = UserMission(
        id: 'x',
        userId: 'u',
        missionId: 'm',
        mission: _mission(),
        progress: 0,
        status: MissionStatus.active,
        assignedAt: DateTime(2025, 7, 4),
      );
      expect(um.toJson()['assigned_at'], contains('2025'));
    });
  });
}
