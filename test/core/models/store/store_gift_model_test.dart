import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/core/models/store/store_gift_model.dart';

void main() {
  // -------------------------------------------------------------------------
  // resolveColor
  // -------------------------------------------------------------------------

  group('resolveColor', () {
    test('"green" → 0xFF10B981', () {
      expect(resolveColor('green'), const Color(0xFF10B981));
    });

    test('"yellow" → 0xFFF59E0B', () {
      expect(resolveColor('yellow'), const Color(0xFFF59E0B));
    });

    test('"amber" → same as yellow 0xFFF59E0B', () {
      expect(resolveColor('amber'), const Color(0xFFF59E0B));
    });

    test('"red" → 0xFFEF4444', () {
      expect(resolveColor('red'), const Color(0xFFEF4444));
    });

    test('"purple" → 0xFF8B5CF6', () {
      expect(resolveColor('purple'), const Color(0xFF8B5CF6));
    });

    test('"blue" → 0xFF6366F1', () {
      expect(resolveColor('blue'), const Color(0xFF6366F1));
    });

    test('"pink" → 0xFFEC4899', () {
      expect(resolveColor('pink'), const Color(0xFFEC4899));
    });

    test('hex string with # prefix', () {
      expect(resolveColor('#FF0000'), const Color(0xFFFF0000));
    });

    test('hex string without # prefix', () {
      expect(resolveColor('00FF00'), const Color(0xFF00FF00));
    });

    test('null → fallback color', () {
      expect(resolveColor(null), const Color(0xFF6366F1));
    });

    test('empty string → fallback color', () {
      expect(resolveColor(''), const Color(0xFF6366F1));
    });

    test('invalid hex → fallback color', () {
      expect(resolveColor('not_a_color'), const Color(0xFF6366F1));
    });

    test('custom fallback used for null', () {
      expect(
        resolveColor(null, fallback: const Color(0xFFABCDEF)),
        const Color(0xFFABCDEF),
      );
    });
  });

  // -------------------------------------------------------------------------
  // ReceivedGift.fromJson
  // -------------------------------------------------------------------------

  group('ReceivedGift.fromJson', () {
    Map<String, dynamic> _json({
      String id = 'g1',
      String from = 'Alice',
      String? avatarUrl,
      String giftName = 'Energy Pack',
      String icon = 'flash_on',
      String color = 'green',
      String timeLabel = '2 hours ago',
      String? message,
      bool claimed = false,
    }) =>
        {
          'id': id,
          'from': from,
          if (avatarUrl != null) 'avatarUrl': avatarUrl,
          'giftName': giftName,
          'icon': icon,
          'color': color,
          'timeLabel': timeLabel,
          if (message != null) 'message': message,
          'claimed': claimed,
        };

    test('parses id', () {
      expect(ReceivedGift.fromJson(_json(id: 'gift_x')).id, 'gift_x');
    });

    test('parses from', () {
      expect(ReceivedGift.fromJson(_json(from: 'Bob')).from, 'Bob');
    });

    test('parses avatarUrl', () {
      expect(
          ReceivedGift.fromJson(_json(avatarUrl: 'https://img/a.png')).avatarUrl,
          'https://img/a.png');
    });

    test('avatarUrl is null when absent', () {
      expect(ReceivedGift.fromJson(_json()).avatarUrl, isNull);
    });

    test('parses giftName', () {
      expect(ReceivedGift.fromJson(_json(giftName: 'Coins')).giftName, 'Coins');
    });

    test('parses icon', () {
      expect(ReceivedGift.fromJson(_json(icon: 'flash_on')).icon, Icons.flash_on);
    });

    test('unknown icon falls back to card_giftcard', () {
      expect(ReceivedGift.fromJson(_json(icon: 'unknown')).icon,
          Icons.card_giftcard);
    });

    test('parses color via resolveColor', () {
      expect(ReceivedGift.fromJson(_json(color: 'red')).color,
          const Color(0xFFEF4444));
    });

    test('parses timeLabel', () {
      expect(
          ReceivedGift.fromJson(_json(timeLabel: '1 day ago')).timeLabel,
          '1 day ago');
    });

    test('parses message', () {
      expect(ReceivedGift.fromJson(_json(message: 'Good luck!')).message,
          'Good luck!');
    });

    test('message is null when absent', () {
      expect(ReceivedGift.fromJson(_json()).message, isNull);
    });

    test('parses claimed', () {
      expect(ReceivedGift.fromJson(_json(claimed: true)).claimed, isTrue);
    });

    test('claimed defaults to false when absent', () {
      final json = _json();
      json.remove('claimed');
      expect(ReceivedGift.fromJson(json).claimed, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // SendableGift.fromJson
  // -------------------------------------------------------------------------

  group('SendableGift.fromJson', () {
    Map<String, dynamic> _json({
      String id = 'sg1',
      String name = 'Energy Pack',
      String description = '5 refills',
      String icon = 'flash_on',
      String color = 'green',
      String cost = '50 Coins',
    }) =>
        {
          'id': id,
          'name': name,
          'description': description,
          'icon': icon,
          'color': color,
          'cost': cost,
        };

    test('parses id', () {
      expect(SendableGift.fromJson(_json(id: 'sg_x')).id, 'sg_x');
    });

    test('parses name', () {
      expect(SendableGift.fromJson(_json(name: 'Gem Gift')).name, 'Gem Gift');
    });

    test('parses description', () {
      expect(
          SendableGift.fromJson(_json(description: '10 gems')).description,
          '10 gems');
    });

    test('parses icon', () {
      expect(SendableGift.fromJson(_json(icon: 'diamond')).icon, Icons.diamond);
    });

    test('unknown icon falls back to card_giftcard', () {
      expect(SendableGift.fromJson(_json(icon: 'unk')).icon,
          Icons.card_giftcard);
    });

    test('parses cost', () {
      expect(SendableGift.fromJson(_json(cost: '100 Coins')).cost, '100 Coins');
    });

    test('parses color', () {
      expect(SendableGift.fromJson(_json(color: 'purple')).color,
          const Color(0xFF8B5CF6));
    });

    test('defaults for absent optional fields', () {
      final json = <String, dynamic>{'id': 'x'};
      final g = SendableGift.fromJson(json);
      expect(g.name, '');
      expect(g.description, '');
      expect(g.cost, '');
    });
  });

  // -------------------------------------------------------------------------
  // GiftHistoryItem.fromJson
  // -------------------------------------------------------------------------

  group('GiftHistoryItem.fromJson', () {
    Map<String, dynamic> _json({
      String id = 'h1',
      String type = 'sent',
      String to = 'Bob',
      String from = 'Alice',
      String giftName = 'Energy Pack',
      String icon = 'flash_on',
      String color = 'green',
      String timeLabel = '3 hours ago',
      String status = 'Delivered',
    }) =>
        {
          'id': id,
          'type': type,
          'to': to,
          'from': from,
          'giftName': giftName,
          'icon': icon,
          'color': color,
          'timeLabel': timeLabel,
          'status': status,
        };

    test('parses id', () {
      expect(GiftHistoryItem.fromJson(_json(id: 'h99')).id, 'h99');
    });

    test('parses type', () {
      expect(GiftHistoryItem.fromJson(_json(type: 'received')).type, 'received');
    });

    test('type defaults to "sent" when absent', () {
      final json = _json();
      json.remove('type');
      expect(GiftHistoryItem.fromJson(json).type, 'sent');
    });

    test('parses to', () {
      expect(GiftHistoryItem.fromJson(_json(to: 'Charlie')).to, 'Charlie');
    });

    test('parses from', () {
      expect(GiftHistoryItem.fromJson(_json(from: 'Dave')).from, 'Dave');
    });

    test('parses giftName', () {
      expect(
          GiftHistoryItem.fromJson(_json(giftName: '1000 Coins')).giftName,
          '1000 Coins');
    });

    test('parses status', () {
      expect(GiftHistoryItem.fromJson(_json(status: 'Claimed')).status,
          'Claimed');
    });

    test('parses icon', () {
      expect(
          GiftHistoryItem.fromJson(_json(icon: 'monetization_on')).icon,
          Icons.monetization_on);
    });
  });

  // -------------------------------------------------------------------------
  // GiftStats.fromJson
  // -------------------------------------------------------------------------

  group('GiftStats.fromJson', () {
    test('parses string values', () {
      final stats = GiftStats.fromJson(
          {'received': '10', 'sent': '5', 'pending': '2'});
      expect(stats.received, '10');
      expect(stats.sent, '5');
      expect(stats.pending, '2');
    });

    test('coerces int values via toString()', () {
      final stats = GiftStats.fromJson({'received': 10, 'sent': 5, 'pending': 2});
      expect(stats.received, '10');
      expect(stats.sent, '5');
      expect(stats.pending, '2');
    });

    test('defaults all to "0" when absent', () {
      final stats = GiftStats.fromJson({});
      expect(stats.received, '0');
      expect(stats.sent, '0');
      expect(stats.pending, '0');
    });
  });

  // -------------------------------------------------------------------------
  // GiftsData.fromJson
  // -------------------------------------------------------------------------

  group('GiftsData.fromJson', () {
    test('parses stats', () {
      final data = GiftsData.fromJson({
        'stats': {'received': '3', 'sent': '1', 'pending': '0'},
        'received': [],
        'available': [],
        'history': [],
      });
      expect(data.stats.received, '3');
    });

    test('parses received list', () {
      final data = GiftsData.fromJson({
        'received': [
          {
            'id': 'g1',
            'from': 'Alice',
            'giftName': 'Pack',
            'icon': 'flash_on',
            'color': 'green',
            'timeLabel': 'now',
            'claimed': false,
          }
        ],
        'available': [],
        'history': [],
      });
      expect(data.received.length, 1);
      expect(data.received.first.id, 'g1');
    });

    test('parses available (sendable) list', () {
      final data = GiftsData.fromJson({
        'available': [
          {
            'id': 'sg1',
            'name': 'Energy',
            'description': '',
            'icon': 'flash_on',
            'color': 'green',
            'cost': '50',
          }
        ],
        'received': [],
        'history': [],
      });
      expect(data.available.length, 1);
    });

    test('parses history list', () {
      final data = GiftsData.fromJson({
        'history': [
          {
            'id': 'h1',
            'type': 'sent',
            'to': 'Bob',
            'from': 'You',
            'giftName': 'Pack',
            'icon': 'flash_on',
            'color': 'green',
            'timeLabel': '1h',
            'status': 'Delivered',
          }
        ],
        'received': [],
        'available': [],
      });
      expect(data.history.length, 1);
    });

    test('all lists default to empty when absent', () {
      final data = GiftsData.fromJson({});
      expect(data.received, isEmpty);
      expect(data.available, isEmpty);
      expect(data.history, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // GiftsData.fallback
  // -------------------------------------------------------------------------

  group('GiftsData.fallback', () {
    test('has 3 received gifts', () {
      expect(GiftsData.fallback.received.length, 3);
    });

    test('has 4 available gifts', () {
      expect(GiftsData.fallback.available.length, 4);
    });

    test('has 3 history items', () {
      expect(GiftsData.fallback.history.length, 3);
    });

    test('stats are non-zero', () {
      expect(GiftsData.fallback.stats.received, isNot('0'));
    });
  });
}
