import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/models/currency_type.dart';
import 'package:trivia_tycoon/game/models/drawer_enums.dart';
import 'package:trivia_tycoon/game/models/menu_enums.dart';

void main() {
  // -------------------------------------------------------------------------
  // CurrencyType
  // -------------------------------------------------------------------------

  group('CurrencyType enum', () {
    test('has exactly 2 values: coins and diamonds', () {
      expect(CurrencyType.values.length, 2);
      expect(CurrencyType.values, containsAll([CurrencyType.coins, CurrencyType.diamonds]));
    });

    test('coins name is "coins"', () {
      expect(CurrencyType.coins.name, 'coins');
    });

    test('diamonds name is "diamonds"', () {
      expect(CurrencyType.diamonds.name, 'diamonds');
    });
  });

  // -------------------------------------------------------------------------
  // AgeGroup (menu_enums.dart)
  // -------------------------------------------------------------------------

  group('AgeGroup enum', () {
    test('has 4 values', () {
      expect(AgeGroup.values.length, 4);
    });

    test('AgeGroupExtension.value returns correct strings', () {
      expect(AgeGroup.kids.value, 'kids');
      expect(AgeGroup.teens.value, 'teens');
      expect(AgeGroup.adults.value, 'adults');
      expect(AgeGroup.general.value, 'general');
    });

    test('AgeGroupExtension.fromString round-trips all values', () {
      expect(AgeGroupExtension.fromString('kids'), AgeGroup.kids);
      expect(AgeGroupExtension.fromString('teens'), AgeGroup.teens);
      expect(AgeGroupExtension.fromString('adults'), AgeGroup.adults);
    });

    test('fromString unknown defaults to general', () {
      expect(AgeGroupExtension.fromString('unknown'), AgeGroup.general);
    });

    test('fromString is case-insensitive', () {
      expect(AgeGroupExtension.fromString('KIDS'), AgeGroup.kids);
      expect(AgeGroupExtension.fromString('Teens'), AgeGroup.teens);
    });
  });

  // -------------------------------------------------------------------------
  // MatchStatus (menu_enums.dart)
  // -------------------------------------------------------------------------

  group('MatchStatus enum', () {
    test('has 5 values', () {
      expect(MatchStatus.values.length, 5);
    });

    test('displayText returns user-facing labels', () {
      expect(MatchStatus.yourTurn.displayText, 'Your turn');
      expect(MatchStatus.waiting.displayText, 'Waiting...');
      expect(MatchStatus.similarStats.displayText, '#SimilarStats');
      expect(MatchStatus.fastPlayer.displayText, '#FastPlayer');
      expect(MatchStatus.finished.displayText, 'Finished');
    });

    test('value returns API/storage strings', () {
      expect(MatchStatus.yourTurn.value, 'your_turn');
      expect(MatchStatus.waiting.value, 'waiting');
      expect(MatchStatus.similarStats.value, 'similar_stats');
      expect(MatchStatus.fastPlayer.value, 'fast_player');
      expect(MatchStatus.finished.value, 'finished');
    });

    test('fromString round-trips all known values', () {
      expect(MatchStatusExtension.fromString('your_turn'), MatchStatus.yourTurn);
      expect(MatchStatusExtension.fromString('waiting'), MatchStatus.waiting);
      expect(MatchStatusExtension.fromString('similar_stats'), MatchStatus.similarStats);
      expect(MatchStatusExtension.fromString('fast_player'), MatchStatus.fastPlayer);
      expect(MatchStatusExtension.fromString('finished'), MatchStatus.finished);
    });

    test('fromString unknown defaults to waiting', () {
      expect(MatchStatusExtension.fromString('bogus'), MatchStatus.waiting);
    });
  });

  // -------------------------------------------------------------------------
  // MatchTab (menu_enums.dart)
  // -------------------------------------------------------------------------

  group('MatchTab enum', () {
    test('has 2 values', () {
      expect(MatchTab.values.length, 2);
    });

    test('displayText returns readable labels', () {
      expect(MatchTab.classic.displayText, 'Classic');
      expect(MatchTab.live.displayText, 'Live');
    });
  });

  // -------------------------------------------------------------------------
  // MatchFilter (menu_enums.dart)
  // -------------------------------------------------------------------------

  group('MatchFilter enum', () {
    test('has 3 values', () {
      expect(MatchFilter.values.length, 3);
    });

    test('displayText returns readable labels', () {
      expect(MatchFilter.all.displayText, 'All');
      expect(MatchFilter.yourTurn.displayText, 'Your turn');
      expect(MatchFilter.suggestions.displayText, 'Suggestions');
    });
  });

  // -------------------------------------------------------------------------
  // LayoutMode (menu_enums.dart)
  // -------------------------------------------------------------------------

  group('LayoutMode enum', () {
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
      expect(LayoutMode.desktop.isTablet, isFalse);
    });

    test('isDesktop is true only for desktop', () {
      expect(LayoutMode.desktop.isDesktop, isTrue);
      expect(LayoutMode.mobile.isDesktop, isFalse);
      expect(LayoutMode.tablet.isDesktop, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // MenuSection (drawer_enums.dart)
  // -------------------------------------------------------------------------

  group('MenuSection enum', () {
    test('has 4 values', () {
      expect(MenuSection.values.length, 4);
    });

    test('displayName returns readable section names', () {
      expect(MenuSection.main.displayName, 'Main Menu');
      expect(MenuSection.more.displayName, 'More Options');
      expect(MenuSection.bottom.displayName, 'Settings');
      expect(MenuSection.logout.displayName, 'Logout');
    });
  });

  // -------------------------------------------------------------------------
  // MenuItemType (drawer_enums.dart)
  // -------------------------------------------------------------------------

  group('MenuItemType enum', () {
    test('has 2 values: gradient and simple', () {
      expect(MenuItemType.values.length, 2);
      expect(MenuItemType.values, containsAll([MenuItemType.gradient, MenuItemType.simple]));
    });
  });
}
