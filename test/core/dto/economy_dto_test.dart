import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/core/dto/economy_dto.dart';

void main() {
  // -------------------------------------------------------------------------
  // ModeCostDto
  // -------------------------------------------------------------------------

  group('ModeCostDto construction', () {
    test('stores mode', () {
      final d = ModeCostDto(
          mode: 'solo', costType: 'energy', baseCost: 5, available: true);
      expect(d.mode, 'solo');
    });

    test('stores costType', () {
      final d = ModeCostDto(
          mode: 'ranked', costType: 'ticket', baseCost: 1, available: true);
      expect(d.costType, 'ticket');
    });

    test('stores baseCost', () {
      final d = ModeCostDto(
          mode: 'solo', costType: 'energy', baseCost: 10, available: false);
      expect(d.baseCost, 10);
    });

    test('adjustedCost defaults null', () {
      final d = ModeCostDto(
          mode: 'solo', costType: 'energy', baseCost: 5, available: true);
      expect(d.adjustedCost, isNull);
    });

    test('stores adjustedCost when provided', () {
      final d = ModeCostDto(
          mode: 'solo', costType: 'energy', baseCost: 5, available: true,
          adjustedCost: 3);
      expect(d.adjustedCost, 3);
    });
  });

  group('ModeCostDto.effectiveCost', () {
    test('returns baseCost when adjustedCost is null', () {
      final d = ModeCostDto(
          mode: 'x', costType: 'energy', baseCost: 8, available: true);
      expect(d.effectiveCost, 8);
    });

    test('returns adjustedCost when non-null', () {
      final d = ModeCostDto(
          mode: 'x', costType: 'energy', baseCost: 8, available: true,
          adjustedCost: 4);
      expect(d.effectiveCost, 4);
    });
  });

  group('ModeCostDto.hasDiscount', () {
    test('false when adjustedCost is null', () {
      final d = ModeCostDto(
          mode: 'x', costType: 'energy', baseCost: 5, available: true);
      expect(d.hasDiscount, isFalse);
    });

    test('true when adjustedCost < baseCost', () {
      final d = ModeCostDto(
          mode: 'x', costType: 'energy', baseCost: 10, available: true,
          adjustedCost: 7);
      expect(d.hasDiscount, isTrue);
    });

    test('false when adjustedCost == baseCost', () {
      final d = ModeCostDto(
          mode: 'x', costType: 'energy', baseCost: 5, available: true,
          adjustedCost: 5);
      expect(d.hasDiscount, isFalse);
    });

    test('false when adjustedCost > baseCost', () {
      final d = ModeCostDto(
          mode: 'x', costType: 'energy', baseCost: 5, available: true,
          adjustedCost: 8);
      expect(d.hasDiscount, isFalse);
    });
  });

  group('ModeCostDto.fromJson', () {
    test('parses mode', () {
      final d = ModeCostDto.fromJson(
          {'mode': 'duo', 'costType': 'energy', 'baseCost': 3, 'available': true});
      expect(d.mode, 'duo');
    });

    test('parses costType', () {
      final d = ModeCostDto.fromJson(
          {'mode': 'x', 'costType': 'ticket', 'baseCost': 1, 'available': true});
      expect(d.costType, 'ticket');
    });

    test('available defaults true when absent', () {
      final d = ModeCostDto.fromJson({'mode': 'x', 'baseCost': 2});
      expect(d.available, isTrue);
    });

    test('costType defaults energy when absent', () {
      final d = ModeCostDto.fromJson({'mode': 'x', 'baseCost': 2});
      expect(d.costType, 'energy');
    });

    test('adjustedCost null when absent', () {
      final d = ModeCostDto.fromJson({'mode': 'x', 'baseCost': 5});
      expect(d.adjustedCost, isNull);
    });

    test('parses adjustedCost when present', () {
      final d = ModeCostDto.fromJson(
          {'mode': 'x', 'baseCost': 5, 'adjustedCost': 3});
      expect(d.adjustedCost, 3);
    });
  });

  group('ModeCostDto.toJson', () {
    test('mode always present', () {
      final j = ModeCostDto(
          mode: 'solo', costType: 'energy', baseCost: 5, available: true)
          .toJson();
      expect(j['mode'], 'solo');
    });

    test('adjustedCost omitted when null', () {
      final j = ModeCostDto(
          mode: 'x', costType: 'energy', baseCost: 5, available: true)
          .toJson();
      expect(j.containsKey('adjustedCost'), isFalse);
    });

    test('adjustedCost included when non-null', () {
      final j = ModeCostDto(
          mode: 'x', costType: 'energy', baseCost: 5, available: true,
          adjustedCost: 3)
          .toJson();
      expect(j['adjustedCost'], 3);
    });

    test('round-trip with adjustedCost', () {
      final d = ModeCostDto(
          mode: 'pvp', costType: 'ticket', baseCost: 2, available: false,
          adjustedCost: 1);
      final d2 = ModeCostDto.fromJson(d.toJson());
      expect(d2.mode, d.mode);
      expect(d2.adjustedCost, d.adjustedCost);
    });

    test('round-trip without adjustedCost', () {
      final d = ModeCostDto(
          mode: 'solo', costType: 'energy', baseCost: 8, available: true);
      final d2 = ModeCostDto.fromJson(d.toJson());
      expect(d2.baseCost, 8);
      expect(d2.adjustedCost, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // EconomyStateDto
  // -------------------------------------------------------------------------

  group('EconomyStateDto', () {
    Map<String, dynamic> _fullJson() => {
          'energy': 20,
          'maxEnergy': 50,
          'regenIntervalMinutes': 30,
          'firstSessionDiscount': true,
          'dailyTicketAvailable': false,
          'dailyTicketsRemaining': 3,
          'pityActive': false,
          'modes': {
            'solo': {
              'mode': 'solo',
              'costType': 'energy',
              'baseCost': 5,
              'available': true
            },
          },
        };

    test('fromJson parses energy', () {
      expect(EconomyStateDto.fromJson(_fullJson()).energy, 20);
    });

    test('fromJson parses maxEnergy', () {
      expect(EconomyStateDto.fromJson(_fullJson()).maxEnergy, 50);
    });

    test('fromJson parses regenIntervalMinutes', () {
      expect(EconomyStateDto.fromJson(_fullJson()).regenIntervalMinutes, 30);
    });

    test('fromJson parses firstSessionDiscount true', () {
      expect(EconomyStateDto.fromJson(_fullJson()).firstSessionDiscount, isTrue);
    });

    test('fromJson parses modes map into ModeCostDto objects', () {
      final dto = EconomyStateDto.fromJson(_fullJson());
      expect(dto.modes['solo'], isA<ModeCostDto>());
      expect(dto.modes['solo']!.baseCost, 5);
    });

    test('fromJson with empty modes gives empty map', () {
      final j = Map<String, dynamic>.from(_fullJson())..['modes'] = {};
      expect(EconomyStateDto.fromJson(j).modes, isEmpty);
    });

    test('toJson contains energy key', () {
      expect(EconomyStateDto.fromJson(_fullJson()).toJson()['energy'], 20);
    });

    test('toJson serializes modes map back to nested maps', () {
      final j = EconomyStateDto.fromJson(_fullJson()).toJson();
      expect(j['modes'], isA<Map>());
      expect((j['modes'] as Map)['solo'], isA<Map>());
    });
  });

  // -------------------------------------------------------------------------
  // SessionStartDto
  // -------------------------------------------------------------------------

  group('SessionStartDto', () {
    test('fromJson discountApplied defaults false when absent', () {
      final d = SessionStartDto.fromJson({});
      expect(d.discountApplied, isFalse);
    });

    test('fromJson parses discountApplied true', () {
      final d = SessionStartDto.fromJson({'discountApplied': true});
      expect(d.discountApplied, isTrue);
    });

    test('fromJson adjustedCosts empty when absent', () {
      final d = SessionStartDto.fromJson({});
      expect(d.adjustedCosts, isEmpty);
    });

    test('fromJson parses adjustedCosts map', () {
      final d = SessionStartDto.fromJson({
        'discountApplied': true,
        'adjustedCosts': {
          'solo': {'mode': 'solo', 'costType': 'energy', 'baseCost': 3, 'available': true},
        },
      });
      expect(d.adjustedCosts['solo'], isA<ModeCostDto>());
    });

    test('toJson contains discountApplied', () {
      final d = const SessionStartDto(discountApplied: true, adjustedCosts: {});
      expect(d.toJson()['discountApplied'], isTrue);
    });

    test('toJson contains adjustedCosts', () {
      final d = const SessionStartDto(discountApplied: false, adjustedCosts: {});
      expect(d.toJson().containsKey('adjustedCosts'), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // DailyTicketClaimDto
  // -------------------------------------------------------------------------

  group('DailyTicketClaimDto', () {
    test('fromJson success defaults false', () {
      final d = DailyTicketClaimDto.fromJson({});
      expect(d.success, isFalse);
    });

    test('fromJson ticketsRemaining defaults 0', () {
      final d = DailyTicketClaimDto.fromJson({});
      expect(d.ticketsRemaining, 0);
    });

    test('fromJson denyReason null when absent', () {
      final d = DailyTicketClaimDto.fromJson({});
      expect(d.denyReason, isNull);
    });

    test('fromJson parses denyReason', () {
      final d = DailyTicketClaimDto.fromJson({'denyReason': 'already claimed'});
      expect(d.denyReason, 'already claimed');
    });

    test('toJson success present', () {
      final d =
          DailyTicketClaimDto.fromJson({'success': true, 'ticketsRemaining': 2});
      expect(d.toJson()['success'], isTrue);
    });

    test('toJson denyReason omitted when null', () {
      final d = DailyTicketClaimDto.fromJson({'success': false});
      expect(d.toJson().containsKey('denyReason'), isFalse);
    });

    test('toJson denyReason included when non-null', () {
      final d =
          DailyTicketClaimDto.fromJson({'denyReason': 'no tickets left'});
      expect(d.toJson()['denyReason'], 'no tickets left');
    });
  });

  // -------------------------------------------------------------------------
  // ReviveQuoteDto
  // -------------------------------------------------------------------------

  group('ReviveQuoteDto', () {
    test('stores baseCost', () {
      final d = ReviveQuoteDto.fromJson(
          {'baseCost': 50, 'finalCost': 40, 'almostWinApplied': false, 'costCurrency': 'coins'});
      expect(d.baseCost, 50);
    });

    test('costCurrency defaults coins when absent', () {
      final d = ReviveQuoteDto.fromJson({});
      expect(d.costCurrency, 'coins');
    });

    test('hasDiscount true when finalCost < baseCost', () {
      final d = ReviveQuoteDto.fromJson({'baseCost': 100, 'finalCost': 80});
      expect(d.hasDiscount, isTrue);
    });

    test('hasDiscount false when finalCost == baseCost', () {
      final d = ReviveQuoteDto.fromJson({'baseCost': 50, 'finalCost': 50});
      expect(d.hasDiscount, isFalse);
    });

    test('hasDiscount false when finalCost > baseCost', () {
      final d = ReviveQuoteDto.fromJson({'baseCost': 30, 'finalCost': 35});
      expect(d.hasDiscount, isFalse);
    });

    test('toJson contains all 4 fields', () {
      final j = ReviveQuoteDto.fromJson(
          {'baseCost': 20, 'finalCost': 15, 'almostWinApplied': true, 'costCurrency': 'gems'})
          .toJson();
      expect(j.containsKey('baseCost'), isTrue);
      expect(j.containsKey('finalCost'), isTrue);
      expect(j.containsKey('almostWinApplied'), isTrue);
      expect(j.containsKey('costCurrency'), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // PityResponseDto
  // -------------------------------------------------------------------------

  group('PityResponseDto', () {
    test('fromJson pityActive defaults false', () {
      final d = PityResponseDto.fromJson({});
      expect(d.pityActive, isFalse);
    });

    test('fromJson lossCount defaults 0', () {
      final d = PityResponseDto.fromJson({});
      expect(d.lossCount, 0);
    });

    test('fromJson parses pityActive true', () {
      final d = PityResponseDto.fromJson({'pityActive': true, 'lossCount': 3});
      expect(d.pityActive, isTrue);
    });

    test('fromJson parses lossCount', () {
      final d = PityResponseDto.fromJson({'pityActive': false, 'lossCount': 5});
      expect(d.lossCount, 5);
    });

    test('toJson pityActive present', () {
      final d = PityResponseDto.fromJson({'pityActive': true});
      expect(d.toJson()['pityActive'], isTrue);
    });

    test('toJson lossCount present', () {
      final d = PityResponseDto.fromJson({'lossCount': 7});
      expect(d.toJson()['lossCount'], 7);
    });
  });
}
