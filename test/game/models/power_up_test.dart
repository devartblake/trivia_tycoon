import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/models/power_up.dart';

Map<String, dynamic> _baseJson({
  String id = 'pu1',
  String name = 'XP Boost',
  String description = 'Doubles XP for 30 minutes',
  String iconPath = 'assets/icons/xp_boost.png',
  int duration = 1800,
  int price = 200,
  String currency = 'coins',
  String type = 'xp',
}) =>
    {
      'id': id,
      'name': name,
      'description': description,
      'iconPath': iconPath,
      'duration': duration,
      'price': price,
      'currency': currency,
      'type': type,
    };

void main() {
  // -------------------------------------------------------------------------
  // PowerUp.fromJson
  // -------------------------------------------------------------------------

  group('PowerUp.fromJson — scalar fields', () {
    test('parses id', () {
      expect(PowerUp.fromJson(_baseJson(id: 'pu99')).id, 'pu99');
    });

    test('parses name', () {
      expect(PowerUp.fromJson(_baseJson(name: 'Hint')).name, 'Hint');
    });

    test('parses description', () {
      expect(
          PowerUp.fromJson(_baseJson(description: 'Shows a hint'))
              .description,
          'Shows a hint');
    });

    test('parses iconPath', () {
      expect(
          PowerUp.fromJson(_baseJson(iconPath: 'assets/hint.png')).iconPath,
          'assets/hint.png');
    });

    test('iconPath falls back to icon field', () {
      final json = _baseJson();
      json.remove('iconPath');
      json['icon'] = 'assets/fallback.png';
      expect(PowerUp.fromJson(json).iconPath, 'assets/fallback.png');
    });

    test('iconPath defaults to "" when both absent', () {
      final json = _baseJson();
      json.remove('iconPath');
      expect(PowerUp.fromJson(json).iconPath, '');
    });

    test('parses duration', () {
      expect(PowerUp.fromJson(_baseJson(duration: 3600)).duration, 3600);
    });

    test('duration falls back to cooldown_seconds', () {
      final json = _baseJson();
      json.remove('duration');
      json['cooldown_seconds'] = 120;
      expect(PowerUp.fromJson(json).duration, 120);
    });

    test('duration defaults to 60 when both absent', () {
      final json = _baseJson();
      json.remove('duration');
      expect(PowerUp.fromJson(json).duration, 60);
    });

    test('parses price', () {
      expect(PowerUp.fromJson(_baseJson(price: 500)).price, 500);
    });

    test('price falls back to cost_coins', () {
      final json = _baseJson();
      json.remove('price');
      json['cost_coins'] = 150;
      expect(PowerUp.fromJson(json).price, 150);
    });

    test('price falls back to cost_diamonds', () {
      final json = _baseJson();
      json.remove('price');
      json['cost_diamonds'] = 10;
      expect(PowerUp.fromJson(json).price, 10);
    });

    test('price defaults to 0 when all absent', () {
      final json = _baseJson();
      json.remove('price');
      expect(PowerUp.fromJson(json).price, 0);
    });

    test('currency is "diamonds" when cost_diamonds present', () {
      final json = _baseJson();
      json.remove('price');
      json['cost_diamonds'] = 10;
      expect(PowerUp.fromJson(json).currency, 'diamonds');
    });

    test('currency is "coins" when cost_diamonds absent', () {
      expect(PowerUp.fromJson(_baseJson()).currency, 'coins');
    });

    test('parses type', () {
      expect(PowerUp.fromJson(_baseJson(type: 'shield')).type, 'shield');
    });

    test('type defaults to "boost" when absent', () {
      final json = _baseJson();
      json.remove('type');
      expect(PowerUp.fromJson(json).type, 'boost');
    });
  });

  // -------------------------------------------------------------------------
  // PowerUp.none factory
  // -------------------------------------------------------------------------

  group('PowerUp.none factory', () {
    test('id is "none"', () {
      expect(PowerUp.none().id, 'none');
    });

    test('isNone is true', () {
      expect(PowerUp.none().isNone, isTrue);
    });

    test('price is 0', () {
      expect(PowerUp.none().price, 0);
    });

    test('duration is 0', () {
      expect(PowerUp.none().duration, 0);
    });
  });

  // -------------------------------------------------------------------------
  // PowerUp — isNone
  // -------------------------------------------------------------------------

  group('PowerUp — isNone', () {
    test('false for regular power-up', () {
      expect(PowerUp.fromJson(_baseJson()).isNone, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // PowerUp — isActive
  // -------------------------------------------------------------------------

  group('PowerUp — isActive', () {
    test('true when remainingTime > 0', () {
      expect(PowerUp.fromJson(_baseJson()).isActive(10), isTrue);
    });

    test('false when remainingTime is 0', () {
      expect(PowerUp.fromJson(_baseJson()).isActive(0), isFalse);
    });

    test('false when remainingTime is null', () {
      expect(PowerUp.fromJson(_baseJson()).isActive(null), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // PowerUp — formattedDuration
  // -------------------------------------------------------------------------

  group('PowerUp — formattedDuration', () {
    test('shows seconds only when < 60s', () {
      final pu = PowerUp.fromJson(_baseJson(duration: 45));
      expect(pu.formattedDuration, '45s');
    });

    test('shows minutes and seconds for 90s', () {
      final pu = PowerUp.fromJson(_baseJson(duration: 90));
      expect(pu.formattedDuration, '1m 30s');
    });

    test('shows 0s for duration 0', () {
      final pu = PowerUp.fromJson(_baseJson(duration: 0));
      expect(pu.formattedDuration, '0s');
    });

    test('shows minutes and 0 seconds for exact minutes', () {
      final pu = PowerUp.fromJson(_baseJson(duration: 120));
      expect(pu.formattedDuration, '2m 0s');
    });

    test('shows 30m 0s for 1800 seconds', () {
      final pu = PowerUp.fromJson(_baseJson(duration: 1800));
      expect(pu.formattedDuration, '30m 0s');
    });
  });

  // -------------------------------------------------------------------------
  // PowerUp.toJson
  // -------------------------------------------------------------------------

  group('PowerUp.toJson', () {
    test('serializes all fields', () {
      final pu = PowerUp.fromJson(_baseJson());
      final json = pu.toJson();
      expect(json['id'], pu.id);
      expect(json['name'], pu.name);
      expect(json['description'], pu.description);
      expect(json['iconPath'], pu.iconPath);
      expect(json['duration'], pu.duration);
      expect(json['price'], pu.price);
      expect(json['currency'], pu.currency);
      expect(json['type'], pu.type);
    });

    test('round-trip preserves all fields', () {
      final original = PowerUp.fromJson(_baseJson());
      final restored = PowerUp.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.duration, original.duration);
      expect(restored.price, original.price);
      expect(restored.type, original.type);
    });
  });

  // -------------------------------------------------------------------------
  // PowerUp.copyWith
  // -------------------------------------------------------------------------

  group('PowerUp.copyWith', () {
    late PowerUp base;
    setUp(() => base = PowerUp.fromJson(_baseJson()));

    test('copies name', () {
      expect(base.copyWith(name: 'Shield').name, 'Shield');
    });

    test('copies duration', () {
      expect(base.copyWith(duration: 600).duration, 600);
    });

    test('copies price', () {
      expect(base.copyWith(price: 999).price, 999);
    });

    test('copies type', () {
      expect(base.copyWith(type: 'eliminate').type, 'eliminate');
    });

    test('copies currency', () {
      expect(base.copyWith(currency: 'diamonds').currency, 'diamonds');
    });

    test('preserves unchanged fields', () {
      final updated = base.copyWith(price: 1);
      expect(updated.id, base.id);
      expect(updated.name, base.name);
      expect(updated.type, base.type);
    });
  });

  // -------------------------------------------------------------------------
  // PowerUp equality
  // -------------------------------------------------------------------------

  group('PowerUp — equality', () {
    test('equal when id, name, type, duration match', () {
      final a = PowerUp.fromJson(_baseJson());
      final b = PowerUp.fromJson(_baseJson());
      expect(a, equals(b));
    });

    test('not equal when id differs', () {
      final a = PowerUp.fromJson(_baseJson(id: 'pu1'));
      final b = PowerUp.fromJson(_baseJson(id: 'pu2'));
      expect(a, isNot(equals(b)));
    });

    test('not equal when duration differs', () {
      final a = PowerUp.fromJson(_baseJson(duration: 60));
      final b = PowerUp.fromJson(_baseJson(duration: 120));
      expect(a, isNot(equals(b)));
    });

    test('hashCode equal for equal objects', () {
      final a = PowerUp.fromJson(_baseJson());
      final b = PowerUp.fromJson(_baseJson());
      expect(a.hashCode, b.hashCode);
    });
  });
}
