import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/game/utils/gradient_themes.dart';
import 'package:synaptix/game/utils/drawer_menu_config.dart';
import 'package:synaptix/game/models/drawer_menu_data.dart';

void main() {
  // -------------------------------------------------------------------------
  // GradientThemes.getRewardGradient
  // -------------------------------------------------------------------------

  group('GradientThemes.getRewardGradient', () {
    test('returns LinearGradient for kids', () {
      final g = GradientThemes.getRewardGradient('kids');
      expect(g, isA<LinearGradient>());
      expect(g.colors.length, 2);
    });

    test('kids reward gradient starts with 0xFFFF6B6B', () {
      final g = GradientThemes.getRewardGradient('kids');
      expect(g.colors.first, const Color(0xFFFF6B6B));
    });

    test('returns LinearGradient for teens', () {
      final g = GradientThemes.getRewardGradient('teens');
      expect(g, isA<LinearGradient>());
      expect(g.colors.length, 2);
    });

    test('teens reward gradient starts with 0xFF4ECDC4', () {
      final g = GradientThemes.getRewardGradient('teens');
      expect(g.colors.first, const Color(0xFF4ECDC4));
    });

    test('returns LinearGradient for adults', () {
      final g = GradientThemes.getRewardGradient('adults');
      expect(g, isA<LinearGradient>());
      expect(g.colors.length, 2);
    });

    test('adults reward gradient starts with 0xFFF59E0B', () {
      final g = GradientThemes.getRewardGradient('adults');
      expect(g.colors.first, const Color(0xFFF59E0B));
    });

    test('unknown age group falls back to adults gradient', () {
      final adults = GradientThemes.getRewardGradient('adults');
      final unknown = GradientThemes.getRewardGradient('unknown');
      expect(unknown.colors.first, adults.colors.first);
      expect(unknown.colors.last, adults.colors.last);
    });
  });

  // -------------------------------------------------------------------------
  // GradientThemes.getGreetingGradient
  // -------------------------------------------------------------------------

  group('GradientThemes.getGreetingGradient', () {
    test('returns LinearGradient for kids', () {
      final g = GradientThemes.getGreetingGradient('kids');
      expect(g, isA<LinearGradient>());
      expect(g.colors.length, 2);
    });

    test('kids greeting gradient starts with 0xFFFF6B6B', () {
      final g = GradientThemes.getGreetingGradient('kids');
      expect(g.colors.first, const Color(0xFFFF6B6B));
    });

    test('returns LinearGradient for teens', () {
      final g = GradientThemes.getGreetingGradient('teens');
      expect(g, isA<LinearGradient>());
      expect(g.colors.length, 2);
    });

    test('teens greeting gradient starts with 0xCB769CFD', () {
      final g = GradientThemes.getGreetingGradient('teens');
      expect(g.colors.first, const Color(0xCB769CFD));
    });

    test('adults greeting gradient starts with 0xFF667eea', () {
      final g = GradientThemes.getGreetingGradient('adults');
      expect(g.colors.first, const Color(0xFF667eea));
    });

    test('default greeting gradient is purple (0xFF6366F1)', () {
      final g = GradientThemes.getGreetingGradient('seniors');
      expect(g.colors.first, const Color(0xFF6366F1));
    });

    test('greeting and reward gradients differ for teens', () {
      final reward = GradientThemes.getRewardGradient('teens');
      final greeting = GradientThemes.getGreetingGradient('teens');
      expect(reward.colors.first, isNot(equals(greeting.colors.first)));
    });
  });

  // -------------------------------------------------------------------------
  // GradientThemes static getters
  // -------------------------------------------------------------------------

  group('GradientThemes static getters', () {
    test('primaryActionGradient is a LinearGradient with 2 colors', () {
      final g = GradientThemes.primaryActionGradient;
      expect(g, isA<LinearGradient>());
      expect(g.colors.length, 2);
    });

    test('primaryActionGradient starts with indigo 0xFF6366F1', () {
      expect(GradientThemes.primaryActionGradient.colors.first,
          const Color(0xFF6366F1));
    });

    test('secondaryActionGradient is a LinearGradient with 2 colors', () {
      final g = GradientThemes.secondaryActionGradient;
      expect(g, isA<LinearGradient>());
      expect(g.colors.length, 2);
    });

    test('successGradient starts with green 0xFF10B981', () {
      expect(
          GradientThemes.successGradient.colors.first, const Color(0xFF10B981));
    });

    test('warningGradient starts with amber 0xFFF59E0B', () {
      expect(
          GradientThemes.warningGradient.colors.first, const Color(0xFFF59E0B));
    });

    test('errorGradient starts with red 0xFFEF4444', () {
      expect(
          GradientThemes.errorGradient.colors.first, const Color(0xFFEF4444));
    });

    test('all static getters return distinct first colors', () {
      final first = {
        GradientThemes.primaryActionGradient.colors.first,
        GradientThemes.secondaryActionGradient.colors.first,
        GradientThemes.successGradient.colors.first,
        GradientThemes.warningGradient.colors.first,
        GradientThemes.errorGradient.colors.first,
      };
      expect(first.length, 5);
    });
  });

  // -------------------------------------------------------------------------
  // GradientThemes.getAgeGroupColors
  // -------------------------------------------------------------------------

  group('GradientThemes.getAgeGroupColors', () {
    test('returns list of 2 colors for kids', () {
      expect(GradientThemes.getAgeGroupColors('kids').length, 2);
    });

    test('kids colors start with 0xFFFF6B6B', () {
      expect(GradientThemes.getAgeGroupColors('kids').first,
          const Color(0xFFFF6B6B));
    });

    test('returns list of 2 colors for teens', () {
      expect(GradientThemes.getAgeGroupColors('teens').length, 2);
    });

    test('teens colors start with 0xFF4ECDC4', () {
      expect(GradientThemes.getAgeGroupColors('teens').first,
          const Color(0xFF4ECDC4));
    });

    test('returns list of 2 colors for adults', () {
      expect(GradientThemes.getAgeGroupColors('adults').length, 2);
    });

    test('adults colors start with 0xFF667eea', () {
      expect(GradientThemes.getAgeGroupColors('adults').first,
          const Color(0xFF667eea));
    });

    test('unknown returns default 2 colors starting with 0xFF6366F1', () {
      final colors = GradientThemes.getAgeGroupColors('other');
      expect(colors.length, 2);
      expect(colors.first, const Color(0xFF6366F1));
    });
  });

  // -------------------------------------------------------------------------
  // GradientThemes.custom
  // -------------------------------------------------------------------------

  group('GradientThemes.custom', () {
    test('returns LinearGradient with provided colors', () {
      const c1 = Color(0xFF111111);
      const c2 = Color(0xFF222222);
      final g = GradientThemes.custom([c1, c2]);
      expect(g, isA<LinearGradient>());
      expect(g.colors, [c1, c2]);
    });

    test('default begin is topLeft', () {
      final g = GradientThemes.custom([Colors.red, Colors.blue]);
      expect(g.begin, Alignment.topLeft);
    });

    test('default end is bottomRight', () {
      final g = GradientThemes.custom([Colors.red, Colors.blue]);
      expect(g.end, Alignment.bottomRight);
    });

    test('custom begin/end are respected', () {
      final g = GradientThemes.custom(
        [Colors.red, Colors.blue],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      );
      expect(g.begin, Alignment.centerLeft);
      expect(g.end, Alignment.centerRight);
    });
  });

  // -------------------------------------------------------------------------
  // DrawerMenuConfig.mainMenuItems
  // -------------------------------------------------------------------------

  group('DrawerMenuConfig.mainMenuItems', () {
    test('returns 7 items', () {
      expect(DrawerMenuConfig.mainMenuItems.length, 7);
    });

    test('all items are GradientMenuItems', () {
      for (final item in DrawerMenuConfig.mainMenuItems) {
        expect(item, isA<GradientMenuItem>());
      }
    });

    test('first item is Home with the canonical home route', () {
      final home = DrawerMenuConfig.mainMenuItems.first;
      expect(home.title, 'Home');
      expect(home.route, '/home');
    });

    test('last item is Arena with route "/leaderboard"', () {
      final arena = DrawerMenuConfig.mainMenuItems.last;
      expect(arena.title, 'Arena');
      expect(arena.route, '/leaderboard');
    });

    test('all items have non-empty titles and routes', () {
      for (final item in DrawerMenuConfig.mainMenuItems) {
        expect(item.title, isNotEmpty);
        expect(item.route, isNotEmpty);
      }
    });

    test('all items have gradients with 2 colors', () {
      for (final item in DrawerMenuConfig.mainMenuItems) {
        expect(item.gradient.colors.length, 2);
      }
    });

    test('contains Quiz item with route "/quiz"', () {
      final quiz =
          DrawerMenuConfig.mainMenuItems.firstWhere((i) => i.title == 'Quiz');
      expect(quiz.route, '/quiz');
    });
  });

  // -------------------------------------------------------------------------
  // DrawerMenuConfig.moreMenuItems
  // -------------------------------------------------------------------------

  group('DrawerMenuConfig.moreMenuItems', () {
    test('returns 1 item', () {
      expect(DrawerMenuConfig.moreMenuItems.length, 1);
    });

    test('item is Missions with route "/missions"', () {
      final item = DrawerMenuConfig.moreMenuItems.first;
      expect(item.title, 'Missions');
      expect(item.route, '/missions');
    });

    test('all items are SimpleMenuItems', () {
      for (final item in DrawerMenuConfig.moreMenuItems) {
        expect(item, isA<SimpleMenuItem>());
      }
    });
  });

  // -------------------------------------------------------------------------
  // DrawerMenuConfig.bottomMenuItems
  // -------------------------------------------------------------------------

  group('DrawerMenuConfig.bottomMenuItems', () {
    test('returns 4 items', () {
      expect(DrawerMenuConfig.bottomMenuItems.length, 4);
    });

    test('all items are SimpleMenuItems', () {
      for (final item in DrawerMenuConfig.bottomMenuItems) {
        expect(item, isA<SimpleMenuItem>());
      }
    });

    test('contains Settings item with route "/settings"', () {
      final s = DrawerMenuConfig.bottomMenuItems
          .firstWhere((i) => i.title == 'Settings');
      expect(s.route, '/settings');
    });

    test('contains Report item with route "/report"', () {
      final r = DrawerMenuConfig.bottomMenuItems
          .firstWhere((i) => i.title == 'Report');
      expect(r.route, '/report');
    });

    test('all items have non-empty titles and routes', () {
      for (final item in DrawerMenuConfig.bottomMenuItems) {
        expect(item.title, isNotEmpty);
        expect(item.route, isNotEmpty);
      }
    });
  });

  // -------------------------------------------------------------------------
  // DrawerMenuConfig gradients
  // -------------------------------------------------------------------------

  group('DrawerMenuConfig gradient constants', () {
    test('headerGradient has 3 colors', () {
      expect(DrawerMenuConfig.headerGradient.colors.length, 3);
    });

    test('headerGradient first color is 0xFF6366F1', () {
      expect(DrawerMenuConfig.headerGradient.colors.first,
          const Color(0xFF6366F1));
    });

    test('backgroundGradient has 2 colors', () {
      expect(DrawerMenuConfig.backgroundGradient.colors.length, 2);
    });

    test('logoutGradient has 2 colors', () {
      expect(DrawerMenuConfig.logoutGradient.colors.length, 2);
    });

    test('logoutGradient first color is red 0xFFEF4444', () {
      expect(DrawerMenuConfig.logoutGradient.colors.first,
          const Color(0xFFEF4444));
    });

    test('logoutGradient last color is darker red 0xFFDC2626', () {
      expect(
          DrawerMenuConfig.logoutGradient.colors.last, const Color(0xFFDC2626));
    });
  });
}
