import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/core/services/advanced/customization_service.dart';
import 'package:synaptix/core/services/advanced/gift_transaction_service.dart';

void main() {
  // CustomizationService is a singleton — use unique user IDs per test.
  // _loadDefaultItems() gives current_user/user_1/user_2 the 'default' theme
  // and 'emoji_basics' sticker pack when initialize() is called.
  final CustomizationService svc = CustomizationService();
  final GiftTransactionService gts = GiftTransactionService();

  setUpAll(() {
    svc.initialize();
  });

  // ---------------------------------------------------------------------------
  // Default state after initialize
  // ---------------------------------------------------------------------------

  group('default state after initialize', () {
    test('current_user owns default theme', () {
      expect(svc.ownsTheme('current_user', 'default'), isTrue);
    });

    test('current_user active theme is "default"', () {
      expect(svc.getActiveTheme('current_user'), 'default');
    });

    test('current_user owns emoji_basics sticker pack', () {
      expect(svc.ownsStickerPack('current_user', 'emoji_basics'), isTrue);
    });

    test('user_1 owns default theme', () {
      expect(svc.ownsTheme('user_1', 'default'), isTrue);
    });

    test('user_2 owns emoji_basics sticker pack', () {
      expect(svc.ownsStickerPack('user_2', 'emoji_basics'), isTrue);
    });

    test('unknown user owns no themes', () {
      expect(svc.getOwnedThemes('brand_new_user_xyz'), isEmpty);
    });

    test('unknown user active theme is "default" fallback', () {
      expect(svc.getActiveTheme('no_state_user'), 'default');
    });

    test('unknown user owns no sticker packs', () {
      expect(svc.getOwnedStickerPacks('brand_new_user_xyz2'), isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // purchaseTheme
  // ---------------------------------------------------------------------------

  group('purchaseTheme', () {
    test('returns true when user has enough coins', () async {
      await gts.addCoins(
          userId: 'pt_u1', amount: 500, type: TransactionType.coinPurchase);
      final result = await svc.purchaseTheme('pt_u1', 'ocean_theme', 100);
      expect(result, isTrue);
    });

    test('ownsTheme true after successful purchase', () async {
      await gts.addCoins(
          userId: 'pt_u2', amount: 500, type: TransactionType.coinPurchase);
      await svc.purchaseTheme('pt_u2', 'fire_theme', 100);
      expect(svc.ownsTheme('pt_u2', 'fire_theme'), isTrue);
    });

    test('theme appears in getOwnedThemes after purchase', () async {
      await gts.addCoins(
          userId: 'pt_u3', amount: 500, type: TransactionType.coinPurchase);
      await svc.purchaseTheme('pt_u3', 'space_theme', 100);
      expect(svc.getOwnedThemes('pt_u3'), contains('space_theme'));
    });

    test('returns false when user has insufficient coins', () async {
      final result =
          await svc.purchaseTheme('pt_u4_broke', 'expensive_theme', 9999);
      expect(result, isFalse);
    });

    test('ownsTheme false after failed purchase', () async {
      await svc.purchaseTheme('pt_u5_broke', 'pricey_theme', 9999);
      expect(svc.ownsTheme('pt_u5_broke', 'pricey_theme'), isFalse);
    });

    test('returns false when theme already owned', () async {
      final result = await svc.purchaseTheme('current_user', 'default', 0);
      expect(result, isFalse);
    });

    test('can purchase multiple themes for same user', () async {
      await gts.addCoins(
          userId: 'pt_multi', amount: 1000, type: TransactionType.coinPurchase);
      await svc.purchaseTheme('pt_multi', 'theme_a', 100);
      await svc.purchaseTheme('pt_multi', 'theme_b', 100);
      final owned = svc.getOwnedThemes('pt_multi');
      expect(owned, containsAll(['theme_a', 'theme_b']));
    });
  });

  // ---------------------------------------------------------------------------
  // applyTheme
  // ---------------------------------------------------------------------------

  group('applyTheme', () {
    test('returns false when theme not owned', () async {
      final result = await svc.applyTheme('at_u1', 'unowned_theme');
      expect(result, isFalse);
    });

    test('returns true when theme is owned', () async {
      // current_user owns 'default'
      final result = await svc.applyTheme('current_user', 'default');
      expect(result, isTrue);
    });

    test('getActiveTheme returns applied theme', () async {
      await gts.addCoins(
          userId: 'at_u2', amount: 500, type: TransactionType.coinPurchase);
      await svc.purchaseTheme('at_u2', 'neon_theme', 100);
      await svc.applyTheme('at_u2', 'neon_theme');
      expect(svc.getActiveTheme('at_u2'), 'neon_theme');
    });

    test('active theme unchanged when applyTheme fails', () async {
      await svc.applyTheme('at_u3', 'nonexistent_theme');
      expect(svc.getActiveTheme('at_u3'), 'default'); // fallback
    });

    test('can switch active themes', () async {
      await gts.addCoins(
          userId: 'at_u4', amount: 1000, type: TransactionType.coinPurchase);
      await svc.purchaseTheme('at_u4', 'theme_x', 100);
      await svc.purchaseTheme('at_u4', 'theme_y', 100);
      await svc.applyTheme('at_u4', 'theme_x');
      expect(svc.getActiveTheme('at_u4'), 'theme_x');
      await svc.applyTheme('at_u4', 'theme_y');
      expect(svc.getActiveTheme('at_u4'), 'theme_y');
    });
  });

  // ---------------------------------------------------------------------------
  // purchaseStickerPack / ownsStickerPack
  // ---------------------------------------------------------------------------

  group('purchaseStickerPack', () {
    test('returns true with sufficient coins', () async {
      await gts.addCoins(
          userId: 'sp_u1', amount: 500, type: TransactionType.coinPurchase);
      final result = await svc.purchaseStickerPack('sp_u1', 'gaming', 50);
      expect(result, isTrue);
    });

    test('ownsStickerPack true after purchase', () async {
      await gts.addCoins(
          userId: 'sp_u2', amount: 500, type: TransactionType.coinPurchase);
      await svc.purchaseStickerPack('sp_u2', 'reactions', 50);
      expect(svc.ownsStickerPack('sp_u2', 'reactions'), isTrue);
    });

    test('pack appears in getOwnedStickerPacks', () async {
      await gts.addCoins(
          userId: 'sp_u3', amount: 500, type: TransactionType.coinPurchase);
      await svc.purchaseStickerPack('sp_u3', 'animals', 50);
      expect(svc.getOwnedStickerPacks('sp_u3'), contains('animals'));
    });

    test('returns false with insufficient coins', () async {
      final result = await svc.purchaseStickerPack(
          'sp_u4_broke', 'premium_animated', 9999);
      expect(result, isFalse);
    });

    test('returns false when already owned', () async {
      final result =
          await svc.purchaseStickerPack('current_user', 'emoji_basics', 0);
      expect(result, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // getAvailableStickers
  // ---------------------------------------------------------------------------

  group('getAvailableStickers', () {
    test('empty for user with no owned packs', () {
      expect(svc.getAvailableStickers('sticker_fresh_user'), isEmpty);
    });

    test('non-empty for current_user (owns emoji_basics)', () {
      expect(svc.getAvailableStickers('current_user'), isNotEmpty);
    });

    test('emoji_basics has 8 stickers', () {
      // Only user with emoji_basics pack
      final stickers = svc.getAvailableStickers('current_user');
      // current_user may have more packs from other tests — at least 8
      expect(stickers.length, greaterThanOrEqualTo(8));
    });

    test('grows after purchasing additional pack', () async {
      await gts.addCoins(
          userId: 'sticker_u1',
          amount: 500,
          type: TransactionType.coinPurchase);
      final before = svc.getAvailableStickers('sticker_u1').length;
      await svc.purchaseStickerPack('sticker_u1', 'gaming', 50);
      final after = svc.getAvailableStickers('sticker_u1').length;
      expect(after, greaterThan(before));
    });
  });

  // ---------------------------------------------------------------------------
  // setPreference / getPreference
  // ---------------------------------------------------------------------------

  group('preferences', () {
    test('getPreference returns defaultValue when not set', () {
      expect(svc.getPreference('pref_u1', 'someKey', defaultValue: 42), 42);
    });

    test('getPreference returns null when not set and no default', () {
      expect(svc.getPreference('pref_u2', 'missingKey'), isNull);
    });

    test('setPreference / getPreference round-trip string', () async {
      await svc.setPreference('pref_u3', 'myKey', 'myValue');
      expect(svc.getPreference('pref_u3', 'myKey'), 'myValue');
    });

    test('setPreference / getPreference round-trip int', () async {
      await svc.setPreference('pref_u4', 'count', 99);
      expect(svc.getPreference('pref_u4', 'count'), 99);
    });

    test('setPreference / getPreference round-trip bool', () async {
      await svc.setPreference('pref_u5', 'flag', false);
      expect(svc.getPreference('pref_u5', 'flag'), isFalse);
    });

    test('getAllPreferences includes set values', () async {
      await svc.setPreference('pref_u6', 'k1', 'v1');
      await svc.setPreference('pref_u6', 'k2', 100);
      final prefs = svc.getAllPreferences('pref_u6');
      expect(prefs['k1'], 'v1');
      expect(prefs['k2'], 100);
    });

    test('getAllPreferences empty for fresh user', () {
      expect(svc.getAllPreferences('pref_fresh_user'), isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // Common preferences: chatBubbleStyle, fontSize, notificationSound
  // ---------------------------------------------------------------------------

  group('chatBubbleStyle', () {
    test('default is "rounded"', () {
      expect(svc.getChatBubbleStyle('cbs_u1'), 'rounded');
    });

    test('setChatBubbleStyle / getChatBubbleStyle round-trip', () async {
      await svc.setChatBubbleStyle('cbs_u2', 'flat');
      expect(svc.getChatBubbleStyle('cbs_u2'), 'flat');
    });

    test('different users have independent styles', () async {
      await svc.setChatBubbleStyle('cbs_u3', 'modern');
      await svc.setChatBubbleStyle('cbs_u4', 'classic');
      expect(svc.getChatBubbleStyle('cbs_u3'), 'modern');
      expect(svc.getChatBubbleStyle('cbs_u4'), 'classic');
    });
  });

  group('fontSize', () {
    test('default is 14.0', () {
      expect(svc.getFontSize('fs_u1'), 14.0);
    });

    test('setFontSize / getFontSize round-trip', () async {
      await svc.setFontSize('fs_u2', 18.0);
      expect(svc.getFontSize('fs_u2'), 18.0);
    });
  });

  group('notificationSound', () {
    test('default is true', () {
      expect(svc.getNotificationSound('ns_u1'), isTrue);
    });

    test('setNotificationSound false / getNotificationSound', () async {
      await svc.setNotificationSound('ns_u2', false);
      expect(svc.getNotificationSound('ns_u2'), isFalse);
    });

    test('setNotificationSound true / getNotificationSound', () async {
      await svc.setNotificationSound('ns_u3', true);
      expect(svc.getNotificationSound('ns_u3'), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // watchActiveTheme stream
  // ---------------------------------------------------------------------------

  group('watchActiveTheme stream', () {
    test('emits immediately with current active theme', () async {
      // current_user has 'default' active
      final stream = svc.watchActiveTheme('current_user');
      final first = await stream.first.timeout(const Duration(seconds: 2));
      expect(first, isNotEmpty);
    });

    test('emits new theme after applyTheme', () async {
      await gts.addCoins(
          userId: 'watch_u1', amount: 500, type: TransactionType.coinPurchase);
      await svc.purchaseTheme('watch_u1', 'lava_theme', 100);

      final stream = svc.watchActiveTheme('watch_u1');
      final received = <String>[];
      final sub = stream.listen(received.add);

      await svc.applyTheme('watch_u1', 'lava_theme');
      await Future.delayed(const Duration(milliseconds: 100));

      expect(received, contains('lava_theme'));
      await sub.cancel();
    });
  });

  // ---------------------------------------------------------------------------
  // watchOwnedStickers stream
  // ---------------------------------------------------------------------------

  group('watchOwnedStickers stream', () {
    test('emits current sticker packs immediately', () async {
      final stream = svc.watchOwnedStickers('current_user');
      final first = await stream.first.timeout(const Duration(seconds: 2));
      expect(first, isA<Set<String>>());
    });

    test('emits updated set after purchaseStickerPack', () async {
      await gts.addCoins(
          userId: 'watch_sticker_u1',
          amount: 500,
          type: TransactionType.coinPurchase);

      final stream = svc.watchOwnedStickers('watch_sticker_u1');
      final received = <Set<String>>[];
      final sub = stream.listen(received.add);

      await svc.purchaseStickerPack('watch_sticker_u1', 'food', 50);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(received.any((set) => set.contains('food')), isTrue);
      await sub.cancel();
    });
  });

  // ---------------------------------------------------------------------------
  // getCustomizationAnalytics
  // ---------------------------------------------------------------------------

  group('getCustomizationAnalytics', () {
    test('returns map with all expected keys', () {
      final analytics = svc.getCustomizationAnalytics('current_user');
      expect(analytics.containsKey('ownedThemes'), isTrue);
      expect(analytics.containsKey('activeTheme'), isTrue);
      expect(analytics.containsKey('ownedStickerPacks'), isTrue);
      expect(analytics.containsKey('availableStickers'), isTrue);
      expect(analytics.containsKey('preferences'), isTrue);
    });

    test('ownedThemes count ≥ 1 for current_user', () {
      final analytics = svc.getCustomizationAnalytics('current_user');
      expect(analytics['ownedThemes'], greaterThanOrEqualTo(1));
    });

    test('activeTheme is non-empty string', () {
      final analytics = svc.getCustomizationAnalytics('current_user');
      expect((analytics['activeTheme'] as String).isNotEmpty, isTrue);
    });

    test('availableStickers count ≥ 8 for current_user (has emoji_basics)', () {
      final analytics = svc.getCustomizationAnalytics('current_user');
      expect(analytics['availableStickers'], greaterThanOrEqualTo(8));
    });

    test('zero ownedThemes for fresh user', () {
      final analytics = svc.getCustomizationAnalytics('analytics_fresh_user');
      expect(analytics['ownedThemes'], 0);
    });
  });

  // ---------------------------------------------------------------------------
  // exportCustomizations / importCustomizations
  // ---------------------------------------------------------------------------

  group('exportCustomizations', () {
    test('export contains themes, stickers, preferences keys', () async {
      final export = await svc.exportCustomizations('current_user');
      expect(export.containsKey('themes'), isTrue);
      expect(export.containsKey('stickers'), isTrue);
      expect(export.containsKey('preferences'), isTrue);
    });

    test('exported themes.active matches getActiveTheme', () async {
      final export = await svc.exportCustomizations('current_user');
      final themes = export['themes'] as Map<String, dynamic>;
      expect(themes['active'], svc.getActiveTheme('current_user'));
    });
  });

  group('importCustomizations', () {
    test('returns true for valid data', () async {
      final result = await svc.importCustomizations('import_u1', {
        'themes': {
          'owned': ['dark_theme', 'ocean_theme'],
          'active': 'dark_theme'
        },
        'stickers': {
          'owned': ['gaming', 'reactions']
        },
        'preferences': {'fontSize': 18.0},
      });
      expect(result, isTrue);
    });

    test('imported themes are owned after import', () async {
      await svc.importCustomizations('import_u2', {
        'themes': {
          'owned': ['imported_theme'],
          'active': 'imported_theme'
        },
        'stickers': {'owned': []},
        'preferences': {},
      });
      expect(svc.ownsTheme('import_u2', 'imported_theme'), isTrue);
      expect(svc.getActiveTheme('import_u2'), 'imported_theme');
    });

    test('imported sticker packs are owned after import', () async {
      await svc.importCustomizations('import_u3', {
        'themes': {'owned': [], 'active': 'default'},
        'stickers': {
          'owned': ['gaming', 'food']
        },
        'preferences': {},
      });
      expect(svc.ownsStickerPack('import_u3', 'gaming'), isTrue);
      expect(svc.ownsStickerPack('import_u3', 'food'), isTrue);
    });

    test('imported preferences are retrievable', () async {
      await svc.importCustomizations('import_u4', {
        'themes': {'owned': [], 'active': 'default'},
        'stickers': {'owned': []},
        'preferences': {'fontSize': 20.0, 'chatBubbleStyle': 'square'},
      });
      expect(svc.getFontSize('import_u4'), 20.0);
      expect(svc.getChatBubbleStyle('import_u4'), 'square');
    });

    test('round-trip: export then import preserves data', () async {
      await gts.addCoins(
          userId: 'rt_export_u',
          amount: 500,
          type: TransactionType.coinPurchase);
      await svc.purchaseTheme('rt_export_u', 'rt_theme', 100);
      await svc.setFontSize('rt_export_u', 22.0);

      final exported = await svc.exportCustomizations('rt_export_u');
      final result = await svc.importCustomizations('rt_import_u', exported);
      expect(result, isTrue);
      expect(svc.ownsTheme('rt_import_u', 'rt_theme'), isTrue);
      expect(svc.getFontSize('rt_import_u'), 22.0);
    });
  });

  // ---------------------------------------------------------------------------
  // syncCustomizations
  // ---------------------------------------------------------------------------

  group('syncCustomizations', () {
    test('completes without error', () async {
      await expectLater(svc.syncCustomizations('sync_user'), completes);
    });
  });
}
