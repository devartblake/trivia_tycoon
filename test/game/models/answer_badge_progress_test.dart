import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/models/answer.dart';
import 'package:trivia_tycoon/game/models/badge.dart';
import 'package:trivia_tycoon/game/models/player_progress.dart';
import 'package:trivia_tycoon/game/models/flow_connect_level_data.dart';
import 'package:trivia_tycoon/game/models/flow_connect_grid_cell.dart';
import 'package:trivia_tycoon/game/models/flow_connect_path_point.dart';
import 'package:trivia_tycoon/game/models/drawer_enums.dart';

void main() {
  // -------------------------------------------------------------------------
  // Answer
  // -------------------------------------------------------------------------

  group('Answer', () {
    test('constructor stores text and isCorrect', () {
      final a = Answer(text: 'Paris', isCorrect: true);
      expect(a.text, 'Paris');
      expect(a.isCorrect, isTrue);
    });

    test('fromJson parses text field', () {
      final a = Answer.fromJson({'text': 'Berlin', 'isCorrect': false});
      expect(a.text, 'Berlin');
    });

    test('fromJson parses isCorrect true', () {
      final a = Answer.fromJson({'text': 'Rome', 'isCorrect': true});
      expect(a.isCorrect, isTrue);
    });

    test('fromJson isCorrect defaults false when absent', () {
      final a = Answer.fromJson({'text': 'Madrid'});
      expect(a.isCorrect, isFalse);
    });

    test('toJson returns map with text key', () {
      final a = Answer(text: 'London', isCorrect: false);
      expect(a.toJson()['text'], 'London');
    });

    test('toJson returns map with isCorrect key', () {
      final a = Answer(text: 'London', isCorrect: true);
      expect(a.toJson()['isCorrect'], isTrue);
    });

    test('round-trip preserves text', () {
      final a = Answer(text: 'Tokyo', isCorrect: true);
      expect(Answer.fromJson(a.toJson()).text, 'Tokyo');
    });

    test('round-trip preserves isCorrect', () {
      final a = Answer(text: 'Tokyo', isCorrect: true);
      expect(Answer.fromJson(a.toJson()).isCorrect, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // GameBadge
  // -------------------------------------------------------------------------

  group('GameBadge', () {
    test('constructor stores all required fields', () {
      final b = GameBadge(
        id: 'b1',
        name: 'First Win',
        description: 'Won first match',
        iconPath: 'assets/badges/win.png',
      );
      expect(b.id, 'b1');
      expect(b.name, 'First Win');
      expect(b.description, 'Won first match');
      expect(b.iconPath, 'assets/badges/win.png');
    });

    test('isUnlocked defaults false', () {
      final b = GameBadge(
        id: 'b2',
        name: 'X',
        description: 'Y',
        iconPath: 'Z',
      );
      expect(b.isUnlocked, isFalse);
    });

    test('constructor stores explicit isUnlocked true', () {
      final b = GameBadge(
        id: 'b3',
        name: 'X',
        description: 'Y',
        iconPath: 'Z',
        isUnlocked: true,
      );
      expect(b.isUnlocked, isTrue);
    });

    test('fromJson parses all fields', () {
      final b = GameBadge.fromJson({
        'id': 'b4',
        'name': 'Top Scorer',
        'description': 'Score 1000 points',
        'iconPath': 'assets/badges/scorer.png',
        'isUnlocked': true,
      });
      expect(b.id, 'b4');
      expect(b.name, 'Top Scorer');
      expect(b.description, 'Score 1000 points');
      expect(b.iconPath, 'assets/badges/scorer.png');
      expect(b.isUnlocked, isTrue);
    });

    test('fromJson isUnlocked defaults false when absent', () {
      final b = GameBadge.fromJson({
        'id': 'b5',
        'name': 'N',
        'description': 'D',
        'iconPath': 'P',
      });
      expect(b.isUnlocked, isFalse);
    });

    test('toJson contains all 5 keys', () {
      final b = GameBadge(
        id: 'b6',
        name: 'N',
        description: 'D',
        iconPath: 'P',
        isUnlocked: false,
      );
      final j = b.toJson();
      expect(j.containsKey('id'), isTrue);
      expect(j.containsKey('name'), isTrue);
      expect(j.containsKey('description'), isTrue);
      expect(j.containsKey('iconPath'), isTrue);
      expect(j.containsKey('isUnlocked'), isTrue);
    });

    test('round-trip preserves id', () {
      final b = GameBadge(
        id: 'b7', name: 'X', description: 'Y', iconPath: 'Z', isUnlocked: true,
      );
      expect(GameBadge.fromJson(b.toJson()).id, 'b7');
    });

    test('round-trip preserves isUnlocked true', () {
      final b = GameBadge(
        id: 'b8', name: 'X', description: 'Y', iconPath: 'Z', isUnlocked: true,
      );
      expect(GameBadge.fromJson(b.toJson()).isUnlocked, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // PlayerProgress
  // -------------------------------------------------------------------------

  group('PlayerProgress', () {
    test('constructor stores score and streak', () {
      final p = PlayerProgress(score: 500, streak: 3);
      expect(p.score, 500);
      expect(p.streak, 3);
    });

    test('fromJson parses score', () {
      final p = PlayerProgress.fromJson({'score': 200, 'streak': 1});
      expect(p.score, 200);
    });

    test('fromJson parses streak', () {
      final p = PlayerProgress.fromJson({'score': 200, 'streak': 7});
      expect(p.streak, 7);
    });

    test('fromJson score defaults 0 when absent', () {
      final p = PlayerProgress.fromJson({'streak': 2});
      expect(p.score, 0);
    });

    test('fromJson streak defaults 0 when absent', () {
      final p = PlayerProgress.fromJson({'score': 100});
      expect(p.streak, 0);
    });

    test('toJson has score key', () {
      final p = PlayerProgress(score: 300, streak: 5);
      expect(p.toJson()['score'], 300);
    });

    test('toJson has streak key', () {
      final p = PlayerProgress(score: 300, streak: 5);
      expect(p.toJson()['streak'], 5);
    });

    test('round-trip preserves score and streak', () {
      final p = PlayerProgress(score: 999, streak: 10);
      final r = PlayerProgress.fromJson(p.toJson());
      expect(r.score, 999);
      expect(r.streak, 10);
    });
  });

  // -------------------------------------------------------------------------
  // FlowConnectLevelData
  // -------------------------------------------------------------------------

  group('FlowConnectLevelData', () {
    FlowConnectLevelData _build() {
      final grid = [
        [FlowConnectGridCell(row: 0, col: 0), FlowConnectGridCell(row: 0, col: 1)],
        [FlowConnectGridCell(row: 1, col: 0), FlowConnectGridCell(row: 1, col: 1)],
      ];
      final path = [
        FlowConnectPathPoint(row: 0, col: 0, order: 0),
        FlowConnectPathPoint(row: 0, col: 1, order: 1),
      ];
      return FlowConnectLevelData(
        grid: grid,
        gridSize: 2,
        totalNumbers: 1,
        solutionPath: path,
      );
    }

    test('stores gridSize', () {
      expect(_build().gridSize, 2);
    });

    test('stores totalNumbers', () {
      expect(_build().totalNumbers, 1);
    });

    test('stores grid with correct dimensions', () {
      expect(_build().grid.length, 2);
      expect(_build().grid[0].length, 2);
    });

    test('stores solutionPath with correct length', () {
      expect(_build().solutionPath.length, 2);
    });
  });

  // -------------------------------------------------------------------------
  // MenuSection enum + extension
  // -------------------------------------------------------------------------

  group('MenuSection enum', () {
    test('has exactly 4 values', () {
      expect(MenuSection.values.length, 4);
    });

    test('all values are distinct', () {
      expect(MenuSection.values.toSet().length, 4);
    });

    test('main displayName is "Main Menu"', () {
      expect(MenuSection.main.displayName, 'Main Menu');
    });

    test('more displayName is "More Options"', () {
      expect(MenuSection.more.displayName, 'More Options');
    });

    test('bottom displayName is "Settings"', () {
      expect(MenuSection.bottom.displayName, 'Settings');
    });

    test('logout displayName is "Logout"', () {
      expect(MenuSection.logout.displayName, 'Logout');
    });

    test('all displayNames are non-empty', () {
      for (final s in MenuSection.values) {
        expect(s.displayName, isNotEmpty);
      }
    });

    test('all displayNames are distinct', () {
      final names = MenuSection.values.map((s) => s.displayName).toSet();
      expect(names.length, MenuSection.values.length);
    });
  });

  // -------------------------------------------------------------------------
  // MenuItemType enum
  // -------------------------------------------------------------------------

  group('MenuItemType enum', () {
    test('has exactly 2 values', () {
      expect(MenuItemType.values.length, 2);
    });

    test('contains gradient', () {
      expect(MenuItemType.values, contains(MenuItemType.gradient));
    });

    test('contains simple', () {
      expect(MenuItemType.values, contains(MenuItemType.simple));
    });

    test('all values are distinct', () {
      expect(MenuItemType.values.toSet().length, 2);
    });
  });
}
