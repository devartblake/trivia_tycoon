import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/core/dto/player_dto.dart';

void main() {
  // -------------------------------------------------------------------------
  // WalletDto
  // -------------------------------------------------------------------------

  group('WalletDto construction', () {
    test('stores coins', () {
      const w = WalletDto(coins: 100, gems: 5);
      expect(w.coins, 100);
    });

    test('stores gems', () {
      const w = WalletDto(coins: 0, gems: 20);
      expect(w.gems, 20);
    });
  });

  group('WalletDto.fromJson', () {
    test('parses coins', () {
      final w = WalletDto.fromJson({'coins': 250, 'gems': 10});
      expect(w.coins, 250);
    });

    test('parses gems', () {
      final w = WalletDto.fromJson({'coins': 0, 'gems': 7});
      expect(w.gems, 7);
    });

    test('coins defaults 0 when absent', () {
      final w = WalletDto.fromJson({'gems': 3});
      expect(w.coins, 0);
    });

    test('gems defaults 0 when absent', () {
      final w = WalletDto.fromJson({'coins': 50});
      expect(w.gems, 0);
    });

    test('empty map gives coins=0 gems=0', () {
      final w = WalletDto.fromJson({});
      expect(w.coins, 0);
      expect(w.gems, 0);
    });
  });

  group('WalletDto.toJson', () {
    test('contains coins key', () {
      expect(const WalletDto(coins: 5, gems: 2).toJson()['coins'], 5);
    });

    test('contains gems key', () {
      expect(const WalletDto(coins: 0, gems: 9).toJson()['gems'], 9);
    });

    test('round-trip preserves coins and gems', () {
      const w = WalletDto(coins: 300, gems: 15);
      final w2 = WalletDto.fromJson(w.toJson());
      expect(w2.coins, 300);
      expect(w2.gems, 15);
    });
  });

  // -------------------------------------------------------------------------
  // PlayerDto
  // -------------------------------------------------------------------------

  Map<String, dynamic> _fullPlayerJson() => {
        'id': 'p1',
        'username': 'alice',
        'email': 'alice@example.com',
        'handle': '@alice',
        'avatarUrl': 'https://example.com/avatar.png',
        'country': 'US',
        'ageGroup': 'adults',
        'role': 'user',
        'wallet': {'coins': 200, 'gems': 10},
        'xp': 1500,
        'level': 5,
        'createdAt': '2024-01-15T12:00:00.000Z',
      };

  group('PlayerDto.fromJson', () {
    test('parses id', () {
      expect(PlayerDto.fromJson(_fullPlayerJson()).id, 'p1');
    });

    test('parses username', () {
      expect(PlayerDto.fromJson(_fullPlayerJson()).username, 'alice');
    });

    test('parses email', () {
      expect(PlayerDto.fromJson(_fullPlayerJson()).email, 'alice@example.com');
    });

    test('parses handle', () {
      expect(PlayerDto.fromJson(_fullPlayerJson()).handle, '@alice');
    });

    test('parses avatarUrl', () {
      expect(PlayerDto.fromJson(_fullPlayerJson()).avatarUrl,
          'https://example.com/avatar.png');
    });

    test('parses country', () {
      expect(PlayerDto.fromJson(_fullPlayerJson()).country, 'US');
    });

    test('parses ageGroup', () {
      expect(PlayerDto.fromJson(_fullPlayerJson()).ageGroup, 'adults');
    });

    test('parses role', () {
      expect(PlayerDto.fromJson(_fullPlayerJson()).role, 'user');
    });

    test('parses xp', () {
      expect(PlayerDto.fromJson(_fullPlayerJson()).xp, 1500);
    });

    test('parses level', () {
      expect(PlayerDto.fromJson(_fullPlayerJson()).level, 5);
    });

    test('avatarUrl null when absent', () {
      final j = Map<String, dynamic>.from(_fullPlayerJson())
        ..remove('avatarUrl');
      expect(PlayerDto.fromJson(j).avatarUrl, isNull);
    });

    test('country null when absent', () {
      final j = Map<String, dynamic>.from(_fullPlayerJson())
        ..remove('country');
      expect(PlayerDto.fromJson(j).country, isNull);
    });

    test('ageGroup defaults general when absent', () {
      final j = Map<String, dynamic>.from(_fullPlayerJson())
        ..remove('ageGroup');
      expect(PlayerDto.fromJson(j).ageGroup, 'general');
    });

    test('role defaults user when absent', () {
      final j = Map<String, dynamic>.from(_fullPlayerJson())..remove('role');
      expect(PlayerDto.fromJson(j).role, 'user');
    });

    test('wallet deserialized as WalletDto', () {
      final p = PlayerDto.fromJson(_fullPlayerJson());
      expect(p.wallet, isA<WalletDto>());
      expect(p.wallet.coins, 200);
      expect(p.wallet.gems, 10);
    });

    test('wallet from missing key defaults to empty wallet', () {
      final j = Map<String, dynamic>.from(_fullPlayerJson())..remove('wallet');
      final p = PlayerDto.fromJson(j);
      expect(p.wallet.coins, 0);
      expect(p.wallet.gems, 0);
    });

    test('createdAt parsed from ISO string', () {
      final p = PlayerDto.fromJson(_fullPlayerJson());
      expect(p.createdAt, isA<DateTime>());
      expect(p.createdAt.year, 2024);
    });

    test('invalid createdAt falls back to a DateTime', () {
      final j = Map<String, dynamic>.from(_fullPlayerJson())
        ..['createdAt'] = 'not-a-date';
      final p = PlayerDto.fromJson(j);
      expect(p.createdAt, isA<DateTime>());
    });
  });

  group('PlayerDto.toJson', () {
    test('contains id', () {
      expect(PlayerDto.fromJson(_fullPlayerJson()).toJson()['id'], 'p1');
    });

    test('contains username', () {
      expect(PlayerDto.fromJson(_fullPlayerJson()).toJson()['username'], 'alice');
    });

    test('wallet serialized as nested map', () {
      final j = PlayerDto.fromJson(_fullPlayerJson()).toJson();
      expect(j['wallet'], isA<Map>());
      expect((j['wallet'] as Map)['coins'], 200);
    });

    test('createdAt serialized as ISO string', () {
      final j = PlayerDto.fromJson(_fullPlayerJson()).toJson();
      expect(j['createdAt'], isA<String>());
      expect((j['createdAt'] as String).contains('2024'), isTrue);
    });

    test('avatarUrl present (possibly null) in toJson', () {
      final j = PlayerDto.fromJson(_fullPlayerJson()).toJson();
      expect(j.containsKey('avatarUrl'), isTrue);
    });

    test('country present (possibly null) in toJson', () {
      final j = PlayerDto.fromJson(_fullPlayerJson()).toJson();
      expect(j.containsKey('country'), isTrue);
    });
  });
}
