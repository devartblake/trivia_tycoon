import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/core/dto/skill_dto.dart';

void main() {
  group('SkillNodeDto', () {
    final fullJson = {
      'id': 'sch_root',
      'name': 'Study Habits',
      'description': 'Increases XP gain',
      'unlocked': true,
      'cost': 2,
      'requires': ['base_node'],
    };

    test('round-trips through JSON', () {
      final dto = SkillNodeDto.fromJson(fullJson);
      final roundTripped = SkillNodeDto.fromJson(dto.toJson());

      expect(roundTripped.id, dto.id);
      expect(roundTripped.name, dto.name);
      expect(roundTripped.description, dto.description);
      expect(roundTripped.unlocked, dto.unlocked);
      expect(roundTripped.cost, dto.cost);
      expect(roundTripped.requires, dto.requires);
    });

    test('fromJson parses all fields correctly', () {
      final dto = SkillNodeDto.fromJson(fullJson);

      expect(dto.id, 'sch_root');
      expect(dto.name, 'Study Habits');
      expect(dto.description, 'Increases XP gain');
      expect(dto.unlocked, isTrue);
      expect(dto.cost, 2);
      expect(dto.requires, ['base_node']);
    });

    test('fromJson uses defaults when optional fields are absent', () {
      final dto = SkillNodeDto.fromJson({'id': 'x', 'name': 'X'});

      expect(dto.description, '');
      expect(dto.unlocked, isFalse);
      expect(dto.cost, 0);
    });

    test('requires list is empty when absent from JSON', () {
      final dto = SkillNodeDto.fromJson({'id': 'x', 'name': 'X'});
      expect(dto.requires, isEmpty);
    });

    test('toJson includes requires list', () {
      final dto = SkillNodeDto.fromJson(fullJson);
      final json = dto.toJson();
      expect(json['requires'], ['base_node']);
    });
  });

  group('SkillTreeDto', () {
    final fullJson = {
      'playerId': 'player_abc',
      'availablePoints': 3,
      'nodes': [
        {
          'id': 'sch_root',
          'name': 'Study Habits',
          'description': '',
          'unlocked': true,
          'cost': 1,
          'requires': [],
        },
        {
          'id': 'sch_focus',
          'name': 'Deep Focus',
          'description': '',
          'unlocked': false,
          'cost': 2,
          'requires': ['sch_root'],
        },
      ],
    };

    test('round-trips through JSON with nested nodes', () {
      final dto = SkillTreeDto.fromJson(fullJson);
      final roundTripped = SkillTreeDto.fromJson(dto.toJson());

      expect(roundTripped.playerId, dto.playerId);
      expect(roundTripped.availablePoints, dto.availablePoints);
      expect(roundTripped.nodes.length, dto.nodes.length);
      expect(roundTripped.nodes[0].id, dto.nodes[0].id);
      expect(roundTripped.nodes[1].requires, dto.nodes[1].requires);
    });

    test('fromJson parses all fields correctly', () {
      final dto = SkillTreeDto.fromJson(fullJson);

      expect(dto.playerId, 'player_abc');
      expect(dto.availablePoints, 3);
      expect(dto.nodes.length, 2);
      expect(dto.nodes[0].unlocked, isTrue);
      expect(dto.nodes[1].unlocked, isFalse);
    });

    test('availablePoints defaults to 0 when absent', () {
      final dto = SkillTreeDto.fromJson({'playerId': 'p', 'nodes': []});
      expect(dto.availablePoints, 0);
    });

    test('nodes defaults to empty list when absent', () {
      final dto = SkillTreeDto.fromJson({'playerId': 'p'});
      expect(dto.nodes, isEmpty);
    });

    test('toJson serializes nested nodes', () {
      final dto = SkillTreeDto.fromJson(fullJson);
      final json = dto.toJson();

      expect(json['playerId'], 'player_abc');
      expect((json['nodes'] as List).length, 2);
      expect((json['nodes'] as List)[0]['id'], 'sch_root');
    });
  });
}