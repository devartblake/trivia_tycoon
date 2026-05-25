import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/models/menu_enums.dart';
import 'package:trivia_tycoon/game/models/menu_data.dart';
import 'package:trivia_tycoon/game/models/game_mode.dart';
import 'package:trivia_tycoon/game/models/versus_models.dart';
import 'package:trivia_tycoon/game/models/drawer_menu_data.dart';
import 'package:trivia_tycoon/game/models/search.dart';

void main() {
  // -------------------------------------------------------------------------
  // AgeGroup enum
  // -------------------------------------------------------------------------

  group('AgeGroup', () {
    test('has 4 values', () {
      expect(AgeGroup.values.length, 4);
    });

    test('value getter returns correct string for each', () {
      expect(AgeGroup.kids.value, 'kids');
      expect(AgeGroup.teens.value, 'teens');
      expect(AgeGroup.adults.value, 'adults');
      expect(AgeGroup.general.value, 'general');
    });

    test('fromString returns correct AgeGroup', () {
      expect(AgeGroupExtension.fromString('kids'), AgeGroup.kids);
      expect(AgeGroupExtension.fromString('teens'), AgeGroup.teens);
      expect(AgeGroupExtension.fromString('adults'), AgeGroup.adults);
    });

    test('fromString is case-insensitive', () {
      expect(AgeGroupExtension.fromString('KIDS'), AgeGroup.kids);
    });

    test('fromString defaults to general for unknown value', () {
      expect(AgeGroupExtension.fromString('unknown'), AgeGroup.general);
    });

    test('fromString returns general for empty string', () {
      expect(AgeGroupExtension.fromString(''), AgeGroup.general);
    });

    test('all values have non-empty string representation', () {
      for (final age in AgeGroup.values) {
        expect(age.value.isNotEmpty, isTrue);
      }
    });
  });

  // -------------------------------------------------------------------------
  // MatchStatus enum
  // -------------------------------------------------------------------------

  group('MatchStatus', () {
    test('has 5 values', () {
      expect(MatchStatus.values.length, 5);
    });

    test('displayText for each value is non-empty', () {
      for (final s in MatchStatus.values) {
        expect(s.displayText.isNotEmpty, isTrue);
      }
    });

    test('value getter returns correct string', () {
      expect(MatchStatus.yourTurn.value, 'your_turn');
      expect(MatchStatus.waiting.value, 'waiting');
      expect(MatchStatus.similarStats.value, 'similar_stats');
      expect(MatchStatus.fastPlayer.value, 'fast_player');
      expect(MatchStatus.finished.value, 'finished');
    });

    test('fromString returns correct value', () {
      expect(
          MatchStatusExtension.fromString('your_turn'), MatchStatus.yourTurn);
      expect(MatchStatusExtension.fromString('waiting'), MatchStatus.waiting);
      expect(MatchStatusExtension.fromString('similar_stats'),
          MatchStatus.similarStats);
      expect(MatchStatusExtension.fromString('fast_player'),
          MatchStatus.fastPlayer);
      expect(MatchStatusExtension.fromString('finished'), MatchStatus.finished);
    });

    test('fromString defaults to waiting for unknown value', () {
      expect(MatchStatusExtension.fromString('unknown'), MatchStatus.waiting);
    });

    test('displayText values match expected strings', () {
      expect(MatchStatus.yourTurn.displayText, 'Your turn');
      expect(MatchStatus.waiting.displayText, 'Waiting...');
      expect(MatchStatus.finished.displayText, 'Finished');
    });
  });

  // -------------------------------------------------------------------------
  // MatchTab enum
  // -------------------------------------------------------------------------

  group('MatchTab', () {
    test('has 2 values', () {
      expect(MatchTab.values.length, 2);
    });

    test('displayText for classic is "Classic"', () {
      expect(MatchTab.classic.displayText, 'Classic');
    });

    test('displayText for live is "Live"', () {
      expect(MatchTab.live.displayText, 'Live');
    });
  });

  // -------------------------------------------------------------------------
  // MatchFilter enum
  // -------------------------------------------------------------------------

  group('MatchFilter', () {
    test('has 3 values', () {
      expect(MatchFilter.values.length, 3);
    });

    test('displayText for each is non-empty', () {
      for (final f in MatchFilter.values) {
        expect(f.displayText.isNotEmpty, isTrue);
      }
    });

    test('displayText for all is "All"', () {
      expect(MatchFilter.all.displayText, 'All');
    });

    test('displayText for yourTurn is "Your turn"', () {
      expect(MatchFilter.yourTurn.displayText, 'Your turn');
    });
  });

  // -------------------------------------------------------------------------
  // LayoutMode enum
  // -------------------------------------------------------------------------

  group('LayoutMode', () {
    test('has 3 values', () {
      expect(LayoutMode.values.length, 3);
    });

    test('isMobile is true only for mobile', () {
      expect(LayoutMode.mobile.isMobile, isTrue);
      expect(LayoutMode.tablet.isMobile, isFalse);
      expect(LayoutMode.desktop.isMobile, isFalse);
    });

    test('isTablet is true only for tablet', () {
      expect(LayoutMode.tablet.isTablet, isTrue);
      expect(LayoutMode.mobile.isTablet, isFalse);
    });

    test('isDesktop is true only for desktop', () {
      expect(LayoutMode.desktop.isDesktop, isTrue);
      expect(LayoutMode.mobile.isDesktop, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // GameMode enum
  // -------------------------------------------------------------------------

  group('GameMode', () {
    test('has 6 values', () {
      expect(GameMode.values.length, 6);
    });

    test('contains all expected modes', () {
      expect(
          GameMode.values,
          containsAll([
            GameMode.classic,
            GameMode.topicExplorer,
            GameMode.survival,
            GameMode.arena,
            GameMode.teams,
            GameMode.daily,
          ]));
    });
  });

  group('normalizeGameModeName', () {
    test('strips "GameMode." prefix', () {
      expect(normalizeGameModeName('GameMode.classic'), 'classic');
      expect(normalizeGameModeName('GameMode.arena'), 'arena');
    });

    test('returns input unchanged when no prefix', () {
      expect(normalizeGameModeName('classic'), 'classic');
      expect(normalizeGameModeName('survival'), 'survival');
    });

    test('returns empty string for empty input', () {
      expect(normalizeGameModeName(''), '');
    });
  });

  // -------------------------------------------------------------------------
  // VersusMode enum
  // -------------------------------------------------------------------------

  group('VersusMode', () {
    test('has 2 values', () {
      expect(VersusMode.values.length, 2);
    });

    test('contains oneVone and teamVteam', () {
      expect(
          VersusMode.values,
          containsAll([
            VersusMode.oneVone,
            VersusMode.teamVteam,
          ]));
    });
  });

  // -------------------------------------------------------------------------
  // Member
  // -------------------------------------------------------------------------

  group('Member', () {
    test('stores id and name', () {
      const m = Member(id: 'm1', name: 'Alice');
      expect(m.id, 'm1');
      expect(m.name, 'Alice');
    });

    test('avatarUrl defaults to null', () {
      const m = Member(id: 'm1', name: 'Alice');
      expect(m.avatarUrl, isNull);
    });

    test('stores optional avatarUrl', () {
      const m = Member(id: 'm1', name: 'Alice', avatarUrl: 'http://img.png');
      expect(m.avatarUrl, 'http://img.png');
    });
  });

  // -------------------------------------------------------------------------
  // Participant.isTeam
  // -------------------------------------------------------------------------

  group('Participant.isTeam', () {
    test('isTeam is false when no members', () {
      const p = Participant(id: 'p1', displayName: 'Solo');
      expect(p.isTeam, isFalse);
    });

    test('isTeam is false for single member', () {
      const p = Participant(
        id: 'p1',
        displayName: 'Solo',
        members: [Member(id: 'm1', name: 'Alice')],
      );
      expect(p.isTeam, isFalse);
    });

    test('isTeam is true for 2+ members', () {
      const p = Participant(
        id: 'p1',
        displayName: 'Team',
        members: [
          Member(id: 'm1', name: 'Alice'),
          Member(id: 'm2', name: 'Bob'),
        ],
      );
      expect(p.isTeam, isTrue);
    });

    test('isHost defaults to false', () {
      const p = Participant(id: 'p1', displayName: 'P');
      expect(p.isHost, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // MatchData
  // -------------------------------------------------------------------------

  group('MatchData', () {
    test('fromJson parses required fields', () {
      final m = MatchData.fromJson({
        'name': 'Alice',
        'status': 'your_turn',
      });
      expect(m.name, 'Alice');
      expect(m.status, 'your_turn');
    });

    test('fromJson score and avatarUrl are nullable', () {
      final m = MatchData.fromJson({
        'name': 'Bob',
        'status': 'waiting',
      });
      expect(m.score, isNull);
      expect(m.avatarUrl, isNull);
    });

    test('fromJson stores optional score', () {
      final m = MatchData.fromJson({
        'name': 'Carol',
        'score': '1200',
        'status': 'finished',
      });
      expect(m.score, '1200');
    });

    test('toJson round-trip preserves name and status', () {
      final original =
          MatchData.fromJson({'name': 'Dave', 'status': 'waiting'});
      final json = original.toJson();
      final restored = MatchData.fromJson(json);
      expect(restored.name, 'Dave');
      expect(restored.status, 'waiting');
    });
  });

  // -------------------------------------------------------------------------
  // JourneyData
  // -------------------------------------------------------------------------

  group('JourneyData', () {
    test('progress is 0.0 when currentXP is 0', () {
      const j = JourneyData(currentXP: 0, maxXP: 500, level: 1);
      expect(j.progress, 0.0);
    });

    test('progress is 1.0 when currentXP equals maxXP', () {
      const j = JourneyData(currentXP: 500, maxXP: 500, level: 1);
      expect(j.progress, 1.0);
    });

    test('progress is clamped at 1.0 when currentXP exceeds maxXP', () {
      const j = JourneyData(currentXP: 600, maxXP: 500, level: 1);
      expect(j.progress, 1.0);
    });

    test('progress is between 0 and 1 for partial XP', () {
      const j = JourneyData(currentXP: 250, maxXP: 500, level: 1);
      expect(j.progress, 0.5);
    });

    test('percentage is 0 when progress is 0', () {
      const j = JourneyData(currentXP: 0, maxXP: 500, level: 1);
      expect(j.percentage, 0);
    });

    test('percentage is 100 when progress is 1.0', () {
      const j = JourneyData(currentXP: 500, maxXP: 500, level: 1);
      expect(j.percentage, 100);
    });

    test('percentage is 50 when halfway', () {
      const j = JourneyData(currentXP: 250, maxXP: 500, level: 1);
      expect(j.percentage, 50);
    });

    test('level is stored correctly', () {
      const j = JourneyData(currentXP: 100, maxXP: 500, level: 5);
      expect(j.level, 5);
    });

    test('nextReward defaults to null', () {
      const j = JourneyData(currentXP: 0, maxXP: 500, level: 1);
      expect(j.nextReward, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // ProfileStats (drawer_menu_data)
  // -------------------------------------------------------------------------

  group('ProfileStats', () {
    test('fromMap parses level, currentXP, isPremium', () {
      final s = ProfileStats.fromMap(
          {'level': 5, 'currentXP': 300, 'isPremium': true});
      expect(s.level, 5);
      expect(s.currentXP, 300);
      expect(s.isPremium, isTrue);
    });

    test('fromMap uses defaults for missing fields', () {
      final s = ProfileStats.fromMap({});
      expect(s.level, 1);
      expect(s.currentXP, 0);
      expect(s.isPremium, isFalse);
    });

    test('isPremium is false by default', () {
      final s = ProfileStats.fromMap({'level': 3, 'currentXP': 100});
      expect(s.isPremium, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // SearchCategory / SearchResultType enums
  // -------------------------------------------------------------------------

  group('SearchCategory', () {
    test('has 10 values', () {
      expect(SearchCategory.values.length, 10);
    });

    test('contains expected categories', () {
      expect(
          SearchCategory.values,
          containsAll([
            SearchCategory.skills,
            SearchCategory.questions,
            SearchCategory.leaderboard,
            SearchCategory.players,
            SearchCategory.achievements,
            SearchCategory.store,
            SearchCategory.settings,
            SearchCategory.help,
            SearchCategory.games,
            SearchCategory.powerUps,
          ]));
    });
  });

  group('SearchResultType', () {
    test('has 8 values', () {
      expect(SearchResultType.values.length, 8);
    });

    test('contains expected types', () {
      expect(
          SearchResultType.values,
          containsAll([
            SearchResultType.skill,
            SearchResultType.question,
            SearchResultType.player,
            SearchResultType.achievement,
            SearchResultType.storeItem,
            SearchResultType.settingPage,
            SearchResultType.helpArticle,
            SearchResultType.navigation,
          ]));
    });
  });

  // -------------------------------------------------------------------------
  // SearchFilter
  // -------------------------------------------------------------------------

  group('SearchFilter', () {
    test('defaults: categories and types empty, include flags true', () {
      final f = SearchFilter();
      expect(f.categories, isEmpty);
      expect(f.types, isEmpty);
      expect(f.includeUnlocked, isTrue);
      expect(f.includeLocked, isTrue);
    });

    test('copyWith categories updated', () {
      final f = SearchFilter();
      final updated = f.copyWith(categories: {SearchCategory.store});
      expect(updated.categories, contains(SearchCategory.store));
    });

    test('copyWith types updated', () {
      final f = SearchFilter();
      final updated = f.copyWith(types: {SearchResultType.player});
      expect(updated.types, contains(SearchResultType.player));
    });

    test('copyWith includeUnlocked toggled', () {
      final f = SearchFilter();
      final updated = f.copyWith(includeUnlocked: false);
      expect(updated.includeUnlocked, isFalse);
    });

    test('copyWith preserves unchanged fields', () {
      final f = SearchFilter(
        categories: {SearchCategory.help},
        includeUnlocked: false,
      );
      final updated = f.copyWith(includeLocked: false);
      expect(updated.categories, contains(SearchCategory.help));
      expect(updated.includeUnlocked, isFalse);
      expect(updated.includeLocked, isFalse);
    });
  });
}
