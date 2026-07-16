import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/game/models/seasonal_competition_model.dart';
import 'package:synaptix/game/models/season_reward_preview_models.dart';
import 'package:synaptix/game/models/seasonal_theme_models.dart';
import 'package:synaptix/core/theme/themes.dart';

Map<String, dynamic> _seasonPlayerJson({
  String playerId = 'p1',
  String playerName = 'Alice',
  int points = 500,
  int rank = 1,
  String lastActive = '2025-06-01T10:00:00.000Z',
}) =>
    {
      'playerId': playerId,
      'playerName': playerName,
      'points': points,
      'rank': rank,
      'lastActive': lastActive,
    };

Map<String, dynamic> _themeJson({
  String id = 'th1',
  String name = 'Summer Blaze',
  String themeType = 'main',
  String startDate = '2025-06-01T00:00:00.000Z',
  String endDate = '2025-08-31T23:59:59.000Z',
  bool isActive = true,
  String? description,
  String? iconEmoji,
}) =>
    {
      'id': id,
      'name': name,
      'theme_type': themeType,
      'start_date': startDate,
      'end_date': endDate,
      'is_active': isActive,
      if (description != null) 'description': description,
      if (iconEmoji != null) 'icon_emoji': iconEmoji,
    };

void main() {
  // -------------------------------------------------------------------------
  // SeasonPlayer.fromJson
  // -------------------------------------------------------------------------

  group('SeasonPlayer.fromJson', () {
    test('parses playerId', () {
      expect(
          SeasonPlayer.fromJson(_seasonPlayerJson(playerId: 'uid_x')).playerId,
          'uid_x');
    });

    test('parses playerName', () {
      expect(
          SeasonPlayer.fromJson(_seasonPlayerJson(playerName: 'Bob'))
              .playerName,
          'Bob');
    });

    test('parses points', () {
      expect(
          SeasonPlayer.fromJson(_seasonPlayerJson(points: 1200)).points, 1200);
    });

    test('parses rank', () {
      expect(SeasonPlayer.fromJson(_seasonPlayerJson(rank: 5)).rank, 5);
    });

    test('parses lastActive', () {
      final player = SeasonPlayer.fromJson(
          _seasonPlayerJson(lastActive: '2025-09-15T00:00:00.000Z'));
      expect(player.lastActive.month, 9);
    });
  });

  // -------------------------------------------------------------------------
  // SeasonEndResult
  // -------------------------------------------------------------------------

  group('SeasonEndResult', () {
    test('stores promoted and demoted lists', () {
      final result = SeasonEndResult(
        promoted: [SeasonPlayer.fromJson(_seasonPlayerJson())],
        demoted: [],
        tiebreakers: [],
        seasonId: 's1',
      );
      expect(result.promoted.length, 1);
      expect(result.demoted, isEmpty);
    });

    test('hasError is false when error is null', () {
      final result = SeasonEndResult(
          promoted: [], demoted: [], tiebreakers: [], seasonId: 's1');
      expect(result.hasError, isFalse);
    });

    test('hasError is true when error is set', () {
      final result = SeasonEndResult(
          promoted: [],
          demoted: [],
          tiebreakers: [],
          seasonId: 's1',
          error: 'Something went wrong');
      expect(result.hasError, isTrue);
    });

    test('SeasonEndResult.error() sets error string', () {
      final result = SeasonEndResult.error('DB timeout');
      expect(result.error, 'DB timeout');
      expect(result.hasError, isTrue);
    });

    test('SeasonEndResult.error() clears promoted/demoted/tiebreakers', () {
      final result = SeasonEndResult.error('fail');
      expect(result.promoted, isEmpty);
      expect(result.demoted, isEmpty);
      expect(result.tiebreakers, isEmpty);
      expect(result.seasonId, '');
    });

    test('hasTiebreakers false when empty', () {
      final result = SeasonEndResult(
          promoted: [], demoted: [], tiebreakers: [], seasonId: 's1');
      expect(result.hasTiebreakers, isFalse);
    });

    test('hasTiebreakers true when list has items', () {
      final p = SeasonPlayer.fromJson(_seasonPlayerJson());
      final result = SeasonEndResult(promoted: [], demoted: [], tiebreakers: [
        [p, p]
      ], seasonId: 's1');
      expect(result.hasTiebreakers, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // SeasonRewardPreview.fromJson
  // -------------------------------------------------------------------------

  group('SeasonRewardPreview.fromJson', () {
    Map<String, dynamic> previewJson({
      String seasonId = 'szn1',
      String playerId = 'p1',
      bool eligible = true,
      int tier = 3,
      int tierRank = 7,
      int rewardXp = 500,
      int rewardCoins = 200,
    }) =>
        {
          'seasonId': seasonId,
          'playerId': playerId,
          'eligible': eligible,
          'tier': tier,
          'tierRank': tierRank,
          'rewardXp': rewardXp,
          'rewardCoins': rewardCoins,
        };

    test('parses seasonId', () {
      expect(
          SeasonRewardPreview.fromJson(previewJson(seasonId: 'szn_x')).seasonId,
          'szn_x');
    });

    test('parses playerId', () {
      expect(
          SeasonRewardPreview.fromJson(previewJson(playerId: 'uid_y')).playerId,
          'uid_y');
    });

    test('parses eligible', () {
      expect(
          SeasonRewardPreview.fromJson(previewJson(eligible: false)).eligible,
          isFalse);
    });

    test('parses tier', () {
      expect(SeasonRewardPreview.fromJson(previewJson(tier: 5)).tier, 5);
    });

    test('parses tierRank', () {
      expect(
          SeasonRewardPreview.fromJson(previewJson(tierRank: 12)).tierRank, 12);
    });

    test('parses rewardXp', () {
      expect(SeasonRewardPreview.fromJson(previewJson(rewardXp: 1000)).rewardXp,
          1000);
    });

    test('parses rewardCoins', () {
      expect(
          SeasonRewardPreview.fromJson(previewJson(rewardCoins: 500))
              .rewardCoins,
          500);
    });
  });

  // -------------------------------------------------------------------------
  // SeasonalTheme.fromJson
  // -------------------------------------------------------------------------

  group('SeasonalTheme.fromJson — scalar fields', () {
    test('parses id', () {
      expect(SeasonalTheme.fromJson(_themeJson(id: 'th99')).id, 'th99');
    });

    test('parses name', () {
      expect(SeasonalTheme.fromJson(_themeJson(name: 'Winter Frost')).name,
          'Winter Frost');
    });

    test('parses isActive', () {
      expect(SeasonalTheme.fromJson(_themeJson(isActive: false)).isActive,
          isFalse);
    });

    test('isActive defaults to false when absent', () {
      final json = _themeJson();
      json.remove('is_active');
      expect(SeasonalTheme.fromJson(json).isActive, isFalse);
    });

    test('parses description', () {
      expect(
          SeasonalTheme.fromJson(_themeJson(description: 'A hot theme'))
              .description,
          'A hot theme');
    });

    test('description is null when absent', () {
      expect(SeasonalTheme.fromJson(_themeJson()).description, isNull);
    });

    test('parses iconEmoji', () {
      expect(
          SeasonalTheme.fromJson(_themeJson(iconEmoji: '🔥')).iconEmoji, '🔥');
    });

    test('iconEmoji is null when absent', () {
      expect(SeasonalTheme.fromJson(_themeJson()).iconEmoji, isNull);
    });
  });

  group('SeasonalTheme.fromJson — DateTime fields', () {
    test('parses startDate', () {
      final theme = SeasonalTheme.fromJson(
          _themeJson(startDate: '2025-03-01T00:00:00.000Z'));
      expect(theme.startDate.month, 3);
    });

    test('parses endDate', () {
      final theme = SeasonalTheme.fromJson(
          _themeJson(endDate: '2025-12-31T00:00:00.000Z'));
      expect(theme.endDate.month, 12);
    });
  });

  group('SeasonalTheme.fromJson — ThemeType', () {
    test('"main" → ThemeType.main', () {
      expect(SeasonalTheme.fromJson(_themeJson(themeType: 'main')).themeType,
          ThemeType.main);
    });

    test('"allStar" → ThemeType.allStar', () {
      expect(SeasonalTheme.fromJson(_themeJson(themeType: 'allStar')).themeType,
          ThemeType.allStar);
    });

    test('"competition" → ThemeType.competition', () {
      expect(
          SeasonalTheme.fromJson(_themeJson(themeType: 'competition'))
              .themeType,
          ThemeType.competition);
    });

    test('unknown themeType falls back to main', () {
      expect(SeasonalTheme.fromJson(_themeJson(themeType: 'unknown')).themeType,
          ThemeType.main);
    });
  });

  // -------------------------------------------------------------------------
  // SeasonalTheme — isCurrentlyActive()
  // -------------------------------------------------------------------------

  group('SeasonalTheme — isCurrentlyActive()', () {
    test('true when isActive=true and now is within range', () {
      final start =
          DateTime.now().subtract(const Duration(days: 1)).toIso8601String();
      final end = DateTime.now().add(const Duration(days: 1)).toIso8601String();
      final theme = SeasonalTheme.fromJson(
          _themeJson(isActive: true, startDate: start, endDate: end));
      expect(theme.isCurrentlyActive(), isTrue);
    });

    test('false when isActive=false even if within date range', () {
      final start =
          DateTime.now().subtract(const Duration(days: 1)).toIso8601String();
      final end = DateTime.now().add(const Duration(days: 1)).toIso8601String();
      final theme = SeasonalTheme.fromJson(
          _themeJson(isActive: false, startDate: start, endDate: end));
      expect(theme.isCurrentlyActive(), isFalse);
    });

    test('false when end date is in the past', () {
      final start =
          DateTime.now().subtract(const Duration(days: 10)).toIso8601String();
      final end =
          DateTime.now().subtract(const Duration(days: 1)).toIso8601String();
      final theme = SeasonalTheme.fromJson(
          _themeJson(isActive: true, startDate: start, endDate: end));
      expect(theme.isCurrentlyActive(), isFalse);
    });

    test('false when start date is in the future', () {
      final start =
          DateTime.now().add(const Duration(days: 1)).toIso8601String();
      final end =
          DateTime.now().add(const Duration(days: 10)).toIso8601String();
      final theme = SeasonalTheme.fromJson(
          _themeJson(isActive: true, startDate: start, endDate: end));
      expect(theme.isCurrentlyActive(), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // SeasonalTheme.toJson
  // -------------------------------------------------------------------------

  group('SeasonalTheme.toJson', () {
    test('serializes themeType as name', () {
      final theme = SeasonalTheme.fromJson(_themeJson(themeType: 'allStar'));
      expect(theme.toJson()['theme_type'], 'allStar');
    });

    test('serializes startDate and endDate as ISO strings', () {
      final theme = SeasonalTheme.fromJson(_themeJson());
      expect(theme.toJson()['start_date'], isA<String>());
      expect(theme.toJson()['end_date'], isA<String>());
    });

    test('round-trip preserves name, themeType, isActive', () {
      final original = SeasonalTheme.fromJson(
          _themeJson(name: 'Blaze', themeType: 'competition', isActive: false));
      final restored = SeasonalTheme.fromJson(original.toJson());
      expect(restored.name, 'Blaze');
      expect(restored.themeType, ThemeType.competition);
      expect(restored.isActive, isFalse);
    });
  });
}
