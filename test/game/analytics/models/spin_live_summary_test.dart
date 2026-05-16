import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/analytics/models/spin_live_summary.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _snapshotIso = '2026-01-01T12:00:00.000Z';
final _snapshotDt = DateTime.utc(2026, 1, 1, 12, 0, 0);

Map<String, dynamic> _fullMap() => {
      'today_count': 3,
      'daily_limit': 10,
      'weekly_count': 15,
      'total_spins': 120,
      'can_spin': true,
      'spins_remaining': 7,
      'reward_points': 4.5,
      'user_name': 'Alice',
      'user_id': 'u1',
      'snapshot_at': _snapshotIso,
    };

SpinLiveSummary _fromFull() => SpinLiveSummary.fromMap(
      _fullMap(),
      fallbackUserName: 'Fallback',
      fallbackUserId: 'fb-id',
      source: 'test',
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  // fromMap — normal fields
  // -------------------------------------------------------------------------

  group('SpinLiveSummary.fromMap — all fields present', () {
    test('parses todayCount', () => expect(_fromFull().todayCount, 3));
    test('parses dailyLimit', () => expect(_fromFull().dailyLimit, 10));
    test('parses weeklyCount', () => expect(_fromFull().weeklyCount, 15));
    test('parses totalSpins', () => expect(_fromFull().totalSpins, 120));
    test('parses canSpin', () => expect(_fromFull().canSpin, isTrue));
    test('parses spinsRemaining', () => expect(_fromFull().spinsRemaining, 7));
    test('parses rewardPoints', () => expect(_fromFull().rewardPoints, 4.5));
    test('parses userName from map', () => expect(_fromFull().userName, 'Alice'));
    test('parses userId from map', () => expect(_fromFull().userId, 'u1'));
    test('source comes from factory parameter', () => expect(_fromFull().source, 'test'));
    test('parses snapshotAt from snapshot_at key', () {
      expect(_fromFull().snapshotAt, _snapshotDt);
    });
  });

  // -------------------------------------------------------------------------
  // fromMap — defaults when fields absent
  // -------------------------------------------------------------------------

  group('SpinLiveSummary.fromMap — missing fields default to 0/false', () {
    late SpinLiveSummary empty;
    setUp(() {
      empty = SpinLiveSummary.fromMap(
        {'snapshot_at': _snapshotIso},
        fallbackUserName: 'FB',
        fallbackUserId: 'fb',
        source: 's',
      );
    });

    test('todayCount defaults to 0', () => expect(empty.todayCount, 0));
    test('dailyLimit defaults to 0', () => expect(empty.dailyLimit, 0));
    test('weeklyCount defaults to 0', () => expect(empty.weeklyCount, 0));
    test('totalSpins defaults to 0', () => expect(empty.totalSpins, 0));
    test('canSpin defaults to false', () => expect(empty.canSpin, isFalse));
    test('spinsRemaining defaults to 0', () => expect(empty.spinsRemaining, 0));
    test('rewardPoints defaults to 0', () => expect(empty.rewardPoints, 0.0));
  });

  // -------------------------------------------------------------------------
  // fromMap — userName/userId fallback logic
  // -------------------------------------------------------------------------

  group('SpinLiveSummary.fromMap — userName fallback', () {
    test('uses map user_name when non-empty', () {
      final s = SpinLiveSummary.fromMap(
        {..._fullMap(), 'user_name': 'RealName'},
        fallbackUserName: 'Fallback',
        fallbackUserId: 'fb',
        source: 's',
      );
      expect(s.userName, 'RealName');
    });

    test('uses fallbackUserName when user_name is null', () {
      final map = {..._fullMap()}..remove('user_name');
      final s = SpinLiveSummary.fromMap(
        map,
        fallbackUserName: 'FallbackUser',
        fallbackUserId: 'fb',
        source: 's',
      );
      expect(s.userName, 'FallbackUser');
    });

    test('uses fallbackUserName when user_name is empty string', () {
      final s = SpinLiveSummary.fromMap(
        {..._fullMap(), 'user_name': ''},
        fallbackUserName: 'FallbackUser',
        fallbackUserId: 'fb',
        source: 's',
      );
      expect(s.userName, 'FallbackUser');
    });

    test('uses fallbackUserName when user_name is whitespace only', () {
      final s = SpinLiveSummary.fromMap(
        {..._fullMap(), 'user_name': '   '},
        fallbackUserName: 'FallbackUser',
        fallbackUserId: 'fb',
        source: 's',
      );
      expect(s.userName, 'FallbackUser');
    });

    test('uses fallbackUserId when user_id is absent', () {
      final map = {..._fullMap()}..remove('user_id');
      final s = SpinLiveSummary.fromMap(
        map,
        fallbackUserName: 'FB',
        fallbackUserId: 'fallback-uid',
        source: 's',
      );
      expect(s.userId, 'fallback-uid');
    });
  });

  // -------------------------------------------------------------------------
  // fromMap — timestamp key priority
  // -------------------------------------------------------------------------

  group('SpinLiveSummary.fromMap — timestamp key priority', () {
    test('snapshot_at takes precedence over timestamp', () {
      final s = SpinLiveSummary.fromMap(
        {
          'snapshot_at': '2026-01-01T12:00:00.000Z',
          'timestamp': '2026-06-01T00:00:00.000Z',
        },
        fallbackUserName: 'FB',
        fallbackUserId: 'fb',
        source: 's',
      );
      expect(s.snapshotAt, DateTime.utc(2026, 1, 1, 12));
    });

    test('falls back to timestamp when snapshot_at absent', () {
      final s = SpinLiveSummary.fromMap(
        {'timestamp': '2026-03-01T00:00:00.000Z'},
        fallbackUserName: 'FB',
        fallbackUserId: 'fb',
        source: 's',
      );
      expect(s.snapshotAt, DateTime.utc(2026, 3, 1));
    });

    test('falls back to date when snapshot_at and timestamp absent', () {
      final s = SpinLiveSummary.fromMap(
        {'date': '2026-07-04T00:00:00.000Z'},
        fallbackUserName: 'FB',
        fallbackUserId: 'fb',
        source: 's',
      );
      expect(s.snapshotAt, DateTime.utc(2026, 7, 4));
    });

    test('snapshotAt is non-null when no timestamp key present (uses DateTime.now())', () {
      final before = DateTime.now();
      final s = SpinLiveSummary.fromMap(
        {},
        fallbackUserName: 'FB',
        fallbackUserId: 'fb',
        source: 's',
      );
      expect(s.snapshotAt.isAfter(before.subtract(const Duration(seconds: 2))), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // toMap
  // -------------------------------------------------------------------------

  group('SpinLiveSummary.toMap', () {
    test('includes all 10 keys', () {
      final keys = _fromFull().toMap().keys.toSet();
      expect(
        keys,
        containsAll([
          'today_count', 'daily_limit', 'weekly_count', 'total_spins',
          'can_spin', 'spins_remaining', 'reward_points',
          'user_name', 'user_id', 'snapshot_at', 'source',
        ]),
      );
    });

    test('snapshot_at is ISO8601 string', () {
      final map = _fromFull().toMap();
      expect(() => DateTime.parse(map['snapshot_at'] as String), returnsNormally);
    });

    test('round-trip preserves numeric fields', () {
      final original = _fromFull();
      final restored = SpinLiveSummary.fromMap(
        original.toMap(),
        fallbackUserName: 'x',
        fallbackUserId: 'y',
        source: 'test',
      );
      expect(restored.todayCount, original.todayCount);
      expect(restored.dailyLimit, original.dailyLimit);
      expect(restored.weeklyCount, original.weeklyCount);
      expect(restored.totalSpins, original.totalSpins);
      expect(restored.rewardPoints, original.rewardPoints);
    });
  });

  // -------------------------------------------------------------------------
  // dedupeKey
  // -------------------------------------------------------------------------

  group('SpinLiveSummary.dedupeKey', () {
    test('contains todayCount, dailyLimit, source as substrings', () {
      final key = _fromFull().dedupeKey;
      expect(key, contains('3'));
      expect(key, contains('10'));
      expect(key, contains('test'));
    });

    test('two summaries with same data produce the same dedupeKey', () {
      expect(_fromFull().dedupeKey, _fromFull().dedupeKey);
    });

    test('different todayCount produces different dedupeKey', () {
      final a = _fromFull();
      final b = SpinLiveSummary.fromMap(
        {..._fullMap(), 'today_count': 99},
        fallbackUserName: 'Fallback',
        fallbackUserId: 'fb-id',
        source: 'test',
      );
      expect(a.dedupeKey, isNot(b.dedupeKey));
    });

    test('different source produces different dedupeKey', () {
      final a = SpinLiveSummary.fromMap(
        _fullMap(),
        fallbackUserName: 'FB',
        fallbackUserId: 'fb',
        source: 'source-a',
      );
      final b = SpinLiveSummary.fromMap(
        _fullMap(),
        fallbackUserName: 'FB',
        fallbackUserId: 'fb',
        source: 'source-b',
      );
      expect(a.dedupeKey, isNot(b.dedupeKey));
    });
  });
}
